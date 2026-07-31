return { 
      {
            "williamboman/mason.nvim",
            config = function()
                  require("mason").setup()
            end
      },
      {
            "williamboman/mason-lspconfig.nvim",
            config = function()
                  require("mason-lspconfig").setup({
                        ensure_installed = { "lua_ls", "clangd", "zls", "gopls", "verible", "tinymist", "pyright", "ols" }
                  })
            end
      },
      {
            "neovim/nvim-lspconfig",
            config = function()
                  local capabilities = require('cmp_nvim_lsp').default_capabilities()
                  vim.lsp.config('*', {
                        capabilities = capabilities,
                  })

                  vim.lsp.enable('lua_ls')
                  vim.lsp.enable('clangd')
                  vim.lsp.enable('zls')
                  vim.lsp.enable('gopls')
                  vim.lsp.enable('verible')
                  vim.lsp.enable('svlangserver')
            end
      },

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
                  vim.api.nvim_set_hl(0, "CmpBorder", { fg = "#b8bb26" })
                  vim.api.nvim_set_hl(0, "Pmenu", { bg = "NONE", fg = "#d5c4a1" })
                  vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#458588", fg = "#0D1117" })
                  vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { fg = "#83a598", bg = "NONE", bold = true })
                  vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { fg = "#83a598", bg = "NONE", bold = true })
                  vim.api.nvim_set_hl(0, "CmpItemAbbr", { fg = "#d5c4a1", bg = "NONE" })
                  vim.api.nvim_set_hl(0, "CmpItemKind", { fg = "#83a598", bg = "NONE" })
                  vim.api.nvim_set_hl(0, "CmpItemMenu", { fg = "#b8bb26", bg = "NONE" })

                  local cmp = require'cmp'
                  local luasnip = require('luasnip')

                  require("luasnip.loaders.from_vscode").lazy_load()
                  require("luasnip.loaders.from_vscode").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })

                  cmp.setup({
                        formatting = {
                              format = function(entry, vim_item)
                                    local kind_text = require("lspkind").cmp_format({
                                          mode = "symbol_text", 
                                          maxwidth = 50,
                                    })(entry, vim_item)

                                    if entry.source.name == "path" then
                                          local icon, hl_group = require("nvim-web-devicons").get_icon(entry:get_completion_item().label)
                                          if icon then
                                                kind_text.kind = icon .. " " .. kind_text.kind
                                                kind_text.kind_hl_group = hl_group
                                          end
                                    end

                                    return kind_text
                              end
                        },
                        snippet = {
                              expand = function(args)
                                    luasnip.lsp_expand(args.body)
                              end,
                        },
                        window = {
                              completion = cmp.config.window.bordered({
                                    border = "rounded",
                                    winhighlight = "Normal:Pmenu,FloatBorder:CmpBorder,NormalFloat:Pmenu,CursorLine:PmenuSel",
                              }),
                              documentation = cmp.config.window.bordered({
                                    winhighlight = "Normal:Pmenu,FloatBorder:CmpBorder,NormalFloat:Pmenu",
                              }),
                        },
                        mapping = cmp.mapping.preset.insert({
                              ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                              ['<C-f>'] = cmp.mapping.scroll_docs(4),
                              ['<C-Space>'] = cmp.mapping.complete(),
                              ['<C-e>'] = cmp.mapping.abort(),
                              ['<CR>'] = cmp.mapping.confirm({ select = true }),

                              -- Enhanced TAB behavior to select next item or jump forward through your snippet parameters ($1, $2, etc.)
                              ['<TAB>'] = cmp.mapping(function(fallback)
                                    if cmp.visible() then
                                          cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                                    elseif luasnip.expand_or_jumpable() then
                                          luasnip.expand_or_jump()
                                    else
                                          fallback()
                                    end
                              end, {'i', 's'}),

                              -- Enhanced UP / S-TAB behavior to move backwards inside lists or snippet blocks
                              ['<Up>'] = cmp.mapping(function(fallback)
                                    if cmp.visible() then
                                          cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
                                    elseif luasnip.jumpable(-1) then
                                          luasnip.jump(-1)
                                    else
                                          fallback()
                                    end
                              end, {'i', 's'}),
                        }),
                        sources = cmp.config.sources({
                              { name = 'nvim_lsp' }, -- Gives you default LSP variables, functions, and symbols
                              { name = 'luasnip' },  -- Gives you your custom C and Go snippets
                        }, {
                              { name = 'buffer' },   -- Text words within current file
                              { name = 'path' }      -- File path completions
                        })
                  })
            end,
      }
}

