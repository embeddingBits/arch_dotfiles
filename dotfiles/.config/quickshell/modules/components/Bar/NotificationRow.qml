import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents
import qs.modules.services

Item {
    id: row

    property var notifData: null
    property bool showIcon: true
    property bool reserveIconColumn: false
    property bool showAppName: true
    property bool isExtended: false
    property bool interactive: true

    readonly property bool hasActions: (row.notifData?.actions?.length ?? 0) > 0
    readonly property bool hasBody: (row.notifData?.body ?? "").length > 0
    readonly property bool hasImage: !!row.notifData?.image

    property string relativeTime: row.computeRelative(row.notifData?.arrivalTimestamp ?? Date.now())

    function computeRelative(ts) {
        var diff = Date.now() - ts
        var mins = Math.floor(diff / 60000)
        if (mins < 1)  return "now"
        if (mins < 60) return mins + "m"
        var hrs = Math.floor(mins / 60)
        if (hrs < 24)  return hrs + "h"
        return Math.floor(hrs / 24) + "d"
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: row.relativeTime = row.computeRelative(row.notifData?.arrivalTimestamp ?? Date.now())
    }

    function resolveSymbol(appIcon, appName) {
        const ic = (appIcon || "").toLowerCase()
        const ap = (appName || "").toLowerCase()
        if (ic.includes("camera-photo") || ap.includes("screenshot")) return "photo_camera"
        if (ic.includes("camera-video") || ap.includes("record"))     return "screen_record"
        if (ic.includes("dialog-error") || ic.includes("error"))      return "error_outline"
        if (ic.includes("bluetooth"))                                  return "bluetooth"
        if (ic.includes("network") || ic.includes("wifi"))            return "wifi"
        if (ic.includes("battery"))                                    return "battery_std"
        if (ic.includes("volume") || ic.includes("audio"))            return "volume_up"
        return ""
    }

    readonly property string symbol: row.resolveSymbol(row.notifData?.appIcon, row.notifData?.appName)
    readonly property bool usesSymbol: row.symbol !== ""

    readonly property bool headerShowsAppName: row.isExtended && row.showAppName

    implicitHeight: col.implicitHeight
    Behavior on implicitHeight {
        NumberAnimation {
            duration: M3Motion.container.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: M3Motion.container.curve
        }
    }

    Item {
        id: swipe
        y: 0
        width: row.width
        height: row.height
        clip: true

        MouseArea {
            id: swipeArea
            anchors.fill: parent
            enabled: row.interactive
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            drag.target: swipe
            drag.axis: Drag.XAxis

            onPressed: event => {
                if (event.button === Qt.MiddleButton)
                    ServiceNotification.removeNotification(row.notifData)
            }
            onReleased: {
                if (Math.abs(swipe.x) < row.width * 0.35)
                    swipe.x = 0
                else
                    ServiceNotification.removeNotification(row.notifData)
            }
            onClicked: event => {
                if (event.button === Qt.LeftButton && Math.abs(swipe.x) < 4)
                    row.isExtended = !row.isExtended
            }
        }

        Behavior on x {
            enabled: !swipeArea.drag.active
            SpringAnimation {
                spring: Appearance.motion.swipeSpring
                damping: Appearance.motion.swipeDamping
                mass: Appearance.motion.swipeMass
                epsilon: 0.4
            }
        }

        opacity: 1 - Math.min(1, Math.abs(swipe.x) / (row.width || 1))

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    visible: row.showIcon || row.reserveIconColumn
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignTop

                    Rectangle {
                        anchors.fill: parent
                        visible: row.showIcon
                        radius: 18
                        color: row.usesSymbol ? Colors.primaryContainer
                                              : Qt.alpha(Colors.primary, 0.12)

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: row.symbol
                            iconSize: 19
                            customColor: Colors.primaryContainerText
                            visible: row.usesSymbol
                        }

                        Image {
                            id: appIconImage
                            anchors.fill: parent
                            anchors.margins: 6
                            source: row.usesSymbol ? "" : IconUtil.getIconPath(row.notifData?.appIcon ?? "")
                            sourceSize: Qt.size(24, 24)
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                            visible: !row.usesSymbol && status === Image.Ready
                        }

                        MaterialIconSymbol {
                            anchors.centerIn: parent
                            content: "notifications"
                            iconSize: 17
                            customColor: Colors.primaryContainerText
                            visible: !row.usesSymbol && appIconImage.status !== Image.Ready
                        }
                    }

                    Loader {
                        anchors.fill: parent
                        active: !row.showIcon && row.hasImage
                        visible: active

                        sourceComponent: ClippingRectangle {
                            radius: 18
                            color: Colors.surfaceContainerHighest

                            Image {
                                anchors.fill: parent
                                source: row.notifData?.image ?? ""
                                sourceSize: Qt.size(36, 36)
                                asynchronous: true
                                fillMode: Image.PreserveAspectCrop
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        CustomText {
                            Layout.fillWidth: !row.headerShowsAppName
                            content: row.headerShowsAppName
                                ? (row.notifData?.appName ?? "")
                                : (row.notifData?.summary ?? "")
                            size: row.headerShowsAppName ? 11 : 13
                            weight: row.headerShowsAppName ? 500 : 700
                            customColor: row.headerShowsAppName ? Colors.outline : Colors.surfaceText
                            elide: Text.ElideRight
                        }

                        CustomText {
                            content: "·"
                            size: 11
                            customColor: Colors.outline
                        }

                        CustomText {
                            content: row.relativeTime
                            size: 11
                            customColor: Colors.outline
                        }

                        Item { Layout.fillWidth: row.headerShowsAppName }
                    }

                    CustomText {
                        Layout.fillWidth: true
                        visible: row.headerShowsAppName
                        content: row.notifData?.summary ?? ""
                        size: 13
                        weight: 700
                        wrapMode: Text.WordWrap
                    }

                    CustomText {
                        Layout.fillWidth: true
                        visible: row.hasBody
                        content: row.isExtended
                            ? (row.notifData?.body ?? "")
                            : (row.notifData?.body ?? "").replace(/\s+/g, " ")
                        size: 12
                        customColor: Colors.outline
                        wrapMode: row.isExtended ? Text.WordWrap : Text.NoWrap
                        elide: Text.ElideRight
                    }
                }

                Loader {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: row.isExtended ? Qt.AlignTop : Qt.AlignVCenter
                    active: row.hasImage && row.showIcon
                    visible: active

                    sourceComponent: ClippingRectangle {
                        radius: 10
                        color: Colors.surfaceContainerHighest

                        Image {
                            anchors.fill: parent
                            source: row.notifData?.image ?? ""
                            sourceSize: Qt.size(40, 40)
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                        }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: row.showIcon ? 6 : 0
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: Colors.surfaceContainerHighest

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: "keyboard_arrow_down"
                        iconSize: 16
                        customColor: Colors.surfaceVariantText
                        rotation: row.isExtended ? 180 : 0
                        Behavior on rotation {
                            NumberAnimation {
                                duration: M3Motion.container.duration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: M3Motion.container.curve
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.isExtended = !row.isExtended
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: (row.isExtended && row.hasActions) ? 34 : 0
                clip: true
                visible: row.hasActions

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: row.showIcon ? 46 : 0
                    spacing: 2
                    opacity: row.isExtended ? 1 : 0
                    Behavior on opacity { EffectsAnim {} }

                    Repeater {
                        model: row.notifData?.actions ?? []

                        delegate: Rectangle {
                            id: actionBtn
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 14
                            color: actionHover.containsMouse
                                ? Qt.alpha(Colors.primary, 0.12) : "transparent"
                            Behavior on color { EffectsColorAnim {} }

                            CustomText {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                content: actionBtn.modelData.text ?? ""
                                size: 12
                                weight: 600
                                customColor: Colors.primary
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                id: actionHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    actionBtn.modelData.invoke()
                                    ServiceNotification.removeNotification(row.notifData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
