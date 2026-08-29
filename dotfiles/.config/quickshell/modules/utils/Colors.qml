pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io
import qs.modules.settings

Item{
    id: colorProvider

    property var currentTheme: {
        switch(Settings.activeTheme) {
            case "Dark": return DarkTheme
            case "Light": return LightTheme
            case "Wallpaper": return WallpaperTheme
            default: return LightTheme
        }
    }

    // Expose all color properties from current theme
    readonly property string primary: currentTheme.primary
    readonly property string primaryText: currentTheme.primaryText
    readonly property string primaryContainer: currentTheme.primaryContainer
    readonly property string primaryContainerText: currentTheme.primaryContainerText

    readonly property string secondary: currentTheme.secondary
    readonly property string secondaryText: currentTheme.secondaryText
    readonly property string secondaryContainer: currentTheme.secondaryContainer
    readonly property string secondaryContainerText: currentTheme.secondaryContainerText

    readonly property string tertiary: currentTheme.tertiary
    readonly property string tertiaryText: currentTheme.tertiaryText
    readonly property string tertiaryContainer: currentTheme.tertiaryContainer
    readonly property string tertiaryContainerText: currentTheme.tertiaryContainerText

    readonly property string error: currentTheme.error
    readonly property string errorText: currentTheme.errorText
    readonly property string errorContainer: currentTheme.errorContainer
    readonly property string errorContainerText: currentTheme.errorContainerText

    readonly property string surface: currentTheme.surface
    readonly property string surfaceText: currentTheme.surfaceText
    readonly property string surfaceVariant: currentTheme.surfaceVariant
    readonly property string surfaceVariantText: currentTheme.surfaceVariantText

    readonly property string outline: currentTheme.outline
    readonly property string outlineVariant: currentTheme.outlineVariant
    readonly property string shadow: currentTheme.shadow
    readonly property string scrim: currentTheme.scrim

    readonly property string inverseSurface: currentTheme.inverseSurface
    readonly property string inverseSurfaceText: currentTheme.inverseSurfaceText
    readonly property string inversePrimary: currentTheme.inversePrimary

    readonly property string surfaceDim: currentTheme.surfaceDim
    readonly property string surfaceBright: currentTheme.surfaceBright
    readonly property string surfaceContainerLowest: currentTheme.surfaceContainerLowest
    readonly property string surfaceContainerLow: currentTheme.surfaceContainerLow
    readonly property string surfaceContainer: currentTheme.surfaceContainer
    readonly property string surfaceContainerHigh: currentTheme.surfaceContainerHigh
    readonly property string surfaceContainerHighest: currentTheme.surfaceContainerHighest

    readonly property string wallpaper: currentTheme.wallpaper || ""
}


