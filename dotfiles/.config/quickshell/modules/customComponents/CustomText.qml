import QtQuick
import qs.modules.settings
import qs.modules.utils
import QtQuick.Effects

Text {
    id: root
    property alias content: root.text
    property int size: 12
    verticalAlignment: Text.AlignVCenter
    property int weight: _baseWeight
    property string customColor: Colors.surfaceText
    property string family: SettingsConfig.general.defaultFont ?? "Rubik"
    renderType: Text.NativeRendering
    elide: Text.ElideRight
    color: customColor
    font.pixelSize: Math.round(size * _sizeScale)
    font.weight: weight
    font.family: family

    readonly property real _sizeScale: {
        var s = SettingsConfig.general.fontScale ?? "normal"
        if (s === "compact") return 0.85
        if (s === "large")   return 1.15
        if (s === "xlarge")  return 1.3
        return 1.0
    }

    readonly property int _baseWeight: {
        var w = SettingsConfig.general.fontWeight ?? "extrabold"
        if (w === "thin")     return 300
        if (w === "regular")  return 400
        if (w === "medium")   return 500
        if (w === "semibold") return 600
        if (w === "bold")     return 700
        return 800
    }

    Behavior on color {
        ColorAnimation { duration: 200 }
    }
}
