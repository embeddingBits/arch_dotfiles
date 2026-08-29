// Dynamic Path Generator for Layout Arcs
// Makes it easy to add new components with automatic arc generation

.pragma library

var ARC_CONFIG = {
    radiusX: 18,
    radiusY: 12,
    arcOffset: 20,
    gap: 8
}

/**
 * Generate SVG path for the entire layout
 * @param {Object} layout - Object containing component references and dimensions
 * @returns {String} SVG path string
 */
function generateLayoutPath(layout) {
    var path = ""
    var config = ARC_CONFIG

    // Start with outer boundary (fill area)
    path += "M 0 0 "
    path += "L " + layout.width + " 0 "
    path += "L " + layout.width + " " + layout.height + " "
    path += "L 0 " + layout.height + " "
    path += "L 0 0 "

    // Generate top bar path
    path += generateTopBarPath(layout, config)

    // Generate side components
    path += generateSideComponentsPath(layout, config)

    // Generate bottom components
    path += generateBottomComponentsPath(layout, config)

    return path
}

/**
 * Generate path for top bar components (horizontal sequence)
 */
function generateTopBarPath(layout, config) {
    var path = ""
    var components = []

    // Define top bar component sequence
    if (layout.workspaces) {
        components.push({
            name: "workspaces",
            x: layout.workspaces.x || 0,
            width: layout.workspaces.container.width,
            height: config.gap + config.arcHeight + config.arcHeight
        })
    }

    if (layout.clock) {
        components.push({
            name: "clock",
            x: layout.clock.x,
            width: layout.clock.container.width,
            height: config.gap + config.arcHeight + config.arcHeight
        })
    }

    if (layout.utility) {
        components.push({
            name: "utility",
            x: layout.utility.x,
            width: layout.utility.width,
            height: layout.utility.height
        })
    }

    // Start position after first component
    if (components.length > 0) {
        path += "M " + components[0].width + " " + (config.gap + config.arcHeight + config.arcHeight) + " "
    }

    // Generate arcs between components
    for (var i = 1; i < components.length; i++) {
        var prev = components[i - 1]
        var curr = components[i]

        // Arc out from previous
        path += arcRelative(config.arcOffset, -config.arcHeight, config.radiusX, config.arcHeight)

        // Line to current component
        path += "L " + (curr.x - config.arcOffset) + " " + config.gap + " "

        // Arc into current
        path += arcRelative(config.arcOffset, config.arcHeight, config.radiusX, config.arcHeight)

        // Line across component (except last one may need special handling)
        var widthAcross = (i === components.length - 1 && curr.name === "utility")
            ? curr.width - 28
            : curr.width
        path += "l " + widthAcross + " 0 "
    }

    return path
}

/**
 * Generate path for side components (like utility extending down and notifications)
 */
function generateSideComponentsPath(layout, config) {
    var path = ""

    if (!layout.utility) return path

    var utility = layout.utility

    // Utility extending down right side
    path += "l 0 " + (utility.height - config.arcOffset) + " "
    path += arcRelative(config.arcOffset, config.arcHeight, config.radiusX, config.arcHeight)

    // Space down to notification area
    var notifHeight = layout.notificationLoader && layout.isNotificationVisible
        ? layout.notificationLoader.height
        : 0

    var downDistance = layout.height - utility.height - notifHeight - 32 + (notifHeight > 0 ? 8 : 0)
    path += "l 0 " + downDistance + " "

    // Notification box if visible
    if (notifHeight > 0 && layout.notificationLoader) {
        path += arcRelative(-config.arcOffset, config.arcHeight, config.radiusX, config.arcHeight)
        path += "l 0 " + Math.max(0, notifHeight - 20) + " "
        path += "l " + (-Math.max(0, layout.notificationLoader.width - 26)) + " 0 "

        var notifArcHeight = Math.min(config.arcHeight, Math.max(0, notifHeight / 30))
        path += arcRelative(-config.arcOffset, notifArcHeight, config.radiusX, notifArcHeight)
    } else {
        path += arcRelative(-config.arcOffset, config.arcHeight, config.radiusX, config.arcHeight)
    }

    return path
}

/**
 * Generate path for bottom components (clipboard, appLauncher)
 */
function generateBottomComponentsPath(layout, config) {
    var path = ""

    // Clipboard
    if (layout.clipboardLoader) {
        var clipX = (layout.width - layout.clipboardLoader.width) / 2
        var clipH = layout.clipboardLoader.height

        path += "L " + (clipX + layout.clipboardLoader.width + config.arcOffset) + " " + (layout.height - config.gap) + " "

        var clipArcRadius = Math.max(0, Math.min(config.arcHeight, (clipH - 12) / 588 * config.arcHeight))
        path += arcRelative(-config.arcOffset, -clipArcRadius, config.radiusX, clipArcRadius)
        path += "l " + (-layout.clipboardLoader.width) + " 0 "
        path += arcRelative(-config.arcOffset, clipArcRadius, config.radiusX, clipArcRadius)
    }

    // Continue to app launcher area
    path += "L " + (config.gap + config.arcHeight + 6) + " " + (layout.height - config.gap) + " "
    path += arcRelative(-config.arcOffset, -config.arcHeight, config.radiusX, config.arcHeight)

    // App launcher
    if (layout.appLauncher) {
        var appX = layout.appLauncher.x
        var appY = layout.appLauncher.y
        var appW = layout.appLauncher.container.width
        var appH = layout.appLauncher.container.height

        path += "L " + (appX + config.gap) + " " + (appY + appH + config.arcHeight) + " "

        var appArcX = Math.max(0, Math.min(config.arcOffset, (appW - 8) / 292 * config.arcOffset))
        var appArcRadiusX = Math.max(0, Math.min(config.radiusX, (appW - 8) / 292 * config.radiusX))

        path += "A " + appArcRadiusX + " " + config.arcHeight + " 0 0 0 "
        path += (appX + config.gap + appArcX) + " " + (appY + appH) + " "

        path += "L " + (appX + config.gap + appArcX) + " " + appY + " "

        path += "A " + appArcRadiusX + " " + config.arcHeight + " 0 0 0 "
        path += (appX + config.gap) + " " + (appY - config.arcHeight) + " "
    }

    // Back to workspaces
    if (layout.workspaces) {
        path += "L " + (layout.workspaces.x + config.gap) + " "
            + (layout.workspaces.y + layout.workspaces.container.height + config.arcHeight) + " "

        path += arcRelative(config.arcOffset, -config.arcHeight, config.radiusX, config.arcHeight)
        path += "l 0 " + (-config.arcOffset) + " "
        path += "l " + (layout.workspaces.container.width - 30) + " 0 "
    }

    return path
}

/**
 * Helper: Generate relative arc command
 */
function arcRelative(dx, dy, rx, ry) {
    return "a " + rx + " " + ry + " 0 0 0 " + dx + " " + dy + " "
}

/**
 * Helper: Generate absolute arc command
 */
function arcAbsolute(x, y, rx, ry) {
    return "A " + rx + " " + ry + " 0 0 0 " + x + " " + y + " "
}
