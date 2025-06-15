return {
  'lmantw/themify.nvim',
    
  lazy = false,
  priority = 999,

  config = function()
            require('themify').setup({
            {"gbprod/nord.nvim"},
            {'AlexvZyl/nordic.nvim'},
            {"rmehri01/onenord.nvim"},
            {"sainnhe/gruvbox-material"},
            {"sainnhe/everforest"},
            })
            vim.keymap.set('n', '<leader>th', '<Cmd>Themify<CR>', {})
      end
}
