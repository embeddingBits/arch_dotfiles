import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

Item {
    id: appLauncher
    implicitHeight: parent.height

    signal closed

    property bool isGrid: SettingsConfig.general.appGrid
    property var appList: isGrid ? gridLoader.item : listLoader.item

    // ── Launcher modes ────────────────────────────────────────────────────
    // "apps" keeps the whole existing app pipeline (categories, pin, context
    // menu); every other mode is served by ServiceLauncher + its own view.
    readonly property string mode: ServiceLauncher.mode
    readonly property bool isApps: mode === "apps"
    readonly property bool isEmoji: mode === "emoji"

    // The one view that currently owns keyboard selection.
    readonly property var activeView: isApps ? appList
        : isEmoji ? emojiLoader.item : resultsLoader.item

    readonly property int resultCount: isApps
        ? filteredApps.length : ServiceLauncher.results.length

    // ── Category filter ───────────────────────────────────────────────────
    property string selectedCategory: "All"

    readonly property var _categoryMap: ({
        "AudioVideo": "Media",   "Audio": "Media",    "Video": "Media",
        "Development": "Dev",    "Education": "Education",
        "Game": "Games",         "Graphics": "Graphics",
        "Network": "Internet",   "Office": "Office",
        "Science": "Science",    "Settings": "Settings",
        "System": "System",      "Utility": "Utilities"
    })

    readonly property var availableCategories: {
        var seen = new Set()
        var result = [{ value: "All", label: "All" }]
        for (var app of ServiceApps.list) {
            for (var cat of (app.categories ?? [])) {
                var label = _categoryMap[cat]
                if (label && !seen.has(label)) {
                    seen.add(label)
                    result.push({ value: cat, label: label })
                }
            }
        }
        result.sort((a, b) => a.label === "All" ? -1 : b.label === "All" ? 1 : a.label.localeCompare(b.label))
        return result
    }

    // Applies both search and category filter
    property var filteredApps: {
        var base = ServiceApps.filteredApps
        if (selectedCategory === "All") return base
        var catKey = selectedCategory
        return base.filter(function(app) {
            return (app.categories ?? []).some(function(c) {
                return _categoryMap[c] === _categoryMap[catKey] || c === catKey
            })
        })
    }

    onClosed: {
        col.visible = false
        col.opacity = 0
        col.scale   = 0.92
        searchInput.text = ""
        ServiceApps.reset()
        ServiceLauncher.reset()
        // appList is null whenever we close from a non-app mode, because its
        // Loader is inactive then.
        if (appList) {
            appList.activeIndex = 0
            appList.animationsEnabled = false
        }
        selectedCategory = "All"
    }

    // Routes the query to the right backend. ServiceLauncher decides the mode;
    // ServiceApps only ever sees a real app search.
    function updateQuery(text) {
        ServiceLauncher.query = text
        ServiceApps.updateSearch(ServiceLauncher.mode === "apps" ? text : "")
        if (activeView) activeView.activeIndex = 0
    }

    function activateSelected() {
        if (isApps) {
            const app = filteredApps[appList.activeIndex]
            if (app) { app.execute(); appLauncher.closed() }
        } else if (activeView) {
            activeView.activateIndex(activeView.activeIndex)
        }
    }

    // ── Context menu ──────────────────────────────────────────────────────
    function showContextMenu(clickX, clickY, app) {
        ctxMenu.targetApp = app
        ctxMenu.x = Math.max(4, Math.min(clickX, width - ctxMenu.width - 4))
        ctxMenu.y = clickY
    }

    Connections {
        target: GlobalStates
        function onAppLauncherOpenChanged() {
            if (!GlobalStates.appLauncherOpen) {
                showTimer.stop()
                col.visible = false
                col.opacity = 0
                col.scale   = 0.92
            }
        }
    }

    // ── Main content ──────────────────────────────────────────────────────
    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8
        visible: false
        opacity: 0
        scale: 0.92

        // Wait for the panel slide to finish, then spring the content in
        Timer {
            id: showTimer
            interval: 300
            onTriggered: {
                col.visible = true
                entranceAnim.start()
                searchInput.forceActiveFocus()
            }
        }

        Component.onCompleted: showTimer.start()

        ParallelAnimation {
            id: entranceAnim
            NumberAnimation {
                target: col; property: "opacity"
                from: 0; to: 1
                duration: 200; easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: col; property: "scale"
                from: 0.92; to: 1
                duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.5
            }
        }

        // ── Search bar ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 16
            color: Colors.surfaceContainerHigh

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 10

                MaterialIconSymbol {
                    content: "search"
                    iconSize: 20
                    customColor: Colors.primary
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextMetrics {
                        id: hintMetrics
                        font: placeholder.font
                        text: "Search apps   = calc   > run   : emoji   w windows"
                    }

                    CustomText {
                        id: placeholder
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        content: hintMetrics.width <= placeholder.width
                            ? hintMetrics.text : "Search apps"
                        size: 15
                        customColor: Colors.outline
                        elide: Text.ElideRight
                        visible: searchInput.text.length === 0
                    }

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        font.pixelSize: 15
                        font.weight: 600
                        font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                        color: Colors.surfaceText
                        focus: true

                        onTextChanged: appLauncher.updateQuery(text)

                        onAccepted: appLauncher.activateSelected()

                        Keys.onPressed: event => {
                            const view = appLauncher.activeView
                            if (!view) return

                            // Grid navigation applies to the app grid and to
                            // the emoji grid; everything else is a plain list.
                            const grid = (appLauncher.isApps && isGrid) || appLauncher.isEmoji
                            const cols = appLauncher.isEmoji ? view.columns : 4
                            const last = appLauncher.resultCount - 1

                            function moveTo(i) {
                                view.activeIndex = Math.max(0, Math.min(last, i))
                                view.positionViewAtIndex(view.activeIndex, GridView.Contain)
                            }

                            if (event.key === Qt.Key_Down) {
                                moveTo(view.activeIndex + (grid ? cols : 1))
                            } else if (event.key === Qt.Key_Up) {
                                moveTo(view.activeIndex - (grid ? cols : 1))
                            } else if (event.key === Qt.Key_Right && grid) {
                                moveTo(view.activeIndex + 1)
                            } else if (event.key === Qt.Key_Left && grid) {
                                moveTo(view.activeIndex - 1)
                            } else if (event.key === Qt.Key_Backspace
                                       && searchInput.cursorPosition === 0
                                       && !appLauncher.isApps) {
                                // Backspace at the very start leaves the mode
                                // rather than deleting nothing.
                                searchInput.text = ""
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                if (!appLauncher.isApps) {
                                    searchInput.text = ""   // first Esc exits the mode
                                    event.accepted = true
                                } else {
                                    appLauncher.closed()
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: 28; height: 28; radius: 10
                    color: Colors.surfaceContainerHighest
                    visible: searchInput.text.length > 0

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: "close"; iconSize: 14
                        customColor: Colors.outline
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchInput.text = ""
                    }
                }

                Rectangle {
                    visible: appLauncher.isApps
                    width: 60; height: 28; radius: 10
                    color: Colors.surfaceContainerHighest

                    Rectangle {
                        x: appLauncher.isGrid ? 30 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: 27; height: 22; radius: 8
                        color: Colors.primary
                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 3; spacing: 0

                        Item {
                            Layout.preferredWidth: 27; Layout.fillHeight: true
                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: "lists"; iconSize: 15
                                customColor: !appLauncher.isGrid ? Colors.primaryText : Colors.outline
                                Behavior on customColor { ColorAnimation { duration: 150 } }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: SettingsConfig.general = Object.assign({}, SettingsConfig.general, { appGrid: false })
                            }
                        }
                        Item {
                            Layout.preferredWidth: 27; Layout.fillHeight: true
                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: "grid_view"; iconSize: 15
                                customColor: appLauncher.isGrid ? Colors.primaryText : Colors.outline
                                Behavior on customColor { ColorAnimation { duration: 150 } }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: SettingsConfig.general = Object.assign({}, SettingsConfig.general, { appGrid: true })
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 30
            visible: appLauncher.isApps ? appLauncher.availableCategories.length > 1 : true

            Flickable {
                anchors.fill: parent
                visible: appLauncher.isApps
                contentWidth: catGroup.implicitWidth
                contentHeight: height
                clip: true
                interactive: contentWidth > width

                M3ButtonGroup {
                    id: catGroup
                    height: 30
                    model: appLauncher.availableCategories
                    activeCheck: function(value) { return value === appLauncher.selectedCategory }
                    onSegmentClicked: value => {
                        appLauncher.selectedCategory = value
                        if (appList) appList.activeIndex = 0
                    }
                    inactiveColor: Colors.surfaceContainerHigh
                }
            }

            LauncherModeBar {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: !appLauncher.isApps
                detail: appLauncher.isEmoji && emojiLoader.item && appLauncher.resultCount > 0
                    ? emojiLoader.item.activeName
                    : ""
            }
        }

        // ── App list ──────────────────────────────────────────────────
        ClippingWrapperRectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: "transparent"

            Item {
                anchors.fill: parent

                Loader {
                    id: gridLoader
                    active: appLauncher.isApps && appLauncher.isGrid
                    visible: active
                    anchors.fill: parent
                    sourceComponent: GridApps {}
                }
                Loader {
                    id: listLoader
                    active: appLauncher.isApps && !appLauncher.isGrid
                    visible: active
                    anchors.fill: parent
                    sourceComponent: ListApps {}
                }
                Loader {
                    id: emojiLoader
                    active: appLauncher.isEmoji
                    visible: active
                    anchors.fill: parent
                    sourceComponent: EmojiGrid {
                        onActivated: appLauncher.closed()
                    }
                }
                Loader {
                    id: resultsLoader
                    active: !appLauncher.isApps && !appLauncher.isEmoji
                    visible: active
                    anchors.fill: parent
                    sourceComponent: LauncherResults {
                        onActivated: appLauncher.closed()
                    }
                }

                // Empty state — a mode with a query but nothing to show
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: !appLauncher.isApps
                             && appLauncher.resultCount === 0
                             && ServiceLauncher.term.length > 0

                    MaterialIconSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        content: "search_off"; iconSize: 30
                        customColor: Colors.outline
                    }
                    CustomText {
                        Layout.alignment: Qt.AlignHCenter
                        content: "No results"
                        size: 13; customColor: Colors.outline
                    }
                }
            }
        }
    }

    // ── Context menu click-away ────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        visible: ctxMenu.targetApp !== null
        z: 98
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
        onClicked: ctxMenu.targetApp = null
        onPressed: ctxMenu.targetApp = null
    }

    // ── Context menu ──────────────────────────────────────────────────────
    Rectangle {
        id: ctxMenu
        property var targetApp: null

        visible: targetApp !== null
        z: 99
        width: 220
        height: cmCol.implicitHeight + 16
        radius: 18
        color: Colors.surfaceContainer

        onHeightChanged: {
            if (y + height > appLauncher.height - 8)
                y = Math.max(4, appLauncher.height - height - 8)
        }

        scale: visible ? 1 : 0.88
        opacity: visible ? 1 : 0
        Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        ColumnLayout {
            id: cmCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
            spacing: 6

            // App header
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 54
                radius: 12
                color: Colors.surfaceContainerHigh

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        width: 36; height: 36; radius: 10
                        color: Qt.alpha(Colors.primary, 0.1)

                        Image {
                            anchors.centerIn: parent
                            width: 26; height: 26
                            source: IconUtil.getIconPath(ctxMenu.targetApp?.icon ?? "")
                            sourceSize.width: 26
                            sourceSize.height: 26
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        CustomText {
                            Layout.fillWidth: true
                            content: ctxMenu.targetApp?.name ?? ""
                            size: 13; weight: 700
                            elide: Text.ElideRight
                        }
                        CustomText {
                            Layout.fillWidth: true
                            content: ctxMenu.targetApp?.genericName || ctxMenu.targetApp?.comment || ""
                            size: 10
                            customColor: Colors.outline
                            elide: Text.ElideRight
                            visible: (ctxMenu.targetApp?.genericName || ctxMenu.targetApp?.comment || "").length > 0
                        }
                    }
                }
            }

            // Actions
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: cmActions.implicitHeight
                radius: 12
                color: Colors.surfaceContainerHigh
                clip: true

                ColumnLayout {
                    id: cmActions
                    anchors { left: parent.left; right: parent.right }
                    spacing: 0

                    // Launch
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 42
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10
                            MaterialIconSymbol { content: "rocket_launch"; iconSize: 16; customColor: Colors.primary }
                            CustomText { Layout.fillWidth: true; content: "Launch"; size: 13 }
                        }

                        RippleEffect {
                            anchors.fill: parent
                            onClicked: {
                                ctxMenu.targetApp.execute()
                                ctxMenu.targetApp = null
                                appLauncher.closed()
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colors.surfaceContainerHighest }

                    // Pin / Unpin
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 42
                        color: "transparent"

                        readonly property bool pinned: ctxMenu.targetApp
                            ? ServiceApps.isPinned(ctxMenu.targetApp) : false

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10
                            MaterialIconSymbol {
                                content: "push_pin"; iconSize: 16
                                fill: parent.parent.pinned ? 1 : 0
                                customColor: Colors.primary
                            }
                            CustomText {
                                Layout.fillWidth: true
                                content: parent.parent.pinned ? "Unpin from Dock" : "Pin to Dock"
                                size: 13
                            }
                        }

                        RippleEffect {
                            anchors.fill: parent
                            onClicked: {
                                ServiceApps.togglePin(ctxMenu.targetApp)
                                ctxMenu.targetApp = null
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colors.surfaceContainerHighest }

                    // Copy name
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 42
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10
                            MaterialIconSymbol { content: "content_copy"; iconSize: 16; customColor: Colors.outline }
                            CustomText { Layout.fillWidth: true; content: "Copy Name"; size: 13 }
                        }

                        RippleEffect {
                            anchors.fill: parent
                            onClicked: {
                                Quickshell.clipboardText = ctxMenu.targetApp?.name ?? ""
                                ctxMenu.targetApp = null
                            }
                        }
                    }
                }
            }
        }
    }
}
