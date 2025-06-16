return {
      {
            'goolord/alpha-nvim',
            config = function()
                  local alpha = require('alpha')
                  local dashboard = require("alpha.themes.dashboard")

                  dashboard.section.header.val = {
                        [[                                                                                                            ]],
                        [[                                                                                                            ]],
                        [[                                                                                                            ]],
                        [[                                                                                                            ]],
                        [[    ▓█████  ███▄ ▄███▓ ▄▄▄▄   ▓█████ ▓█████▄ ▓█████▄  ██▓ ███▄    █   ▄████  ▄▄▄▄    ██▓▄▄▄█████▓  ██████   ]],
                        [[    ▓█   ▀ ▓██▒▀█▀ ██▒▓█████▄ ▓█   ▀ ▒██▀ ██▌▒██▀ ██▌▓██▒ ██ ▀█   █  ██▒ ▀█▒▓█████▄ ▓██▒▓  ██▒ ▓▒▒██    ▒   ]],
                        [[    ▒███   ▓██    ▓██░▒██▒ ▄██▒███   ░██   █▌░██   █▌▒██▒▓██  ▀█ ██▒▒██░▄▄▄░▒██▒ ▄██▒██▒▒ ▓██░ ▒░░ ▓██▄     ]],
                        [[    ▒▓█  ▄ ▒██    ▒██ ▒██░█▀  ▒▓█  ▄ ░▓█▄   ▌░▓█▄   ▌░██░▓██▒  ▐▌██▒░▓█  ██▓▒██░█▀  ░██░░ ▓██▓ ░   ▒   ██▒  ]],
                        [[    ░▒████▒▒██▒   ░██▒░▓█  ▀█▓░▒████▒░▒████▓ ░▒████▓ ░██░▒██░   ▓██░░▒▓███▀▒░▓█  ▀█▓░██░  ▒██▒ ░ ▒██████▒▒  ]],
                        [[    ░░ ▒░ ░░ ▒░   ░  ░░▒▓███▀▒░░ ▒░ ░ ▒▒▓  ▒  ▒▒▓  ▒ ░▓  ░ ▒░   ▒ ▒  ░▒   ▒ ░▒▓███▀▒░▓    ▒ ░░   ▒ ▒▓▒ ▒ ░  ]],
                        [[     ░ ░  ░░  ░      ░▒░▒   ░  ░ ░  ░ ░ ▒  ▒  ░ ▒  ▒  ▒ ░░ ░░   ░ ▒░  ░   ░ ▒░▒   ░  ▒ ░    ░    ░ ░▒  ░ ░  ]],
                        [[       ░   ░      ░    ░    ░    ░    ░ ░  ░  ░ ░  ░  ▒ ░   ░   ░ ░ ░ ░   ░  ░    ░  ▒ ░  ░      ░  ░  ░    ]],
                        [[       ░  ░       ░    ░         ░  ░   ░       ░     ░           ░       ░  ░       ░                 ░  ]],
                        [[                            ░         ░       ░                                   ░                       ]],
                        [[                                                                                                          ]],
                        [[                  “One man's magic is another man's engineering, 'Supernatural' is a null word”           ]],
                        [[                                                                                             - Robert Heinlein]]
                  }

                  dashboard.section.buttons.val = {
                        dashboard.button("SPC n", "  New File", ":enew<CR>"),
                        dashboard.button("SPC f f", "󰈞  Find File", ":Telescope find_files<CR>"),
                        dashboard.button("SPC o", "  Open Project", ":cd ~/Projects<CR>"),
                        dashboard.button("SPC f g", "  Find Word", ":Telescope live_grep<CR>"),
                        dashboard.button("q", "󰗼  Quit", ":qa<CR>"),
                  }

                  dashboard.section.footer.val = {
                                    "Engineers aren’t boring people. We just get excited about boring things."
                  }


                  alpha.setup(dashboard.opts)
            end
      }
}

