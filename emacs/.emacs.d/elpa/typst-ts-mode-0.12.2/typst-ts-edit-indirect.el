;;; typst-ts-watch-mode.el --- Edit blocks in separate buffer  -*- lexical-binding: t; -*-

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

;; Integration with edit-indirect.  Get it from <https://github.com/Fanael/edit-indirect/>.

;;; Code:

(require 'typst-ts-embedding-lang-settings)
(require 'edit-indirect nil t)
(defvar edit-indirect-guess-mode-function)
(defvar edit-indirect-after-commit-functions)

(defun typst-ts-edit-indirect--guess-mode (parent-buffer beg _end)
  "Guess the mode for `edit-indirect-guess-mode-function'.
BEG in the PARENT-BUFFER will be used to traverse the treesitter tree to
lang: (ident).

By default the treesit mode will be preferred.
If the user does not have the grammar installed it will fallback to the
non treesitter mode.
If there is no fitting mode or no lang it will be `normal-mode'."
  (let* ((lang (treesit-node-text
                (treesit-node-child-by-field-name
                 (treesit-node-parent
                  (with-current-buffer parent-buffer
                    (treesit-node-at beg 'typst)))
                 "lang")))
         (lang (gethash lang typst-ts-els-tag-lang-map))
         (lang (when lang  ; TODO
                 (if (eq lang 'cpp)
                     "c++"
                   (symbol-name lang))))
         (ts-mode (intern-soft
                   (concat lang "-ts-mode")))
         (non-ts-mode (intern-soft
                       (concat lang "-mode"))))
    (cond
     ((not lang) (normal-mode))
     ((and (treesit-language-available-p (intern lang) nil)
           (fboundp ts-mode))
      (funcall ts-mode))
     ((fboundp non-ts-mode) (funcall non-ts-mode))
     (t (normal-mode)))))

(defun typst-ts-edit-indirect ()
  "Edit the block at point with `edit-indirect-region'."
  (interactive)
  (unless (fboundp 'edit-indirect-region)
    (user-error "You need to install package edit-indirect to enable editing in another buffer"))
  (let* ((block (treesit-parent-until
                 (treesit-node-at (point) 'typst)
                 (lambda (node)
                   (string= (treesit-node-type node) "raw_blck"))
                 t))
         (_ (unless block (user-error "Point is not on a raw block")))
         (blob (car (treesit-filter-child
                     block
                     (lambda (node)
                       (string= (treesit-node-type node) "blob")))))
         (beg (treesit-node-start blob))
         (end (treesit-node-end blob)))
    ;; when beg and end are on the same line it will look like:
    ;; ```lang content```
    ;; although it is valid syntax, I think it should be handled because if you
    ;; want to edit a raw block in a separate buffer you are
    ;; probably going to insert newlines
    ;; it is handled by inserting 2 newlines
    (if (= (line-number-at-pos beg) (line-number-at-pos end))
        (progn (save-excursion
                 (goto-char end)
                 (newline)
                 (goto-char beg)
                 ;; when there is content
                 ;; it will include the space between lang and content
                 (unless (= beg end)
                   (delete-char 1))
                 (newline))
               (typst-ts-edit-indirect))
      ;; beg sadly starts at the line with the lang
      ;; beg needs to be the next line
      (setq beg (1+ beg))
      ;; when beg and end are the same now it will look like
      ;; ```lang
      ;; ```
      ;; when this is the case a newline must be added
      ;; end will be at the beginning of the closing ```
      (when (= beg end)
        (save-excursion
          (goto-char beg)
          (newline)
          (setq end (line-beginning-position))))
      ;; in the block, there needs to be a space when it is empty
      ;; `edit-indirect-region' does not like editing empty blocks
      (save-excursion
        (goto-char beg)
        (insert " "))
      (when (fboundp 'edit-indirect-region)  ; pass elisp's dumb linter
        (edit-indirect-region beg end t))
      ;; delete the inserted space
      (save-excursion
        (goto-char (point-min))
        (delete-char 1)))))

(provide 'typst-ts-edit-indirect)
;;; typst-ts-edit-indirect.el ends here
