pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import Quickshell.Widgets
import Quickshell.Wayland
import qs.modules.utils
import qs.modules.settings

Singleton{
    id: root
  
    property real scoreThreshold: 0.2
    property var allApplications: DesktopEntries.applications
    property real totalApps: allApplications.values.length
    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values)
    .sort((a, b) => a.name.localeCompare(b.name))   
    readonly property list<DesktopEntry> pinnedApps: list.filter(app => SettingsConfig.general.pinnedApps.includes(app.id))

    readonly property var dockModel: {
        const map = new Map()

        for (const id of SettingsConfig.general.pinnedApps) {
            map.set(id.toLowerCase(), { appId: id, pinned: true, toplevels: [] })
        }

        for (const toplevel of ToplevelManager.toplevels.values) {
            const appId = toplevel.appId?.toLowerCase() ?? ""
            if (!appId) continue
            if (!map.has(appId))
                map.set(appId, { appId: toplevel.appId, pinned: false, toplevels: [] })
            map.get(appId).toplevels.push(toplevel)
        }

        return Array.from(map.values())
    }

    property var displayableApps: {
        return allApplications.values.filter(function(app) {
            return !app.runInTerminal
        })
    }

    property var filteredApps: [...list]
    property string currentSearchText: ""
    property int selectedIndex: 0


    // Computed on first fuzzy search rather than at singleton creation (229 apps × Fuzzy.prepare)
    property var _preppedNames: null

    function _ensurePrepared() {
        if (!_preppedNames)
            _preppedNames = list.map(a => ({ name: Fuzzy.prepare(`${a.name} `), entry: a }))
        return _preppedNames
    }

    // Invalidate cache when app list changes
    onListChanged: _preppedNames = null

    function reset(): void{
        filteredApps = [...list]
    }


    function fuzzyQuery(search: string): var {
        if (root.sloppySearch) {
            const results = list.map(obj => ({
                entry: obj,
                score: Levendist.computeScore(obj.name.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
            .sort((a, b) => b.score - a.score)
            return results
            .map(item => item.entry)
        }

        return Fuzzy.go(search, _ensurePrepared(), {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }




    // dockModel holds plain objects, not DesktopEntry, so a launch has to
    // resolve the entry first
    function entryFor(appId: string): var {
        if (!appId) return null
        const direct = DesktopEntries.heuristicLookup(appId)
        if (direct) return direct
        const lower = appId.toLowerCase()
        return root.list.find(a => (a.id ?? "").toLowerCase() === lower) ?? null
    }

    function launch(appId: string): bool {
        const entry = root.entryFor(appId)
        if (!entry) {
            console.warn("ServiceApps.launch: no desktop entry for", appId)
            return false
        }
        entry.execute()
        return true
    }

    function isPinned(app): bool {
        return SettingsConfig.general.pinnedApps.includes(app.id)
    }

    function pin(app): void {
        if (!SettingsConfig.general.pinnedApps.includes(app.id))
            SettingsConfig.general = Object.assign({}, SettingsConfig.general, {pinnedApps: [...SettingsConfig.general.pinnedApps, app.id]})
    }

    function unpin(app): void {
        SettingsConfig.general = Object.assign({}, SettingsConfig.general, {pinnedApps: SettingsConfig.general.pinnedApps.filter(id => id !== app.id)})
    }

    function togglePin(app): void {
        if (isPinned(app)) unpin(app)
        else pin(app)
    }

    function isPinnedById(appId: string): bool {
        return SettingsConfig.general.pinnedApps.some(id => id.toLowerCase() === appId.toLowerCase())
    }

    function togglePinById(appId: string): void {
        if (isPinnedById(appId))
            SettingsConfig.general = Object.assign({}, SettingsConfig.general, {pinnedApps: SettingsConfig.general.pinnedApps.filter(id => id.toLowerCase() !== appId.toLowerCase())})
        else
            SettingsConfig.general = Object.assign({}, SettingsConfig.general, {pinnedApps: [...SettingsConfig.general.pinnedApps, appId]})
    }

    function updateSearch(searchText){
        currentSearchText = searchText
        selectedIndex = 0

        if (searchText.length > 0) {
            filteredApps = fuzzyQuery(searchText)
        } else {
            filteredApps = [...list]
        }
    }
}
