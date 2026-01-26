;;; gruvbox-material-dark-hard-theme.el -*- lexical-binding: t -*-

(deftheme gruvbox-material-dark-hard
  "Gruvbox Material inspired retro-groove theme — dark + hard contrast")

(let* ((bg-hard      "#1d2021")
       (bg           "#1d2021")
       (bg-soft      "#212529")
       (bg-dim       "#282828")
       (bg-alt       "#2e3237")
       (bg-highlight "#3a4047")
       (fg-dim       "#a89984")
       (fg           "#d4be98")
       (fg-light     "#e2d5c5")
       (gray         "#928374")
       (gray-light   "#b4a79d")
       (red          "#ea6962")
       (green        "#a9b665")
       (yellow       "#d8a657")
       (blue         "#7daea3")
       (purple       "#d3869b")
       (aqua         "#89b482")
       (orange       "#e78a4e")
       (bright-red    "#ea6962")
       (bright-green  "#a9b665")
       (bright-yellow "#d8a657")
       (bright-blue   "#7daea3")
       (bright-purple "#d3869b")
       (bright-aqua   "#89b482")
       (bright-orange "#e78a4e")
       (cursor       "#d4be98")
       (warning      "#e78a4e")
       (error        "#ea6962")
       (success      "#a9b665")
       (link         "#7daea3"))

  (custom-theme-set-faces
   'gruvbox-material-dark-hard

   `(default                              ((t (:background ,bg :foreground ,fg))))
   `(cursor                               ((t (:background ,cursor :foreground ,bg))))
   `(fringe                               ((t (:background ,bg))))
   `(region                               ((t (:background ,bg-highlight))))
   `(highlight                            ((t (:background ,bg-highlight))))
   `(secondary-selection                  ((t (:background ,bg-dim))))
   `(minibuffer-prompt                    ((t (:foreground ,blue :weight bold))))
   `(mode-line                            ((t (:background ,bg-alt :foreground ,fg-light :box nil))))
   `(mode-line-inactive                   ((t (:background ,bg-dim :foreground ,gray :box nil))))
   `(vertical-border                      ((t (:foreground ,bg-alt))))
   `(line-number                          ((t (:foreground ,gray))))
   `(line-number-current-line             ((t (:foreground ,fg :background ,bg-highlight))))

   `(font-lock-comment-face               ((t (:foreground ,gray :slant italic))))
   `(font-lock-doc-face                   ((t (:foreground ,gray-light :slant italic))))
   `(font-lock-string-face                ((t (:foreground ,green))))
   `(font-lock-keyword-face               ((t (:foreground ,red :weight semi-bold))))
   `(font-lock-builtin-face               ((t (:foreground ,orange))))
   `(font-lock-function-name-face         ((t (:foreground ,blue))))
   `(font-lock-variable-name-face         ((t (:foreground ,fg-light))))
   `(font-lock-type-face                  ((t (:foreground ,yellow))))
   `(font-lock-constant-face              ((t (:foreground ,purple))))
   `(font-lock-warning-face               ((t (:foreground ,warning :weight bold))))

   `(success                              ((t (:foreground ,success))))
   `(warning                              ((t (:foreground ,warning))))
   `(error                                ((t (:foreground ,error :weight bold))))
   `(link                                 ((t (:foreground ,link :underline t))))
   `(shadow                               ((t (:foreground ,gray))))

   `(ansi-color-black                     ((t (:foreground ,bg-dim))))
   `(ansi-color-red                       ((t (:foreground ,red))))
   `(ansi-color-green                     ((t (:foreground ,green))))
   `(ansi-color-yellow                    ((t (:foreground ,yellow))))
   `(ansi-color-blue                      ((t (:foreground ,blue))))
   `(ansi-color-magenta                   ((t (:foreground ,purple))))
   `(ansi-color-cyan                      ((t (:foreground ,aqua))))
   `(ansi-color-white                     ((t (:foreground ,fg))))

   `(org-level-1                          ((t (:foreground ,blue :weight bold :height 1.4))))
   `(org-level-2                          ((t (:foreground ,green :weight bold :height 1.3))))
   `(font-lock-regexp-face                ((t (:foreground ,purple)))))

  (custom-theme-set-variables
   'gruvbox-material-dark-hard
   `(ansi-color-names-vector
     [,bg-dim ,red ,green ,yellow ,blue ,purple ,aqua ,fg-light])))

(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'gruvbox-material-dark-hard)
