;;; typst-ts-misc-commands.el --- Miscellaneous commands for typst-ts-mode -*- lexical-binding: t; -*-

;; Copyright (C) 2023-2025 The typst-ts-mode Project Contributors

;; This file is NOT part of GNU Emacs.
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

;; Miscellaneous commands

;;; Code:

(require 'treesit)

(defun typst-ts-mc-open-thing-function (thing type)
  "Open THING which is of TYPE.
TYPE is one of the following symbols: (local url)

If it is url it will open it outside Emacs.
When it is local it will open it inside Emacs (THING will be a relative link)."
  (pcase-exhaustive type
    ('url
     (browse-url thing))
    ('local
     (find-file thing))))

(defcustom typst-ts-mc-open-function #'typst-ts-mc-open-thing-function
  "The function that is called by `typst-ts-mc-open-at-point'."
  :type 'function
  :group 'typst)

(defun typst-ts-mc-install-grammar ()
  "Install Typst grammar."
  (interactive)
  (let ((treesit-language-source-alist
         (cons '(typst "https://github.com/Ziqi-Yang/tree-sitter-typst")
               treesit-language-source-alist)))
    (treesit-install-language-grammar 'typst)))


(defun typst-ts-mc-export-to-markdown ()
  "Export current file to markdown.
Require pandoc to be installed."
  (interactive)

  ;; for simplicity
  ;; TODO: suggest saving the buffer
  (unless buffer-file-name
    (user-error "You should save the file first!"))

  (when (equal (file-name-extension buffer-file-name) "md")
    (user-error "Couldn't operate on a Typst file with `md' as its extension!"))

  (let* ((base-path (file-name-directory buffer-file-name))
         (file-name (file-relative-name buffer-file-name base-path))
         (output-file-name
          (file-name-with-extension file-name "md"))
         (buffer-name (format "*pandoc %s*" file-name)))
    ;; TODO: check if installed pandoc supports typst
    (start-process "pandoc"
                   buffer-name
                   "pandoc" "-o" output-file-name file-name)
    (display-buffer buffer-name)))

(defun typst-ts-mc-search-typst-symbol ()
  "Search typst symbols through website."
  (interactive)
  (browse-url "https://typst.app/docs/reference/symbols/sym/"))

(defun typst-ts-mc-recognize-typst-symbol ()
  "Recognize hand-written symbols through website."
  (interactive)
  (browse-url "https://detypify.quarticcat.com/"))

(defun typst-ts-mc-search-package ()
  "Search typst packages through website."
  (interactive)
  (browse-url "https://typst.app/universe"))

(defun typst-ts-mc-open-at-point ()
  "Follow thing at point.

By default it will call `typst-ts-mc-open-thing-function'.
Default behavior can be changed in `typst-ts-mc-open-function'."
  (interactive)
  (let ((node (treesit-node-at (point)))
        type thing)
    (if (string= (treesit-node-type node) "url")
        (funcall typst-ts-mc-open-function
                 (treesit-node-text node)
                 'url)
      (setq node (treesit-node-parent node))
      (setq type (treesit-node-type node))
      ;; remove the quotes in "text"
      (setq thing (substring (treesit-node-text node) 1 -1))
      (if (and (string= type "string")
               (file-exists-p thing))
          (funcall typst-ts-mc-open-function
                   thing
                   'local)
        (user-error "Not on an openable thing")))))

(defun typst-ts-mc-insert-link ()
  "Insert a local relative file link."
  (interactive)
  (let ((link (read-file-name "File: ")))
    (when (or (not link) (= (length link) 0))
      (user-error "No input"))
    (insert (file-relative-name link))))

(provide 'typst-ts-misc-commands)

;;; typst-ts-misc-commands.el ends here
