vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true  -- Optional: Highlight the current line for better visibility

vim.cmd("set expandtab")
vim.cmd("set expandtab")
vim.cmd("set tabstop=6")
vim.cmd("set softtabstop=6")
vim.cmd("set shiftwidth=6")

------------------------------ Lazy Neovim Setup -------------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

------------------ Keybinds ------------------

vim.keymap.set('n', '<leader>n', "<Cmd>enew<CR>", {})
vim.keymap.set('n', '<leader>x', "<Cmd>bd<CR>", {})
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to below window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to above window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

vim.cmd([[
  highlight NordGrad1 guifg=#2E3440
  highlight NordGrad2 guifg=#3B4252
  highlight NordGrad3 guifg=#434C5E
  highlight NordGrad4 guifg=#4C566A
  highlight NordGrad5 guifg=#5E81AC
  highlight NordGrad6 guifg=#81A1C1
  highlight NordGrad7 guifg=#88C0D0
  highlight NordGrad8 guifg=#8FBCBB
  highlight NordGrad9 guifg=#A3BE8C
  highlight NordGrad10 guifg=#ECEFF4
]])


if vim.g.neovide then
    vim.opt.guifont = "JetBrainsMono Nerd Font:h14:b"
    vim.g.neovide_cursor_animation_length = 0.05   
end
require("lazy").setup("plugins")



