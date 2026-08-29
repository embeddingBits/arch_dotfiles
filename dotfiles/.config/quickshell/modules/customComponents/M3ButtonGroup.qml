import QtQuick
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

// M3 Connected Button Group.
// Spec: BetweenSpace 2dp, inner corners CornerValueSmall (8dp), CornerValueExtraSmall
// (4dp) while pressed, and 50% (fully round) on the selected segment. Outer corners
// stay CornerFull. Pressing a segment expands it by ExpandedRatio (0.15) and
// compresses its neighbours.
//
// model:       array of { value, label?, icon? }
// activeCheck: function(value) => bool
// signal segmentClicked(value)
Item {
    id: root

    property var model: []
    property var activeCheck: function(value) { return false }
    signal segmentClicked(var value)

    property bool reorderable: false
    signal segmentMoved(int from, int to)

    property int dragIndex: -1
    property int dropIndex: -1

    property color activeColor: Colors.primary
    property color activeTextColor: Colors.primaryText
    property color inactiveColor: Colors.surfaceContainerHighest
    property color inactiveTextColor: Colors.surfaceText

    property bool fillWidth: false
    property int iconSize: 14
    property int textSize: 11

    readonly property real fullRadius: height / 2
    readonly property real innerRadius: 8
    readonly property real pressedInnerRadius: 4
    readonly property real gap: 2
    readonly property real expandedRatio: 0.15

    property int pressedIndex: -1

    height: 30
    implicitWidth: fillWidth ? root.width : _row.implicitWidth

    Row {
        id: _row
        height: parent.height
        width: root.fillWidth ? root.width : implicitWidth
        spacing: root.gap

        Repeater {
            model: root.model

            delegate: Item {
                id: seg
                required property var modelData
                required property int index

                readonly property bool active: root.activeCheck(modelData.value)
                readonly property bool isFirst: index === 0
                readonly property bool isLast: index === root.model.length - 1
                readonly property bool hasIcon: !!modelData.icon
                readonly property bool hasLabel: !!modelData.label
                readonly property bool isPressed: root.pressedIndex === index
                readonly property bool isDragged: root.dragIndex === index
                readonly property bool isDropTarget: root.reorderable
                    && root.dropIndex === index && root.dragIndex !== index
                readonly property bool isNeighbour:
                    root.pressedIndex >= 0 && Math.abs(root.pressedIndex - index) === 1

                height: root.height
                z: seg.isDragged ? 2 : 1

                property real dragShift: 0
                transform: Translate { x: seg.dragShift }

                readonly property real contentWidth:
                    (seg.hasIcon ? _icon.implicitWidth : 0)
                    + (seg.hasIcon && seg.hasLabel ? _content.spacing : 0)
                    + (seg.hasLabel ? _label.implicitWidth : 0)

                readonly property real baseWidth: root.fillWidth
                    ? (root.width - (root.model.length - 1) * root.gap)
                      / Math.max(root.model.length, 1)
                    : seg.contentWidth + 22

                // Pressed segment grows by expandedRatio; neighbours give the room back.
                readonly property real _grow: seg.baseWidth * root.expandedRatio
                readonly property int  _neighbours:
                    root.pressedIndex < 0 ? 0
                    : ((root.pressedIndex > 0 ? 1 : 0)
                       + (root.pressedIndex < root.model.length - 1 ? 1 : 0))

                implicitWidth: seg.baseWidth
                width: {
                    if (seg.isPressed) return seg.baseWidth + seg._grow
                    if (seg.isNeighbour && seg._neighbours > 0)
                        return Math.max(seg.baseWidth * 0.5,
                                        seg.baseWidth - seg._grow / seg._neighbours)
                    return seg.baseWidth
                }
                Behavior on width {
                    NumberAnimation {
                        duration: M3Motion.spatial.fastDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3Motion.spatial.fastCurve
                    }
                }

                readonly property real _inner:
                    seg.active ? root.fullRadius
                    : seg.isPressed ? root.pressedInnerRadius
                    : root.innerRadius

                readonly property real tl: seg.isFirst ? root.fullRadius : seg._inner
                readonly property real bl: seg.isFirst ? root.fullRadius : seg._inner
                readonly property real tr: seg.isLast  ? root.fullRadius : seg._inner
                readonly property real br: seg.isLast  ? root.fullRadius : seg._inner

                Rectangle {
                    anchors.fill: parent
                    scale: seg.isDragged ? 1.05 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    color: seg.isDropTarget ? Qt.alpha(root.activeColor, 0.35)
                         : seg.active ? root.activeColor : root.inactiveColor
                    Behavior on color {
                        ColorAnimation { duration: M3Motion.effects.fastDuration }
                    }

                    topLeftRadius: seg.tl
                    bottomLeftRadius: seg.bl
                    topRightRadius: seg.tr
                    bottomRightRadius: seg.br
                    Behavior on topLeftRadius     { NumberAnimation { duration: M3Motion.container.radiusDuration } }
                    Behavior on bottomLeftRadius  { NumberAnimation { duration: M3Motion.container.radiusDuration } }
                    Behavior on topRightRadius    { NumberAnimation { duration: M3Motion.container.radiusDuration } }
                    Behavior on bottomRightRadius { NumberAnimation { duration: M3Motion.container.radiusDuration } }
                }

                Item {
                    id: _box
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    clip: true

                    Row {
                        id: _content
                        anchors.centerIn: parent
                        spacing: 5

                        MaterialIconSymbol {
                            id: _icon
                            visible: seg.hasIcon
                            anchors.verticalCenter: parent.verticalCenter
                            content: seg.modelData.icon ?? ""
                            iconSize: root.iconSize
                            fill: seg.active ? 1 : 0
                            Behavior on fill {
                                NumberAnimation { duration: M3Motion.effects.defaultDuration }
                            }
                            customColor: seg.active ? root.activeTextColor
                                                    : root.inactiveTextColor
                        }

                        CustomText {
                            id: _label
                            visible: seg.hasLabel
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(0, Math.min(implicitWidth,
                                _box.width - (seg.hasIcon
                                    ? _icon.implicitWidth + _content.spacing : 0)))
                            content: seg.modelData.label ?? ""
                            size: root.textSize
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            customColor: seg.active ? root.activeTextColor
                                                    : root.inactiveTextColor
                        }
                    }
                }

                RippleEffect {
                    anchors.fill: parent
                    topLeftRadius: seg.tl
                    bottomLeftRadius: seg.bl
                    topRightRadius: seg.tr
                    bottomRightRadius: seg.br
                    hoverColor: Qt.alpha(seg.active ? root.activeTextColor
                                                    : Colors.primary, 0.08)
                    rippleColor: Qt.alpha(seg.active ? root.activeTextColor
                                                     : Colors.primary, 0.25)
                    onPressedChanged: root.pressedIndex = pressed ? seg.index : -1
                    onClicked: if (!root.reorderable) root.segmentClicked(seg.modelData.value)
                }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    enabled: root.reorderable
                    visible: root.reorderable
                    hoverEnabled: false
                    cursorShape: Qt.PointingHandCursor

                    property real pressX: 0
                    property bool moved: false

                    onPressed: mouse => {
                        dragArea.pressX = mouse.x
                        dragArea.moved = false
                        root.dragIndex = seg.index
                        root.dropIndex = seg.index
                        root.pressedIndex = seg.index
                    }

                    onPositionChanged: mouse => {
                        if (root.dragIndex !== seg.index) return
                        const dx = mouse.x - dragArea.pressX
                        if (Math.abs(dx) > 3) dragArea.moved = true
                        seg.dragShift = dx

                        const p = dragArea.mapToItem(_row, mouse.x, seg.height / 2)
                        const over = _row.childAt(p.x, seg.height / 2)
                        if (over && over.index !== undefined)
                            root.dropIndex = over.index
                    }

                    onReleased: {
                        const from = seg.index
                        const to = root.dropIndex
                        seg.dragShift = 0
                        root.dragIndex = -1
                        root.dropIndex = -1
                        root.pressedIndex = -1

                        if (dragArea.moved && to >= 0 && to !== from)
                            root.segmentMoved(from, to)
                        else if (!dragArea.moved)
                            root.segmentClicked(seg.modelData.value)
                    }

                    onCanceled: {
                        seg.dragShift = 0
                        root.dragIndex = -1
                        root.dropIndex = -1
                        root.pressedIndex = -1
                    }
                }
            }
        }
    }
}
