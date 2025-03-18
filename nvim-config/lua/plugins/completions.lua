return {
  {
    "hrsh7th/cmp-nvim-lsp"
  },
  {
    'L3MON4D3/LuaSnip',
    dependencies = {
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets"
    },
  },
  {
    "hrsh7th/nvim-cmp",
    config = function()
      -- Enable true color support
      vim.opt.termguicolors = true

      -- Define custom highlight groups for completion window
      vim.api.nvim_set_hl(0, "CmpBorder", { fg = "#757165" }) -- Border color
      vim.api.nvim_set_hl(0, "Pmenu", { bg = "#2D353B", fg = "#cdd6f4" }) -- Background and foreground
      vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#45475a", fg = "#f5e0dc" }) -- Selected item

      -- Set up nvim-cmp
      local cmp = require'cmp'
      require("luasnip.loaders.from_vscode").lazy_load()
      cmp.setup({
        snippet = {
          -- REQUIRED - you must specify a snippet engine
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:Pmenu,FloatBorder:CmpBorder,NormalFloat:Pmenu,CursorLine:PmenuSel",
          }),
          documentation = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:Pmenu,FloatBorder:CmpBorder,NormalFloat:Pmenu",
          }),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' }, -- For luasnip users.
        }, {
          { name = 'buffer' },
        })
      })
    end,
  }
}
