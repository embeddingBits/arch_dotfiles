;;; utils.el --- Utility Functions  -*- lexical-binding: t; -*-
;; Copyright (C) 2023 Meow King <mr.meowking@anche.no>

;; This file is NOT part of Emacs.
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file provide some utility functions for developing `typst-ts-mode'
;; It is not supposed to be loaded by package managers.

;; gain the functions here by evaluating buffer.

;;; Code:

(require 'treesit)

(defun typst-ts/util/setup-indent-debug-environment ()
  (interactive)
  (setq debug-on-error t
        treesit--indent-verbose t)
  (treesit-explore-mode 1)
  (treesit-inspect-mode 1)

  ;; note that when in intensive testing, you'd better turn off `auto-save-visited-mode'
  (whitespace-mode 1))

(defun typst-ts/util/setup-fontification-debug-environment ()
  (interactive)
  (setq
   ;; treesit--font-lock-verbose t
   debug-on-error t)

  (treesit-explore-mode 1)
  (treesit-inspect-mode 1))

(defun typst-ts/util/els/get-all-ts-major-modes ()
  "Get all tree sitter major modes from `treesit-auto'."
  (require 'treesit-auto)
  (require 'eglot)
  (let (treesit-auto-ts-modes local-ts-modes)
    (setq treesit-auto-ts-modes
          (seq-map #'treesit-auto-recipe-ts-mode treesit-auto-recipe-list)
          local-ts-modes
          (cl-loop for major-mode in (eglot--all-major-modes)
                   when (string-suffix-p "ts-mode" (symbol-name major-mode))
                   collect major-mode))
    (seq-uniq (nconc treesit-auto-ts-modes local-ts-modes))))

;; (message "%s" (typst-ts/util/els/get-all-ts-major-modes))

