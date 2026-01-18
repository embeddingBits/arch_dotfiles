return {
      "nvim-neorg/neorg",
      dependancies = {
            "nvim-treesitter/nvim-treesitter",
      },
      lazy = false,
      version = "*",
      config = function()
            require("neorg").setup {
                  load = {
                        ["core.defaults"] = {},
                        ["core.concealer"] = {},
                        ["core.esupports.metagen"] = {},
                        ["core.ui.calendar"] = {},
                        ["core.dirman"] = {
                              config = {
                                    workspaces = {
                                          notes = "~/PersonalManagement",
                                    },
                              },
                        },
                  },
            }

            vim.wo.foldlevel = 99
            vim.wo.conceallevel = 2
      end,
}
