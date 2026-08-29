pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.modules.settings
import WfRecorder


Singleton{
    id: root

    // Recording state — sourced directly from the C++ plugin
    readonly property bool   isRecording:   WfRecorder.recording
    readonly property string recordingMode: WfRecorder.mode
    readonly property int    recordingSeconds: WfRecorder.elapsed
    readonly property string lastFilename:  WfRecorder.filename

    // Send stop notification when recording finishes
    Connections {
        target: WfRecorder
        function onRecordingStopped(duration) {
            const path = root.lastFilename
            const dur  = Math.floor(duration / 60) + ":" + String(duration % 60).padStart(2, "0")
            const safe = "'" + path.replace(/'/g, "'\\''") + "'"
            const dir  = "'" + path.replace(/'/g, "'\\''").replace(/\/[^/]*$/, "") + "'"
            Quickshell.execDetached(["sh", "-c",
                'A=$(notify-send "Recording Saved" "Duration: ' + dur + '" --app-icon=camera-video ' +
                '--action="open=Open" --action="folder=Show in Folder" --action="delete=Delete" --wait); ' +
                'case "$A" in ' +
                'open)   xdg-open ' + safe + ' ;; ' +
                'folder) xdg-open ' + dir  + ' ;; ' +
                'delete) rm -- '    + safe + ' ;; ' +
                'esac'
            ])
        }
        function onRecordingError(message) {
            ServiceNotification.sendNotification(
                "Recording Error",
                message,
                "Recording",
                "dialog-error"
            )
        }
    }

    // ── Screenshot sound ──────────────────────────────────────────────────────
    function playShutterSound() {
        const p = SettingsConfig.screenshot.soundPath || ""
        if (SettingsConfig.screenshot.soundEnabled && p !== "")
            Quickshell.execDetached(["paplay", p.replace("~", Quickshell.env("HOME"))])
    }

    // Captures the path grimblast prints to stdout, then sends a notification with actions
    property string _screenshotPath: ""

    Process {
        id: screenshotProc
        stdout: SplitParser {
            onRead: line => {
                const p = line.trim()
                if (p !== "") root._screenshotPath = p
            }
        }
        onExited: exitCode => {
            root.playShutterSound()
            if (exitCode === 0 && root._screenshotPath !== "")
                root.screenshotReady(root._screenshotPath)
            else
                root._sendScreenshotNotif(root._screenshotPath)
            root._screenshotPath = ""
        }
    }

    Process {
        id: areaScreenshotProc
        onExited: exitCode => {
            root.playShutterSound()
            if (exitCode === 0 && root._areaScreenshotPath !== "")
                root.screenshotReady(root._areaScreenshotPath)
            else
                root._sendScreenshotNotif(root._areaScreenshotPath)
        }
    }

    property int  captureDelay: 0
    property int  countdownRemaining: 0
    readonly property bool countingDown: countdownRemaining > 0
    signal screenshotReady(string path)

    property string _pendingKind: ""
    property string _pendingGeo:  ""

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdownRemaining -= 1
            if (root.countdownRemaining <= 0) {
                stop()
                root._runPendingCapture()
            }
        }
    }

    function _beginCapture(kind, geo) {
        root._pendingKind = kind
        root._pendingGeo  = geo
        if (root.captureDelay > 0) {
            root.countdownRemaining = root.captureDelay
            countdownTimer.restart()
        } else {
            root._runPendingCapture()
        }
    }

    function _runPendingCapture() {
        const k = root._pendingKind, g = root._pendingGeo
        root._pendingKind = ""
        root._pendingGeo  = ""
        if (k === "Screen")    root._doScreenshot()
        else if (k === "Area") root._doAreaScreenshot(g)
    }

    function cancelCountdown() {
        countdownTimer.stop()
        root.countdownRemaining = 0
        root._pendingKind = ""
        root._pendingGeo  = ""
    }

    function editScreenshot(path) {
        Quickshell.execDetached(["swappy", "-f", path])
    }

    function deleteScreenshot(path) {
        Quickshell.execDetached(["rm", "-f", path])
    }

    function copyScreenshot(path) {
        Quickshell.execDetached(["sh", "-c", "wl-copy < " + root._shq(path)])
    }

    property string _areaScreenshotPath: ""

    property string _ocrText: ""
    readonly property bool ocrBusy: ocrProc.running

    Process {
        id: ocrProc
        stdout: StdioCollector {
            onStreamFinished: root._ocrText = this.text
        }
        onExited: exitCode => {
            var t = (root._ocrText ?? "").trim()
            if (exitCode !== 0 || t.length === 0) {
                ServiceNotification.sendNotification(
                    "No text found", "Nothing recognisable in that region", "OCR", "edit-find")
                return
            }
            Quickshell.execDetached(["sh", "-c",
                "printf '%s' " + root._shq(t) + " | wl-copy"])
            var preview = t.length > 140 ? t.substring(0, 140) + "\u2026" : t
            ServiceNotification.sendNotification("Text copied", preview, "OCR", "edit-copy")
        }
    }

    function _shq(v) { return "'" + String(v).replace(/'/g, "'\\''") + "'" }

    property var    ocrLines:   []
    property string ocrImage:   ""
    readonly property bool ocrScanning: ocrScanProc.running
    signal ocrCaptureReady(string path)
    signal ocrScanFinished(int count)

    Process {
        id: ocrCaptureProc
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.ocrImage = ""
                ServiceNotification.sendNotification(
                    "Live Text failed", "Could not capture the screen", "OCR", "dialog-error")
                return
            }
            root.ocrCaptureReady(root.ocrImage)
            ocrScanProc.command = ["sh", "-c",
                "tesseract " + root._shq(root.ocrImage) + " - tsv --psm 11 2>/dev/null"]
            ocrScanProc.running = true
        }
    }

    Process {
        id: ocrScanProc
        stdout: StdioCollector {
            onStreamFinished: root._parseTsv(this.text)
        }
        onExited: exitCode => {
            if (exitCode !== 0) root.ocrLines = []
            root.ocrScanFinished(root.ocrLines.length)
        }
    }

    property string _liveTextOutput: ""

    Timer {
        id: liveTextSettle
        interval: 80
        onTriggered: {
            ocrCaptureProc.command = ["grim", "-l", "0", "-o", root._liveTextOutput, root.ocrImage]
            ocrCaptureProc.running = true
        }
    }

    function startLiveText(outputName) {
        if (ocrCaptureProc.running || ocrScanProc.running || liveTextSettle.running) return
        root.ocrLines = []
        root._liveTextOutput = outputName
        root.ocrImage = "/tmp/quickshell-livetext-" + Date.now() + ".png"
        liveTextSettle.restart()
    }

    function clearScan() {
        if (root.ocrImage !== "")
            Quickshell.execDetached(["rm", "-f", root.ocrImage])
        root.ocrImage = ""
        root.ocrLines = []
    }

    property real ocrSplitRatio: 1.5

    function _parseTsv(tsv) {
        var rows = String(tsv).split("\n")
        var byLine = {}
        var order  = []

        for (var i = 1; i < rows.length; i++) {
            var f = rows[i].split("\t")
            if (f.length < 12) continue

            var level = parseInt(f[0])
            if (level !== 4 && level !== 5) continue

            var key = f[2] + "/" + f[3] + "/" + f[4]
            if (byLine[key] === undefined) {
                byLine[key] = { h: 0, words: [] }
                order.push(key)
            }

            if (level === 4) {
                byLine[key].h = parseInt(f[9])
            } else if (parseFloat(f[10]) >= 40) {
                var word = f[11]
                if (word === undefined || word.trim() === "") continue
                byLine[key].words.push({
                    x: parseInt(f[6]), y: parseInt(f[7]),
                    w: parseInt(f[8]), h: parseInt(f[9]),
                    t: word
                })
            }
        }

        var out = []
        for (var j = 0; j < order.length; j++) {
            var e = byLine[order[j]]
            if (e.words.length === 0) continue

            var ws = e.words.slice().sort(function(a, b) { return a.x - b.x })
            var ref = e.h > 0 ? e.h : ws[0].h
            var limit = Math.max(ref, 1) * root.ocrSplitRatio

            var segs = [[ws[0]]]
            for (var k = 1; k < ws.length; k++) {
                var prev = ws[k - 1]
                if (ws[k].x - (prev.x + prev.w) > limit) segs.push([ws[k]])
                else segs[segs.length - 1].push(ws[k])
            }

            for (var m = 0; m < segs.length; m++) {
                var seg = segs[m]
                var x0 = seg[0].x, y0 = seg[0].y, x1 = seg[0].x + seg[0].w, y1 = seg[0].y + seg[0].h
                var parts = []
                for (var n = 0; n < seg.length; n++) {
                    var t = seg[n]
                    if (t.x < x0) x0 = t.x
                    if (t.y < y0) y0 = t.y
                    if (t.x + t.w > x1) x1 = t.x + t.w
                    if (t.y + t.h > y1) y1 = t.y + t.h
                    parts.push(t.t)
                }
                if (x1 - x0 < 6 || y1 - y0 < 6) continue
                out.push({ x: x0, y: y0, w: x1 - x0, h: y1 - y0, text: parts.join(" ") })
            }
        }
        root.ocrLines = out
    }

    function copyText(t) {
        var s = String(t).trim()
        if (s === "") return
        Quickshell.execDetached(["sh", "-c", "printf '%s' " + root._shq(s) + " | wl-copy"])
        var preview = s.length > 140 ? s.substring(0, 140) + "\u2026" : s
        ServiceNotification.sendNotification("Text copied", preview, "OCR", "edit-copy")
    }

    // Grab a region, run it through tesseract, put the text on the clipboard.
    // --psm 6 assumes a uniform block, which suits UI text far better than the
    // default page-segmentation mode. Capturing at 2x and telling tesseract the
    // DPI doubled measurably improves accuracy on small antialiased UI text.
    function ocrArea(geo) {
        root._ocrText = ""
        ocrProc.command = ["sh", "-c",
            "grim -s 2 -g " + root._shq(geo) + " - | tesseract - - --dpi 300 --psm 6 2>/dev/null"]
        ocrProc.running = true
    }

    function _sendScreenshotNotif(path) {
        if (path === "") return
        const safe = "'" + path.replace(/'/g, "'\\''") + "'"
        const dir  = "'" + path.replace(/'/g, "'\\''").replace(/\/[^/]*$/, "") + "'"
        Quickshell.execDetached(["sh", "-c",
            'A=$(notify-send "Screenshot" ' + safe + ' --app-icon=camera-photo ' +
            '--action="open=Open" --action="folder=Show in Folder" --action="delete=Delete" --wait); ' +
            'case "$A" in ' +
            'open)   xdg-open ' + safe + ' ;; ' +
            'folder) xdg-open ' + dir  + ' ;; ' +
            'delete) rm -- '    + safe + ' ;; ' +
            'esac'
        ])
    }

    property var tools: [
        {
            name: "Record",
            icon: "screen_record",
            options:[
                {
                    name: "Screen",
                    icon: "screenshot_frame_2",
                    audio: false
                },

                {
                    name: "Window",
                    icon: "window",
                    audio: false
                },
                {
                    name: "Area",
                    icon: "select",
                    audio: false
                },
 
            ]
        },
        {
            name: "Screenshot",
            icon: "photo_camera",
            options:[
                {
                    name: "Screen",
                    icon: "screenshot_frame_2",
                    command: ["sh", "-c", "sleep 0.5 && grimblast copysave output"]

                },
                {
                    name: "Window",
                    icon: "window",
                    command: ["sh", "-c", "sleep 0.5 && grimblast copysave active"]

                },
                {
                    name: "Area",
                    icon: "select",
                    command: ["sh", "-c", "sleep 0.5 && grimblast copysave area"]

                }
            ]
        },
        {
            name: "Setting",
            icon: "settings"
        },
        {
            name: "Power",
            icon: "power_settings_new",
            options:[
                {
                    name: "Shutdown",
                    icon: "power_settings_new",
                    command: ["systemctl", "poweroff"]


                },
                {
                    name: "Restart",
                    icon: "refresh",
                    command: ["systemctl", "reboot"]

                },
                {
                    name: "Logout",
                    icon: "logout",
                    command: ["loginctl", "lock-session"]

                }
            ]
        }
    ]

    // Delay timer for Area mode: fires after the widget fully closes so
    // HyprlandFocusGrab is released before slurp requests Wayland input.
    Timer {
        id: delayTimer
        interval: 700
        repeat: false
        property string pendingMode: ""
        property string pendingGeometry: ""
        onTriggered: root.toggleRecording(pendingMode, pendingGeometry)
    }

    // Call this from ToolsWidgetContent for Area/Window so the timer
    // survives the Loader teardown.
    function startDelayed(mode, geometry) {
        delayTimer.pendingMode = mode
        delayTimer.pendingGeometry = geometry
        delayTimer.restart()
    }

    // Generate filename using SettingsConfig output path + muxer extension
    function generateFilename() {
        var now = new Date()
        var timestamp = now.getFullYear() + "-" +
            String(now.getMonth() + 1).padStart(2, "0") + "-" +
            String(now.getDate()).padStart(2, "0") + "_" +
            String(now.getHours()).padStart(2, "0") + "." +
            String(now.getMinutes()).padStart(2, "0") + "." +
            String(now.getSeconds()).padStart(2, "0")
        var dir = SettingsConfig.recording.outputPath.replace("~", Quickshell.env("HOME"))
        var ext = SettingsConfig.recording.muxer
        return dir + "/recording_" + timestamp + "." + ext
    }

    function toggleRecording(mode, geometry) {
        if (WfRecorder.recording) {
            WfRecorder.stop()
            return
        }

        var rec = SettingsConfig.recording
        var dir = rec.outputPath.replace("~", Quickshell.env("HOME"))
        var filename = generateFilename()
        var base = `wf-recorder --codec ${rec.codec} --pixel-format ${rec.pixelFormat} -r ${rec.framerate}`
        var cmd = ""

        if (mode === "Screen") {
            cmd = `mkdir -p '${dir}' && ${base} -o ${Hyprland.focusedMonitor.name} -f '${filename}'`
        } else if (mode === "Area") {
            // slurp must run after the tools widget fully closes and releases its focus grab
            cmd = `mkdir -p '${dir}' && ${base} -g "$(slurp)" -f '${filename}'`
        }

        if (rec.audioEnabled) {
            var audioCodecFlags = ` --audio-codec ${rec.audioCodec} --audio-bitrate ${rec.audioBitrate} --sample-rate ${rec.audioSampleRate}`
            if (rec.audioSource === "system") {
                cmd += ` --audio=$(pactl get-default-sink).monitor` + audioCodecFlags
            } else if (rec.audioSource === "both") {
                // Create a temporary virtual combined sink, loopback both sources into it,
                // run wf-recorder, then unload modules on exit (; runs even if wf-recorder fails)
                cmd = `NULL_MOD=$(pactl load-module module-null-sink sink_name=qsrec_combined sink_properties=device.description=QuickshellCombined) && ` +
                      `SYS_MOD=$(pactl load-module module-loopback source=$(pactl get-default-sink).monitor sink=qsrec_combined latency_msec=1) && ` +
                      `MIC_MOD=$(pactl load-module module-loopback source=$(pactl get-default-source) sink=qsrec_combined latency_msec=1) && ` +
                      cmd + ` --audio=qsrec_combined.monitor` + audioCodecFlags +
                      ` ; pactl unload-module $MIC_MOD ; pactl unload-module $SYS_MOD ; pactl unload-module $NULL_MOD`
            } else {
                cmd += ` --audio` + audioCodecFlags
            }
        }

        WfRecorder.start(cmd, mode, filename)
        ServiceNotification.sendNotification("Recording Started", "Recording " + mode, "Recording", "camera-video")
    }

    function stopRecording() {
        WfRecorder.stop()
    }

    function takeScreenshot(mode) {
        if (mode === "Screen") root._beginCapture("Screen", "")
    }

    function _doScreenshot() {
        screenshotProc.command = ["sh", "-c", "sleep 0.5 && grimblast copysave output"]
        screenshotProc.running = true
    }

    // Called after the in-shell area selector provides a geometry string "x,y WxH"
    function takeAreaScreenshot(geo) {
        root._beginCapture("Area", geo)
    }

    function _doAreaScreenshot(geo) {
        var now = new Date()
        var ts  = now.getFullYear() + "-" +
                  String(now.getMonth() + 1).padStart(2, "0") + "-" +
                  String(now.getDate()).padStart(2, "0") + "_" +
                  String(now.getHours()).padStart(2, "0") + "." +
                  String(now.getMinutes()).padStart(2, "0") + "." +
                  String(now.getSeconds()).padStart(2, "0")
        var dir  = SettingsConfig.screenshot.outputPath.replace("~", Quickshell.env("HOME"))
        var path = dir + "/screenshot_" + ts + ".png"
        root._areaScreenshotPath = path
        areaScreenshotProc.command = ["sh", "-c",
            "mkdir -p '" + dir + "' && sleep 0.4 && grim -g '" + geo + "' '" + path + "' && wl-copy < '" + path + "'"]
        areaScreenshotProc.running = true
    }

    // Start recording with a geometry string provided by the in-shell area selector
    function startWithGeometry(mode, geometry) {
        var rec      = SettingsConfig.recording
        var dir      = rec.outputPath.replace("~", Quickshell.env("HOME"))
        var filename = generateFilename()
        var base     = `wf-recorder --codec ${rec.codec} --pixel-format ${rec.pixelFormat} -r ${rec.framerate}`
        var cmd      = `mkdir -p '${dir}' && ${base} -g "${geometry}" -f '${filename}'`
        if (rec.audioEnabled) {
            var audioCodecFlags = ` --audio-codec ${rec.audioCodec} --audio-bitrate ${rec.audioBitrate} --sample-rate ${rec.audioSampleRate}`
            if (rec.audioSource === "system") {
                cmd += ` --audio=$(pactl get-default-sink).monitor` + audioCodecFlags
            } else if (rec.audioSource === "both") {
                // Create a temporary virtual combined sink, loopback both sources into it,
                // run wf-recorder, then unload modules on exit (; runs even if wf-recorder fails)
                cmd = `NULL_MOD=$(pactl load-module module-null-sink sink_name=qsrec_combined sink_properties=device.description=QuickshellCombined) && ` +
                      `SYS_MOD=$(pactl load-module module-loopback source=$(pactl get-default-sink).monitor sink=qsrec_combined latency_msec=1) && ` +
                      `MIC_MOD=$(pactl load-module module-loopback source=$(pactl get-default-source) sink=qsrec_combined latency_msec=1) && ` +
                      cmd + ` --audio=qsrec_combined.monitor` + audioCodecFlags +
                      ` ; pactl unload-module $MIC_MOD ; pactl unload-module $SYS_MOD ; pactl unload-module $NULL_MOD`
            } else {
                cmd += ` --audio` + audioCodecFlags
            }
        }
        WfRecorder.start(cmd, mode, filename)
        ServiceNotification.sendNotification("Recording Started", "Recording " + mode, "Recording", "camera-video")
    }

    function getFormattedRecordingTime() {
        return WfRecorder.formattedTime()
    }
}
