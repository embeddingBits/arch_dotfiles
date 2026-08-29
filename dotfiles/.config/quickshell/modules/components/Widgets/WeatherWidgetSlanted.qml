import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

WidgetHost {
    id: root
    configKey: "weatherSlanted"
    defaultPos: Qt.point(100, 200)
    implicitWidth: 200
    implicitHeight: 200

    // getPill() is a horizontal pill — render it on a swapped canvas rotated 90°
    // so it becomes a vertical pill that fills the portrait Item exactly.
    MaterialShapes.ShapeCanvas {
        anchors.centerIn: parent
        width: parent.height
        height: parent.width
        roundedPolygon: MaterialShapeFn.getPill()
        color: Colors.surface
    }

    CustomText {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 30
        anchors.rightMargin: 30
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 2
        content: ServiceWeather.temperature
        size: 60
        color: Colors.surfaceText
    }

    Image {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 40
        anchors.leftMargin: 40
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 8
        width: 60
        height: 60
        sourceSize.width: 60
        sourceSize.height: 60
        source: IconUtil.getSystemIcon(ServiceWeather.weatherIconPath.svg)
    }

}
