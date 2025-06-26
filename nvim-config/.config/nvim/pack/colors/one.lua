local M = {}

-- Color definitions
local colors = {
  base_30 = {
    white = "#D8DEE9",
    darker_black = "#252b37",
    black = "#2a303c",
    black2 = "#2f3541",
    one_bg = "#343a46",
    one_bg2 = "#3e4450",
    one_bg3 = "#484e5a",
    grey = "#4d535f",
    grey_fg = "#545a66",
    grey_fg2 = "#595f6b",
    light_grey = "#606672",
    red = "#d57780",
    baby_pink = "#de878f",
    pink = "#da838b",
    line = "#414753",
    green = "#A3BE8C",
    vibrant_green = "#afca98",
    blue = "#7797b7",
    nord_blue = "#81A1C1",
    yellow = "#EBCB8B",
    sun = "#e1c181",
    purple = "#aab1be",
    dark_purple = "#B48EAD",
    teal = "#6484a4",
    orange = "#e39a83",
    cyan = "#9aafe6",
    statusline_bg = "#333945",
    lightbg = "#3f4551",
    pmenu_bg = "#A3BE8C",
    folder_bg = "#7797b7",
  },
  base_16 = {
    base00 = "#2a303c",
    base01 = "#3B4252",
    base02 = "#434C5E",
    base03 = "#4C566A",
    base04 = "#566074",
    base05 = "#bfc5d0",
    base06 = "#c7cdd8",
    base07 = "#ced4df",
    base08 = "#d57780",
    base09 = "#e39a83",
    base0A = "#EBCB8B",
    base0B = "#A3BE8C",
    base0C = "#97b7d7",
    base0D = "#81A1C1",
    base0E = "#B48EAD",
    base0F = "#d57780",
  },
}

-- Helper function to set highlights
local function set_hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Theme setup function
function M.setup()
  -- Ensure termguicolors is enabled
  vim.o.termguicolors = true
  vim.o.background = "dark"

  -- Clear existing highlights
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  -- Set colorscheme name
  vim.g.colors_name = "custom_theme"

  local c = colors.base_30
  local b = colors.base_16

  -- Basic UI
  set_hl("Normal", { fg = c.white, bg = c.black })
  set_hl("NormalFloat", { fg = c.white, bg = c.one_bg })
  set_hl("FloatBorder", { fg = c.line, bg = c.one_bg })
  set_hl("CursorLine", { bg = c.one_bg2 })
  set_hl("CursorColumn", { bg = c.one_bg2 })
  set_hl("LineNr", { fg = c.grey_fg })
  set_hl("CursorLineNr", { fg = c.white, bold = true })
  set_hl("VertSplit", { fg = c.line })
  set_hl("StatusLine", { fg = c.white, bg = c.statusline_bg })
  set_hl("StatusLineNC", { fg = c.grey_fg, bg = c.statusline_bg })
  set_hl("WinSeparator", { fg = c.line })

  -- Pmenu (popup menu)
  set_hl("Pmenu", { fg = c.white, bg = c.one_bg })
  set_hl("PmenuSel", { fg = c.black, bg = c.pmenu_bg })
  set_hl("PmenuSbar", { bg = c.one_bg2 })
  set_hl("PmenuThumb", { bg = c.grey })

  -- Syntax highlighting
  set_hl("Comment", { fg = c.grey_fg, italic = true })
  set_hl("String", { fg = c.red })
  set_hl("Character", { fg = c.green })
  set_hl("Number", { fg = c.yellow })
  set_hl("Float", { fg = c.yellow })
  set_hl("Boolean", { fg = c.cyan })
  set_hl("Constant", { fg = c.cyan })
  set_hl("Identifier", { fg = c.nord_blue })
  set_hl("Function", { fg = c.blue })
  set_hl("Statement", { fg = c.purple })
  set_hl("Conditional", { fg = c.purple })
  set_hl("Repeat", { fg = c.purple })
  set_hl("Label", { fg = c.purple })
  set_hl("Operator", { fg = c.white })
  set_hl("Keyword", { fg = c.red })
  set_hl("Exception", { fg = c.red })
  set_hl("PreProc", { fg = c.orange })
  set_hl("Include", { fg = c.orange })
  set_hl("Define", { fg = c.orange })
  set_hl("Macro", { fg = c.orange })
  set_hl("Type", { fg = c.yellow })
  set_hl("StorageClass", { fg = c.yellow })
  set_hl("Structure", { fg = c.yellow })
  set_hl("Typedef", { fg = c.yellow })
  set_hl("Special", { fg = c.teal })
  set_hl("SpecialChar", { fg = c.teal })
  set_hl("Tag", { fg = c.teal })
  set_hl("Delimiter", { fg = c.white })
  set_hl("SpecialComment", { fg = c.grey_fg2, italic = true })
  set_hl("Debug", { fg = c.red })

  -- Diff
  set_hl("DiffAdd", { fg = c.green, bg = c.darker_black })
  set_hl("DiffChange", { fg = c.yellow, bg = c.darker_black })
  set_hl("DiffDelete", { fg = c.red, bg = c.darker_black })
  set_hl("DiffText", { fg = c.blue, bg = c.one_bg })

  -- Search
  set_hl("Search", { fg = c.black, bg = c.yellow })
  set_hl("IncSearch", { fg = c.black, bg = c.orange })
  set_hl("CurSearch", { fg = c.black, bg = c.orange })

  -- Visual
  set_hl("Visual", { bg = c.one_bg3 })
  set_hl("VisualNOS", { bg = c.one_bg3 })

  -- Fold
  set_hl("Folded", { fg = c.grey_fg, bg = c.one_bg })
  set_hl("FoldColumn", { fg = c.grey_fg, bg = c.black })

  -- Sign column
  set_hl("SignColumn", { bg = c.black })
  set_hl("ColorColumn", { bg = c.one_bg })

  -- Messages
  set_hl("ErrorMsg", { fg = c.red, bold = true })
  set_hl("WarningMsg", { fg = c.yellow, bold = true })
  set_hl("ModeMsg", { fg = c.green, bold = true })
  set_hl("MoreMsg", { fg = c.blue, bold = true })
  set_hl("Question", { fg = c.purple, bold = true })

  -- NonText and SpecialKey
  set_hl("NonText", { fg = c.grey })
  set_hl("SpecialKey", { fg = c.grey })

  -- Directory
  set_hl("Directory", { fg = c.folder_bg })

  -- LSP
  set_hl("DiagnosticError", { fg = c.red })
  set_hl("DiagnosticWarn", { fg = c.yellow })
  set_hl("DiagnosticInfo", { fg = c.blue })
  set_hl("DiagnosticHint", { fg = c.cyan })
  set_hl("DiagnosticVirtualTextError", { fg = c.red, bg = c.darker_black })
  set_hl("DiagnosticVirtualTextWarn", { fg = c.yellow, bg = c.darker_black })
  set_hl("DiagnosticVirtualTextInfo", { fg = c.blue, bg = c.darker_black })
  set_hl("DiagnosticVirtualTextHint", { fg = c.cyan, bg = c.darker_black })

  -- Treesitter
  set_hl("@variable", { fg = c.white })
  set_hl("@property", { fg = c.nord_blue })
  set_hl("@field", { fg = c.nord_blue })
  set_hl("@parameter", { fg = c.white })
  set_hl("@symbol", { fg = c.purple })
  set_hl("@constant", { fg = c.cyan })
  set_hl("@string", { fg = c.green })
  set_hl("@number", { fg = c.yellow })
  set_hl("@boolean", { fg = c.cyan })
  set_hl("@function", { fg = c.blue })
  set_hl("@method", { fg = c.blue })
  set_hl("@constructor", { fg = c.blue })
  set_hl("@keyword", { fg = c.red })
  set_hl("@operator", { fg = c.white })
  set_hl("@punctuation", { fg = c.white })
  set_hl("@tag", { fg = c.teal })
  set_hl("@tag.attribute", { fg = c.orange })
  set_hl("@tag.delimiter", { fg = c.white })

  -- Common plugins
  -- GitSigns
  set_hl("GitSignsAdd", { fg = c.green })
  set_hl("GitSignsChange", { fg = c.yellow })
  set_hl("GitSignsDelete", { fg = c.red })

  -- Telescope
  set_hl("TelescopeBorder", { fg = c.line })
  set_hl("TelescopePromptBorder", { fg = c.line })
  set_hl("TelescopeResultsBorder", { fg = c.line })
  set_hl("TelescopePreviewBorder", { fg = c.line })
  set_hl("TelescopeSelection", { fg = c.white, bg = c.one_bg2 })
  set_hl("TelescopeMatching", { fg = c.yellow })

  -- NvimTree
  set_hl("NvimTreeFolderName", { fg = c.folder_bg })
  set_hl("NvimTreeOpenedFolderName", { fg = c.folder_bg, bold = true })
  set_hl("NvimTreeRootFolder", { fg = c.purple, bold = true })
  set_hl("NvimTreeNormal", { fg = c.white, bg = c.darker_black })
  set_hl("NvimTreeGitDirty", { fg = c.yellow })
  set_hl("NvimTreeGitNew", { fg = c.green })
  set_hl("NvimTreeGitDeleted", { fg = c.red })

  -- Notify user that theme is loaded
  vim.notify("Custom theme loaded successfully", vim.log.levels.INFO)
end

return M
