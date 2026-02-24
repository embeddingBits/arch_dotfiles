return {
  'nvim-orgmode/orgmode',
  event = 'VeryLazy',
  config = function()
    -- Setup orgmode
    require('orgmode').setup({
      org_default_notes_file = '~/TODO',
    })
    -- Experimental LSP support
    vim.lsp.enable('org')
  end,
}
