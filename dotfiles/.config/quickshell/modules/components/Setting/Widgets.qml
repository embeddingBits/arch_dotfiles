import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents
import "../Widgets" as W
import QtQuick.Controls

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 5

    // ── Reusable section header ───────────────────────────────────────────
    component SectionLabel: CustomText {
        Layout.topMargin: 20
        size: 13
        customColor: Colors.primary
    }

    // ── Live previews ─────────────────────────────────────────────────────
    // Each card renders the real widget with preview: true, which suppresses
    // positioning, dragging and (where it matters) expensive animation.
    Component { id: cProfileCard;   W.ProfileCard          { preview: true } }
    Component { id: cProfileTile;   W.ProfileTile          { preview: true } }
    Component { id: cMusicCircle;   W.CircularMusicPlayer  { preview: true } }
    Component { id: cClockClassic;  W.NewClock             { preview: true } }
    Component { id: cClockMinimal;  W.DigitalClockMinimal  { preview: true } }
    Component { id: cClockStacked;  W.DigitalClockStacked  { preview: true } }
    Component { id: cClockOutline;  W.DigitalClockOutline  { preview: true } }
    Component { id: cClockEcho;     W.DigitalClockEcho     { preview: true } }
    Component { id: cClockColumn;   W.DigitalClockColumn   { preview: true } }
    Component { id: cClockTicker;   W.DigitalClockTicker   { preview: true } }
    Component { id: cClockSlab;     W.DigitalClockSlab     { preview: true } }
    Component { id: cClockThin;     W.DigitalClockThin     { preview: true } }
    Component { id: cClockPair;     W.DigitalClockPair     { preview: true } }
    Component { id: cAnalogClassic; W.AnalogClockClassic   { preview: true } }
    Component { id: cAnalogMinimal; W.AnalogClockMinimal   { preview: true } }
    Component { id: cAnalogShape;   W.AnalogClockShape     { preview: true } }
    Component { id: cDateDefault;   W.DateWidget           { preview: true } }
    Component { id: cDateCalendar;  W.DateWidgetCalendar   { preview: true } }
    Component { id: cDatePill;      W.DateWidgetPill       { preview: true } }
    Component { id: cDateSplit;     W.DateWidgetSplit      { preview: true } }
    Component { id: cDateBold;      W.DateWidgetBold       { preview: true } }
    Component { id: cDateGhost;     W.DateWidgetGhost      { preview: true } }
    Component { id: cDateAccent;    W.DateWidgetAccent     { preview: true } }
    Component { id: cDateInline;    W.DateWidgetInline     { preview: true } }
    Component { id: cWeatherSlant;  W.WeatherWidgetSlanted { preview: true } }
    Component { id: cWeatherCast;   W.WeatherWidgetForecast{ preview: true } }
    Component { id: cWeatherDetail; W.WeatherWidgetDetails { preview: true } }
    Component { id: cSunArc;        W.SunArcWidget         { preview: true } }
    Component { id: cWeatherHourly; W.WeatherHourlyWidget    { preview: true } }
    Component { id: cWeatherWind;   W.WeatherWindWidget      { preview: true } }
    Component { id: cWeatherBaro;   W.WeatherBarometerWidget { preview: true } }
    Component { id: cMoonPhase;     W.MoonPhaseWidget      { preview: true } }
    Component { id: cPomodoro;      W.PomodoroWidget       { preview: true } }
    Component { id: cTaskList;      W.TaskListWidget       { preview: true } }
    Component { id: cStickyNote;    W.StickyNoteWidget     { preview: true } }
    Component { id: cHeadlines;     W.HeadlinesWidget      { preview: true } }
    Component { id: cSysDefault;    W.SystemMonitorWidget  { preview: true } }
    Component { id: cSysCompact;    W.SystemMonitorCompact { preview: true } }
    Component { id: cSysPulse;      W.SystemMonitorPulse   { preview: true } }
    Component { id: cBattDefault;   W.BatteryWidget        { preview: true } }
    Component { id: cBattMinimal;   W.BatteryWidgetMinimal { preview: true } }
    Component { id: cBattRing;      W.BatteryWidgetRing    { preview: true } }
    Component { id: cAlbumArt;      W.AlbumArtWidget       { preview: true } }
    Component { id: cSpectrum;      W.SpectrumWidget       { preview: true } }
    Component { id: cNetGraph;      W.NetworkGraphWidget   { preview: true } }

    // ── Catalog ───────────────────────────────────────────────────────────
    // show      — the SettingsConfig.widgets key that turns the family on
    // styleKey  — the key holding which variant is active (omitted if only one)
    // style     — this card's variant value
    // def       — the family's default variant, for the ?? fallback
    readonly property var catalog: [
        { section: "Personal", items: [
            { label: "Card", comp: cProfileCard, show: "showProfileCard", styleKey: "profileCardStyle", style: "card", def: "card" },
            { label: "Tile", comp: cProfileTile, show: "showProfileCard", styleKey: "profileCardStyle", style: "tile", def: "card" }
        ]},
        { section: "Music", items: [
            { label: "Circular Player", comp: cMusicCircle, show: "showCircularMusicPlayer" },
            { label: "Album Art",       comp: cAlbumArt,    show: "showAlbumArt" },
            { label: "Spectrum",        comp: cSpectrum,    show: "showSpectrum" }
        ]},
        { section: "Digital Clock", items: [
            { label: "Classic", comp: cClockClassic, show: "showClock", styleKey: "digitalClockStyle", style: "classic", def: "classic" },
            { label: "Minimal", comp: cClockMinimal, show: "showClock", styleKey: "digitalClockStyle", style: "minimal", def: "classic" },
            { label: "Stacked", comp: cClockStacked, show: "showClock", styleKey: "digitalClockStyle", style: "stacked", def: "classic" },
            { label: "Outline", comp: cClockOutline, show: "showClock", styleKey: "digitalClockStyle", style: "outline", def: "classic" },
            { label: "Echo",    comp: cClockEcho,    show: "showClock", styleKey: "digitalClockStyle", style: "echo",    def: "classic" },
            { label: "Column",  comp: cClockColumn,  show: "showClock", styleKey: "digitalClockStyle", style: "column",  def: "classic" },
            { label: "Ticker",  comp: cClockTicker,  show: "showClock", styleKey: "digitalClockStyle", style: "ticker",  def: "classic" },
            { label: "Slab",    comp: cClockSlab,    show: "showClock", styleKey: "digitalClockStyle", style: "slab",    def: "classic" },
            { label: "Thin",    comp: cClockThin,    show: "showClock", styleKey: "digitalClockStyle", style: "thin",    def: "classic" },
            { label: "Pair",    comp: cClockPair,    show: "showClock", styleKey: "digitalClockStyle", style: "pair",    def: "classic" }
        ]},
        { section: "Analog Clock", items: [
            { label: "Classic", comp: cAnalogClassic, show: "showAnalogClock", styleKey: "analogClockStyle", style: "classic", def: "classic" },
            { label: "Minimal", comp: cAnalogMinimal, show: "showAnalogClock", styleKey: "analogClockStyle", style: "minimal", def: "classic" },
            { label: "Shape",   comp: cAnalogShape,   show: "showAnalogClock", styleKey: "analogClockStyle", style: "shape",   def: "classic" }
        ]},
        { section: "Date", items: [
            { label: "Default",  comp: cDateDefault,  show: "showDateWidget", styleKey: "dateWidgetStyle", style: "default",  def: "default" },
            { label: "Calendar", comp: cDateCalendar, show: "showDateWidget", styleKey: "dateWidgetStyle", style: "calendar", def: "default" },
            { label: "Pill",     comp: cDatePill,     show: "showDateWidget", styleKey: "dateWidgetStyle", style: "pill",     def: "default" },
            { label: "Split",    comp: cDateSplit,    show: "showDateWidget", styleKey: "dateWidgetStyle", style: "split",    def: "default" },
            { label: "Bold",     comp: cDateBold,     show: "showDateWidget", styleKey: "dateWidgetStyle", style: "bold",     def: "default" },
            { label: "Ghost",    comp: cDateGhost,    show: "showDateWidget", styleKey: "dateWidgetStyle", style: "ghost",    def: "default" },
            { label: "Accent",   comp: cDateAccent,   show: "showDateWidget", styleKey: "dateWidgetStyle", style: "accent",   def: "default" },
            { label: "Inline",   comp: cDateInline,   show: "showDateWidget", styleKey: "dateWidgetStyle", style: "inline",   def: "default" }
        ]},
        { section: "Weather", items: [
            { label: "Slanted",  comp: cWeatherSlant,  show: "showWeatherSlanted" },
            { label: "Forecast", comp: cWeatherCast,   show: "showWeatherForecast" },
            { label: "Details",  comp: cWeatherDetail, show: "showWeatherDetails" },
            { label: "Hourly",   comp: cWeatherHourly, show: "showWeatherHourly" },
            { label: "Wind",     comp: cWeatherWind,   show: "showWeatherWind" },
            { label: "Pressure", comp: cWeatherBaro,   show: "showWeatherBarometer" },
            { label: "Sun Arc",  comp: cSunArc,        show: "showSunArc" },
            { label: "Moon",     comp: cMoonPhase,     show: "showMoonPhase" }
        ]},
        { section: "Productivity", items: [
            { label: "Tasks",    comp: cTaskList,   show: "showTaskList" },
            { label: "Note",     comp: cStickyNote, show: "showStickyNote" },
            { label: "Pomodoro", comp: cPomodoro,   show: "showPomodoro" }
        ]},
        { section: "News", items: [
            { label: "Headlines", comp: cHeadlines, show: "showHeadlines" }
        ]},
        { section: "System", items: [
            { label: "Monitor",   comp: cSysDefault,  show: "showSystemMonitor", styleKey: "systemMonitorStyle", style: "default", def: "default" },
            { label: "Compact",   comp: cSysCompact,  show: "showSystemMonitor", styleKey: "systemMonitorStyle", style: "compact", def: "default" },
            { label: "Pulse",     comp: cSysPulse,    show: "showSystemMonitor", styleKey: "systemMonitorStyle", style: "pulse",   def: "default" },
            { label: "Battery",   comp: cBattDefault, show: "showBattery", styleKey: "batteryStyle", style: "default", def: "default" },
            { label: "Bar",       comp: cBattMinimal, show: "showBattery", styleKey: "batteryStyle", style: "minimal", def: "default" },
            { label: "Ring",      comp: cBattRing,    show: "showBattery", styleKey: "batteryStyle", style: "ring",    def: "default" },
            { label: "Network",   comp: cNetGraph,    show: "showNetworkGraph" }
        ]}
    ]

    readonly property var networkWindows: [
        { name: "1 min" }, { name: "3 min" }, { name: "5 min" },
        { name: "10 min" }, { name: "15 min" }, { name: "30 min" }
    ]
    readonly property var networkIntervals: [
        { name: "1 s" }, { name: "2 s" }, { name: "5 s" }, { name: "10 s" }, { name: "30 s" }
    ]

    readonly property var visualizerStyles: [
        { name: "Wave" }, { name: "Chart" }
    ]
    readonly property var visualizerColors: [
        { name: "Primary" }, { name: "Secondary" }, { name: "Tertiary" },
        { name: "Two-tone" }, { name: "Deep" }, { name: "Warm" }
    ]
    readonly property var visualizerFps: [
        { name: "15 fps" }, { name: "30 fps" }, { name: "60 fps" },
        { name: "90 fps" }, { name: "120 fps" }
    ]

    function isActive(item) {
        if (!(SettingsConfig.widgets[item.show] ?? false)) return false
        if (!item.styleKey) return true
        return (SettingsConfig.widgets[item.styleKey] ?? item.def) === item.style
    }

    // One click both enables the family and picks the variant; clicking the
    // active card switches the family off.
    function selectItem(item) {
        var patch = {}
        if (root.isActive(item)) {
            patch[item.show] = false
        } else {
            patch[item.show] = true
            if (item.styleKey) patch[item.styleKey] = item.style
        }
        SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets, patch)
    }

    Flickable {
        ScrollBar.vertical: CustomScrollBar {}
        id: flick
        anchors.fill: parent
        contentHeight: column.implicitHeight
        contentWidth: width
        clip: true

        ColumnLayout {
            id: column
            width: parent.width
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors { leftMargin: 5; rightMargin: 5; topMargin: 5 }
            spacing: 0

            // ── Page header ──────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                MaterialIconSymbol { content: "widgets"; iconSize: 20 }
                CustomText { content: "Widgets"; size: 20; customColor: Colors.primary }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: arrangeRow.implicitWidth + 26
                    implicitHeight: 34
                    radius: 17
                    color: Colors.primary

                    RowLayout {
                        id: arrangeRow
                        anchors.centerIn: parent
                        spacing: 7
                        MaterialIconSymbol { content: "drag_pan"; iconSize: 16; customColor: Colors.primaryText }
                        CustomText { content: "Arrange"; size: 13; customColor: Colors.primaryText }
                    }

                    RippleEffect {
                        anchors.fill: parent
                        radius: 17
                        hoverColor: Qt.alpha(Colors.primaryText, 0.10)
                        rippleColor: Qt.alpha(Colors.primaryText, 0.24)
                        // Settings is a separate window sitting over the desktop —
                        // it has to get out of the way of what you're arranging.
                        onClicked: {
                            GlobalStates.settingsOpen = false
                            GlobalStates.widgetEditMode = true
                        }
                    }
                }
            }

            CustomText {
                Layout.topMargin: 6
                content: "Click a widget to place it on the desktop. Click it again to remove it."
                size: 12
                customColor: Colors.outline
            }

            // ── Gallery ──────────────────────────────────────────────────
            Repeater {
                model: root.catalog

                delegate: ColumnLayout {
                    id: sectionDelegate
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0

                    SectionLabel { content: sectionDelegate.modelData.section }

                    Flow {
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        spacing: 10

                        Repeater {
                            model: sectionDelegate.modelData.items

                            delegate: Rectangle {
                                id: card
                                required property var modelData

                                readonly property bool active: root.isActive(modelData)

                                width: 184
                                height: 158
                                radius: 18
                                color: active ? Qt.alpha(Colors.primary, 0.13)
                                              : Colors.surfaceContainerHigh
                                border.width: active ? 2 : 0
                                border.color: Colors.primary

                                Behavior on color { ColorAnimation { duration: 150 } }

                                // ── Preview ──────────────────────────────
                                Item {
                                    id: box
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 10
                                    height: 110
                                    clip: true

                                    Loader {
                                        id: pv
                                        sourceComponent: card.modelData.comp

                                        // Only build previews near the viewport — 28 live
                                        // widgets with their own timers is a real cost.
                                        active: {
                                            const y = card.mapToItem(flick.contentItem, 0, 0).y
                                            return y + card.height > flick.contentY - 300
                                                && y < flick.contentY + flick.height + 300
                                        }

                                        transformOrigin: Item.TopLeft
                                        scale: (item && item.implicitWidth > 0 && item.implicitHeight > 0)
                                            ? Math.min(box.width / item.implicitWidth,
                                                       box.height / item.implicitHeight, 1)
                                            : 1
                                        x: (box.width  - width  * scale) / 2
                                        y: (box.height - height * scale) / 2
                                    }
                                }

                                // ── Label ────────────────────────────────
                                RowLayout {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    anchors.bottomMargin: 10
                                    spacing: 5

                                    CustomText {
                                        Layout.fillWidth: true
                                        content: card.modelData.label
                                        size: 12
                                        weight: card.active ? 700 : 500
                                        customColor: card.active ? Colors.primary : Colors.surfaceText
                                    }

                                    MaterialIconSymbol {
                                        visible: card.active
                                        content: "check_circle"
                                        iconSize: 15
                                        fill: 1
                                        customColor: Colors.primary
                                    }
                                }

                                RippleEffect {
                                    anchors.fill: parent
                                    radius: 18
                                    onClicked: root.selectItem(card.modelData)
                                }
                            }
                        }
                    }
                }
            }

            // ── Visualizer options (not widgets) ─────────────────────────
            SectionLabel { content: "Visualizer" }

            ColumnLayout {
                Layout.fillWidth: true; Layout.topMargin: 6; spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Cava Visualizer"; size: 14 }
                            CustomText { content: "Audio bar overlay alongside the circular player"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomToogle {
                            isToggleOn: SettingsConfig.general.musicVisOn
                            onToggled: function(state) {
                                SettingsConfig.general = Object.assign({}, SettingsConfig.general, { musicVisOn: state })
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
                            CustomText { content: "Visualizer Style"; size: 14 }
                            CustomText { content: "Smooth wave or segmented trapezoid chart"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomListNew {
                            Layout.preferredHeight: 30; Layout.preferredWidth: 160
                            color: Colors.surfaceContainerHighest
                            currentVal: SettingsConfig.general.musicVisStyle ?? "Wave"
                            list: root.visualizerStyles
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== SettingsConfig.general.musicVisStyle)
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general,
                                                                           { musicVisStyle: currentVal })
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
                            CustomText { content: "Visualizer Color"; size: 14 }
                            CustomText { content: "Theme role for the bars and their ghost cap"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomListNew {
                            Layout.preferredHeight: 30; Layout.preferredWidth: 160
                            color: Colors.surfaceContainerHighest
                            currentVal: SettingsConfig.general.musicVisColor ?? "Primary"
                            list: root.visualizerColors
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== SettingsConfig.general.musicVisColor)
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general,
                                                                           { musicVisColor: currentVal })
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
                            CustomText { content: "Visualizer Frame Rate"; size: 14 }
                            CustomText { content: "Higher is smoother and costs more CPU"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomListNew {
                            Layout.preferredHeight: 30; Layout.preferredWidth: 160
                            color: Colors.surfaceContainerHighest
                            currentVal: SettingsConfig.general.musicVisFps ?? "30 fps"
                            list: root.visualizerFps
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== SettingsConfig.general.musicVisFps)
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general,
                                                                           { musicVisFps: currentVal })
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
                            CustomText { content: "Visualizer Bars"; size: 14 }
                            CustomText { content: "Number of frequency bands to render"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomSpinBox {
                            color: Colors.surfaceContainerHighest
                            value: SettingsConfig.general.musicVisBars ?? 60
                            onValChanged: {
                                if (val !== value)
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general, { musicVisBars: val })
                            }
                        }
                    }
                }
            }

            // ── Network options (not widgets) ────────────────────────────
            SectionLabel { content: "Network" }

            ColumnLayout {
                Layout.fillWidth: true; Layout.topMargin: 6; spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Stats Duration"; size: 14 }
                            CustomText {
                                content: "How much history the network graph spans"
                                size: 12
                                customColor: Colors.outline
                            }
                        }
                        Item { Layout.fillWidth: true }
                        CustomListNew {
                            Layout.preferredHeight: 30; Layout.preferredWidth: 160
                            color: Colors.surfaceContainerHighest
                            currentVal: SettingsConfig.widgets.networkGraphWindow ?? "3 min"
                            list: root.networkWindows
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== SettingsConfig.widgets.networkGraphWindow)
                                    SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets,
                                                                           { networkGraphWindow: currentVal })
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
                            CustomText { content: "Update Interval"; size: 14 }
                            CustomText {
                                content: "How often the speeds are re-read"
                                size: 12
                                customColor: Colors.outline
                            }
                        }
                        Item { Layout.fillWidth: true }
                        CustomListNew {
                            Layout.preferredHeight: 30; Layout.preferredWidth: 160
                            color: Colors.surfaceContainerHighest
                            currentVal: SettingsConfig.widgets.networkGraphInterval ?? "2 s"
                            list: root.networkIntervals
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== SettingsConfig.widgets.networkGraphInterval)
                                    SettingsConfig.widgets = Object.assign({}, SettingsConfig.widgets,
                                                                           { networkGraphInterval: currentVal })
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
        flickable: flick
    }
}
