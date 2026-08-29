import QtQuick
import qs.modules.utils
import "../MatrialShapes" as MaterialShapes
import "../MatrialShapes/material-shapes.js" as MaterialShapeFn

FocusScope {
    id: root

    property alias text: textInput.text
    property string placeholderText: ""
    property color placeholderColor: Colors.outline

    signal accepted()

    implicitHeight: 40

    // index 0 is circle — reserved as the settled state; cycle indices 1-34 for the burst shape
    property var shapeGetters: [
        MaterialShapeFn.getCircle,
        MaterialShapeFn.getSquare,
        MaterialShapeFn.getSlanted,
        MaterialShapeFn.getArch,
        MaterialShapeFn.getFan,
        MaterialShapeFn.getArrow,
        MaterialShapeFn.getSemiCircle,
        MaterialShapeFn.getOval,
        MaterialShapeFn.getPill,
        MaterialShapeFn.getTriangle,
        MaterialShapeFn.getDiamond,
        MaterialShapeFn.getClamShell,
        MaterialShapeFn.getPentagon,
        MaterialShapeFn.getGem,
        MaterialShapeFn.getSunny,
        MaterialShapeFn.getVerySunny,
        MaterialShapeFn.getCookie4Sided,
        MaterialShapeFn.getCookie6Sided,
        MaterialShapeFn.getCookie7Sided,
        MaterialShapeFn.getCookie9Sided,
        MaterialShapeFn.getCookie12Sided,
        MaterialShapeFn.getGhostish,
        MaterialShapeFn.getClover4Leaf,
        MaterialShapeFn.getClover8Leaf,
        MaterialShapeFn.getBurst,
        MaterialShapeFn.getSoftBurst,
        MaterialShapeFn.getBoom,
        MaterialShapeFn.getSoftBoom,
        MaterialShapeFn.getFlower,
        MaterialShapeFn.getPuffy,
        MaterialShapeFn.getPuffyDiamond,
        MaterialShapeFn.getPixelCircle,
        MaterialShapeFn.getPixelTriangle,
        MaterialShapeFn.getBun,
        MaterialShapeFn.getHeart
    ]

    ListModel { id: shapesModel }

    TextInput {
        id: textInput
        anchors.fill: parent
        color: "transparent"
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhSensitiveData
        font.pixelSize: 20
        enabled: root.enabled
        focus: true
        cursorDelegate: Item {}

        property int trackedLength: 0

        onLengthChanged: {
            if (length > trackedLength) {
                for (let i = 0; i < length - trackedLength; i++) {
                    // cycle indices 1..N-1 so the burst shape is never a plain circle
                    const idx = (shapesModel.count % (root.shapeGetters.length - 1)) + 1
                    shapesModel.append({ shapeIndex: idx })
                }
            } else {
                for (let i = 0; i < trackedLength - length; i++)
                    if (shapesModel.count > 0)
                        shapesModel.remove(shapesModel.count - 1)
            }
            trackedLength = length
        }

        onAccepted: root.accepted()
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.placeholderText
        color: root.placeholderColor
        font.pixelSize: 20
        visible: textInput.length === 0
    }

    ListView {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 30
        orientation: Qt.Horizontal
        spacing: 5
        clip: false
        interactive: false
        model: shapesModel

        delegate: Item {
            width: 30
            height: 30

            MaterialShapes.ShapeCanvas {
                id: shapeCanvas
                anchors.centerIn: parent
                width: 30
                height: 30
                color: Colors.primary
                roundedPolygon: root.shapeGetters[model.shapeIndex]()

                Behavior on scale {
                    NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                }
            }

            Timer {
                interval: 100
                running: true
                repeat: false
                onTriggered: {
                    shapeCanvas.roundedPolygon = MaterialShapeFn.getCircle()
                    shapeCanvas.scale = 0.62
                }
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: shapesModel.count * 35
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 30
        radius: 1
        color: Colors.primary
        visible: textInput.activeFocus

        SequentialAnimation on opacity {
            running: textInput.activeFocus
            loops: Animation.Infinite
            NumberAnimation { to: 0; duration: 500; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutSine }
        }
    }
}
