-- Hyprland Lua Configuration (requires Hyprland >= 0.55)
-- Entry point — loads all modules in order
-- ~/.config/hypr/hyprland.lua

require("lua.environment") -- env vars must come first
require("lua.colors")      -- pywal colors (used by settings)
require("lua.monitor")     -- monitor + workspace assignments
require("lua.autostart")   -- exec-once startup programs
require("lua.settings")    -- general, decoration, input, misc, layouts
require("lua.animations")  -- bezier curves + animations
require("lua.keybinds")    -- key bindings
require("lua.rules")       -- window / layer rules
