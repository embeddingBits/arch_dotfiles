return {
  "mfussenegger/nvim-lint",
  config = function()
    -- Configure linters by filetype
    require('lint').linters_by_ft = {
      go = { 'golangcilint' }, -- Correct for Go
      c = { 'cppcheck' },      -- Better linter for C
      cpp = { 'cppcheck' },    -- Linter for C++
    }

    -- Automatically run linters on certain events
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
      callback = function()
        require("lint").try_lint()
      end,
    })
  end,
}
