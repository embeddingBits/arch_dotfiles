;;; typst-ts-transient.el --- Transient menu for typst-ts-mode -*- lexical-binding: t; -*-
;; Copyright (C) 2023-2024 The typst-ts-mode Project Contributors

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

;; Miscellaneous commands

;;; Code:

(require 'transient)
(require 'typst-ts-compile)
(require 'typst-ts-misc-commands)

(transient-define-prefix typst-ts-tmenu ()
  "`typst-ts-mode' transient menu."
  [["Compile"
    ("c" "compile & preview" typst-ts-compile-and-preview)
    ("C" "compile" typst-ts-compile)
    ("w" "watch" typst-ts-watch-mode)
    ("p" "preview" typst-ts-preview)]

   ["Export"
    ("em" "markdown" typst-ts-mc-export-to-markdown)]

   ["Search"
    ("ss" "symbol" typst-ts-mc-search-typst-symbol)
    ("sr" "recognize symbol" typst-ts-mc-recognize-typst-symbol)
    ("sp" "package" typst-ts-mc-search-package)]])


(provide 'typst-ts-transient)

;;; typst-ts-transient.el ends here
