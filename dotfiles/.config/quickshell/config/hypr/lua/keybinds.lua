-- Key bindings
-- ~/.config/hypr/lua/keybinds.lua
-- ML4W scripts replaced with direct commands.

local mainMod    = "SUPER"
local SCRIPTS    = "~/.config/hypr/scripts"

-- Direct app commands
local terminal    = "kitty"
local browser     = "firefox"
local filemanager = "nautilus --new-window"
local calculator  = "gnome-calculator"

-- ─── Quickshell global shortcuts ─────────────────────────────────────────────
-- hl.dsp.global() is the native global dispatcher (available in 0.55+).
hl.bind(mainMod .. " + W",             hl.dsp.global("quickshell:wallpaperLauncher"))
hl.bind(mainMod .. " + L",             hl.dsp.global("quickshell:lock"),       { locked = true })
hl.bind(mainMod .. " + SHIFT + S",     hl.dsp.global("quickshell:shutdown"),   { locked = true })
hl.bind(mainMod .. " + CTRL + RETURN", hl.dsp.global("quickshell:appLauncher"))
hl.bind(mainMod .. " + S",             hl.dsp.global("quickshell:toolsWidget"))
hl.bind(mainMod .. " + V",             hl.dsp.global("quickshell:clipboard"))
hl.bind(mainMod .. " + CTRL + S",      hl.dsp.global("quickshell:settingOpen"))
hl.bind(mainMod .. " + SHIFT + W",     hl.dsp.global("quickshell:welcome"))
hl.bind(mainMod .. " + O",             hl.dsp.global("quickshell:ocr"))

-- ─── Applications ─────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + RETURN",   hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B",        hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + E",        hl.dsp.exec_cmd(filemanager))
hl.bind(mainMod .. " + CTRL + C", hl.dsp.exec_cmd(calculator))

-- ─── Window management ────────────────────────────────────────────────────────
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("bash -c 'hyprctl activewindow | grep pid | tr -d \" pid:\" | xargs kill'"))
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + T",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"))
hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + G",         hl.dsp.group.toggle())
hl.bind(mainMod .. " + K",         hl.dsp.exec_cmd("hyprctl dispatch swapsplit"))

-- Focus direction
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Resize active window with keyboard
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 100 0"),  { repeating = true })
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive -100 0"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 100"),  { repeating = true })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -100"), { repeating = true })

-- Swap tiled windows
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.swap({ direction = "d" }))

-- Cycle windows (Alt+Tab): both binds fire together (cycle + raise)
hl.bind("ALT + Tab", hl.dsp.window.cycle_next(),   { repeating = true })
hl.bind("ALT + Tab", hl.dsp.window.bring_to_top(), { repeating = true })

-- ─── Actions ──────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + CTRL + R",  hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(SCRIPTS .. "/toggle-animations.sh"))
hl.bind(mainMod .. " + PRINT",     hl.dsp.exec_cmd(SCRIPTS .. "/screenshot.sh"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("waypaper --random"))
hl.bind(mainMod .. " + ALT + W",   hl.dsp.exec_cmd(SCRIPTS .. "/wallpaper-automation.sh"))
hl.bind(mainMod .. " + CTRL + K",  hl.dsp.exec_cmd(SCRIPTS .. "/keybindings.sh"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(SCRIPTS .. "/loadconfig.sh"))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd(SCRIPTS .. "/hyprshade.sh"))
hl.bind(mainMod .. " + ALT + G",   hl.dsp.exec_cmd(SCRIPTS .. "/gamemode.sh"))
hl.bind(mainMod .. " + CTRL + L",  hl.dsp.exec_cmd(SCRIPTS .. "/power.sh lock"))

-- ─── Workspaces ───────────────────────────────────────────────────────────────
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i,   hl.dsp.window.move({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. i,    hl.dsp.exec_cmd(SCRIPTS .. "/moveTo.sh " .. i))
end
-- Workspace 10 maps to key 0
hl.bind(mainMod .. " + 0",          hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0",  hl.dsp.window.move({ workspace = 10 }))
hl.bind(mainMod .. " + CTRL + 0",   hl.dsp.exec_cmd(SCRIPTS .. "/moveTo.sh 10"))

-- Navigate workspaces
hl.bind(mainMod .. " + Tab",         hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + mouse_down",  hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",    hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + CTRL + down", hl.dsp.focus({ workspace = "empty" }))

-- ─── Function / media keys ────────────────────────────────────────────────────
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -q s +10%"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q s 10%-"), { repeating = true })

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("bash -c 'pactl set-sink-mute @DEFAULT_SINK@ 0 && pactl set-sink-volume @DEFAULT_SINK@ +5%'"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("bash -c 'pactl set-sink-mute @DEFAULT_SINK@ 0 && pactl set-sink-volume @DEFAULT_SINK@ -5%'"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl pause"),      { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

hl.bind("XF86Calculator", hl.dsp.exec_cmd(calculator))
hl.bind("XF86ScreenSaver", hl.dsp.exec_cmd("hyprlock"), { locked = true })

-- Keyboard backlight
hl.bind("code:238", hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight s +10"), { repeating = true })
hl.bind("code:237", hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight s 10-"), { repeating = true })
