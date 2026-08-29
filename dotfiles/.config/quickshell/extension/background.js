const BRIDGE_URL = "ws://127.0.0.1:8765";

const RECONNECT_MIN_MS = 500;
const RECONNECT_MAX_MS = 10000;

let socket = null;
let reconnectDelay = RECONNECT_MIN_MS;
let reconnectTimer = null;

function connect() {
  clearTimeout(reconnectTimer);

  try {
    socket = new WebSocket(BRIDGE_URL);
  } catch (e) {
    scheduleReconnect();
    return;
  }

  socket.onopen = () => {
    reconnectDelay = RECONNECT_MIN_MS;
    send({ type: "hello", agent: "zen-extension" });
  };

  socket.onmessage = async (event) => {
    let msg;
    try {
      msg = JSON.parse(event.data);
    } catch (e) {
      return;
    }
    if (msg.type === "prompt" || msg.type === "newchat") {
      await forwardToTab(msg);
    }
  };

  socket.onclose = () => {
    socket = null;
    scheduleReconnect();
  };

  socket.onerror = () => {};
}

function scheduleReconnect() {
  clearTimeout(reconnectTimer);
  reconnectTimer = setTimeout(connect, reconnectDelay);
  reconnectDelay = Math.min(reconnectDelay * 2, RECONNECT_MAX_MS);
}

function send(obj) {
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify(obj));
  }
}

async function findClaudeTab() {
  const tabs = await browser.tabs.query({ url: "https://claude.ai/*" });
  if (tabs.length === 0) return null;
  const active = tabs.find((t) => t.active);
  if (active) return active;
  return tabs.sort((a, b) => (b.lastAccessed || 0) - (a.lastAccessed || 0))[0];
}

async function forwardToTab(msg) {
  const tab = await findClaudeTab();
  if (!tab) {
    send({
      type: "error",
      id: msg.id,
      where: "tab",
      message: "No claude.ai tab is open in Zen.",
    });
    return;
  }

  try {
    await browser.tabs.sendMessage(tab.id, msg);
  } catch (e) {

    send({
      type: "error",
      id: msg.id,
      where: "tab",
      message: "claude.ai tab found but not reachable. Reload the tab.",
    });
  }
}

browser.runtime.onMessage.addListener((msg) => {
  send(msg);
});

connect();
