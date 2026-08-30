import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../../config/Theme.qml" as Theme

PanelWindow {
    id: bar

    required property var niriService
    required property var calendarService
    required property var memoryService

    // Popup state — owned by root, injected
    required property bool calendarOpen
    required property bool volumePopupOpen
    required property bool wifiPopupOpen
    required property bool bluetoothPopupOpen

    signal toggleCalendar
    signal toggleVolume
    signal toggleWifi
    signal toggleBluetooth

    anchors {
        left: true
        right: true
        top: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.bg

    // ── Background + bottom separator ──
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        border.color: "transparent"
        border.width: 0

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.25)
        }
    }

    Item {
        id: barContent
        anchors.fill: parent
        anchors.leftMargin: Theme.barPadding
        anchors.rightMargin: Theme.barPadding

        // ── Left section ──
        RowLayout {
            id: leftSection
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            MenuButton {}

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 18
                color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.35)
                opacity: 0.6
            }

            Workspaces {
                niriService: bar.niriService
            }

            Rectangle {
                visible: activeWindowItem.visible
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.35)
                opacity: 0.6
            }

            ActiveWindow {
                id: activeWindowItem
                niriService: bar.niriService
            }
        }

        // ── Center section ──
        CenterClock {
            id: centerClock
            anchors.centerIn: parent
            calendarOpen: bar.calendarOpen
            calendarService: bar.calendarService
            onToggleCalendar: bar.toggleCalendar()
        }

        // ── Right section ──
        RowLayout {
            id: rightSection
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            SystemTrayWidget {}

            // Audio — needs wrapper to provide Layout props when using Item root
            Item {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 26

                AudioWidget {
                    anchors.fill: parent
                    volumePopupOpen: bar.volumePopupOpen
                    onToggleVolume: bar.toggleVolume()
                }
            }

            Item {
                Layout.preferredWidth: 78
                Layout.preferredHeight: 26

                MemoryWidget {
                    anchors.fill: parent
                    memoryService: bar.memoryService
                }
            }

            NetworkWidget {
                wifiPopupOpen: bar.wifiPopupOpen
                onToggleWifi: bar.toggleWifi()
            }

            BluetoothWidget {
                bluetoothPopupOpen: bar.bluetoothPopupOpen
                onToggleBluetooth: bar.toggleBluetooth()
            }

            BatteryWidget {}

            PowerButton {}
        }
    }
}
