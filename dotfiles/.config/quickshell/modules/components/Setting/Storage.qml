import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import QtQuick.Controls

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 5

    readonly property var drive: ServiceStorage.rootDrive

    property real usedBytes: root.drive?.used ?? 0
    property real availBytes: root.drive?.avail ?? 0
    property real usedPct: root.drive?.pct ?? 0

    Behavior on usedBytes {
        NumberAnimation { duration: 850; easing.type: Easing.OutCubic }
    }
    Behavior on availBytes {
        NumberAnimation { duration: 850; easing.type: Easing.OutCubic }
    }
    Behavior on usedPct {
        NumberAnimation { duration: 850; easing.type: Easing.OutCubic }
    }

    Flickable {
        id: pageFlick
        ScrollBar.vertical: CustomScrollBar {}
        anchors.fill: parent
        contentHeight: column.implicitHeight
        contentWidth: width
        clip: true

        ColumnLayout {
            id: column
            width: parent.width
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors { leftMargin: 5; rightMargin: 5; topMargin: 5 }
            spacing: 0

            RowLayout {
                spacing: 10
                MaterialIconSymbol { content: "hard_drive"; iconSize: 20 }
                CustomText { content: "Storage"; size: 20; customColor: Colors.primary }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: rescanRow.implicitWidth + 26
                    implicitHeight: 34
                    radius: 17
                    color: ServiceStorage.mapScanning ? Colors.surfaceContainerHighest : Colors.primary

                    Behavior on color { EffectsColorAnim {} }
                    Behavior on implicitWidth { SpatialAnim { speed: "fast" } }

                    RowLayout {
                        id: rescanRow
                        anchors.centerIn: parent
                        spacing: 8

                        Item {
                            implicitWidth: 16
                            implicitHeight: 16

                            CustomCircularLoader {
                                anchors.centerIn: parent
                                size: 16
                                trackWidth: 2
                                highlightColor: Colors.primary
                                trackColor: Colors.surfaceContainerHigh
                                opacity: ServiceStorage.mapScanning ? 1 : 0
                                visible: opacity > 0
                                Behavior on opacity { EffectsAnim { speed: "fast" } }
                            }

                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: "refresh"
                                iconSize: 16
                                customColor: Colors.primaryText
                                opacity: ServiceStorage.mapScanning ? 0 : 1
                                visible: opacity > 0
                                rotation: ServiceStorage.mapScanning ? -120 : 0
                                Behavior on opacity { EffectsAnim { speed: "fast" } }
                                Behavior on rotation { SpatialAnim { speed: "fast" } }
                            }
                        }

                        CustomText {
                            content: ServiceStorage.mapScanning ? "Scanning" : "Rescan"
                            size: 13
                            customColor: ServiceStorage.mapScanning ? Colors.surfaceText : Colors.primaryText
                        }
                    }

                    RippleEffect {
                        anchors.fill: parent
                        radius: 17
                        enabled: !ServiceStorage.mapScanning
                        hoverColor: Qt.alpha(Colors.primaryText, 0.10)
                        rippleColor: Qt.alpha(Colors.primaryText, 0.24)
                        onClicked: ServiceStorage.rescan()
                    }
                }
            }

            // ── Overview ─────────────────────────────────────────
            CustomText { Layout.topMargin: 24; content: "Overview"; size: 13; customColor: Colors.primary }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            spacing: 2
                            RowLayout {
                                spacing: 6
                                CustomText {
                                    content: ServiceStorage.formatBytes(root.usedBytes)
                                    size: 30
                                    weight: 700
                                }
                                CustomText {
                                    Layout.alignment: Qt.AlignBottom
                                    Layout.bottomMargin: 5
                                    content: "of " + ServiceStorage.formatBytes(root.drive?.size ?? 0)
                                    size: 13
                                    customColor: Colors.outline
                                }
                            }
                            CustomText {
                                content: ServiceStorage.formatBytes(root.availBytes) + " free"
                                size: 12
                                customColor: Colors.outline
                            }
                        }

                        Item { Layout.fillWidth: true }

                        CustomText {
                            content: Math.round(root.usedPct * 100) + "%"
                            size: 26
                            weight: 700
                            customColor: root.usedPct > 0.9 ? Colors.error : Colors.primary
                        }
                    }

                    M3WavyProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        progress: root.usedPct
                        activeThickness: 24
                        trackThickness: 24
                        waveAmplitude: 0
                        showStopIndicator: true
                        stopSize: 5
                        activeColor: root.usedPct > 0.9 ? Colors.error : Colors.primary
                        trackColor: Colors.surfaceContainerHighest
                    }
                }
            }

            // ── Usage map ────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Usage Map"; size: 13; customColor: Colors.primary }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            implicitWidth: 32; implicitHeight: 32
                            radius: 16
                            color: Colors.surfaceContainerHighest
                            opacity: ServiceStorage.canGoUp ? 1 : 0.4
                            scale: ServiceStorage.canGoUp ? 1 : 0.9

                            Behavior on opacity { EffectsAnim { speed: "fast" } }
                            Behavior on scale { SpatialAnim { speed: "fast" } }

                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: "arrow_upward"
                                iconSize: 16
                                customColor: Colors.primary
                            }

                            RippleEffect {
                                anchors.fill: parent
                                radius: 16
                                enabled: ServiceStorage.canGoUp
                                onClicked: ServiceStorage.goUp()
                            }
                        }

                        Flickable {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            contentWidth: crumbRow.implicitWidth
                            contentHeight: height
                            clip: true
                            interactive: contentWidth > width

                            RowLayout {
                                id: crumbRow
                                height: 32
                                spacing: 2

                                Repeater {
                                    model: ServiceStorage.breadcrumb

                                    delegate: RowLayout {
                                        id: crumb
                                        required property var modelData
                                        required property int index
                                        spacing: 2

                                        readonly property bool last:
                                            crumb.index === ServiceStorage.breadcrumb.length - 1

                                        opacity: 0

                                        SequentialAnimation {
                                            running: true
                                            PauseAnimation {
                                                duration: Math.min(crumb.index, 8) * 26
                                            }
                                            EffectsAnim {
                                                target: crumb; property: "opacity"; to: 1
                                            }
                                        }

                                        MaterialIconSymbol {
                                            visible: crumb.index > 0
                                            content: "chevron_right"
                                            iconSize: 14
                                            customColor: Colors.outline
                                        }

                                        Rectangle {
                                            id: crumbPill
                                            implicitWidth: crumbText.implicitWidth + 16
                                            implicitHeight: 26
                                            radius: 13
                                            color: crumb.last ? Qt.alpha(Colors.primary, 0.16)
                                                 : crumbRipple.containsMouse ? Qt.alpha(Colors.primary, 0.07)
                                                 : "transparent"

                                            Behavior on color { EffectsColorAnim { speed: "fast" } }
                                            Behavior on implicitWidth { SpatialAnim { speed: "fast" } }

                                            CustomText {
                                                id: crumbText
                                                anchors.centerIn: parent
                                                content: crumb.modelData.label
                                                size: 12
                                                weight: crumb.last ? 700 : 500
                                                customColor: crumb.last ? Colors.primary : Colors.outline
                                            }

                                            RippleEffect {
                                                id: crumbRipple
                                                anchors.fill: parent
                                                radius: 13
                                                hoverColor: "transparent"
                                                onClicked: ServiceStorage.jumpTo(crumb.modelData.path)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: rootSwitch
                            implicitWidth: rootRow.implicitWidth + 22
                            implicitHeight: 32
                            radius: 16
                            color: Colors.surfaceContainerHighest

                            readonly property bool atHome:
                                ServiceStorage.currentPath === ServiceStorage.home

                            Behavior on implicitWidth { SpatialAnim { speed: "fast" } }

                            RowLayout {
                                id: rootRow
                                anchors.centerIn: parent
                                spacing: 6
                                MaterialIconSymbol {
                                    content: rootSwitch.atHome ? "hard_drive" : "home"
                                    iconSize: 15
                                    customColor: Colors.primary
                                }
                                CustomText {
                                    content: rootSwitch.atHome ? "Whole disk" : "Home"
                                    size: 12
                                    customColor: Colors.primary
                                }
                            }

                            RippleEffect {
                                anchors.fill: parent
                                radius: 16
                                onClicked: ServiceStorage.openRoot(
                                    rootSwitch.atHome ? "/" : ServiceStorage.home)
                            }
                        }

                        Rectangle {
                            implicitWidth: openRow.implicitWidth + 22
                            implicitHeight: 32
                            radius: 16
                            color: Colors.surfaceContainerHighest

                            RowLayout {
                                id: openRow
                                anchors.centerIn: parent
                                spacing: 6
                                MaterialIconSymbol {
                                    content: "folder_open"; iconSize: 15
                                    customColor: Colors.primary
                                }
                                CustomText {
                                    content: "Open"; size: 12
                                    customColor: Colors.primary
                                }
                            }

                            RippleEffect {
                                anchors.fill: parent
                                radius: 16
                                onClicked: ServiceStorage.openPath(ServiceStorage.currentPath)
                            }
                        }
                    }

                    StorageTreemap {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 380
                        items: ServiceStorage.children
                        busy: ServiceStorage.mapScanning
                        scanKey: ServiceStorage.currentPath
                        itemsKey: ServiceStorage.childrenPath
                        onDrill: name => ServiceStorage.drillInto(name)
                    }

                    CustomText {
                        Layout.fillWidth: true
                        content: ServiceStorage.children.length > 0
                            ? ServiceStorage.children.length + " items  ·  click a tile to go deeper"
                            : ""
                        size: 11
                        customColor: Colors.outline

                        opacity: content === "" ? 0 : 1
                        Behavior on opacity { EffectsAnim {} }
                    }
                }
            }

            // ── Drives ───────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Drives"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3

                Repeater {
                    model: ServiceStorage.drives

                    delegate: CustomCard {
                        id: driveCard
                        required property var modelData
                        required property int index

                        autoRadius: false
                        topRadius: driveCard.index === 0 ? 20 : 5
                        bottomRadius: driveCard.index === ServiceStorage.drives.length - 1 ? 20 : 5

                        opacity: 0

                        SequentialAnimation {
                            running: true
                            PauseAnimation { duration: Math.min(driveCard.index, 8) * 45 }
                            ParallelAnimation {
                                EffectsAnim { target: driveCard; property: "opacity"; to: 1 }
                                SpatialAnim {
                                    target: driveCard; property: "scale"
                                    from: 0.97; to: 1; speed: "fast"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Rectangle {
                                    implicitWidth: 38; implicitHeight: 38
                                    radius: driveArea.containsMouse ? 19 : 12
                                    color: Colors.surfaceContainerHighest

                                    Behavior on radius {
                                        NumberAnimation {
                                            duration: M3Motion.container.radiusDuration
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: M3Motion.container.curve
                                        }
                                    }

                                    MouseArea {
                                        id: driveArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }

                                    MaterialIconSymbol {
                                        anchors.centerIn: parent
                                        content: driveCard.modelData.target === "/" ? "hard_drive" : "sd_card"
                                        iconSize: 19
                                        customColor: Colors.primary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    CustomText { content: driveCard.modelData.target; size: 14 }
                                    CustomText {
                                        content: driveCard.modelData.source + "  ·  " + driveCard.modelData.fstype
                                        size: 12
                                        customColor: Colors.outline
                                    }
                                }

                                ColumnLayout {
                                    spacing: 2
                                    CustomText {
                                        Layout.alignment: Qt.AlignRight
                                        content: ServiceStorage.formatBytes(driveCard.modelData.used)
                                        size: 13
                                        weight: 600
                                    }
                                    CustomText {
                                        Layout.alignment: Qt.AlignRight
                                        content: "of " + ServiceStorage.formatBytes(driveCard.modelData.size)
                                        size: 11
                                        customColor: Colors.outline
                                    }
                                }
                            }

                            M3WavyProgressBar {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 12
                                progress: 0
                                activeThickness: 8
                                trackThickness: 8
                                waveAmplitude: 0
                                showStopIndicator: true
                                activeColor: driveCard.modelData.pct > 0.9 ? Colors.error : Colors.primary
                                trackColor: Colors.surfaceContainerHighest

                                Behavior on progress {
                                    NumberAnimation { duration: 850; easing.type: Easing.OutCubic }
                                }

                                Component.onCompleted: Qt.callLater(
                                    () => progress = driveCard.modelData.pct)
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
    ScrollFade {
        anchors.fill: parent
        flickable: pageFlick
    }
}
