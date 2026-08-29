pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

Singleton{
    id: root

    // Niri-backed implementation – keeps the same public API as the old
    // Hyprland version so callers don't need to change, but internally talks
    // to ServiceNiri (niri IPC via event-stream) instead of Hyprland.

    // Expose niri workspaces in a shape similar to Hyprland's for legacy callers.
    // New code should prefer ServiceNiri directly.
    property var workspaces: ServiceNiri.workspaces
    property var allWorkspaces: ServiceNiri.allWorkspaces

    function refreshToplevels(): void{
        // No-op on niri: Wayland ToplevelManager is reactive and ServiceNiri
        // windows are updated via event-stream. Kept for compatibility.
    }

    // Get workspace by idx (niri idx is 1-based per output). For compatibility
    // `index` is treated as idx. If the workspace for the current output does
    // not exist (niri has not created it yet) we return null – the caller
    // will then dispatch a focus that creates it.
    // Optionally pass outputName to disambiguate multi-monitor (idx duplicates per output).
    function getWorkspace(index: int, outputName: string): var {
        if (outputName !== undefined && outputName !== "") {
            return ServiceNiri.getWorkspaceByIdx(index, outputName)
        }
        // Try currentOutput first
        var ws = ServiceNiri.getWorkspaceByIdx(index, ServiceNiri.currentOutput)
        if (ws) return ws
        // Fallback: search any output with that idx (for global mode)
        for (var i = 0; i < ServiceNiri.allWorkspaces.length; i++) {
            if (ServiceNiri.allWorkspaces[i].idx === index) return ServiceNiri.allWorkspaces[i]
        }
        return null
    }

    // Legacy alias used by some components that expect HyprlandWorkspace shape.
    // We synthesize a compatible object: {id, idx, output, active, focused, urgent, monitor:{name}, toplevels}
    function getWorkspaceCompat(index: int, outputName: string): var {
        var ws = getWorkspace(index, outputName)
        if (!ws) return null
        // Build a Hyprland-like wrapper
        return {
            id: ws.idx, // expose idx as id for UI that uses id === idx
            niriId: ws.id,
            idx: ws.idx,
            output: ws.output,
            monitor: { name: ws.output },
            active: ws.is_active,
            focused: ws.is_focused,
            urgent: ws.is_urgent,
            // Provide toplevels lazily via helper – UI should prefer TopLevels niri path
            toplevels: getToplevelsForWorkspace(ws.idx, ws.output)
        }
    }

    // niri: idx is per-output. Dispatching focus-workspace <idx> focuses that
    // idx on the currently focused output (or the output that owns the workspace
    // when idx is ambiguous? niri chooses current output). For per-monitor bars
    // we need to ensure we focus the correct output. The simplest reliable way
    // is to just focus-workspace by idx – niri will focus the output that
    // contains that workspace if perMonitorMode and we are on that screen?
    // If we need output-specific focusing we could do: focus-monitor <output> then focus-workspace.
    // For now direct idx focus.
    function activateWorkspaceId(id): void {
        // id here is idx (1..workspaceCount)
        ServiceNiri.focusWorkspaceByIdx(id)
    }

    // Overload for output-aware activation (used by new Workspaces.qml)
    function activateWorkspace(idx, outputName): void {
        // If outputName differs from currentOutput, first focus that monitor
        // niri does not have a direct "focus output then workspace" but focusing
        // the workspace on that output should bring output focus as side-effect.
        // We attempt to focus via idx; if output mismatch, niri will still act on
        // currently focused output – so we prepend a monitor focus if needed.
        if (outputName && outputName !== ServiceNiri.currentOutput) {
            // Try to focus monitor first (best-effort, no-op if output not found)
            ServiceNiri.runAction(["focus-monitor", outputName])
            // small delay then focus workspace – use timer to sequence?
            // For now just focus workspace directly; niri's focus-workspace is per-output
            // but the reference "Index" is relative to current output. To focus workspace
            // on another output we need to ensure that output is focused first.
            // We'll queue both actions; ServiceNiri's pendingActions queue will serialize.
        }
        ServiceNiri.focusWorkspaceByIdx(idx)
    }

    // Move window to workspace. `address` may be:
    //  - niri window id (number)
    //  - Hyprland address string (hex)
    //  - Wayland Toplevel object
    //  - niri window object
    // We resolve to a niri window id via ServiceNiri matching.
    function moveWindowToWorkspace(address, workspaceId): void {
        if (!workspaceId) return
        var windowId = null

        if (typeof address === "number") {
            windowId = address
        } else if (typeof address === "string") {
            // Could be Hyprland hex address or numeric id string
            var asNum = parseInt(address, 10)
            if (!isNaN(asNum) && ServiceNiri.getWorkspaceById(asNum) === null) {
                // Check if it's a niri window id directly (numeric string)
                // Search windows for id match
                for (var i = 0; i < ServiceNiri.windows.length; i++) {
                    if (ServiceNiri.windows[i].id.toString() === address) { windowId = ServiceNiri.windows[i].id; break }
                }
                if (windowId === null && !isNaN(asNum)) windowId = asNum
            } else {
                // hex address – try to match via ToplevelManager is not accessible here;
                // fallback to focused window
                console.warn("[ServiceWorkspaces] moveWindowToWorkspace called with hex address", address, "– cannot map to niri window, using focused")
            }
        } else if (address && typeof address === "object") {
            // Could be Toplevel or niri window
            if (address.id !== undefined && address.app_id !== undefined) {
                // niri window object
                windowId = address.id
            } else {
                // Wayland Toplevel – try to match
                var nw = ServiceNiri.findNiriWindowForToplevel(address)
                if (nw) windowId = nw.id
                else if (address.wayland) {
                    nw = ServiceNiri.findNiriWindowForToplevel(address.wayland)
                    if (nw) windowId = nw.id
                }
                // Also check address.wayland.appId etc.
                if (!windowId && address.appId) {
                    nw = ServiceNiri.findNiriWindowForToplevel(address)
                    if (nw) windowId = nw.id
                }
            }
        }

        if (windowId !== null) {
            ServiceNiri.moveWindowToWorkspace(windowId, workspaceId)
        } else {
            console.warn("[ServiceWorkspaces] moveWindowToWorkspace could not resolve window", address, "moving focused window to", workspaceId)
            ServiceNiri.moveFocusedWindowToWorkspace(workspaceId)
        }
    }

    // Check if any workspace in the given array is active (visible on its output)
    function hasActiveWorkspace(workspaceIds): bool {
        for(var i = 0; i < workspaceIds.length; i++){
            var ws = getWorkspace(workspaceIds[i])
            if(ws && ws.is_active){
                return true
            }
        }
        return false
    }

    // Helper for TopLevels: get Wayland toplevels enriched for a workspace
    function getToplevelsForWorkspace(idx, outputName): var {
        var niriWins = ServiceNiri.getNiriWindowsForWorkspace(idx, outputName)
        // We need to map niri windows to Wayland Toplevels via ToplevelManager
        // This requires ToplevelManager access – but ServiceWorkspaces has no screen context.
        // Return niri windows directly as fallback; TopLevels.qml can handle both.
        return niriWins
    }
}

