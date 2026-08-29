pragma ComponentBehavior: Bound

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

    readonly property var monoFonts: {
        const all = Qt.fontFamilies()
        const out = []
        const seen = {}
        for (let i = 0; i < all.length; i++) {
            const f = all[i]
            if (!/mono|code|consol|courier/i.test(f)) continue
            if (/light|medium|semibold|bold|thin|retina|propo|italic/i.test(f)) continue
            if (seen[f]) continue
            seen[f] = true
            out.push({ name: f })
        }
        return out.length > 0 ? out : [{ name: "Adwaita Mono" }]
    }

    function patch(key, value) {
        const next = {}
        next[key] = value
        SettingsConfig.ai = Object.assign({}, SettingsConfig.ai, next)
    }

    Flickable {
        id: pageFlick
        ScrollBar.vertical: CustomScrollBar {}
        anchors.fill: parent
        contentHeight: column.implicitHeight
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: parent.width
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            anchors.topMargin: 5
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialIconSymbol { content: "neurology"; iconSize: 20; customColor: Colors.primary }
                CustomText { content: "AI"; size: 20; customColor: Colors.primary }
                Item { Layout.fillWidth: true }
                CustomText {
                    content: ServiceAi.bridgeConnected ? "claude.ai connected" : "Zen offline"
                    size: 12
                    customColor: ServiceAi.bridgeConnected ? Colors.primary : Colors.error
                }
            }

            // ── Assistant ────────────────────────────────────────────────────

            CustomText {
                Layout.topMargin: 24
                content: "Assistant"
                size: 13
                customColor: Colors.primary
            }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Enable AI"; size: 14 }
                        CustomText {
                            content: "Off closes the panel and stops the browser bridge and dictation daemon"
                            size: 12
                            customColor: Colors.outline
                        }
                    }
                    Item { Layout.fillWidth: true }
                    CustomToogle {
                        isToggleOn: SettingsConfig.ai?.enabled ?? true
                        onToggled: function(state) { root.patch("enabled", state) }
                    }
                }
            }

            // ── Reply text ───────────────────────────────────────────────────

            CustomText {
                Layout.topMargin: 16
                content: "Reply text"
                size: 13
                customColor: Colors.primary
            }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 5

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Code font"; size: 14 }
                        CustomText { content: "Monospace family used in code blocks"; size: 12; customColor: Colors.outline }
                    }
                    Item { Layout.fillWidth: true }
                    CustomListNew {
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: 190
                        color: Colors.surfaceContainerHighest
                        currentVal: SettingsConfig.ai?.codeFont ?? "Adwaita Mono"
                        list: root.monoFonts
                        onCurrentValChanged: {
                            if (currentVal && currentVal !== SettingsConfig.ai.codeFont)
                                root.patch("codeFont", currentVal)
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
                        CustomText { content: "Code size"; size: 14 }
                        CustomText { content: "Pixel size of code text"; size: 12; customColor: Colors.outline }
                    }
                    Item { Layout.fillWidth: true }
                    CustomSpinBox {
                        color: Colors.surfaceContainerHighest
                        inc: 1
                        limit: 24
                        Component.onCompleted: val = SettingsConfig.ai?.codeFontSize ?? 13
                        onValChanged: if (val >= 8) root.patch("codeFontSize", val)
                    }
                }
            }

            CustomCard {
                autoRadius: false; topRadius: 5; bottomRadius: 5

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Syntax colours"; size: 14 }
                        CustomText { content: "Highlight keywords, strings and comments"; size: 12; customColor: Colors.outline }
                    }
                    Item { Layout.fillWidth: true }
                    CustomToogle {
                        isToggleOn: SettingsConfig.ai?.syntaxHighlight ?? true
                        onToggled: function(state) { root.patch("syntaxHighlight", state) }
                    }
                }
            }

            CustomCard {
                autoRadius: false; topRadius: 5; bottomRadius: 20

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Accent bold text"; size: 14 }
                        CustomText { content: "Show bold text in the accent colour"; size: 12; customColor: Colors.outline }
                    }
                    Item { Layout.fillWidth: true }
                    CustomToogle {
                        isToggleOn: SettingsConfig.ai?.accentBold ?? true
                        onToggled: function(state) { root.patch("accentBold", state) }
                    }
                }
            }

            // ── Composer ─────────────────────────────────────────────────────

            CustomText {
                Layout.topMargin: 16
                content: "Composer"
                size: 13
                customColor: Colors.primary
            }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 5

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Message font"; size: 14 }
                        CustomText { content: "Family used in the input field"; size: 12; customColor: Colors.outline }
                    }
                    Item { Layout.fillWidth: true }
                    CustomListNew {
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: 190
                        color: Colors.surfaceContainerHighest
                        currentVal: SettingsConfig.ai?.composerFont ?? "Adwaita Mono"
                        list: root.monoFonts
                        onCurrentValChanged: {
                            if (currentVal && currentVal !== SettingsConfig.ai.composerFont)
                                root.patch("composerFont", currentVal)
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
                        CustomText { content: "Message size"; size: 14 }
                        CustomText { content: "Pixel size of typed text"; size: 12; customColor: Colors.outline }
                    }
                    Item { Layout.fillWidth: true }
                    CustomSpinBox {
                        color: Colors.surfaceContainerHighest
                        inc: 1
                        limit: 26
                        Component.onCompleted: val = SettingsConfig.ai?.composerFontSize ?? 15
                        onValChanged: if (val >= 10) root.patch("composerFontSize", val)
                    }
                }
            }

            // ── Dictation ────────────────────────────────────────────────────

            CustomText {
                Layout.topMargin: 16
                content: "Dictation"
                size: 13
                customColor: Colors.primary
            }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 5

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Whisper model"; size: 14 }
                        CustomText { content: "distil-large-v3 is most accurate, base.en is lighter"; size: 12; customColor: Colors.outline }
                    }
                    Item { Layout.fillWidth: true }
                    CustomListNew {
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: 190
                        color: Colors.surfaceContainerHighest
                        currentVal: SettingsConfig.ai?.model ?? "distil-large-v3"
                        list: [{ name: "distil-large-v3" }, { name: "small.en" }, { name: "base.en" }, { name: "tiny.en" }]
                        onCurrentValChanged: {
                            if (currentVal && currentVal !== SettingsConfig.ai.model)
                                root.patch("model", currentVal)
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
                        CustomText { content: "Send on dictate"; size: 14 }
                        CustomText { content: "Send immediately instead of leaving it to read over"; size: 12; customColor: Colors.outline }
                    }
                    Item { Layout.fillWidth: true }
                    CustomToogle {
                        isToggleOn: SettingsConfig.ai?.autoSend ?? false
                        onToggled: function(state) { root.patch("autoSend", state) }
                    }
                }
            }

            CustomCard {
                autoRadius: false; topRadius: 5; bottomRadius: 20

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Vocabulary"; size: 14 }
                        CustomText { content: "Names and jargon whisper keeps mangling, comma separated"; size: 12; customColor: Colors.outline }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 10
                        color: Colors.surfaceContainerHighest

                        TextInput {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: Colors.surfaceText
                            font.pixelSize: 13
                            clip: true
                            text: SettingsConfig.ai?.vocabulary ?? ""
                            onEditingFinished: root.patch("vocabulary", text)
                        }
                    }
                }
            }

            // ── Reply parsing ────────────────────────────────────────────────

            CustomText {
                Layout.topMargin: 16
                content: "Reply parsing"
                size: 13
                customColor: Colors.primary
            }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 5

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Keep screen-reader copy"; size: 14 }
                        CustomText { content: "claude.ai repeats every reply for screen readers"; size: 12; customColor: Colors.outline }
                    }
                    Item { Layout.fillWidth: true }
                    CustomToogle {
                        isToggleOn: SettingsConfig.ai?.keepScreenReader ?? false
                        onToggled: function(state) { root.patch("keepScreenReader", state) }
                    }
                }
            }

            CustomCard {
                autoRadius: false; topRadius: 5; bottomRadius: 20

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        CustomText { content: "Keep page controls"; size: 14 }
                        CustomText { content: "Buttons and labels such as Copy"; size: 12; customColor: Colors.outline }
                    }
                    Item { Layout.fillWidth: true }
                    CustomToogle {
                        isToggleOn: SettingsConfig.ai?.keepControls ?? false
                        onToggled: function(state) { root.patch("keepControls", state) }
                    }
                }
            }

            Item { Layout.preferredHeight: 12 }
        }
    }
    ScrollFade {
        anchors.fill: parent
        flickable: pageFlick
    }
}
