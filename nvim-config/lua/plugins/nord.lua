return { "gbprod/nord.nvim", 
          priority = 1000,
          config = function()
            require("nord").setup()
            vim.cmd.colorscheme("nord")
          end
}
