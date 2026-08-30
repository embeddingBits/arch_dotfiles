.pragma library

function groupedRunningApps(niriWindows) {
    var map = {};
    var order = [];

    for (var i = 0; i < niriWindows.length; i++) {
        var w = niriWindows[i];
        if (!w)
            continue;

        var rawAid = String(w.app_id || w.appId || "unknown");
        if (rawAid === "" || rawAid === "unknown")
            rawAid = w.title ? String(w.title).split(" ")[0] : "unknown";

        var low = rawAid.toLowerCase();
        var key = low;
        var displayId = rawAid;

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

        var ts = 0;
        if (w.focus_timestamp) {
            var s = Number(w.focus_timestamp.secs) || 0;
            var n = Number(w.focus_timestamp.nanos) || 0;
            ts = s * 1000000000 + n;
        }
        if (ts > map[key].lastFocused)
            map[key].lastFocused = ts;
    }

    var out = [];
    for (var k = 0; k < order.length; k++)
        out.push(map[order[k]]);

    out.sort(function (a, b) {
        return b.lastFocused - a.lastFocused;
    });
    return out;
}

function filteredRunningApps(grouped, allowedAppIds) {
    var filtered = [];
    for (var i = 0; i < grouped.length; i++) {
        var entry = grouped[i];
        var low = String(entry.appId || "").toLowerCase();
        for (var j = 0; j < allowedAppIds.length; j++) {
            if (low.indexOf(allowedAppIds[j]) !== -1) {
                filtered.push(entry);
                break;
            }
        }
    }
    return filtered;
}
