import Quickshell
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents


Item{
    id: root
    property real progress: 0.0
    property real thickness: 2
    property real radius: Math.min(width, height) / 2 - thickness
    property string baseColor: Colors.surfaceContainerHigh
    property string lineColor: Colors.primary
    property bool showText: true
    Canvas{
        id: canvas
        anchors.fill: parent
        
        antialiasing: true

        readonly property real centerX: width / 2
        readonly property real centerY: height / 2
        readonly property real startAngle: -Math.PI / 2
        readonly property real endAngle: startAngle + (2 * Math.PI * root.progress)
        
        onEndAngleChanged: requestPaint()

        onPaint:{
            const ctx = getContext("2d")
            ctx.reset();

            ctx.lineWidth = root.thickness;
            ctx.lineCap = "round"

            const radius = root.radius
            const cx = centerX;
            const cy = centerY;

            ctx.beginPath();
            ctx.arc(cx, cy, radius, 0, 2 * Math.PI, false)
            ctx.strokeStyle = root.baseColor
            ctx.stroke();

            if(root.progress > 0){
                ctx.beginPath();
                ctx.arc(cx, cy, radius, startAngle, endAngle, false);
                ctx.strokeStyle = root.lineColor
                ctx.stroke();
            }
        }
        RowLayout{
            anchors.centerIn: parent
            visible: root.showText
            CustomText{
                content: Math.floor(root.progress * 100)
                size: 24
            }
            CustomText{
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 5
                content: "%"
                size: 13
                color: Colors.outline
            }
        }
    }
}

