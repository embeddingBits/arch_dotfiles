pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.modules.utils
import qs.modules.services

// Emoji results as a grid — a list would waste the panel's width on 1500
// single-glyph rows. Column count is derived from the panel width so this
// still works if the launcher is ever widened.
GridView {
    id: view

    width: parent.width
    height: parent.height
    clip: true

    property int activeIndex: 0
    readonly property int columns: Math.max(4, Math.floor(width / 58))

    cellWidth: Math.floor(width / columns)
    cellHeight: cellWidth

    signal activated()

    model: ScriptModel { values: ServiceLauncher.results }

    delegate: Item {
        id: cell
        required property int index
        required property var modelData

        width: view.cellWidth
        height: view.cellHeight

        readonly property bool isActive: view.activeIndex === cell.index

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 6
            height: parent.height - 6
            radius: 14

            color: cell.isActive
                ? Colors.primaryContainer
                : cellArea.containsMouse ? Qt.alpha(Colors.primary, 0.1) : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }

            scale: cell.isActive ? 1.06 : 1
            Behavior on scale {
                NumberAnimation { duration: 140; easing.type: Easing.OutBack }
            }

            // Deliberately not CustomText — that forces the themed UI font
            // (no emoji coverage) and NativeRendering, which drops the colour
            // layers of a CBDT/COLR font. Default rendering keeps them.
            Text {
                anchors.centerIn: parent
                text: cell.modelData.glyph ?? ""
                font.family: "Noto Color Emoji"
                font.pixelSize: Math.round(view.cellWidth * 0.5)
            }
        }

        MouseArea {
            id: cellArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: view.activeIndex = cell.index
            onClicked: view.activateIndex(cell.index)
        }
    }

    function activateIndex(i) {
        const r = ServiceLauncher.results[i]
        if (ServiceLauncher.activate(r)) view.activated()
    }

    // Name of whatever is selected — shown by AppLauncherContent's footer,
    // since the cells themselves have no room for a label.
    readonly property string activeName: {
        const r = ServiceLauncher.results[activeIndex]
        return r ? r.subtitle : ""
    }
}
