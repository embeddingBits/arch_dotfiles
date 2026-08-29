pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

// List view over ServiceLauncher.results — used by calc, run and windows.
// Emoji gets its own grid instead. Mirrors ListApps' selection and hover
// behaviour so keyboard handling in AppLauncherContent stays uniform.
ListView {
    id: view

    width: parent.width
    height: parent.height
    spacing: 3
    clip: true

    property int activeIndex: 0

    model: ScriptModel { values: ServiceLauncher.results }

    // Calc results are big and singular; everything else is a normal row.
    readonly property bool isCalc: ServiceLauncher.mode === "calc"

    delegate: Rectangle {
        id: item
        required property int index
        required property var modelData

        implicitWidth: view.width
        implicitHeight: view.isCalc ? 84 : 58
        radius: 16

        readonly property bool isActive: view.activeIndex === item.index

        color: item.isActive
            ? Colors.primaryContainer
            : rowArea.containsMouse ? Qt.alpha(Colors.primary, 0.08) : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 12

            // Leading icon — a window's own app icon when we have one,
            // otherwise the mode's material symbol.
            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                radius: 13
                color: item.isActive
                    ? Qt.alpha(Colors.primary, 0.25)
                    : Qt.alpha(Colors.surfaceText, 0.06)
                Behavior on color { ColorAnimation { duration: 100 } }

                Image {
                    anchors.centerIn: parent
                    width: 26; height: 26
                    sourceSize.width: 26
                    sourceSize.height: 26
                    source: (item.modelData.iconName ?? "").length > 0
                        ? IconUtil.getIconPath(item.modelData.iconName)
                        : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: item.modelData.symbol ?? ""
                    iconSize: 20
                    customColor: item.isActive ? Colors.primaryContainerText : Colors.primary
                    visible: (item.modelData.iconName ?? "").length === 0
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                CustomText {
                    Layout.fillWidth: true
                    content: item.modelData.title ?? ""
                    size: view.isCalc ? 26 : 15
                    weight: view.isCalc ? 800 : 600
                    customColor: item.isActive ? Colors.primaryContainerText : Colors.surfaceText
                    elide: Text.ElideRight
                }

                CustomText {
                    Layout.fillWidth: true
                    content: item.modelData.subtitle ?? ""
                    size: 12
                    customColor: item.isActive
                        ? Qt.alpha(Colors.primaryContainerText, 0.65)
                        : Colors.outline
                    elide: Text.ElideRight
                    visible: (item.modelData.subtitle ?? "").length > 0
                }
            }

            // Affordance for what Enter will do
            CustomText {
                content: item.modelData.action === "copy" ? "copy"
                    : item.modelData.action === "focus" ? "focus" : "run"
                size: 10; weight: 700
                customColor: item.isActive
                    ? Qt.alpha(Colors.primaryContainerText, 0.7)
                    : Colors.outline
                visible: item.isActive
            }
        }

        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: view.activeIndex = item.index
            onClicked: view.activateIndex(item.index)
        }
    }

    function activateIndex(i) {
        const r = ServiceLauncher.results[i]
        if (ServiceLauncher.activate(r)) view.activated()
    }

    signal activated()
}
