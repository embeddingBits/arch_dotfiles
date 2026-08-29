import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.settings
import qs.modules.customComponents

// Expanded panel for `barCenter: "both"` — the calendar keeps its established
// square, and the player takes whatever is left as a column.
//
// Calander anchors.fill's its parent, so it goes in a sized wrapper rather than
// straight into the RowLayout.
RowLayout {
    id: root
    anchors.fill: parent
    spacing: 0

    Item {
        Layout.preferredWidth: Appearance.size.calanderWidth
        Layout.fillHeight: true

        Calander { anchors.fill: parent }
    }

    Rectangle {
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        Layout.topMargin: 22
        Layout.bottomMargin: 22
        color: Colors.outlineVariant
        opacity: 0.6
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        BarMusicColumn { anchors.fill: parent }
    }
}
