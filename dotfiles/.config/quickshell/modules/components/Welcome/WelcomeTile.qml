import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

Rectangle {
    id: tile

    property string icon: ""
    property string title: ""
    property string note: ""

    default property alias tileData: content.data

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + 36
    radius: 24
    color: Colors.surfaceContainerLow

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 18
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            MaterialIconSymbol {
                content: tile.icon
                iconSize: 18
                fill: 1
                customColor: Colors.primary
            }

            CustomText {
                content: tile.title
                size: 13
                weight: 700
                customColor: Colors.primary
            }

            CustomText {
                Layout.fillWidth: true
                visible: tile.note !== ""
                content: tile.note
                size: 12
                customColor: Colors.outline
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            id: content
            Layout.fillWidth: true
            spacing: 12
        }
    }
}
