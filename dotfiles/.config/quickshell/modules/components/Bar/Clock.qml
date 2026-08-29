import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapesFn

// The bar's centre slot. Shows the clock, the music player, or both side by
// side, per SettingsConfig.general.barCenter — and expands on hover into the
// calendar, the full player, or both.
//
// Kept as Clock.qml with the `clock` id at both call sites because Layout.qml's
// pill-shape maths carves the bar outline from this item's x/width/height — the
// centre section's geometry contract is what the shape depends on, not what it
// happens to be showing.
Item{
    id: clock
    implicitWidth: container.width
    implicitHeight: container.height
    anchors.horizontalCenter: parent.horizontalCenter
    property alias container: container

    readonly property string centerMode: SettingsConfig.general.barCenter ?? "clock"
    readonly property bool showClock: clock.centerMode !== "music"
    readonly property bool showMusic: clock.centerMode !== "clock"
    readonly property bool bothMode:  clock.centerMode === "both"

    Item{
        id: container
        property bool isClicked: hoverHandler.hovered
        anchors.horizontalCenter: parent.horizontalCenter

        // Collapsed width tracks whichever content is loaded; expanded size is
        // per-mode, since a calendar wants a square, a player wants a landscape
        // panel, and the pair wants the square plus a column beside it.
        readonly property real collapsedWidth: collapsedRow.implicitWidth + 30

        readonly property real expandedWidth:
            clock.bothMode            ? Appearance.size.calanderWidth + 300
          : clock.centerMode === "music" ? 470
                                         : Appearance.size.calanderWidth

        readonly property real expandedHeight:
            clock.centerMode === "music" ? 186 : Appearance.size.calanderHeight

        implicitWidth:  isClicked ? expandedWidth  : collapsedWidth
        implicitHeight: isClicked ? expandedHeight : Appearance.size.clockHeight

        HoverHandler{
            id: hoverHandler
        }

        Behavior on implicitWidth{
            NumberAnimation{
                duration: Appearance.duration.large
                easing.type: Easing.OutQuad
            }
        }

        Behavior on implicitHeight{
            NumberAnimation{
                duration: Appearance.duration.large
                easing.type: Easing.OutQuad
            }
        }

        // ── Collapsed content ─────────────────────────────────────────
        readonly property bool collapsed: container.height === Appearance.size.clockHeight

        // A Row positioner rather than a RowLayout: CustomClock and BarMusic
        // both centre themselves with anchors, which a layout would refuse. The
        // fixed-height wrapper slots give them a parent to centre against and
        // keep the three items on a common baseline.
        Row{
            id: collapsedRow
            anchors.centerIn: parent
            visible: container.collapsed
            spacing: 12

            Item{
                width: clockText.implicitWidth
                height: Appearance.size.clockHeight
                visible: clock.showClock

                CustomClock{ id: clockText }
            }

            Item{
                width: 1
                height: Appearance.size.clockHeight
                visible: clock.bothMode

                Rectangle{
                    anchors.centerIn: parent
                    width: 1
                    height: 18
                    color: Colors.outlineVariant
                    opacity: 0.7
                }
            }

            Item{
                width: musicText.implicitWidth
                height: Appearance.size.clockHeight
                visible: clock.showMusic

                // Halved in both mode — the clock has taken the other half of
                // the slot, and a wide title would push the bar off centre.
                BarMusic{
                    id: musicText
                    maxTextWidth: clock.bothMode ? 110 : 160
                }
            }
        }

        // ── Expanded content ──────────────────────────────────────────
        // Held back until the size animation finishes, otherwise the panel
        // renders at the collapsed width and reflows as the bar grows.
        Loader{
            id: expandedLoader
            active: container.isClicked
            anchors.fill: parent
            visible: false
            opacity: visible ? 1 : 0
            Behavior on opacity{
                NumberAnimation{
                    duration: 300
                }
            }
            Timer{
                id: showTimer
                interval: Appearance.duration.large
                running: container.isClicked
                onTriggered:{
                    expandedLoader.visible = true
                }
            }
            Timer{
                id: hideTimer
                interval: Appearance.duration.small
                running: !container.isClicked && expandedLoader.visible
                onTriggered:{
                    expandedLoader.visible = false
                }
            }
            sourceComponent: clock.bothMode               ? bothComp
                           : clock.centerMode === "music" ? musicPanelComp
                                                          : calanderComp
        }

        Component{ id: calanderComp;   Calander{} }
        Component{ id: musicPanelComp; BarMusicPanel{} }
        Component{ id: bothComp;       BarCenterBoth{} }
    }
}
