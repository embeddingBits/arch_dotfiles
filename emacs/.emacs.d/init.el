;;; Startup performance tweaks
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.8)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))
;; Increase process IO for LSP & subprocesses
(setq read-process-output-max (* 4 1024 1024))

;;; UI Defaults
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq dired-kill-when-opening-new-dired-buffer t)
(setq split-height-threshold nil)
(setq split-width-threshold 0)

;;; UI / Look & Feel
(setq inhibit-startup-message t
      ring-bell-function 'ignore
      make-backup-files nil
      auto-save-default nil
      visible-bell nil)

;; Keybinding
(global-set-key (kbd "C-c d") 'delete-file)
(global-set-key (kbd "C-c e") 'eshell)
(global-set-key (kbd "C-c b") 'eaf-open-browser)

;;; Package system & use-package
(require 'package)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t
      use-package-defer t)

;; Font
(defvar +fixed-width-font "JetBrainsMono Nerd Font"
  "Font used globally for fixed-width text.")

(defvar +variable-width-font "IosevkaTerm Nerd Font"
  "Font used in Org buffers (variable + fixed pitch).")

(set-face-attribute 'default nil
                    :font +fixed-width-font
                    :height 130
                    :weight 'medium)

(set-face-attribute 'fixed-pitch nil
                    :font +fixed-width-font
                    :height 130)

;; Line numbers
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative
      display-line-numbers-width 3)

(global-visual-line-mode 1)
(column-number-mode 1)
(add-hook 'prog-mode-hook #'hl-line-mode)

;; Scrolling feel
(setq scroll-step 1
      scroll-margin 8
      scroll-conservatively 101)

;;; Built-in Treesitter configuration
(use-package treesit
  :ensure nil
  :config
  (setq treesit-language-source-alist
        '((zig "https://github.com/tree-sitter-grammars/tree-sitter-zig")
          (typst "https://github.com/uben0/tree-sitter-typst"))
        treesit-font-lock-level 4)
  (setq major-mode-remap-alist
        '((c-mode . c-ts-mode)
          (c++-mode . c++-ts-mode)
          (python-mode . python-ts-mode)
          (go-mode . go-ts-mode)
          (zig-mode . zig-ts-mode)
          (typst-mode . typst-ts-mode)
          (sh-mode . bash-ts-mode)
          (bash-mode . bash-ts-mode)
          (fish-mode . fish-ts-mode))))

(use-package treesit-auto
  :config
  (global-treesit-auto-mode))

;; Zig mode
(use-package zig-ts-mode
  :vc (:url "https://codeberg.org/meow_king/zig-ts-mode"
       :rev :newest))
(add-to-list 'auto-mode-alist '("\\.zig\\(?:\\.zon\\)?\\'" . zig-ts-mode))

;;; Theme
(use-package gruvbox-theme
  :demand t
  :config
  (load-theme 'gruvbox-dark-hard t))

;;; Doom modeline
(use-package doom-modeline
  :demand t
  :config
  (doom-modeline-mode 1))

;;; Icons support
(use-package all-the-icons
  :if (display-graphic-p))

;;; Vertico and Marginalia
(use-package vertico
  :init
  (vertico-mode 1))
(use-package marginalia
  :init
  (marginalia-mode 1))

;;; Evil + Keybindings
(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil)
  :config
  (evil-mode 1))
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))
;; Leader key
(use-package general
  :after evil
  :config
  (general-create-definer my/leader
    :states '(normal visual)
    :prefix "SPC")
  (my/leader
    "f f" '(find-file :which-key "find file")
    "f s" '(save-buffer :which-key "save")
    "b b" '(switch-to-buffer :which-key "switch buffer")
    "w q" '(kill-buffer-and-window :which-key "close window")
    "g g" '(magit-status :which-key "git status")
    "l d" '(lsp-find-definition :which-key "definition")
    "l r" '(lsp-find-references :which-key "references")
    "l h" '(lsp-describe-thing-at-point :which-key "hover")
    "l f" '(lsp-format-buffer :which-key "format")))
(use-package which-key
  :config
  (which-key-mode 1))

;;; Completion & LSP

;; Yasnippets
(use-package yasnippet
  :hook (prog-mode . yas-minor-mode)
  :config
  (yas-reload-all))

(use-package yasnippet-snippets
  :after yasnippet)

;; Company
(use-package company
  :hook
  (prog-mode . company-mode)
  :config
  (setq company-minimum-prefix-length 1
        company-idle-delay 0.0
        company-tooltip-align-annotations t
        company-backends (cons 'company-capf company-backends)))  ;; Ensure capf for LSP/Eglot
(dolist (hook '(eshell-mode-hook
                shell-mode-hook
                term-mode-hook
                vterm-mode-hook
                minibuffer-setup-hook))
  (add-hook hook (lambda () (company-mode -1))))

;; Eglot
(use-package eglot
  :hook ((c-ts-mode . eglot-ensure)
         (c++-ts-mode . eglot-ensure)
         (zig-mode . eglot-ensure)
         (org-mode . eglot-ensure)
         (typst-mode . eglot-ensure)
         (go-ts-mode . eglot-ensure))
  :custom
  (eglot-autoshutdown t)
  (eglot-events-buffer-size 0)
  (eglot-extend-to-xref nil)
  (eglot-ignored-server-capabilities
   '(:hoverProvider
     :documentHighlightProvider
     :documentFormattingProvider
     :documentRangeFormattingProvider
     :documentOnTypeFormattingProvider
     :colorProvider
     :foldingRangeProvider))
  (eglot-stay-out-of '(yasnippet)))


;;; Typst
(use-package typst-preview
  :init
  (setq typst-preview-browser "eaf-browser")
  (setq typst-preview-autostart t)
  (setq typst-preview-open-browser-automatically t)

  :custom
  (typst-preview-invert-colors "auto"))

(use-package typst-ts-mode
  :mode "\\.typ\\'")

;;; Indent Bars
(use-package indent-bars
  :custom
  (indent-bars-treesit-support t)
  :hook ((emacs-lisp-mode
          c-mode c++-mode
          c-ts-mode c++-ts-mode
          zig-mode zig-ts-mode)))

;;; Project / Search / Git
(use-package rg)
(use-package magit)

;;; Dashboard
(use-package dashboard
  :demand t
  :config
  (setq dashboard-startup-banner (expand-file-name "~/Downloads/dashboard-1.jpeg")
        dashboard-banner-logo-title "eBits Emacs"
        dashboard-center-content t
        dashboard-vertically-center-content t
        dashboard-show-shortcuts nil
        dashboard-display-icons-p t
        dashboard-icon-type 'all-the-icons
        dashboard-set-heading-icons t
        dashboard-set-file-icons t
        dashboard-items '((recents . 5)
                          (bookmarks . 5))
        dashboard-projects-backend 'projectile)
  (dashboard-setup-startup-hook))

;; eaf tools
(use-package eaf
  :load-path "~/.emacs.d/site-lisp/emacs-application-framework"
  :custom
  (eaf-browser-continue-where-left-off t)
  (eaf-browser-enable-adblocker t)
  (browse-url-browser-function 'eaf-open-browser))
(require 'eaf-browser)

;; PDF Tools
(use-package pdf-tools
  :config
  (pdf-loader-install)
  (setq-default pdf-view-display-size 'fit-page)
  (setq pdf-view-resize-factor 1.1)
  (with-eval-after-load 'evil
    (evil-define-key 'normal pdf-view-mode-map
      (kbd "j") 'pdf-view-next-page
      (kbd "k") 'pdf-view-previous-page))
  :hook (pdf-view-mode-hook . (lambda () (display-line-numbers-mode nil))))

;;; Programming defaults
(setq-default indent-tabs-mode nil
              tab-width 4)
(electric-pair-mode 1)

;; Org mode

(defvar +fixed-width-font "JetBrainsMono NF")
(defvar +org-font "IosevkaTerm NF")

(defun my/org-font-setup ()
  ;; Enable variable pitch in Org buffers
  (variable-pitch-mode 1)

  ;; Main text
  (face-remap-add-relative
   'variable-pitch
   :family +org-font
   :height 130
   :weight 'regular)

  ;; Fixed-width parts in Org
  (face-remap-add-relative
   'fixed-pitch
   :family +org-font
   :height 130)

  ;; Explicit Org faces
  (dolist (face '(org-code
                  org-table
                  org-block
                  org-block-begin-line
                  org-block-end-line
                  org-verbatim
                  org-meta-line
                  org-special-keyword
                  org-modern-symbol))
    (face-remap-add-relative
     face
     :family +org-font
     :height 130)))

(add-hook 'org-mode-hook #'my/org-font-setup)

;;;; Org Appearance Basics
(setq org-hide-emphasis-markers t
      org-pretty-entities t
      org-ellipsis "…"
      org-auto-align-tags nil
      org-tags-column 0
      org-agenda-tags-column 0)

;;;; org-appear
(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-autoemphasis t
        org-appear-autolinks t
        org-appear-autosubmarkers t
        org-appear-delay 0.1))


;;;; org-modern
(use-package org-modern
  :after org
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :config
  (setq org-modern-variable-pitch t
        org-modern-table nil
        org-modern-star '("⌬" "⊛" "➤" "▻" "◎" "❂" "⦿" "✦" "❅" "◈" "☢")))


;;;; Org Visual Polish
(add-hook 'org-mode-hook
          (lambda ()
            (display-line-numbers-mode -1)))

(setq org-startup-indented nil)

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(line-number ((t (:background "#1d2021" :foreground "#7c6f64"))))
 '(mode-line ((t (:background "#1d2021" :foreground "#ebdbb2" :box (:line-width 2 :color "#1d2021")))))
 '(mode-line-inactive ((t (:background "#555555" :foreground "#eeeeee")))))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(all-the-icons company dashboard doom-modeline evil-collection
                   general gruvbox-theme indent-bars lsp-ui magit
                   marginalia org-appear org-modern pdf-tools
                   projectile rg treesit treesit-auto typst-preview
                   typst-ts-mode vertico yasnippet-capf
                   yasnippet-snippets zig-mode zig-ts-mode)))
