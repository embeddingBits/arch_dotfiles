;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "rg" "20260823.1828"
  "A search tool based on ripgrep."
  '((emacs     "28.1")
    (transient "0.9.2")
    (wgrep     "2.1.10"))
  :url "https://github.com/dajva/rg.el"
  :commit "6b00e2ae98c47cf7ea04d26636e11b7fa2a540e3"
  :revdesc "6b00e2ae98c4"
  :keywords '("matching" "tools")
  :authors '(("David Landell" . "david.landell@sunnyhill.email")
             ("Roland McGrath" . "roland@gnu.org"))
  :maintainers '(("David Landell" . "david.landell@sunnyhill.email")
                 ("Roland McGrath" . "roland@gnu.org")))
