return {
      'akinsho/bufferline.nvim',
      dependencies = {
            'nvim-tree/nvim-web-devicons',
      },
      config = function()
            local bufferline = require("bufferline")

            bufferline.setup {
                  options = {
                        mode = "buffers",
                        separator_style = "slant",  -- Simple separators to check
                        color_icons = true

                  },
                  highlights = require("nord.plugins.bufferline").akinsho(),
            }
      end
}

