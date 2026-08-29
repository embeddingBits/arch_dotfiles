import Quickshell
import QtQuick
import QtQuick.Layouts
import Qt.labs.platform
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents
import QtQuick.Controls

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 5

    FileDialog {
        id: notifSoundPicker
        title: "Select a notification sound file"
        nameFilters: ["WAV files (*.wav)"]
        onAccepted: {
            const path = notifSoundPicker.file.toString().replace(/^file:\/\//, "")
            SettingsConfig.notifications = Object.assign({}, SettingsConfig.notifications, { soundPath: path })
            GlobalStates.fileDialogOpen = false
        }
        onRejected: GlobalStates.fileDialogOpen = false
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
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            anchors.topMargin: 5
            spacing: 0

            // ── Page header ──────────────────────────────────────────────
            RowLayout {
                spacing: 10
                MaterialIconSymbol { content: "notifications"; iconSize: 20 }
                CustomText { content: "Notifications"; size: 20; customColor: Colors.primary }
            }

            // ── Focus ────────────────────────────────────────────────────
            CustomText { Layout.topMargin: 24; content: "Focus"; size: 13; customColor: Colors.primary }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Do Not Disturb"; size: 14 }
                        CustomText { content: "Suppress all notification popups"; size: 12; customColor: Colors.outline }
                    }
                    Item { Layout.fillWidth: true }
                    CustomToogle {
                        isToggleOn: SettingsConfig.notifications?.doNotDisturb ?? false
                        onToggled: function(state) {
                            SettingsConfig.notifications = Object.assign({}, SettingsConfig.notifications, { doNotDisturb: state })
                        }
                    }
                }
            }

            // ── Popups ───────────────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Popups"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Show Banners"; size: 14 }
                            CustomText { content: "Display popup banners for new notifications"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomToogle {
                            isToggleOn: SettingsConfig.notifications?.showBanners ?? true
                            onToggled: function(state) {
                                SettingsConfig.notifications = Object.assign({}, SettingsConfig.notifications, { showBanners: state })
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Popup Timeout"; size: 14 }
                            CustomText { content: "Seconds before a banner auto-dismisses"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomSpinBox {
                            color: Colors.surfaceContainerHighest
                            inc: 1
                            limit: 30
                            Component.onCompleted: val = SettingsConfig.notifications?.popupTimeout ?? 5
                            onValChanged: {
                                if (val > 0)
                                    SettingsConfig.notifications = Object.assign({}, SettingsConfig.notifications, { popupTimeout: val })
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 20
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Max Visible"; size: 14 }
                            CustomText { content: "Maximum number of banners shown at once"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomSpinBox {
                            color: Colors.surfaceContainerHighest
                            inc: 1
                            limit: 5
                            Component.onCompleted: val = SettingsConfig.notifications?.maxVisible ?? 3
                            onValChanged: {
                                if (val > 0)
                                    SettingsConfig.notifications = Object.assign({}, SettingsConfig.notifications, { maxVisible: val })
                            }
                        }
                    }
                }
            }

            // ── Notification Center ──────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Notification Center"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Show in Center"; size: 14 }
                            CustomText { content: "Store notifications in the notification center"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomToogle {
                            isToggleOn: SettingsConfig.notifications?.showInCenter ?? true
                            onToggled: function(state) {
                                SettingsConfig.notifications = Object.assign({}, SettingsConfig.notifications, { showInCenter: state })
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5
                    bottomRadius: (SettingsConfig.notifications?.playSound ?? false) ? 5 : 20
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Play Sound"; size: 14 }
                            CustomText { content: "Play a sound when a notification arrives"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomToogle {
                            isToggleOn: SettingsConfig.notifications?.playSound ?? false
                            onToggled: function(state) {
                                SettingsConfig.notifications = Object.assign({}, SettingsConfig.notifications, { playSound: state })
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 20
                    visible: SettingsConfig.notifications?.playSound ?? false
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Sound File"; size: 14 }
                            CustomText { content: "WAV file only (uncompressed PCM)"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        RowLayout {
                            spacing: 4
                            Rectangle {
                                implicitHeight: 32; implicitWidth: 180
                                topLeftRadius: 16; bottomLeftRadius: 16
                                topRightRadius: 6;  bottomRightRadius: 6
                                color: Colors.surfaceContainerHighest
                                clip: true
                                CustomText {
                                    anchors.left: parent.left; anchors.leftMargin: 12
                                    anchors.right: parent.right; anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    content: (SettingsConfig.notifications?.soundPath ?? "") === ""
                                             ? "No file selected"
                                             : SettingsConfig.notifications.soundPath.split("/").pop()
                                    size: 11
                                    customColor: (SettingsConfig.notifications?.soundPath ?? "") === "" ? Colors.outline : Colors.surfaceText
                                    elide: Text.ElideLeft
                                }
                            }
                            M3IconButton {
                                implicitHeight: 32; implicitWidth: 40
                                topLeftRadius: 6;   bottomLeftRadius: 6
                                topRightRadius: 16; bottomRightRadius: 16
                                icon: "audio_file"; iconSize: 18
                                onClicked: {
                                    GlobalStates.fileDialogOpen = true
                                    notifSoundPicker.open()
                                }
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
