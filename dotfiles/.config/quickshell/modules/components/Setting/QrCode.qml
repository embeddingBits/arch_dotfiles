import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Rectangle {
    id: root
    color: Qt.alpha(Colors.surface, 0.5)
    radius: 20

    property var network
    signal close

    implicitWidth: 280
    implicitHeight: 280

    Component.onCompleted: {
        if (network)
            ServiceNetwork.generateQr(network.name, network.security)
    }

    
    MouseArea{
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.close()
    }

    Connections {
        target: ServiceNetwork
        function onQrGenerated(path) {
            qrImage.source = "file://" + path
        }
        function onQrFailed() {
            statusText.visible = true
        }
    }

    Rectangle {
        width: 240
        height: 240
        radius: 20
        color: Colors.surfaceContainerHigh
        anchors.centerIn: parent


        NumberAnimation on scale{
            from: 0.7
            to: 1
            duration: 300
            easing.type: Easing.OutQuad
        }
        ClippingWrapperRectangle{
            anchors.fill: parent
            anchors.margins: 10
            radius: 20
            color: "transparent"
            Image {
                id: qrImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                visible: source !== ""
                smooth: false
            }
        }

        Text {
            id: statusText
            anchors.centerIn: parent
            text: qrImage.source !== "" ? "" : (statusText.visible ? "Failed to generate QR" : "Generating...")
            color: Colors.onSurface
            visible: qrImage.source === ""
        }
    }
}
