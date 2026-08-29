import QtQuick
import qs.modules.utils
import qs.modules.settings

Item {
    id: root

    property var items: []
    property bool busy: false
    property string emptyText: "Empty folder"
    property string scanKey: ""
    property string itemsKey: ""

    signal drill(string name)

    function formatBytes(bytes) {
        const b = Number(bytes) || 0
        if (b >= 1099511627776) return (b / 1099511627776).toFixed(2) + " TB"
        if (b >= 1073741824)    return (b / 1073741824).toFixed(1) + " GB"
        if (b >= 1048576)       return (b / 1048576).toFixed(1) + " MB"
        if (b >= 1024)          return (b / 1024).toFixed(0) + " KB"
        return b + " B"
    }

    property var tiles: []

    property var _slotNames: []
    property string _slotKey: ""
    property bool _awaitingScan: false

    property int revealToken: 0
    property real enterScale: 0.94
    property real tileLayerOpacity: 1
    property bool instant: false

    property var morphRect: null
    property string morphColor: "transparent"
    property string morphTextColor: "transparent"
    property string morphLabel: ""
    property real morphT: 0
    property real morphOpacity: 0
    property bool morphing: false

    readonly property var _fills: [
        Colors.primaryContainer,
        Colors.secondaryContainer,
        Colors.tertiaryContainer
    ]
    readonly property var _texts: [
        Colors.primaryContainerText,
        Colors.secondaryContainerText,
        Colors.tertiaryContainerText
    ]

    onItemsChanged: {
        if (root._awaitingScan) {
            root._maybeReveal(false)
            return
        }
        root._rebuild()
    }
    onWidthChanged: root._reflow()
    onHeightChanged: root._reflow()

    onItemsKeyChanged: root._maybeReveal(false)

    onScanKeyChanged: root._awaitingScan = true

    function _maybeReveal(fromMorph) {
        if (!root._awaitingScan) return
        if (root.morphing) return
        if (root.itemsKey !== root.scanKey) return

        root._awaitingScan = false
        root._slotKey = root.scanKey
        root._slotNames = []
        root.enterScale = fromMorph ? 1.06 : 0.94
        root.tileLayerOpacity = 1
        root._rebuild()
        root.revealToken++
    }

    function _lerp(a, b, t) { return a + (b - a) * t }

    function _reflow() {
        root.instant = true
        root._rebuild()
        Qt.callLater(() => root.instant = false)
    }

    function _splitLayout(list, x, y, w, h, out) {
        if (list.length === 0) return
        if (list.length === 1) {
            out.push({ item: list[0], x: x, y: y, w: w, h: h })
            return
        }

        let total = 0
        for (let i = 0; i < list.length; i++) total += list[i].bytes

        let half = 0
        let split = 1
        for (let i = 0; i < list.length - 1; i++) {
            half += list[i].bytes
            split = i + 1
            if (half >= total / 2) break
        }

        let frac = total > 0 ? half / total : 0.5
        frac = Math.max(0.05, Math.min(0.95, frac))

        const first = list.slice(0, split)
        const second = list.slice(split)

        if (w >= h) {
            root._splitLayout(first, x, y, w * frac, h, out)
            root._splitLayout(second, x + w * frac, y, w * (1 - frac), h, out)
        } else {
            root._splitLayout(first, x, y, w, h * frac, out)
            root._splitLayout(second, x, y + h * frac, w, h * (1 - frac), out)
        }
    }

    function _rebuild() {
        if (root.width <= 0 || root.height <= 0 || root.items.length === 0) {
            root.tiles = []
            root._slotNames = []
            return
        }
        const list = []
        for (const it of root.items)
            list.push({ name: it.name, bytes: Math.max(1, it.bytes), isDir: it.isDir })

        const out = []
        root._splitLayout(list, 0, 0, root.width, root.height, out)
        root.tiles = root._assignSlots(out)
    }

    function _assignSlots(cells) {
        if (root.scanKey !== root._slotKey) {
            root._slotKey = root.scanKey
            root._slotNames = []
        }

        const byName = ({})
        for (let i = 0; i < cells.length; i++) byName[cells[i].item.name] = cells[i]

        const names = root._slotNames.slice()
        const placed = []
        for (let i = 0; i < names.length; i++) {
            const c = byName[names[i]]
            if (c === undefined) {
                names[i] = ""
                placed[i] = null
            } else {
                placed[i] = c
                delete byName[names[i]]
            }
        }

        for (const n in byName) {
            let idx = names.indexOf("")
            if (idx === -1) {
                idx = names.length
                names.push("")
                placed.push(null)
            }
            names[idx] = n
            placed[idx] = byName[n]
        }

        while (placed.length > 0 && placed[placed.length - 1] === null) {
            placed.pop()
            names.pop()
        }

        root._slotNames = names
        return placed
    }

    function beginDrill(rect, fill, textColor, label, name) {
        root.morphRect = rect
        root.morphColor = fill
        root.morphTextColor = textColor
        root.morphLabel = label
        root.morphT = 0
        root.morphOpacity = 1
        root.morphing = true
        morphAnim.restart()
        root.drill(name)
    }

    SequentialAnimation {
        id: morphAnim

        ParallelAnimation {
            NumberAnimation {
                target: root; property: "morphT"; from: 0; to: 1
                duration: M3Motion.container.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3Motion.container.curve
            }
            NumberAnimation {
                target: root; property: "tileLayerOpacity"; from: 1; to: 0
                duration: M3Motion.container.crossFadeDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3Motion.container.alphaOut
            }
        }

        ScriptAction {
            script: {
                root.morphing = false
                root.enterScale = 1.06
                if (root._awaitingScan) {
                    root._maybeReveal(true)
                } else {
                    root.tileLayerOpacity = 1
                    root.revealToken++
                }
            }
        }

        NumberAnimation {
            target: root; property: "morphOpacity"; to: 0
            duration: M3Motion.container.crossFadeDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: M3Motion.container.alphaOut
        }

        ScriptAction { script: root.morphRect = null }
    }

    CustomText {
        anchors.centerIn: parent
        visible: root.tiles.length === 0 && !root.morphing
        content: root.busy ? "Scanning…" : root.emptyText
        size: 13
        customColor: Colors.outline

        opacity: visible ? 1 : 0
        Behavior on opacity { EffectsAnim {} }
    }

    Item {
        id: tileLayer
        anchors.fill: parent
        opacity: root.tileLayerOpacity

        Repeater {
            model: root.tiles.length

            delegate: Rectangle {
                id: tile
                required property int index

                readonly property var cell: tile.index < root.tiles.length ? root.tiles[tile.index] : null
                readonly property var entry: tile.cell ? tile.cell.item : null
                readonly property bool isDir: tile.entry ? tile.entry.isDir : false
                readonly property bool hovered: tileArea.containsMouse || tileRipple.containsMouse
                readonly property bool labelled: tile.width > 70 && tile.height > 38

                visible: tile.cell !== null && tile.cell !== undefined

                property bool geomReady: false

                x: (tile.cell ? tile.cell.x : 0) + 2
                y: (tile.cell ? tile.cell.y : 0) + 2
                width: Math.max(1, (tile.cell ? tile.cell.w : 0) - 4)
                height: Math.max(1, (tile.cell ? tile.cell.h : 0) - 4)
                radius: Math.min(12, Math.min(width, height) / 3)
                color: root._fills[tile.index % 3]
                opacity: 0
                scale: root.enterScale
                clip: true
                transformOrigin: Item.Center

                readonly property bool animateGeom: tile.geomReady && !root.instant

                Behavior on x      { enabled: tile.animateGeom; SpatialAnim { speed: "fast" } }
                Behavior on y      { enabled: tile.animateGeom; SpatialAnim { speed: "fast" } }
                Behavior on width  { enabled: tile.animateGeom; SpatialAnim { speed: "fast" } }
                Behavior on height { enabled: tile.animateGeom; SpatialAnim { speed: "fast" } }
                Behavior on color  { EffectsColorAnim {} }

                function playEnter() {
                    tile.geomReady = false
                    tile.opacity = 0
                    tile.scale = root.enterScale
                    enterAnim.restart()
                }

                SequentialAnimation {
                    id: enterAnim

                    PauseAnimation { duration: Math.min(tile.index, 12) * 16 }

                    ParallelAnimation {
                        EffectsAnim { target: tile; property: "opacity"; to: 1 }
                        SpatialAnim { target: tile; property: "scale"; to: 1; speed: "fast" }
                    }

                    ScriptAction { script: tile.geomReady = true }
                }

                Component.onCompleted: tile.playEnter()

                Connections {
                    target: root
                    function onRevealTokenChanged() { tile.playEnter() }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Colors.surfaceText
                    opacity: tile.hovered ? 0.06 : 0
                    Behavior on opacity { EffectsAnim { speed: "fast" } }
                }

                Column {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 9
                    spacing: 1
                    width: tile.width - 18

                    opacity: tile.labelled ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { EffectsAnim { speed: "fast" } }

                    Row {
                        spacing: 5
                        width: parent.width

                        MaterialIconSymbol {
                            anchors.verticalCenter: nameText.verticalCenter
                            content: tile.isDir ? "folder" : "draft"
                            iconSize: 13
                            fill: tile.isDir ? 1 : 0
                            customColor: root._texts[tile.index % 3]
                            opacity: 0.75
                        }

                        CustomText {
                            id: nameText
                            width: parent.width - 18
                            content: tile.entry ? tile.entry.name : ""
                            size: 12
                            weight: 600
                            elide: Text.ElideMiddle
                            customColor: root._texts[tile.index % 3]
                        }
                    }

                    CustomText {
                        content: root.formatBytes(tile.entry ? tile.entry.bytes : 0)
                        size: 11
                        opacity: 0.8
                        customColor: root._texts[tile.index % 3]
                    }
                }

                MouseArea {
                    id: tileArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor
                }

                RippleEffect {
                    id: tileRipple
                    anchors.fill: parent
                    radius: tile.radius
                    enabled: tile.isDir && !root.morphing
                    hoverColor: "transparent"
                    rippleColor: Qt.alpha(root._texts[tile.index % 3], 0.20)
                    onClicked: {
                        if (!tile.entry || !tile.isDir) return
                        root.beginDrill(
                            { x: tile.x, y: tile.y, w: tile.width, h: tile.height, r: tile.radius },
                            tile.color,
                            root._texts[tile.index % 3],
                            tile.entry.name,
                            tile.entry.name)
                    }
                }

                CustomToolTip {
                    content: (tile.entry ? tile.entry.name : "") + "  ·  "
                        + root.formatBytes(tile.entry ? tile.entry.bytes : 0)
                    visible: tile.hovered
                }
            }
        }
    }

    Rectangle {
        id: morph
        z: 5
        visible: root.morphRect !== null && root.morphOpacity > 0
        opacity: root.morphOpacity
        color: root.morphColor

        readonly property var from: root.morphRect

        x: root._lerp(morph.from ? morph.from.x : 0, 0, root.morphT)
        y: root._lerp(morph.from ? morph.from.y : 0, 0, root.morphT)
        width: root._lerp(morph.from ? morph.from.w : 0, root.width, root.morphT)
        height: root._lerp(morph.from ? morph.from.h : 0, root.height, root.morphT)
        radius: root._lerp(morph.from ? morph.from.r : 0, 12, root.morphT)
        clip: true

        Row {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 9
            spacing: 5
            opacity: Math.max(0, 1 - root.morphT * 2.5)

            MaterialIconSymbol {
                anchors.verticalCenter: morphText.verticalCenter
                content: "folder"
                iconSize: 13
                fill: 1
                customColor: root.morphTextColor
                opacity: 0.75
            }

            CustomText {
                id: morphText
                content: root.morphLabel
                size: 12
                weight: 600
                customColor: root.morphTextColor
            }
        }
    }
}
