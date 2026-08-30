import QtQuick
import Quickshell.Io

Item {
    id: root

    property real memUsedGB: 0
    property real memTotalGB: 0
    property string memUsedText: memUsedGB.toFixed(1) + "G"
    property string memTooltip: {
        if (memTotalGB > 0)
            return "RAM: " + memUsedGB.toFixed(1) + " / " + memTotalGB.toFixed(1) + " GB  (" + Math.round(memUsedGB / memTotalGB * 100) + "%)";
        return "RAM: " + memUsedText;
    }

    function refresh() {
        if (!memProc.running)
            memProc.running = true;
    }

    Process {
        id: memProc
        command: ["bash", "-c", "awk '/MemTotal:/{t=$2} /MemAvailable:/{a=$2} END{printf \"%.0f %.0f\", (t-a), t}' /proc/meminfo"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let s = String(text || "").trim();
                if (!s)
                    return;
                let parts = s.split(/\s+/);
                if (parts.length >= 2) {
                    let usedKB = Number(parts[0]);
                    let totalKB = Number(parts[1]);
                    if (isFinite(usedKB) && isFinite(totalKB) && totalKB > 0) {
                        root.memUsedGB = usedKB / 1024 / 1024;
                        root.memTotalGB = totalKB / 1024 / 1024;
                    }
                }
            }
        }
    }

    Timer {
        id: memPollTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: if (!memProc.running)
            memProc.running = true
    }

    Component.onCompleted: memProc.running = true
}
