-- Monitor and workspace configuration
-- ~/.config/hypr/lua/monitor.lua

-- Fallback: any monitor not explicitly listed uses preferred mode
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- External display (HDMI) — left side
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1,
})

-- Laptop internal display — right side
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "1920x0",
    scale    = 1,
})

-- Workspace → monitor assignments
-- Workspaces 1-5: external monitor
hl.workspace_rule({ workspace = "1",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "2",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "3",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "4",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "5",  monitor = "HDMI-A-1" })
-- Workspaces 6-10: laptop screen
hl.workspace_rule({ workspace = "6",  monitor = "eDP-1" })
hl.workspace_rule({ workspace = "7",  monitor = "eDP-1" })
hl.workspace_rule({ workspace = "8",  monitor = "eDP-1" })
hl.workspace_rule({ workspace = "9",  monitor = "eDP-1" })
hl.workspace_rule({ workspace = "10", monitor = "eDP-1" })
