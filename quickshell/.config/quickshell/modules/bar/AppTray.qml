import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../../config/Theme.qml" as Theme

RowLayout {
    id: root

    required property var niriService

    visible: niriService.filteredRunningApps.length > 0
    spacing: 2

    Repeater {
        model: root.niriService.filteredRunningApps

        delegate: Item {
            required property var modelData
            property string appId: String(modelData.appId || "")
            property bool isFocused: !!modelData.isFocused
            property var appWindows: modelData.windows || []
            property string combinedTitle: {
                let t = modelData.titles || [];
                if (t.length === 0)
                    return "";
                return t.slice(0, 3).join("\n");
            }

            Layout.preferredWidth: 28
            Layout.preferredHeight: 26

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: appMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : isFocused ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12) : "transparent"
            }

            IconImage {
                id: appIcon
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                width: 18
                height: 18
                source: root.niriService.appIconName(appId)
                asynchronous: true
            }

            Text {
                visible: appIcon.source === "" || appIcon.status === Image.Error || appIcon.status === Image.Null
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: appId.length > 0 ? appId.charAt(0).toUpperCase() : "?"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.barFontSize
                font.weight: 700
                color: isFocused ? Theme.accent : Theme.fg
            }

            Rectangle {
                visible: modelData.count > 1
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 1
                anchors.topMargin: 2
                width: countBadgeText.implicitWidth + 6
                height: 10
                radius: 5
                color: Theme.accent

                Text {
                    id: countBadgeText
                    anchors.centerIn: parent
                    text: String(modelData.count)
                    font.family: Theme.fontFamily
                    font.pixelSize: 7
                    font.weight: 700
                    color: Theme.bg
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: isFocused ? 2.5 : 2
                radius: 1
                color: isFocused ? Theme.underlineApps : Qt.rgba(Theme.underlineApps.r, Theme.underlineApps.g, Theme.underlineApps.b, 0.45)
                opacity: appMouse.containsMouse || isFocused ? 1 : 0.8
            }

            MouseArea {
                id: appMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: function (mouse) {
                    if (mouse.button === Qt.MiddleButton) {
                        root.niriService.closeGroupedApp(modelData, false);
                        return;
                    }
                    if (mouse.button === Qt.RightButton) {
                        if (appWindows.length > 1) {
                            let curIdx = -1;
                            for (let i = 0; i < appWindows.length; i++)
                                if (appWindows[i].is_focused)
                                    curIdx = i;
                            if (curIdx !== -1) {
                                let nextIdx = (curIdx + 1) % appWindows.length;
                                let nid = appWindows[nextIdx].id;
                                if (nid !== undefined)
                                    Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(nid)]);
                            } else {
                                root.niriService.focusGroupedApp(modelData);
                            }
                        } else {
                            root.niriService.focusGroupedApp(modelData);
                        }
                        return;
                    }
                    root.niriService.focusGroupedApp(modelData);
                }
            }

            ToolTip {
                visible: appMouse.containsMouse
                delay: 400
                text: appId + (combinedTitle ? "\n" + combinedTitle : "") + (modelData.count > 1 ? "  (" + modelData.count + " windows)" : "")
                contentItem: Text {
                    text: appMouse.containsMouse ? (appId + (combinedTitle ? "\n" + combinedTitle : "") + (modelData.count > 1 ? "  (" + modelData.count + " windows)" : "")) : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.fg
                    wrapMode: Text.Wrap
                }
                background: Rectangle {
                    color: Theme.bg
                    border.color: Theme.border
                    border.width: 1
                    radius: 4
                }
            }
        }
    }

    Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 16
        color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.35)
        visible: root.niriService.filteredRunningApps.length > 0
    }
}
