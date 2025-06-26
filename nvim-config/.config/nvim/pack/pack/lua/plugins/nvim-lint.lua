return {
  "mfussenegger/nvim-lint",
  config = function()
    local lint = require("lint")

    -- Define linters for specific filetypes
    lint.linters_by_ft = {
      go = { "golangcilint" }, -- Go
    }

    -- Optional: Configure how often linting runs
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      callback = function()
        lint.try_lint()
      end,
    })

    vim.diagnostic.config({
      virtual_text = {
        prefix = "●", -- Change the prefix for virtual text
        source = "if_many", -- Show source only if there are multiple sources
      },
      signs = true, -- Show signs in the gutter
      underline = true, -- Underline issues
      update_in_insert = false, -- Don't update diagnostics while typing
      severity_sort = true, -- Sort by severity (errors before warnings)
    })
  end,
}
