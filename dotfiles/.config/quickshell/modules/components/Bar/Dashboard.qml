import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.settings
import qs.modules.components.Bar.DashboardSections
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MatrialShapeFn

Item{
    id: root
    anchors.fill: parent

    implicitHeight: col.implicitHeight
    property string panelMode: ""   // "" | "wifi" | "bluetooth" | "modes"
    property bool   compact:   false

    property var parentPos
    property var wifiPos
    property var bluetoothPos
    property var pos
    property var srcSize: null
    property real srcRadius: 20


    readonly property bool isPill: SettingsConfig.general.barMode === "pill"

    readonly property int morphOpen: M3Motion.spatial.slowDuration
    readonly property int morphClose: M3Motion.spatial.defaultDuration

    property string activeMode: ""
    property bool panelVisible: false

    onPanelModeChanged: {
        closeTimer.stop()
        contentTimer.stop()
        if (root.panelMode !== "") {
            root.activeMode = root.panelMode
            root.panelVisible = true
            contentTimer.restart()
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: root.morphClose
        onTriggered: {
            panelLoader.active = false
            root.panelVisible = false
            root.activeMode = ""
        }
    }

    opacity: 0
    scale: root.isPill ? 1 : 0.8

    NumberAnimation on opacity {
        from: 0; to: 1; duration: 400; running: true
    }

    NumberAnimation on scale {
        from: root.isPill ? 1 : 0.8
        to: 1
        duration: 400
        running: true
    }


    Connections {
        target: ServiceNetwork
        function onWifiEnabledChanged() {
            SettingsConfig.toggles = Object.assign({}, SettingsConfig.toggles, { airplaneMode: !ServiceNetwork.wifiEnabled })
        }
    }

    Connections {
        target: ServicePipewire
        function onMutedChanged() {
            SettingsConfig.toggles = Object.assign({}, SettingsConfig.toggles, { speakerMuted: ServicePipewire.muted })
        }
        function onMicMutedChanged() {
            SettingsConfig.toggles = Object.assign({}, SettingsConfig.toggles, { micMuted: ServicePipewire.micMuted })
        }
    }




    // Overlay backdrop — fades in/out independently
    Rectangle {
        id: overlayBackdrop
        anchors.fill: parent
        z: 1
        radius: 20
        color: Qt.alpha(Colors.surface, 0.7)
        opacity: root.panelMode !== "" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation {
                duration: root.panelMode !== "" ? root.morphOpen : root.morphClose
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3Motion.effects.curve
            }
        }
    }

    // Panel container — persistent so states/transitions actually animate
    Rectangle {
        id: container
        z: 2
        enabled: root.panelMode !== ""

        x: root.pos ? root.pos.x : 0
        y: root.pos ? root.pos.y : 0
        width:  root.srcSize ? root.srcSize.width  : (root.controlsItem?.width ?? 300)
        height: root.srcSize ? root.srcSize.height : 60
        radius: root.srcRadius
        opacity: {
            if (!root.panelVisible) return 0
            if (root.panelMode !== "") return 1
            const srcH = root.srcSize ? root.srcSize.height : 60
            const band = Math.max(40, srcH)
            return Math.max(0, Math.min(1, (container.height - srcH) / band))
        }
        visible: opacity > 0.01

        color: Colors.surfaceContainerHigh
        clip: true

        states: [
            State {
                name: "wifi"
                when: root.panelMode === "wifi"
                PropertyChanges {
                    target: container
                    x: root.parentPos ? root.parentPos.x : 0
                    y: root.parentPos ? root.parentPos.y : 0
                    width: (root.controlsItem?.width ?? 300)
                    height: (root.controlsItem?.height ?? 60) + 400
                    radius: 20
                }
            },
            State {
                name: "modes"
                when: root.panelMode === "modes"
                PropertyChanges {
                    target: container
                    x: root.parentPos ? root.parentPos.x : 0
                    y: root.parentPos ? root.parentPos.y : 0
                    width: (root.controlsItem?.width ?? 300)
                    height: 310
                    radius: 20
                }
            },
            State {
                name: "bluetooth"
                when: root.panelMode === "bluetooth"
                PropertyChanges {
                    target: container
                    x: root.parentPos ? root.parentPos.x : 0
                    y: root.parentPos ? root.parentPos.y : 0
                    width: (root.controlsItem?.width ?? 300)
                    height: (root.controlsItem?.height ?? 60) + 400
                    radius: 20
                }
            }
        ]

        transitions: [
            Transition {
                to: ""
                SpatialAnim {
                    properties: "x,y,width,height,radius"
                    speed: "default"
                }
            },
            Transition {
                SpatialAnim {
                    properties: "x,y,width,height,radius"
                    speed: "slow"
                }
            }
        ]

        Timer {
            id: contentTimer
            interval: root.morphOpen * 0.6
            onTriggered: if (root.panelMode !== "") panelLoader.active = true
        }

        Loader {
            id: panelLoader
            active: false
            anchors.fill: parent
            opacity: (root.panelMode !== "" && active) ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { EffectsAnim { speed: "default" } }
            sourceComponent: root.activeMode === "wifi" ? wifiComponent
                : root.activeMode === "bluetooth" ? bluetoothComponent
                : root.activeMode === "modes" ? modesComponent
                : null
        }

        Component {
            id: wifiComponent
            Wifi { onBackClicked: root.panelMode = "" }
        }

        Component {
            id: modesComponent
            ModesPanel { onBackClicked: root.panelMode = "" }
        }

        Component {
            id: bluetoothComponent
            Bluetooth { onBackClicked: root.panelMode = "" }
        }
    }

    NumberAnimation on opacity{
        from: 0
        to: 1
        duration: 200
        running: true
    }


    signal toggleDashboard
    property bool active: false//hoverHandler.hovered

    onActiveChanged:{
        if(!active) root.toggleDashboard()
    }


    // HoverHandler{
    //     id: hoverHandler
    // }

    // ── Sections ──────────────────────────────────────────────────────────
    // Order and visibility both come from SettingsConfig.dashboard. Sections
    // report their size through implicitHeight rather than Layout attachments,
    // because a Loader can pass a size up but not a Layout attached property.
    readonly property var defaultOrder: [
        "profile", "controls", "quickActions", "notifications", "calendar"
    ]

    readonly property var sectionOrder: {
        const saved = SettingsConfig.dashboard?.order
        if (!Array.isArray(saved) || saved.length === 0) return root.defaultOrder
        // Tolerate a stale saved order: drop keys that no longer exist and
        // append any section added since it was written.
        const known = saved.filter(k => root.defaultOrder.indexOf(k) !== -1)
        const missing = root.defaultOrder.filter(k => known.indexOf(k) === -1)
        return known.concat(missing)
    }

    function shows(key) {
        return SettingsConfig.dashboard?.[key] ?? true
    }

    // The wifi/bluetooth overlay sizes itself from the controls section, so the
    // driver has to hand back a reference the Loader would otherwise hide.
    property Item controlsItem: null

    Component { id: cProfile
        DashProfile { compact: root.compact; onToggleDashboard: root.toggleDashboard() } }

    Component { id: cControls
        DashControls {
            compact: root.compact
            coordSpace: root
            panelMode: root.panelMode
            onToggleDashboard: root.toggleDashboard()
            Component.onCompleted: root.controlsItem = this
            Component.onDestruction: if (root.controlsItem === this) root.controlsItem = null
            onOpenPanel: function(mode, pPos, p, sz, r) {
                root.parentPos = pPos
                root.pos = p
                root.srcSize = sz
                root.srcRadius = r
                root.panelMode = mode
            }
        } }

    Component { id: cQuickActions;  DashQuickActions  { compact: root.compact } }
    Component { id: cNotifications; DashNotifications { compact: root.compact } }
    Component { id: cCalendar;      DashCalendar      { compact: root.compact } }

    function componentFor(key) {
        switch (key) {
            case "profile":       return cProfile
            case "controls":      return cControls
            case "quickActions":  return cQuickActions
            case "notifications": return cNotifications
            case "calendar":      return cCalendar
        }
        return null
    }

    ColumnLayout{
        id: col
        anchors.fill: parent
        spacing:         root.compact ? 7 : 10
        anchors.margins: root.compact ? 7 : 10

        Repeater {
            model: root.sectionOrder

            delegate: Loader {
                required property string modelData

                active:  root.shows(modelData)
                visible: active          // an inactive Loader still takes space
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 0
                Layout.fillHeight: modelData === "notifications"
                Layout.minimumHeight: modelData === "notifications" ? 120 : 0
                sourceComponent: root.componentFor(modelData)
            }
        }

    }
}
