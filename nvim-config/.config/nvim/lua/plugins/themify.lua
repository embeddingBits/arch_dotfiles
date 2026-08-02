return {
      'lmantw/themify.nvim',

      lazy = false,
      priority = 999,
      config = function()
            local themify = require("themify")

            -- Transparent background: let the terminal bg show through
            local function transparent_bg()
                  for _, group in ipairs({ 'Normal', 'NormalFloat', 'NonText', 'SignColumn' }) do
                        vim.api.nvim_set_hl(0, group, { bg = 'NONE' })
                  end
            end

            vim.api.nvim_create_autocmd('ColorScheme', {
                  callback = transparent_bg,
            })

            transparent_bg()

            themify.setup({
                  { "sainnhe/gruvbox-material" },
                  { "ellisonleao/gruvbox.nvim" },
                  { "RRethy/base16-nvim" },

            })

            vim.keymap.set('n', '<leader>th', '<Cmd>Themify<CR>', {})
      end
}

