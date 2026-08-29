import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents
import qs.modules.services

Item {
    id: root

    property var group: null

    property int index: 0
    property int listDragIndex: -1
    property real listDragDistance: 0
    property real dismissThreshold: 80
    property bool dragSettling: true
    property var dismissTarget: null
    property real clipBottomAmount: 0

    signal dragBegan(int i)
    signal expandRequested(int i)
    signal dragMoved(real d)
    signal dragCancelled
    signal dragDismissed(bool toRight)

    readonly property bool dismissing: root.dismissTarget !== null
        && root.dismissTarget === root.group

    readonly property var notifs: root.group?.notifications ?? []
    readonly property int count: root.notifs.length
    readonly property bool multiple: root.count > 1
    readonly property var latest: root.count > 0 ? root.notifs[root.count - 1] : null

    readonly property int pad: 12
    readonly property int vPad: 10
    readonly property int outerRadius: 20
    readonly property int innerRadius: 0
    readonly property int childIndent: root.pad + 36 + 10
    readonly property int seam: 3
    readonly property int collapsedChildren: 2

    property int childDragIndex: -1
    property real childDragDistance: 0
    property var childDismissTarget: null
    readonly property bool childDragActive: root.childDragIndex >= 0
    readonly property real childDismissThreshold: Math.max(60, root.width * 0.3)

    function beginChildDrag(i) { if (!childFling.running) root.childDragIndex = i }
    function updateChildDrag(d) { if (!childFling.running) root.childDragDistance = d }
    function endChildDrag() {
        if (childFling.running) return
        root.childDragIndex = -1
        root.childDragDistance = 0
    }
    function flingChild(i, item, toRight) {
        root.childDragIndex = i
        root.childDismissTarget = item
        childFling.to = toRight ? root.width + 48 : -(root.width + 48)
        childFling.restart()
    }

    NumberAnimation {
        id: childFling
        target: root
        property: "childDragDistance"
        duration: Appearance.motion.spatialFast
        easing.type: Easing.InCubic
        onFinished: {
            const target = root.childDismissTarget
            root.childDismissTarget = null
            root.childDragDistance = 0
            root.childDragIndex = -1
            if (target) ServiceNotification.removeNotification(target)
        }
    }

    property bool expanded: root.group?.isExpanded ?? false

    property real unfoldRaw: 0
    readonly property real unfold: Math.max(0, Math.min(1, root.unfoldRaw))
    readonly property bool unfolding: expandAnim.running
    readonly property bool seamsOpen: root.expanded && !root.unfolding

    readonly property real cardHeight:
        Math.max(0, stack.implicitHeight - root.clipBottomAmount)

    onExpandedChanged: {
        if (root.group) root.group.isExpanded = root.expanded
        expandAnim.to = root.expanded ? 1 : 0
        expandAnim.restart()
        if (root.expanded) root.expandRequested(root.index)
    }

    onMultipleChanged: if (!root.multiple) root.expanded = false

    NumberAnimation {
        id: expandAnim
        target: root
        property: "unfoldRaw"
        duration: M3Motion.container.duration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: M3Motion.container.curve
    }

    Component.onCompleted: root.unfoldRaw = root.expanded ? 1 : 0

    readonly property int dragDiff: Math.abs(root.listDragIndex - root.index)
    readonly property real xOffset: {
        if (root.dismissing) return root.listDragDistance
        if (root.listDragIndex < 0) return 0
        const d = root.listDragDistance
        if (root.dragDiff === 0) return d
        if (Math.abs(d) > root.dismissThreshold) return 0
        if (root.dragDiff === 1) return d * 0.3
        if (root.dragDiff === 2) return d * 0.1
        return 0
    }

    property string relativeTime: root.computeRelative(root.latest?.arrivalTimestamp ?? Date.now())

    function computeRelative(ts) {
        var diff = Date.now() - ts
        var mins = Math.floor(diff / 60000)
        if (mins < 1)  return "now"
        if (mins < 60) return mins + "m"
        var hrs = Math.floor(mins / 60)
        if (hrs < 24)  return hrs + "h"
        return Math.floor(hrs / 24) + "d"
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.relativeTime = root.computeRelative(root.latest?.arrivalTimestamp ?? Date.now())
    }

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

    readonly property string symbol: root.resolveSymbol(root.group?.appIcon, root.group?.appName)
    readonly property bool usesSymbol: root.symbol !== ""

    implicitHeight: stack.implicitHeight

    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: !root.expanded
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        property real pressX: 0
        property bool dragging: false

        onPressed: event => {
            if (event.button === Qt.MiddleButton) {
                root.dragDismissed(true)
                return
            }
            dragArea.pressX = event.x
            dragArea.dragging = false
        }

        onPositionChanged: event => {
            if (!dragArea.pressed) return
            const d = event.x - dragArea.pressX
            if (!dragArea.dragging) {
                if (Math.abs(d) < 6) return
                dragArea.dragging = true
                root.dragBegan(root.index)
            }
            root.dragMoved(d)
        }

        onReleased: event => {
            const d = event.x - dragArea.pressX
            if (dragArea.dragging) {
                dragArea.dragging = false
                if (Math.abs(d) > root.dismissThreshold)
                    root.dragDismissed(d > 0)
                else
                    root.dragCancelled()
            } else if (event.button === Qt.LeftButton && dragArea.containsMouse && root.multiple) {
                root.expanded = true
            }
        }

        onCanceled: {
            if (dragArea.dragging) {
                dragArea.dragging = false
                root.dragCancelled()
            }
        }
    }

    Item {
        id: swipe
        y: 0
        width: root.width
        height: root.cardHeight
        clip: root.clipBottomAmount > 0.5
        x: root.xOffset

        Behavior on x {
            enabled: root.dragSettling
            SpringAnimation {
                spring: Appearance.motion.swipeSpring
                damping: Appearance.motion.swipeDamping
                mass: Appearance.motion.swipeMass
                epsilon: 0.4
            }
        }

        opacity: 1 - Math.min(1, Math.abs(swipe.x) / (root.width || 1))

        Rectangle {
            id: groupCard
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: root.cardHeight
            radius: root.outerRadius
            color: Colors.surfaceContainerHigh
            visible: !root.seamsOpen
        }

        ColumnLayout {
            id: stack
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 0

            Rectangle {
                visible: !root.multiple
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? loneRow.implicitHeight + 2 * root.vPad : 0
                color: "transparent"
                radius: root.outerRadius
                clip: true

                NotificationRow {
                    id: loneRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: root.pad
                    anchors.rightMargin: root.pad
                    anchors.topMargin: root.vPad
                    notifData: root.latest
                    showIcon: true
                    showAppName: true
                    interactive: false
                }
            }

            Rectangle {
                id: headerSeg
                visible: root.multiple
                Layout.fillWidth: true
                Layout.preferredHeight: visible
                    ? Math.round(root.vPad + headerRow.implicitHeight + root.vPad * root.unfold)
                    : 0
                color: root.seamsOpen ? Colors.surfaceContainerHigh : "transparent"
                clip: true

                readonly property real bottomR: (root.childDragActive && root.childDragIndex === 0)
                    ? root.outerRadius : root.innerRadius

                topLeftRadius: root.outerRadius
                topRightRadius: root.outerRadius
                bottomLeftRadius: headerSeg.bottomR
                bottomRightRadius: headerSeg.bottomR
                Behavior on bottomLeftRadius { NumberAnimation { duration: M3Motion.effects.fastDuration } }
                Behavior on bottomRightRadius { NumberAnimation { duration: M3Motion.effects.fastDuration } }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.expanded
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expanded = false
                }

                RowLayout {
                    id: headerRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: root.pad
                    anchors.rightMargin: root.pad
                    anchors.topMargin: root.vPad
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: root.usesSymbol ? Colors.primaryContainer
                                               : Qt.alpha(Colors.primary, 0.12)

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: root.symbol
                            iconSize: 19
                            customColor: Colors.primaryContainerText
                            visible: root.usesSymbol
                        }

                        Image {
                            id: groupIcon
                            anchors.fill: parent
                            anchors.margins: 6
                            source: root.usesSymbol ? "" : IconUtil.getIconPath(root.group?.appIcon ?? "")
                            sourceSize: Qt.size(24, 24)
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                            visible: !root.usesSymbol && status === Image.Ready
                        }

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: "notifications"
                            iconSize: 17
                            customColor: Colors.primaryContainerText
                            visible: !root.usesSymbol && groupIcon.status !== Image.Ready
                        }
                    }

                    CustomText {
                        Layout.maximumWidth: 150
                        content: root.group?.appName ?? ""
                        size: 11
                        weight: 500
                        customColor: Colors.outline
                        elide: Text.ElideRight
                    }

                    CustomText {
                        content: "·"
                        size: 11
                        customColor: Colors.outline
                    }

                    CustomText {
                        content: root.relativeTime
                        size: 11
                        customColor: Colors.outline
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: chipRow.implicitWidth + 14
                        implicitHeight: 24
                        radius: 12
                        color: Colors.surfaceContainerHighest

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 1

                            CustomText {
                                content: root.count.toString()
                                size: 11
                                weight: 700
                                customColor: Colors.surfaceVariantText
                            }

                            MaterialIconSymbol {
                                content: "keyboard_arrow_down"
                                iconSize: 15
                                customColor: Colors.surfaceVariantText
                                rotation: 180 * root.unfold
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.expanded = !root.expanded
                        }
                    }
                }
            }

            Repeater {
                id: childRepeater
                model: ScriptModel {
                    values: root.multiple ? root.notifs.slice().reverse() : []
                }

                delegate: Item {
                    id: childSlot
                    required property var modelData
                    required property int index

                    readonly property bool isLast: childSlot.index === childRepeater.count - 1
                    readonly property bool overflow: childSlot.index >= root.collapsedChildren

                    readonly property real fullHeight: childRow.implicitHeight + 2 * root.vPad
                    readonly property real collapsedHeight: childSlot.overflow
                        ? 0 : compactRow.implicitHeight

                    Layout.fillWidth: true
                    Layout.topMargin: Math.round(root.seam * (childSlot.overflow ? root.unfold : 1))
                    Layout.preferredHeight: Math.round(childSlot.collapsedHeight
                        + (childSlot.fullHeight - childSlot.collapsedHeight) * root.unfold)

                    readonly property bool isDragged: root.childDragActive
                        && root.childDragIndex === childSlot.index
                    readonly property bool draggedAbove: root.childDragActive
                        && root.childDragIndex === childSlot.index - 1
                    readonly property bool draggedBelow: root.childDragActive
                        && root.childDragIndex === childSlot.index + 1
                    readonly property int dragDiff: Math.abs(root.childDragIndex - childSlot.index)
                    readonly property bool dismissing: root.childDismissTarget !== null
                        && root.childDismissTarget === childSlot.modelData

                    readonly property real xOffset: {
                        if (childSlot.dismissing) return root.childDragDistance
                        if (root.childDragIndex < 0) return 0
                        const d = root.childDragDistance
                        if (childSlot.dragDiff === 0) return d
                        if (Math.abs(d) > root.childDismissThreshold) return 0
                        if (childSlot.dragDiff === 1) return d * 0.3
                        if (childSlot.dragDiff === 2) return d * 0.1
                        return 0
                    }

                    readonly property real cornerTop:
                        (childSlot.isDragged || childSlot.draggedAbove) ? root.outerRadius : root.innerRadius
                    readonly property real cornerBottom:
                        (childSlot.isLast || childSlot.isDragged || childSlot.draggedBelow)
                            ? root.outerRadius : root.innerRadius

                    MouseArea {
                        id: childDragArea
                        anchors.fill: parent
                        enabled: root.expanded
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                        property real pressX: 0
                        property bool dragging: false

                        onPressed: event => {
                            if (event.button === Qt.MiddleButton) {
                                root.flingChild(childSlot.index, childSlot.modelData, true)
                                return
                            }
                            childDragArea.pressX = event.x
                            childDragArea.dragging = false
                        }
                        onPositionChanged: event => {
                            if (!childDragArea.pressed) return
                            const d = event.x - childDragArea.pressX
                            if (!childDragArea.dragging) {
                                if (Math.abs(d) < 6) return
                                childDragArea.dragging = true
                                root.beginChildDrag(childSlot.index)
                            }
                            root.updateChildDrag(d)
                        }
                        onReleased: event => {
                            const d = event.x - childDragArea.pressX
                            if (childDragArea.dragging) {
                                childDragArea.dragging = false
                                if (Math.abs(d) > root.childDismissThreshold)
                                    root.flingChild(childSlot.index, childSlot.modelData, d > 0)
                                else
                                    root.endChildDrag()
                            } else if (event.button === Qt.LeftButton && childDragArea.containsMouse) {
                                childRow.isExtended = !childRow.isExtended
                            }
                        }
                        onCanceled: {
                            if (childDragArea.dragging) {
                                childDragArea.dragging = false
                                root.endChildDrag()
                            }
                        }
                    }

                    Rectangle {
                        id: childBg
                        y: 0
                        x: childSlot.xOffset
                        width: parent.width
                        height: parent.height
                        clip: true
                        color: root.seamsOpen ? Colors.surfaceContainerHigh : "transparent"

                        topLeftRadius: childSlot.cornerTop
                        topRightRadius: childSlot.cornerTop
                        bottomLeftRadius: childSlot.cornerBottom
                        bottomRightRadius: childSlot.cornerBottom
                        Behavior on topLeftRadius { NumberAnimation { duration: M3Motion.effects.fastDuration } }
                        Behavior on topRightRadius { NumberAnimation { duration: M3Motion.effects.fastDuration } }
                        Behavior on bottomLeftRadius { NumberAnimation { duration: M3Motion.effects.fastDuration } }
                        Behavior on bottomRightRadius { NumberAnimation { duration: M3Motion.effects.fastDuration } }

                        Behavior on x {
                            enabled: !root.childDragActive
                            SpringAnimation {
                                spring: Appearance.motion.swipeSpring
                                damping: Appearance.motion.swipeDamping
                                mass: Appearance.motion.swipeMass
                                epsilon: 0.4
                            }
                        }

                        opacity: 1 - Math.min(1, Math.abs(childBg.x) / (root.width || 1))

                        RowLayout {
                            id: compactRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: root.childIndent
                            anchors.rightMargin: root.pad
                            spacing: 5
                            visible: !childSlot.overflow
                            opacity: 1 - root.unfold

                            CustomText {
                                content: childSlot.modelData?.summary ?? ""
                                size: 12
                                weight: 700
                                elide: Text.ElideRight
                            }

                            CustomText {
                                Layout.fillWidth: true
                                content: (childSlot.modelData?.body ?? "").replace(/\s+/g, " ")
                                size: 12
                                customColor: Colors.outline
                                elide: Text.ElideRight
                            }
                        }

                        NotificationRow {
                            id: childRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: root.pad
                            anchors.rightMargin: root.pad
                            anchors.topMargin: root.vPad
                            enabled: root.seamsOpen
                            opacity: root.unfold
                            notifData: childSlot.modelData
                            showIcon: false
                            reserveIconColumn: true
                            showAppName: false
                            interactive: false
                        }
                    }
                }
            }

            Item {
                visible: root.multiple
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? Math.round(root.vPad * (1 - root.unfold)) : 0
            }
        }
    }
}
