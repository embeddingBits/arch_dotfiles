-- General Hyprland settings
-- ~/.config/hypr/lua/settings.lua

local colors = require("lua.colors")

hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = { top = 50, right = 10, bottom = 10, left = 10 },

        border_size = 3,

        col = {
            active_border   = colors.active_border,
            inactive_border = colors.inactive_border,
        },

        layout           = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding           = 20,
        active_opacity     = 1.0,
        inactive_opacity   = 1.0,
        fullscreen_opacity = 1.0,

        blur = {
            enabled           = true,
            size              = 6,
            passes            = 2,
            new_optimizations = true,
            ignore_opacity    = true,
            xray              = true,
        },

        shadow = {
            enabled      = true,
            range        = 30,
            render_power = 3,
            color        = "0x66000000",
        },
    },

    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",

        numlock_by_default = true,
        follow_mouse       = 1,
        mouse_refocus      = false,

        sensitivity   = 0, -- -1.0 to 1.0, 0 = no modification

        touchpad = {
            natural_scroll = true,  -- natural (Mac-style) scrolling
            scroll_factor  = 1.0,
        },

        scroll_method = "2fg",
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        -- new_status = "master",
    },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles   = true,
        pass_mouse_when_bound    = false,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        initial_workspace_tracking = 1,
    },

    animations = {
        enabled = true,
    },
})

-- 3-finger horizontal swipe → switch workspace
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
