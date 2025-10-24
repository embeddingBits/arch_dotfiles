return {
      'lmantw/themify.nvim',

      lazy = false,
      priority = 999,
      config = function()
            local themify = require("themify")

            themify.setup({
                  { "ellisonleao/gruvbox.nvim" },
                  { "RRethy/base16-nvim" },
                  { "sainnhe/gruvbox-material" }

            })

            vim.keymap.set('n', '<leader>th', '<Cmd>Themify<CR>', {})
      end
}

