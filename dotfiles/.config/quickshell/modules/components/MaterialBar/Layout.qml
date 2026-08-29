import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.components.Bar
import qs.modules.settings
import qs.modules.components.ToolsWidget
import qs.modules.components.Setting
import qs.modules.components.Notification
import qs.modules.services
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MatrialShapeFn


PanelWindow{
    id: layout
    color: "transparent"
    anchors{
        top: true
        left: true
        right: true
        bottom: true
    }

    // true = full bar; false = secondary monitor minimal bar
    property bool isPrimary: true

    WlrLayershell.namespace: "quickshell:materialBar"
    WlrLayershell.keyboardFocus: isPrimary && utility.isTodoClicked
    ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region{
        item: maskRect;
        intersection: Intersection.Xor;
    }
    Rectangle{
        id: maskRect
        implicitHeight: parent.height
        implicitWidth: parent.width
        anchors.bottom: parent.bottom
        color: "transparent"
    }


    Item{
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: 50
        RowLayout{
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 10
            spacing: 10

            Rectangle{
                Layout.preferredWidth: 60
                Layout.preferredHeight: 36
                radius: 15
                color: Colors.primary
            }

            MaterialShapes.ShapeCanvas{
                implicitHeight: 36
                implicitWidth: 36
                roundedPolygon: MatrialShapeFn.getCircle()
                color: Colors.primary
            }

            MaterialShapes.ShapeCanvas{
                implicitHeight: 36
                implicitWidth: 36
                roundedPolygon: MatrialShapeFn.getCookie6Sided()
                color: Colors.primary
            }
        }
    }

}
