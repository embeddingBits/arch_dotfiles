return {
      'lmantw/themify.nvim',

      lazy = false,
      priority = 999,
      config = function()
            local themify = require("themify")

            themify.setup({
                  -- Plugins (these get loaded automatically)
                  { "gbprod/nord.nvim" },
                  { "EdenEast/nightfox.nvim" },
                  { "catppuccin/nvim" },
                  { "folke/tokyonight.nvim"}

            })

            vim.keymap.set('n', '<leader>th', '<Cmd>Themify<CR>', {})
      end
}

