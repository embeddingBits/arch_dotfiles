pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io

Singleton {
    id: root

    // Defaults — used on startup until the JSON cache loads
    property string primary: "#ffb2b8"
    property string primaryText: "#67001d"
    property string primaryContainer: "#ff506d"
    property string primaryContainerText: "#000000"

    property string secondary: "#ffb2b8"
    property string secondaryText: "#67001d"
    property string secondaryContainer: "#8c1c32"
    property string secondaryContainerText: "#ffdcdd"

    property string tertiary: "#ffb68f"
    property string tertiaryText: "#542100"
    property string tertiaryContainer: "#e76d19"
    property string tertiaryContainerText: "#000000"

    property string error: "#ffb4ab"
    property string errorText: "#690005"
    property string errorContainer: "#93000a"
    property string errorContainerText: "#ffdad6"

    property string surface: "#1f0f10"
    property string surfaceText: "#fbdbdc"
    property string surfaceVariant: "#5c3f41"
    property string surfaceVariantText: "#e5bdbf"

    property string outline: "#ac888a"
    property string outlineVariant: "#5c3f41"
    property string shadow: "#000000"
    property string scrim: "#000000"

    property string inverseSurface: "#fbdbdc"
    property string inverseSurfaceText: "#3f2b2d"
    property string inversePrimary: "#be003c"

    property string surfaceDim: "#1f0f10"
    property string surfaceBright: "#493435"
    property string surfaceContainerLowest: "#190a0b"
    property string surfaceContainerLow: "#281718"
    property string surfaceContainer: "#2d1b1c"
    property string surfaceContainerHigh: "#382526"
    property string surfaceContainerHighest: "#443031"

    property string wallpaper: Quickshell.env("HOME") + "/wallpaper/sunset-lookout.jpg"

    property double _reloadRequestedAt: 0

    function _apply(json) {
        const elapsed = _reloadRequestedAt > 0
            ? (Date.now() - _reloadRequestedAt).toFixed(0) + "ms"
            : "startup"
        try {
            const c = JSON.parse(json)
            if (c.primary)                  root.primary                  = c.primary
            if (c.primaryText)              root.primaryText              = c.primaryText
            if (c.primaryContainer)         root.primaryContainer         = c.primaryContainer
            if (c.primaryContainerText)     root.primaryContainerText     = c.primaryContainerText
            if (c.secondary)                root.secondary                = c.secondary
            if (c.secondaryText)            root.secondaryText            = c.secondaryText
            if (c.secondaryContainer)       root.secondaryContainer       = c.secondaryContainer
            if (c.secondaryContainerText)   root.secondaryContainerText   = c.secondaryContainerText
            if (c.tertiary)                 root.tertiary                 = c.tertiary
            if (c.tertiaryText)             root.tertiaryText             = c.tertiaryText
            if (c.tertiaryContainer)        root.tertiaryContainer        = c.tertiaryContainer
            if (c.tertiaryContainerText)    root.tertiaryContainerText    = c.tertiaryContainerText
            if (c.error)                    root.error                    = c.error
            if (c.errorText)                root.errorText                = c.errorText
            if (c.errorContainer)           root.errorContainer           = c.errorContainer
            if (c.errorContainerText)       root.errorContainerText       = c.errorContainerText
            if (c.surface)                  root.surface                  = c.surface
            if (c.surfaceText)              root.surfaceText              = c.surfaceText
            if (c.surfaceVariant)           root.surfaceVariant           = c.surfaceVariant
            if (c.surfaceVariantText)       root.surfaceVariantText       = c.surfaceVariantText
            if (c.outline)                  root.outline                  = c.outline
            if (c.outlineVariant)           root.outlineVariant           = c.outlineVariant
            if (c.shadow)                   root.shadow                   = c.shadow
            if (c.scrim)                    root.scrim                    = c.scrim
            if (c.inverseSurface)           root.inverseSurface           = c.inverseSurface
            if (c.inverseSurfaceText)       root.inverseSurfaceText       = c.inverseSurfaceText
            if (c.inversePrimary)           root.inversePrimary           = c.inversePrimary
            if (c.surfaceDim)               root.surfaceDim               = c.surfaceDim
            if (c.surfaceBright)            root.surfaceBright            = c.surfaceBright
            if (c.surfaceContainerLowest)   root.surfaceContainerLowest   = c.surfaceContainerLowest
            if (c.surfaceContainerLow)      root.surfaceContainerLow      = c.surfaceContainerLow
            if (c.surfaceContainer)         root.surfaceContainer         = c.surfaceContainer
            if (c.surfaceContainerHigh)     root.surfaceContainerHigh     = c.surfaceContainerHigh
            if (c.surfaceContainerHighest)  root.surfaceContainerHighest  = c.surfaceContainerHighest
            if (c.wallpaper)                root.wallpaper                = c.wallpaper
            console.log("[WallpaperTheme] Colors applied (" + elapsed + ") — primary:", root.primary, "wallpaper:", root.wallpaper)
        } catch (e) {
            console.error("[WallpaperTheme] Failed to parse colors.json (" + elapsed + "):", e)
        }
        _reloadRequestedAt = 0
    }

    readonly property string _colorsPath: Quickshell.env("HOME") + "/.cache/quickshell/colors.json"

    Component.onCompleted: {
        console.log("[WallpaperTheme] Initialized — loading colors.json")
        _forceReopen()
    }

    // reload() re-reads from the same open FD, which points to the OLD inode after
    // matugen's atomic rename (rename changes the inode, FD stays on deleted file).
    // Resetting path forces FileView to close the stale FD and re-open by path.
    function reloadColors() {
        _reloadRequestedAt = Date.now()
        console.log("[WallpaperTheme] reloadColors() — forcing fresh open at", _reloadRequestedAt)
        _forceReopen()
    }

    function _forceReopen() {
        colorFile.path = ""
        colorFile.path = root._colorsPath
    }

    FileView {
        id: colorFile
        watchChanges: true
        onFileChanged: {
            // inotify IN_MOVED_TO fired — Qt already re-opened the FD here, so reload() is safe
            console.log("[WallpaperTheme] FileView inotify change detected — reloading")
            if (root._reloadRequestedAt === 0) root._reloadRequestedAt = Date.now()
            reload()
        }
        onLoaded: root._apply(text())
        onLoadFailed: console.warn("[WallpaperTheme] FileView could not load colors.json")
    }
}
