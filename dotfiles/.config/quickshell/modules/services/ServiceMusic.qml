pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Services.Mpris
import qs.modules.settings

Singleton{
    id: root

    property MprisPlayer trackedPlayer: null
    property MprisPlayer activePlayer: trackedPlayer ?? Mpris.players.values[0] ?? null
    signal trackChanged(reverse: bool)

    property bool __reverse: false
    property var activeTrack
    property string _lastArtUrl: ""

    readonly property string _musicColorsScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/music_colors.sh"

    Process {
        id: musicColorGen
        onExited: (exitCode) => {
            if (exitCode !== 0)
                console.warn("[ServiceMusic] music_colors.sh exited with code:", exitCode)
        }
    }

    function generateMusicColors(artUrl) {
        if (!artUrl || artUrl === _lastArtUrl) return
        _lastArtUrl = artUrl
        musicColorGen.command = [
            _musicColorsScript,
            artUrl,
            SettingsConfig.theme.matugenScheme,
            SettingsConfig.theme.matugenTheme.toLowerCase()
        ]
        musicColorGen.running = true
    }

    property real trackLength: 0

    function _metadataLength(player) {
        const raw = Number(player?.metadata?.["mpris:length"])
        return (isFinite(raw) && raw > 0) ? raw / 1000000 : 0
    }

    function refreshLength() {
        const p = root.activePlayer
        if (!p) {
            root.trackLength = 0
            return
        }
        const fromMeta = root._metadataLength(p)
        if (fromMeta > 0) {
            root.trackLength = fromMeta
            return
        }
        if (p.lengthSupported && p.length > 0)
            root.trackLength = p.length
    }

    Timer {
        running: ServiceMusic.activePlayer?.isPlaying ?? false
        interval: 1000
        repeat: true
        onTriggered: {
            if (ServiceMusic.activePlayer) {
                ServiceMusic.activePlayer.positionChanged()
                ServiceMusic.refreshLength()
            }
        }
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: {
                if (root.trackedPlayer == null || modelData.isPlaying) {
                    root.trackedPlayer = modelData
                }
            }

            Component.onDestruction: {
                if (root.trackedPlayer == null || !root.trackedPlayer.isPlaying) {
                    for (const player of Mpris.players.values) {
                        if (player.playbackState.isPlaying) {
                            root.trackedPlayer = player
                            break
                        }
                    }

                    if (trackedPlayer == null && Mpris.players.values.length != 0) {
                        trackedPlayer = Mpris.players.values[0]
                    }
                }
            }

            function onPlaybackStateChanged() {
                if (root.trackedPlayer !== modelData) root.trackedPlayer = modelData
            }
        }
    }

    Connections {
        target: activePlayer

        function onPostTrackChanged() {
            root.updateTrack()
        }

        function onMetadataChanged() {
            root.refreshLength()
        }

        function onTrackArtUrlChanged() {
            if (root.activePlayer.uniqueId == root.activeTrack.uniqueId && root.activePlayer.trackArtUrl != root.activeTrack.artUrl) {
                const r = root.__reverse
                root.updateTrack()
                root.__reverse = r
            }
        }
    }

    function formatTime(seconds) {
        if (!seconds || seconds <= 0) return "0:00"
        const mins = Math.floor(seconds / 60)
        const secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    onActivePlayerChanged: this.updateTrack()

    function updateTrack() {
        this.trackLength = 0
        this.refreshLength()
        this.activeTrack = {
            uniqueId: this.activePlayer?.uniqueId ?? 0,
            artUrl: this.activePlayer?.trackArtUrl ?? "",
            title: this.activePlayer?.trackTitle || "Unknown Title",
            artist: this.activePlayer?.trackArtist || "Unknown Artist",
            album: this.activePlayer?.trackAlbum || "Unknown Album",
            desktopEntry: this.activePlayer?.desktopEntry,
            identity: this.activePlayer?.identity
        }

        this.trackChanged(__reverse)
        this.__reverse = false

        // if (this.activeTrack.artUrl)
        //     this.generateMusicColors(this.activeTrack.artUrl)
    }

    property bool isPlaying: this.activePlayer && this.activePlayer.isPlaying
    property bool canTogglePlaying: this.activePlayer?.canTogglePlaying ?? false
    function togglePlaying() {
        if (this.canTogglePlaying) this.activePlayer.togglePlaying()
    }

    property bool canGoPrevious: this.activePlayer?.canGoPrevious ?? false
    function previous() {
        if (this.canGoPrevious) {
            this.__reverse = true
            this.activePlayer.previous()
        }
    }

    property bool canGoNext: this.activePlayer?.canGoNext ?? false
    function next() {
        if (this.canGoNext) {
            this.__reverse = false
            this.activePlayer.next()
        }
    }

    property bool canChangeVolume: this.activePlayer && this.activePlayer.volumeSupported && this.activePlayer.canControl

    property bool loopSupported: this.activePlayer && this.activePlayer.loopSupported && this.activePlayer.canControl
    property var loopState: this.activePlayer?.loopState ?? MprisLoopState.None
    function setLoopState(loopState) {
        if (this.loopSupported) {
            this.activePlayer.loopState = loopState
        }
    }

    property bool shuffleSupported: this.activePlayer && this.activePlayer.shuffleSupported && this.activePlayer.canControl
    property bool hasShuffle: this.activePlayer?.shuffle ?? false
    function setShuffle(shuffle) {
        if (this.shuffleSupported) {
            this.activePlayer.shuffle = shuffle
        }
    }

    function setActivePlayer(player) {
        const targetPlayer = player ?? Mpris.players[0]

        if (targetPlayer && this.activePlayer) {
            this.__reverse = Mpris.players.indexOf(targetPlayer) < Mpris.players.indexOf(this.activePlayer)
        } else {
            this.__reverse = false
        }

        this.trackedPlayer = targetPlayer
    }

    function pauseAll() {
        for (const player of Mpris.players.values) {
            if (player.canPause) player.pause()
        }
    }
}
