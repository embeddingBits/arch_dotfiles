import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.services
import qs.modules.customComponents

// Right-click context menu for wallpaper tiles (local and online).
// Instantiate with anchors.fill on the grid container Item so position
// clamping uses the correct bounds.
//
// Usage:
//   WallpaperContextMenu { id: ctxMenu; anchors.fill: parent }
//   ctxMenu.show(mappedX, mappedY, itemData, isOnline)
Item {
    id: root

    property var  target:        null   // set to show, null to hide
    property bool online:        false
    property bool deleteConfirm: false
    property real preferredX:    0
    property real preferredY:    0

    function show(x, y, data, isOnline) {
        deleteConfirm = false
        online        = isOnline
        target        = data
        preferredX    = x
        preferredY    = y
    }

    function close() {
        target        = null
        deleteConfirm = false
    }

    // Click-away dismiss
    MouseArea {
        anchors.fill: parent
        z: 98
        visible: root.target !== null
        propagateComposedEvents: false
        onClicked: root.close()
        onPressed: root.close()
    }

    // ── Menu rectangle ─────────────────────────────────────────────────────
    Rectangle {
        id: menuRect
        z: 99
        x: Math.max(4, Math.min(root.preferredX, root.width  - width  - 4))
        y: Math.max(4, Math.min(root.preferredY, root.height - height - 4))

        width: 230
        height: menuCol.implicitHeight + 16
        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

        radius: 18
        color:  Colors.surfaceContainer
        visible: root.target !== null

        scale:   visible ? 1.0 : 0.88
        opacity: visible ? 1.0 : 0.0
        Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        ColumnLayout {
            id: menuCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
            spacing: 6

            // ── Header: thumbnail + name / resolution ──────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 60
                radius: 12
                color: Colors.surfaceContainerHigh

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        width: 44; height: 40; radius: 8; clip: true
                        color: Colors.surfaceContainerHighest
                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            source: {
                                if (!root.target) return ""
                                if (root.online)  return root.target.thumbUrl ?? ""
                                return "file://" + root.target
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        CustomText {
                            Layout.fillWidth: true
                            content: {
                                if (!root.target) return ""
                                if (root.online)  return root.target.id ?? ""
                                return ServiceWallpaper.getOriginalPath(root.target).split("/").pop()
                            }
                            size: 12; weight: 600
                            elide: Text.ElideRight
                        }

                        CustomText {
                            Layout.fillWidth: true
                            content: {
                                if (!root.target) return ""
                                if (root.online) {
                                    const sz = (root.target.fileSize / (1024 * 1024)).toFixed(1)
                                    return root.target.resolution + " · " + sz + " MB"
                                }
                                return ServiceWallpaper.getOriginalPath(root.target)
                            }
                            size: 10; customColor: Colors.outline
                            elide: Text.ElideLeft
                        }
                    }
                }
            }

            // ── Actions ────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: ctxActions.implicitHeight
                Behavior on implicitHeight { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
                radius: 12
                color:  Colors.surfaceContainerHigh
                clip:   true

                ColumnLayout {
                    id: ctxActions
                    anchors { left: parent.left; right: parent.right }
                    spacing: 0

                    // ── LOCAL ──────────────────────────────────────────────

                    Rectangle {
                        visible: !root.online
                        Layout.fillWidth: true; implicitHeight: 40; color: "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            MaterialIconSymbol { content: "wallpaper"; iconSize: 16; customColor: Colors.primary }
                            CustomText { Layout.fillWidth: true; content: "Set as Wallpaper"; size: 12 }
                        }
                        RippleEffect {
                            anchors.fill: parent; radius: 6
                            onClicked: { ServiceWallpaper.setWallpaper(root.target); root.close() }
                        }
                    }

                    Rectangle { visible: !root.online; Layout.fillWidth: true; implicitHeight: 1; color: Colors.surfaceContainerHighest }

                    Rectangle {
                        id: favRow
                        visible: !root.online
                        Layout.fillWidth: true; implicitHeight: 40; color: "transparent"
                        readonly property bool faved: root.target && !root.online
                            ? ServiceWallpaper.isFavorite(root.target) : false
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            MaterialIconSymbol {
                                content: favRow.faved ? "favorite" : "favorite_border"
                                iconSize: 16; fill: favRow.faved ? 1 : 0
                                customColor: favRow.faved ? Colors.error : Colors.outline
                            }
                            CustomText {
                                Layout.fillWidth: true
                                content: favRow.faved ? "Remove from Favorites" : "Add to Favorites"
                                size: 12
                            }
                        }
                        RippleEffect {
                            anchors.fill: parent; radius: 6
                            onClicked: { ServiceWallpaper.toggleFavorite(root.target); root.close() }
                        }
                    }

                    Rectangle { visible: !root.online; Layout.fillWidth: true; implicitHeight: 1; color: Colors.surfaceContainerHighest }

                    Rectangle {
                        visible: !root.online
                        Layout.fillWidth: true; implicitHeight: 40; color: "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            MaterialIconSymbol { content: "content_copy"; iconSize: 16; customColor: Colors.outline }
                            CustomText { Layout.fillWidth: true; content: "Copy Path"; size: 12 }
                        }
                        RippleEffect {
                            anchors.fill: parent; radius: 6
                            onClicked: {
                                Quickshell.clipboardText = ServiceWallpaper.getOriginalPath(root.target)
                                root.close()
                            }
                        }
                    }

                    // Delete — normal state
                    Rectangle { visible: !root.online && !root.deleteConfirm; Layout.fillWidth: true; implicitHeight: 1; color: Colors.surfaceContainerHighest }

                    Rectangle {
                        visible: !root.online && !root.deleteConfirm
                        Layout.fillWidth: true; implicitHeight: 40; color: "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            MaterialIconSymbol { content: "delete"; iconSize: 16; customColor: Colors.error }
                            CustomText { Layout.fillWidth: true; content: "Delete File"; size: 12; customColor: Colors.error }
                        }
                        RippleEffect { anchors.fill: parent; radius: 6; onClicked: root.deleteConfirm = true }
                    }

                    // Delete — confirm state
                    Rectangle {
                        visible: !root.online && root.deleteConfirm
                        Layout.fillWidth: true; implicitHeight: 34; color: "transparent"
                        CustomText {
                            anchors.centerIn: parent
                            content: "Permanently delete this file?"; size: 11; customColor: Colors.outline
                        }
                    }
                    Rectangle {
                        visible: !root.online && root.deleteConfirm
                        Layout.fillWidth: true; implicitHeight: 38; color: "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            MaterialIconSymbol { content: "delete_forever"; iconSize: 16; customColor: Colors.error }
                            CustomText { Layout.fillWidth: true; content: "Yes, delete permanently"; size: 12; customColor: Colors.error }
                        }
                        RippleEffect {
                            anchors.fill: parent; radius: 6
                            onClicked: { ServiceWallpaper.deleteWallpaper(root.target); root.close() }
                        }
                    }
                    Rectangle { visible: !root.online && root.deleteConfirm; Layout.fillWidth: true; implicitHeight: 1; color: Colors.surfaceContainerHighest }
                    Rectangle {
                        visible: !root.online && root.deleteConfirm
                        Layout.fillWidth: true; implicitHeight: 38; color: "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            MaterialIconSymbol { content: "close"; iconSize: 16; customColor: Colors.outline }
                            CustomText { Layout.fillWidth: true; content: "Cancel"; size: 12 }
                        }
                        RippleEffect { anchors.fill: parent; radius: 6; onClicked: root.deleteConfirm = false }
                    }

                    // ── ONLINE ─────────────────────────────────────────────

                    Rectangle {
                        id: dlRow
                        visible: root.online
                        Layout.fillWidth: true; implicitHeight: 40; color: "transparent"
                        readonly property bool busy: root.target
                            && ServiceWallpaper.downloadingId === root.target.id
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            MaterialIconSymbol {
                                content: dlRow.busy ? "hourglass_empty" : "download"
                                iconSize: 16; customColor: Colors.primary
                            }
                            CustomText {
                                Layout.fillWidth: true
                                content: dlRow.busy ? "Downloading…" : "Download & Set"
                                size: 12
                            }
                            Rectangle {
                                visible: dlRow.busy
                                height: 20; radius: 10; implicitWidth: _pct.implicitWidth + 16
                                color: Qt.alpha(Colors.primary, 0.15)
                                CustomText {
                                    id: _pct; anchors.centerIn: parent
                                    content: Math.round(ServiceWallpaper.downloadProgress * 100) + "%"
                                    size: 10; customColor: Colors.primary
                                }
                            }
                        }
                        RippleEffect {
                            anchors.fill: parent; radius: 6
                            onClicked: {
                                if (!dlRow.busy && root.target)
                                    ServiceWallpaper.downloadAndSetWallpaper(root.target)
                                root.close()
                            }
                        }
                    }

                    Rectangle { visible: root.online; Layout.fillWidth: true; implicitHeight: 1; color: Colors.surfaceContainerHighest }

                    Rectangle {
                        visible: root.online
                        Layout.fillWidth: true; implicitHeight: 40; color: "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            MaterialIconSymbol { content: "content_copy"; iconSize: 16; customColor: Colors.outline }
                            CustomText { Layout.fillWidth: true; content: "Copy Image URL"; size: 12 }
                        }
                        RippleEffect {
                            anchors.fill: parent; radius: 6
                            onClicked: {
                                if (root.target) Quickshell.clipboardText = root.target.fullUrl ?? ""
                                root.close()
                            }
                        }
                    }

                    Rectangle { visible: root.online; Layout.fillWidth: true; implicitHeight: 1; color: Colors.surfaceContainerHighest }

                    Rectangle {
                        visible: root.online
                        Layout.fillWidth: true; implicitHeight: 40; color: "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            MaterialIconSymbol { content: "open_in_new"; iconSize: 16; customColor: Colors.outline }
                            CustomText { Layout.fillWidth: true; content: "Open in Browser"; size: 12 }
                        }
                        RippleEffect {
                            anchors.fill: parent; radius: 6
                            onClicked: {
                                if (root.target)
                                    Quickshell.execDetached(["xdg-open",
                                        "https://wallhaven.cc/w/" + root.target.id])
                                root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
