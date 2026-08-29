pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    property var monitors: Hyprland.monitors

    property var monitorList: {
        if (!monitors || !monitors.values) return []

        return monitors.values.map(monitor => {
            const data = monitor.lastIpcObject

            const parsedModes = (data.availableModes || []).map(mode => {
                const match = mode.match(/^(\d+)x(\d+)@([\d.]+)Hz$/)
                if (!match) {
                    console.warn("Failed to parse mode:", mode)
                    return null
                }

                const parsed = {
                    mode: mode,
                    width: parseInt(match[1]),
                    height: parseInt(match[2]),
                    resolution: `${match[1]}x${match[2]}`,
                    refreshRate: parseFloat(match[3]),
                    refreshRateFormatted: `${parseFloat(match[3]).toFixed(2)} Hz`
                }
                return parsed
            }).filter(m => m !== null)

            

            // Extract unique resolutions
            const resolutionSet = new Set()
            const availableResolutions = []
            parsedModes.forEach(mode => {
                if (!resolutionSet.has(mode.resolution)) {
                    resolutionSet.add(mode.resolution)
                    availableResolutions.push({ name: mode.resolution })
                }
            })

            // Extract all unique refresh rates (across all resolutions)
            const refreshRateSet = new Set()
            const availableRefreshRates = []
            parsedModes.forEach(mode => {
                if (!refreshRateSet.has(mode.refreshRateFormatted)) {
                    refreshRateSet.add(mode.refreshRateFormatted)
                    availableRefreshRates.push({ name: mode.refreshRateFormatted })
                }
            })

            return {
                id: data.id || 0,
                name: data.name || "",
                description: data.description || "",
                make: data.make || "",
                model: data.model || "",
                serial: data.serial || "",

                width: data.width || 0,
                height: data.height || 0,
                resolution: `${data.width || 0}x${data.height || 0}`,

                refreshRate: data.refreshRate ? data.refreshRate.toFixed(2) : "0.00",
                refreshRateRaw: data.refreshRate || 0,

                physicalWidth: data.physicalWidth || 0,
                physicalHeight: data.physicalHeight || 0,

                x: data.x || 0,
                y: data.y || 0,
                position: `${data.x || 0}, ${data.y || 0}`,

                scale: data.scale || 1.0,
                transform: data.transform || 0,

                focused: data.focused || false,
                dpmsStatus: data.dpmsStatus || false,
                vrr: data.vrr || false,
                disabled: data.disabled || false,

                currentFormat: data.currentFormat || "",
                mirrorOf: data.mirrorOf || "none",

                colorManagementPreset: data.colorManagementPreset || "srgb",
                sdrBrightness: data.sdrBrightness || 1.0,
                sdrSaturation: data.sdrSaturation || 1.0,
                sdrMinLuminance: data.sdrMinLuminance || 0.2,
                sdrMaxLuminance: data.sdrMaxLuminance || 80,

                availableModes: parsedModes,
                availableResolutions: availableResolutions,
                availableRefreshRates: availableRefreshRates,

                activeWorkspace: data.activeWorkspace || { id: 0, name: "" },

                activelyTearing: data.activelyTearing || false,
                tearingBlockedBy: data.tearingBlockedBy || [],

                directScanoutTo: data.directScanoutTo || "0",
                directScanoutBlockedBy: data.directScanoutBlockedBy || [],

                solitary: data.solitary || "0",
                solitaryBlockedBy: data.solitaryBlockedBy || []
            }
        })
    }

    // Get refresh rates for a specific monitor and resolution
    function getRefreshRatesForResolution(monitorName, resolution) {
        const monitor = monitorList.find(m => m.name === monitorName)
        if (!monitor || !monitor.availableModes) return []

        const rates = new Set()
        const result = []

        monitor.availableModes.forEach(mode => {
            if (mode.resolution === resolution && !rates.has(mode.refreshRateFormatted)) {
                rates.add(mode.refreshRateFormatted)
                result.push({ name: mode.refreshRateFormatted })
            }
        })

        return result
    }

    // Get monitor by name
    function getMonitor(name) {
        return monitorList.find(m => m.name === name) || null
    }

}
