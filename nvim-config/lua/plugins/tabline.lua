return {
  'romgrk/barbar.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
  },
  config = function()
    -- Keymaps for switching tabs
    vim.api.nvim_set_keymap('n', '<Tab>', '<Cmd>BufferNext<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<S-Tab>', '<Cmd>BufferPrevious<CR>', { noremap = true, silent = true })
  end,
}

