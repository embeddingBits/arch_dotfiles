local M = {}

M.base46 = {
      theme = "onenord",

   changed_themes = {
      onenord = {
         base_30 = {
            dark_purple = "#DF7780",
         },
      },
   }
}

M.ui = {
      statusline = {
            theme = "default",
            separator_style = "block"
      },
      telescope = {
            style = "bordered"
      }
}

return M
