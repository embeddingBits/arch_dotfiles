import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import Qt.labs.platform

Rectangle {
    id: root

    implicitWidth: parent.width
    anchors.bottom: parent.bottom
    color: Settings.layoutColor
    topLeftRadius: 20
    topRightRadius: 20

    signal closed

    function human(bytes) {
        return ServiceFileDrop.humanSize(bytes)
    }

    function baseName(path) {
        const parts = (path ?? "").split("/")
        return parts[parts.length - 1]
    }

    FileDialog {
        id: sendPicker
        title: "Share with phone"
        fileMode: FileDialog.OpenFiles
        onAccepted: {
            const paths = []
            for (const f of sendPicker.files)
                paths.push(f.toString().replace("file://", ""))
            ServiceFileDrop.share(paths)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MaterialIconSymbol {
                content: "phonelink"
                iconSize: 20
                customColor: Colors.primary
            }

            CustomText {
                content: "Nebula Drop"
                size: 16
                weight: 700
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: statusRow.implicitWidth + 18
                implicitHeight: 24
                radius: 12
                color: ServiceFileDrop.peer !== "" ? Colors.primaryContainer
                                                   : Colors.surfaceContainerHigh

                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        implicitWidth: 7; implicitHeight: 7; radius: 4
                        color: ServiceFileDrop.running ? Colors.primary : Colors.outline
                    }

                    CustomText {
                        content: !ServiceFileDrop.running ? "off"
                            : ServiceFileDrop.peer !== "" ? ServiceFileDrop.peer
                            : "waiting"
                        size: 11
                        weight: 600
                        customColor: ServiceFileDrop.peer !== "" ? Colors.primaryContainerText
                                                                 : Colors.outline
                    }
                }
            }

            Rectangle {
                implicitWidth: 28; implicitHeight: 28; radius: 14
                color: closeArea.containsMouse ? Colors.surfaceContainerHighest : "transparent"

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "close"
                    iconSize: 17
                    customColor: Colors.outline
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closed()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 168
                Layout.preferredHeight: 168
                radius: 20
                color: "white"

                Image {
                    id: qrImage
                    anchors.centerIn: parent
                    width: 148
                    height: 148
                    sourceSize: Qt.size(148, 148)
                    asynchronous: true
                    smooth: false
                    visible: ServiceFileDrop.url !== "" && status === Image.Ready
                    source: ServiceFileDrop.url === "" ? ""
                        : "file://" + ServiceFileDrop.qrPath + "?v=" + ServiceFileDrop.qrRevision
                }

                CustomText {
                    anchors.centerIn: parent
                    visible: !qrImage.visible
                    content: ServiceFileDrop.running ? "starting…" : "off"
                    size: 12
                    customColor: "#555555"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 8

                CustomText {
                    Layout.fillWidth: true
                    content: ServiceFileDrop.running
                        ? "Scan with your phone's camera while on the same Wi-Fi. Closing this panel keeps the link alive — use Shut down to end it."
                        : "Start a session to get a link your phone can open."
                    size: 12
                    customColor: Colors.outline
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 12
                    color: Colors.surfaceContainerHigh

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 8

                        CustomText {
                            Layout.fillWidth: true
                            content: ServiceFileDrop.url !== "" ? ServiceFileDrop.url : "—"
                            size: 12
                            weight: 600
                            elide: Text.ElideMiddle
                        }

                        Rectangle {
                            implicitWidth: 26; implicitHeight: 26; radius: 13
                            color: copyArea.containsMouse ? Colors.surfaceContainerHighest : "transparent"
                            visible: ServiceFileDrop.url !== ""

                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: root.copied ? "check" : "content_copy"
                                iconSize: 15
                                customColor: root.copied ? Colors.primary : Colors.outline
                            }

                            MouseArea {
                                id: copyArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.clipboardText = ServiceFileDrop.url
                                    root.copied = true
                                    copyReset.restart()
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    M3Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        size: "xsmall"
                        variant: "tonal"
                        icon: "attach_file"
                        label: "Add files"
                        onClicked: sendPicker.open()
                    }

                    M3Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        size: "xsmall"
                        variant: ServiceFileDrop.running ? "outlined" : "filled"
                        icon: ServiceFileDrop.running ? "power_settings_new" : "play_arrow"
                        label: ServiceFileDrop.running ? "Shut down" : "Start"
                        onClicked: ServiceFileDrop.toggle()
                    }
                }

                CustomText {
                    Layout.fillWidth: true
                    visible: ServiceFileDrop.error !== ""
                    content: ServiceFileDrop.error
                    size: 11
                    customColor: Colors.error ?? Colors.primary
                    wrapMode: Text.WordWrap
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 8

            CustomText {
                content: ServiceFileDrop.shared.length > 0 ? "Offered to phone" : "Received"
                size: 12
                customColor: Colors.primary
            }

            Item { Layout.fillWidth: true }

            CustomText {
                visible: ServiceFileDrop.shared.length > 0
                content: "Clear"
                size: 11
                customColor: Colors.outline

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ServiceFileDrop.clearShared()
                }
            }
        }

        ListView {
            id: feed
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds

            model: {
                const out = []
                for (const p of ServiceFileDrop.shared)
                    out.push({ kind: "offer", name: root.baseName(p), path: p, size: 0 })
                for (const t of ServiceFileDrop.transfers)
                    out.push(t)
                return out
            }

            delegate: Rectangle {
                required property var modelData

                width: feed.width
                height: 44
                radius: 12
                color: Colors.surfaceContainerHigh

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 10

                    MaterialIconSymbol {
                        content: modelData.kind === "in" ? "download"
                               : modelData.kind === "out" ? "upload" : "attach_file"
                        iconSize: 17
                        customColor: modelData.kind === "in" ? Colors.primary : Colors.outline
                    }

                    CustomText {
                        Layout.fillWidth: true
                        content: modelData.name ?? ""
                        size: 12
                        weight: 600
                        elide: Text.ElideMiddle
                    }

                    CustomText {
                        content: root.human(modelData.size)
                        size: 11
                        customColor: Colors.outline
                    }

                    Rectangle {
                        implicitWidth: 24; implicitHeight: 24; radius: 12
                        color: "transparent"
                        visible: modelData.kind === "offer" || modelData.kind === "in"

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: modelData.kind === "offer" ? "close" : "folder_open"
                            iconSize: 15
                            customColor: Colors.outline
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.kind === "offer")
                                    ServiceFileDrop.unshare(modelData.path)
                                else
                                    Quickshell.execDetached(["xdg-open", ServiceFileDrop.saveDir])
                            }
                        }
                    }
                }
            }
        }

        CustomText {
            Layout.fillWidth: true
            visible: feed.count === 0
            content: "Files your phone sends land in " + ServiceFileDrop.saveDir
            size: 11
            customColor: Colors.outline
            elide: Text.ElideMiddle
        }
    }

    property bool copied: false

    Timer {
        id: copyReset
        interval: 1400
        onTriggered: root.copied = false
    }

    DropArea {
        anchors.fill: parent
        keys: ["text/uri-list"]
        onDropped: drop => {
            const paths = []
            for (const u of drop.urls)
                paths.push(u.toString().replace("file://", ""))
            ServiceFileDrop.share(paths)
            drop.accept()
        }
    }
}
