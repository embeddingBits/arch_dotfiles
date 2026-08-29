import QtQuick
import "../MatrialShapes/" as MaterialShapes
import "../MatrialShapes/material-shapes.js" as MaterialShapesFn

Item {
    id: root

    property color color: "#6750A4"
    property real size: 60
    property bool running: true

    width: size
    height: size

    property int  _shapeIdx:      0
    property real _rotation:      0
    property real _rotationBase:  0

    property var _shapes: [
        MaterialShapesFn.getCookie12Sided,
        MaterialShapesFn.getSlanted,
        MaterialShapesFn.getCircle,
        MaterialShapesFn.getCookie4Sided,
        MaterialShapesFn.getGem,
        MaterialShapesFn.getPill,
    ]

    SequentialAnimation {
        loops: Animation.Infinite
        running: root.running

        // Advance shape first — ShapeCanvas auto-morphs via its Behavior on progress
        ScriptAction {
            script: root._shapeIdx = (root._shapeIdx + 1) % root._shapes.length
        }

        // Rotate while the morph plays out
        NumberAnimation {
            target: root; property: "_rotation"
            to: root._rotationBase + 180
            duration: 700; easing.type: Easing.OutExpo
        }

        ScriptAction {
            script: root._rotationBase += 180
        }

        PauseAnimation { duration: 100 }
    }

    MaterialShapes.ShapeCanvas {
        anchors.centerIn: parent
        width: root.size
        height: root.size
        color: root.color
        rotation: root._rotation
        roundedPolygon: root._shapes[root._shapeIdx]()
    }
}
