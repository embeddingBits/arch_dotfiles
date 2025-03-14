return {
  "rcarriga/nvim-notify",
  config = function()
    require("notify").setup({
      stages = "slide",
      timeout = 3000,
    })
    vim.notify = require("notify")
    vim.api.nvim_set_hl(0, "NotifyINFOBorder", { fg = "#88C0D0" })
  end,
}
