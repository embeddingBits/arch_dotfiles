pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// hypridle honours logind idle inhibitors unless ignore_systemd_inhibit is set
// in its config, and ServiceIdle never writes that key — so holding a single
// systemd-inhibit lock is enough to suppress dim, lock and DPMS together.
// The lock lives for exactly as long as the child process does, so there is no
// stale state to clean up if the shell dies.
Singleton {
    id: root

    property bool active: false

    onActiveChanged: inhibitProc.running = root.active

    Process {
        id: inhibitProc
        command: ["systemd-inhibit",
                  "--what=idle:sleep",
                  "--who=Nebula shell",
                  "--why=Keep awake",
                  "--mode=block",
                  "sleep", "infinity"]
        onExited: root.active = false
    }

    function toggle() { root.active = !root.active }
}
