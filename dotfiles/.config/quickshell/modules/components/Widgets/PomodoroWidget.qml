import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

WidgetHost {
    id: root
    configKey: "pomodoro"
    defaultPos: Qt.point(400, 120)
    implicitWidth: 200
    implicitHeight: 234

    // ── Timer state ────────────────────────────────────────────────────
    property bool isWorking: true
    property bool running: false
    property int sessionsCompleted: 0    // 0–4 per cycle

    readonly property int workSecs:  25 * 60
    readonly property int shortSecs:  5 * 60
    readonly property int longSecs:  15 * 60

    property int timeRemaining: workSecs

    readonly property int totalTime: isWorking ? workSecs
        : (sessionsCompleted >= 4 ? longSecs : shortSecs)

    readonly property real progress: timeRemaining / totalTime

    readonly property color modeColor: {
        if (!isWorking) return Qt.color(Colors.tertiary)
        if (timeRemaining < 60) return Qt.color(Colors.error)
        return Qt.color(Colors.primary)
    }

    readonly property string modeLabel: isWorking ? "FOCUS"
        : (sessionsCompleted >= 4 ? "Long Break" : "Break")

    function formatTime(secs) {
        var m = Math.floor(secs / 60)
        var s = secs % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    // ── Countdown ─────────────────────────────────────────────────────
    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (root.timeRemaining > 0) { root.timeRemaining--; return }
            root.running = false
            if (root.isWorking) {
                root.sessionsCompleted = Math.min(root.sessionsCompleted + 1, 4)
                root.isWorking = false
                root.timeRemaining = root.sessionsCompleted >= 4 ? root.longSecs : root.shortSecs
            } else {
                if (root.sessionsCompleted >= 4) root.sessionsCompleted = 0
                root.isWorking = true
                root.timeRemaining = root.workSecs
            }
        }
    }

    // ── Position save ──────────────────────────────────────────────────

    // ── Drag / edit ────────────────────────────────────────────────────

    // ── Background ─────────────────────────────────────────────────────
    Rectangle { anchors.fill: parent; radius: 24; color: Colors.surface }

    // ── Arc + center content ───────────────────────────────────────────
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 14
        width: 164; height: 164

        CustomGaugeProgress {
            anchors.fill: parent
            progress: root.progress
            thickness: 12
            gap: 0.35
            showData: false
            lineColor: root.modeColor
            baseColor: Colors.surfaceContainerHighest
        }

        Column {
            anchors.centerIn: parent
            spacing: -4

            CustomText {
                anchors.horizontalCenter: parent.horizontalCenter
                content: root.modeLabel
                size: 11; weight: 600; customColor: Colors.outline
            }

            CustomText {
                anchors.horizontalCenter: parent.horizontalCenter
                content: root.formatTime(root.timeRemaining)
                size: 38; weight: 700; customColor: root.modeColor
                font.family: SettingsConfig.general.displayFont ?? "Titan One"
            }
        }
    }

    // ── Session dots ───────────────────────────────────────────────────
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: btnRow.top
        anchors.bottomMargin: 10
        spacing: 8

        Repeater {
            model: 4
            Rectangle {
                width: 8; height: 8; radius: 4
                color: index < root.sessionsCompleted ? root.modeColor : Colors.surfaceContainerHighest
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }
    }

    // ── Button group ───────────────────────────────────────────────────
    // Two segments: Reset (left, icon-only) | Play/Pause (right, icon+label)
    // Built manually so the play icon/label can be reactive without Repeater
    // flicker. Styled identically to the ButtonGroup component.
    Item {
        id: btnRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        width: 174; height: 42

        readonly property real r: height / 2   // full pill radius
        readonly property real ir: 4            // inner join radius
        readonly property real gap: 2
        readonly property real leftW: 54

        // ── Reset segment ───────────────────────────────────────────
        Rectangle {
            id: resetSeg
            x: 0; y: 0
            width: btnRow.leftW; height: btnRow.height
            topLeftRadius:     btnRow.r;  bottomLeftRadius:  btnRow.r
            topRightRadius:    btnRow.ir; bottomRightRadius: btnRow.ir
            color: resetRipple.containsMouse ? Qt.darker(Colors.surfaceContainerHighest, 1.05)
                                             : Colors.surfaceContainerHighest
            Behavior on color { ColorAnimation { duration: 150 } }

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: "refresh"; iconSize: 20
                customColor: Colors.outline
            }

            RippleEffect {
                id: resetRipple
                anchors.fill: parent
                topLeftRadius:     btnRow.r;  bottomLeftRadius:  btnRow.r
                topRightRadius:    btnRow.ir; bottomRightRadius: btnRow.ir
                hoverColor:  Qt.alpha(Colors.primary, 0.08)
                rippleColor: Qt.alpha(Colors.primary, 0.22)
                onClicked: { root.running = false; root.timeRemaining = root.totalTime }
            }
        }

        // ── Play/Pause segment ──────────────────────────────────────
        Rectangle {
            id: playSeg
            x: btnRow.leftW + btnRow.gap; y: 0
            width: btnRow.width - btnRow.leftW - btnRow.gap; height: btnRow.height
            topLeftRadius:    btnRow.ir; bottomLeftRadius:  btnRow.ir
            topRightRadius:   btnRow.r;  bottomRightRadius: btnRow.r
            color: root.running
                ? Qt.rgba(root.modeColor.r, root.modeColor.g, root.modeColor.b, 0.22)
                : Colors.surfaceContainerHighest
            Behavior on color { ColorAnimation { duration: 200 } }

            Row {
                anchors.centerIn: parent
                spacing: 6

                MaterialIconSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    content: root.running ? "pause" : "play_arrow"
                    iconSize: 20
                    customColor: root.running ? root.modeColor : Colors.surfaceText
                    Behavior on customColor { ColorAnimation { duration: 200 } }
                }

                CustomText {
                    anchors.verticalCenter: parent.verticalCenter
                    content: root.running ? "Pause" : "Start"
                    size: 13; weight: 600
                    customColor: root.running ? root.modeColor : Colors.surfaceText
                    Behavior on customColor { ColorAnimation { duration: 200 } }
                }
            }

            RippleEffect {
                anchors.fill: parent
                topLeftRadius:    btnRow.ir; bottomLeftRadius:  btnRow.ir
                topRightRadius:   btnRow.r;  bottomRightRadius: btnRow.r
                hoverColor:  Qt.alpha(root.modeColor, 0.10)
                rippleColor: Qt.alpha(root.modeColor, 0.28)
                onClicked: root.running = !root.running
            }
        }
    }
}
