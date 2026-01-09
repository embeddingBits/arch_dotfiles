return {
  {
    "hrsh7th/cmp-nvim-lsp"
  },
  {
    'L3MON4D3/LuaSnip',
    dependencies = {
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "hrsh7th/cmp-path"
    },
  },
  {
    "hrsh7th/nvim-cmp",
    config = function()

      vim.api.nvim_set_hl(0, "CmpBorder", { fg = "#757165" }) -- Border color
      vim.api.nvim_set_hl(0, "Pmenu", { bg = "#2D353B", fg = "#cdd6f4" }) -- Background and foreground
      vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#45475a", fg = "#f5e0dc" }) -- Selected item

      local cmp = require'cmp'
      require("luasnip.loaders.from_vscode").lazy_load()
      cmp.setup({
        snippet = {
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
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<TAB>'] = cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }), {'i'}),
          ['<Up>'] = cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }), {'i'}),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' }, 
        }, {
          { name = 'buffer' },
          { name = 'path' }
        })
      })
    end,
  }
}
