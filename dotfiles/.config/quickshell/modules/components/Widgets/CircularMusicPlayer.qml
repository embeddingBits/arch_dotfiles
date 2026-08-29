import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell
import QtQuick.Effects
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

WidgetHost {
    id: root
    configKey: "musicPlayer"
    defaultPos: Qt.point(200, 200)
    visible: true
    implicitHeight: 500
    implicitWidth: 500

    // Never start audio capture for a gallery thumbnail
    Component.onCompleted: if (!root.preview) ServiceCava.retain()
    Component.onDestruction: if (!root.preview) ServiceCava.release()

    // Settings load asynchronously via a 100ms timer in SettingsConfig,
    // so widgets.musicPlayerX may not be ready at Component.onCompleted time.
    // React to the load completing here.

    Canvas {
        id: outerVizShape
        anchors.centerIn: parent
        width: 540
        height: 540
        antialiasing: true

        property real shapeRotation: 0
        property color fillColor: Qt.alpha(Colors.primary, 0.4)

        NumberAnimation on shapeRotation {
            from: 0; to: 360
            duration: 20000
            loops: Animation.Infinite
            running: ServiceMusic.isPlaying
        }

        onShapeRotationChanged: requestPaint()
        onFillColorChanged: requestPaint()

        Connections {
            target: ServiceCava
            function onCavaData12Changed() { outerVizShape.requestPaint() }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2
            const cy = height / 2

            const scale      = Math.min(width, height) / 130
            const baseOuterR = 44 * scale
            const valleyR    = 35 * scale
            const maxExt     = 25 * scale

            const rotRad = shapeRotation * Math.PI / 180
            const data   = ServiceCava.cavaData12
            const verts  = []

            for (let i = 0; i < 12; i++) {
                const tipAngle = (Math.PI / 6  * (i + 1))     + rotRad
                const valAngle = (Math.PI / 12 * (2 * i + 3)) + rotRad
                const tipR     = baseOuterR + (data.length === 12 ? data[i] : 0) * maxExt

                verts.push({ x: cx + tipR    * Math.cos(tipAngle),
                y: cy + tipR    * Math.sin(tipAngle) })
                verts.push({ x: cx + valleyR * Math.cos(valAngle),
                y: cy + valleyR * Math.sin(valAngle) })
            }

            ctx.beginPath()
            const last  = verts[verts.length - 1]
            const first = verts[0]
            ctx.moveTo((last.x + first.x) / 2, (last.y + first.y) / 2)

            for (let i = 0; i < verts.length; i++) {
                const cur  = verts[i]
                const next = verts[(i + 1) % verts.length]
                ctx.quadraticCurveTo(cur.x, cur.y,
                (cur.x + next.x) / 2,
                (cur.y + next.y) / 2)
            }

            ctx.closePath()
            ctx.fillStyle = fillColor
            ctx.fill()
        }
    }

    // ── Visualizer canvas ──────────────────────────────────────────
    Canvas {
        id: vizShape
        anchors.centerIn: parent
        width: 500
        height: 500
        antialiasing: true

        property real shapeRotation: 0
        property color fillColor: Colors.primary

        NumberAnimation on shapeRotation {
            from: 0; to: 360
            duration: 20000
            loops: Animation.Infinite
            running: ServiceMusic.isPlaying
        }

        onShapeRotationChanged: requestPaint()
        onFillColorChanged: requestPaint()

        Connections {
            target: ServiceCava
            function onCavaData12Changed() { vizShape.requestPaint() }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2
            const cy = height / 2

            const scale      = Math.min(width, height) / 130
            const baseOuterR = 44 * scale
            const valleyR    = 35 * scale
            const maxExt     = 25 * scale

            const rotRad = shapeRotation * Math.PI / 180
            const data   = ServiceCava.cavaData12
            const verts  = []

            for (let i = 0; i < 12; i++) {
                const tipAngle = (Math.PI / 6  * (i + 1))     + rotRad
                const valAngle = (Math.PI / 12 * (2 * i + 3)) + rotRad
                const tipR     = baseOuterR + (data.length === 12 ? data[i] : 0) * maxExt

                verts.push({ x: cx + tipR    * Math.cos(tipAngle),
                y: cy + tipR    * Math.sin(tipAngle) })
                verts.push({ x: cx + valleyR * Math.cos(valAngle),
                y: cy + valleyR * Math.sin(valAngle) })
            }

            ctx.beginPath()
            const last  = verts[verts.length - 1]
            const first = verts[0]
            ctx.moveTo((last.x + first.x) / 2, (last.y + first.y) / 2)

            for (let i = 0; i < verts.length; i++) {
                const cur  = verts[i]
                const next = verts[(i + 1) % verts.length]
                ctx.quadraticCurveTo(cur.x, cur.y,
                (cur.x + next.x) / 2,
                (cur.y + next.y) / 2)
            }

            ctx.closePath()
            ctx.fillStyle = fillColor
            ctx.fill()
        }
    }

    // ── Cookie12 mask shape ────────────────────────────────────────
    Item {
        id: artMask
        width: 300
        height: 300
        anchors.centerIn: parent
        layer.enabled: true
        visible: false

        MaterialShapes.ShapeCanvas {
            anchors.fill: parent
            roundedPolygon: MaterialShapeFn.getCookie12Sided()
            color: "white"

            NumberAnimation on rotation {
                from: 0; to: 360
                duration: 20000
                loops: Animation.Infinite
                running: ServiceMusic.isPlaying
            }
        }
    }

    // ── Pass 1: raw album art layer ────────────────────────────────
    Item {
        id: blurredArt
        width: 300
        height: 300
        anchors.centerIn: parent
        visible: false
        layer.enabled: true

        Image {
            anchors.fill: parent
            sourceSize.width: 300
            sourceSize.height: 300
            fillMode: Image.PreserveAspectCrop
            source: ServiceMusic.activeTrack?.artUrl ?? ""
        }
    }

    // // ── Pass 2: blurred version of that layer ──────────────────────
    MultiEffect {
        id: blurredArtEffect
        source: blurredArt
        anchors.fill: blurredArt
        visible: false
        layer.enabled: true
        blurEnabled: true
        blur: 0.3
        blurMax: 64
        autoPaddingEnabled: true
        saturation: -0.2
    }

    // ── Pass 3: composited content ─────────────────────────────────
    Item {
        id: artContent
        width: 300
        height: 300
        anchors.centerIn: parent
        visible: false
        layer.enabled: true

        // // Sharp album art
        Image {
            anchors.fill: parent
            sourceSize.width: 300
            sourceSize.height: 300
            fillMode: Image.PreserveAspectCrop
            source: ServiceMusic.activeTrack?.artUrl ?? ""
        }

        // // Clipping container — shows only bottom 160px of blurred art
        Item {
            width: 300
            height: 300
            clip: true

            MultiEffect {
                source: blurredArtEffect
                width: 300
                height: 300
            }
        }

        // Dark tint over the blur
        Rectangle {
            id: container
            width: 300
            height: 300
            color: Qt.rgba(0, 0, 0, 0.55)
        }

    }

    // ── Final mask ─────────────────────────────────────────────────
    MultiEffect {
        source: artContent
        anchors.fill: artContent
        maskEnabled: true
        maskSource: artMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    ColumnLayout{
        anchors.centerIn: parent
  
        CustomText{
            Layout.alignment: Qt.AlignCenter
            Layout.maximumWidth: container.width - 60
            content: ServiceMusic.activeTrack?.identity ?? "Unknown"
            size: 14
        }
        CustomText{
            Layout.alignment: Qt.AlignCenter
            Layout.maximumWidth: container.width - 80
            content: ServiceMusic.activeTrack?.title ?? "Unknown Title"
            size: 17
            color: Colors.primary
        }

        CustomText{
            Layout.alignment: Qt.AlignCenter
            Layout.maximumWidth: container.width - 60
            content: ServiceMusic.activeTrack?.artist ?? "Unknown Artist"
            color: Colors.outline
            size: 12
        }

        RowLayout{
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 30
            spacing: 20

            Rectangle{
                implicitHeight: 50
                implicitWidth: 45
                radius: width / 2
                color: Colors.primary

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "skip_previous"
                    iconSize: 30
                    color: Colors.primaryText

                    MouseArea{
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked:{
                            ServiceMusic.previous()
                        }
                    }
                }
            }

            M3WavyCircularProgress {
                implicitWidth: 64
                implicitHeight: 64
                progress: ServiceMusic.trackLength > 0
                    ? Math.max(0, Math.min(1, (ServiceMusic.activePlayer?.position ?? 0) / ServiceMusic.trackLength))
                    : 0
                thickness: 3
                sperm: false
                gap: 0.2
                spermFrequency: 12
                animateSperm: false

                MaterialShapes.ShapeCanvas {
                    anchors.centerIn: parent
                    implicitWidth: 50
                    implicitHeight: 50
                    roundedPolygon: MaterialShapeFn.getCookie12Sided()
                    color: Colors.primary

                    MaterialIconSymbol{
                        anchors.centerIn: parent
                        content: ServiceMusic.isPlaying ? "pause" : "play_arrow"
                        iconSize: 30
                        color: Colors.primaryText

                        MouseArea{
                            anchors.fill: parent
                            enabled: !root.lifted

                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked:{
                                ServiceMusic.togglePlaying()
                            }
                        }
                    }
                }
            }

            Rectangle{
                implicitHeight: 50
                implicitWidth: 45
                radius: width / 2
                color: Colors.primary
                MaterialIconSymbol{
                    anchors.centerIn: parent
                    content: "skip_next"
                    iconSize: 30
                    color: Colors.primaryText

                    MouseArea{
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked:{
                            ServiceMusic.next()
                        }
                    }

                }
            }

        }

    }
}

