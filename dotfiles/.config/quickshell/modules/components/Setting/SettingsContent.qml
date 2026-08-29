import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

Item {
    id: root
    anchors.fill: parent

    property int currentPage: firstPage
    signal settingClosed

    Connections {
        target: GlobalStates
        function onSettingsPageChanged() { root.currentPage = GlobalStates.settingsPage }

        // This Item is built once inside the FloatingWindow and only toggled via `visible`,
        // so the page has to be (re)selected on each open rather than at construction.
        function onSettingsOpenChanged() {
            if (GlobalStates.settingsOpen)
                root.currentPage = GlobalStates.settingsPage
            else
                GlobalStates.settingsPage = root.firstPage   // plain reopen lands on page one
        }
    }

    opacity: 0
    scale: 0.7

    NumberAnimation on opacity { from: 0; to: 1; duration: 200; running: true }
    NumberAnimation on scale   { from: 0.7; to: 1; duration: 100; running: true }

    // Section → page-index mapping
    readonly property var navSections: [
        { label: "System",  indices: [9, 0, 1, 2, 3, 10, 11] },
        { label: "Connect", indices: [4, 5] },
        { label: "Apps",    indices: [6, 7, 8] }
    ]

    // Whatever sits at the top of the sidebar — not necessarily page 0
    readonly property int firstPage: navSections[0].indices[0]

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Colors.surface

        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            radius: 20
            color: Colors.surfaceContainer

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ── Sidebar ──────────────────────────────────────
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 160
                    radius: 20
                    color: Colors.surfaceContainerHigh

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 0

                        // Original header — unchanged
                        CustomText {
                            content: "Nebula"
                            size: 22
                            weight: 700
                        }
                        CustomText {
                            content: "v0.2.0-beta"
                            size: 12
                            customColor: Colors.outline
                        }

                        Item { Layout.preferredHeight: 14 }

                        // ── Nav sections ──────────────────────────
                        Repeater {
                            model: root.navSections

                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                // Separator between sections (skip first)
                                Rectangle {
                                    visible: index !== 0
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4
                                    Layout.bottomMargin: 4
                                    implicitHeight: 1
                                    color: Colors.surfaceContainerHighest
                                }

                                // Items in this section
                                Repeater {
                                    model: modelData.indices

                                    delegate: Item {
                                        id: navDelegate
                                        readonly property int pageIndex: modelData
                                        readonly property bool active: root.currentPage === pageIndex
                                        readonly property var pageData: Settings.pages[pageIndex]
                                        Layout.fillWidth: true
                                        implicitWidth: parent ? parent.width : 0
                                        implicitHeight: 38

                                        // Active / hover background
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 10
                                            color: (navDelegate.active || navMouse.containsMouse)
                                                   ? Colors.primary
                                                   : "transparent"
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            scale: navDelegate.active ? 1.0 : 0.96
                                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            MaterialIconSymbol {
                                                content: navDelegate.pageData?.icon ?? ""
                                                iconSize: 18
                                                fill: navDelegate.active ? 1 : 0
                                                customColor: (navDelegate.active || navMouse.containsMouse) ? Colors.primaryText : Colors.surfaceVariantText
                                                Behavior on fill        { NumberAnimation { duration: 180 } }
                                                Behavior on customColor { ColorAnimation  { duration: 150 } }
                                            }

                                            CustomText {
                                                Layout.fillWidth: true
                                                content: navDelegate.pageData?.name ?? ""
                                                size: 15
                                                weight: navDelegate.active ? 700 : 500
                                                customColor: (navDelegate.active || navMouse.containsMouse) ? Colors.primaryText : Colors.surfaceVariantText
                                                Behavior on customColor { ColorAnimation { duration: 150 } }
                                            }
                                        }

                                        MouseArea {
                                            id: navMouse
                                            anchors.fill: parent
                                            cursorShape: GlobalStates.fileDialogOpen ? Qt.ArrowCursor : Qt.PointingHandCursor
                                            hoverEnabled: !GlobalStates.fileDialogOpen
                                            enabled: !GlobalStates.fileDialogOpen
                                            onClicked: root.currentPage = navDelegate.pageIndex
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Edit Config button
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            radius: 15
                            color: Colors.primary

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                MaterialIconSymbol {
                                    content: "edit"
                                    iconSize: 18
                                    customColor: Colors.primaryText
                                }
                                CustomText {
                                    content: "Edit Config"
                                    size: 14
                                    customColor: Colors.primaryText
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["kitty", "-e", "nvim",
                                    Quickshell.env("HOME") + "/.config/quickshell"])
                            }
                        }
                    }
                }

                // ── Content area ──────────────────────────────────
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    Loader { anchors.fill: parent; active: root.currentPage === 0; visible: active; opacity: active ? 1 : 0; scale: active ? 1 : 0.985; Behavior on opacity { NumberAnimation { duration: M3Motion.effects.defaultDuration } } Behavior on scale { NumberAnimation { duration: M3Motion.spatial.fastDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: M3Motion.spatial.fastCurve } } sourceComponent: Theme{} }
                    Loader { anchors.fill: parent; active: root.currentPage === 1; visible: active; opacity: active ? 1 : 0; scale: active ? 1 : 0.985; Behavior on opacity { NumberAnimation { duration: M3Motion.effects.defaultDuration } } Behavior on scale { NumberAnimation { duration: M3Motion.spatial.fastDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: M3Motion.spatial.fastCurve } } sourceComponent: Sound{} }
                    Loader { anchors.fill: parent; active: root.currentPage === 2; visible: active; opacity: active ? 1 : 0; scale: active ? 1 : 0.985; Behavior on opacity { NumberAnimation { duration: M3Motion.effects.defaultDuration } } Behavior on scale { NumberAnimation { duration: M3Motion.spatial.fastDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: M3Motion.spatial.fastCurve } } sourceComponent: Notifications{} }
                    Loader { anchors.fill: parent; active: root.currentPage === 3; visible: active; opacity: active ? 1 : 0; scale: active ? 1 : 0.985; Behavior on opacity { NumberAnimation { duration: M3Motion.effects.defaultDuration } } Behavior on scale { NumberAnimation { duration: M3Motion.spatial.fastDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: M3Motion.spatial.fastCurve } } sourceComponent: Widgets{} }
                    Loader { anchors.fill: parent; active: root.currentPage === 4; visible: active; opacity: active ? 1 : 0; scale: active ? 1 : 0.985; Behavior on opacity { NumberAnimation { duration: M3Motion.effects.defaultDuration } } Behavior on scale { NumberAnimation { duration: M3Motion.spatial.fastDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: M3Motion.spatial.fastCurve } } sourceComponent: Networking{} }
                    Loader { anchors.fill: parent; active: root.currentPage === 5; visible: active; opacity: active ? 1 : 0; scale: active ? 1 : 0.985; Behavior on opacity { NumberAnimation { duration: M3Motion.effects.defaultDuration } } Behavior on scale { NumberAnimation { duration: M3Motion.spatial.fastDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: M3Motion.spatial.fastCurve } } sourceComponent: Bluetooth{} }
                    Loader { anchors.fill: parent; active: root.currentPage === 6; visible: active; opacity: active ? 1 : 0; scale: active ? 1 : 0.985; Behavior on opacity { NumberAnimation { duration: M3Motion.effects.defaultDuration } } Behavior on scale { NumberAnimation { duration: M3Motion.spatial.fastDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: M3Motion.spatial.fastCurve } } sourceComponent: WeatherSettings{} }
                    Loader { anchors.fill: parent; active: root.currentPage === 7; visible: active; opacity: active ? 1 : 0; scale: active ? 1 : 0.985; Behavior on opacity { NumberAnimation { duration: M3Motion.effects.defaultDuration } } Behavior on scale { NumberAnimation { duration: M3Motion.spatial.fastDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: M3Motion.spatial.fastCurve } } sourceComponent: MediaSettings{} }
                    Loader { anchors.fill: parent; active: root.currentPage === 8; visible: active; opacity: active ? 1 : 0; scale: active ? 1 : 0.985; Behavior on opacity { NumberAnimation { duration: M3Motion.effects.defaultDuration } } Behavior on scale { NumberAnimation { duration: M3Motion.spatial.fastDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: M3Motion.spatial.fastCurve } } sourceComponent: About{} }
                    Loader { anchors.fill: parent; active: root.currentPage === 9; visible: active; opacity: active ? 1 : 0; scale: active ? 1 : 0.985; Behavior on opacity { NumberAnimation { duration: M3Motion.effects.defaultDuration } } Behavior on scale { NumberAnimation { duration: M3Motion.spatial.fastDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: M3Motion.spatial.fastCurve } } sourceComponent: AppearanceSettings{} }
                    Loader { anchors.fill: parent; active: root.currentPage === 10; visible: active; opacity: active ? 1 : 0; scale: active ? 1 : 0.985; Behavior on opacity { NumberAnimation { duration: M3Motion.effects.defaultDuration } } Behavior on scale { NumberAnimation { duration: M3Motion.spatial.fastDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: M3Motion.spatial.fastCurve } } sourceComponent: Sleep{} }
                    Loader { anchors.fill: parent; active: root.currentPage === 11; visible: active; opacity: active ? 1 : 0; scale: active ? 1 : 0.985; Behavior on opacity { NumberAnimation { duration: M3Motion.effects.defaultDuration } } Behavior on scale { NumberAnimation { duration: M3Motion.spatial.fastDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: M3Motion.spatial.fastCurve } } sourceComponent: Storage{} }

                }
            }

        }
    }
}
