;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "rg" "20251022.457"
  "A search tool based on ripgrep."
  '((emacs     "28.1")
    (transient "0.9.2")
    (wgrep     "2.1.10"))
  :url "https://github.com/dajva/rg.el"
  :commit "9ff6cb24bda58f481886ebaf16b524f4f9b3769c"
  :revdesc "9ff6cb24bda5"
  :keywords '("matching" "tools")
  :authors '(("David Landell" . "david.landell@sunnyhill.email")
             ("Roland McGrath" . "roland@gnu.org"))
  :maintainers '(("David Landell" . "david.landell@sunnyhill.email")
                 ("Roland McGrath" . "roland@gnu.org")))
