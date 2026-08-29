import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.settings
import qs.modules.customComponents

// Rotating headline ticker. Shows three at a time and advances through the feed
// so a long list stays readable instead of being truncated.
WidgetHost {
    id: root
    configKey: "headlines"
    tile: WidgetSizes.wide
    defaultPos: Qt.point(620, 900)

    readonly property int pageSize: 3

    readonly property var sampleHeadlines: [
        { title: "Markets close higher as inflation eases for a third month" },
        { title: "Researchers map an ocean current that had gone unrecorded" },
        { title: "City transit plan adds two lines and a night service" },
        { title: "Long-running telescope survey releases its final catalogue" },
        { title: "New standard promises faster charging across devices" },
        { title: "Archive of early radio broadcasts goes online this week" }
    ]

    readonly property var items: root.preview ? root.sampleHeadlines : ServiceNews.headlines

    property int page: 0
    readonly property int pageCount: Math.max(1, Math.ceil(items.length / pageSize))

    readonly property var visibleItems: {
        if (items.length === 0) return []
        const start = (page % pageCount) * pageSize
        return items.slice(start, start + pageSize)
    }

    // Previews must never start the fetch loop
    Component.onCompleted: if (!root.preview) ServiceNews.retain()
    Component.onDestruction: if (!root.preview) ServiceNews.release()

    onItemsChanged: root.page = 0

    Timer {
        interval: 15000
        repeat: true
        running: !root.preview && root.pageCount > 1
        onTriggered: root.page = (root.page + 1) % root.pageCount
    }

    Rectangle {
        anchors.fill: parent
        radius: WidgetSizes.radius
        color: Colors.surface

        // ── Header ────────────────────────────────────────────────────
        RowLayout {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 7

            MaterialIconSymbol { content: "newspaper"; iconSize: 15; customColor: Colors.primary }
            CustomText {
                Layout.fillWidth: true
                content: root.preview ? "World News"
                       : (ServiceNews.channelTitle.length > 0 ? ServiceNews.channelTitle : "Headlines")
                size: 13
                customColor: Colors.primary
            }

            Loader {
                active: !root.preview && ServiceNews.isLoading
                visible: active
                sourceComponent: CustomCircularLoader {
                    size: 14; trackWidth: 2
                    waveAmplitude: 0
                    highlightColor: Colors.outline
                }
            }

            MaterialIconSymbol {
                visible: !root.preview && !ServiceNews.isLoading
                content: "refresh"
                iconSize: 15
                customColor: Colors.outline
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ServiceNews.refresh()
                }
            }
        }

        // ── Headlines ─────────────────────────────────────────────────
        ColumnLayout {
            id: list
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 10
            spacing: 9

            opacity: 1
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

            Repeater {
                model: root.visibleItems

                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 9

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 5
                        implicitWidth: 5; implicitHeight: 5
                        radius: 2.5
                        color: Colors.primary
                    }

                    CustomText {
                        Layout.fillWidth: true
                        content: modelData.title
                        size: 12
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // ── Empty / error state ───────────────────────────────────────
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6
            visible: root.items.length === 0

            MaterialIconSymbol {
                Layout.alignment: Qt.AlignHCenter
                content: ServiceNews.hasError ? "cloud_off" : "hourglass_empty"
                iconSize: 20
                customColor: Colors.outline
            }
            CustomText {
                Layout.alignment: Qt.AlignHCenter
                content: ServiceNews.hasError ? "Couldn't load feed" : "Loading headlines…"
                size: 12
                customColor: Colors.outline
            }
        }

        // ── Page dots ─────────────────────────────────────────────────
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            spacing: 5
            visible: root.pageCount > 1

            Repeater {
                model: root.pageCount
                delegate: Rectangle {
                    required property int index
                    implicitWidth: index === (root.page % root.pageCount) ? 14 : 5
                    implicitHeight: 5
                    radius: 2.5
                    color: index === (root.page % root.pageCount) ? Colors.primary
                                                                  : Colors.surfaceContainerHighest
                    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
