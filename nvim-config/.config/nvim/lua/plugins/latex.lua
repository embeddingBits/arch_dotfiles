return {
      "lervag/vimtex",
      lazy = false, -- don't lazy load VimTeX
      init = function()
            -- General viewer settings
            vim.g.vimtex_view_method = "zathura"

            -- Recommended by VimTeX to avoid conflicts
            vim.g.tex_flavor = "latex"
            vim.g.did_load_filetypes = 1
            -- Turn on quickfix mode (shows compilation errors)
            vim.g.vimtex_quickfix_mode = 0

            -- If you want to use lualatex/xelatex instead of pdflatex
            -- vim.g.vimtex_compiler_latexmk = {
            --   build_dir = 'build',
            --   options = {
            --     '-pdf',
            --     '-interaction=nonstopmode',
            --     '-synctex=1',
            --   },
            -- }
      end,
}

