import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

WidgetHost {
    id: root
    configKey: "dateWidget"
    defaultPos: Qt.point(300, 300)
    implicitWidth: row.implicitWidth + 32
    implicitHeight: 52

    // Single-line row — no background, no box
    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        // Day abbrev
        CustomText {
            content: ServiceClock.day.slice(0, 3).toUpperCase()
            size: 14
            weight: 700
            customColor: Colors.primary
            font.letterSpacing: 1
        }

        // Divider
        Rectangle {
            implicitWidth: 1; implicitHeight: 16; radius: 1
            color: Colors.outline; opacity: 0.4
            Layout.leftMargin: 10; Layout.rightMargin: 10
        }

        // Date number
        CustomText {
            content: ServiceClock.date
            size: 14
            weight: 700
            customColor: Colors.surfaceText
        }

        // Divider
        Rectangle {
            implicitWidth: 1; implicitHeight: 16; radius: 1
            color: Colors.outline; opacity: 0.4
            Layout.leftMargin: 10; Layout.rightMargin: 10
        }

        // Month
        CustomText {
            content: ServiceClock.month
            size: 14
            weight: 400
            customColor: Colors.outline
        }

        // Divider
        Rectangle {
            implicitWidth: 1; implicitHeight: 16; radius: 1
            color: Colors.outline; opacity: 0.4
            Layout.leftMargin: 10; Layout.rightMargin: 10
        }

        // Year
        CustomText {
            content: ServiceClock.year
            size: 14
            weight: 400
            customColor: Colors.outline
        }
    }

    // Bottom accent line — the only non-text visual element
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        radius: 1
        color: Colors.primary
        opacity: 0.5
    }
}
