import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import QtCore
import QtQuick
import qs.modules.settings
import qs.modules.utils
import qs.modules.services

pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    property string wallpaperDir: SettingsConfig.general.wallpaperDir ?? (Quickshell.env("HOME") + "/wallpaper")

    onWallpaperDirChanged: {
        if (folderModel.folder.toString() !== "") {
            processedFiles = {}
            wallpaperMap = {}
            wallpapers = []
            folderModel.folder = "file://" + wallpaperDir
        }
    }
    property string cacheDir: StandardPaths.writableLocation(StandardPaths.CacheLocation).toString().replace("file://", "") + "/wallpaper-thumbs"
    property int thumbSize: 256
    property string wallpaperScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/wallpaper.sh"
    property string scheme: SettingsConfig.theme.matugenScheme
    property string theme: SettingsConfig.theme.matugenTheme
    property string transitionType: SettingsConfig.theme.transitionType ?? "fade"

    // ── Wallpaper application queue ────────────────────────────────────────
    // awww (~0.16s) + matugen (~0.3s) = wallpaper.sh finishes in < 1s.
    // We use execDetached (fire-and-forget) and reload colors after a fixed
    // 1.5s window — no Process re-use state to get stuck.
    // Rapid clicks: only the latest path within the 1.5s window is applied.
    property string _pendingPath: ""
    property bool   _applying: false

    // Fired 3s after _startApply — awww (~0.16s) + gen_colors cold (~615ms) = well within 3s
    Timer {
        id: applyTimer
        interval: 3000
        repeat: false
        onTriggered: {
            const elapsed = (Date.now() - root._applyStartedAt).toFixed(0)
            console.log("[ServiceWallpaper] applyTimer fired at", elapsed + "ms — calling reloadColors()")
            WallpaperTheme.reloadColors()
            root._applying = false
            const next = root._pendingPath
            root._pendingPath = ""
            if (next) {
                console.log("[ServiceWallpaper] Dequeuing pending wallpaper:", next)
                root._startApply(next)
            }
        }
    }

    property double _applyStartedAt: 0

    function _startApply(path) {
        _applying = true
        _pendingPath = ""
        _applyStartedAt = Date.now()
        console.log("[ServiceWallpaper] _startApply →", path, "| mode:", root.theme, "| t=0ms")
        Quickshell.execDetached([wallpaperScript, path, root.scheme, root.theme, root.transitionType])
        applyTimer.restart()
    }

    function _enqueue(path) {
        if (!path || path.length === 0) return
        if (_applying) {
            console.log("[ServiceWallpaper] Queued (busy):", path)
            _pendingPath = path
        } else {
            _startApply(path)
        }
    }

    property string colorsScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/gen_colors.py"

    // Re-generates colors for the current wallpaper in the new mode.
    // No awww — wallpaper image isn't changing, only the color scheme.
    // gen_colors.py: ~615ms cold, ~44ms score-cached, ~2ms fully-cached.
    function applyTheme() {
        const wp = WallpaperTheme.wallpaper
        if (!wp || wp.length === 0) {
            console.warn("[ServiceWallpaper] applyTheme: no wallpaper loaded yet")
            return
        }
        console.log("[ServiceWallpaper] applyTheme → mode:", root.theme, "wallpaper:", wp)
        Quickshell.execDetached(["python3", colorsScript, wp, root.scheme, root.theme])
        themeTimer.restart()
        console.log("[ServiceWallpaper] execDetached done, timer started (fires in 2000ms)")
    }

    // 2s covers worst-case cold gen (~615ms) plus plenty of margin
    Timer {
        id: themeTimer
        interval: 2000
        repeat: false
        onTriggered: {
            console.log("[ServiceWallpaper] themeTimer fired — calling reloadColors()")
            WallpaperTheme.reloadColors()
        }
    }
    // ── End queue ──────────────────────────────────────────────────────────

    property list<string> wallpapers: []
    property var filteredWallpapers: []
    property string currentSearchText: ""
    property var wallpaperMap: ({})
    property var processedFiles: ({})
    property string localSortBy: "name"

    onLocalSortByChanged: updateWallpapersList()

    // ── Favorites ──────────────────────────────────────────────────────────
    property string favoritesPath: Quickshell.env("HOME") + "/.config/quickshell/favorites.json"
    property var favorites: ({})
    property var favoritedWallpapers: []

    function isFavorite(cachePath) {
        return !!favorites[getOriginalPath(cachePath)]
    }

    function toggleFavorite(cachePath) {
        const orig = getOriginalPath(cachePath)
        if (!orig) return
        const copy = Object.assign({}, favorites)
        if (copy[orig]) delete copy[orig]
        else copy[orig] = true
        favorites = copy
        _updateFavoritedWallpapers()
        saveFavorites()
    }

    function _updateFavoritedWallpapers() {
        const favList = []
        for (let i = 0; i < wallpapers.length; i++) {
            const cp = wallpapers[i]
            if (favorites[getOriginalPath(cp)]) favList.push(cp)
        }
        favoritedWallpapers = favList
    }

    function saveFavorites() {
        const data = JSON.stringify(Object.keys(favorites))
        favSaver.command = [
            "python3", "-c",
            "import sys,json; json.dump(json.loads(sys.argv[1]),open(sys.argv[2],'w'),indent=2)",
            data, favoritesPath
        ]
        favSaver.running = true
    }

    function loadFavorites() {
        favLoader._buffer = ""
        favLoader.command = [
            "bash", "-c",
            "[ -f '" + favoritesPath + "' ] && cat '" + favoritesPath + "' || echo '[]'"
        ]
        favLoader.running = true
    }
    // ── End Favorites ──────────────────────────────────────────────────────

    // ── Online / Wallhaven ──────────────────────────────────────────────────
    property bool onlineMode: false
    property list<var> onlineWallpapers: []
    property bool isFetchingOnline: false
    property int  onlinePage: 1
    property bool hasMorePages: false
    property string _fetchBuffer: ""
    property string _pendingDownloadPath: ""
    property string onlineError: ""
    property string downloadingId: ""
    property int downloadedBytes: 0
    property int downloadTotalBytes: 0
    readonly property real downloadProgress: downloadTotalBytes > 0
        ? Math.min(1.0, downloadedBytes / downloadTotalBytes) : 0
    property bool _cancelingDownload: false

    onOnlineModeChanged: {
        if (onlineMode) {
            onlineWallpapers = []
            onlinePage = 1
            onlineError = ""
        }
    }

    function buildWallhavenUrl(page) {
        const p = []
        p.push("categories=" + SettingsConfig.wallhaven.categories)
        p.push("purity="     + SettingsConfig.wallhaven.purity)
        p.push("sorting="    + SettingsConfig.wallhaven.sorting)
        p.push("order="      + SettingsConfig.wallhaven.order)
        if (SettingsConfig.wallhaven.sorting === "toplist")
            p.push("topRange=" + SettingsConfig.wallhaven.topRange)
        if (SettingsConfig.wallhaven.atleast.length > 0)
            p.push("atleast=" + SettingsConfig.wallhaven.atleast)
        if (SettingsConfig.wallhaven.ratios.length > 0)
            p.push("ratios=" + SettingsConfig.wallhaven.ratios)
        if (currentSearchText.length > 0)
            p.push("q=" + encodeURIComponent(currentSearchText))
        if (SettingsConfig.wallhaven.apiKey.length > 0)
            p.push("apikey=" + SettingsConfig.wallhaven.apiKey)
        p.push("page=" + page)
        return "https://wallhaven.cc/api/v1/search?" + p.join("&")
    }

    function fetchWallhaven(resetPage) {
        if (isFetchingOnline) return
        if (resetPage) {
            onlinePage = 1
            onlineWallpapers = []
        }
        isFetchingOnline = true
        onlineError = ""
        _fetchBuffer = ""
        const url = buildWallhavenUrl(onlinePage)
        console.log("[ServiceWallpaper] Fetching Wallhaven page", onlinePage, "–", url)
        wallhavenFetcher.command = ["bash", "-c", "curl -s '" + url + "'"]
        wallhavenFetcher.running = true
    }

    function _parseWallhavenResults(json) {
        try {
            const data = JSON.parse(json)

            // API-level error (e.g. bad API key, invalid params)
            if (data.error) {
                onlineError = data.error
                console.error("[ServiceWallpaper] Wallhaven API error:", data.error)
                isFetchingOnline = false
                return
            }

            const items = data.data || []
            const meta  = data.meta || {}

            const parsed = items.map(item => ({
                id:         item.id,
                thumbUrl:   item.thumbs.large,
                fullUrl:    item.path,
                resolution: item.resolution,
                fileType:   item.file_type,
                fileSize:   item.file_size || 0
            }))

            onlineWallpapers = (onlinePage === 1)
                ? parsed
                : [...onlineWallpapers, ...parsed]

            hasMorePages = (meta.current_page || 1) < (meta.last_page || 1)
            onlineError = ""
            console.log("[ServiceWallpaper] Wallhaven: got", parsed.length,
                        "wallpapers, page", meta.current_page, "/", meta.last_page)
        } catch (e) {
            // Non-JSON response — usually the rate-limit plain-text message
            const msg = json.trim()
            onlineError = msg.length > 0 ? msg : "Failed to parse response"
            console.error("[ServiceWallpaper] Wallhaven parse error:", e, "| body:", msg)
        }
        isFetchingOnline = false
    }

    function fetchNextPage() {
        if (!hasMorePages || isFetchingOnline) return
        onlinePage++
        fetchWallhaven(false)
    }

    function downloadAndSetWallpaper(wallpaper) {
        if (_pendingDownloadPath.length > 0) {
            console.warn("[ServiceWallpaper] Download already in progress")
            return
        }
        const ext = wallpaper.fullUrl.split('.').pop().split('?')[0] || "jpg"
        const savePath = root.wallpaperDir + "/" + wallpaper.id + "." + ext
        _pendingDownloadPath = savePath
        downloadingId = wallpaper.id
        downloadedBytes = 0
        downloadTotalBytes = wallpaper.fileSize || 0
        downloadPoller.restart()
        console.log("[ServiceWallpaper] Downloading wallpaper", wallpaper.id, "->", savePath)
        wallhavenDownloader.command = [
            "bash", "-c",
            "curl -sL '" + wallpaper.fullUrl + "' -o '" + savePath + "'"
        ]
        wallhavenDownloader.running = true
    }

    function cancelDownload() {
        if (!wallhavenDownloader.running) return
        _cancelingDownload = true
        wallhavenDownloader.running = false
    }
    // ── End Online ──────────────────────────────────────────────────────────

    onWallpapersChanged: {
        updateSearch(currentSearchText)
        _updateFavoritedWallpapers()
    }

    function fuzzyQuery(search: string): var {
        const existing = new Set(wallpapers)
        const preps = []
        for (let i = 0; i < folderModel.count; i++) {
            const orig = folderModel.get(i, "filePath")
            const cachePath = root.cacheDir + "/" + Qt.md5(orig) + ".jpg"
            if (existing.has(cachePath)) {
                preps.push({
                    content: Fuzzy.prepare(orig.split("/").pop()),
                    cachePath: cachePath
                })
            }
        }
        return Fuzzy.go(search, preps, { all: true, key: "content" })
            .map(r => r.obj.cachePath)
    }

    function updateSearch(searchText) {
        currentSearchText = searchText
        filteredWallpapers = searchText.length > 0 ? fuzzyQuery(searchText) : [...wallpapers]
    }

    property alias folderModel: folderModel
    property alias cacheModel: cacheModel

    property var thumbQueue: []
    property bool isProcessing: false

    Process {
        id: createCacheDir
        command: ["sh", "-c", "mkdir -p '" + root.cacheDir + "' && ls '" + root.cacheDir + "' > /dev/null"]
        running: true
        onExited: (exitCode) => {
            if (exitCode === 0) {
                console.log("[ServiceWallpaper] Cache directory ready:", root.cacheDir)
                cacheModel.folder = "file://" + root.cacheDir
                folderModel.folder = "file://" + root.wallpaperDir
                root.loadFavorites()
            } else {
                console.error("[ServiceWallpaper] Failed to create cache directory:", root.cacheDir)
            }
        }
    }

    FolderListModel {
        id: folderModel
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.PNG", "*.JPG", "*.JPEG"]
        showDirs: false
        showFiles: true
        showDotAndDotDot: false
        showOnlyReadable: true

        onFolderChanged: {
            console.log("[ServiceWallpaper] Scanning wallpaper folder:", root.wallpaperDir)
        }

        onCountChanged: {
            console.log("[ServiceWallpaper] Found", count, "wallpapers in folder")
            if (count === 0) {
                console.warn("[ServiceWallpaper] No wallpapers found! Check if folder exists:", root.wallpaperDir)
            }
            if (count > 0 && !root.isProcessing) {
                generateThumbnails()
            }
        }

        onStatusChanged: {
            if (status === FolderListModel.Ready && count === 0)
                console.warn("[ServiceWallpaper] Folder is ready but empty. Path:", root.wallpaperDir)
            if (status === FolderListModel.Ready)
                root.generateThumbnails()
        }
    }

    FolderListModel {
        id: cacheModel
        nameFilters: ["*.jpg"]
        showDirs: false
        showFiles: true
        showDotAndDotDot: false
        showOnlyReadable: true

        onFolderChanged: {
            console.log("[ServiceWallpaper] Cache folder changed to:", folder)
        }

        onCountChanged: {
            console.log("[ServiceWallpaper] Cache contains", count, "thumbnails")
            updateWallpapersList()
        }

        onStatusChanged: {
            if (status === FolderListModel.Ready)
                root.generateThumbnails()
        }
    }

    function cachedThumbNames() {
        const have = ({})
        for (let i = 0; i < cacheModel.count; i++)
            have[cacheModel.get(i, "fileName")] = true
        return have
    }

    function generateThumbnails() {
        if (root.isProcessing) return
        if (folderModel.count === 0) return
        if (folderModel.status !== FolderListModel.Ready) return
        if (cacheModel.status !== FolderListModel.Ready) return

        const have = root.cachedThumbNames()
        const queue = []

        for (let i = 0; i < folderModel.count; i++) {
            const originalPath = folderModel.get(i, "filePath")
            const hash = Qt.md5(originalPath)
            const thumbPath = root.cacheDir + "/" + hash + ".jpg"

            if (have[hash + ".jpg"]) {
                root.wallpaperMap[thumbPath] = originalPath
                root.processedFiles[originalPath] = true
                continue
            }

            if (root.processedFiles[originalPath]) continue
            queue.push({ originalPath: originalPath, thumbPath: thumbPath })
        }

        root.updateWallpapersList()

        if (queue.length === 0) return

        console.log("[ServiceWallpaper] Generating", queue.length, "missing thumbnails")
        root.thumbQueue = queue
        root.isProcessing = true
        root.processNextThumbnail()
    }

    function processNextThumbnail() {
        if (root.thumbQueue.length === 0) {
            root.isProcessing = false
            root.updateWallpapersList()
            return
        }

        const job = root.thumbQueue[0]
        root.processedFiles[job.originalPath] = true
        root.wallpaperMap[job.thumbPath] = job.originalPath

        thumbGenerator.originalPath = job.originalPath
        thumbGenerator.thumbPath = job.thumbPath
        thumbGenerator.command = [
            "convert",
            job.originalPath,
            "-resize", root.thumbSize + "x" + root.thumbSize + "^",
            "-gravity", "center",
            "-extent", root.thumbSize + "x" + root.thumbSize,
            "-quality", "85",
            job.thumbPath
        ]
        thumbGenerator.running = true
    }

    Process {
        id: thumbGenerator
        property string originalPath: ""
        property string thumbPath: ""

        onExited: (exitCode) => {
            if (exitCode !== 0) {
                console.error("[ServiceWallpaper] Failed to generate thumbnail for:", originalPath)
                delete root.wallpaperMap[thumbPath]
            }
            root.thumbQueue = root.thumbQueue.slice(1)
            processNextThumbnail()
        }
    }

    function updateWallpapersList() {
        const entries = []
        for (let i = 0; i < folderModel.count; i++) {
            const originalPath = folderModel.get(i, "filePath")
            const cachePath = root.cacheDir + "/" + Qt.md5(originalPath) + ".jpg"
            if (root.wallpaperMap[cachePath]) {
                entries.push({
                    cachePath: cachePath,
                    modified: folderModel.get(i, "fileModified")
                })
            }
        }
        if (localSortBy === "newest") {
            entries.sort((a, b) => new Date(b.modified) - new Date(a.modified))
        } else {
            entries.sort((a, b) => {
                const nameA = root.wallpaperMap[a.cachePath].split("/").pop().toLowerCase()
                const nameB = root.wallpaperMap[b.cachePath].split("/").pop().toLowerCase()
                return nameA < nameB ? -1 : nameA > nameB ? 1 : 0
            })
        }
        console.log("[ServiceWallpaper] Total wallpapers available:", entries.length)
        root.wallpapers = entries.map(e => e.cachePath)
    }

    function getOriginalPath(cachePath: string): string {
        return root.wallpaperMap[cachePath] || cachePath
    }

    function setWallpaper(cachePath: string) {
        const originalPath = getOriginalPath(cachePath)
        if (!originalPath) {
            console.error("[ServiceWallpaper] Cannot find original path for:", cachePath)
            return
        }
        console.log("[ServiceWallpaper] Setting wallpaper:", originalPath)
        _enqueue(originalPath)
    }

    function refresh() {
        console.log("[ServiceWallpaper] Refreshing wallpaper list")
        const folder = folderModel.folder
        folderModel.folder = ""
        folderModel.folder = folder
    }

    // ── Wallhaven processes ─────────────────────────────────────────────────
    Process {
        id: wallhavenFetcher
        stdout: SplitParser {
            onRead: line => { root._fetchBuffer += line }
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root._parseWallhavenResults(root._fetchBuffer)
            } else {
                root.onlineError = "Network error — check your connection (curl exit " + exitCode + ")"
                console.error("[ServiceWallpaper] Wallhaven curl failed, exit:", exitCode)
                root.isFetchingOnline = false
            }
            root._fetchBuffer = ""
        }
    }

    Process {
        id: wallhavenDownloader
        onExited: (exitCode) => {
            downloadPoller.stop()
            root.downloadingId = ""
            root.downloadedBytes = 0
            if (root._cancelingDownload) {
                console.log("[ServiceWallpaper] Download canceled:", root._pendingDownloadPath)
                Quickshell.execDetached(["rm", "-f", root._pendingDownloadPath])
                root._cancelingDownload = false
            } else if (exitCode === 0) {
                console.log("[ServiceWallpaper] Download complete:", root._pendingDownloadPath)
                const savePath = root._pendingDownloadPath
                const thumbPath = root.cacheDir + "/" + Qt.md5(savePath) + ".jpg"
                root.processedFiles[savePath] = true
                downloadedThumbGen.savePath = savePath
                downloadedThumbGen.thumbPath = thumbPath
                downloadedThumbGen.command = [
                    "convert", savePath,
                    "-resize", root.thumbSize + "x" + root.thumbSize + "^",
                    "-gravity", "center",
                    "-extent", root.thumbSize + "x" + root.thumbSize,
                    "-quality", "85",
                    thumbPath
                ]
                downloadedThumbGen.running = true
                root._enqueue(savePath)
            } else {
                console.error("[ServiceWallpaper] Download failed for:", root._pendingDownloadPath)
                ServiceNotification.sendNotification(
                    "Wallpaper Download Failed",
                    root._pendingDownloadPath.split("/").pop(),
                    "Wallpaper",
                    "dialog-error"
                )
            }
            root._pendingDownloadPath = ""
        }
    }

    Process {
        id: downloadedThumbGen
        property string savePath: ""
        property string thumbPath: ""
        onExited: (exitCode) => {
            if (exitCode === 0) {
                console.log("[ServiceWallpaper] Download thumbnail ready:", thumbPath)
                root.wallpaperMap[thumbPath] = savePath
                const fileName = savePath.split("/").pop()
                ServiceNotification.sendNotification(
                    "Wallpaper Downloaded",
                    fileName,
                    "Wallpaper",
                    "image-x-generic",
                    thumbPath
                )
                root.refresh()
            } else {
                console.error("[ServiceWallpaper] Failed to generate thumbnail for:", savePath)
                ServiceNotification.sendNotification(
                    "Wallpaper Download Failed",
                    savePath.split("/").pop(),
                    "Wallpaper",
                    "dialog-error"
                )
            }
        }
    }

    Timer {
        id: downloadPoller
        interval: 300
        repeat: true
        running: false
        onTriggered: {
            if (root._pendingDownloadPath.length > 0 && !fileSizeChecker.running) {
                fileSizeChecker._buf = ""
                fileSizeChecker.command = ["stat", "-c", "%s", root._pendingDownloadPath]
                fileSizeChecker.running = true
            }
        }
    }

    Process {
        id: fileSizeChecker
        property string _buf: ""
        stdout: SplitParser {
            onRead: line => fileSizeChecker._buf += line
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                const sz = parseInt(fileSizeChecker._buf.trim())
                if (!isNaN(sz)) root.downloadedBytes = sz
            }
            fileSizeChecker._buf = ""
        }
    }
    // ── End Wallhaven processes ─────────────────────────────────────────────

    // ── Favorites processes ─────────────────────────────────────────────────
    Process {
        id: favLoader
        property string _buffer: ""
        stdout: SplitParser {
            onRead: line => { favLoader._buffer += line }
        }
        onExited: (exitCode) => {
            if (exitCode === 0 && favLoader._buffer.length > 0) {
                try {
                    const keys = JSON.parse(favLoader._buffer)
                    const set = {}
                    for (let i = 0; i < keys.length; i++) set[keys[i]] = true
                    root.favorites = set
                    root._updateFavoritedWallpapers()
                    console.log("[ServiceWallpaper] Loaded", keys.length, "favorites")
                } catch (e) {
                    console.warn("[ServiceWallpaper] Failed to parse favorites:", e)
                }
            }
            favLoader._buffer = ""
        }
    }

    Process {
        id: favSaver
        onExited: (exitCode) => {
            if (exitCode !== 0)
                console.error("[ServiceWallpaper] Failed to save favorites, exit:", exitCode)
        }
    }
    // ── End Favorites processes ─────────────────────────────────────────────

    // ── File management ─────────────────────────────────────────────────────
    function deleteWallpaper(cachePath) {
        const orig = getOriginalPath(cachePath)
        if (!orig) return
        fileDeleter._cachePath = cachePath
        fileDeleter._origPath  = orig
        fileDeleter.command = ["rm", "-f", orig, cachePath]
        fileDeleter.running = true
        console.log("[ServiceWallpaper] Deleting wallpaper:", orig)
    }

    Process {
        id: fileDeleter
        property string _cachePath: ""
        property string _origPath: ""
        onExited: exitCode => {
            if (exitCode === 0) {
                delete root.wallpaperMap[_cachePath]
                delete root.processedFiles[_origPath]
                root.wallpapers = root.wallpapers.filter(w => w !== _cachePath)
            } else {
                console.error("[ServiceWallpaper] Delete failed for:", _origPath)
            }
        }
    }
    // ── End File management ──────────────────────────────────────────────────
}
