const SELECTORS = {
  composer: [
    'div[contenteditable="true"].ProseMirror',
    'div[contenteditable="true"][enterkeyhint]',
    'div[contenteditable="true"]',
  ],
  sendButton: [
    'button[aria-label="Send message"]',
    'button[aria-label="Send Message"]',
    'button[aria-label*="Send" i]',
    'button[type="submit"]',
  ],
  stopButton: [
    'button[aria-label="Stop response"]',
    'button[aria-label*="Stop" i]',
  ],
  assistantMessage: [
    'div[data-is-streaming]',
    '[data-testid="assistant-message"]',
    ".font-claude-response",
    ".font-claude-message",
  ],

  newChat: [
    'a[href="/new"]',
    'a[href$="/new"]',
    'button[aria-label*="New chat" i]',
    'a[aria-label*="New chat" i]',
  ],
};

const STABLE_MS = 800;
const SETTLE_FALLBACK_MS = 20000;
const HARD_TIMEOUT_MS = 180000;
const DELTA_THROTTLE_MS = 150;
const SEND_POLL_MS = 80;
const SEND_BUTTON_WAIT_MS = 4000;
const SEND_VERIFY_MS = 600;
const SEND_MAX_ATTEMPTS = 3;
const WATCHDOG_STEP_MS = 10000;
const WATCHDOG_TRIES = 9;
const TAP_ENABLED = true;
const TAP_THROTTLE_MS = 120;
const TAP_SAMPLE_LINES = 40;
const TAP_SAMPLE_CHARS = 300;

function firstMatch(list) {
  for (const sel of list) {
    const els = document.querySelectorAll(sel);
    if (els.length) return els[els.length - 1];
  }
  return null;
}

function allMatches(list) {
  for (const sel of list) {
    const els = document.querySelectorAll(sel);
    if (els.length) return Array.from(els);
  }
  return [];
}

function isVisible(el) {
  if (!el) return false;
  const r = el.getBoundingClientRect();
  return r.width > 0 && r.height > 0;
}

function findComposer() {
  for (const sel of SELECTORS.composer) {
    const candidates = Array.from(document.querySelectorAll(sel)).filter(isVisible);
    if (candidates.length) {

      return candidates.sort(
        (a, b) =>
          b.getBoundingClientRect().width * b.getBoundingClientRect().height -
          a.getBoundingClientRect().width * a.getBoundingClientRect().height
      )[0];
    }
  }
  return null;
}

function fireInput(el, text) {
  try {
    el.dispatchEvent(
      new InputEvent("input", { bubbles: true, cancelable: false, inputType: "insertText", data: text })
    );
  } catch (e) {
    el.dispatchEvent(new Event("input", { bubbles: true }));
  }
}

function insertIntoComposer(el, text) {
  el.focus();

  const range = document.createRange();
  range.selectNodeContents(el);
  const sel = window.getSelection();
  sel.removeAllRanges();
  sel.addRange(range);

  let ok = false;
  try {
    ok = document.execCommand("insertText", false, text) && el.innerText.trim().length > 0;
  } catch (e) {
    ok = false;
  }

  if (!ok) {
    const dt = new DataTransfer();
    dt.setData("text/plain", text);
    el.dispatchEvent(
      new ClipboardEvent("paste", { clipboardData: dt, bubbles: true, cancelable: true })
    );
    ok = el.innerText.trim().length > 0;
  }

  if (ok) fireInput(el, text);
  return ok;
}

function composerText(el) {
  return ((el && el.innerText) || "").trim();
}

function pressEnter(el) {
  for (const type of ["keydown", "keypress", "keyup"]) {
    el.dispatchEvent(
      new KeyboardEvent(type, {
        key: "Enter",
        code: "Enter",
        keyCode: 13,
        which: 13,
        bubbles: true,
        cancelable: true,
      })
    );
  }
}

function isSendable(btn) {
  if (!btn) return false;
  if (btn.disabled) return false;
  if (btn.getAttribute && btn.getAttribute("aria-disabled") === "true") return false;

  if (document.visibilityState !== "visible") return true;
  return isVisible(btn);
}

function sendButton() {
  const btn = firstMatch(SELECTORS.sendButton);
  return isSendable(btn) ? btn : null;
}

function whenSendable(cb) {
  const ready = sendButton();
  if (ready) {
    cb(ready);
    return;
  }
  let settled = false;
  const finish = (btn) => {
    if (settled) return;
    settled = true;
    obs.disconnect();
    clearTimeout(timer);
    cb(btn);
  };
  const obs = new MutationObserver(() => {
    const btn = sendButton();
    if (btn) finish(btn);
  });
  obs.observe(document.body, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ["disabled", "aria-disabled", "class"],
  });
  const timer = setTimeout(() => {
    const late = firstMatch(SELECTORS.sendButton);
    finish(isSendable(late) ? late : null);
  }, SEND_BUTTON_WAIT_MS);
}

function whenComposerChanges(el, before, cb) {
  const now = composerText(el);
  if (now === "" || now !== before) {
    cb(true);
    return;
  }
  let settled = false;
  const finish = (ok) => {
    if (settled) return;
    settled = true;
    obs.disconnect();
    clearTimeout(timer);
    cb(ok);
  };
  const obs = new MutationObserver(() => {
    const n = composerText(el);
    if (n === "" || n !== before) finish(true);
  });
  obs.observe(el, { childList: true, subtree: true, characterData: true });
  const timer = setTimeout(() => finish(false), SEND_VERIFY_MS);
}

function sendDiag(el) {
  const btn = firstMatch(SELECTORS.sendButton);
  return (
    "focused=" + (document.hasFocus ? document.hasFocus() : "?") +
    " visibility=" + (document.visibilityState || "?") +
    " sendButton=" + (btn ? (btn.disabled ? "disabled" : "enabled") : "absent") +
    " sendable=" + isSendable(btn) +
    " btnRect=" + (btn && btn.getBoundingClientRect
        ? Math.round(btn.getBoundingClientRect().width) + "x" + Math.round(btn.getBoundingClientRect().height)
        : "?") +
    " composerChars=" + composerText(el).length
  );
}

function submitComposer(el, reinsert, done) {
  const before = composerText(el);
  let attempts = 0;

  const attempt = () => {
    attempts += 1;
    whenSendable((btn) => {
      const how = btn ? "button" : "enter";
      if (btn) btn.click();
      else pressEnter(el);

      whenComposerChanges(el, before, (ok) => {
        if (ok) {
          done(true, how, attempts);
          return;
        }
        if (attempts >= SEND_MAX_ATTEMPTS) {
          done(false, how, attempts);
          return;
        }
        try {
          if (reinsert) reinsert();
        } catch (e) {}
        attempt();
      });
    });
  };

  attempt();
}

function displayOf(el) {
  try {
    const cs = window.getComputedStyle(el);
    return cs ? cs.display : "";
  } catch (e) {
    return "";
  }
}

function isRendered(el) {
  let visible = false;
  try {
    if (typeof el.checkVisibility === "function") visible = el.checkVisibility();
    else visible = !!(el.offsetParent || (el.getClientRects && el.getClientRects().length));
  } catch (e) {
    visible = !!(el.offsetParent || (el.getClientRects && el.getClientRects().length));
  }
  if (visible) return true;

  return displayOf(el) === "contents";
}

function isScreenReaderOnly(el, ignoreAria) {
  const cls = (el.getAttribute && el.getAttribute("class")) || "";
  if (/\b(sr-only|visually-hidden|screen-reader)/i.test(cls)) return true;
  if (!ignoreAria && el.getAttribute && el.getAttribute("aria-hidden") === "true") return true;

  if (el.getBoundingClientRect) {
    const r = el.getBoundingClientRect();
    const clipped = r.width > 0 && r.height > 0 && r.width <= 1 && r.height <= 1;
    if (clipped && (el.textContent || "").trim().length > 0) return true;
  }
  return false;
}

function isControl(el) {
  const tag = el.tagName.toLowerCase();
  if (tag === "button" || tag === "summary" || tag === "svg") return true;
  return el.getAttribute && el.getAttribute("role") === "button";
}

const RAW_NODE_LIMIT = 20000;

function rawNodes(rootEl) {
  const out = [];
  let truncated = false;

  const walk = (node, depth) => {
    for (const n of node.childNodes) {
      if (out.length >= RAW_NODE_LIMIT) {
        truncated = true;
        return;
      }

      if (n.nodeType === Node.TEXT_NODE) {
        if (n.textContent !== "") out.push({ k: "t", d: depth, x: n.textContent });
        continue;
      }
      if (n.nodeType !== Node.ELEMENT_NODE) continue;

      const e = { k: "e", d: depth, g: n.tagName.toLowerCase() };

      const cls = (n.getAttribute && n.getAttribute("class")) || "";
      if (cls) e.c = cls.slice(0, 80);

      const lang =
        (n.getAttribute && (n.getAttribute("data-language") || n.getAttribute("data-lang"))) || "";
      if (lang) e.l = lang;

      const href = n.tagName === "A" && n.getAttribute ? n.getAttribute("href") || "" : "";
      if (href) e.u = href;

      if (n.tagName === "LI" && n.parentElement) {
        e.i = Array.from(n.parentElement.children).indexOf(n) + 1;
        if (n.parentElement.tagName === "OL") e.o = 1;
      }

      if (!isRendered(n)) {
        e.h = 1;
        e.y = displayOf(n);
      }
      if (isScreenReaderOnly(n, false)) e.s = 1;
      if (isControl(n)) e.b = 1;

      out.push(e);
      walk(n, depth + 1);

      if (out.length >= RAW_NODE_LIMIT) {
        truncated = true;
        return;
      }
      out.push({ k: "/", d: depth, g: e.g });
    }
  };

  walk(rootEl, 0);
  return { nodes: out, truncated: truncated };
}

function readResponse() {
  const msgs = allMatches(SELECTORS.assistantMessage);
  if (!msgs.length) return null;
  const el = msgs[msgs.length - 1];
  const raw = rawNodes(el);
  return { text: el.innerText || "", nodes: raw.nodes, truncated: raw.truncated };
}

function isGenerating() {
  if (document.querySelector('div[data-is-streaming="true"]')) return true;
  const stop = firstMatch(SELECTORS.stopButton);
  return !!(stop && isVisible(stop));
}


const tap = {
  installed: false,
  method: "",
  error: "",
  responses: 0,
  streams: 0,
  activeId: null,
  liveId: null,
  sample: [],
  shapes: {},
  lastEmit: 0,
};

const watchers = {};


function tapDiag(stage, extra) {
  const msg = {
    type: "streamtap",
    stage: stage,
    installed: tap.installed,
    method: tap.method,
    error: tap.error,
    responses: tap.responses,
    streams: tap.streams,
    shapes: tap.shapes,
    sample: tap.sample,
  };
  if (extra) for (const k of Object.keys(extra)) msg[k] = extra[k];
  reply(msg);
}

const streams = {};

function claimStream(s) {
  if (s.claimed) return true;
  if (s.id === null || s.id === undefined) return false;
  s.claimed = true;
  tap.liveId = s.id;
  return true;
}

function onTapMessage(ev) {
  if (ev.source !== window) return;
  const d = ev.data;
  if (!d || d.__qsTap !== true) return;

  if (d.kind === "install") {
    tap.installed = !!d.ok;
    tap.method = d.world === "main" ? "main-world" : tap.method;
    if (!d.ok) tap.error = d.error || "inject failed";
    tapDiag("install");
    return;
  }

  if (d.kind === "open") {
    tap.responses += 1;
    tap.streams += 1;
    streams[d.sid] = {
      id: tap.activeId,
      url: d.url || "",
      raw: "",
      claimed: false,
    };
    return;
  }

  if (d.kind === "chunk") {
    const s = streams[d.sid];
    if (!s) return;
    const chunk = String(d.text || "");
    if (chunk === "") return;
    if (tap.sample.length < TAP_SAMPLE_LINES) tap.sample.push(chunk.slice(0, TAP_SAMPLE_CHARS));
    s.raw += chunk;
    if (s.raw.indexOf("data:") === -1) return;
    if (!claimStream(s)) return;
    reply({ type: "rawchunk", id: s.id, text: chunk });
    return;
  }

  if (d.kind === "close") {
    const s = streams[d.sid];
    if (!s) return;
    delete streams[d.sid];
    armTap(false);
    if (!s.claimed) return;

    tap.liveId = null;
    tap.activeId = null;
    const stop = watchers[s.id];
    if (stop) {
      delete watchers[s.id];
      stop();
    }
    reply({ type: "rawdone", id: s.id });
    tapDiag("done", { url: s.url, chars: s.raw.length });
  }
}

function armTap(on) {
  if (!TAP_ENABLED) return;
  try {
    window.postMessage({ __qsTapCmd: on ? "arm" : "disarm" }, "*");
  } catch (e) {}
}

function startTap() {
  if (!TAP_ENABLED) {
    tap.method = "disabled";
    return;
  }
  window.addEventListener("message", onTapMessage);
  tap.method = "main-world";
}

function watchForResponse(id) {
  const before = readResponse();

  if (before === null && !findComposer()) {
    reply({
      type: "error",
      id,
      where: "response",
      message:
        "Could not locate assistant messages in the page. Run __voiceBridgeProbe() in devtools on claude.ai.",
    });
    return;
  }

  const baseline = before === null ? "" : before.text;
  let lastText = "";
  let lastChange = Date.now();
  let lastEmit = 0;
  let sawNewMessage = false;
  const startedAt = Date.now();

  const tick = () => {
    if (tap.liveId === id) {
      sawNewMessage = true;
      lastChange = Date.now();
      return;
    }

    const current = readResponse();

    if (current !== null && current.text !== lastText) {
      if (sawNewMessage || current.text !== baseline) {
        sawNewMessage = true;
        lastText = current.text;
        lastChange = Date.now();

        const now = Date.now();
        if (now - lastEmit > DELTA_THROTTLE_MS) {
          lastEmit = now;
          reply({ type: "delta", id, text: current.text, nodes: current.nodes, truncated: current.truncated });
        }
      }
    }

    if (Date.now() - startedAt > HARD_TIMEOUT_MS) {
      cleanup();
      reply({ type: "error", id, where: "response", message: "Timed out waiting for the reply." });
      return;
    }

    const settled = Date.now() - lastChange;
    if (sawNewMessage && ((!isGenerating() && settled > STABLE_MS) || settled > SETTLE_FALLBACK_MS)) {
      cleanup();
      tap.activeId = null;
      armTap(false);
      tapDiag("domfallback", { chars: lastText.length });
      const final = readResponse();
      reply({
        type: "done",
        id,
        text: final ? final.text : lastText,
        nodes: final ? final.nodes : [],
        truncated: final ? final.truncated : false,
      });
    }
  };

  const safeTick = () => {
    try {
      tick();
    } catch (e) {
      cleanup();
      reply({
        type: "error",
        id,
        where: "response",
        message: "Reply watcher crashed: " + (e && e.message ? e.message : String(e)),
      });
    }
  };

  const observer = new MutationObserver(safeTick);
  observer.observe(document.body, { childList: true, subtree: true, characterData: true });

  const poller = setInterval(safeTick, 300);

  let watchdogTries = 0;
  const watchdog = setInterval(() => {
    if (sawNewMessage) return;
    if (tap.liveId === id || isGenerating()) return;
    watchdogTries += 1;
    if (watchdogTries < WATCHDOG_TRIES) return;
    const counts = SELECTORS.assistantMessage
      .map((s) => s + " = " + document.querySelectorAll(s).length)
      .join(", ");
    cleanup();
    tap.activeId = null;
    armTap(false);
    tapDiag("watchdog", { counts: counts, generating: isGenerating() });
    reply({
      type: "error",
      id,
      where: "response",
      message:
        "No reply detected after " + Math.round((WATCHDOG_STEP_MS * WATCHDOG_TRIES) / 1000) + "s. generating=" + isGenerating() + "; matches: " + counts,
    });
  }, WATCHDOG_STEP_MS);

  watchers[id] = cleanup;

  function cleanup() {
    delete watchers[id];
    observer.disconnect();
    clearInterval(poller);
    clearInterval(watchdog);
  }
}

function reply(msg) {
  browser.runtime.sendMessage(msg);
}

function startNewChat() {
  for (const sel of SELECTORS.newChat) {
    const el = Array.from(document.querySelectorAll(sel)).find(isVisible);
    if (el) {
      el.click();
      return true;
    }
  }
  return false;
}

browser.runtime.onMessage.addListener((msg) => {
  if (msg.type === "newchat") {
    const clicked = startNewChat();

    if (!clicked) {

      reply({ type: "newchat", id: msg.id, ok: true });
      location.assign("https://claude.ai/new");
      return;
    }

    setTimeout(() => {
      if (allMatches(SELECTORS.assistantMessage).length === 0) {
        reply({ type: "newchat", id: msg.id, ok: true });
      } else {
        reply({ type: "newchat", id: msg.id, ok: true });
        location.assign("https://claude.ai/new");
      }
    }, 400);
    return;
  }

  if (msg.type !== "prompt") return;

  const composer = findComposer();
  if (!composer) {
    reply({
      type: "error",
      id: msg.id,
      where: "composer",
      message: "Could not find the message box. Open a chat in this tab.",
    });
    return;
  }

  if (!insertIntoComposer(composer, msg.text)) {
    reply({
      type: "error",
      id: msg.id,
      where: "composer",
      message: "Found the message box but could not type into it.",
    });
    return;
  }

  tap.activeId = msg.id;
  tap.sample = [];
  tap.shapes = {};
  tap.error = "";
  tap.responses = 0;
  tap.streams = 0;
  armTap(true);

  {
    submitComposer(composer, () => insertIntoComposer(composer, msg.text), (sent, how, attempts) => {
      if (!sent) {
        armTap(false);
        tap.activeId = null;
        reply({
          type: "error",
          id: msg.id,
          where: "composer",
          message:
            "Typed the prompt but claude.ai never accepted it (tried " +
            attempts +
            " times, last via " +
            how +
            "). " +
            sendDiag(composer) +
            ". The text is still in the message box.",
        });
        return;
      }
      reply({ type: "accepted", id: msg.id, via: how, attempts: attempts });
      watchForResponse(msg.id);
    });
  }
});

window.__voiceBridgeDump = function (maxDepth) {
  maxDepth = maxDepth || 5;
  const msgs = allMatches(SELECTORS.assistantMessage);
  if (!msgs.length) {
    console.log("no assistant message matched; check SELECTORS.assistantMessage");
    return;
  }
  const root = msgs[msgs.length - 1];
  const lines = [];

  (function walk(el, depth) {
    if (depth > maxDepth) return;
    for (const c of el.children) {
      const cls = (c.getAttribute("class") || "").split(/\s+/).filter(Boolean).slice(0, 3).join(".");
      const data = Array.from(c.attributes)
        .filter((a) => a.name.indexOf("data-") === 0)
        .slice(0, 3)
        .map((a) => a.name + "=" + a.value)
        .join(" ");
      const txt = (c.textContent || "").replace(/\s+/g, " ").slice(0, 45);
      lines.push(
        "  ".repeat(depth) +
          "<" + c.tagName.toLowerCase() + ">" +
          (cls ? " ." + cls : "") +
          (data ? " [" + data + "]" : "") +
          " :: " + txt
      );
      walk(c, depth + 1);
    }
  })(root, 0);

  const out = lines.join("\n");
  console.log(out);
  try {
    copy(out);
    return "(copied to clipboard — " + lines.length + " nodes)";
  } catch (e) {
    return "(select the output above and copy it)";
  }
};

window.__voiceBridgeTap = function () {
  const out = {
    installed: tap.installed,
    method: tap.method,
    error: tap.error,
    responses: tap.responses,
    streams: tap.streams,
    activeId: tap.activeId,
    liveId: tap.liveId,
    shapes: tap.shapes,
    sample: tap.sample,
  };
  console.log(out);
  return out;
};

window.__voiceBridgeProbe = function () {
  const out = {};
  for (const [name, list] of Object.entries(SELECTORS)) {
    out[name] = list.map((sel) => ({ selector: sel, matches: document.querySelectorAll(sel).length }));
  }
  const r = readResponse();
  out.resolved = {
    composer: findComposer(),
    sendButton: firstMatch(SELECTORS.sendButton),
    generating: isGenerating(),
    nodes: r ? r.nodes.length : null,
    truncated: r ? r.truncated : null,
  };
  console.log(out);
  return out;
};

startTap();
