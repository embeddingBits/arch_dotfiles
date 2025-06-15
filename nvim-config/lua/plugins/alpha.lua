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
        [[                  "Engineers aren’t boring people. We just get excited about boring things."]]
      }

      dashboard.section.footer.val = {
        "I still write code. But now, it runs closer to hardware — where every bit counts because the Embedded Chose me"
      }

      alpha.setup(dashboard.opts)
    end
  }
}

