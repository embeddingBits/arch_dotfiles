;; UI basics
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(setq inhibit-startup-message t
      ring-bell-function 'ignore
      visible-bell nil
      make-backup-files nil
      auto-save-default nil)

;; Defaults
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(electric-pair-mode t)
(electric-indent-mode 1)
(setq tab-always-indent 'complete)

;; indentation guides
(add-hook 'prog-mode-hook 'highlight-indent-guides-mode)

(setq scroll-step 1
      scroll-margin 8
      scroll-conservatively 101)

(setq read-process-output-max (* 4 1024 1024))

;; Package system
(require 'package)

(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu"   . "https://elpa.gnu.org/packages/")))

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

;; Theme
(use-package gruvbox-theme
  :demand t
  :config
  (load-theme 'gruvbox-dark-hard t))

;; Line numbers & visuals
(column-number-mode 1)
(global-visual-line-mode 1)

(add-hook 'prog-mode-hook
          (lambda ()
            (display-line-numbers-mode 1)
            (setq display-line-numbers 'relative)
            (hl-line-mode 1)))

(add-hook 'text-mode-hook
          (lambda ()
            (display-line-numbers-mode 0)))

;; Modeline & icons
(use-package doom-modeline
  :demand t
  :config
  (doom-modeline-mode 1))

(use-package nerd-icons
  :ensure t)

;; Evil
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

;; Completion
(use-package company
  :hook (prog-mode . company-mode)
  :config
  (setq company-minimum-prefix-length 1
        company-idle-delay 0.0
        company-tooltip-align-annotations t))

;; Vertico
(vertico-mode 1)
(marginalia-mode 1)

;; Disable in minibuffers and eshell
(dolist (hook '(eshell-mode-hook
                shell-mode-hook
                term-mode-hook
                vterm-mode-hook
                minibuffer-setup-hook))
  (add-hook hook (lambda () (company-mode -1))))

(use-package flycheck
  :hook (after-init . global-flycheck-mode))

;; LSP
(use-package lsp-mode
  :hook ((c-mode c++-mode python-mode go-mode zig-mode) . lsp)
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  (setq lsp-enable-snippet t
        lsp-idle-delay 0.5
        lsp-headerline-breadcrumb-enable t
        lsp-completion-provider :company))

(use-package lsp-ui
  :after lsp-mode
  :config
  (setq lsp-ui-doc-enable t
        lsp-ui-doc-position 'bottom
        lsp-ui-doc-show-with-cursor t
        lsp-ui-doc-delay 0.2
        lsp-ui-sideline-enable t
        lsp-ui-sideline-show-hover t))

(use-package lsp-treemacs
  :after lsp-mode)

;; Project / Git / Search
(use-package projectile
  :config
  (projectile-mode 1))

(use-package rg)
(use-package magit)

;; Dashboard
(use-package dashboard
  :demand t
  :config
  (setq dashboard-startup-banner '"~/Downloads/dashboard.jpeg"
        dashboard-banner-logo-title "eBits Emacs"
        dashboard-center-content t
        dashboard-vertically-center-content t
        dashboard-show-shortcuts nil
        dashboard-display-icons-p t
        dashboard-icon-type 'nerd-icons
        dashboard-set-heading-icons t
        dashboard-set-file-icons t
        dashboard-items '((recents . 5)))
  (dashboard-setup-startup-hook))

;; Org extras
(use-package org-modern
  :hook (org-mode . org-modern-mode))

(use-package org-appear
  :hook (org-mode . org-appear-mode))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes '(gruvbox-dark-hard))
 '(custom-safe-themes
   '("d5fd482fcb0fe42e849caba275a01d4925e422963d1cd165565b31d3f4189c87"
     default))
 '(package-selected-packages
   '(company corfu dashboard doom-modeline evil-collection flycheck
             general gruvbox-theme lsp-treemacs lsp-ui magit
             marginalia nerd-icons-dired org-appear org-modern
             projectile rg spacious-padding vertico yasnippet)))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(line-number ((t (:background "#1d2021" :foreground "#7c6f64"))))
 '(mode-line ((t (:background "#1d2021" :foreground "#ebdbb2" :box (:line-width 2 :color "#1d2021")))))
 '(mode-line-inactive ((t (:background "#555555" :foreground "#eeeeee")))))
