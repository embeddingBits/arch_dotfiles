import Quickshell
import Quickshell.Io
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

    property var info: ({})

    readonly property string home: Quickshell.env("HOME") ?? ""
    readonly property string shellDir: Quickshell.shellDir ?? ""
    readonly property string prettyDir: root.home !== "" && root.shellDir.startsWith(root.home)
        ? "~" + root.shellDir.slice(root.home.length) : root.shellDir

    readonly property var links: [
        { icon: "code",       label: "GitHub",       url: "https://github.com/iamSt3el/Nebula" },
        { icon: "bug_report", label: "Report issue", url: "https://github.com/iamSt3el/Nebula/issues/new" },
        { icon: "star",       label: "Star",         url: "https://github.com/iamSt3el/Nebula" }
    ]

    function shown(v) {
        return (v === undefined || v === null || v === "") ? "—" : v
    }

    readonly property var envRows: [
        { label: "Quickshell", value: root.shown(root.info.quickshell), copyable: false },
        { label: "Compositor", value: root.shown(root.info.compositor), copyable: false },
        { label: "Kernel",     value: root.shown(root.info.kernel),     copyable: false },
        { label: "Distro",     value: root.shown(root.info.distro),     copyable: false }
    ]

    readonly property var configRows: [
        { label: "Location", value: root.shown(root.prettyDir),         copyable: true },
        { label: "Revision", value: root.shown(root.info.revision),     copyable: true },
        { label: "Uptime",   value: root.shown(ServiceSystemInfo.uptime), copyable: false }
    ]

    Process {
        id: infoProcess
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/about_info.sh", root.shellDir]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.info = JSON.parse(text)
                } catch (e) {
                    root.info = ({})
                }
            }
        }
    }

    Component.onCompleted: {
        infoProcess.running = true
        ServiceSystemInfo.getUptime()
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
            spacing: 3

            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 5
                implicitHeight: 84
                radius: 20
                color: Colors.surfaceContainerHigh

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 52
                        Layout.alignment: Qt.AlignVCenter
                        radius: 16
                        color: Colors.primaryContainer

                        Image {
                            anchors.centerIn: parent
                            width: 32; height: 32
                            sourceSize.width: 32
                            sourceSize.height: 32
                            source: IconUtil.getSystemIconPng("nebula")
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 3

                        RowLayout {
                            spacing: 8
                            CustomText {
                                content: "Nebula"; size: 20; weight: 700
                                customColor: Colors.primary
                            }
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: _ver.implicitWidth + 18
                                implicitHeight: 21
                                radius: 11
                                color: Colors.primaryContainer
                                CustomText {
                                    id: _ver
                                    anchors.centerIn: parent
                                    content: "v0.2.0-beta"; size: 10; weight: 600
                                    customColor: Colors.primary
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }

                        CustomText {
                            Layout.fillWidth: true
                            content: "A modern desktop shell for Wayland"
                            size: 12; customColor: Colors.outline
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            CustomText {
                Layout.topMargin: 24
                Layout.leftMargin: 5
                content: "Environment"
                size: 13
                customColor: Colors.primary
            }

            Repeater {
                model: root.envRows
                delegate: InfoRow {
                    required property var modelData
                    required property int index
                    row: modelData
                    first: index === 0
                    last: index === root.envRows.length - 1
                }
            }

            CustomText {
                Layout.topMargin: 16
                Layout.leftMargin: 5
                content: "Config"
                size: 13
                customColor: Colors.primary
            }

            Repeater {
                model: root.configRows
                delegate: InfoRow {
                    required property var modelData
                    required property int index
                    row: modelData
                    first: index === 0
                    last: index === root.configRows.length - 1
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.leftMargin: 5
                Layout.rightMargin: 5
                Layout.bottomMargin: 5
                spacing: 8

                Repeater {
                    model: root.links
                    delegate: M3Button {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        size: "xsmall"
                        variant: "tonal"
                        icon: modelData.icon
                        label: modelData.label
                        onClicked: Quickshell.execDetached(["xdg-open", modelData.url])
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 5
                Layout.rightMargin: 5
                Layout.bottomMargin: 5
                spacing: 8

                M3Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    size: "xsmall"
                    variant: "outlined"
                    icon: "restart_alt"
                    label: "Run setup again"
                    onClicked: {
                        GlobalStates.settingsOpen = false
                        GlobalStates.welcomeOpen = true
                    }
                }

                M3Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    size: "xsmall"
                    variant: "outlined"
                    icon: "refresh"
                    label: "Restart shell"
                    onClicked: Quickshell.reload(true)
                }
            }
        }
    }
    ScrollFade {
        anchors.fill: parent
        flickable: pageFlick
    }

    component InfoRow: CustomCard {
        id: card

        property var row: ({})
        property bool first: false
        property bool last: false
        property bool copied: false

        Layout.leftMargin: 5
        Layout.rightMargin: 5
        autoRadius: false
        topRadius: card.first ? 20 : 5
        bottomRadius: card.last ? 20 : 5
        implicitHeight: 48

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            CustomText {
                content: card.row.label ?? ""
                size: 12
                customColor: Colors.outline
            }

            CustomText {
                Layout.fillWidth: true
                content: card.row.value ?? ""
                size: 13
                weight: 600
                customColor: Colors.surfaceText
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideMiddle
            }

            Item {
                visible: card.row.copyable === true
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: card.copied ? "check" : "content_copy"
                    iconSize: 16
                    customColor: card.copied ? Colors.primary : Colors.outline
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -7
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.clipboardText = card.row.value ?? ""
                        card.copied = true
                        copyReset.restart()
                    }
                }
            }
        }

        Timer {
            id: copyReset
            interval: 1400
            onTriggered: card.copied = false
        }
    }
}
