pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents
import "../../services/AiHighlight.js" as Hl

Column {
    id: root

    property var blocks: []
    property var offsets: []
    property int revealChars: -1
    property real contentWidth: width
    property bool animateBlocks: true

    spacing: 12

    function _accent(s) {
        if (!(SettingsConfig.ai?.accentBold ?? true)) return s
        const c = String(Colors.primary)
        return s.replace(/\*\*([^*]+)\*\*/g, '<b><font color="' + c + '">$1</font></b>')
    }

    function _typed(full, n) {
        if (n >= full.length) return full
        if (n <= 0) return ""

        let s = full.substring(0, n)

        const bold = s.match(/\*\*/g)
        if (bold && bold.length % 2 === 1) s = s.substring(0, s.lastIndexOf("**"))

        const ticks = s.match(/`/g)
        if (ticks && ticks.length % 2 === 1) s = s.substring(0, s.lastIndexOf("`"))

        if (/(^|[^*])\*$/.test(s) || /(^|[^_])_$/.test(s)) s = s.slice(0, -1)

        return s
    }

    ScriptModel {
        id: blockModel
        values: root.blocks
        objectProp: "id"
    }

    Repeater {
        model: blockModel

        delegate: Loader {
            id: blockLoader
            required property var modelData
            required property int index

            readonly property int localReveal: root.revealChars < 0
                ? -1
                : root.revealChars - (root.offsets[index] ?? 0)

            readonly property var block: modelData

            width: root.width

            sourceComponent: !modelData ? textBlock
                           : modelData.type === "code" ? codeBlock
                           : modelData.type === "table" ? tableBlock
                           : textBlock

            onLoaded: if (item) item.host = blockLoader

            opacity: 1

            Component.onCompleted: if (root.animateBlocks) {
                opacity = 0
                blockFade.start()
            }

            NumberAnimation {
                id: blockFade
                target: blockLoader
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.duration.normal
                easing.type: Easing.OutQuad
            }
        }
    }

    Component {
        id: textBlock

        CustomText {
            property var host: null
            readonly property var block: host ? host.block : null

            readonly property string full: block?.text ?? ""

            content: root._accent(!host || host.localReveal < 0 ? full : root._typed(full, host.localReveal))
            size: 15
            weight: 400
            customColor: Colors.surfaceText
            wrapMode: Text.Wrap
            textFormat: Text.MarkdownText
            onLinkActivated: link => Quickshell.execDetached(["xdg-open", link])

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }

    Component {
        id: tableBlock

        Column {
            id: tbl
            property var host: null
            readonly property var block: host ? host.block : null

            readonly property bool shown: !host || host.localReveal < 0 || host.localReveal > 0
            visible: shown

            readonly property var headers: shown ? (block?.headers ?? []) : []
            readonly property var rows: shown ? (block?.rows ?? []) : []
            readonly property int columns: headers.length

            readonly property real gap: 14

            readonly property var weights: {
                const n = tbl.columns
                if (n === 0)
                    return []
                const lengths = []
                for (let c = 0; c < n; c++) {
                    let longest = (tbl.headers[c] ?? "").length
                    for (let r = 0; r < tbl.rows.length; r++)
                        longest = Math.max(longest, (tbl.rows[r][c] ?? "").length)
                    lengths.push(Math.max(8, Math.min(70, longest)))
                }
                const total = lengths.reduce((a, b) => a + b, 0)
                return lengths.map(v => v / total)
            }

            function columnWidth(i) {
                if (tbl.columns === 0)
                    return 0
                const usable = tbl.width - (tbl.columns - 1) * tbl.gap
                return Math.max(48, usable * (tbl.weights[i] ?? 1 / tbl.columns))
            }

            spacing: 0

            Row {
                spacing: tbl.gap
                bottomPadding: 8

                Repeater {
                    model: tbl.columns
                    delegate: CustomText {
                        required property int index
                        width: tbl.columnWidth(index)
                        content: tbl.headers[index] ?? ""
                        size: 11
                        weight: 700
                        customColor: Colors.surfaceVariantText
                        wrapMode: Text.Wrap
                        textFormat: Text.MarkdownText
                    }
                }
            }

            Rectangle {
                width: tbl.width
                height: 1
                color: Qt.alpha(Colors.outlineVariant, 0.7)
            }

            Repeater {
                model: tbl.rows.length

                delegate: Column {
                    id: rowItem
                    required property int index
                    readonly property var cells: tbl.rows[index] ?? []

                    width: tbl.width
                    spacing: 0

                    Row {
                        spacing: tbl.gap
                        topPadding: 10
                        bottomPadding: 10

                        Repeater {
                            model: tbl.columns
                            delegate: CustomText {
                                required property int index
                                width: tbl.columnWidth(index)
                                content: rowItem.cells[index] ?? ""
                                size: 13
                                weight: 400
                                customColor: Colors.surfaceText
                                wrapMode: Text.Wrap
                                textFormat: Text.MarkdownText
                            }
                        }
                    }

                    Rectangle {
                        width: tbl.width
                        height: 1
                        visible: rowItem.index < tbl.rows.length - 1
                        color: Qt.alpha(Colors.outlineVariant, 0.28)
                    }
                }
            }
        }
    }

    Component {
        id: codeBlock

        Rectangle {
            id: codeRoot
            property var host: null
            readonly property var block: host ? host.block : null

            readonly property string full: block?.text ?? ""

            readonly property string shownText: !host || host.localReveal < 0
                ? full
                : full.substring(0, Math.max(0, Math.min(full.length, host.localReveal)))

            visible: !host || host.localReveal < 0 || host.localReveal > 0

            implicitHeight: codeCol.implicitHeight
            radius: 16
            color: Colors.surfaceContainerHighest
            border.width: 1
            border.color: Qt.alpha(Colors.outlineVariant, 0.35)

            ColumnLayout {
                id: codeCol
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 10
                    Layout.bottomMargin: 2
                    spacing: 8

                    Rectangle {
                        implicitWidth: langLabel.implicitWidth + 16
                        implicitHeight: langLabel.implicitHeight + 7
                        radius: height / 2
                        color: Qt.alpha(Colors.primary, 0.12)

                        CustomText {
                            id: langLabel
                            anchors.centerIn: parent
                            content: (codeRoot.block?.lang ?? "") !== "" ? codeRoot.block.lang : "code"
                            size: 10
                            weight: 700
                            customColor: Colors.primary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    CustomText {
                        id: copyLabel
                        property bool copied: false
                        content: copied ? "copied" : "copy"
                        size: 10
                        weight: 600
                        customColor: copied ? Colors.primary : Colors.outline

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {

                                Quickshell.clipboardText = codeRoot.full
                                copyLabel.copied = true
                                copiedReset.restart()
                            }
                        }

                        Timer {
                            id: copiedReset
                            interval: 1400
                            onTriggered: copyLabel.copied = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    implicitHeight: 1
                    color: Qt.alpha(Colors.outlineVariant, 0.28)
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.bottomMargin: 12
                    implicitHeight: codeText.implicitHeight
                    contentWidth: codeText.implicitWidth
                    contentHeight: codeText.implicitHeight
                    clip: true
                    flickableDirection: Flickable.HorizontalFlick
                    interactive: contentWidth > width
                    boundsBehavior: Flickable.StopAtBounds

                    Text {
                        id: codeText
                        readonly property bool hl: SettingsConfig.ai?.syntaxHighlight ?? true
                        text: !hl ? codeRoot.shownText
                            : Hl.highlight(codeRoot.shownText, codeRoot.block?.lang ?? "", {
                            keyword: String(Colors.primary),
                            string: String(Colors.tertiary),
                            number: String(Colors.secondary),
                            comment: String(Colors.outline)
                        })
                        color: Colors.surfaceText
                        font.family: SettingsConfig.ai?.codeFont ?? "Adwaita Mono"
                        font.pixelSize: SettingsConfig.ai?.codeFontSize ?? 13
                        textFormat: hl ? Text.RichText : Text.PlainText
                    }
                }
            }
        }
    }
}
