import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents
import qs.modules.services
import qs.modules.settings
import qs.modules.components.Bar
import "../../../MatrialShapes/" as MaterialShapes
import "../../../MatrialShapes/material-shapes.js" as MatrialShapeFn

Rectangle {
    id: root
    property bool compact: false

    readonly property int pad: root.compact ? 8 : 10
    readonly property int headerHeight: 26
    readonly property int footerHeight: 34
    readonly property bool isEmpty: ServiceNotification.groupedNotifications.length === 0
    readonly property real naturalListHeight: root.isEmpty ? 110 : (root.compact ? 300 : 420)

    implicitHeight: root.headerHeight + root.naturalListHeight + root.footerHeight + 12

    color: "transparent"
    clip: true

    component ActionPill: Rectangle {
        id: pill
        property string icon: ""
        property string label: ""
        property bool active: false
        signal triggered

        implicitHeight: 32
        implicitWidth: pill.label === "" ? 32 : pillRow.implicitWidth + 28
        radius: 16
        color: pill.active ? Colors.primary : Colors.surfaceContainerHigh
        Behavior on color {
            EffectsColorAnim {}
        }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 5

            MaterialIconSymbol {
                visible: pill.icon !== ""
                content: pill.icon
                iconSize: 15
                customColor: pill.active ? Colors.primaryText : Colors.surfaceVariantText
                Behavior on customColor {
                    EffectsColorAnim {}
                }
            }

            CustomText {
                visible: pill.label !== ""
                content: pill.label
                size: 12
                weight: 600
                customColor: pill.active ? Colors.primaryText : Colors.surfaceVariantText
            }
        }

        RippleEffect {
            anchors.fill: parent
            radius: parent.radius
            hoverColor: Qt.alpha(pill.active ? Colors.primaryText : Colors.primary, 0.10)
            rippleColor: Qt.alpha(pill.active ? Colors.primaryText : Colors.primary, 0.22)
            onClicked: pill.triggered()
        }
    }

    RowLayout {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.headerHeight
        spacing: 6

        MaterialIconSymbol {
            content: ServiceNotification.muted ? "notifications_off" : "notifications"
            iconSize: 17
            customColor: Colors.primary
        }

        CustomText {
            content: "Notifications"
            size: 14
            weight: 700
        }

        Rectangle {
            visible: ServiceNotification.allNotifications.length > 0
            implicitWidth: Math.max(dashCount.implicitWidth + 10, 20)
            implicitHeight: 18
            radius: 9
            color: Qt.alpha(Colors.primary, 0.15)

            CustomText {
                id: dashCount
                anchors.centerIn: parent
                content: ServiceNotification.allNotifications.length.toString()
                size: 11
                weight: 700
                customColor: Colors.primary
            }
        }

        Item { Layout.fillWidth: true }
    }

    RowLayout {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.footerHeight
        spacing: 8

        ActionPill {
            icon: "notifications_off"
            active: ServiceNotification.muted
            onTriggered: ServiceNotification.toggleMute()
        }

        ActionPill {
            Layout.fillWidth: true
            visible: ServiceNotification.allNotifications.length > 0
            label: "Clear all"
            onTriggered: ServiceNotification.clear()
        }

        Item {
            Layout.fillWidth: true
            visible: ServiceNotification.allNotifications.length === 0
        }
    }

    Item {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: footer.top
        anchors.topMargin: 6
        anchors.bottomMargin: 6

        Loader {
            id: emptyLoader
            anchors.fill: parent
            active: root.isEmpty
            visible: active
            sourceComponent: Item {
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    MaterialShapes.ShapeCanvas {
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredHeight: 54
                        Layout.preferredWidth: 54
                        roundedPolygon: MatrialShapeFn.getSunny()
                        color: Colors.surfaceContainerHigh

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: ServiceNotification.muted ? "notifications_off" : "emoji_events"
                            iconSize: 20
                            customColor: Colors.primary
                        }
                    }

                    CustomText {
                        Layout.alignment: Qt.AlignCenter
                        content: ServiceNotification.muted ? "Do Not Disturb on" : "You're all caught up!"
                        size: 12
                        weight: 500
                        customColor: Colors.outline
                    }
                }
            }
        }

        Loader {
            id: notifLoader
            anchors.fill: parent
            active: !root.isEmpty
            visible: active
            sourceComponent: NotificationList {}
        }
    }
}
