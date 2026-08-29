import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import "../../MatrialShapes/" as MaterialShapes
import "../../MatrialShapes/material-shapes.js" as MaterialShapeFn

// Shown by every expanded music surface when no MPRIS player is alive. Same
// shape-plus-glyph treatment the settings pages use for their empty sections,
// so an idle player reads as "nothing here yet" rather than as a broken panel.
Item {
    id: root

    property string message: "Nothing playing"
    property string hint: "Start something and it'll show up here"

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 46
            implicitHeight: 46

            MaterialShapes.ShapeCanvas {
                anchors.fill: parent
                roundedPolygon: MaterialShapeFn.getCookie6Sided()
                color: Colors.surfaceContainerHighest
            }

            MaterialIconSymbol {
                anchors.centerIn: parent
                content: "music_off"
                iconSize: 22
                customColor: Colors.outline
            }
        }

        CustomText {
            Layout.alignment: Qt.AlignHCenter
            content: root.message
            size: 13
            weight: 600
            customColor: Colors.outline
        }

        CustomText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -6
            content: root.hint
            size: 11
            customColor: Colors.outline
            visible: root.hint !== ""
        }
    }
}
