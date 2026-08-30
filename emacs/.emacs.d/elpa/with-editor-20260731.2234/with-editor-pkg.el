;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "with-editor" "20260731.2234"
  "Use the Emacsclient as $EDITOR."
  '((emacs    "28.1")
    (compat   "31.0")
    (cond-let "1.1")
    (llama    "1.0"))
  :url "https://github.com/magit/with-editor"
  :commit "a1f92a26e53033ec58e1d2ce9b132da7ebae816e"
  :revdesc "a1f92a26e530"
  :keywords '("processes" "terminals")
  :authors '(("Jonas Bernoulli" . "emacs.with-editor@jonas.bernoulli.dev"))
  :maintainers '(("Jonas Bernoulli" . "emacs.with-editor@jonas.bernoulli.dev")))
