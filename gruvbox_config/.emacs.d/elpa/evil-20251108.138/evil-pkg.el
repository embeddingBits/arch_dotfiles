;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "evil" "20251108.138"
  "Extensible vi layer."
  '((emacs    "24.1")
    (cl-lib   "0.5")
    (goto-chg "1.6")
    (nadvice  "0.3"))
  :url "https://github.com/emacs-evil/evil"
  :commit "729d9a58b387704011a115c9200614e32da3cefc"
  :revdesc "729d9a58b387"
  :keywords '("emulations")
  :maintainers '(("Tom Dalziel" . "tom.dalziel@gmail.com")))
