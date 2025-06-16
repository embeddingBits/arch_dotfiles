return {
  {
    'goolord/alpha-nvim',
    config = function()
      local alpha = require('alpha')
      local dashboard = require("alpha.themes.dashboard")

      dashboard.section.header.val = {
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
        "I still write code, but now it runs closer to the hardware because the Embedded Chose Me"
      }

      alpha.setup(dashboard.opts)
    end
  }
}

