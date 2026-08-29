import Quickshell
import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    property int focalCount: 3
    readonly property var paths: ServiceWallpaper.wallpapers
    readonly property real tileSize: view.tileSize
    readonly property real decodeWidth: Math.max(320, Math.ceil(view.tileSize / 160) * 160)

    ListView {
        id: view
        anchors.fill: parent
        orientation: ListView.Horizontal
        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2500
        maximumFlickVelocity: 8000
        pixelAligned: false

        property real itemSpacing: 10
        spacing: itemSpacing

        readonly property real itemRadius: 28
        readonly property real xSmallSize: 10

        readonly property var arrangement: {
            const W = width, sp = itemSpacing
            if (W <= 0)
                return { n: 1, m: 0, large: Math.max(1, W), medium: 0, small: 0 }

            const cands = []
            for (const m of [1, 0]) {
                for (let n = 1; n <= 6; n++) {
                    let S = 48, L = 0
                    for (let k = 0; k < 10; k++) {
                        L = (W - S * (1 + m / 2) - (n + m) * sp) / (n + m / 2)
                        S = Math.max(40, Math.min(56, L * 0.3))
                    }
                    if (L <= S * 1.2) continue
                    cands.push({ cost: Math.abs(n - root.focalCount) * 1000 + m, n: n, m: m, L: L, S: S })
                }
            }

            let best = null
            for (const c of cands)
                if (best === null || c.cost < best.cost) best = c

            if (best === null) {
                const L = Math.max(1, W)
                return { n: 1, m: 0, large: L, medium: L, small: L }
            }
            return { n: best.n, m: best.m, large: best.L, small: best.S,
                     medium: (best.L + best.S) / 2 }
        }

        readonly property real tileSize: arrangement.large
        readonly property real pitch: tileSize + itemSpacing
        readonly property real focalLoc: tileSize / 2
        readonly property real focalSpan: arrangement.n * tileSize
                                        + (arrangement.n - 1) * itemSpacing

        rightMargin: Math.max(0, width - focalSpan)

        displayMarginBeginning: Math.ceil(pitch)
        displayMarginEnd: Math.ceil(Math.max(0, tileSize
            + (arrangement.n + arrangement.m) * pitch - width))
        cacheBuffer: Math.ceil(pitch * 2)

        readonly property real minContentX: 0
        readonly property real maxContentX: Math.max(0, contentWidth + rightMargin - width)

        property real wheelAccum: 0

        readonly property var keylines: {
            const sp = itemSpacing, L = tileSize, p = pitch
            const n = arrangement.n, m = arrangement.m
            const S = arrangement.small, M = arrangement.medium, xS = xSmallSize

            const k = []
            k.push({ io: -1, lo: -(sp + xS / 2), sz: xS })
            k.push({ io: 0,  lo: focalLoc,       sz: L  })
            if (n > 1)
                k.push({ io: n - 1, lo: focalLoc + (n - 1) * p, sz: L })

            let lo = focalLoc + (n - 1) * p, prev = L, io = n - 1
            if (m === 1) {
                lo += prev / 2 + sp + M / 2; prev = M; io += 1
                k.push({ io: io, lo: lo, sz: M })
            }
            lo += prev / 2 + sp + S / 2;  prev = S; io += 1
            k.push({ io: io, lo: lo, sz: S })
            lo += prev / 2 + sp + xS / 2; io += 1
            k.push({ io: io, lo: lo, sz: xS })

            for (let j = 0; j < k.length; j++) k[j].loc = focalLoc + k[j].io * p
            return k
        }

        function sample(childLoc) {
            const k = keylines, last = k.length - 1
            if (childLoc <= k[0].loc)
                return { c: k[0].lo - (k[0].loc - childLoc), s: k[0].sz }
            if (childLoc >= k[last].loc)
                return { c: k[last].lo + (childLoc - k[last].loc), s: k[last].sz }
            for (let j = 0; j < last; j++) {
                if (childLoc > k[j + 1].loc) continue
                const a = k[j], b = k[j + 1]
                const span = b.loc - a.loc
                const u = span > 0 ? (childLoc - a.loc) / span : 0
                return { c: a.lo + (b.lo - a.lo) * u,
                         s: a.sz + (b.sz - a.sz) * u }
            }
            return { c: k[last].lo, s: k[last].sz }
        }

        function snapTarget(x) {
            const t = Math.round(x / pitch) * pitch
            return Math.max(minContentX, Math.min(maxContentX, t))
        }

        function glideTo(dest) {
            const d = Math.max(minContentX, Math.min(maxContentX, dest))
            if (Math.abs(d - contentX) < 0.5) return
            cancelFlick()
            wheelAnim.stop()
            wheelAnim.from = contentX
            wheelAnim.to = d
            wheelAnim.start()
        }

        function snapToNearest() { glideTo(snapTarget(contentX)) }

        onDraggingHorizontallyChanged: if (draggingHorizontally) wheelAnim.stop()
        onMovementEnded: if (!wheelAnim.running) snapToNearest()

        NumberAnimation {
            id: wheelAnim
            target: view
            property: "contentX"
            duration: 380
            easing.type: Easing.OutCubic
        }

        model: root.paths

        onModelChanged: Qt.callLater(() => { wheelAnim.stop(); view.contentX = 0 })
        Component.onCompleted: view.contentX = 0

        delegate: Item {
            id: slot
            required property string modelData
            required property int index

            width: view.tileSize
            height: view.height

            readonly property bool chosen: ServiceWallpaper.getOriginalPath(slot.modelData) === Colors.wallpaper

            readonly property real childLoc:
                slot.index * view.pitch + view.tileSize / 2 - view.contentX
            readonly property var keyline: view.sample(slot.childLoc)

            readonly property var band: {
                const c = slot.keyline.c, s = slot.keyline.s, W = view.width
                let l = c - s / 2, r = c + s / 2
                if (l < 0 && r > 0) l = 0
                if (r > W && l < W) r = Math.max(W, l)
                return { l: l, r: r }
            }

            readonly property real tileWidth: Math.max(0, slot.band.r - slot.band.l)
            readonly property real tileRadius: Math.min(view.itemRadius, slot.tileWidth / 2)
            readonly property real imageX: slot.keyline.c - view.tileSize / 2 - slot.band.l

            Rectangle {
                id: tile
                x: slot.band.l - slot.childLoc + slot.width / 2
                width: slot.tileWidth
                height: parent.height
                radius: slot.tileRadius
                color: Colors.surfaceContainerHigh

                Item {
                    id: masked
                    anchors.fill: parent

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: masked.width
                            height: masked.height
                            radius: slot.tileRadius
                        }
                    }

                    Image {
                        x: slot.imageX
                        width: view.tileSize
                        height: parent.height
                        source: "file://" + slot.modelData
                        sourceSize.width: root.decodeWidth
                        asynchronous: true
                        cache: true
                        smooth: true
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: slot.chosen ? 3 : 0
                    border.color: Colors.primary
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 10
                    width: 28
                    height: 28
                    radius: 14
                    visible: slot.chosen && slot.tileWidth > 70
                    color: Colors.primary

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: "check"
                        iconSize: 17
                        customColor: Colors.primaryText
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ServiceWallpaper.setWallpaper(slot.modelData)
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton

            onWheel: wheel => {
                wheel.accepted = false
                if (view.maxContentX <= view.minContentX) return

                if (wheel.phase === Qt.ScrollEnd) {
                    view.wheelAccum = 0
                    view.snapToNearest()
                    wheel.accepted = true
                    return
                }

                const px = wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y : wheel.pixelDelta.x
                const ang = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                if (px === 0 && ang === 0) return

                if (px !== 0) {
                    view.wheelAccum = 0
                    const d = Math.max(view.minContentX,
                        Math.min(view.maxContentX, view.contentX - px))
                    if (Math.abs(d - view.contentX) < 0.01) return
                    wheelAnim.stop()
                    view.cancelFlick()
                    view.contentX = d
                    wheel.accepted = true
                    return
                }

                const n = ang / 120
                if (view.wheelAccum !== 0 && (view.wheelAccum > 0) !== (n > 0))
                    view.wheelAccum = 0

                const base = wheelAnim.running ? wheelAnim.to : view.contentX
                const dest = Math.max(view.minContentX,
                    Math.min(view.maxContentX, view.snapTarget(base - n * view.pitch)))
                if (Math.abs(dest - view.contentX) < 0.5) return

                view.wheelAccum = n
                view.glideTo(dest)
                wheel.accepted = true
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.paths.length === 0
        radius: 24
        color: Colors.surfaceContainerHigh

        CustomText {
            anchors.centerIn: parent
            content: "No images in this folder"
            size: 13
            customColor: Colors.outline
        }
    }
}
