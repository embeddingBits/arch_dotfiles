return {
      'lmantw/themify.nvim',

      lazy = false,
      priority = 999,
      config = function()
            local themify = require("themify")

            themify.setup({
                  { "sainnhe/gruvbox-material" },
                  { "ellisonleao/gruvbox.nvim" },
                  { "RRethy/base16-nvim" },

            })

            vim.keymap.set('n', '<leader>th', '<Cmd>Themify<CR>', {})
      end
}

