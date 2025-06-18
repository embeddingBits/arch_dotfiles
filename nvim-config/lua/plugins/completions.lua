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

                  vim.api.nvim_set_hl(0, "CmpBorder", { fg = "#5e81ac" }) -- Border color
                  vim.api.nvim_set_hl(0, "Pmenu", { bg = "NONE", fg = "#cdd6f4" }) -- Background and foreground
                  vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#45475a", fg = "#f5e0dc" }) -- Selected item
                  vim.api.nvim_set_hl(0, "CmpItemKindInterface", { fg = "#BF616A", bg = "NONE" })

                  local cmp = require'cmp'
                  require("luasnip.loaders.from_vscode").lazy_load()
                  cmp.setup({
                        formatting = {
                              format = function(entry, vim_item)
                                    local kind_text = require("lspkind").cmp_format({
                                          mode = "symbol_text", -- enable text labels like File, Snippet, etc.
                                          maxwidth = 50,
                                    })(entry, vim_item)

                                    -- Add devicons for file path completions
                                    if entry.source.name == "path" then
                                          local icon, hl_group = require("nvim-web-devicons").get_icon(entry:get_completion_item().label)
                                          if icon then
                                                kind_text.kind = icon .. " " .. kind_text.kind  -- icon + label
                                                kind_text.kind_hl_group = hl_group
                                          end
                                    end

                                    return kind_text
                              end
                        },
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
