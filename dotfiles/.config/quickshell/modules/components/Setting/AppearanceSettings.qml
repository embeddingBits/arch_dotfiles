import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents
import Qt.labs.platform
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn
import QtQuick.Controls

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 5

    property var monitorList: ServiceDisplay.monitorList

    // ── Dashboard section order ───────────────────────────────────────────
    // Mirrors Dashboard.qml's normalisation so the settings list and the
    // dashboard can never disagree about what the saved order means.
    readonly property var dashSections: [
        { key: "profile",      label: "Profile",      icon: "person" },
        { key: "controls",     label: "Controls",     icon: "tune" },
        { key: "quickActions", label: "Quick",        icon: "apps" },
        { key: "notifications", label: "Alerts",      icon: "notifications" },
        { key: "calendar",     label: "Calendar",     icon: "calendar_month" }
    ]

    readonly property var dashDefaultOrder: dashSections.map(s => s.key)

    readonly property var dashOrder: {
        const saved = SettingsConfig.dashboard?.order
        if (!Array.isArray(saved) || saved.length === 0) return root.dashDefaultOrder
        const known = saved.filter(k => root.dashDefaultOrder.indexOf(k) !== -1)
        const missing = root.dashDefaultOrder.filter(k => known.indexOf(k) === -1)
        return known.concat(missing)
    }

    function dashMeta(key) {
        for (var i = 0; i < root.dashSections.length; i++)
            if (root.dashSections[i].key === key) return root.dashSections[i]
        return { key: key, label: key, icon: "widgets" }
    }

    readonly property var dashSegments: {
        const out = []
        const o = root.dashOrder
        for (var i = 0; i < o.length; i++) {
            const m = root.dashMeta(o[i])
            out.push({ value: o[i], label: m.label, icon: m.icon })
        }
        return out
    }

    FileDialog {
        id: imagePicker
        title: "Select a profile image"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.webp *.gif)"]
        onAccepted: {
            SettingsConfig.general = Object.assign({}, SettingsConfig.general, {
                profile: imagePicker.file.toString().replace(/^file:\/\//, "")
            })
            GlobalStates.fileDialogOpen = false
        }
        onRejected: GlobalStates.fileDialogOpen = false
    }

    Flickable {
        id: pageFlick
        ScrollBar.vertical: CustomScrollBar {}
        anchors.fill: parent
        contentHeight: column.implicitHeight
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

            // ── Page header ──────────────────────────────────────────────
            RowLayout {
                spacing: 10
                MaterialIconSymbol { content: "brush"; iconSize: 20 }
                CustomText { content: "Appearance"; size: 20; customColor: Colors.primary }
            }

            // ── Profile ──────────────────────────────────────────────────
            CustomText { Layout.topMargin: 24; content: "Profile"; size: 13; customColor: Colors.primary }

            CustomCard {
                Layout.topMargin: 6
                autoRadius: false; topRadius: 20; bottomRadius: 20

                RowLayout {
                    spacing: 16

                    Item {
                        Layout.preferredWidth: 68
                        Layout.preferredHeight: 68
                        Layout.alignment: Qt.AlignVCenter

                        MaterialShapes.ShapeCanvas {
                            id: artMask
                            anchors.fill: parent
                            roundedPolygon: MaterialShapeFn.getPill()
                            color: Colors.primaryContainer
                        }
                        Image {
                            id: profileArt
                            anchors.fill: parent
                            sourceSize.width: 136
                            sourceSize.height: 136
                            source: SettingsConfig.general.profile
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            layer.enabled: true
                        }
                        MultiEffect {
                            source: profileArt
                            anchors.fill: profileArt
                            maskEnabled: true
                            maskSource: artMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6

                        CustomText { content: "St3el"; size: 16; weight: 700 }
                        CustomText {
                            content: "Shown in overview and lock screen"
                            size: 12; customColor: Colors.outline
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                topLeftRadius: 16; bottomLeftRadius: 16
                                topRightRadius: 6;  bottomRightRadius: 6
                                color: Colors.surfaceContainerHighest
                                clip: true

                                CustomText {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    content: SettingsConfig.general.profile
                                    size: 11
                                    elide: Text.ElideLeft
                                }
                            }

                            M3IconButton {
                                Layout.preferredWidth: 42
                                Layout.preferredHeight: 32
                                topLeftRadius: 6;   bottomLeftRadius: 6
                                topRightRadius: 16; bottomRightRadius: 16
                                icon: "image"
                                iconSize: 18
                                onClicked: {
                                    GlobalStates.fileDialogOpen = true
                                    imagePicker.open()
                                }
                            }
                        }
                    }
                }
            }

            // ── Fonts ────────────────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Fonts"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Body Font"; size: 14 }
                            CustomText { content: "Applied globally to all UI text"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomListNew {
                            Layout.preferredHeight: 30
                            Layout.preferredWidth: 180
                            color: Colors.surfaceContainerHighest
                            currentVal: SettingsConfig.general.defaultFont
                            list: Settings.fonts
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== SettingsConfig.general.defaultFont)
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general, { defaultFont: currentVal })
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
                            CustomText { content: "Display Font"; size: 14 }
                            CustomText { content: "Used in clocks, date widgets, and headings"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomListNew {
                            Layout.preferredHeight: 30
                            Layout.preferredWidth: 180
                            color: Colors.surfaceContainerHighest
                            currentVal: SettingsConfig.general.displayFont ?? "Titan One"
                            list: Settings.displayFonts
                            onCurrentValChanged: {
                                if (currentVal && currentVal !== (SettingsConfig.general.displayFont ?? "Titan One"))
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general, { displayFont: currentVal })
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
                            CustomText { content: "Font Size"; size: 14 }
                            CustomText { content: "Scale applied to all text"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        M3Slider {
                            Layout.preferredWidth: 160
                            Layout.preferredHeight: 30
                            stepCount: 4
                            stepLabels: ["compact", "normal", "large", "xlarge"]
                            currentStep: ({ "compact": 0, "normal": 1, "large": 2, "xlarge": 3 })[SettingsConfig.general.fontScale ?? "normal"] ?? 1
                            onStepChanged: step => {
                                var val = ["compact", "normal", "large", "xlarge"][step]
                                SettingsConfig.general = Object.assign({}, SettingsConfig.general, { fontScale: val })
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
                            CustomText { content: "Font Weight"; size: 14 }
                            CustomText { content: "Default weight for body text"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        M3Slider {
                            Layout.preferredWidth: 160
                            Layout.preferredHeight: 30
                            stepCount: 6
                            stepLabels: ["thin", "regular", "medium", "semibold", "bold", "extrabold"]
                            currentStep: ({ "thin": 0, "regular": 1, "medium": 2, "semibold": 3, "bold": 4, "extrabold": 5 })[SettingsConfig.general.fontWeight ?? "extrabold"] ?? 5
                            onStepChanged: step => {
                                var val = ["thin", "regular", "medium", "semibold", "bold", "extrabold"][step]
                                SettingsConfig.general = Object.assign({}, SettingsConfig.general, { fontWeight: val })
                            }
                        }
                    }
                }
            }

            // ── Bar ──────────────────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Bar"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3

                CustomCard {
                    id: barModeCard
                    autoRadius: false; topRadius: 20; bottomRadius: 5

                    readonly property string currentBarMode: SettingsConfig.general.barMode
                        ?? (SettingsConfig.general.flatBarMode === false ? "stepped" : "flat")

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Bar Mode"; size: 14 }
                            CustomText { content: "Shape of the top bar"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        M3ButtonGroup {
                            model: [
                                { value: "stepped", label: "Stepped", icon: "view_agenda" },
                                { value: "flat",    label: "Flat",    icon: "remove" },
                                { value: "pill",    label: "Pill",    icon: "circle" }
                            ]
                            activeCheck: function(value) { return barModeCard.currentBarMode === value }
                            onSegmentClicked: function(value) {
                                SettingsConfig.general = Object.assign({}, SettingsConfig.general, { barMode: value })
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
                            CustomText { content: "Bar Centre"; size: 14 }
                            CustomText { content: "What sits in the middle of the bar; all of them expand on hover"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        M3ButtonGroup {
                            model: [
                                { value: "clock", label: "Clock", icon: "schedule" },
                                { value: "music", label: "Music", icon: "music_note" },
                                { value: "both",  label: "Both",  icon: "splitscreen" }
                            ]
                            activeCheck: function(value) {
                                return (SettingsConfig.general.barCenter ?? "clock") === value
                            }
                            onSegmentClicked: function(value) {
                                SettingsConfig.general = Object.assign({}, SettingsConfig.general, { barCenter: value })
                            }
                        }
                    }
                }

                CustomCard {
                    autoRadius: false; topRadius: 5
                    bottomRadius: barModeCard.currentBarMode === "pill" ? 5 : 20
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Primary Monitor"; size: 14 }
                            CustomText {
                                content: {
                                    const pm = SettingsConfig.general.primaryMonitor ?? ""
                                    return pm === ""
                                        ? "All monitors show the full bar"
                                        : pm + " shows full bar · others show minimal bar"
                                }
                                size: 12; customColor: Colors.outline
                            }
                        }
                        Item { Layout.fillWidth: true }
                        M3ButtonGroup {
                            height: 30
                            model: {
                                const all = [{ value: "", label: "All", icon: "devices" }]
                                return all.concat(root.monitorList.map(m => ({
                                    value: m.name, label: m.name
                                })))
                            }
                            activeCheck: function(v) {
                                return (SettingsConfig.general.primaryMonitor ?? "") === v
                            }
                            onSegmentClicked: function(v) {
                                SettingsConfig.general = Object.assign(
                                    {}, SettingsConfig.general, { primaryMonitor: v })
                            }
                            inactiveColor: Colors.surfaceContainerHighest
                            textSize: 11; iconSize: 14
                        }
                    }
                }

                CustomCard {
                    visible: barModeCard.currentBarMode === "pill"
                    autoRadius: false; topRadius: 5; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Top Margin"; size: 14 }
                            CustomText { content: "Gap between pill and top screen edge"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        M3Slider {
                            Layout.preferredWidth: 160
                            stepCount: 31
                            currentStep: SettingsConfig.general.pillMargin ?? 6
                            onStepChanged: step => {
                                if (step !== (SettingsConfig.general.pillMargin ?? 6))
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general, { pillMargin: step })
                            }
                        }
                    }
                }

                CustomCard {
                    visible: barModeCard.currentBarMode === "pill"
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
                                CustomText { content: "Left Margin"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Gap between pill and left screen edge"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            M3Slider {
                                Layout.preferredWidth: 160
                                stepCount: 11
                                currentStep: SettingsConfig.general.pillLeftMargin ?? 6
                                onStepChanged: step => {
                                    if (step !== (SettingsConfig.general.pillLeftMargin ?? 6))
                                        SettingsConfig.general = Object.assign({}, SettingsConfig.general, { pillLeftMargin: step })
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
                                CustomText { content: "Right Margin"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Gap between pill and right screen edge"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            M3Slider {
                                Layout.preferredWidth: 160
                                stepCount: 11
                                currentStep: SettingsConfig.general.pillRightMargin ?? 6
                                onStepChanged: step => {
                                    if (step !== (SettingsConfig.general.pillRightMargin ?? 6))
                                        SettingsConfig.general = Object.assign({}, SettingsConfig.general, { pillRightMargin: step })
                                }
                            }
                        }
                    }
                }
            }

            // ── Window Gaps ──────────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Window Gaps"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3

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
                                CustomText { content: "Top Extra"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Added on top of bar height (auto-calculated)"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            M3Slider {
                                Layout.preferredWidth: 160
                                stepCount: 21
                                currentStep: SettingsConfig.general.gapTop ?? 0
                                onStepChanged: step => {
                                    if (step !== (SettingsConfig.general.gapTop ?? 0))
                                        SettingsConfig.general = Object.assign({}, SettingsConfig.general, { gapTop: step })
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
                                CustomText { content: "Bottom"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Gap from bottom screen edge"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            M3Slider {
                                Layout.preferredWidth: 160
                                stepCount: 21
                                currentStep: SettingsConfig.general.gapBottom ?? 5
                                onStepChanged: step => {
                                    if (step !== (SettingsConfig.general.gapBottom ?? 5))
                                        SettingsConfig.general = Object.assign({}, SettingsConfig.general, { gapBottom: step })
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
                                CustomText { content: "Left"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Gap from left screen edge"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            M3Slider {
                                Layout.preferredWidth: 160
                                stepCount: 21
                                currentStep: SettingsConfig.general.gapLeft ?? 5
                                onStepChanged: step => {
                                    if (step !== (SettingsConfig.general.gapLeft ?? 5))
                                        SettingsConfig.general = Object.assign({}, SettingsConfig.general, { gapLeft: step })
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
                                CustomText { content: "Right"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Gap from right screen edge"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            M3Slider {
                                Layout.preferredWidth: 160
                                stepCount: 21
                                currentStep: SettingsConfig.general.gapRight ?? 5
                                onStepChanged: step => {
                                    if (step !== (SettingsConfig.general.gapRight ?? 5))
                                        SettingsConfig.general = Object.assign({}, SettingsConfig.general, { gapRight: step })
                                }
                            }
                        }
                    }
                }
            }

            // ── Workspaces ───────────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Workspaces"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Workspace Count"; size: 14 }
                            CustomText { content: "Number of workspaces shown in the bar"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomSpinBox {
                            color: Colors.surfaceContainerHighest
                            inc: 1
                            limit: 20
                            value: SettingsConfig.general.workspaceCount ?? 10
                            onValChanged: {
                                if (val !== value)
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general, { workspaceCount: val })
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
                                CustomText { content: "Show Numbers"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Display index on each workspace indicator"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            CustomToogle {
                                isToggleOn: SettingsConfig.general.showWorkspaceNumbers ?? false
                                onToggled: function(state) {
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general, { showWorkspaceNumbers: state })
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
                                CustomText { content: "Per-monitor"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Each monitor shows only its own workspaces"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            CustomToogle {
                                isToggleOn: SettingsConfig.general.perMonitorWorkspaces ?? false
                                onToggled: function(state) {
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general, { perMonitorWorkspaces: state })
                                }
                            }
                        }
                    }
                }
            }

            // ── Dock ─────────────────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Dock"; size: 13; customColor: Colors.primary }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 3

                CustomCard {
                    autoRadius: false; topRadius: 20; bottomRadius: 5
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2
                            CustomText { content: "Show Dock"; size: 14 }
                            CustomText { content: "Show or hide the application dock"; size: 12; customColor: Colors.outline }
                        }
                        Item { Layout.fillWidth: true }
                        CustomToogle {
                            isToggleOn: SettingsConfig.general.dock
                            onToggled: function(state) {
                                SettingsConfig.general = Object.assign({}, SettingsConfig.general, { dock: state })
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
                                CustomText { content: "Auto-hide"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Dock hides when a window overlaps it"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            CustomToogle {
                                isToggleOn: SettingsConfig.general.dockAutoHide
                                onToggled: function(state) {
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general, { dockAutoHide: state })
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
                                CustomText { content: "Music Player"; size: 14 }
                                CustomText { Layout.fillWidth: true; wrapMode: Text.WordWrap; content: "Show the mini player in the dock"; size: 12; customColor: Colors.outline }
                            }
                            Item { Layout.fillWidth: true }
                            CustomToogle {
                                isToggleOn: SettingsConfig.general.dockMusicPlayer
                                onToggled: function(state) {
                                    SettingsConfig.general = Object.assign({}, SettingsConfig.general, { dockMusicPlayer: state })
                                }
                            }
                        }
                    }
                }
            }

            // ── Dashboard ────────────────────────────────────────────────
            CustomText { Layout.topMargin: 16; content: "Dashboard"; size: 13; customColor: Colors.primary }

            CustomText {
                Layout.topMargin: 2
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                content: "Click one to show or hide it, drag to reorder. They stack in the dashboard in this order, which sizes itself to whatever you leave on."
                size: 12
                customColor: Colors.outline
            }

            M3ButtonGroup {
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.preferredHeight: 56

                fillWidth: true
                reorderable: true
                iconSize: 20
                textSize: 12
                model: root.dashSegments

                activeCheck: key => SettingsConfig.dashboard?.[key] ?? true

                onSegmentClicked: key => {
                    var patch = {}
                    patch[key] = !(SettingsConfig.dashboard?.[key] ?? true)
                    SettingsConfig.dashboard = Object.assign({}, SettingsConfig.dashboard, patch)
                }

                onSegmentMoved: (from, to) => {
                    const arr = root.dashOrder.slice()
                    arr.splice(to, 0, arr.splice(from, 1)[0])
                    SettingsConfig.dashboard = Object.assign({}, SettingsConfig.dashboard, { order: arr })
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
