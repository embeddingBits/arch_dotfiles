import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Night-side companion to the sun arc. wttr.in already returns moon_phase,
// moon_illumination, moonrise and moonset with every weather refresh — none of
// it was being read anywhere, so this widget costs no extra fetching.
WidgetHost {
    id: root
    configKey: "moonPhase"
    tile: WidgetSizes.small
    defaultPos: Qt.point(620, 440)

    readonly property var astro: ServiceWeather.astronomy

    readonly property string phaseName: root.preview ? "Waxing Gibbous"
                                                     : (astro?.moon_phase ?? "—")

    // wttr.in reports illumination as a percentage string
    readonly property real illum: {
        if (root.preview) return 0.72
        const v = parseFloat(astro?.moon_illumination ?? "")
        return isNaN(v) ? 0 : Math.max(0, Math.min(1, v / 100))
    }

    // Waxing = lit on the right, waning = lit on the left
    readonly property bool waxing: {
        const p = (root.phaseName ?? "").toLowerCase()
        if (p.indexOf("waning") !== -1) return false
        if (p.indexOf("last") !== -1)   return false
        return true
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        CustomText {
            x: 20; y: 16
            content: "Moon"
            size: 13
            customColor: Colors.primary
        }

        // ── Disc ──────────────────────────────────────────────────────
        Canvas {
            id: moon
            width: 92; height: 92
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 40
            antialiasing: true

            property color litColor: Colors.surfaceText
            property color shadowColor: Colors.surfaceContainerHighest
            property real  frac: root.illum
            property bool  wax: root.waxing

            onLitColorChanged: requestPaint()
            onShadowColorChanged: requestPaint()
            onFracChanged: requestPaint()
            onWaxChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()

                const cx = width / 2, cy = height / 2
                const r = Math.min(width, height) / 2 - 1
                const f = frac

                ctx.save()
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                ctx.clip()

                // Unlit disc
                ctx.fillStyle = shadowColor
                ctx.fillRect(cx - r - 1, cy - r - 1, 2 * r + 2, 2 * r + 2)

                // Lit half — right when waxing, left when waning
                ctx.fillStyle = litColor
                ctx.beginPath()
                if (wax) ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI / 2, false)
                else     ctx.arc(cx, cy, r,  Math.PI / 2, 3 * Math.PI / 2, false)
                ctx.closePath()
                ctx.fill()

                // The terminator is an ellipse whose half-width shrinks to zero
                // at the quarters. Past half it *adds* light (gibbous), before
                // half it *removes* it (crescent).
                const rx = r * Math.abs(1 - 2 * f)
                if (rx > 0.5) {
                    ctx.fillStyle = (f > 0.5) ? litColor : shadowColor
                    ctx.save()
                    ctx.translate(cx, cy)
                    ctx.scale(rx / r, 1)
                    ctx.beginPath()
                    ctx.arc(0, 0, r, 0, 2 * Math.PI)
                    ctx.closePath()
                    ctx.restore()   // path keeps its transformed points
                    ctx.fill()
                }

                ctx.restore()
            }
        }

        // ── Readout ───────────────────────────────────────────────────
        ColumnLayout {
            width: parent.width
            anchors.top: moon.bottom
            anchors.topMargin: 10
            spacing: 0

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: root.phaseName
                size: 13
                weight: 700
            }

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: Math.round(root.illum * 100) + "% lit"
                size: 11
                customColor: Colors.outline
            }
        }

        // ── Moonrise / moonset ────────────────────────────────────────
        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            anchors.bottomMargin: 12
            spacing: 4

            MaterialIconSymbol { content: "arrow_upward"; iconSize: 11; customColor: Colors.outline }
            CustomText {
                content: root.preview ? "07:12 PM" : (root.astro?.moonrise ?? "—")
                size: 11
                customColor: Colors.outline
            }

            Item { Layout.fillWidth: true }

            MaterialIconSymbol { content: "arrow_downward"; iconSize: 11; customColor: Colors.outline }
            CustomText {
                content: root.preview ? "06:04 AM" : (root.astro?.moonset ?? "—")
                size: 11
                customColor: Colors.outline
            }
        }
    }
}
