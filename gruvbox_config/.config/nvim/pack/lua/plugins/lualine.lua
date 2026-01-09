return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        local lualine = require('lualine')

        -- Custom function to get filetype icon (logo) using nvim-web-devicons
        local function filetype_icon()
            local devicons = require('nvim-web-devicons')
            local filetype = vim.bo.filetype
            local icon, _ = devicons.get_icon_by_filetype(filetype, { default = true })
            return icon or '' -- Fallback icon if no specific filetype icon is found
        end

        lualine.setup({
            options = {
                theme = 'auto', -- Keep your preferred theme
                section_separators = { left = '', right = '' }, -- Remove section separators to avoid interference
                component_separators = { left = '', right = '' }, -- Remove default component separators
                globalstatus = true, -- Enable global statusline (Neovim 0.7+ feature)
                disabled_filetypes = { 'NvimTree', 'dashboard' }, -- Disable on certain filetypes
            },
            sections = {
                lualine_a = { 
                    -- Combine filetype icon and mode into a single pill for better alignment
                    { 
                        function() return filetype_icon() .. ' ' .. require('lualine.utils.mode').get_mode() end, 
                        separator = { left = '', right = '' }, 
                        padding = { left = 1, right = 1 } 
                    },
                },
                lualine_b = { 
                    { 'branch', icon = '', separator = { left = '', right = '' }, padding = { left = 1, right = 1 } }, -- Branch as a pill
                    { 'diff', symbols = { added = ' ', modified = '柳 ', removed = ' ' }, separator = { left = '', right = '' }, padding = { left = 1, right = 1 } }, -- Diff as a pill
                },
                lualine_c = { 
                    { 'filename', path = 1, symbols = { modified = ' [+]', readonly = ' [-]' }, separator = { left = '', right = '' }, padding = { left = 1, right = 1 } }, -- Filename as a pill
                },
                lualine_x = { },
                lualine_y = { 
                    { 'progress', separator = { left = '', right = '' }, padding = { left = 1, right = 1 } }, -- Progress as a pill
                },
                lualine_z = { 
                    { 'location', separator = { left = '', right = '' }, padding = { left = 1, right = 1 } }, -- Location as a pill
                },
            },
            inactive_sections = { -- Define inactive window sections
                lualine_a = {},
                lualine_b = {},
                lualine_c = { 
                    { 'filename', separator = { left = '', right = '' }, padding = { left = 1, right = 1 } }, -- Keep filename as a pill
                },
                lualine_x = { 
                    { 'location', separator = { left = '', right = '' }, padding = { left = 1, right = 1 } }, -- Keep location as a pill
                },
                lualine_y = {},
                lualine_z = {},
            },
        })
    end,
}
