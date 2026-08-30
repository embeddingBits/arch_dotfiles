;;; typst-ts-watch-mode.el --- Watch typst file  -*- lexical-binding: t; -*-
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

;; Minor mode for watching(hot compile) current typst file.

;;; Code:

(require 'typst-ts-compile)
(require 'typst-ts-variables)

(defgroup typst-ts-watch nil
  "Typst TS Watch."
  :prefix "typst-ts-watch"
  :group 'typst-ts)

(define-minor-mode typst-ts-watch-mode
  "Watch(hot compile) current typst file."
  :lighter " [Watch]"
  :group 'typst-ts-watch
  (if typst-ts-watch-mode
      (typst-ts-watch-start)
    (typst-ts-watch-stop)))


(defun typst-ts-watch--process-filter (proc output)
  "Filter the `typst watch' process output.
Only error will be transported to the process buffer.
See `(info \"(elisp) Filter Functions\")'.
PROC: process; OUTPUT: new output from PROC."
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (erase-buffer)
      (let ((window (get-buffer-window))
            (re (rx bol "error:" (+ not-newline) "\n" (+ blank) "┌─ "
                    (+ not-newline) ":"  ; file
                    (+ num) ":"  ; start-line
                    (+ num) "\n"  ; start-col
                    (+ (+ (or blank num)) "│" (* not-newline) "\n")))
            (next-match-start-pos 0)
            res-output)
        (while (string-match re output next-match-start-pos)
          (setq res-output (concat
                            res-output
                            (when res-output "\n")
                            (substring output (match-beginning 0) (match-end 0)))
                next-match-start-pos (match-end 0)))
        ;; Insert the Error text
        (if (not res-output)
            (when (and typst-ts-watch-auto-display-compilation-error window)
              (delete-window window))
          (insert res-output)
          (goto-char (point-min))
          (when typst-ts-watch-auto-display-compilation-error
            (typst-ts-watch-display-buffer)))))))

;;;###autoload
(defun typst-ts-watch-display-buffer ()
  "Display typst watch process buffer."
  (interactive)
  (when (and (called-interactively-p 'interactive)
             (not (buffer-live-p typst-ts-watch-process-buffer-name)))
    (user-error "The typst watch process buffer '%s' is not alive!" typst-ts-watch-process-buffer-name))
  (let ((buf (get-buffer-create typst-ts-watch-process-buffer-name)))
    (display-buffer buf typst-ts-watch-display-buffer-parameters)))

;;;###autoload
(defun typst-ts-watch-start ()
  "Watch(hot compile) current typst file."
  (interactive)
  (run-hooks typst-ts-watch-before-watch-hook)
  (with-current-buffer (get-buffer-create typst-ts-watch-process-buffer-name)
    (erase-buffer)
    (unless (derived-mode-p 'typst-ts-compilation-mode)
      (typst-ts-compilation-mode)
      (read-only-mode -1)))
  (set-process-filter
   (apply
    #'start-process
    typst-ts-watch-process-name typst-ts-watch-process-buffer-name
    typst-ts-compile-executable-location
    "watch"
    (file-name-nondirectory buffer-file-name)
    (typst-ts-compile-get-result-pdf-filename)
    typst-ts-watch-options)
   'typst-ts-watch--process-filter)
  (message "Start Watch"))

;;;###autoload
(defun typst-ts-watch-stop ()
  "Stop watch process."
  (interactive)
  (delete-process typst-ts-watch-process-name)
  ;; delete associated watch process buffer and window
  (let ((window (get-buffer-window typst-ts-watch-process-buffer-name)))
    (kill-buffer typst-ts-watch-process-buffer-name)
    (when window
      (delete-window window)))
  (run-hooks typst-ts-watch-after-watch-hook)
  (message "Stop Watch"))

(provide 'typst-ts-watch-mode)
;;; typst-ts-watch-mode.el ends here
