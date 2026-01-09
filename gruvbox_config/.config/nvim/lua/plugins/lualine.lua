return {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      config = function()

            local gruvbox = require('lualine.themes.gruvbox')

            gruvbox.normal.a.bg = '#83a598'
            gruvbox.normal.a.fg = '#1d2021'
            gruvbox.normal.a.gui = 'bold'
            gruvbox.insert.a.bg = '#a9b665'
            gruvbox.insert.a.fg = '#1d2021'
            gruvbox.insert.a.gui = 'bold'
            gruvbox.visual.a.bg = '#d3869b'
            gruvbox.visual.a.fg = '#1d2021'
            gruvbox.visual.a.gui = 'bold'
            gruvbox.command = {
                  a = {
                        fg = '#1d2021',
                        bg = '#ea6962',
                        gui = 'bold',
                  }
            }


            require('lualine').setup {
                  options = {
                        icons_enabled = true,
                        theme = gruvbox,
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
                              }
                        },
                        lualine_b = {'branch', 'diff', 'diagnostics',
                              {
					"buffers",
					buffers_color = {
						active = { bg = '#D8A657' , fg = '#1d2021', gui = "bold" },
						inactive = { bg = '#a89984', fg = '#282828', gui = "italic" },
					},
					symbols = {
						modified = " ●",
						alternate_file = "",
						directory = "",
					},
					mode = 0,
				},
                        },
                        lualine_c = {
                              'filename',
                        },
                        lualine_x = {'encoding', 'filetype'},
                        lualine_y = {'progress'},
                        lualine_z = {'location'}
                  },
            }
      end
}

