return {
      {
            'goolord/alpha-nvim',
            config = function()
                  local alpha = require("alpha")
                  local dashboard = require("alpha.themes.dashboard")

                  -- Define gradient highlight groups
                  vim.cmd([[
        highlight Grad1 guifg=#8FBCBB
        highlight Grad2 guifg=#88C0D0
        highlight Grad3 guifg=#81A1C1
        highlight Grad4 guifg=#5E81AC
        highlight Grad5 guifg=#BF616A
        highlight Grad6 guifg=#D08770
        highlight Grad7 guifg=#EBCB8B
        highlight Grad8 guifg=#E5A76B
        highlight Grad9 guifg=#D9776F
        highlight Grad10 guifg=#D08770
        ]])
                  -- ASCII Art split with highlight per line
                  local header = {
                        { type = "text", val = [[▓█████  ███▄ ▄███▓ ▄▄▄▄   ▓█████ ▓█████▄ ▓█████▄  ██▓ ███▄    █   ▄████  ▄▄▄▄    ██▓▄▄▄█████▓  ██████ ]], opts = { hl = "Grad1", position = "center" } },
                        { type = "text", val = [[▓█   ▀ ▓██▒▀█▀ ██▒▓█████▄ ▓█   ▀ ▒██▀ ██▌▒██▀ ██▌▓██▒ ██ ▀█   █  ██▒ ▀█▒▓█████▄ ▓██▒▓  ██▒ ▓▒▒██    ▒ ]], opts = { hl = "Grad2", position = "center" } },
                        { type = "text", val = [[▒███   ▓██    ▓██░▒██▒ ▄██▒███   ░██   █▌░██   █▌▒██▒▓██  ▀█ ██▒▒██░▄▄▄░▒██▒ ▄██▒██▒▒ ▓██░ ▒░░ ▓██▄   ]], opts = { hl = "Grad3", position = "center" } },
                        { type = "text", val = [[▒▓█  ▄ ▒██    ▒██ ▒██░█▀  ▒▓█  ▄ ░▓█▄   ▌░▓█▄   ▌░██░▓██▒  ▐▌██▒░▓█  ██▓▒██░█▀  ░██░░ ▓██▓ ░   ▒   ██▒]], opts = { hl = "Grad4", position = "center" } },
                        { type = "text", val = [[░▒████▒▒██▒   ░██▒░▓█  ▀█▓░▒████▒░▒████▓ ░▒████▓ ░██░▒██░   ▓██░░▒▓███▀▒░▓█  ▀█▓░██░  ▒██▒ ░ ▒██████▒▒]], opts = { hl = "Grad5", position = "center" } },
                        { type = "text", val = [[░░ ▒░ ░░ ▒░   ░  ░░▒▓███▀▒░░ ▒░ ░ ▒▒▓  ▒  ▒▒▓  ▒ ░▓  ░ ▒░   ▒ ▒  ░▒   ▒ ░▒▓███▀▒░▓    ▒ ░░   ▒ ▒▓▒ ▒ ░]], opts = { hl = "Grad6", position = "center" } },
                        { type = "text", val = [[ ░ ░  ░░  ░      ░▒░▒   ░  ░ ░  ░ ░ ▒  ▒  ░ ▒  ▒  ▒ ░░ ░░   ░ ▒░  ░   ░ ▒░▒   ░  ▒ ░    ░    ░ ░▒  ░ ░]], opts = { hl = "Grad7", position = "center" } },
                        { type = "text", val = [[   ░   ░      ░    ░    ░    ░    ░ ░  ░  ░ ░  ░  ▒ ░   ░   ░ ░ ░ ░   ░  ░    ░  ▒ ░  ░      ░  ░  ░  ]], opts = { hl = "Grad8", position = "center" } },
                        { type = "text", val = [[   ░  ░       ░    ░         ░  ░   ░       ░     ░           ░       ░  ░       ░                 ░  ]], opts = { hl = "Grad9", position = "center" } },
                        { type = "text", val = [[                        ░         ░       ░                                   ░                        ]], opts = { hl = "Grad10", position = "center" } },
                        { type = "text", val = [[                                                                                                        ]], opts = { hl = "Grad6", position = "center" } },
                        { type = "text", val = [[      "One man's magic is another man's engineering, 'Supernatural' is a null word"       ]], opts = { hl = "Grad3", position = "center" } },
                        { type = "text", val = [[                                                                           -- Robert Heinlein]], opts = { hl = "Grad3", position = "center" } },
                  }

                  dashboard.section.header = {
                        type = "group",
                        val = vim.tbl_extend("force", {
                              { type = "padding", val = 1 },
                        }, header),
                        opts = {},
                  }

                  -- Buttons
                  dashboard.section.buttons = {
                        type = "group",
                        val = {
                              dashboard.button("SPC n", "  New File", ":enew<CR>"),
                              dashboard.button("SPC f f", "󰈞  Find File", ":Telescope find_files<CR>"),
                              dashboard.button("SPC o", "  Open Project", ":cd ~/Projects<CR>"),
                              dashboard.button("SPC f g", "  Find Word", ":Telescope live_grep<CR>"),
                              dashboard.button("q", "󰗼  Quit", ":qa<CR>"),
                        },
                        opts = { spacing = 1 },
                  }

                  -- Final layout
                  dashboard.config.layout = {
                        { type = "padding", val = 2 },
                        dashboard.section.header,
                        { type = "padding", val = 1 },
                        dashboard.section.buttons,
                        { type = "padding", val = 1 },
                        dashboard.section.footer,
                  }

                  alpha.setup(dashboard.config)
            end
      }
}

