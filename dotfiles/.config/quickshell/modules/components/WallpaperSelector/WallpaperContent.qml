import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Controls
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

Rectangle {
    anchors.fill: parent
    topLeftRadius: Appearance.radius.large
    topRightRadius: Appearance.radius.extraLarge
    color: Colors.surface
    anchors.bottom: parent.bottom

    Behavior on implicitHeight {
        NumberAnimation { duration: Appearance.duration.normal; easing.type: Easing.OutQuad }
    }

    Timer {
        id: timer
        interval: 300
        running: true
        onTriggered: colLoader.active = true
    }

    Loader {
        id: colLoader
        active: false
        visible: active
        anchors.fill: parent

        sourceComponent: ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            property string activeTab: "all"

            // Drives top-bar height animation: 50px local → 82px online (2 rows)
            property real barH: ServiceWallpaper.onlineMode ? 82 : 50
            Behavior on barH { NumberAnimation { duration: Appearance.duration.normal; easing.type: Easing.OutQuad } }

            Component.onCompleted: searchInput.forceActiveFocus()

            ListModel { id: onlineRowModel }

            function syncOnlineRows() {
                if (!ServiceWallpaper.onlineMode) return
                const total = ServiceWallpaper.onlineWallpapers.length
                if (total === 0) { onlineRowModel.clear(); return }
                const newRowCount = Math.ceil(total / grid.columns)
                if (onlineRowModel.count === 0 || onlineRowModel.count > newRowCount
                    || ServiceWallpaper.onlinePage === 1) {
                    onlineRowModel.clear()
                    for (let i = 0; i < newRowCount; i++) onlineRowModel.append({})
                } else {
                    const prev = onlineRowModel.count
                    for (let i = prev; i < newRowCount; i++) onlineRowModel.append({})
                }
            }

            Connections {
                target: ServiceWallpaper

                function onOnlineWallpapersChanged() { col.syncOnlineRows() }

                function onOnlineModeChanged() {
                    if (ServiceWallpaper.onlineMode) {
                        col.activeTab = "all"
                    } else {
                        onlineRowModel.clear()
                        onlineSearch.text = ""
                    }
                }
            }

            NumberAnimation on opacity { from: 0; to: 1; duration: 100; running: col.visible }
            NumberAnimation on scale   { from: 0.8; to: 1; duration: 100; running: col.visible }

            // ── Top bar ────────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: col.barH
                clip: true
                radius: Appearance.radius.extraLarge
                color: Colors.surfaceContainer

                // ── Local controls ─────────────────────────────────────────────
                RowLayout {
                    id: localContent
                    anchors.fill: parent
                    anchors.leftMargin: 10; anchors.rightMargin: 10
                    spacing: 8
                    enabled: !ServiceWallpaper.onlineMode
                    opacity: ServiceWallpaper.onlineMode ? 0 : 1
                    scale:   ServiceWallpaper.onlineMode ? 0.92 : 1
                    Behavior on opacity { NumberAnimation { duration: Appearance.duration.normal } }
                    Behavior on scale   { NumberAnimation { duration: Appearance.duration.normal; easing.type: Easing.OutQuad } }

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 35
                        radius: 20; color: Colors.surfaceContainerHighest
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 5; anchors.leftMargin: 10; spacing: 8
                            MaterialIconSymbol { content: "search"; iconSize: 18 }
                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true; Layout.fillHeight: true
                                clip: true; font.pixelSize: 14; font.weight: 700
                                color: Colors.inverseSurface
                                onTextChanged: ServiceWallpaper.updateSearch(text)
                                Keys.onEscapePressed: text = ""
                                Keys.onDownPressed: {
                                    grid.forceActiveFocus()
                                    if (grid.selectedIndex < 0) grid.moveSelection(0)
                                }
                            }
                            MaterialIconSymbol {
                                content: "close"; iconSize: 14; customColor: Colors.outline
                                visible: searchInput.text.length > 0
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: searchInput.text = ""
                                }
                            }
                        }
                    }

                    M3ButtonGroup {
                        model: [
                            { value: "all",       icon: "grid_view", label: "All" },
                            { value: "favorites", icon: "favorite",  label: "Fav" }
                        ]
                        activeCheck: v => col.activeTab === v
                        onSegmentClicked: v => col.activeTab = v
                    }

                    M3ButtonGroup {
                        model: [
                            { icon: "schedule",      value: "newest" },
                            { icon: "sort_by_alpha", value: "name"   }
                        ]
                        activeCheck: v => ServiceWallpaper.localSortBy === v
                        onSegmentClicked: v => ServiceWallpaper.localSortBy = v
                    }

                    Rectangle {
                        width: 30; height: 30; radius: 15; color: Colors.surfaceContainerHighest
                        MaterialIconSymbol { anchors.centerIn: parent; content: "refresh"; iconSize: 18 }
                        CustomMouseArea {
                            anchors.fill: parent; radius: parent.radius; cursorShape: Qt.PointingHandCursor
                            onClicked: ServiceWallpaper.refresh()
                        }
                    }

                    Rectangle {
                        width: 30; height: 30; radius: 15; color: Colors.surfaceContainerHighest
                        MaterialIconSymbol { anchors.centerIn: parent; content: "public"; iconSize: 18 }
                        CustomMouseArea {
                            anchors.fill: parent; radius: parent.radius; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ServiceWallpaper.updateSearch("")
                                searchInput.text = ""
                                ServiceWallpaper.onlineMode = true
                                ServiceWallpaper.fetchWallhaven(true)
                            }
                        }
                    }
                }

                // ── Online controls (two rows) ─────────────────────────────────
                ColumnLayout {
                    id: onlineConfigCol
                    anchors.fill: parent; anchors.margins: 8
                    spacing: 6
                    enabled: ServiceWallpaper.onlineMode
                    opacity: ServiceWallpaper.onlineMode ? 1 : 0
                    scale:   ServiceWallpaper.onlineMode ? 1 : 0.92
                    Behavior on opacity { NumberAnimation { duration: Appearance.duration.normal } }
                    Behavior on scale   { NumberAnimation { duration: Appearance.duration.normal; easing.type: Easing.OutQuad } }

                    property var sortOpts: [
                        ["Recent","date_added"],["Hot","toplist"],
                        ["Views","views"],["Fav","favorites"],
                        ["Random","random"],["Relevant","relevance"]
                    ]
                    property var rangeOpts: ["1d","3d","1w","1M","3M","6M","1y"]

                    function toggleCat(pos) {
                        let c = SettingsConfig.wallhaven.categories.split("")
                        c[pos] = c[pos] === "1" ? "0" : "1"
                        if (!c.includes("1")) return
                        SettingsConfig.wallhaven = Object.assign({}, SettingsConfig.wallhaven, { categories: c.join("") })
                    }
                    function togglePur(pos) {
                        let p = SettingsConfig.wallhaven.purity.split("")
                        p[pos] = p[pos] === "1" ? "0" : "1"
                        if (!p.includes("1")) return
                        SettingsConfig.wallhaven = Object.assign({}, SettingsConfig.wallhaven, { purity: p.join("") })
                    }

                    // Row 1: back · search · fetch
                    RowLayout {
                        Layout.fillWidth: true; spacing: 6

                        Rectangle {
                            height: 30; radius: 15; implicitWidth: _backRow.implicitWidth + 20
                            color: Colors.surfaceContainerHighest
                            RowLayout { id: _backRow; anchors.centerIn: parent; spacing: 4
                                MaterialIconSymbol { content: "arrow_back"; iconSize: 14; customColor: Colors.surfaceText }
                                CustomText { content: "Local"; size: 11; customColor: Colors.surfaceText }
                            }
                            CustomMouseArea {
                                anchors.fill: parent; radius: parent.radius; cursorShape: Qt.PointingHandCursor
                                onClicked: { ServiceWallpaper.updateSearch(searchInput.text); ServiceWallpaper.onlineMode = false }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 30; radius: 15; color: Colors.surfaceContainerHighest
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 8; spacing: 6
                                MaterialIconSymbol { content: "search"; iconSize: 14; customColor: Colors.outline }
                                Item {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    CustomText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        content: "Search Wallhaven…"; size: 12; customColor: Colors.outline
                                        visible: onlineSearch.text.length === 0
                                    }
                                    TextInput {
                                        id: onlineSearch
                                        anchors.fill: parent; clip: true; font.pixelSize: 13
                                        color: Colors.inverseSurface; verticalAlignment: TextInput.AlignVCenter
                                        Keys.onEscapePressed: text = ""
                                        Keys.onReturnPressed: {
                                            if (!ServiceWallpaper.isFetchingOnline) {
                                                ServiceWallpaper.currentSearchText = text
                                                ServiceWallpaper.fetchWallhaven(true)
                                            }
                                        }
                                    }
                                }
                                MaterialIconSymbol {
                                    content: "close"; iconSize: 13; customColor: Colors.outline
                                    visible: onlineSearch.text.length > 0
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: onlineSearch.text = "" }
                                }
                            }
                        }

                        // Download progress pill — expands in when a download is active
                        Rectangle {
                            id: _headerDlPill
                            height: 30; radius: 15; clip: true
                            readonly property bool isActive: ServiceWallpaper.downloadingId !== ""
                            implicitWidth: isActive ? (_dlPillRow.implicitWidth + 20) : 0
                            Behavior on implicitWidth { NumberAnimation { duration: Appearance.duration.normal; easing.type: Easing.OutQuad } }
                            color: Qt.alpha(Colors.primary, 0.15)

                            RowLayout {
                                id: _dlPillRow; anchors.centerIn: parent; spacing: 6
                                MaterialIconSymbol { content: "download"; iconSize: 14; customColor: Colors.primary }
                                CustomText {
                                    content: Math.round(ServiceWallpaper.downloadProgress * 100) + "%"
                                    size: 11; customColor: Colors.primary; weight: 600
                                }
                                Rectangle {
                                    width: 18; height: 18; radius: 9
                                    color: Qt.alpha(Colors.primary, 0.3)
                                    MaterialIconSymbol { anchors.centerIn: parent; content: "close"; iconSize: 11; customColor: Colors.primary }
                                    CustomMouseArea {
                                        anchors.fill: parent; radius: parent.radius; cursorShape: Qt.PointingHandCursor
                                        onClicked: ServiceWallpaper.cancelDownload()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 30; height: 30; radius: 15
                            color: ServiceWallpaper.isFetchingOnline ? Colors.surfaceContainerHighest : Colors.primary
                            Behavior on color { ColorAnimation { duration: 150 } }
                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: ServiceWallpaper.isFetchingOnline ? "hourglass_empty" : "search"
                                iconSize: 16
                                customColor: ServiceWallpaper.isFetchingOnline ? Colors.surfaceText : Colors.primaryText
                            }
                            CustomMouseArea {
                                anchors.fill: parent; radius: parent.radius; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!ServiceWallpaper.isFetchingOnline) {
                                        ServiceWallpaper.currentSearchText = onlineSearch.text
                                        ServiceWallpaper.fetchWallhaven(true)
                                    }
                                }
                            }
                        }
                    }

                    // Row 2: filters (flickable)
                    Flickable {
                        Layout.fillWidth: true; height: 28
                        contentHeight: height; contentWidth: _filterRow.implicitWidth
                        clip: true; interactive: contentWidth > width
                        flickDeceleration: 3000; maximumFlickVelocity: 4000

                        RowLayout { id: _filterRow; height: parent.height; spacing: 6
                            M3ButtonGroup {
                                height: 28
                                model: onlineConfigCol.sortOpts.map(o => ({ label: o[0], value: o[1] }))
                                activeCheck: v => SettingsConfig.wallhaven.sorting === v
                                onSegmentClicked: v => SettingsConfig.wallhaven = Object.assign({}, SettingsConfig.wallhaven, { sorting: v })
                            }
                            M3ButtonGroup {
                                height: 28; visible: SettingsConfig.wallhaven.sorting === "toplist"
                                model: onlineConfigCol.rangeOpts.map(v => ({ label: v, value: v }))
                                activeCheck: v => SettingsConfig.wallhaven.topRange === v
                                onSegmentClicked: v => SettingsConfig.wallhaven = Object.assign({}, SettingsConfig.wallhaven, { topRange: v })
                            }
                            Rectangle { width: 1; height: 18; color: Colors.outline; opacity: 0.35 }
                            M3ButtonGroup {
                                height: 28
                                model: [{ icon: "arrow_downward", value: "desc" }, { icon: "arrow_upward", value: "asc" }]
                                activeCheck: v => SettingsConfig.wallhaven.order === v
                                onSegmentClicked: v => SettingsConfig.wallhaven = Object.assign({}, SettingsConfig.wallhaven, { order: v })
                            }
                            Rectangle { width: 1; height: 18; color: Colors.outline; opacity: 0.35 }
                            M3ButtonGroup {
                                height: 28
                                model: [{ label: "General", value: 0 }, { label: "Anime", value: 1 }, { label: "People", value: 2 }]
                                activeCheck: v => SettingsConfig.wallhaven.categories[v] === "1"
                                onSegmentClicked: v => onlineConfigCol.toggleCat(v)
                            }
                            M3ButtonGroup {
                                height: 28
                                model: [{ label: "SFW", value: 0 }, { label: "Sketchy", value: 1 }]
                                activeCheck: v => SettingsConfig.wallhaven.purity[v] === "1"
                                onSegmentClicked: v => onlineConfigCol.togglePur(v)
                            }
                            Rectangle {
                                visible: SettingsConfig.wallhaven.apiKey.length > 0
                                readonly property bool active: SettingsConfig.wallhaven.purity[2] === "1"
                                height: 28; radius: 14; implicitWidth: _nsfwText.implicitWidth + 24
                                color: active ? Colors.error : "transparent"
                                border.width: 1; border.color: Colors.outline
                                Behavior on color { ColorAnimation { duration: 150 } }
                                CustomText {
                                    id: _nsfwText; anchors.centerIn: parent; content: "NSFW"; size: 11
                                    customColor: parent.active ? Colors.errorText : Colors.surfaceText
                                }
                                CustomMouseArea {
                                    anchors.fill: parent; radius: parent.radius; cursorShape: Qt.PointingHandCursor
                                    onClicked: onlineConfigCol.togglePur(2)
                                }
                            }
                        }
                    }
                }
            }
            // ── End top bar ────────────────────────────────────────────────────

            // Wallpaper count strip (local mode only)
            RowLayout {
                Layout.fillWidth: true; Layout.topMargin: -2
                visible: !ServiceWallpaper.onlineMode; spacing: 4
                MaterialIconSymbol { content: "wallpaper"; iconSize: 12; customColor: Colors.outline }
                CustomText { content: ServiceWallpaper.cacheModel.count + " wallpapers"; size: 11; customColor: Colors.outline }
                Item { Layout.fillWidth: true }
            }

            // ── Grid wrapper ───────────────────────────────────────────────────
            Item {
                id: gridWrapper
                Layout.fillHeight: true
                Layout.fillWidth: true

                // Fetch overlay — morphing shape loader while wallpapers load
                Loader {
                    anchors.centerIn: parent
                    z: 1
                    active: ServiceWallpaper.onlineMode
                         && ServiceWallpaper.isFetchingOnline
                         && ServiceWallpaper.onlineError.length === 0
                    visible: active
                    sourceComponent: CustomLoader { size: 80; color: Colors.primary }
                }

                // Error overlay
                Rectangle {
                    anchors.centerIn: parent
                    visible: ServiceWallpaper.onlineMode && ServiceWallpaper.onlineError.length > 0
                    z: 1
                    implicitWidth: _errRow.implicitWidth + 32; implicitHeight: _errRow.implicitHeight + 20
                    radius: 14; color: Colors.surfaceContainer
                    RowLayout {
                        id: _errRow; anchors.centerIn: parent; spacing: 8
                        MaterialIconSymbol { content: "error"; iconSize: 20; customColor: Colors.error }
                        CustomText {
                            content: ServiceWallpaper.onlineError
                            size: 13; customColor: Colors.error
                        }
                    }
                }

                // Local loading overlay
                Loader {
                    anchors.centerIn: parent
                    z: 1
                    active: !ServiceWallpaper.onlineMode && ServiceWallpaper.isProcessing
                    visible: active
                    sourceComponent: ColumnLayout {
                        spacing: 12
                        CustomLoader { size: 60; color: Colors.primary; Layout.alignment: Qt.AlignHCenter }
                        CustomText {
                            content: "Loading wallpapers…"
                            size: 13; customColor: Colors.outline
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // Local empty state
                Rectangle {
                    anchors.centerIn: parent
                    z: 1
                    visible: !ServiceWallpaper.onlineMode
                          && !ServiceWallpaper.isProcessing
                          && (col.activeTab === "favorites"
                              ? ServiceWallpaper.favoritedWallpapers.length === 0
                              : ServiceWallpaper.filteredWallpapers.length === 0)
                    implicitWidth:  _emptyCol.implicitWidth  + 48
                    implicitHeight: _emptyCol.implicitHeight + 32
                    radius: 14; color: Colors.surfaceContainer

                    ColumnLayout {
                        id: _emptyCol
                        anchors.centerIn: parent; spacing: 8

                        MaterialIconSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            content: col.activeTab === "favorites" ? "favorite_border" : "image_not_supported"
                            iconSize: 32; customColor: Colors.outline
                        }
                        CustomText {
                            Layout.alignment: Qt.AlignHCenter
                            content: col.activeTab === "favorites"
                                ? "No favourites yet"
                                : ServiceWallpaper.wallpapers.length === 0
                                  ? "No wallpapers in folder"
                                  : "No wallpapers match search"
                            size: 13; customColor: Colors.outline
                        }
                        CustomText {
                            Layout.alignment: Qt.AlignHCenter
                            visible: col.activeTab !== "favorites" && ServiceWallpaper.wallpapers.length === 0
                            content: ServiceWallpaper.wallpaperDir
                            size: 11; customColor: Qt.alpha(Colors.outline, 0.6)
                        }
                    }
                }

                // ── Wallpaper grid ─────────────────────────────────────────────
                ListView {
                    id: grid
                    anchors.fill: parent; clip: true; interactive: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: CustomScrollBar {}
                    flickDeceleration: 2500; maximumFlickVelocity: 8000

                    property real itemSpacing: 8
                    spacing: itemSpacing

                    readonly property real targetTileWidth: 320
                    readonly property int  columns: Math.max(2, Math.min(6,
                        Math.round(width / targetTileWidth))) || 2
                    readonly property real cellWidth:
                        (width - itemSpacing * (columns - 1)) / columns

                    onColumnsChanged: col.syncOnlineRows()

                    readonly property real itemRadius: 28
                    readonly property real xSmallSize: 10
                    readonly property real preferredRowHeight: cellWidth * 9 / 16

                    // false: biggest focal rows that fit  ([L…L, S], abrupt L→S at the edge)
                    // true:  smoother L→M→S ladder, at the cost of a smaller focal row
                    readonly property bool preferSmoothLadder: false

                    readonly property var arrangement: {
                        const H = height, sp = itemSpacing, pref = preferredRowHeight
                        if (H <= 0 || cellWidth <= 0)
                            return { n: 1, m: 0, large: Math.max(1, pref), medium: 0, small: 0 }

                        const cands = []
                        for (const m of [1, 0]) {
                            for (let n = 1; n <= 8; n++) {
                                let S = 48, L = 0
                                for (let k = 0; k < 10; k++) {
                                    L = (H - S * (1 + m / 2) - (n + m) * sp) / (n + m / 2)
                                    S = Math.max(40, Math.min(56, L * 0.3))
                                }
                                if (L <= S * 1.2) continue
                                cands.push({ cost: Math.abs(L - pref), n: n, m: m, L: L, S: S })
                            }
                        }

                        let best = null
                        for (const c of cands) {
                            if (preferSmoothLadder && c.m !== 1) continue
                            if (best === null || c.cost < best.cost) best = c
                        }
                        if (best === null)
                            for (const c of cands)
                                if (best === null || c.cost < best.cost) best = c

                        if (best === null) {
                            const L = Math.max(1, Math.min(pref, H))
                            return { n: 1, m: 0, large: L, medium: L, small: L }
                        }
                        return { n: best.n, m: best.m, large: best.L, small: best.S,
                                 medium: (best.L + best.S) / 2 }
                    }

                    readonly property real rowHeight: arrangement.large
                    readonly property real rowPitch:  rowHeight + itemSpacing
                    readonly property real wheelStep: rowPitch
                    readonly property real focalLoc:  rowHeight / 2
                    readonly property real focalSpan: arrangement.n * rowHeight
                                                    + (arrangement.n - 1) * itemSpacing

                    bottomMargin: Math.max(0, height - focalSpan)

                    // Exactly the slots whose drawn extent can touch the viewport:
                    // one pitch above, and down to the last *visible* keyline (the
                    // small one). The xS anchors are drawn off-screen, so let them cull.
                    displayMarginBeginning: Math.ceil(rowPitch)
                    displayMarginEnd: Math.ceil(Math.max(0, rowHeight
                        + (arrangement.n + arrangement.m) * rowPitch - height))
                    cacheBuffer: Math.ceil(rowPitch * 2)

                    readonly property real minContentY: 0
                    readonly property real maxContentY: Math.max(0,
                        contentHeight + bottomMargin - height)

                    property real wheelAccum: 0

                    readonly property var keylines: {
                        const sp = itemSpacing, L = rowHeight, p = rowPitch
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

                    function snapTarget(y) {
                        const t = Math.round(y / rowPitch) * rowPitch
                        return Math.max(minContentY, Math.min(maxContentY, t))
                    }

                    function glideTo(dest) {
                        const d = Math.max(minContentY, Math.min(maxContentY, dest))
                        if (Math.abs(d - contentY) < 0.5) return
                        cancelFlick()
                        wheelAnim.stop()
                        wheelAnim.from = contentY
                        wheelAnim.to   = d
                        wheelAnim.start()
                    }

                    function snapToNearest() { glideTo(snapTarget(contentY)) }

                    // ── Keyboard navigation ────────────────────────────────────
                    keyNavigationEnabled: false
                    property int selectedIndex: -1
                    readonly property int itemCount: currentDataArray ? currentDataArray.length : 0

                    onCurrentDataArrayChanged: selectedIndex = -1

                    function focalFirstRow() { return Math.round(contentY / rowPitch) }

                    function revealRow(row) {
                        const first = focalFirstRow()
                        const last  = first + arrangement.n - 1
                        if (row < first)     glideTo(row * rowPitch)
                        else if (row > last) glideTo((row - arrangement.n + 1) * rowPitch)
                    }

                    function moveSelection(delta) {
                        if (itemCount === 0) return
                        let i = selectedIndex < 0 ? focalFirstRow() * columns
                                                  : selectedIndex + delta
                        i = Math.max(0, Math.min(itemCount - 1, i))
                        selectedIndex = i
                        revealRow(Math.floor(i / columns))
                    }

                    function activateSelection() {
                        if (selectedIndex < 0 || selectedIndex >= itemCount) return
                        const d = currentDataArray[selectedIndex]
                        if (ServiceWallpaper.onlineMode)
                            ServiceWallpaper.downloadAndSetWallpaper(d)
                        else
                            ServiceWallpaper.setWallpaper(d)
                    }

                    Keys.onLeftPressed:   moveSelection(-1)
                    Keys.onRightPressed:  moveSelection(1)
                    Keys.onUpPressed:     moveSelection(-columns)
                    Keys.onDownPressed:   moveSelection(columns)
                    Keys.onReturnPressed: activateSelection()
                    Keys.onEnterPressed:  activateSelection()
                    Keys.onEscapePressed: {
                        selectedIndex = -1
                        if (ServiceWallpaper.onlineMode) onlineSearch.forceActiveFocus()
                        else searchInput.forceActiveFocus()
                    }
                    Keys.onPressed: event => {
                        const page = columns * arrangement.n
                        if (event.key === Qt.Key_PageDown)      moveSelection(page)
                        else if (event.key === Qt.Key_PageUp)   moveSelection(-page)
                        else if (event.key === Qt.Key_Home && itemCount > 0) {
                            selectedIndex = 0
                            revealRow(0)
                        } else if (event.key === Qt.Key_End && itemCount > 0) {
                            selectedIndex = itemCount - 1
                            revealRow(Math.floor(selectedIndex / columns))
                        } else return
                        event.accepted = true
                    }

                    onDraggingVerticallyChanged: if (draggingVertically) wheelAnim.stop()

                    onMovementEnded: {
                        if (wheelAnim.running) return
                        snapToNearest()
                    }

                    readonly property var currentDataArray: ServiceWallpaper.onlineMode
                        ? ServiceWallpaper.onlineWallpapers
                        : (col.activeTab === "favorites"
                            ? ServiceWallpaper.favoritedWallpapers
                            : ServiceWallpaper.filteredWallpapers)

                    model: ServiceWallpaper.onlineMode
                        ? onlineRowModel
                        : (currentDataArray ? Math.ceil(currentDataArray.length / columns) : 0)

                    readonly property real prefetchMargin: rowPitch * 2

                    function maybeFetchMore() {
                        if (!ServiceWallpaper.onlineMode) return
                        if (contentY < maxContentY - prefetchMargin) return
                        ServiceWallpaper.fetchNextPage()
                    }

                    onContentYChanged: maybeFetchMore()
                    onContentHeightChanged: maybeFetchMore()

                    delegate: Item {
                        id: rowContainer
                        width:  grid.width
                        height: grid.rowHeight

                        property int rowIndex: index

                        readonly property real childLoc:
                            index * grid.rowPitch + grid.rowHeight / 2 - grid.contentY
                        readonly property var  keyline:    grid.sample(childLoc)

                        readonly property var band: {
                            const c = keyline.c, s = keyline.s, H = grid.height
                            let t = c - s / 2, b = c + s / 2
                            if (t < 0 && b > 0) t = 0
                            if (b > H && t < H) b = Math.max(H, t)
                            return { t: t, b: b }
                        }

                        readonly property real tileHeight: Math.max(0, band.b - band.t)
                        readonly property real tileRadius: Math.min(grid.itemRadius, tileHeight / 2)
                        readonly property real imageY: keyline.c - grid.rowHeight / 2 - band.t

                        Row {
                            y: rowContainer.band.t - rowContainer.childLoc
                             + rowContainer.height / 2
                            spacing: grid.itemSpacing

                            Repeater {
                                model: grid.columns

                                delegate: Rectangle {
                                    id: wallpaperItem

                                    property int wallpaperIndex: (rowContainer.rowIndex * grid.columns) + index
                                    property var itemData: (grid.currentDataArray && wallpaperIndex < grid.currentDataArray.length)
                                        ? grid.currentDataArray[wallpaperIndex] : null

                                    readonly property bool isDownloading: ServiceWallpaper.onlineMode
                                        && itemData && ServiceWallpaper.downloadingId === itemData.id

                                    visible: itemData !== null
                                    width:  grid.cellWidth
                                    height: rowContainer.tileHeight
                                    radius: rowContainer.tileRadius
                                    clip:   true
                                    color:  tileArea.containsMouse ? Qt.alpha(Colors.primary, 0.15) : "transparent"

                                    Item {
                                        id: maskContainer
                                        anchors.fill: parent
                                        scale: tileHover.hovered ? 0.97 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle {
                                                width: maskContainer.width; height: maskContainer.height
                                                radius: rowContainer.tileRadius
                                            }
                                        }

                                        Image {
                                            id: thumbnail
                                            y: rowContainer.imageY
                                            width: parent.width; height: rowContainer.height
                                            sourceSize.width: 640
                                            sourceSize.height: 640
                                            asynchronous: true; smooth: true; cache: true
                                            source: {
                                                if (!wallpaperItem.itemData) return ""
                                                ServiceWallpaper.onlineMode
                                                    ? wallpaperItem.itemData.thumbUrl
                                                    : "file://" + wallpaperItem.itemData
                                            }
                                            fillMode: Image.PreserveAspectCrop
                                        }
                                    }

                                    // Loading spinner (online thumbnails)
                                    Loader {
                                        anchors.centerIn: parent
                                        active: ServiceWallpaper.onlineMode && thumbnail.status === Image.Loading
                                        visible: active
                                        sourceComponent: CustomLoader { size: 52; color: Colors.primary }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        z: 4
                                        visible: grid.selectedIndex === wallpaperItem.wallpaperIndex
                                              && wallpaperItem.itemData !== null
                                        color: "transparent"
                                        radius: rowContainer.tileRadius
                                        border.width: 3
                                        border.color: Colors.primary
                                    }

                                    HoverHandler { id: tileHover }

                                    MouseArea {
                                        id: tileArea
                                        anchors.fill: parent; hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                                        onClicked: mouse => {
                                            if (mouse.button === Qt.RightButton) {
                                                const mapped = tileArea.mapToItem(gridWrapper, mouse.x, mouse.y)
                                                ctxMenu.show(mapped.x, mapped.y,
                                                    wallpaperItem.itemData, ServiceWallpaper.onlineMode)
                                            } else {
                                                grid.selectedIndex = wallpaperItem.wallpaperIndex
                                                if (ServiceWallpaper.onlineMode)
                                                    ServiceWallpaper.downloadAndSetWallpaper(wallpaperItem.itemData)
                                                else
                                                    ServiceWallpaper.setWallpaper(wallpaperItem.itemData)
                                            }
                                        }
                                    }

                                    // ── Download overlay ───────────────────────
                                    Rectangle {
                                        anchors.fill: parent; radius: rowContainer.tileRadius
                                        color: Qt.rgba(0, 0, 0, 0.55)
                                        visible: wallpaperItem.isDownloading; z: 3

                                        ColumnLayout {
                                            anchors.centerIn: parent; spacing: 8
                                            width: Math.min(parent.width - 16, 100)

                                            Loader {
                                                Layout.alignment: Qt.AlignHCenter
                                                active: wallpaperItem.isDownloading
                                                visible: active
                                                sourceComponent: CustomLoader { size: 56; color: "white" }
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true; height: 4; radius: 2
                                                color: Qt.rgba(1, 1, 1, 0.2)
                                                Rectangle {
                                                    width: parent.width * ServiceWallpaper.downloadProgress
                                                    height: parent.height; radius: 2; color: Colors.primary
                                                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                                                }
                                            }

                                            CustomText {
                                                Layout.alignment: Qt.AlignHCenter
                                                content: {
                                                    const pct = Math.round(ServiceWallpaper.downloadProgress * 100)
                                                    const mb  = (ServiceWallpaper.downloadedBytes / (1024 * 1024)).toFixed(1)
                                                    if (ServiceWallpaper.downloadTotalBytes > 0) {
                                                        const tot = (ServiceWallpaper.downloadTotalBytes / (1024 * 1024)).toFixed(1)
                                                        return pct + "% · " + mb + "/" + tot + " MB"
                                                    }
                                                    return mb + " MB"
                                                }
                                                size: 10; customColor: "white"
                                            }
                                        }
                                    }

                                    // Favourite button (local mode)
                                    Rectangle {
                                        id: heartBtn
                                        visible: !ServiceWallpaper.onlineMode && wallpaperItem.itemData !== null
                                        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8
                                        width: 28; height: 28; radius: 14; z: 2

                                        readonly property bool faved: ServiceWallpaper.favoritedWallpapers.indexOf(
                                            wallpaperItem.itemData) >= 0

                                        color:   faved ? Colors.error : Colors.surfaceContainer
                                        opacity: faved || tileHover.hovered ? 0.92 : 0
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                        Behavior on color   { ColorAnimation  { duration: 150 } }

                                        MaterialIconSymbol {
                                            anchors.centerIn: parent
                                            content: heartBtn.faved ? "favorite" : "favorite_border"; iconSize: 16
                                            customColor: heartBtn.faved ? Colors.errorText : Colors.surfaceText
                                        }

                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: mouse => {
                                                ServiceWallpaper.toggleFavorite(wallpaperItem.itemData)
                                                mouse.accepted = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Smooth wheel scrolling ─────────────────────────────────────
                NumberAnimation {
                    id: wheelAnim
                    target: grid
                    property: "contentY"
                    duration: 180
                    easing.type: Easing.OutCubic
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    enabled: ctxMenu.target === null

                    onWheel: wheel => {
                        wheel.accepted = false
                        if (grid.maxContentY <= grid.minContentY) return

                        if (wheel.phase === Qt.ScrollEnd) {
                            grid.wheelAccum = 0
                            grid.snapToNearest()
                            wheel.accepted = true
                            return
                        }

                        const px = wheel.pixelDelta.y
                        const ang = wheel.angleDelta.y
                        if (px === 0 && ang === 0) return

                        if (px !== 0) {
                            grid.wheelAccum = 0
                            const d = Math.max(grid.minContentY,
                                Math.min(grid.maxContentY, grid.contentY - px))
                            if (Math.abs(d - grid.contentY) < 0.01) return
                            wheelAnim.stop()
                            grid.cancelFlick()
                            grid.contentY = d
                            wheel.accepted = true
                            return
                        }

                        const n = ang / 120
                        if (grid.wheelAccum !== 0 && (grid.wheelAccum > 0) !== (n > 0))
                            grid.wheelAccum = 0
                        grid.wheelAccum += n

                        const steps = grid.wheelAccum > 0
                            ? Math.floor(grid.wheelAccum) : Math.ceil(grid.wheelAccum)
                        wheel.accepted = true
                        if (steps === 0) return
                        grid.wheelAccum -= steps

                        const base = wheelAnim.running ? wheelAnim.to : grid.contentY
                        grid.glideTo(grid.snapTarget(base - steps * grid.wheelStep))
                    }
                }

                // Context menu — fills gridWrapper so clamping uses the right bounds
                WallpaperContextMenu {
                    id: ctxMenu
                    anchors.fill: parent
                }
            }
        }
    }
}
