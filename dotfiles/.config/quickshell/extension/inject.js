(function () {
  if (window.__qsTapInstalled) return;
  window.__qsTapInstalled = true;

  var nextSid = 1;
  var armed = false;

  function post(msg) {
    try {
      msg.__qsTap = true;
      window.postMessage(msg, "*");
    } catch (e) {}
  }

  window.addEventListener("message", function (ev) {
    if (ev.source !== window) return;
    var d = ev.data;
    if (!d || !d.__qsTapCmd) return;
    armed = d.__qsTapCmd === "arm";
  });

  var orig = window.fetch;
  if (typeof orig !== "function") {
    post({ kind: "install", ok: false, error: "no window.fetch" });
    return;
  }

  function pump(reader, decoder, sid) {
    reader.read().then(
      function (r) {
        try {
          if (r.done) {
            armed = false;
            post({ kind: "close", sid: sid });
            return;
          }
          post({ kind: "chunk", sid: sid, text: decoder.decode(r.value, { stream: true }) });
          pump(reader, decoder, sid);
        } catch (e) {
          armed = false;
          post({ kind: "close", sid: sid });
        }
      },
      function () {
        armed = false;
        post({ kind: "close", sid: sid });
      }
    );
  }

  function observe(p) {
    p.then(
      function (res) {
        try {
          var ct = (res.headers && res.headers.get("content-type")) || "";
          if (ct.indexOf("event-stream") === -1) return;
          if (!res.body) return;

          var clone = res.clone();
          if (!clone.body) return;

          var sid = nextSid++;
          post({ kind: "open", sid: sid, url: String(res.url || "") });
          pump(clone.body.getReader(), new TextDecoder("utf-8"), sid);
        } catch (e) {}
      },
      function () {}
    );
  }

  window.fetch = function () {
    var p = orig.apply(this, arguments);
    if (armed) {
      try {
        observe(p);
      } catch (e) {}
    }
    return p;
  };

  post({ kind: "install", ok: true, world: "main" });
})();
