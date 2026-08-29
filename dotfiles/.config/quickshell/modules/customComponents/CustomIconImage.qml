import Quickshell
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.modules.utils



IconImage {
    property bool isColor: true
    property string icon
    property var color: Colors.surfaceText
    property var size
    property real bright : 0.1
    implicitSize: size
    source: IconUtil.getSystemIcon(icon)
    layer.enabled: isColor
    layer.effect: MultiEffect {
        colorization: 1.0
        colorizationColor: color
        Behavior on colorizationColor{
            ColorAnimation{
                duration: 200
            }
        }
        brightness: bright
    } 
}



