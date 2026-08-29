import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform
import qs.modules.utils
import qs.modules.settings
import qs.modules.services
import qs.modules.customComponents

Item {
    id: root
    anchors.fill: parent

    signal closed
    signal pinned

    readonly property bool showAgain: SettingsConfig.general.welcomeDone !== true
    readonly property bool multiMonitor: Quickshell.screens.length > 1

    readonly property string prettyDir: {
        const home = Quickshell.env("HOME") ?? ""
        const dir = SettingsConfig.general.wallpaperDir ?? (home + "/wallpaper")
        return home !== "" && dir.startsWith(home) ? "~" + dir.slice(home.length) : dir
    }

    opacity: 0
    NumberAnimation on opacity { from: 0; to: 1; duration: 220; running: true }

    FolderDialog {
        id: folderPicker
        title: "Select wallpaper directory"
        onAccepted: {
            SettingsConfig.general = Object.assign({}, SettingsConfig.general, {
                wallpaperDir: folder.toString().replace(/^file:\/\//, "")
            })
            GlobalStates.fileDialogOpen = false
        }
        onRejected: GlobalStates.fileDialogOpen = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 26
        color: Colors.surface

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    spacing: 0

                    CustomText {
                        content: "Set up Nebula"
                        size: 24
                        family: SettingsConfig.general.displayFont ?? "Titan One"
                        weight: Font.Normal
                    }

                    CustomText {
                        content: "Pick a wallpaper — everything else colours itself from it."
                        size: 12
                        customColor: Colors.outline
                    }
                }

                Item { Layout.fillWidth: true }

                CustomText {
                    Layout.alignment: Qt.AlignVCenter
                    content: "Show at startup"
                    size: 12
                    customColor: Colors.outline
                }

                CustomToogle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 30
                    isToggleOn: root.showAgain
                    onToggled: state => {
                        SettingsConfig.general = Object.assign({}, SettingsConfig.general, { welcomeDone: !state })
                        if (state)
                            root.pinned()
                    }
                }

                M3IconButton {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 4
                    icon: "close"
                    implicitWidth: 36
                    implicitHeight: 36
                    iconSize: 18
                    onClicked: root.closed()
                }
            }

            WallpaperCarousel {
                id: carousel
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(Math.max(140, Math.min(300, carousel.tileSize * 9 / 16)))
                focalCount: 3
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                M3ButtonGroup {
                    Layout.preferredWidth: 190
                    Layout.preferredHeight: 30
                    fillWidth: true
                    model: [
                        { value: "dark",  label: "Dark",  icon: "dark_mode"  },
                        { value: "light", label: "Light", icon: "light_mode" }
                    ]
                    activeCheck: v => (SettingsConfig.theme.matugenTheme ?? "dark") === v
                    onSegmentClicked: v => {
                        if ((SettingsConfig.theme.matugenTheme ?? "dark") === v) return
                        SettingsConfig.theme = Object.assign({}, SettingsConfig.theme, { matugenTheme: v })
                        ServiceWallpaper.applyTheme()
                    }
                }

                CustomListNew {
                    Layout.preferredWidth: 190
                    Layout.preferredHeight: 30
                    color: Colors.surfaceContainerHighest
                    list: Settings.matugen
                    Component.onCompleted: currentVal = SettingsConfig.theme.matugenScheme
                    onCurrentValChanged: {
                        if (!currentVal || currentVal === SettingsConfig.theme.matugenScheme) return
                        SettingsConfig.theme = Object.assign({}, SettingsConfig.theme, { matugenScheme: currentVal })
                        if (Colors.wallpaper !== "")
                            Quickshell.execDetached([ServiceWallpaper.wallpaperScript, Colors.wallpaper, currentVal,
                                                     SettingsConfig.theme.matugenTheme, ServiceWallpaper.transitionType])
                    }
                }

                M3Button {
                    size: "xsmall"
                    variant: "tonal"
                    icon: "folder_open"
                    label: "Folder"
                    onClicked: {
                        GlobalStates.fileDialogOpen = true
                        folderPicker.open()
                    }
                }

                CustomText {
                    Layout.fillWidth: true
                    content: root.prettyDir
                    size: 12
                    customColor: Colors.outline
                    elide: Text.ElideMiddle
                }

                Row {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Repeater {
                        model: [Colors.primary, Colors.secondary, Colors.tertiary,
                                Colors.surfaceContainerHighest, Colors.outline, Colors.error]

                        Rectangle {
                            required property var modelData
                            required property int index

                            width: 24
                            height: 24
                            color: modelData
                            topLeftRadius: index === 0 ? 12 : 0
                            bottomLeftRadius: index === 0 ? 12 : 0
                            topRightRadius: index === 5 ? 12 : 0
                            bottomRightRadius: index === 5 ? 12 : 0

                            Behavior on color { ColorAnimation { duration: 260 } }
                        }
                    }
                }
            }

            Flickable {
                id: scroller
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: grid.implicitHeight
                contentWidth: width
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 2500
                maximumFlickVelocity: 8000
                ScrollBar.vertical: CustomScrollBar {}

                readonly property real maxContentY: Math.max(0, contentHeight - height)

                function glideTo(dest) {
                    const d = Math.max(0, Math.min(maxContentY, dest))
                    if (Math.abs(d - contentY) < 0.5) return
                    cancelFlick()
                    pageAnim.stop()
                    pageAnim.from = contentY
                    pageAnim.to = d
                    pageAnim.start()
                }

                NumberAnimation {
                    id: pageAnim
                    target: scroller
                    property: "contentY"
                    duration: 380
                    easing.type: Easing.OutCubic
                }

                GridLayout {
                    id: grid
                    width: scroller.width - 12
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 12

                    TileProfile {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 12

                        TileWeather {}

                        TileDisplays { visible: root.multiMonitor }
                    }

                    TileShortcuts {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                    }

                    TilePackages {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    z: -1

                    onWheel: wheel => {
                        wheel.accepted = false
                        if (scroller.maxContentY <= 0) return

                        const px = wheel.pixelDelta.y
                        const ang = wheel.angleDelta.y
                        if (px === 0 && ang === 0) return

                        if (px !== 0) {
                            const d = Math.max(0, Math.min(scroller.maxContentY, scroller.contentY - px))
                            if (Math.abs(d - scroller.contentY) < 0.01) return
                            pageAnim.stop()
                            scroller.cancelFlick()
                            scroller.contentY = d
                            wheel.accepted = true
                            return
                        }

                        const base = pageAnim.running ? pageAnim.to : scroller.contentY
                        const dest = base - (ang / 120) * 120
                        if (Math.abs(Math.max(0, Math.min(scroller.maxContentY, dest)) - scroller.contentY) < 0.5) return

                        scroller.glideTo(dest)
                        wheel.accepted = true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                M3Button {
                    size: "small"
                    variant: "text"
                    icon: "tune"
                    label: "Open Settings"
                    onClicked: {
                        GlobalStates.settingsOpen = true
                        root.closed()
                    }
                }

                M3Button {
                    size: "small"
                    variant: "filled"
                    icon: "check"
                    label: "All done"
                    onClicked: root.closed()
                }
            }
        }
    }
}
