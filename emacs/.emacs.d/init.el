;;; init.el --- Robust Entry Point -*- lexical-binding: t; -*-

;; 1. Silence Compiler Noise
(setq native-comp-async-report-warnings-errors 'silent)
(setq byte-compile-warnings '(not free-vars unresolved await regexp))

;; 2. Optimize Startup
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

;; 3. Initialize Package Repos
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

;; 4. Ensure use-package and vc support
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;; Support for the :vc keyword in use-package (Emacs 29+)
(unless (fboundp 'package-vc-install)
  (require 'package-vc))

;; 5. Load the actual config
(org-babel-load-file (expand-file-name "config.org" user-emacs-directory))

;; 6. Load custom.el (Keep init.el clean)
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror 'nomessage)

(provide 'init)
