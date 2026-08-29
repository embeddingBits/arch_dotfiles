import QtQuick
import qs.modules.utils
import QtQuick.Effects 

Item {
    id: root
    clip: true
    property var background
    property var radius

    
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }
    
    // ShaderEffectSource {
    //     id: backgroundCapture
    //     anchors.fill: parent
    //     sourceItem: root.background
    //     sourceRect: Qt.rect(
    //         root.x, 
    //         root.y, 
    //         root.width, 
    //         root.height
    //     )
    //     visible: false
    // }
    
    // MultiEffect {
    //     anchors.fill: parent
    //     source: backgroundCapture
    //     
    //     blurEnabled: true
    //     blur: 1.0
    //     blurMax: 40
    //     autoPaddingEnabled: false
    //     
    //     maskEnabled: true
    //     maskSource: mask
    //     maskThresholdMin: 0.5
    //     maskSpreadAtMin: 0.1
    // }
    
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Qt.alpha(Colors.surface, 0.5)
        border.width: 1
        border.color: Qt.alpha(Colors.outline, 0.5)
    }
}
