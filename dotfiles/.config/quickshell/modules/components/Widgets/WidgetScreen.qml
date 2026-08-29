import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick.Layouts
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents


PanelWindow{
    id: widgetScreen
    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: true

    // Normally parked behind windows. Arrange mode has to come forward and take
    // the keyboard, otherwise the widgets are unreachable and Esc never arrives.
    WlrLayershell.namespace: "quickshell:backgroundWidgets"
    WlrLayershell.layer: GlobalStates.widgetEditMode ? WlrLayer.Top : WlrLayer.Bottom

    // Three states rather than two. A layer surface with None can be clicked but
    // never receives key events, so text fields were untypable; leaving it on
    // OnDemand permanently meant the surface kept the keyboard and no other
    // window could be typed into. So: ask for the keyboard only while a widget
    // text field actually holds focus, and drop straight back to None after.
    WlrLayershell.keyboardFocus: GlobalStates.widgetEditMode  ? WlrKeyboardFocus.Exclusive
                               : GlobalStates.widgetTextFocus ? WlrKeyboardFocus.OnDemand
                                                              : WlrKeyboardFocus.None

    // Parking spot for focus. Clicking empty desktop moves QML focus here, which
    // makes the text field report activeFocus false and releases the keyboard.
    Item { id: focusSink }

    // Sits under everything: a click that a widget already consumed never
    // reaches it, so only clicks on bare desktop drop the field's focus.
    MouseArea {
        anchors.fill: parent
        z: -2
        enabled: GlobalStates.widgetTextFocus && !GlobalStates.widgetEditMode
        onPressed: mouse => {
            focusSink.forceActiveFocus()
            mouse.accepted = false
        }
    }
    color: "transparent"

    // ── Arrange mode: grid + scrim, behind the widgets ────────────────
    Rectangle {
        anchors.fill: parent
        z: -1
        visible: GlobalStates.widgetEditMode
        color: Qt.alpha(Colors.surface, 0.45)

        Canvas {
            id: gridCanvas
            anchors.fill: parent

            property color inkColor: Colors.surfaceText
            onInkColorChanged: requestPaint()
            onVisibleChanged: if (visible) requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()

                const g = WidgetSizes.gutter   // 20 — the snap interval
                const major = g * 5            // 100 — alignment guides

                // Major guides first, so the dots sit on top of them
                ctx.strokeStyle = Qt.alpha(inkColor, 0.20)
                ctx.lineWidth = 1
                ctx.beginPath()
                for (let x = 0; x <= width; x += major) {
                    ctx.moveTo(Math.floor(x) + 0.5, 0)
                    ctx.lineTo(Math.floor(x) + 0.5, height)
                }
                for (let y = 0; y <= height; y += major) {
                    ctx.moveTo(0, Math.floor(y) + 0.5)
                    ctx.lineTo(width, Math.floor(y) + 0.5)
                }
                ctx.stroke()

                // Snap dots
                ctx.fillStyle = Qt.alpha(inkColor, 0.55)
                for (let x = 0; x <= width; x += g)
                    for (let y = 0; y <= height; y += g)
                        ctx.fillRect(x - 1, y - 1, 2, 2)
            }
        }
    }

    // Esc leaves arrange mode
    Item {
        anchors.fill: parent
        focus: GlobalStates.widgetEditMode
        Keys.onEscapePressed: GlobalStates.widgetEditMode = false
    }

    // ── Arrange mode hint bar ─────────────────────────────────────────
    Rectangle {
        z: 200
        visible: GlobalStates.widgetEditMode
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 24
        implicitWidth: hintRow.implicitWidth + 34
        implicitHeight: 42
        radius: 21
        color: Colors.surfaceContainerHigh

        RowLayout {
            id: hintRow
            anchors.centerIn: parent
            spacing: 12

            MaterialIconSymbol { content: "drag_pan"; iconSize: 17; customColor: Colors.primary }
            CustomText { content: "Drag widgets to arrange"; size: 13 }

            Rectangle {
                implicitWidth: 1; implicitHeight: 18
                color: Colors.outlineVariant; opacity: 0.5
            }

            CustomText {
                content: "Done"
                size: 13
                customColor: Colors.primary
                weight: 700
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: GlobalStates.widgetEditMode = false
                }
            }
        }
    }

    Loader {
        active: SettingsConfig.widgets.showCircularMusicPlayer ?? true
        visible: active
        sourceComponent: CircularMusicPlayer {}
    }

    Loader {
        active: SettingsConfig.widgets.showClock ?? false
        visible: active
        sourceComponent: {
            var style = SettingsConfig.widgets.digitalClockStyle ?? "classic"
            if (style === "minimal") return digitalMinimal
            if (style === "stacked") return digitalStacked
            if (style === "outline") return digitalOutline
            if (style === "echo")    return digitalEcho
            if (style === "column")  return digitalColumn
            if (style === "ticker")  return digitalTicker
            if (style === "slab")    return digitalSlab
            if (style === "thin")    return digitalThin
            if (style === "pair")    return digitalPair
            return digitalClassic
        }
    }

    Component { id: digitalClassic; NewClock            {} }
    Component { id: digitalMinimal; DigitalClockMinimal {} }
    Component { id: digitalStacked; DigitalClockStacked {} }
    Component { id: digitalOutline; DigitalClockOutline {} }
    Component { id: digitalEcho;    DigitalClockEcho    {} }
    Component { id: digitalColumn;  DigitalClockColumn  {} }
    Component { id: digitalTicker;  DigitalClockTicker  {} }
    Component { id: digitalSlab;    DigitalClockSlab    {} }
    Component { id: digitalThin;    DigitalClockThin    {} }
    Component { id: digitalPair;    DigitalClockPair    {} }

    Loader {
        active: SettingsConfig.widgets.showDateWidget ?? false
        visible: active
        sourceComponent: {
            var style = SettingsConfig.widgets.dateWidgetStyle ?? "default"
            if (style === "calendar") return dateCalendar
            if (style === "pill")     return datePill
            if (style === "split")    return dateSplit
            if (style === "bold")     return dateBold
            if (style === "ghost")    return dateGhost
            if (style === "accent")   return dateAccent
            if (style === "inline")   return dateInline
            return dateDefault
        }
    }

    Component { id: dateDefault;  DateWidget         {} }
    Component { id: dateCalendar; DateWidgetCalendar {} }
    Component { id: datePill;     DateWidgetPill     {} }
    Component { id: dateSplit;    DateWidgetSplit     {} }
    Component { id: dateBold;     DateWidgetBold     {} }
    Component { id: dateGhost;    DateWidgetGhost    {} }
    Component { id: dateAccent;   DateWidgetAccent   {} }
    Component { id: dateInline;   DateWidgetInline   {} }

    Loader {
        active: SettingsConfig.widgets.showAnalogClock ?? false
        visible: active
        sourceComponent: {
            var style = SettingsConfig.widgets.analogClockStyle ?? "classic"
            if (style === "minimal") return analogMinimal
            if (style === "shape")   return analogShape
            return analogClassic
        }
    }

    Component { id: analogClassic; AnalogClockClassic {} }
    Component { id: analogMinimal; AnalogClockMinimal {} }
    Component { id: analogShape;   AnalogClockShape   {} }

    Loader {
        active: SettingsConfig.widgets.showWeatherSlanted ?? false
        visible: active
        sourceComponent: WeatherWidgetSlanted {}
    }

    Loader {
        active: SettingsConfig.widgets.showWeatherForecast ?? false
        visible: active
        sourceComponent: WeatherWidgetForecast {}
    }

    Loader {
        active: SettingsConfig.widgets.showWeatherDetails ?? false
        visible: active
        sourceComponent: WeatherWidgetDetails {}
    }

    Loader {
        active: SettingsConfig.widgets.showWeatherHourly ?? false
        visible: active
        sourceComponent: WeatherHourlyWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showWeatherWind ?? false
        visible: active
        sourceComponent: WeatherWindWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showWeatherBarometer ?? false
        visible: active
        sourceComponent: WeatherBarometerWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showSunArc ?? false
        visible: active
        sourceComponent: SunArcWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showPomodoro ?? false
        visible: active
        sourceComponent: PomodoroWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showSystemMonitor ?? false
        visible: active
        sourceComponent: {
            var style = SettingsConfig.widgets.systemMonitorStyle ?? "default"
            if (style === "compact") return sysCompact
            if (style === "pulse")   return sysPulse
            return sysDefault
        }
    }

    Component { id: sysDefault; SystemMonitorWidget  {} }
    Component { id: sysCompact; SystemMonitorCompact {} }
    Component { id: sysPulse;   SystemMonitorPulse   {} }

    Loader {
        active: SettingsConfig.widgets.showBattery ?? false
        visible: active
        sourceComponent: {
            var style = SettingsConfig.widgets.batteryStyle ?? "default"
            if (style === "minimal") return battMinimal
            if (style === "ring")    return battRing
            return battDefault
        }
    }

    Component { id: battDefault; BatteryWidget        {} }
    Component { id: battMinimal; BatteryWidgetMinimal {} }
    Component { id: battRing;    BatteryWidgetRing    {} }

    Loader {
        active: SettingsConfig.widgets.showProfileCard ?? false
        visible: active
        sourceComponent: (SettingsConfig.widgets.profileCardStyle ?? "card") === "tile"
            ? profileTile : profileCardComp
    }

    Component { id: profileCardComp; ProfileCard {} }
    Component { id: profileTile;     ProfileTile {} }

    Loader {
        active: SettingsConfig.widgets.showMoonPhase ?? false
        visible: active
        sourceComponent: MoonPhaseWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showStickyNote ?? false
        visible: active
        sourceComponent: StickyNoteWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showHeadlines ?? false
        visible: active
        sourceComponent: HeadlinesWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showTaskList ?? false
        visible: active
        sourceComponent: TaskListWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showNetworkGraph ?? false
        visible: active
        sourceComponent: NetworkGraphWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showSpectrum ?? false
        visible: active
        sourceComponent: SpectrumWidget {}
    }

    Loader {
        active: SettingsConfig.widgets.showAlbumArt ?? false
        visible: active
        sourceComponent: AlbumArtWidget {}
    }

}
