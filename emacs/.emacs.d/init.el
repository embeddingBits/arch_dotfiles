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
(set-frame-font "JetBrainsMono NFP Semibold 13" nil t)
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
(use-package lsp-mode
  :hook
  ((c-mode c++-mode python-mode go-mode zig-mode) . lsp)
  :init (setq lsp-keymap-prefix "C-c l")
  :config
  (setq lsp-enable-snippet t
        lsp-idle-delay 0.5
        lsp-headerline-breadcrumb-enable t
        lsp-completion-provider :capf))  ;; Use capf for completion
(use-package lsp-ui
  :after lsp-mode
  :config
  (setq lsp-ui-doc-enable nil))
;; Eglot
(use-package eglot
  :hook ((c-ts-mode . eglot-ensure)
         (c++-ts-mode . eglot-ensure)
         (zig-mode . eglot-ensure)
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
(use-package websocket)
(use-package typst-preview
  :init
  (setq typst-preview-browser "eaf-browser")
  (setq typst-preview-autostart t)
  (setq typst-preview-open-browser-automatically t)

  :custom
  (typst-preview-invert-colors "never"))

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
(use-package projectile
  :config
  (projectile-mode 1))
(use-package rg)
(use-package magit)

;;; Dashboard
(use-package dashboard
  :demand t
  :config
  (setq dashboard-startup-banner (expand-file-name "~/Downloads/dashboard.jpeg")
        dashboard-banner-logo-title "eBits Emacs"
        dashboard-center-content t
        dashboard-vertically-center-content t
        dashboard-show-shortcuts nil
        dashboard-display-icons-p t
        dashboard-icon-type 'all-the-icons
        dashboard-set-heading-icons t
        dashboard-set-file-icons t
        dashboard-items '((recents . 5)
                          (projects . 5)))
  (dashboard-setup-startup-hook))

;; eaf tools
(use-package eaf
  :load-path "~/.emacs.d/site-lisp/emacs-application-framework"
  :custom
  (eaf-browser-continue-where-left-off t)
  (eaf-browser-enable-adblocker t)
  (browse-url-browser-function 'eaf-open-browser))
(require 'eaf-browser)
(require 'eaf-pdf-viewer)

;;; Programming defaults
(setq-default indent-tabs-mode nil
              tab-width 4)
(electric-pair-mode 1)

;;; Org extras
(use-package org-appear
  :hook (org-mode . org-appear-mode))

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
                   marginalia org-appear projectile rg treesit-auto
                   typst-preview typst-ts-mode vertico zig-mode
                   zig-ts-mode)))
