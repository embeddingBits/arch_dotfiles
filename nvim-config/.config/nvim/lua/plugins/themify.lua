return {
      'lmantw/themify.nvim',

      lazy = false,
      priority = 999,
      config = function()
            local themify = require("themify")

            themify.setup({
                  -- Plugins (these get loaded automatically)
                  { "gbprod/nord.nvim" },
                  { "AlexvZyl/nordic.nvim" },
                  { "rmehri01/onenord.nvim" },
                  { "sainnhe/everforest" },
                  { "EdenEast/nightfox.nvim" },
                  { "RRethy/base16-nvim" },

            })

            vim.keymap.set('n', '<leader>th', '<Cmd>Themify<CR>', {})
      end
}

