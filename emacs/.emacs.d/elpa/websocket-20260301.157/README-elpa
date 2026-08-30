This implements RFC 6455, which can be found at
http://tools.ietf.org/html/rfc6455.

This library contains code to connect Emacs as a client to a
websocket server, and for Emacs to act as a server for websocket
connections.

Websockets clients are created by calling `websocket-open', which
returns a `websocket' struct.  Users of this library use the
websocket struct, and can call methods `websocket-send-text', which
sends text over the websocket, or `websocket-send', which sends a
`websocket-frame' struct, enabling finer control of what is sent.
A callback is passed to `websocket-open' that will retrieve
websocket frames called from the websocket.  Websockets are
eventually closed with `websocket-close'.

Server functionality is similar.  A server is started with
`websocket-server' called with a port and the callbacks to use,
which returns a process.  The process can later be closed with
`websocket-server-close'.  A `websocket' struct is also created
for every connection, and is exposed through the callbacks.
