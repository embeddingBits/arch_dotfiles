return {
      'nvim-treesitter/nvim-treesitter',
      lazy = false,
      build = ':TSUpdate',
      config = function()
            require('nvim-treesitter').setup {
                  highlight = { enable = true },
                  indent = { enable = true },
            }
      end,
}
