import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Rectangle {
    id: container
    implicitWidth: parent.width
    color: Settings.layoutColor
    anchors.bottom: parent.bottom
    topRightRadius: 20
    topLeftRadius: 20
    signal closed

    property var filteredEntries: ServiceCliphist.filteredEntries

    Behavior on implicitHeight {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
    }

    Timer {
        id: timer
        interval: 300
        running: true
        onTriggered: col.visible = true
    }

    Component.onCompleted: searchInput.forceActiveFocus()

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8
        visible: false

        NumberAnimation on opacity { from: 0; to: 1; duration: 120; running: col.visible }
        NumberAnimation on scale   { from: 0.92; to: 1; duration: 180; easing.type: Easing.OutCubic; running: col.visible }

        // ── Search bar ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 16
            color: Colors.surfaceContainerHigh

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 10

                MaterialIconSymbol {
                    content: "search"
                    iconSize: 20
                    customColor: Colors.primary
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    CustomText {
                        anchors.verticalCenter: parent.verticalCenter
                        content: "Search clipboard…"
                        size: 15
                        customColor: Colors.outline
                        visible: searchInput.text.length === 0
                    }

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        font.pixelSize: 15
                        font.weight: 600
                        font.family: SettingsConfig.general.defaultFont ?? "Rubik"
                        color: Colors.surfaceText
                        focus: true

                        onTextChanged: ServiceCliphist.updateSearch(text)

                        onAccepted: {
                            const item = clipboardList.itemAtIndex(clipboardList.activeIndex)
                            if (item) {
                                container.closed()
                                ServiceCliphist.copy(item.modelData)
                            }
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down) {
                                if (clipboardList.activeIndex < clipboardList.count - 1) {
                                    clipboardList.activeIndex++
                                    clipboardList.positionViewAtIndex(clipboardList.activeIndex, ListView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                if (clipboardList.activeIndex > 0) {
                                    clipboardList.activeIndex--
                                    clipboardList.positionViewAtIndex(clipboardList.activeIndex, ListView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Delete) {
                                const item = clipboardList.itemAtIndex(clipboardList.activeIndex)
                                if (item) ServiceCliphist.deleteEntry(item.modelData)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                container.closed()
                            }
                        }
                    }
                }

                // Clear search
                Rectangle {
                    width: 28; height: 28; radius: 10
                    color: Colors.surfaceContainerHighest
                    visible: searchInput.text.length > 0

                    MaterialIconSymbol {
                        anchors.centerIn: parent
                        content: "close"; iconSize: 14
                        customColor: Colors.outline
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: searchInput.text = ""
                    }
                }
            }
        }

        // ── Stats + actions row ───────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 2
            spacing: 0

            MaterialIconSymbol { content: "notes"; iconSize: 14; customColor: Colors.outline }
            CustomText {
                Layout.leftMargin: 4
                content: ServiceCliphist.items + " items"
                size: 12
                customColor: Colors.outline
            }

            Item { Layout.fillWidth: true }

            // Refresh
            Rectangle {
                width: 32; height: 32; radius: 10
                color: refreshArea.containsMouse ? Colors.primaryContainer : Colors.surfaceContainerHigh
                Behavior on color { ColorAnimation { duration: 150 } }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "cached"; iconSize: 18
                    customColor: refreshArea.containsMouse ? Colors.primaryContainerText : Colors.outline
                }
                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: ServiceCliphist.refresh()
                }
                CustomToolTip { visible: refreshArea.containsMouse; content: "Refresh" }
            }

            Item { implicitWidth: 6 }

            // Clear all
            Rectangle {
                width: 32; height: 32; radius: 10
                color: clearArea.containsMouse ? Qt.alpha(Colors.error, 0.15) : Colors.surfaceContainerHigh
                Behavior on color { ColorAnimation { duration: 150 } }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "clear_all"; iconSize: 18
                    customColor: clearArea.containsMouse ? Colors.error : Colors.outline
                }
                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: ServiceCliphist.wipe()
                }
                CustomToolTip { visible: clearArea.containsMouse; content: "Clear all" }
            }
        }

        // ── Clipboard list ────────────────────────────────────────────────
        ClippingWrapperRectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: "transparent"

            ListView {
                id: clipboardList
                anchors.fill: parent
                spacing: 3
                clip: true
                property int activeIndex: 0
                property bool animationsEnabled: false

                model: ScriptModel {
                    values: container.filteredEntries
                    onValuesChanged: clipboardList.animationsEnabled = true
                }

                add: Transition {
                    enabled: clipboardList.animationsEnabled
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
                }

                delegate: Rectangle {
                    id: clipItem
                    required property var modelData
                    required property int index

                    readonly property bool isActive: clipboardList.activeIndex === index
                    readonly property bool hovered: itemMouse.containsMouse
                    readonly property bool isImage: ServiceCliphist.entryIsImage(modelData)

                    width: clipboardList.width
                    height: isImage ? 130 : 68
                    radius: 16

                    color: isActive
                        ? Colors.primaryContainer
                        : hovered ? Qt.alpha(Colors.primary, 0.08) : "transparent"

                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        // Type badge
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: 38; height: 38; radius: 12
                            color: clipItem.isActive
                                ? Qt.alpha(Colors.primary, 0.25)
                                : Qt.alpha(Colors.surfaceText, 0.06)
                            Behavior on color { ColorAnimation { duration: 100 } }

                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: clipItem.isImage ? "image" : "content_paste"
                                iconSize: 18
                                customColor: clipItem.isActive ? Colors.primaryContainerText : Colors.outline
                            }
                        }

                        // Content
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            CustomText {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                visible: !clipItem.isImage
                                content: ServiceCliphist.getEntryText(clipItem.modelData)
                                size: 13
                                customColor: clipItem.isActive ? Colors.primaryContainerText : Colors.surfaceText
                                elide: Text.ElideRight
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                maximumLineCount: 2
                            }

                            Loader {
                                anchors.fill: parent
                                active: clipItem.isImage
                                visible: active
                                sourceComponent: ClipboardImage { entry: clipItem.modelData }
                            }
                        }

                        // Delete button
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: 30; height: 30; radius: 10
                            color: delArea.containsMouse
                                ? Qt.alpha(Colors.error, 0.15)
                                : "transparent"
                            opacity: clipItem.hovered || clipItem.isActive ? 1 : 0
                            Behavior on color   { ColorAnimation  { duration: 120 } }
                            Behavior on opacity { NumberAnimation  { duration: 150 } }

                            MaterialIconSymbol {
                                anchors.centerIn: parent
                                content: "close"; iconSize: 16
                                customColor: delArea.containsMouse ? Colors.error
                                    : clipItem.isActive ? Colors.primaryContainerText : Colors.outline
                            }

                            MouseArea {
                                id: delArea
                                anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: ServiceCliphist.deleteEntry(clipItem.modelData)
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        anchors.rightMargin: 48
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: clipboardList.activeIndex = clipItem.index
                        onClicked: {
                            container.closed()
                            ServiceCliphist.copy(clipItem.modelData)
                        }
                    }

                    ListView.onRemove: clipItem.opacity = 0
                }
            }
        }
    }
}
