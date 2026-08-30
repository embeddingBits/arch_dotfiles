import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import "../../config/Theme.qml" as Theme

PopupWindow {
    id: root

    required property var bar
    required property bool volumePopupOpen

    visible: root.volumePopupOpen
    color: "transparent"

    anchor.window: root.bar
    anchor.rect.x: bar.width - implicitWidth - 90
    anchor.rect.y: bar.height + 6
    anchor.rect.width: 1
    anchor.rect.height: 1

    implicitWidth: 360
    implicitHeight: volumeCol.implicitHeight + 24

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.color: Theme.border
        border.width: 1

        Column {
            id: volumeCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 12

            Row {
                width: parent.width

                Text {
                    text: "󰕾  Audio"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: 700
                    color: Theme.fg
                }

                Item {
                    width: 12
                    height: 1
                }

                Text {
                    text: Pipewire.defaultAudioSink?.audio?.muted ? "MUTED" : Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Qt.darker(Theme.fg, 1.4)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: 20
                    height: 1
                }
            }

            // ── Output ──
            Column {
                width: parent.width
                spacing: 6

                RowLayout {
                    width: parent.width

                    Text {
                        text: "OUTPUT"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.letterSpacing: 1
                        font.bold: true
                        color: Qt.darker(Theme.fg, 1.3)
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 1
                    }

                    Text {
                        text: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.fg
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 28
                    radius: Theme.radius
                    color: "transparent"
                    border.color: Theme.borderMuted
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 8

                        Text {
                            text: Pipewire.defaultAudioSink?.audio?.muted ? "󰝟" : "󰕾"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: Theme.fg
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item {
                            Layout.fillWidth: true
                            height: 6
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radius
                                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.18)
                            }

                            Rectangle {
                                width: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
                                height: parent.height
                                radius: Theme.radius
                                color: Theme.accent
                            }

                            Slider {
                                id: outSlider
                                anchors.fill: parent
                                from: 0
                                to: 1
                                stepSize: 0.02
                                value: Pipewire.defaultAudioSink?.audio.volume ?? 0
                                onMoved: {
                                    if (Pipewire.defaultAudioSink?.audio)
                                        Pipewire.defaultAudioSink.audio.volume = value;
                                }
                                background: Item {}
                                handle: Rectangle {
                                    visible: false
                                    width: 1
                                    height: 1
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: Theme.radius
                            color: volMuteMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) : "transparent"
                            border.color: volMuteMouse.containsMouse ? Theme.borderMuted : "transparent"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: Pipewire.defaultAudioSink?.audio?.muted ? "󰝟" : "󰝧"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.fg
                            }

                            MouseArea {
                                id: volMuteMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (Pipewire.defaultAudioSink?.audio)
                                    Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: {
                            let ns = Pipewire.nodes ? Pipewire.nodes.values : [];
                            let out = [];
                            for (let i = 0; i < ns.length; i++) {
                                let n = ns[i];
                                if (n && n.isSink && !n.isStream)
                                    out.push(n);
                            }
                            return out.slice(0, 5);
                        }

                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width
                            height: 26
                            radius: Theme.radius
                            color: sinkMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) : Pipewire.defaultAudioSink && modelData.id === Pipewire.defaultAudioSink.id ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12) : "transparent"
                            border.color: Pipewire.defaultAudioSink && modelData.id === Pipewire.defaultAudioSink.id ? Theme.borderMuted : sinkMouse.containsMouse ? Theme.borderMuted : "transparent"
                            border.width: 1

                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: "󰓃"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    color: Theme.fg
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: modelData.description || modelData.name || "Unknown"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.fg
                                    elide: Text.ElideRight
                                    width: parent.width - 30
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: sinkMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Pipewire.preferredDefaultAudioSink = modelData
                            }
                        }
                    }
                }
            }

            // ── Input ──
            Column {
                width: parent.width
                spacing: 6

                RowLayout {
                    width: parent.width

                    Text {
                        text: "INPUT"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.letterSpacing: 1
                        font.bold: true
                        color: Qt.darker(Theme.fg, 1.3)
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 1
                    }

                    Text {
                        text: Pipewire.defaultAudioSource?.audio ? Math.round((Pipewire.defaultAudioSource.audio.volume ?? 0) * 100) + "%" : "--"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.fg
                    }
                }

                Rectangle {
                    visible: !!Pipewire.defaultAudioSource
                    width: parent.width
                    height: 28
                    radius: Theme.radius
                    color: "transparent"
                    border.color: Theme.borderMuted
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 8

                        Text {
                            text: Pipewire.defaultAudioSource?.audio?.muted ? "󰍭" : "󰍬"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: Theme.fg
                        }

                        Item {
                            Layout.fillWidth: true
                            height: 6

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radius
                                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.18)
                            }

                            Rectangle {
                                width: parent.width * (Pipewire.defaultAudioSource?.audio.volume ?? 0)
                                height: parent.height
                                radius: Theme.radius
                                color: Theme.accent
                            }

                            Slider {
                                anchors.fill: parent
                                from: 0
                                to: 1
                                stepSize: 0.02
                                value: Pipewire.defaultAudioSource?.audio.volume ?? 0
                                onMoved: if (Pipewire.defaultAudioSource?.audio)
                                    Pipewire.defaultAudioSource.audio.volume = value
                                background: Item {}
                                handle: Rectangle {
                                    visible: false
                                    width: 1
                                    height: 1
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: Theme.radius
                            color: inMuteMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) : "transparent"
                            border.color: inMuteMouse.containsMouse ? Theme.borderMuted : "transparent"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: Pipewire.defaultAudioSource?.audio?.muted ? "󰍭" : "󰍬"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.fg
                            }

                            MouseArea {
                                id: inMuteMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (Pipewire.defaultAudioSource?.audio)
                                    Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted
                            }
                        }
                    }
                }
            }

            // ── App streams ──
            Column {
                width: parent.width
                spacing: 6
                visible: {
                    let ns = Pipewire.nodes ? Pipewire.nodes.values : [];
                    let c = 0;
                    for (let i = 0; i < ns.length; i++)
                        if (ns[i] && ns[i].isStream && ns[i].isSink)
                            c++;
                    return c > 0;
                }

                Text {
                    text: "APPS"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    font.bold: true
                    color: Qt.darker(Theme.fg, 1.3)
                }

                Repeater {
                    model: {
                        let ns = Pipewire.nodes ? Pipewire.nodes.values : [];
                        let out = [];
                        for (let i = 0; i < ns.length; i++) {
                            let n = ns[i];
                            if (n && n.isStream && n.isSink)
                                out.push(n);
                        }
                        return out.slice(0, 6);
                    }

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 30
                        radius: Theme.radius
                        color: streamMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06) : "transparent"
                        border.color: streamMouse.containsMouse ? Theme.borderMuted : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 6

                            Text {
                                text: modelData.audio?.muted ? "󰝟" : "󰕾"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.fg
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: modelData.description || modelData.name || "Stream"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.fg
                            }

                            Text {
                                text: Math.round((modelData.audio.volume ?? 0) * 100) + "%"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Qt.darker(Theme.fg, 1.2)
                            }

                            Rectangle {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                radius: Theme.radius
                                color: "transparent"
                                border.color: "transparent"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.audio?.muted ? "󰝟" : "󰝧"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.fg
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (modelData.audio)
                                        modelData.audio.muted = !modelData.audio.muted
                                }
                            }
                        }

                        Slider {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            anchors.bottomMargin: 2
                            height: 4
                            from: 0
                            to: 1.2
                            value: modelData.audio.volume ?? 0
                            onMoved: if (modelData.audio)
                                modelData.audio.volume = value
                            background: Rectangle {
                                radius: Theme.radius
                                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.14)
                                implicitHeight: 4
                            }
                            handle: Rectangle {
                                visible: false
                            }
                        }

                        MouseArea {
                            id: streamMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }
            }
        }
    }
}
