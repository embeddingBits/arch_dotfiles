return {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      config = function()

            local nord = require('lualine.themes.nord')

            -- Only override the 'normal' mode (you can tweak these)
            nord.normal.a.bg = '#5E81AC'  -- new background color for normal mode
            nord.normal.a.fg = '#2E3440'  -- new foreground color (text)
            nord.normal.a.gui = 'bold'
            nord.insert.a.bg = '#BF616A'  -- new background color for normal mode
            nord.insert.a.fg = '#2E3440'  -- new foreground color (text)
            nord.insert.a.gui = 'bold'


            require('lualine').setup {
                  options = {
                        icons_enabled = true,
                        theme = nord,
                        component_separators = { left = '|', right = '|'},
                        section_separators = { left = '', right = ''},
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
                              refresh_time = 16, -- ~60fps
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
                        }
                  },
                  sections = {
                        lualine_a = {'mode'},
                        lualine_b = {'branch', 'diff'},
                        lualine_c = {'filename'},
                        lualine_x = {'filetype'},
                        lualine_y = {'progress'},
                        lualine_z = {'location'}
                  },
            }
      end
}

