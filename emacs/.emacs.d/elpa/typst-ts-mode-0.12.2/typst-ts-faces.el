;;; typst-ts-faces.el --- typst-ts-mode faces  -*- lexical-binding: t; -*-

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

;; Face definitions.

;;; Code:

(defgroup typst-ts-faces nil
  "Typst tree sitter faces."
  :prefix "typst-ts-faces"
  :group 'typst-ts)

(defcustom typst-ts-markup-header-same-height t
  "Whether to make header face in markup context share the same height."
  :type 'boolean)

(defcustom typst-ts-markup-header-scale
  '(2.0 1.7 1.4 1.1 1.0 1.0)
  "Header Scale for each header level, starting from = to ======."
  :type '(list number number number number number number))

;; Face  =========================================================================
(defface typst-ts-watch-modeline-indicator-face
  '((t :inherit (underline bold)))
  "Face for typst watch modeline indicator.")

;; Common Face ==================================================================

(defface typst-ts-shorthand-face
  '((t :inherit shadow))
  "Face for linebreak."
  :group 'typst-ts-faces)

(defface typst-ts-error-face
  '((t :inherit font-lock-warning-face))
  "Face for linebreak."
  :group 'typst-ts-faces)

;; Markup Faces =================================================================

(defface typst-ts-markup-header-indicator-face
  '((t :weight bold))
  "Face for Typst ts markup header indicator."
  :group 'typst-ts-faces)

(defface typst-ts-markup-header-face
  '((t :weight bold))
  "Face for Typst ts markup headers text."
  :group 'typst-ts-faces)

(defface typst-ts-markup-header-indicator-face-1
  `((t :inherit typst-ts-markup-header-indicator-face
       :height ,(nth 0 typst-ts-markup-header-scale)))
  "See `typst-ts-markup-header-indicator-face'."
  :group 'typst-ts-faces)

(defface typst-ts-markup-header-face-1
  `((t :inherit typst-ts-markup-header-face
       :height ,(nth 0 typst-ts-markup-header-scale)))
  "See `typst-ts-markup-header-face'."
  :group 'typst-ts-faces)

(defface typst-ts-markup-header-indicator-face-2
  `((t :inherit typst-ts-markup-header-indicator-face
       :height ,(nth 1 typst-ts-markup-header-scale)))
  "See `typst-ts-markup-header-indicator-face'."
  :group 'typst-ts-faces)

(defface typst-ts-markup-header-face-2
  `((t :inherit typst-ts-markup-header-face
       :height ,(nth 1 typst-ts-markup-header-scale)))
  "See `typst-ts-markup-header-face'."
  :group 'typst-ts-faces)

(defface typst-ts-markup-header-indicator-face-3
  `((t :inherit typst-ts-markup-header-indicator-face
       :height ,(nth 2 typst-ts-markup-header-scale)))
  "See `typst-ts-markup-header-indicator-face'."
  :group 'typst-ts-faces)

(defface typst-ts-markup-header-face-3
  `((t :inherit typst-ts-markup-header-face
       :height ,(nth 2 typst-ts-markup-header-scale)))
  "See `typst-ts-markup-header-face'."
  :group 'typst-ts-faces)

(defface typst-ts-markup-header-indicator-face-4
  `((t :inherit typst-ts-markup-header-indicator-face
       :height ,(nth 3 typst-ts-markup-header-scale)))
  "See `typst-ts-markup-header-indicator-face'."
  :group 'typst-ts-faces)

(defface typst-ts-markup-header-face-4
  `((t :inherit typst-ts-markup-header-face
       :height ,(nth 3 typst-ts-markup-header-scale)))
  "See `typst-ts-markup-header-face'."
  :group 'typst-ts-faces)

(defface typst-ts-markup-header-indicator-face-5
  `((t :inherit typst-ts-markup-header-indicator-face
       :height ,(nth 4 typst-ts-markup-header-scale)))
  "See `typst-ts-markup-header-indicator-face'."
  :group 'typst-ts-faces)

(defface typst-ts-markup-header-face-5
  `((t :inherit typst-ts-markup-header-face
       :height ,(nth 4 typst-ts-markup-header-scale)))
  "See `typst-ts-markup-header-face'."
  :group 'typst-ts-faces)

(defface typst-ts-markup-header-indicator-face-6
  `((t :inherit typst-ts-markup-header-indicator-face
       :height ,(nth 5 typst-ts-markup-header-scale)))
  "See `typst-ts-markup-header-indicator-face'."
  :group 'typst-ts-faces)

(defface typst-ts-markup-header-face-6
  `((t :inherit typst-ts-markup-header-face
       :height ,(nth 5 typst-ts-markup-header-scale)))
  "See `typst-ts-markup-header-face'."
  :group 'typst-ts-faces)

(defface typst-ts-markup-url-face
  '((t :inherit link))
  "Face for url."
  :group 'typst-ts-faces)

(defface typst-ts-markup-emphasis-indicator-face
  '((t :inherit italic))
  "Face for emphasis."
  :group 'typst-ts-faces)

(defface typst-ts-markup-emphasis-face
  '((t :inherit italic))
  "Face for emphasis."
  :group 'typst-ts-faces)

(defface typst-ts-markup-strong-indicator-face
  '((t :inherit bold))
  "Face for strong."
  :group 'typst-ts-faces)

(defface typst-ts-markup-strong-face
  '((t :inherit bold))
  "Face for strong."
  :group 'typst-ts-faces)

(defface typst-ts-markup-item-indicator-face
  '((t :inherit shadow))
  "Face for item."
  :group 'typst-ts-faces)

(defface typst-ts-markup-term-indicator-face
  '((t :inherit shadow))
  "Face for term indicator."
  :group 'typst-ts-faces)

(defface typst-ts-markup-term-term-face
  '((t :inherit bold))
  "Face for term text."
  :group 'typst-ts-faces)

(defface typst-ts-markup-term-description-face
  '((t :inherit italic))
  "Face for term description."
  :group 'typst-ts-faces)

(defface typst-ts-markup-quote-face
  '((t :inherit shadow))
  "Face for quote."
  :group 'typst-ts-faces)

(defface typst-ts-markup-linebreak-face
  '((t :inherit escape-glyph))
  "Face for linebreak."
  :group 'typst-ts-faces)

(defface typst-ts-markup-escape-face
  '((t :inherit escape-glyph))
  "Face for linebreak."
  :group 'typst-ts-faces)

(defface typst-ts-markup-raw-indicator-face
  '((t :inherit shadow))
  "Face for rawblock and rawspan indicator."
  :group 'typst-ts-faces)

(defface typst-ts-markup-raw-blob-face
  '((t :inherit shadow))
  "Face for rawblock and rawspan blob."
  :group 'typst-ts-faces)

(defface typst-ts-markup-rawblock-indicator-face
  '((t :inherit typst-ts-markup-raw-indicator-face))
  "Face for rawblock indicator."
  :group 'typst-ts-faces)

(defface typst-ts-markup-rawblock-lang-face
  '((t :inherit font-lock-type-face))
  "Face for rawspan ident."
  :group 'typst-ts-faces)

(defface typst-ts-markup-rawblock-blob-face
  '((t :inherit typst-ts-markup-raw-blob-face))
  "Face for rawblock blob."
  :group 'typst-ts-faces)

(defface typst-ts-markup-rawspan-indicator-face
  '((t :inherit typst-ts-markup-raw-indicator-face))
  "Face for rawspan indicator."
  :group 'typst-ts-faces)

(defface typst-ts-markup-rawspan-blob-face
  '((t :inherit typst-ts-markup-raw-blob-face))
  "Face for rawspan blob."
  :group 'typst-ts-faces)

(defface typst-ts-markup-label-face
  '((t :inherit homoglyph))
  "Face for label."
  :group 'typst-ts-faces)

(defface typst-ts-markup-reference-face
  '((t :inherit homoglyph))
  "Face for reference."
  :group 'typst-ts-faces)

;; Code Faces ===================================================================

(defface typst-ts-code-indicator-face
  '((t :inherit shadow))
  "Face for code indicator #."
  :group 'typst-ts-faces)

;; Math Faces ===================================================================

(defface typst-ts-math-indicator-face
  '((t :inherit shadow))
  "Face for math indicator $."
  :group 'typst-ts-faces)

;; code from Auctex
(defface typst-ts-superscript-face
  '((t (:height 0.85)))
  "Face used for superscripts."
  :group 'typst-ts-faces)

;; code from Auctex
(defface typst-ts-subscript-face
  '((t (:height 0.85)))
  "Face used for subscripts."
  :group 'typst-ts-faces)

;; code from Auctex
(defface typst-ts-script-char-face
  (let ((font '(:inherit underline)))
    `((((class grayscale) (background light))
       (:foreground "gray25" ,@font))
      (((class grayscale) (background dark))
       (:foreground "gray" ,@font))
      (((class color) (background light))
       (:foreground "DarkRed"))
      (((class color) (background dark))
       (:foreground "salmon"))
      (t (,@font))))
  "Face used for the script chars ^ and _."
  :group 'typst-ts-faces)

(provide 'typst-ts-faces)

;;; typst-ts-faces.el ends here
