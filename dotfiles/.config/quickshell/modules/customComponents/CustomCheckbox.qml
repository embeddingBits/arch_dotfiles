import QtQuick
import qs.modules.utils
import QtQuick.Effects 

Rectangle{
    id: root
    property bool checkState: false
    implicitWidth: 18
    implicitHeight: 18
    radius: height / 2
    color: Colors.surface
    border{
        width: 1
        color: Colors.outline
    }


    Loader{
        active: root.checkState
        anchors.fill: parent
        sourceComponent: Rectangle{
            anchors.fill: parent
            anchors.margins: 2
            color: Colors.primary
            radius: height / 2
        }
    }

    // MouseArea{
    //     anchors.fill: parent
    //     cursorShape: Qt.PointingHandCursor
    //     onClicked:{
    //         root.checkState = !root.checkState
    //         root.state()
    //     }
    // }

}
