pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io

Item {
    id: colorProvider
    
    // Material You color properties (safe names to avoid QML conflicts)
    property string primary: "#006874"
    property string primaryText: "#ffffff"
    property string primaryContainer: "#9eeffd"
    property string primaryContainerText: "#001f24"
    
    property string secondary: "#4a6267"
    property string secondaryText: "#ffffff"
    property string secondaryContainer: "#cde7ec"
    property string secondaryContainerText: "#051f23"
    
    property string tertiary: "#525e7d"
    property string tertiaryText: "#ffffff"
    property string tertiaryContainer: "#dae2ff"
    property string tertiaryContainerText: "#0e1b37"
    
    property string error: "#ba1a1a"
    property string errorText: "#ffffff"
    property string errorContainer: "#ffdad6"
    property string errorContainerText: "#410002"
    
    property string surface: "#f5fafb"
    property string surfaceText: "#171d1e"
    property string surfaceVariant: "#dbe4e6"
    property string surfaceVariantText: "#3f484a"
    
    property string outline: "#6f797a"
    property string outlineVariant: "#bfc8ca"
    property string shadow: "#000000"
    property string scrim: "#000000"
    
    property string inverseSurface: "#2b3133"
    property string inverseSurfaceText: "#ecf2f3"
    property string inversePrimary: "#82d3e0"
    
    property string surfaceDim: "#d5dbdc"
    property string surfaceBright: "#f5fafb"
    property string surfaceContainerLowest: "#ffffff"
    property string surfaceContainerLow: "#eff5f6"
    property string surfaceContainer: "#e9eff0"
    property string surfaceContainerHigh: "#e3e9ea"
    property string surfaceContainerHighest: "#dee3e5"
    
    // Wallpaper path
    property string wallpaper: ""
    

}

