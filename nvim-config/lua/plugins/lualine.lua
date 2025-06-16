return {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      config = function()

            local nord = require('lualine.themes.nord')

            nord.normal.a.bg = '#81a1c1' 
            nord.normal.a.fg = '#2E3440'  
            nord.normal.a.gui = 'bold'
            nord.insert.a.bg = '#ba6a72'  
            nord.insert.a.fg = '#2E3440'  
            nord.insert.a.gui = 'bold'
            nord.command = {
                  a = {
                        fg = '#2E3440',
                        bg = '#D08770',
                        gui = 'bold',
                  }
            }


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
                        lualine_a = {
                              {
                                    'mode',
                                    icon = ' ',  -- before the mode text (use any Nerd Font icon)
                              }
                        },
                        lualine_b = {'branch', 'diff'},
                        lualine_c = {'filename'},
                        lualine_x = {'filetype'},
                        lualine_y = {'progress'},
                        lualine_z = {'location'}
                  },
            }
      end
}

