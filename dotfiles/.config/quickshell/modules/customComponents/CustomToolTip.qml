import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.utils


ToolTip{
    id: root
    property string content
    opacity: 0
    NumberAnimation on opacity{
        from: 0
        to: 1
        duration: 200
        running: true
    }
    verticalPadding: 7
    horizontalPadding: 10
    background: null
    delay: 400
    contentItem : Item{
        id: contentItemBackground
        implicitWidth: tooltipTextObject.width + 2 * root.horizontalPadding
        implicitHeight: tooltipTextObject.height + 2 * root.verticalPadding

        Rectangle{
            implicitHeight: tooltipTextObject.height + 2 * padding
            implicitWidth: tooltipTextObject.width + 2 * padding
            anchors.bottom: contentItemBackground.bottom
            anchors.horizontalCenter: contentItemBackground.horizontalCenter
            radius: 10
            color: Colors.surface


            CustomText{
                id: tooltipTextObject
                content: root.content
                anchors.centerIn: parent
                size: 12
                wrapMode: Text.Wrap
                font.hintingPreference: Font.PreferNoHinting
            }
        }
    }
}

