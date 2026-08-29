pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root

    property string detail: ""

    implicitHeight: 26

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            Layout.preferredWidth: chipRow.implicitWidth + 18
            Layout.preferredHeight: 24
            radius: 8
            color: Colors.primary

            RowLayout {
                id: chipRow
                anchors.centerIn: parent
                spacing: 5

                MaterialIconSymbol {
                    content: ServiceLauncher.activeMode?.icon ?? ""
                    iconSize: 13
                    customColor: Colors.primaryText
                }
                CustomText {
                    content: ServiceLauncher.activeMode?.label ?? ""
                    size: 11
                    weight: 800
                    customColor: Colors.primaryText
                }
            }
        }

        CustomText {
            Layout.fillWidth: true
            content: root.detail !== "" ? root.detail : (ServiceLauncher.activeMode?.hint ?? "")
            size: 11
            weight: 500
            customColor: Colors.outline
            elide: Text.ElideRight
        }
    }
}
