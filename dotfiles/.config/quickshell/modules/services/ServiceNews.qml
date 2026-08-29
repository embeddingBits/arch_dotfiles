pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.settings

// RSS headlines, fetched the same way ServiceWeather does it: curl through a
// Process, parsed in JS. RSS rather than a JSON API so any feed works without
// an account or key.
Singleton {
    id: root

    readonly property string feedUrl: SettingsConfig.widgets.newsFeedUrl
        ?? "https://feeds.bbci.co.uk/news/world/rss.xml"

    // Minutes between refreshes
    readonly property int refreshMinutes: SettingsConfig.widgets.newsRefreshMinutes ?? 30

    property var headlines: []          // [{ title, link }]
    property string channelTitle: ""
    property bool isLoading: false
    property bool hasError: false
    property var lastUpdated: null

    property int _refCount: 0
    function retain() { root._refCount++; if (root._refCount === 1) root.refresh() }
    function release() { root._refCount = Math.max(0, root._refCount - 1) }

    function refresh() {
        if (root.isLoading) return
        root.isLoading = true
        root.hasError = false
        newsProcess.command[2] = "curl -sL --max-time 15 " + JSON.stringify(root.feedUrl)
        newsProcess.running = true
    }

    Timer {
        interval: root.refreshMinutes * 60000
        repeat: true
        running: root._refCount > 0
        onTriggered: root.refresh()
    }

    function _unescape(s) {
        return s.replace(/<!\[CDATA\[/g, "")
                .replace(/\]\]>/g, "")
                .replace(/&lt;/g, "<").replace(/&gt;/g, ">")
                .replace(/&quot;/g, '"').replace(/&#0?39;/g, "'")
                .replace(/&apos;/g, "'").replace(/&amp;/g, "&")
                .replace(/<[^>]+>/g, "")
                .trim()
    }

    function _tag(block, name) {
        // [\s\S] rather than the s flag — Qt's JS engine is stricter about it
        const m = block.match(new RegExp("<" + name + "[^>]*>([\\s\\S]*?)</" + name + ">"))
        return m ? root._unescape(m[1]) : ""
    }

    function _parse(xml) {
        // Channel title sits before the first item
        const head = xml.split(/<item[\s>]/)[0]
        root.channelTitle = root._tag(head, "title")

        const chunks = xml.split(/<item[\s>]/).slice(1)
        const out = []
        for (let i = 0; i < chunks.length && out.length < 20; i++) {
            const title = root._tag(chunks[i], "title")
            if (title.length === 0) continue
            out.push({ title: title, link: root._tag(chunks[i], "link") })
        }
        root.headlines = out
        root.hasError = out.length === 0
        root.lastUpdated = new Date()
    }

    Process {
        id: newsProcess
        command: ["bash", "-c", ""]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) root._parse(text)
                else root.hasError = true
            }
        }

        onExited: function(code) {
            root.isLoading = false
            if (code !== 0) root.hasError = true
        }
    }
}
