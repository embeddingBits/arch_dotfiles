import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt.labs.platform
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

WelcomeTile {
    id: tile

    icon: "person"
    title: "YOU"

    readonly property string avatar: SettingsConfig.general.profile ?? ""

    FileDialog {
        id: imagePicker
        title: "Select a profile image"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.webp *.gif)"]
        onAccepted: {
            SettingsConfig.general = Object.assign({}, SettingsConfig.general, {
                profile: imagePicker.file.toString().replace(/^file:\/\//, "")
            })
            GlobalStates.fileDialogOpen = false
        }
        onRejected: GlobalStates.fileDialogOpen = false
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        Item {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 52

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Colors.surfaceContainerHigh

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    visible: tile.avatar === ""
                    content: "add_a_photo"
                    iconSize: 20
                    customColor: Colors.outline
                }
            }

            Item {
                id: avatarMask
                anchors.fill: parent
                visible: false
                layer.enabled: true

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "black"
                }
            }

            Image {
                id: avatarImage
                anchors.fill: parent
                source: tile.avatar
                sourceSize: Qt.size(160, 160)
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                visible: false
                layer.enabled: true
            }

            MultiEffect {
                anchors.fill: avatarImage
                source: avatarImage
                visible: tile.avatar !== ""
                maskEnabled: true
                maskSource: avatarMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    GlobalStates.fileDialogOpen = true
                    imagePicker.open()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            CustomText {
                content: tile.avatar === "" ? "Add a picture" : "Picture set"
                size: 14
            }

            CustomText {
                Layout.fillWidth: true
                content: "Dashboard, overview and lock screen"
                size: 12
                customColor: Colors.outline
                wrapMode: Text.WordWrap
            }
        }

        M3Button {
            visible: tile.avatar !== ""
            size: "xsmall"
            variant: "text"
            label: "Remove"
            onClicked: SettingsConfig.general = Object.assign({}, SettingsConfig.general, { profile: "" })
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        spacing: 10

        CustomText { content: "Font"; size: 12; customColor: Colors.outline }

        CustomListNew {
            Layout.preferredWidth: 170
            Layout.preferredHeight: 30
            color: Colors.surfaceContainerHighest
            list: Settings.fonts
            Component.onCompleted: currentVal = SettingsConfig.general.defaultFont
            onCurrentValChanged: {
                if (!currentVal || currentVal === SettingsConfig.general.defaultFont) return
                SettingsConfig.general = Object.assign({}, SettingsConfig.general, { defaultFont: currentVal })
            }
        }

        Item { Layout.fillWidth: true }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        CustomText { content: "Size"; size: 12; customColor: Colors.outline }

        M3ButtonGroup {
            Layout.preferredWidth: 240
            Layout.preferredHeight: 30
            fillWidth: true
            model: [
                { value: "compact", label: "Compact" },
                { value: "normal",  label: "Normal"  },
                { value: "large",   label: "Large"   }
            ]
            activeCheck: v => (SettingsConfig.general.fontScale ?? "normal") === v
            onSegmentClicked: v => SettingsConfig.general = Object.assign({}, SettingsConfig.general, { fontScale: v })
        }

        Item { Layout.fillWidth: true }
    }
}
