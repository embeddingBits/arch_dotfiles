;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "magit" "20260822.1158"
  "A Git porcelain inside Emacs."
  '((emacs         "28.1")
    (compat        "31.0")
    (cond-let      "1.1")
    (llama         "1.0")
    (magit-section "4.7")
    (seq           "2.24")
    (transient     "0.13")
    (with-editor   "3.5"))
  :url "https://github.com/magit/magit"
  :commit "137f137dccb37097ae9caa31018cafa071ff4ec1"
  :revdesc "137f137dccb3"
  :keywords '("git" "tools" "vc")
  :authors '(("Marius Vollmer" . "marius.vollmer@gmail.com")
             ("Jonas Bernoulli" . "emacs.magit@jonas.bernoulli.dev"))
  :maintainers '(("Jonas Bernoulli" . "emacs.magit@jonas.bernoulli.dev")
                 ("Kyle Meyer" . "kyle@kyleam.com")))
