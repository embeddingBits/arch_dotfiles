import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn
import QtQuick.Controls

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 5

    PwNodePeakMonitor { id: inputPeak; node: ServicePipewire.source }

    property var sinkList: {
        const r = []
        for (let i = 0; i < ServicePipewire.sinks.length; i++)
            r.push({ name: ServicePipewire.sinks[i].description })
        return r
    }
    property var sourceList: {
        const r = []
        for (let i = 0; i < ServicePipewire.sources.length; i++)
            r.push({ name: ServicePipewire.sources[i].description })
        return r
    }

    function fmtRate(node) {
        const p = node?.properties ?? ({})
        let r = parseInt(p["audio.rate"] ?? "")
        if (isNaN(r)) {
            const nr = String(p["node.rate"] ?? "")
            const slash = nr.indexOf("/")
            if (slash >= 0) r = parseInt(nr.slice(slash + 1))
        }
        if (isNaN(r) || r <= 0) return ""
        const k = r / 1000
        return (r % 1000 === 0 ? k : k.toFixed(1)) + " kHz"
    }

    function fmtChannels(node) {
        const n = node?.audio?.channels?.length ?? 0
        if (n <= 0) return ""
        if (n === 1) return "Mono"
        if (n === 2) return "Stereo"
        if (n === 6) return "5.1"
        if (n === 8) return "7.1"
        return n + " ch"
    }

    function fmtLatency(node) {
        const parts = String(node?.properties?.["node.latency"] ?? "").split("/")
        if (parts.length !== 2) return ""
        const q = parseInt(parts[0])
        const r = parseInt(parts[1])
        if (isNaN(q) || isNaN(r) || r <= 0) return ""
        return Math.round(q / r * 1000) + " ms"
    }

    function fmtBus(node) {
        const p = node?.properties ?? ({})
        const api = String(p["device.api"] ?? "")
        const bus = String(p["device.bus"] ?? "")
        if (bus !== "") return bus.toUpperCase()
        if (api !== "") return api.toUpperCase()
        return ""
    }

    function hasInfo(node) {
        return root.fmtRate(node) !== "" || root.fmtChannels(node) !== ""
            || root.fmtLatency(node) !== "" || root.fmtBus(node) !== ""
    }

    component InfoChip: Rectangle {
        id: chip
        property string label: ""
        property string glyph: ""

        visible: chip.label !== ""
        implicitWidth: chipRow.implicitWidth + 20
        implicitHeight: 24
        radius: 12
        color: Colors.surfaceContainerHighest

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 5
            MaterialIconSymbol {
                visible: chip.glyph !== ""
                content: chip.glyph
                iconSize: 13
                customColor: Colors.outline
            }
            CustomText {
                content: chip.label
                size: 11
                weight: 600
                customColor: Colors.outline
            }
        }
    }

    component ValueChip: Rectangle {
        id: vchip
        property string label: ""
        implicitWidth: 52
        implicitHeight: 36
        radius: 10
        color: Colors.surfaceContainerHighest
        CustomText {
            anchors.centerIn: parent
            content: vchip.label
            size: 13
            weight: 600
        }
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
                MaterialIconSymbol { content: "volume_up"; iconSize: 20 }
                CustomText { content: "Sound"; size: 20; customColor: Colors.primary }
            }

            // ── Output ───────────────────────────────────────────────────
            CustomText { Layout.topMargin: 24; content: "Output"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                CustomText { content: "Output Device"; size: 14 }
                                CustomText { content: "Active output sink"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            CustomListNew {
                                Layout.preferredWidth: 200
                                Layout.preferredHeight: 30
                                color: Colors.surfaceContainerHighest
                                currentVal: ServicePipewire.sink?.description ?? ""
                                list: root.sinkList
                                onCurrentValChanged: {
                                    if (!currentVal) return
                                    for (let i = 0; i < ServicePipewire.sinks.length; i++) {
                                        if (ServicePipewire.sinks[i].description === currentVal) {
                                            ServicePipewire.setAudioSink(ServicePipewire.sinks[i])
                                            return
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: root.hasInfo(ServicePipewire.sink)
                            InfoChip { glyph: "graphic_eq";     label: root.fmtRate(ServicePipewire.sink) }
                            InfoChip { glyph: "surround_sound"; label: root.fmtChannels(ServicePipewire.sink) }
                            InfoChip { glyph: "timer";          label: root.fmtLatency(ServicePipewire.sink) }
                            InfoChip { glyph: "cable";          label: root.fmtBus(ServicePipewire.sink) }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 20
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        M3Slider {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            progress: ServicePipewire.volume
                            onMoved: ServicePipewire.setVolume(progress)
                        }

                        ValueChip { label: Math.round(ServicePipewire.volume * 100) + "%" }
                    }
                }
            }

            // ── Input ────────────────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Input"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                CustomText { content: "Input Device"; size: 14 }
                                CustomText { content: "Active input source"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            CustomListNew {
                                Layout.preferredWidth: 200
                                Layout.preferredHeight: 30
                                color: Colors.surfaceContainerHighest
                                currentVal: ServicePipewire.source?.description ?? ""
                                list: root.sourceList
                                onCurrentValChanged: {
                                    if (!currentVal) return
                                    for (let i = 0; i < ServicePipewire.sources.length; i++) {
                                        if (ServicePipewire.sources[i].description === currentVal) {
                                            ServicePipewire.setAudioSource(ServicePipewire.sources[i])
                                            return
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: root.hasInfo(ServicePipewire.source)
                            InfoChip { glyph: "graphic_eq";     label: root.fmtRate(ServicePipewire.source) }
                            InfoChip { glyph: "surround_sound"; label: root.fmtChannels(ServicePipewire.source) }
                            InfoChip { glyph: "timer";          label: root.fmtLatency(ServicePipewire.source) }
                            InfoChip { glyph: "cable";          label: root.fmtBus(ServicePipewire.source) }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 20
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        M3Slider {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            progress: ServicePipewire.micVolume
                            peakLevel: inputPeak.peak
                            showPeak: true
                            onMoved: ServicePipewire.setMicVolume(progress)
                        }

                        ValueChip { label: Math.round(ServicePipewire.micVolume * 100) + "%" }
                    }
                }
            }

            // ── Playbacks ─────────────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Playbacks"; size: 13; customColor: Colors.primary }

            // Empty state — nothing playing
            Rectangle {
                Layout.topMargin: 6
                Layout.fillWidth: true
                implicitHeight: 90
                visible: ServicePipewire.playbacks.length === 0
                color: Colors.surfaceContainerHigh
                radius: 20

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 46; implicitHeight: 46

                        MaterialShapes.ShapeCanvas {
                            anchors.fill: parent
                            roundedPolygon: MaterialShapeFn.getCookie6Sided()
                            color: Colors.surfaceContainerHighest
                        }
                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: "music_off"; iconSize: 22; customColor: Colors.outline
                        }
                    }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: "Nothing is playing"; size: 13; customColor: Colors.outline
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3
                visible: ServicePipewire.playbacks.length > 0

                Repeater {
                    model: ServicePipewire.playbacks

                    delegate: Rectangle {
                        id: stream
                        required property var modelData
                        required property int index

                        readonly property string appName:
                            stream.modelData.properties?.["application.name"] || stream.modelData.name || "Unknown"
                        readonly property string mediaName:
                            stream.modelData.properties?.["media.name"] ?? ""
                        readonly property real vol: stream.modelData.audio?.volume ?? 0

                        Layout.fillWidth: true
                        implicitHeight: streamRow.implicitHeight + 28
                        color: Colors.surfaceContainerHigh
                        topLeftRadius:     stream.index === 0 ? 20 : 5
                        topRightRadius:    stream.index === 0 ? 20 : 5
                        bottomLeftRadius:  stream.index === ServicePipewire.playbacks.length - 1 ? 20 : 5
                        bottomRightRadius: stream.index === ServicePipewire.playbacks.length - 1 ? 20 : 5

                        RowLayout {
                            id: streamRow
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignVCenter
                                radius: 20
                                color: Colors.surfaceContainerHighest

                                Image {
                                    id: streamIcon
                                    anchors.centerIn: parent
                                    width: 24; height: 24
                                    source: IconUtil.getIconPath(stream.modelData.name)
                                    sourceSize.width: 24
                                    sourceSize.height: 24
                                    fillMode: Image.PreserveAspectFit
                                    visible: status === Image.Ready
                                }

                                MaterialIconSymbol {
                                    anchors.centerIn: parent
                                    content: "volume_up"
                                    iconSize: 20
                                    customColor: Colors.outline
                                    visible: streamIcon.status !== Image.Ready
                                }
                            }

                            ColumnLayout {
                                id: streamCol
                                Layout.fillWidth: true
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    CustomText {
                                        Layout.fillWidth: true
                                        content: stream.appName
                                        size: 14
                                    }

                                    CustomText {
                                        content: Math.round(stream.vol * 100) + "%"
                                        size: 12
                                        weight: 600
                                        customColor: Colors.outline
                                    }
                                }

                                CustomText {
                                    Layout.fillWidth: true
                                    content: stream.mediaName
                                    size: 12
                                    customColor: Colors.outline
                                    visible: stream.mediaName.length > 0
                                }

                                M3Slider {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 22
                                    trackHeight: 8
                                    handleHeight: 22
                                    handleGap: 4
                                    showStopIndicator: false
                                    progress: stream.vol
                                    onMoved: ServicePipewire.setSinkVolume(stream.modelData, progress)
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
