pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io

Item {
    id: colorProvider
    
    // Material You color properties (safe names to avoid QML conflicts)
    property string primary: "#87d6bc"
    property string primaryText: "#00382b"
    property string primaryContainer: "#005140"
    property string primaryContainerText: "#a3f2d7"
    
    property string secondary: "#b2ccc1"
    property string secondaryText: "#1d352d"
    property string secondaryContainer: "#344c43"
    property string secondaryContainerText: "#cee9dd"
    
    property string tertiary: "#a8cbe2"
    property string tertiaryText: "#0d3446"
    property string tertiaryContainer: "#284b5e"
    property string tertiaryContainerText: "#c4e7ff"
    
    property string error: "#ffb4ab"
    property string errorText: "#690005"
    property string errorContainer: "#93000a"
    property string errorContainerText: "#ffdad6"
    
    property string surface: "#0f1512"
    property string surfaceText: "#dee4e0"
    property string surfaceVariant: "#3f4945"
    property string surfaceVariantText: "#bfc9c3"
    
    property string outline: "#89938e"
    property string outlineVariant: "#3f4945"
    property string shadow: "#000000"
    property string scrim: "#000000"
    
    property string inverseSurface: "#dee4e0"
    property string inverseSurfaceText: "#2b322f"
    property string inversePrimary: "#126b56"
    
    property string surfaceDim: "#0f1512"
    property string surfaceBright: "#343b38"
    property string surfaceContainerLowest: "#090f0d"
    property string surfaceContainerLow: "#171d1a"
    property string surfaceContainer: "#1b211e"
    property string surfaceContainerHigh: "#252b29"
    property string surfaceContainerHighest: "#303633"
    
    // Wallpaper path
    property string wallpaper: ""
    

}

