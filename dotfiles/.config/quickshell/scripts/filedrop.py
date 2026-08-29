#!/usr/bin/env python3
import argparse
import json
import os
import re
import secrets
import socket
import sys
import threading
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

STATE = {"dir": "", "token": "", "shared": [], "share_list": ""}
EMIT_LOCK = threading.Lock()
SEEN_PEERS = set()


def emit(event, **fields):
    with EMIT_LOCK:
        sys.stdout.write(json.dumps({"event": event, **fields}) + "\n")
        sys.stdout.flush()


def lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def safe_name(raw):
    name = os.path.basename(raw or "").strip()
    name = re.sub(r"[\x00-\x1f/\\]", "", name)
    return name or "upload.bin"


def unique_path(directory, name):
    target = os.path.join(directory, name)
    if not os.path.exists(target):
        return target
    stem, ext = os.path.splitext(name)
    n = 1
    while True:
        candidate = os.path.join(directory, f"{stem} ({n}){ext}")
        if not os.path.exists(candidate):
            return candidate
        n += 1


def describe(paths):
    out = []
    for item in paths:
        try:
            out.append({
                "name": os.path.basename(item),
                "path": item,
                "size": os.path.getsize(item),
            })
        except OSError:
            continue
    return out


def refresh_shared():
    """The shell rewrites the share list while the server runs, so re-read it
    per request rather than restarting (a restart would change the QR)."""
    if not STATE["share_list"]:
        return
    try:
        with open(STATE["share_list"]) as f:
            paths = json.load(f)
        if isinstance(paths, list):
            STATE["shared"] = describe([p for p in paths if isinstance(p, str)])
    except (OSError, ValueError):
        pass


def human(size):
    units = ["B", "KB", "MB", "GB"]
    value = float(size)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{value:.0f} {unit}" if unit == "B" else f"{value:.1f} {unit}"
        value /= 1024
    return f"{value:.1f} GB"


PAGE = """<!doctype html>
<html><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>Nebula Drop</title>
<style>
:root{color-scheme:dark}
*{box-sizing:border-box}
body{margin:0;padding:22px 18px 40px;background:#13140f;color:#e5e6dc;
 font:16px/1.45 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
h1{font-size:19px;margin:0 0 2px}
p.sub{margin:0 0 22px;color:#8f9184;font-size:13px}
h2{font-size:13px;text-transform:uppercase;letter-spacing:.08em;color:#dff182;margin:26px 0 10px}
.drop{display:flex;flex-direction:column;align-items:center;justify-content:center;
 border:2px dashed #3a3d31;border-radius:20px;padding:32px 18px;text-align:center;
 background:#1c1e17;cursor:pointer;-webkit-tap-highlight-color:transparent;
 transition:border-color .15s,background .15s}
.drop.hot{border-color:#dff182;background:#232619}
.drop svg{display:block;width:34px;height:34px;fill:#dff182;margin-bottom:10px}
.drop b{display:block;font-size:15px}
.drop span{display:block;color:#8f9184;font-size:13px;margin-top:3px}
input[type=file]{display:none}
.row{display:flex;align-items:center;gap:12px;background:#1c1e17;border-radius:14px;
 padding:12px 14px;margin-bottom:7px;text-decoration:none;color:inherit}
.row .meta{flex:1;min-width:0}
.row .n{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:14px}
.row .s{color:#8f9184;font-size:12px;flex:none}
.bar{height:5px;border-radius:3px;background:#2b2e24;overflow:hidden;margin-top:8px}
.bar>i{display:block;height:100%;width:0;background:#dff182;transition:width .12s}
.ok{color:#dff182}
.err{color:#ff9c8a}
.empty{color:#8f9184;font-size:13px}
</style></head><body>
<h1>Nebula Drop</h1>
<p class="sub">__HOST__</p>

<h2>Send to PC</h2>
<label class="drop" id="drop">
  <input type="file" id="pick" multiple>
  <svg viewBox="0 0 24 24"><path d="M11 15V6.8L8.4 9.4 7 8l5-5 5 5-1.4 1.4L13 6.8V15h-2Zm-5 5q-.8 0-1.4-.6T4 18v-3h2v3h12v-3h2v3q0 .8-.6 1.4T18 20H6Z"/></svg>
  <b>Choose files</b>
  <span>or drag them here</span>
</label>
<div id="list"></div>

<h2>From PC</h2>
<div id="shared">__SHARED__</div>

<script>
const token = "__TOKEN__";
const drop = document.getElementById('drop');
const pick = document.getElementById('pick');
const list = document.getElementById('list');

['dragenter','dragover'].forEach(e=>drop.addEventListener(e,ev=>{
  ev.preventDefault();drop.classList.add('hot')}));
['dragleave','drop'].forEach(e=>drop.addEventListener(e,ev=>{
  ev.preventDefault();drop.classList.remove('hot')}));
drop.addEventListener('drop',ev=>send(ev.dataTransfer.files));
pick.addEventListener('change',()=>send(pick.files));

function send(files){
  for (const f of files) upload(f);
  pick.value = '';
}

function upload(file){
  const row = document.createElement('div');
  row.className = 'row';
  row.innerHTML = '<div class="meta"><div class="n"></div>'
    + '<div class="bar"><i></i></div></div><div class="s"></div>';
  row.querySelector('.n').textContent = file.name;
  list.prepend(row);
  const bar = row.querySelector('.bar>i');
  const status = row.querySelector('.s');

  const xhr = new XMLHttpRequest();
  xhr.open('POST', '/' + token + '/upload');
  xhr.setRequestHeader('X-Filename', encodeURIComponent(file.name));
  xhr.upload.onprogress = e => {
    if (e.lengthComputable) {
      const pct = Math.round(e.loaded / e.total * 100);
      bar.style.width = pct + '%';
      status.textContent = pct + '%';
    }
  };
  xhr.onload = () => {
    bar.style.width = '100%';
    status.textContent = xhr.status === 200 ? 'sent' : 'failed';
    status.className = 's ' + (xhr.status === 200 ? 'ok' : 'err');
  };
  xhr.onerror = () => { status.textContent = 'failed'; status.className = 's err'; };
  xhr.send(file);
}
</script>
</body></html>
"""


class Handler(BaseHTTPRequestHandler):
    server_version = "NebulaDrop"
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        pass

    def _note_peer(self):
        addr = self.client_address[0]
        if addr not in SEEN_PEERS:
            SEEN_PEERS.add(addr)
            emit("peer", addr=addr, agent=self.headers.get("User-Agent", ""))

    def _reply(self, code, body=b"", ctype="text/plain; charset=utf-8", extra=None):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        for key, value in (extra or {}).items():
            self.send_header(key, value)
        self.end_headers()
        if body:
            self.wfile.write(body)

    def _route(self):
        path = urllib.parse.urlparse(self.path).path
        prefix = "/" + STATE["token"]
        if path == prefix:
            return ""
        if path.startswith(prefix + "/"):
            return path[len(prefix) + 1:]
        return None

    def do_GET(self):
        route = self._route()
        if route is None:
            self._reply(404, b"not found")
            return
        self._note_peer()

        if route in ("", "index.html"):
            refresh_shared()
            rows = []
            for i, item in enumerate(STATE["shared"]):
                rows.append(
                    f'<a class="row" href="/{STATE["token"]}/f/{i}" download>'
                    f'<div class="n">{item["name"]}</div>'
                    f'<div class="s">{human(item["size"])}</div></a>'
                )
            shared = "".join(rows) or '<div class="empty">Nothing shared yet</div>'
            page = (PAGE.replace("__TOKEN__", STATE["token"])
                        .replace("__HOST__", self.headers.get("Host", ""))
                        .replace("__SHARED__", shared))
            self._reply(200, page.encode("utf-8"), "text/html; charset=utf-8")
            return

        if route.startswith("f/"):
            refresh_shared()
            try:
                index = int(route.split("/")[1])
                item = STATE["shared"][index]
            except (IndexError, ValueError):
                self._reply(404, b"not found")
                return
            try:
                with open(item["path"], "rb") as f:
                    self.send_response(200)
                    self.send_header("Content-Type", "application/octet-stream")
                    self.send_header("Content-Length", str(item["size"]))
                    self.send_header(
                        "Content-Disposition",
                        f'attachment; filename="{item["name"]}"')
                    self.end_headers()
                    while True:
                        chunk = f.read(64 * 1024)
                        if not chunk:
                            break
                        self.wfile.write(chunk)
                emit("download", name=item["name"])
            except OSError as e:
                emit("error", message=str(e))
            return

        self._reply(404, b"not found")

    def do_POST(self):
        route = self._route()
        if route != "upload":
            self._reply(404, b"not found")
            return
        self._note_peer()

        length = int(self.headers.get("Content-Length") or 0)
        if length <= 0:
            self._reply(400, b"empty")
            return

        raw = self.headers.get("X-Filename", "")
        name = safe_name(urllib.parse.unquote(raw))
        path = unique_path(STATE["dir"], name)

        written = 0
        try:
            with open(path, "wb") as f:
                while written < length:
                    chunk = self.rfile.read(min(256 * 1024, length - written))
                    if not chunk:
                        break
                    f.write(chunk)
                    written += len(chunk)
        except OSError as e:
            emit("error", message=str(e))
            self._reply(500, b"write failed")
            return

        if written != length:
            try:
                os.remove(path)
            except OSError:
                pass
            emit("error", message=f"truncated upload of {name}")
            self._reply(400, b"truncated")
            return

        emit("upload", name=os.path.basename(path), size=written, path=path)
        self._reply(200, b"ok")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", default=os.path.expanduser("~/Downloads"))
    parser.add_argument("--port", type=int, default=0)
    parser.add_argument("--send", nargs="*", default=[])
    parser.add_argument("--share-list", default="")
    args = parser.parse_args()

    STATE["dir"] = args.dir
    STATE["token"] = secrets.token_urlsafe(6)
    STATE["share_list"] = args.share_list

    try:
        os.makedirs(STATE["dir"], exist_ok=True)
    except OSError as e:
        emit("error", message=f"cannot use {STATE['dir']}: {e}")
        return 1

    STATE["shared"] = describe(args.send)
    refresh_shared()

    try:
        httpd = ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    except OSError as e:
        emit("error", message=str(e))
        return 1

    httpd.daemon_threads = True
    ip = lan_ip()
    port = httpd.server_address[1]
    emit("ready",
         url=f"http://{ip}:{port}/{STATE['token']}",
         ip=ip, port=port, token=STATE["token"], dir=STATE["dir"],
         shared=len(STATE["shared"]))

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
