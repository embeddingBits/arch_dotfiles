pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property alias general: settingsAdapter.general
    property alias theme: settingsAdapter.theme
    property alias wallhaven: settingsAdapter.wallhaven
    property alias ai: settingsAdapter.ai
    property alias recording: settingsAdapter.recording
    property alias screenshot: settingsAdapter.screenshot
    property alias widgets: settingsAdapter.widgets
    property alias weather: settingsAdapter.weather
    property alias notifications: settingsAdapter.notifications
    property alias gameMode: settingsAdapter.gameMode
    property alias dashboard: settingsAdapter.dashboard
    property alias sleep: settingsAdapter.sleep

    property bool settingsReady: false

    Timer {
        id: writeTimer
        interval: 100
        repeat: false
        onTriggered: settingsFile.writeAdapter()
    }

    Timer {
        id: reloadTimer
        interval: 100
        repeat: false
        onTriggered: settingsFile.reload()
    }

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/settings.json"
        watchChanges: true
        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        onLoaded: root.settingsReady = true
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                root.settingsReady = true
                writeTimer.restart()
            }
        }

        adapter: JsonAdapter {
            id: settingsAdapter

            readonly property var _generalDefaults: ({
                dock: true,
                dockAutoHide: true,
                dockMusicPlayer: true,
                appGrid: false,
                pinnedApps: [],
                musicVisOn: true,
                profile: "",
                defaultFont: "Rubik",
                displayFont: "Titan One",
                fontScale: "normal",
                fontWeight: "medium",
                musicVisBars: 60,
                musicVisStyle: "Wave",
                musicVisFps: "30 fps",
                musicVisColor: "Primary",
                wallpaperDir: Quickshell.env("HOME") + "/wallpaper",
                workspaceCount: 10,
                showWorkspaceNumbers: false,
                flatBarMode: true,
                primaryMonitor: "",
                perMonitorWorkspaces: false,
                barCenter: "clock",
                motionScheme: "expressive",
                holidayCountry: "",
                fileDropDir: "",
                welcomeDone: false
            })

            property var general: ({
                dock: true,
                dockAutoHide: true,
                dockMusicPlayer: true,
                appGrid: false,
                pinnedApps: [],
                musicVisOn: true,
                profile: "",
                defaultFont: "Rubik",
                displayFont: "Titan One",
                fontScale: "normal",
                fontWeight: "medium",
                musicVisBars: 60,
                musicVisStyle: "Wave",
                musicVisFps: "30 fps",
                musicVisColor: "Primary",
                wallpaperDir: Quickshell.env("HOME") + "/wallpaper",
                workspaceCount: 10,
                showWorkspaceNumbers: false,
                flatBarMode: true,
                primaryMonitor: "",
                perMonitorWorkspaces: false,
                barCenter: "clock",
                motionScheme: "expressive",
                holidayCountry: "",
                fileDropDir: "",
                welcomeDone: false
            })

            onGeneralChanged: {
                const d = _generalDefaults
                const cur = general || {}
                let needsPatch = false
                for (const k in d) {
                    if (cur[k] === undefined) { needsPatch = true; break }
                }
                if (needsPatch)
                    general = Object.assign({}, d, cur)
            }

            readonly property var _themeDefaults: ({
                matugenScheme: "scheme-content",
                matugenTheme: "dark",
                firstColor: "#ffffff",
                secondColor: "#ffffff",
                thirdColor: "#ffffff",
                transitionType: "fade"
            })

            property var theme: ({
                matugenScheme: "scheme-content",
                matugenTheme: "dark",
                firstColor: "#ffffff",
                secondColor: "#ffffff",
                thirdColor: "#ffffff",
                transitionType: "fade"
            })

            onThemeChanged: {
                const d = _themeDefaults
                let cur = theme || {}
                let dirty = false

                // fill in any missing keys from defaults
                for (const k in d) {
                    if (cur[k] === undefined) { dirty = true; break }
                }
                if (dirty) cur = Object.assign({}, d, cur)

                // normalize legacy capitalized mode values ("Light" → "light")
                const mode = cur.matugenTheme
                if (mode && mode !== mode.toLowerCase()) {
                    cur = Object.assign({}, cur, { matugenTheme: mode.toLowerCase() })
                    dirty = true
                }

                // strip legacy gowall keys
                const legacy = ["colorEngine", "gowallTheme"]
                for (const k of legacy) {
                    if (k in cur) { delete cur[k]; dirty = true }
                }

                if (dirty) theme = cur
            }

            property var wallhaven: ({
                apiKey: "",
                categories: "111",
                purity: "100",
                sorting: "toplist",
                order: "desc",
                topRange: "1M",
                atleast: "",
                ratios: ""
            })

            property var ai: ({
                // Master switch. Off stops the browser bridge and the whisper
                // daemon and makes the panel refuse to open.
                enabled: true,
                // Empty means the PipeWire default source.
                source: "",
                // Send a dictation the moment it lands rather than dropping it
                // into the composer to read over first.
                autoSend: false,
                // faster-whisper model. distil-large-v3 is the most accurate that
                // fits the GPU; base.en / small.en are lighter if it struggles.
                model: "distil-large-v3",
                // Terms whisper keeps mangling. It leans toward words it has
                // already seen, so listing your jargon here makes them far
                // likelier to come out right.
                vocabulary: "",
                // Panel appearance
                codeFont: "Adwaita Mono",
                codeFontSize: 13,
                composerFont: "Adwaita Mono",
                composerFontSize: 15,
                syntaxHighlight: true,
                accentBold: true,
                // Reply parsing policy. The extension ships an unfiltered node
                // walk; these decide what survives into the rendered blocks.
                keepScreenReader: false,
                keepControls: false
            })

            property var recording: ({
                outputPath: "~/Videos",
                codec: "libx264",
                muxer: "mp4",
                framerate: "30",
                pixelFormat: "yuv420p",
                audioEnabled: true,
                audioSource: "mic",
                audioCodec: "aac",
                audioBitrate: "128k",
                audioSampleRate: "48000"
            })

            property var screenshot: ({
                outputPath: "~/Pictures",
                soundEnabled: true,
                soundPath: ""
            })

            property var widgets: ({
                clockX: 100,
                clockY: 100,
                musicPlayerX: 200,
                musicPlayerY: 200,
                dateWidgetX: 300,
                dateWidgetY: 300,
                analogClockX: 400,
                analogClockY: 200,
                showCircularMusicPlayer: true,
                showClock: false,
                showDateWidget: false,
                showAnalogClock: false,
                analogClockStyle: "classic",
                dateWidgetStyle: "default",
                digitalClockStyle: "classic",
                showProfileCard: false,
                profileCardStyle: "card",
                profileCardX: 100,
                profileCardY: 400,
                showSunArc: false,
                sunArcX: 100,
                sunArcY: 620,
                showMoonPhase: false,
                moonPhaseX: 620,
                moonPhaseY: 440,
                showStickyNote: false,
                stickyNoteText: "",
                stickyNoteX: 620,
                stickyNoteY: 660,
                showHeadlines: false,
                headlinesX: 620,
                headlinesY: 900,
                newsFeedUrl: "https://feeds.bbci.co.uk/news/world/rss.xml",
                newsRefreshMinutes: 30,
                showTaskList: false,
                taskListX: 960,
                taskListY: 200,
                showNetworkGraph: false,
                networkGraphX: 100,
                networkGraphY: 780,
                networkGraphWindow: "3 min",
                networkGraphInterval: "2 s",
                showSpectrum: false,
                spectrumX: 420,
                spectrumY: 620,
                showAlbumArt: false,
                albumArtX: 760,
                albumArtY: 620,
                showWeatherHourly: false,
                weatherHourlyX: 420,
                weatherHourlyY: 200,
                showWeatherWind: false,
                weatherWindX: 760,
                weatherWindY: 200,
                showWeatherBarometer: false,
                weatherBarometerX: 1000,
                weatherBarometerY: 200
            })

            property var weather: ({
                location: "Chirawa",
                useMetric: true,
                refreshInterval: 15
            })

            property var notifications: ({
                doNotDisturb: false,
                showBanners: true,
                popupTimeout: 5,
                maxVisible: 3,
                showInCenter: true,
                playSound: false,
                soundPath: ""
            })

            readonly property var _dashboardDefaults: ({
                profile: true,
                controls: true,
                quickActions: true,
                notifications: true,
                calendar: true,
                order: ["profile", "controls", "quickActions", "notifications", "calendar"]
            })

            property var dashboard: ({
                profile: true,
                controls: true,
                quickActions: true,
                notifications: true,
                calendar: true,
                order: ["profile", "controls", "quickActions", "notifications", "calendar"]
            })

            onDashboardChanged: {
                const d = _dashboardDefaults
                const cur = dashboard || {}
                let needsPatch = false
                for (const k in d) {
                    if (cur[k] === undefined) { needsPatch = true; break }
                }
                if (needsPatch)
                    dashboard = Object.assign({}, d, cur)
            }

            readonly property var _sleepDefaults: ({
                dimEnabled: true,
                dimMinutes: 8,
                dimLevel: 10,
                lockEnabled: true,
                lockMinutes: 10,
                screenOffEnabled: false,
                screenOffMinutes: 11,
                suspendEnabled: true,
                suspendMinutes: 30
            })

            property var sleep: ({
                dimEnabled: true,
                dimMinutes: 8,
                dimLevel: 10,
                lockEnabled: true,
                lockMinutes: 10,
                screenOffEnabled: false,
                screenOffMinutes: 11,
                suspendEnabled: true,
                suspendMinutes: 30
            })

            onSleepChanged: {
                const d = _sleepDefaults
                const cur = sleep || {}
                let needsPatch = false
                for (const k in d) {
                    if (cur[k] === undefined) { needsPatch = true; break }
                }
                if (needsPatch)
                    sleep = Object.assign({}, d, cur)
            }

            readonly property var _gameModeDefaults: ({
                hideBar: true,
                hideWidgets: true,
                dnd: true,
                hyprPerf: true
            })

            property var gameMode: ({
                hideBar: true,
                hideWidgets: true,
                dnd: true,
                hyprPerf: true
            })

            onGameModeChanged: {
                const d = _gameModeDefaults
                const cur = gameMode || {}
                let needsPatch = false
                for (const k in d) {
                    if (cur[k] === undefined) { needsPatch = true; break }
                }
                if (needsPatch)
                    gameMode = Object.assign({}, d, cur)
            }

            property var toggles: ({
                airplaneMode: false,
                notificationMuted: false,
                speakerMuted: false,
                micMuted: false
            })
        }
    }
}
