pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io

Item {
    id: colorProvider

    // Defaults until music_colors.json loads
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

    FileView {
        id: colorFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/music_colors.json"
        watchChanges: true

        onFileChanged: reload()

        onLoaded: {
            try {
                const c = JSON.parse(colorFile.text())
                if (c.primary)                  colorProvider.primary                  = c.primary
                if (c.primaryText)              colorProvider.primaryText              = c.primaryText
                if (c.primaryContainer)         colorProvider.primaryContainer         = c.primaryContainer
                if (c.primaryContainerText)     colorProvider.primaryContainerText     = c.primaryContainerText
                if (c.secondary)                colorProvider.secondary                = c.secondary
                if (c.secondaryText)            colorProvider.secondaryText            = c.secondaryText
                if (c.secondaryContainer)       colorProvider.secondaryContainer       = c.secondaryContainer
                if (c.secondaryContainerText)   colorProvider.secondaryContainerText   = c.secondaryContainerText
                if (c.tertiary)                 colorProvider.tertiary                 = c.tertiary
                if (c.tertiaryText)             colorProvider.tertiaryText             = c.tertiaryText
                if (c.tertiaryContainer)        colorProvider.tertiaryContainer        = c.tertiaryContainer
                if (c.tertiaryContainerText)    colorProvider.tertiaryContainerText    = c.tertiaryContainerText
                if (c.error)                    colorProvider.error                    = c.error
                if (c.errorText)               colorProvider.errorText                = c.errorText
                if (c.errorContainer)           colorProvider.errorContainer           = c.errorContainer
                if (c.errorContainerText)       colorProvider.errorContainerText       = c.errorContainerText
                if (c.surface)                  colorProvider.surface                  = c.surface
                if (c.surfaceText)              colorProvider.surfaceText              = c.surfaceText
                if (c.surfaceVariant)           colorProvider.surfaceVariant           = c.surfaceVariant
                if (c.surfaceVariantText)       colorProvider.surfaceVariantText       = c.surfaceVariantText
                if (c.outline)                  colorProvider.outline                  = c.outline
                if (c.outlineVariant)           colorProvider.outlineVariant           = c.outlineVariant
                if (c.shadow)                   colorProvider.shadow                   = c.shadow
                if (c.scrim)                    colorProvider.scrim                    = c.scrim
                if (c.inverseSurface)           colorProvider.inverseSurface           = c.inverseSurface
                if (c.inverseSurfaceText)       colorProvider.inverseSurfaceText       = c.inverseSurfaceText
                if (c.inversePrimary)           colorProvider.inversePrimary           = c.inversePrimary
                if (c.surfaceDim)               colorProvider.surfaceDim               = c.surfaceDim
                if (c.surfaceBright)            colorProvider.surfaceBright            = c.surfaceBright
                if (c.surfaceContainerLowest)   colorProvider.surfaceContainerLowest   = c.surfaceContainerLowest
                if (c.surfaceContainerLow)      colorProvider.surfaceContainerLow      = c.surfaceContainerLow
                if (c.surfaceContainer)         colorProvider.surfaceContainer         = c.surfaceContainer
                if (c.surfaceContainerHigh)     colorProvider.surfaceContainerHigh     = c.surfaceContainerHigh
                if (c.surfaceContainerHighest)  colorProvider.surfaceContainerHighest  = c.surfaceContainerHighest
            } catch (e) {
                console.error("[MusicTheme] Failed to parse music_colors.json:", e)
            }
        }

        onLoadFailed: {
            console.warn("[MusicTheme] Could not load music_colors.json from:", path)
        }
    }
}
