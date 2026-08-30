;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "evil" "20260728.1438"
  "Extensible vi layer."
  '((emacs    "24.1")
    (cl-lib   "0.5")
    (goto-chg "1.6")
    (nadvice  "0.3"))
  :url "https://github.com/emacs-evil/evil"
  :commit "6a3e1ddd04ac504a016590940d0af2a3361b9efd"
  :revdesc "6a3e1ddd04ac"
  :keywords '("emulations")
  :maintainers '(("Tom Dalziel" . "tom.dalziel@gmail.com")))
