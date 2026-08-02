return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()

    -- Icons from nvimrc (lua/hieulw/icons.lua)
    local icons = {
      git = {
        LineAdded = "",
        LineModified = "",
        LineRemoved = "",
      },
      diagnostics = {
        Error = " ",
        Warning = " ",
        Info = " ",
        Hint = " ",
      },
    }

    -- Default colors of the active colorscheme, with bold font
    local function get_theme()
      local loader = require('lualine.utils.loader')
      local ok, theme = pcall(loader.load_theme, 'auto')
      if not ok then
        theme = require('lualine.themes.auto')
      end
      for _, section in pairs(theme) do
        if type(section) == 'table' then
          for _, state in pairs(section) do
            if type(state) == 'table' then
              state.gui = 'bold'
            end
          end
        end
      end
      return theme
    end

    local diff = {
      'diff',
      source = function()
        local gitsigns = vim.b.gitsigns_status_dict
        if gitsigns then
          return {
            added = gitsigns.added,
            modified = gitsigns.changed,
            removed = gitsigns.removed,
          }
        end
      end,
      symbols = {
        added = icons.git.LineAdded .. ' ',
        modified = icons.git.LineModified .. ' ',
        removed = icons.git.LineRemoved .. ' ',
      },
      colored = true,
      always_visible = false,
    }

    local diagnostics = {
      'diagnostics',
      sources = { 'nvim_diagnostic' },
      sections = { 'error', 'warn', 'info', 'hint' },
      symbols = {
        error = icons.diagnostics.Error,
        hint = icons.diagnostics.Hint,
        info = icons.diagnostics.Info,
        warn = icons.diagnostics.Warning,
      },
      colored = true,
      update_in_insert = false,
      always_visible = false,
    }

    require('lualine').setup {
      options = {
        icons_enabled = true,
        theme = get_theme,
        component_separators = { left = '|', right = '|' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {
          statusline = {},
          winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        always_show_tabline = true,
        globalstatus = false,
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
          refresh_time = 16,
          events = {
            'WinEnter',
            'BufEnter',
            'BufWritePost',
            'SessionLoadPost',
            'FileChangedShellPost',
            'VimResized',
            'Filetype',
            'CursorMoved',
            'CursorMovedI',
            'ModeChanged',
          },
        },
      },
      sections = {
        lualine_a = {
          {
            'mode',
          },
        },
        lualine_b = {
          {
            'buffers',
            symbols = {
              modified = ' ●',
              alternate_file = '',
              directory = '',
            },
            mode = 0,
          },
        },
        lualine_c = {
          'filename',
        },
        lualine_x = { 'branch', diff, diagnostics, 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
    }
  end,
}
