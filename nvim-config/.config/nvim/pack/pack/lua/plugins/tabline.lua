return {
  'romgrk/barbar.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
  },
  config = function()
    -- Corrected highlight group names
    vim.api.nvim_set_hl(0, 'BufferLineSeparator', { fg = '#434c5e', bg = '#434c5e' })
    vim.api.nvim_set_hl(0, 'BufferLineSeparatorVisible', { fg = '#434c5e', bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'BufferLineSeparatorInactive', { fg = '#434c5e', bg = 'NONE' })

    require'barbar'.setup {
      icons = {
        separator = { left = '', right = '' }, -- Rounded separators
        separator_at_end = true, -- Ensure separators are visible at the end
      },
    }

    -- Keybindings for navigating buffers
    vim.api.nvim_set_keymap('n', '<Tab>', '<Cmd>BufferNext<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<S-Tab>', '<Cmd>BufferPrevious<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '<leader>x', '<Cmd>BufferClose<CR>', { noremap = true, silent = true })
  end,
}

