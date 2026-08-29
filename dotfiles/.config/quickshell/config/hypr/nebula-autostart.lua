-- Nebula shell — autostart additions
-- Add these lines inside the hl.on("hyprland.start", ...) block
-- in your ~/.config/hypr/lua/autostart.lua (or equivalent).

-- Wallpaper daemon (required for animated transitions)
hl.exec_cmd("awww-daemon")

-- Clipboard history daemon
hl.exec_cmd("wl-paste --watch cliphist store")

-- Nebula shell (Quickshell)
hl.exec_cmd("QSG_RENDER_LOOP=threaded quickshell")
