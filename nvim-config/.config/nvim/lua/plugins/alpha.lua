return {
  'goolord/alpha-nvim',
  event = 'VimEnter',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local alpha = require('alpha')
    local dashboard = require('alpha.themes.dashboard')

    -- make sure leader is space (set this in your core options too, not just here)
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    dashboard.section.header.val = {
      "█▀▀▀▀▀▀▀▀▀▀▀▀▀█",
      "▀   ░░░░░░░   ▀",
      "   ░▒▒▒▒▒▒▒░",
      "   ▒▓▓▓▓▓▓▓▒",
      "   ░▒▓███▓▒░",
      "   ▒▓▓▓▓▓▓▓▒",
      "   ░▒▒▒▒▒▒▒░",
      "▄   ░░░░░░░   ▄",
      "█▄▄▄▄▄▄▄▄▄▄▄▄▄█",
    }

    -- keys: the REAL leader-key sequence (without <leader>) e.g. "ff", "fr"
    -- label: what shows on screen, auto-prefixed with "SPC "
    local function spc_button(keys, desc, action)
      local spaced = keys:gsub("(.)", "%1 "):gsub("%s+$", "") -- "ff" -> "f f"
      local btn = dashboard.button("<leader>" .. keys, "  SPC " .. spaced .. "  " .. desc, action)
      btn.opts.hl = "Keyword"
      btn.opts.hl_shortcut = "Number"
      return btn
    end

    dashboard.section.buttons.val = {
      spc_button("ff", "Find file",    ":Telescope find_files <CR>"),
      spc_button("fr", "Recent files", ":Telescope oldfiles <CR>"),
      spc_button("fg", "Find text",    ":Telescope live_grep <CR>"),
      spc_button("fn", "New file",     ":ene <BAR> startinsert <CR>"),
      spc_button("fc", "Config",       ":e $MYVIMRC <CR>"),
      spc_button("qq", "Quit",         ":qa <CR>"),
    }

    dashboard.section.footer.val = "the void collapses inward"

    dashboard.section.header.opts.hl = "Type"
    dashboard.section.footer.opts.hl = "Comment"

    alpha.setup(dashboard.opts)

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "alpha",
      callback = function()
        vim.opt_local.foldenable = false
      end,
    })
  end,
}
