#!/usr/bin/env python3
"""
Relay between the quickshell ai overlay and the Zen browser extension.

    quickshell  <--line-delimited JSON on stdin/stdout-->  this  <--WebSocket-->  extension

Deliberately dumb: it knows nothing about claude.ai, whisper, or QML. It moves
JSON objects between a pipe and a socket, and reports whether the browser side
is currently attached.

Implements just enough of RFC 6455 to serve one local extension, which keeps the
tool free of any pip dependency.

Messages this emits on stdout, one JSON object per line:
    {"type":"bridge","connected":true|false}   browser attachment changed
    ...anything the extension sends (accepted / delta / done / error)

Messages it accepts on stdin, one JSON object per line:
    {"type":"prompt","id":1,"text":"..."}      forwarded to the extension
    {"type":"newchat","id":2}                  open a fresh claude.ai conversation

Nothing here inspects those beyond reading `id` to attach it to a "not
connected" error: every line is relayed verbatim, so adding a command means
touching the extension and quickshell only.
"""

import base64
import hashlib
import json
import os
import selectors
import socket
import sys

HOST = "127.0.0.1"
PORT = int(os.environ.get("QS_AI_BRIDGE_PORT", "8765"))

WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

OP_CONT = 0x0
OP_TEXT = 0x1
OP_BINARY = 0x2
OP_CLOSE = 0x8
OP_PING = 0x9
OP_PONG = 0xA

MAX_MESSAGE_BYTES = 8 * 1024 * 1024


def emit(obj):
    """Write one JSON line to quickshell."""
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


class Client:
    """One WebSocket connection, driven by non-blocking reads."""

    def __init__(self, sock):
        self.sock = sock
        self.buf = bytearray()
        self.handshaken = False
        self.closed = False
        # Accumulator for fragmented messages.
        self.frag_op = None
        self.frag_data = bytearray()

    # ── receiving ───────────────────────────────────────────────────────────

    def feed(self, data):
        """Consume bytes; yield complete text messages."""
        self.buf.extend(data)

        if not self.handshaken:
            if not self._try_handshake():
                return
        yield from self._drain_frames()

    def _try_handshake(self):
        end = self.buf.find(b"\r\n\r\n")
        if end == -1:
            if len(self.buf) > 16384:
                self.close()
            return False

        head = bytes(self.buf[:end]).decode("latin-1")
        del self.buf[: end + 4]

        key = None
        for line in head.split("\r\n")[1:]:
            name, _, value = line.partition(":")
            if name.strip().lower() == "sec-websocket-key":
                key = value.strip()

        if not key:
            self.sock.sendall(b"HTTP/1.1 400 Bad Request\r\n\r\n")
            self.close()
            return False

        accept = base64.b64encode(
            hashlib.sha1((key + WS_GUID).encode()).digest()
        ).decode()

        self.sock.sendall(
            (
                "HTTP/1.1 101 Switching Protocols\r\n"
                "Upgrade: websocket\r\n"
                "Connection: Upgrade\r\n"
                f"Sec-WebSocket-Accept: {accept}\r\n"
                "\r\n"
            ).encode()
        )
        self.handshaken = True
        return True

    def _drain_frames(self):
        while True:
            frame = self._parse_frame()
            if frame is None:
                return
            fin, opcode, payload = frame

            if opcode == OP_CLOSE:
                self.close()
                return
            if opcode == OP_PING:
                self._send_frame(OP_PONG, payload)
                continue
            if opcode == OP_PONG:
                continue

            if opcode == OP_CONT:
                if self.frag_op is None:
                    self.close()
                    return
                self.frag_data.extend(payload)
            else:
                self.frag_op = opcode
                self.frag_data = bytearray(payload)

            if len(self.frag_data) > MAX_MESSAGE_BYTES:
                self.close()
                return

            if fin:
                op, data = self.frag_op, bytes(self.frag_data)
                self.frag_op = None
                self.frag_data = bytearray()
                if op == OP_TEXT:
                    yield data.decode("utf-8", "replace")

    def _parse_frame(self):
        """Pull one frame off the buffer, or return None if it's incomplete."""
        b = self.buf
        if len(b) < 2:
            return None

        fin = bool(b[0] & 0x80)
        opcode = b[0] & 0x0F
        masked = bool(b[1] & 0x80)
        length = b[1] & 0x7F
        offset = 2

        if length == 126:
            if len(b) < offset + 2:
                return None
            length = int.from_bytes(b[offset : offset + 2], "big")
            offset += 2
        elif length == 127:
            if len(b) < offset + 8:
                return None
            length = int.from_bytes(b[offset : offset + 8], "big")
            offset += 8

        if length > MAX_MESSAGE_BYTES:
            self.close()
            return None

        mask = b""
        if masked:
            if len(b) < offset + 4:
                return None
            mask = bytes(b[offset : offset + 4])
            offset += 4

        if len(b) < offset + length:
            return None

        payload = bytearray(b[offset : offset + length])
        del b[: offset + length]

        if masked:
            for i in range(len(payload)):
                payload[i] ^= mask[i & 3]

        return fin, opcode, bytes(payload)

    # ── sending ─────────────────────────────────────────────────────────────

    def send_text(self, text):
        self._send_frame(OP_TEXT, text.encode("utf-8"))

    def _send_frame(self, opcode, payload):
        if self.closed:
            return
        header = bytearray([0x80 | opcode])
        n = len(payload)
        if n < 126:
            header.append(n)
        elif n < 65536:
            header.append(126)
            header.extend(n.to_bytes(2, "big"))
        else:
            header.append(127)
            header.extend(n.to_bytes(8, "big"))
        try:
            self.sock.sendall(bytes(header) + payload)
        except OSError:
            self.close()

    def close(self):
        if self.closed:
            return
        self.closed = True
        try:
            self.sock.close()
        except OSError:
            pass


def main():
    sel = selectors.DefaultSelector()

    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        listener.bind((HOST, PORT))
    except OSError as e:
        emit({"type": "fatal", "message": f"cannot bind {HOST}:{PORT}: {e}"})
        return 1
    listener.listen(4)
    listener.setblocking(False)

    sel.register(listener, selectors.EVENT_READ, "listener")
    sel.register(sys.stdin.buffer, selectors.EVENT_READ, "stdin")

    clients = []
    stdin_buf = bytearray()

    emit({"type": "bridge", "connected": False})

    def announce():
        emit({"type": "bridge", "connected": any(c.handshaken and not c.closed for c in clients)})

    def drop(client):
        if client in clients:
            try:
                sel.unregister(client.sock)
            except (KeyError, ValueError):
                pass
            client.close()
            clients.remove(client)
            announce()

    while True:
        for key, _ in sel.select():
            tag = key.data

            if tag == "listener":
                try:
                    conn, _ = listener.accept()
                except OSError:
                    continue
                conn.setblocking(False)
                client = Client(conn)
                clients.append(client)
                sel.register(conn, selectors.EVENT_READ, client)

            elif tag == "stdin":
                chunk = os.read(0, 65536)
                if not chunk:
                    return 0  # quickshell closed the pipe; shut down
                stdin_buf.extend(chunk)
                while b"\n" in stdin_buf:
                    line, _, rest = bytes(stdin_buf).partition(b"\n")
                    stdin_buf = bytearray(rest)
                    text = line.decode("utf-8", "replace").strip()
                    if not text:
                        continue
                    live = [c for c in clients if c.handshaken and not c.closed]
                    if not live:
                        try:
                            msg = json.loads(text)
                            mid = msg.get("id")
                        except ValueError:
                            mid = None
                        emit(
                            {
                                "type": "error",
                                "id": mid,
                                "where": "bridge",
                                "message": "Zen extension is not connected.",
                            }
                        )
                        continue
                    for c in live:
                        c.send_text(text)

            else:
                client = key.data
                try:
                    data = client.sock.recv(65536)
                except OSError:
                    drop(client)
                    continue
                if not data:
                    drop(client)
                    continue

                was_up = client.handshaken
                try:
                    for message in client.feed(data):
                        try:
                            json.loads(message)
                        except ValueError:
                            continue
                        sys.stdout.write(message + "\n")
                        sys.stdout.flush()
                except OSError:
                    drop(client)
                    continue

                if client.closed:
                    drop(client)
                elif client.handshaken and not was_up:
                    announce()


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(0)
