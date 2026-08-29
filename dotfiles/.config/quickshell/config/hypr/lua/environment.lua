-- Environment variables
-- ~/.config/hypr/lua/environment.lua

-- XDG Desktop Portal (screen sharing, file picker)
hl.env("XDG_CURRENT_DESKTOP",  "Hyprland")
hl.env("XDG_SESSION_TYPE",     "wayland")
hl.env("XDG_SESSION_DESKTOP",  "Hyprland")

-- Qt
hl.env("QT_QPA_PLATFORM",                    "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME",               "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION","1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR",        "1")

-- GDK / GTK
hl.env("GDK_SCALE",    "1")
hl.env("GDK_BACKEND",  "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")

-- Mozilla / Firefox
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Cursor
hl.env("XCURSOR_SIZE",    "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Ozone (Electron / Chromium apps)
hl.env("OZONE_PLATFORM",               "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-- SDL
hl.env("SDL_VIDEODRIVER", "wayland")

-- Input method (fcitx5)
hl.env("QT_IM_MODULE",   "fcitx")
hl.env("XMODIFIERS",     "@im=fcitx")
hl.env("SDL_IM_MODULE",  "fcitx")
hl.env("GLFW_IM_MODULE", "ibus")
hl.env("INPUT_METHOD",   "fcitx")

-- QML import path + Nebula venv (quickshell)
hl.env("QML_IMPORT_PATH", os.getenv("HOME") .. "/.local/lib/qt6/qml")
hl.env("NEBULA_VENV",     os.getenv("HOME") .. "/.local/state/quickshell/.venv")
