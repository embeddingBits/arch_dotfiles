import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
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
        id: soundFilePicker
        title: "Select a shutter sound file"
        nameFilters: ["WAV files (*.wav)"]
        onAccepted: {
            const path = soundFilePicker.file.toString().replace(/^file:\/\//, "")
            SettingsConfig.screenshot = Object.assign({}, SettingsConfig.screenshot, { soundPath: path })
            GlobalStates.fileDialogOpen = false
        }
        onRejected: GlobalStates.fileDialogOpen = false
    }

    FolderDialog {
        id: recFolderPicker
        title: "Select recording output folder"
        onAccepted: {
            const path = folder.toString().replace(/^file:\/\//, "")
            SettingsConfig.recording = Object.assign({}, SettingsConfig.recording, { outputPath: path })
            GlobalStates.fileDialogOpen = false
        }
        onRejected: GlobalStates.fileDialogOpen = false
    }

    FolderDialog {
        id: ssFolderPicker
        title: "Select screenshot output folder"
        onAccepted: {
            const path = folder.toString().replace(/^file:\/\//, "")
            SettingsConfig.screenshot = Object.assign({}, SettingsConfig.screenshot, { outputPath: path })
            GlobalStates.fileDialogOpen = false
        }
        onRejected: GlobalStates.fileDialogOpen = false
    }

    readonly property var videoCodecs:      [{ name: "libx264" }, { name: "libx265" }, { name: "libvpx-vp9" }, { name: "h264_vaapi" }, { name: "av1_vaapi" }]
    readonly property var muxers:           [{ name: "mp4" }, { name: "mkv" }, { name: "webm" }]
    readonly property var framerates:       [{ name: "24" }, { name: "30" }, { name: "60" }]
    readonly property var pixelFormats:     [{ name: "yuv420p" }, { name: "yuv444p" }, { name: "nv12" }]
    readonly property var audioCodecs:      [{ name: "aac" }, { name: "opus" }, { name: "libmp3lame" }, { name: "flac" }]
    readonly property var audioBitrates:    [{ name: "64k" }, { name: "96k" }, { name: "128k" }, { name: "192k" }, { name: "256k" }]
    readonly property var audioSampleRates: [{ name: "44100" }, { name: "48000" }, { name: "96000" }]

    Flickable {
        id: pageFlick
        ScrollBar.vertical: CustomScrollBar {}
        anchors.fill: parent
        contentHeight: column.implicitHeight + 20
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

            // ── Page header ──────────────────────────────────────
            RowLayout {
                spacing: 10
                MaterialIconSymbol { content: "perm_media"; iconSize: 20 }
                CustomText { content: "Media"; size: 20; customColor: Colors.primary }
            }

            // ════════════════════════════════════════════════════
            // RECORDING
            // ════════════════════════════════════════════════════
            CustomText { Layout.topMargin: 24; content: "Recording"; size: 13; customColor: Colors.primary }

            // Output folder
            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Output Folder"; size: 14 }
                        CustomText { content: "Where recordings are saved"; size: 12; customColor: Colors.outline }
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
                                content: SettingsConfig.recording.outputPath; size: 11
                                elide: Text.ElideLeft
                            }
                        }
                        M3IconButton {
                            implicitHeight: 32; implicitWidth: 40
                            topLeftRadius: 6;   bottomLeftRadius: 6
                            topRightRadius: 16; bottomRightRadius: 16
                            icon: "folder_open"; iconSize: 18
                            onClicked: { GlobalStates.fileDialogOpen = true; recFolderPicker.open() }
                        }
                    }
                }
            }

            // Video
            CustomText { Layout.topMargin: 16; content: "Video"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.topMargin: 6; Layout.fillWidth: true; spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 24

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16
                            ColumnLayout {
                                Layout.preferredWidth: 170
                                Layout.maximumWidth: 170
                                spacing: 2
                                CustomText { content: "Codec"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Video encoding format"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            CustomListNew {
                                Layout.preferredHeight: 30; Layout.preferredWidth: 160
                                color: Colors.surfaceContainerHighest
                                currentVal: SettingsConfig.recording.codec; list: root.videoCodecs
                                onCurrentValChanged: {
                                    if (currentVal && currentVal !== SettingsConfig.recording.codec)
                                        SettingsConfig.recording = Object.assign({}, SettingsConfig.recording, { codec: currentVal })
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16
                            ColumnLayout {
                                Layout.preferredWidth: 170
                                Layout.maximumWidth: 170
                                spacing: 2
                                CustomText { content: "Container"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Output file format"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            CustomListNew {
                                Layout.preferredHeight: 30; Layout.preferredWidth: 160
                                color: Colors.surfaceContainerHighest
                                currentVal: SettingsConfig.recording.muxer; list: root.muxers
                                onCurrentValChanged: {
                                    if (currentVal && currentVal !== SettingsConfig.recording.muxer)
                                        SettingsConfig.recording = Object.assign({}, SettingsConfig.recording, { muxer: currentVal })
                                }
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 20
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 24

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16
                            ColumnLayout {
                                Layout.preferredWidth: 170
                                Layout.maximumWidth: 170
                                spacing: 2
                                CustomText { content: "Framerate"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Frames per second"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            CustomListNew {
                                Layout.preferredHeight: 30; Layout.preferredWidth: 160
                                color: Colors.surfaceContainerHighest
                                currentVal: SettingsConfig.recording.framerate; list: root.framerates
                                onCurrentValChanged: {
                                    if (currentVal && currentVal !== SettingsConfig.recording.framerate)
                                        SettingsConfig.recording = Object.assign({}, SettingsConfig.recording, { framerate: currentVal })
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16
                            ColumnLayout {
                                Layout.preferredWidth: 170
                                Layout.maximumWidth: 170
                                spacing: 2
                                CustomText { content: "Pixel Format"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Color space encoding"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            CustomListNew {
                                Layout.preferredHeight: 30; Layout.preferredWidth: 160
                                color: Colors.surfaceContainerHighest
                                currentVal: SettingsConfig.recording.pixelFormat; list: root.pixelFormats
                                onCurrentValChanged: {
                                    if (currentVal && currentVal !== SettingsConfig.recording.pixelFormat)
                                        SettingsConfig.recording = Object.assign({}, SettingsConfig.recording, { pixelFormat: currentVal })
                                }
                            }
                        }
                    }
                }
            }

            // Audio
            CustomText { Layout.topMargin: 16; content: "Audio"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.topMargin: 6; Layout.fillWidth: true; spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20
                    bottomRadius: SettingsConfig.recording.audioEnabled ? 5 : 20
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout { spacing: 2
                            CustomText { content: "Capture Audio"; size: 14 }
                            CustomText { content: "Record system or mic audio alongside video"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomToogle {
                            isToggleOn: SettingsConfig.recording.audioEnabled
                            onToggled: (state) => SettingsConfig.recording = Object.assign({}, SettingsConfig.recording, { audioEnabled: state })
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 5
                    visible: SettingsConfig.recording.audioEnabled
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout { spacing: 2
                            CustomText { content: "Audio Source"; size: 14 }
                            CustomText { content: "What audio to capture"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        M3ButtonGroup {
                            model: [
                                { value: "mic",    label: "Mic",    icon: "mic"     },
                                { value: "system", label: "System", icon: "speaker" },
                                { value: "both",   label: "Both",   icon: "merge"   }
                            ]
                            activeCheck: (v) => (SettingsConfig.recording.audioSource ?? "mic") === v
                            onSegmentClicked: (v) => SettingsConfig.recording = Object.assign({}, SettingsConfig.recording, { audioSource: v })
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 5
                    visible: SettingsConfig.recording.audioEnabled
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 24

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16
                            ColumnLayout {
                                Layout.preferredWidth: 170
                                Layout.maximumWidth: 170
                                spacing: 2
                                CustomText { content: "Audio Codec"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Audio encoding format"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            CustomListNew {
                                Layout.preferredHeight: 30; Layout.preferredWidth: 160
                                color: Colors.surfaceContainerHighest
                                currentVal: SettingsConfig.recording.audioCodec; list: root.audioCodecs
                                onCurrentValChanged: {
                                    if (currentVal && currentVal !== SettingsConfig.recording.audioCodec)
                                        SettingsConfig.recording = Object.assign({}, SettingsConfig.recording, { audioCodec: currentVal })
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16
                            ColumnLayout {
                                Layout.preferredWidth: 170
                                Layout.maximumWidth: 170
                                spacing: 2
                                CustomText { content: "Bitrate"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Audio quality vs file size"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            CustomListNew {
                                Layout.preferredHeight: 30; Layout.preferredWidth: 160
                                color: Colors.surfaceContainerHighest
                                currentVal: SettingsConfig.recording.audioBitrate; list: root.audioBitrates
                                onCurrentValChanged: {
                                    if (currentVal && currentVal !== SettingsConfig.recording.audioBitrate)
                                        SettingsConfig.recording = Object.assign({}, SettingsConfig.recording, { audioBitrate: currentVal })
                                }
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 20
                    visible: SettingsConfig.recording.audioEnabled
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout { spacing: 2
                            CustomText { content: "Sample Rate"; size: 14 }
                            CustomText { content: "Audio samples per second (Hz)"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomListNew {
                            Layout.preferredHeight: 30; Layout.preferredWidth: 160
                            color: Colors.surfaceContainerHighest
                            currentVal: SettingsConfig.recording.audioSampleRate; list: root.audioSampleRates
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== SettingsConfig.recording.audioSampleRate)
                                    SettingsConfig.recording = Object.assign({}, SettingsConfig.recording, { audioSampleRate: currentVal })
                            }
                        }
                    }
                }
            }

            // ════════════════════════════════════════════════════
            // SCREENSHOT
            // ════════════════════════════════════════════════════
            CustomText { Layout.topMargin: 24; content: "Screenshot"; size: 13; customColor: Colors.primary }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Output Folder"; size: 14 }
                        CustomText { content: "Where screenshots are saved"; size: 12; customColor: Colors.outline }
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
                                content: SettingsConfig.screenshot.outputPath; size: 11
                                elide: Text.ElideLeft
                            }
                        }
                        M3IconButton {
                            implicitHeight: 32; implicitWidth: 40
                            topLeftRadius: 6;   bottomLeftRadius: 6
                            topRightRadius: 16; bottomRightRadius: 16
                            icon: "folder_open"; iconSize: 18
                            onClicked: { GlobalStates.fileDialogOpen = true; ssFolderPicker.open() }
                        }
                    }
                }
            }

            CustomText { Layout.topMargin: 16; content: "Sound"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.topMargin: 6; Layout.fillWidth: true; spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout { spacing: 2
                            CustomText { content: "Shutter Sound"; size: 14 }
                            CustomText { content: "Play a sound when a screenshot is taken"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomToogle {
                            isToggleOn: SettingsConfig.screenshot.soundEnabled
                            onToggled: (state) => SettingsConfig.screenshot = Object.assign({}, SettingsConfig.screenshot, { soundEnabled: state })
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 5
                    visible: SettingsConfig.screenshot.soundEnabled
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout { spacing: 2
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
                                    content: SettingsConfig.screenshot.soundPath === ""
                                             ? "No file selected"
                                             : SettingsConfig.screenshot.soundPath.split("/").pop()
                                    size: 11
                                    customColor: SettingsConfig.screenshot.soundPath === "" ? Colors.outline : Colors.surfaceText
                                    elide: Text.ElideLeft
                                }
                            }
                            M3IconButton {
                                implicitHeight: 32; implicitWidth: 40
                                topLeftRadius: 6;   bottomLeftRadius: 6
                                topRightRadius: 16; bottomRightRadius: 16
                                icon: "audio_file"; iconSize: 18
                                onClicked: { GlobalStates.fileDialogOpen = true; soundFilePicker.open() }
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5; bottomRadius: 20
                    RowLayout {
                        spacing: 8
                        MaterialIconSymbol { content: "info"; iconSize: 15; customColor: Colors.outline }
                        CustomText {
                            Layout.fillWidth: true
                            content: "Full screen and window shots use grimblast. Area selection uses the built-in selection panel. All screenshots are copied to clipboard automatically."
                            size: 12; customColor: Colors.outline
                            wrapMode: Text.WordWrap
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
