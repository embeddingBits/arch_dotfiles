;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "org-roam" "20260425.1623"
  "A database abstraction layer for Org-mode."
  '((emacs         "27.1")
    (compat        "30.1")
    (org           "9.6")
    (emacsql       "4.3.3")
    (magit-section "4.4.2"))
  :url "https://github.com/org-roam/org-roam"
  :commit "c54c523dec175695645399705606ea19056a3053"
  :revdesc "c54c523dec17"
  :keywords '("org-mode" "roam" "convenience")
  :authors '(("Jethro Kuan" . "jethrokuan95@gmail.com"))
  :maintainers '(("Jethro Kuan" . "jethrokuan95@gmail.com")))
