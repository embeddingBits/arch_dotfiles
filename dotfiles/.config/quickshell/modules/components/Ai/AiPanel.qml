pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.services

Scope {
    id: scope

    GlobalShortcut {
        name: "ai"
        onPressed: ServiceAi.toggle()
    }

    GlobalShortcut {
        name: "aiHistory"
        onPressed: {
            ServiceAi.show()
            ServiceAi.openHistory()
        }
    }
}
