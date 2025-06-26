return {
      'goolord/alpha-nvim',
      config = function ()
            local alpha = require('alpha')
            local dashboard = require('alpha.themes.dashboard')

            -- Replace this with your custom ASCII art
            dashboard.section.header.val = {
                  "                                                                                                     ",
                  "                                                                                                     ",
                  "███████╗███╗   ███╗██████╗ ███████╗██████╗ ██████╗ ██╗███╗   ██╗ ██████╗ ██████╗ ██╗████████╗███████╗",
                  "██╔════╝████╗ ████║██╔══██╗██╔════╝██╔══██╗██╔══██╗██║████╗  ██║██╔════╝ ██╔══██╗██║╚══██╔══╝██╔════╝",
                  "█████╗  ██╔████╔██║██████╔╝█████╗  ██║  ██║██║  ██║██║██╔██╗ ██║██║  ███╗██████╔╝██║   ██║   ███████╗",
                  "██╔══╝  ██║╚██╔╝██║██╔══██╗██╔══╝  ██║  ██║██║  ██║██║██║╚██╗██║██║   ██║██╔══██╗██║   ██║   ╚════██║",
                  "███████╗██║ ╚═╝ ██║██████╔╝███████╗██████╔╝██████╔╝██║██║ ╚████║╚██████╔╝██████╔╝██║   ██║   ███████║",
                  "╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚═╝   ╚═╝   ╚══════╝",
                  "                                                                                                     ",
                  "           One man's magic is another man's engineering, Supernatural is a null world                ",
                  "                                                                       - Robert Heinlein             ",
                  "                                                                                                     ",
            }

            -- Optionally set colors or other customizations
            dashboard.section.buttons.val = {
                  dashboard.button("SPC n", "  New File", ":enew<CR>"),
                  dashboard.button("SPC f f", "󰈞  Find File", ":Telescope find_files<CR>"),
                  dashboard.button("SPC o", "  Open Project", ":cd ~/Projects<CR>"),
                  dashboard.button("SPC f g", "  Find Word", ":Telescope live_grep<CR>"),
                  dashboard.button("q", "󰗼  Quit", ":qa<CR>"),}

            -- Set your custom header as part of the configuration
            alpha.setup(dashboard.config)
      end
}

