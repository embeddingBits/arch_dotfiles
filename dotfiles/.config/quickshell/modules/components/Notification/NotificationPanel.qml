import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    implicitWidth: 380
    anchors.right: parent.right
    anchors.bottom: parent.bottom

    readonly property int panelMargin: 10
    readonly property int peek: 10
    readonly property int fanGap: 8
    readonly property int stackHeight: 560

    readonly property int maxVisible:
        Math.max(1, SettingsConfig.notifications?.maxVisible ?? 3)

    readonly property int exitDuration:
        Appearance.motion.effectsFast + Appearance.motion.spatialFast + 60

    readonly property var livePopups: {
        const all = [...ServiceNotification.popups].reverse()
        return all.slice(0, root.maxVisible)
    }

    property var exitQueue: []
    property var prevLive: []

    onLivePopupsChanged: {
        const live = root.livePopups
        const now = Date.now()
        const add = []
        for (var i = 0; i < root.prevLive.length; i++) {
            const it = root.prevLive[i]
            if (live.indexOf(it) < 0 && !root.exitQueue.some(e => e.item === it))
                add.push({ item: it, t: now })
        }
        if (add.length > 0)
            root.exitQueue = root.exitQueue.concat(add)
        root.prevLive = live.slice()
    }

    function isExiting(item) {
        if (!item)
            return false
        return root.exitQueue.some(e => e.item === item)
    }

    Timer {
        interval: 60
        repeat: true
        running: root.exitQueue.length > 0
        onTriggered: {
            const now = Date.now()
            const keep = root.exitQueue.filter(e => now - e.t < root.exitDuration)
            if (keep.length !== root.exitQueue.length)
                root.exitQueue = keep
        }
    }

    readonly property var visiblePopups: {
        const out = root.livePopups.slice()
        for (var i = 0; i < root.exitQueue.length; i++) {
            const it = root.exitQueue[i].item
            if (out.indexOf(it) < 0)
                out.push(it)
        }
        out.sort((a, b) => (b.arrivalTimestamp ?? 0) - (a.arrivalTimestamp ?? 0))
        return out
    }

    property bool expanded: hoverArea.containsMouse

    property real fanProgress: root.expanded ? 1 : 0
    Behavior on fanProgress {
        NumberAnimation {
            duration: Appearance.motion.spatialDefault
            easing.type: Appearance.motion.sizeEasing
        }
    }

    implicitHeight: list.count > 0
        ? Math.min(root.stackHeight, list.contentHeight + 2 * root.panelMargin)
        : 0

    Binding {
        target: ServiceNotification
        property: "popupsPaused"
        value: hoverArea.containsMouse && list.count > 0
    }

    Item {
        id: innerItem
        width: root.implicitWidth
        height: root.stackHeight
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: root.panelMargin
            orientation: Qt.Vertical
            verticalLayoutDirection: ListView.BottomToTop
            model: ScriptModel { values: root.visiblePopups }
            spacing: 0
            interactive: false
            clip: false
            cacheBuffer: 2000

            property bool populated: false
            Component.onCompleted: populateTimer.start()
            Timer {
                id: populateTimer
                interval: 260
                onTriggered: list.populated = true
            }

            add: Transition {
                enabled: list.populated
                ParallelAnimation {
                    SpatialAnim {
                        property: "x"
                        from: list.width
                        to: 0
                    }
                    EffectsAnim {
                        property: "opacity"
                        from: 0
                        to: 1
                    }
                }
            }

            delegate: Item {
                id: slot
                required property var modelData
                required property int index

                property var notif: null
                onModelDataChanged: if (modelData) slot.notif = modelData

                property bool removing: false
                property real collapseFactor: 1
                property int lastDepth: 0

                readonly property int depth: slot.removing
                    ? slot.lastDepth
                    : slot.index
                readonly property bool front: slot.depth === 0

                onDepthChanged: if (!slot.removing) slot.lastDepth = slot.depth
                Component.onCompleted: {
                    slot.notif = slot.modelData
                    slot.lastDepth = slot.depth
                }

                width: list.width
                z: 100 - slot.index

                readonly property real collapsedHeight:
                    slot.front ? card.implicitHeight : root.peek
                readonly property real fannedHeight:
                    card.implicitHeight + (slot.front ? 0 : root.fanGap)

                readonly property real baseHeight: slot.collapsedHeight
                    + (slot.fannedHeight - slot.collapsedHeight) * root.fanProgress

                height: slot.baseHeight * slot.collapseFactor

                readonly property bool exiting: root.isExiting(slot.notif)
                onExitingChanged: if (slot.exiting) removeAnimation.start()

                SequentialAnimation {
                    id: removeAnimation
                    PropertyAction { target: slot; property: "removing"; value: true }
                    ParallelAnimation {
                        NumberAnimation {
                            target: card
                            property: "x"
                            to: slot.width + 24
                            duration: Appearance.motion.spatialFast
                            easing.type: Easing.InCubic
                        }
                        EffectsAnim {
                            target: card
                            property: "opacity"
                            to: 0
                        }
                        SequentialAnimation {
                            PauseAnimation { duration: Appearance.motion.effectsFast }
                            NumberAnimation {
                                target: slot
                                property: "collapseFactor"
                                to: 0
                                duration: Appearance.motion.spatialFast
                                easing.type: Appearance.motion.sizeEasing
                            }
                        }
                    }
                }

                Rectangle {
                    id: card
                    x: 0
                    y: 0
                    width: slot.width
                    implicitHeight: row.implicitHeight + 24
                    height: card.implicitHeight
                    radius: 18
                    color: Colors.surfaceContainerHigh

                    transformOrigin: Item.Top
                    scale: 1 - 0.035 * slot.depth * (1 - root.fanProgress)
                    opacity: 1 - 0.25 * slot.depth * (1 - root.fanProgress)

                    Behavior on scale {
                        EffectsAnim {}
                    }

                    Behavior on opacity {
                        EffectsAnim {}
                    }

                    RowLayout {
                        id: row
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        anchors.topMargin: 12
                        spacing: 12

                        Rectangle {
                            id: iconRect
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            Layout.alignment: Qt.AlignTop
                            radius: 12

                            function resolveSymbol(appIcon, appName) {
                                const ic = (appIcon || "").toLowerCase()
                                const ap = (appName || "").toLowerCase()
                                if (ic.includes("camera-photo") || ap.includes("screenshot")) return "photo_camera"
                                if (ic.includes("camera-video") || ap.includes("record"))     return "screen_record"
                                if (ic.includes("dialog-error") || ic.includes("error"))      return "error_outline"
                                if (ic.includes("bluetooth"))                                  return "bluetooth"
                                if (ic.includes("network") || ic.includes("wifi"))            return "wifi"
                                if (ic.includes("battery"))                                    return "battery_std"
                                if (ic.includes("volume") || ic.includes("audio"))            return "volume_up"
                                return ""
                            }

                            readonly property string symbol: iconRect.resolveSymbol(slot.notif?.appIcon, slot.notif?.appName)
                            readonly property bool usesSymbol: iconRect.symbol !== ""

                            color: iconRect.usesSymbol ? Colors.primaryContainer : Qt.alpha(Colors.primary, 0.12)

                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: iconRect.symbol
                                iconSize: 22
                                customColor: Colors.primaryContainerText
                                visible: iconRect.usesSymbol
                            }

                            Image {
                                id: panelIcon
                                anchors.fill: parent
                                anchors.margins: 7
                                source: iconRect.usesSymbol ? "" : IconUtil.getIconPath(slot.notif?.appIcon ?? "")
                                sourceSize.width: 88
                                sourceSize.height: 88
                                fillMode: Image.PreserveAspectFit
                                visible: !iconRect.usesSymbol && status === Image.Ready
                            }

                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: "notifications"
                                iconSize: 20
                                customColor: Colors.primaryContainerText
                                visible: !iconRect.usesSymbol && panelIcon.status !== Image.Ready
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout {
                                spacing: 4
                                visible: (slot.notif?.appName ?? "").length > 0

                                CustomText {
                                    content: slot.notif?.appName ?? ""
                                    size: 11
                                    weight: 600
                                    color: Colors.primary
                                }

                                CustomText {
                                    content: "·"
                                    size: 10
                                    color: Colors.outline
                                }

                                CustomText {
                                    content: {
                                        var diff = Date.now() - (slot.notif?.arrivalTimestamp ?? Date.now())
                                        var mins = Math.floor(diff / 60000)
                                        if (mins < 1)  return "now"
                                        if (mins < 60) return mins + "m ago"
                                        return Math.floor(mins / 60) + "h ago"
                                    }
                                    size: 10
                                    color: Colors.outline
                                }
                            }

                            CustomText {
                                Layout.fillWidth: true
                                content: slot.notif?.summary ?? ""
                                size: 14
                                weight: 700
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: slot.notif?.body ?? ""
                                font.pixelSize: 13
                                font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                                color: Colors.outline
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                visible: (slot.notif?.body ?? "").length > 0
                                bottomPadding: 2
                            }
                        }

                        Loader {
                            active: !!slot.notif?.image
                            visible: active
                            Layout.preferredHeight: 52
                            Layout.preferredWidth: 52
                            Layout.alignment: Qt.AlignVCenter
                            sourceComponent: Rectangle {
                                radius: 10
                                clip: true
                                color: "transparent"
                                Image {
                                    anchors.fill: parent
                                    source: slot.notif?.image ?? ""
                                    sourceSize.width: 104
                                    sourceSize.height: 104
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: 100
    }
}
