import QtQuick
import QtQuick.Layouts
import qs.modules.utils

Rectangle {
    id: root

    // Marker so adjacent siblings can detect this as a card
    readonly property bool isCustomCard: true

    property int topRadius: 20
    property int bottomRadius: 20
    // Set to false to skip auto-detection and use explicit topRadius/bottomRadius
    property bool autoRadius: true

    // Children placed directly inside CustomCard go into the inner ColumnLayout
    default property alias content: _layout.data

    color: Colors.surfaceContainerHigh

    topLeftRadius:     topRadius
    topRightRadius:    topRadius
    bottomLeftRadius:  bottomRadius
    bottomRightRadius: bottomRadius

    Layout.fillWidth: true
    implicitHeight: _layout.implicitHeight + 28

    // Check only the immediately adjacent siblings.
    // - If the item directly above is also a CustomCard → flatten the top (radius 5)
    // - If the item directly below is also a CustomCard → flatten the bottom (radius 5)
    // This means cards with ANY non-card element between them stay fully rounded,
    // while truly consecutive CustomCards form a grouped stack automatically.
    Component.onCompleted: { if (autoRadius) Qt.callLater(_updateRadius) }

    function _updateRadius() {
        if (!parent) return
        const ch = parent.children
        let myIdx = -1
        for (let i = 0; i < ch.length; i++) {
            if (ch[i] === root) { myIdx = i; break }
        }
        if (myIdx < 0) return

        const prevIsCard = myIdx > 0 && ch[myIdx - 1].isCustomCard === true && ch[myIdx - 1].visible
        const nextIsCard = myIdx < ch.length - 1 && ch[myIdx + 1].isCustomCard === true && ch[myIdx + 1].visible

        root.topRadius    = prevIsCard ? 5 : 20
        root.bottomRadius = nextIsCard ? 5 : 20
    }

    ColumnLayout {
        id: _layout
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14
    }
}
