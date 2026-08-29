-- Nebula shell — required environment variables
-- Add these inside your ~/.config/hypr/lua/environment.lua (or equivalent).

-- Qt Wayland backend
hl.env("QT_QPA_PLATFORM",                     "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME",                "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR",         "1")

-- XDG desktop portal
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE",    "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Quickshell WfRecorder plugin path
hl.env("QML_IMPORT_PATH", os.getenv("HOME") .. "/.local/lib/qt6/qml")

-- Virtual env for gen_colors.py (Material You color engine)
hl.env("NEBULA_VENV", os.getenv("HOME") .. "/.local/state/quickshell/.venv")
