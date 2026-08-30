import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ── Public state ──
    property var niriRaw: []
    property var niriWorkspaces: []
    property var niriWindows: []
    property string activeWindowTitle: ""
    property string activeWindowAppId: ""

    readonly property var allowedAppIds: ["spotify", "telegram", "vesktop", "discord"]

    // Grouped apps derived from niriWindows
    property var groupedRunningApps: {
        let map = {};
        let order = [];
        for (let i = 0; i < niriWindows.length; i++) {
            let w = niriWindows[i];
            if (!w)
                continue;
            let rawAid = String(w.app_id || w.appId || "unknown");
            if (rawAid === "" || rawAid === "unknown")
                rawAid = w.title ? String(w.title).split(" ")[0] : "unknown";
            let low = rawAid.toLowerCase();
            let key = low;
            let displayId = rawAid;
            if (low.indexOf("spotify") !== -1) {
                key = "spotify";
                displayId = "spotify";
            } else if (low.indexOf("telegram") !== -1) {
                key = "telegram";
                displayId = "telegram";
            } else if (low.indexOf("vesktop") !== -1 || low.indexOf("discord") !== -1) {
                key = "vesktop";
                displayId = "vesktop";
            } else {
                key = low;
                displayId = rawAid;
            }
            if (!map[key]) {
                map[key] = {
                    key: key,
                    appId: displayId,
                    count: 0,
                    windows: [],
                    isFocused: false,
                    titles: [],
                    lastFocused: 0
                };
                order.push(key);
            }
            map[key].count++;
            map[key].windows.push(w);
            if (w.is_focused)
                map[key].isFocused = true;
            if (w.title)
                map[key].titles.push(String(w.title));
            let ts = 0;
            if (w.focus_timestamp) {
                let s = Number(w.focus_timestamp.secs) || 0;
                let n = Number(w.focus_timestamp.nanos) || 0;
                ts = s * 1000000000 + n;
            }
            if (ts > map[key].lastFocused)
                map[key].lastFocused = ts;
        }
        let out = [];
        for (let i = 0; i < order.length; i++)
            out.push(map[order[i]]);
        out.sort((a, b) => b.lastFocused - a.lastFocused);
        return out;
    }

    property var filteredRunningApps: {
        let filtered = [];
        for (let i = 0; i < groupedRunningApps.length; i++) {
            let entry = groupedRunningApps[i];
            let low = String(entry.appId || "").toLowerCase();
            for (let j = 0; j < allowedAppIds.length; j++) {
                if (low.indexOf(allowedAppIds[j]) !== -1) {
                    filtered.push(entry);
                    break;
                }
            }
        }
        return filtered;
    }

    // ── App icon resolver ──
    function appIconName(appId) {
        let aid = String(appId || "");
        if (!aid)
            return "";
        let lower = aid.toLowerCase();
        let candidates = [];
        if (lower.indexOf("spotify") !== -1) {
            candidates = ["spotify-launcher", "spotify", "spotify-client"];
        } else if (lower.indexOf("telegram") !== -1) {
            candidates = ["org.telegram.desktop", "telegram", "telegram-desktop"];
        } else if (lower.indexOf("vesktop") !== -1) {
            candidates = ["vesktop", "discord", "Discord"];
        } else if (lower.indexOf("discord") !== -1) {
            candidates = ["discord", "vesktop", "Discord"];
        }
        for (let i = 0; i < candidates.length; i++) {
            let cand = candidates[i];
            if (Quickshell.hasThemeIcon && Quickshell.hasThemeIcon(cand)) {
                let p = Quickshell.iconPath(cand, "");
                if (p && p !== "")
                    return p;
            }
            let e = DesktopEntries.heuristicLookup(cand);
            if (e && e.icon) {
                let pp = Quickshell.iconPath(e.icon, "");
                if (pp && pp !== "")
                    return pp;
            }
        }
        let entry = DesktopEntries.heuristicLookup(aid);
        if (entry && entry.icon) {
            let p = Quickshell.iconPath(entry.icon, "");
            if (p && p !== "")
                return p;
        }
        if (lower !== aid) {
            let e2 = DesktopEntries.heuristicLookup(lower);
            if (e2 && e2.icon) {
                let p2 = Quickshell.iconPath(e2.icon, "");
                if (p2 && p2 !== "")
                    return p2;
            }
        }
        if (Quickshell.hasThemeIcon && Quickshell.hasThemeIcon(aid)) {
            let p3 = Quickshell.iconPath(aid, "");
            if (p3 && p3 !== "")
                return p3;
        }
        if (Quickshell.hasThemeIcon && Quickshell.hasThemeIcon(lower)) {
            let p4 = Quickshell.iconPath(lower, "");
            if (p4 && p4 !== "")
                return p4;
        }
        for (let c = 0; c < candidates.length; c++) {
            let p = Quickshell.iconPath(candidates[c], "");
            if (p && p !== "" && p.indexOf("NOTFOUND") === -1)
                return p;
        }
        let fallback = Quickshell.iconPath("application-x-executable", "");
        if (fallback && fallback !== "")
            return fallback;
        return "";
    }

    // ── Window actions ──
    function focusGroupedApp(group) {
        if (!group || !group.windows || group.windows.length === 0)
            return;
        let wins = group.windows;
        if (wins.length === 1) {
            let nid = wins[0].id;
            if (nid !== undefined)
                Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(nid)]);
            return;
        }
        let focusedIdx = -1;
        for (let i = 0; i < wins.length; i++)
            if (wins[i].is_focused)
                focusedIdx = i;
        if (focusedIdx !== -1) {
            let nextIdx = (focusedIdx + 1) % wins.length;
            let nid = wins[nextIdx].id;
            if (nid !== undefined)
                Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(nid)]);
        } else {
            let best = wins[0];
            let bestTs = -1;
            for (let i = 0; i < wins.length; i++) {
                let w = wins[i];
                let ts = w.focus_timestamp ? (Number(w.focus_timestamp.secs) || 0) * 1000000000 + (Number(w.focus_timestamp.nanos) || 0) : 0;
                if (ts > bestTs) {
                    bestTs = ts;
                    best = w;
                }
            }
            if (best && best.id !== undefined)
                Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(best.id)]);
        }
    }

    function closeGroupedApp(group, onlyFocused) {
        if (!group || !group.windows || group.windows.length === 0)
            return;
        let wins = group.windows;
        let target = null;
        if (onlyFocused) {
            for (let i = 0; i < wins.length; i++)
                if (wins[i].is_focused) {
                    target = wins[i];
                    break;
                }
        }
        if (!target) {
            let bestTs = -1;
            for (let i = 0; i < wins.length; i++) {
                let w = wins[i];
                let ts = w.focus_timestamp ? (Number(w.focus_timestamp.secs) || 0) * 1000000000 + (Number(w.focus_timestamp.nanos) || 0) : 0;
                if (ts > bestTs) {
                    bestTs = ts;
                    target = w;
                }
            }
        }
        if (target && target.id !== undefined)
            Quickshell.execDetached(["niri", "msg", "action", "close-window", "--id", String(target.id)]);
    }

    function focusWorkspace(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(idx)]);
    }

    // ── Niri polling ──
    Process {
        id: niriProc
        command: ["niri", "msg", "-j", "workspaces"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let t = String(text || "").trim();
                if (!t)
                    return;
                try {
                    let arr = JSON.parse(t);
                    if (!Array.isArray(arr))
                        return;
                    root.niriRaw = arr;
                    let map = {};
                    for (let i = 0; i < arr.length; i++) {
                        let w = arr[i];
                        let idx = Number(w.idx);
                        if (!isFinite(idx))
                            continue;
                        if (!map[idx])
                            map[idx] = {
                                idx: idx,
                                is_focused: false,
                                is_active: false,
                                occupied: false,
                                output: w.output || ""
                            };
                        if (w.is_focused)
                            map[idx].is_focused = true;
                        if (w.is_active)
                            map[idx].is_active = true;
                        if (w.active_window_id !== null && w.active_window_id !== undefined)
                            map[idx].occupied = true;
                    }
                    let out = [];
                    for (let k in map)
                        out.push(map[k]);
                    for (let c = 1; c <= 5; c++)
                        if (!map[c])
                            out.push({
                                idx: c,
                                is_focused: false,
                                is_active: false,
                                occupied: false,
                                output: ""
                            });
                    out.sort((a, b) => a.idx - b.idx);
                    root.niriWorkspaces = out;
                } catch (e) {
                    console.warn("niri workspaces parse failed", e);
                }
            }
        }
    }

    Process {
        id: niriWindowsProc
        command: ["niri", "msg", "-j", "windows"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let t = String(text || "").trim();
                if (!t)
                    return;
                try {
                    let wins = JSON.parse(t);
                    if (!Array.isArray(wins))
                        return;
                    root.niriWindows = wins;

                    let occupiedSet = {};
                    for (let i = 0; i < wins.length; i++)
                        occupiedSet[wins[i].workspace_id] = true;

                    let idToIdx = {};
                    for (let i = 0; i < root.niriRaw.length; i++)
                        idToIdx[root.niriRaw[i].id] = root.niriRaw[i].idx;

                    let idxOccupied = {};
                    for (let id in occupiedSet) {
                        let idx = idToIdx[id];
                        if (idx !== undefined)
                            idxOccupied[idx] = true;
                    }

                    let cur = root.niriWorkspaces.slice();
                    for (let j = 0; j < cur.length; j++)
                        if (idxOccupied[cur[j].idx])
                            cur[j].occupied = true;
                    root.niriWorkspaces = cur;

                    // Active window title
                    let focused = null;
                    for (let i = 0; i < wins.length; i++)
                        if (wins[i] && wins[i].is_focused) {
                            focused = wins[i];
                            break;
                        }
                    if (focused) {
                        root.activeWindowTitle = String(focused.title || focused.app_id || "");
                        root.activeWindowAppId = String(focused.app_id || "");
                    } else {
                        let awId = null;
                        for (let i = 0; i < root.niriRaw.length; i++)
                            if (root.niriRaw[i].is_focused)
                                awId = root.niriRaw[i].active_window_id;
                        let found = null;
                        if (awId !== null)
                            for (let i = 0; i < wins.length; i++)
                                if (wins[i].id === awId)
                                    found = wins[i];
                        if (found) {
                            root.activeWindowTitle = String(found.title || found.app_id || "");
                            root.activeWindowAppId = String(found.app_id || "");
                        } else {
                            root.activeWindowTitle = "";
                            root.activeWindowAppId = "";
                        }
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: niriEventProc
        command: ["niri", "msg", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: function (line) {
                let s = String(line || "");
                if (s.indexOf("Workspace") !== -1 || s.indexOf("Window") !== -1) {
                    if (!niriProc.running)
                        niriProc.running = true;
                    if (!niriWindowsProc.running)
                        niriWindowsProc.running = true;
                }
            }
        }
    }

    Timer {
        id: niriPollTimer
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            if (!niriProc.running)
                niriProc.running = true;
            if (!niriWindowsProc.running)
                niriWindowsProc.running = true;
        }
    }

    Component.onCompleted: {
        niriProc.running = true;
        niriWindowsProc.running = true;
    }
}
