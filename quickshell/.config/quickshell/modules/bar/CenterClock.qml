import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../config/Theme.qml" as Theme

Item {
    id: root

    required property bool calendarOpen
    required property var calendarService
    signal toggleCalendar

    // ── Mpris now-playing ──
    property var mprisPlayers: Mpris.players ? Mpris.players.values : []
    property var activeMprisPlayer: {
        for (let i = 0; i < mprisPlayers.length; i++)
            if (mprisPlayers[i] && mprisPlayers[i].isPlaying)
                return mprisPlayers[i];
        for (let j = 0; j < mprisPlayers.length; j++)
            if (mprisPlayers[j] && mprisPlayers[j].trackTitle)
                return mprisPlayers[j];
        return null;
    }
    property string nowPlayingText: {
        let p = activeMprisPlayer;
        if (!p)
            return "";
        let t = p.trackTitle || "";
        let a = p.trackArtist || p.trackArtists || "";
        if (t && a)
            return a + " - " + t;
        if (t)
            return t;
        if (a)
            return a;
        return p.identity || "";
    }
    property bool nowPlayingIsPlaying: activeMprisPlayer ? activeMprisPlayer.isPlaying : false

    width: centerRow.implicitWidth + 28
    height: parent ? parent.height : Theme.barHeight

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        radius: Theme.radius
        color: clockMouse.containsMouse || root.calendarOpen ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07) : "transparent"
    }

    RowLayout {
        id: centerRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            id: clock
            color: Theme.fg
            font.family: Theme.fontFamily
            font.weight: 700
            font.pixelSize: Theme.barFontSize
            Layout.alignment: Qt.AlignVCenter

            property date currentTime: new Date()
            text: Qt.formatDateTime(currentTime, "dddd hh:mm:ss AP")

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.currentTime = new Date()
            }
        }

        Text {
            visible: root.nowPlayingText !== ""
            text: "|"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.barFontSize
            color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.6)
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            visible: root.nowPlayingText !== ""
            Layout.preferredWidth: nowPlayingRow.implicitWidth
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                id: nowPlayingRow
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: root.nowPlayingIsPlaying ? "󰝚" : "󰏤"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.barFontSize
                    color: root.nowPlayingIsPlaying ? Theme.accent : Theme.muted
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.nowPlayingText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.barFontSize
                    font.weight: 500
                    color: Theme.fg
                    elide: Text.ElideRight
                    Layout.maximumWidth: 260
                    Layout.alignment: Qt.AlignVCenter
                    maximumLineCount: 1
                }
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        height: 2
        radius: 1
        color: Theme.underlineClock
        opacity: clockMouse.containsMouse || root.calendarOpen ? 1 : 0.92
    }

    MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: function (mouse) {
            if (root.nowPlayingText !== "" && root.activeMprisPlayer) {
                let rowX = centerRow.x;
                let clockRight = rowX + clock.implicitWidth + 12;
                if (mouseX > clockRight) {
                    let p = root.activeMprisPlayer;
                    if (p.canTogglePlaying)
                        p.togglePlaying();
                    else if (p.isPlaying)
                        p.pause();
                    else
                        p.play();
                    return;
                }
            }
            root.toggleCalendar();
        }
    }
}
