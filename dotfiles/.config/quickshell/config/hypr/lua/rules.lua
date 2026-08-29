-- Window rules, workspace rules, and layer rules
-- ~/.config/hypr/lua/rules.lua

-- ─── Window rules ─────────────────────────────────────────────────────────────

-- Float and center the Settings window
hl.window_rule({
    name  = "float-settings",
    match = { title = "^Settings$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "float-quickshell",
    match = { class = "^(org\\.)?[Qq]uickshell$" },
    float = true,
})

hl.window_rule({
    name   = "center-welcome",
    match  = { title = "^Nebula Setup$" },
    center = true,
})

-- Disable blur for empty-class XWayland context menus (prevents artifacts)
hl.window_rule({
    name  = "noblur-xwayland-menus",
    match = { class = "^$", title = "^$" },
    no_blur = true,
})

-- Fix XWayland drag issues
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Suppress maximize requests (most apps don't tile nicely when maximized)
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Floating utilities
hl.window_rule({ name = "float-blueberry",   match = { class = "^blueberry%.py$"              }, float = true })
hl.window_rule({ name = "float-pavucontrol", match = { class = "^pavucontrol$"                }, float = true, size = "45% 45%", center = true })
hl.window_rule({ name = "float-nm-editor",   match = { class = "^nm%-connection%-editor$"     }, float = true, size = "45% 45%", center = true })
hl.window_rule({ name = "float-zotero",      match = { class = "^Zotero$"                     }, float = true, size = "45% 45%" })
hl.window_rule({ name = "float-bluedevil",   match = { class = ".*bluedevilwizard"            }, float = true })
hl.window_rule({ name = "float-welcome",     match = { title = ".*Welcome"                    }, float = true })

-- Picture-in-Picture (browser video pop-out)
hl.window_rule({
    name             = "pip",
    match            = { title = "^[Pp]icture.?[Ii]n.?[Pp]icture.*$" },
    float            = true,
    pin              = true,
    move             = "73% 72%",
    size             = "25% 25%",
})

-- Common file/save dialogs — float and center
local dialog_titles = {
    "^Open File",
    "^Select a File",
    "^Choose wallpaper",
    "^Open Folder",
    "^Save As",
    "^Library",
    "^File Upload",
    ".*wants to save",
    ".*wants to open",
}
for i, pat in ipairs(dialog_titles) do
    hl.window_rule({
        name   = "float-dialog-" .. i,
        match  = { title = pat },
        float  = true,
        center = true,
    })
end

-- Tearing for games / Wine executables
hl.window_rule({ name = "immediate-exe",     match = { title = ".*%.exe"      }, immediate = true })
hl.window_rule({ name = "immediate-mc",      match = { title = ".*minecraft.*" }, immediate = true })
hl.window_rule({ name = "immediate-steam",   match = { class = "^steam_app.*"  }, immediate = true })

-- No shadow on tiled windows
hl.window_rule({
    name      = "noshadow-tiled",
    match     = { float = false },
    no_shadow = true,
})

-- ─── Workspace rules ──────────────────────────────────────────────────────────
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

-- ─── Layer rules ──────────────────────────────────────────────────────────────
-- Quickshell layers
hl.layer_rule({ name = "qs-blur",       match = { namespace = "quickshell:.*" }, blur = true        })
hl.layer_rule({ name = "qs-blurpopups", match = { namespace = "quickshell:.*" }, blur_popups = true })
hl.layer_rule({ name = "qs-alpha",      match = { namespace = "quickshell:.*" }, ignore_alpha = 0.79 })

hl.layer_rule({ name = "qs-bar-anim",       match = { namespace = "quickshell:bar"              }, animation = "slide top"    })
hl.layer_rule({ name = "qs-corners-anim",   match = { namespace = "quickshell:screenCorners"    }, animation = "fade"         })
hl.layer_rule({ name = "qs-sidebar-r-anim", match = { namespace = "quickshell:sidebarRight"     }, animation = "slide right"  })
hl.layer_rule({ name = "qs-sidebar-l-anim", match = { namespace = "quickshell:sidebarLeft"      }, animation = "slide left"   })
hl.layer_rule({ name = "qs-osk-anim",       match = { namespace = "quickshell:osk"              }, animation = "slide bottom" })
hl.layer_rule({ name = "qs-dock-anim",      match = { namespace = "quickshell:dock"             }, animation = "slide bottom" })
hl.layer_rule({ name = "qs-notif-anim",     match = { namespace = "quickshell:notificationPopup"}, animation = "fade"         })
hl.layer_rule({ name = "qs-overview-noanim",match = { namespace = "quickshell:overview"         }, no_anim = true             })
hl.layer_rule({ name = "qs-session-blur",   match = { namespace = "quickshell:session"          }, blur = true, no_anim = true, ignore_alpha = 0 })
hl.layer_rule({ name = "qs-bg-blur",        match = { namespace = "quickshell:backgroundWidgets"}, blur = true, ignore_alpha = 0.05 })
hl.layer_rule({ name = "qs-screenshot-noanim", match = { namespace = "quickshell:screenshot"    }, no_anim = true             })
hl.layer_rule({ name = "qs-corners-popin",  match = { namespace = "quickshell:screenCorners"    }, animation = "popin 120%"   })
hl.layer_rule({ name = "qs-lock-noanim",    match = { namespace = "quickshell:lockWindowPusher" }, no_anim = true             })
hl.layer_rule({ name = "qs-livetext-noanim", match = { namespace = "quickshell:livetext"       }, no_anim = true             })

-- Notification / GTK layer blur
hl.layer_rule({ name = "gtk-blur",        match = { namespace = "gtk%-layer%-shell" }, blur = true })
hl.layer_rule({ name = "notif-blur",      match = { namespace = "notifications"     }, blur = true, ignore_alpha = 0.69 })
hl.layer_rule({ name = "launcher-blur",   match = { namespace = "launcher"          }, blur = true, ignore_alpha = 0.5  })
hl.layer_rule({ name = "logout-blur",     match = { namespace = "logout_dialog"     }, blur = true })

-- No animation for pickers / overlays
hl.layer_rule({ name = "walker-noanim",   match = { namespace = "walker"    }, no_anim = true })
hl.layer_rule({ name = "anyrun-noanim",   match = { namespace = "anyrun"    }, no_anim = true })
hl.layer_rule({ name = "osk-noanim",      match = { namespace = "osk"       }, no_anim = true })
hl.layer_rule({ name = "picker-noanim",   match = { namespace = "hyprpicker"}, no_anim = true })

-- X-ray for all layers
hl.layer_rule({ name = "xray-all", match = { namespace = ".*" }, xray = true })
