;;; cond-let.el --- Additional and improved binding conditionals  -*- lexical-binding:t -*-

;; Copyright (C) 2025-2026 Jonas Bernoulli

;; May contain traces of Emacs, which is
;; Copyright (C) 1985-2025 Free Software Foundation, Inc.

;; Authors: Jonas Bernoulli <emacs.cond-let@jonas.bernoulli.dev>
;; Homepage: https://github.com/tarsius/cond-let
;; Keywords: extensions

;; Package-Version: 20260101.1828
;; Package-Revision: 0430bd1eb349
;; Package-Requires: ((emacs "28.1"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This is an ALPHA release!
;; Breaking changes are possible!

;; Emacs provides the binding conditionals `if-let', `if-let*',
;; `when-let', `when-let*', `and-let*' and `while-let'.

;; This package implements the missing `and-let' and `while-let*',
;; and the original `cond-let', `cond-let*', `and$' and `and>'.

;; This package additionally provides more consistent and improved
;; implementations of the binding conditionals already provided by
;; Emacs.  Merely loading this library does not shadow the built-in
;; implementations; this can optionally be done in the context of
;; an individual library, as described below.

;; `cond-let' and `cond-let*' are provided exactly under these names.
;; The names of all other macros implemented by this package begin
;; with `cond-let--', the package's prefix for private symbol.

;; Users of this package are not expected to use these unwieldy
;; names.  Instead one should use Emacs' shorthand feature to use
;; all or some of these macros by their conceptual names.  E.g., if
;; you want to use all of the available macros, add this at the end
;; of a library.

;; Local Variables:
;; read-symbol-shorthands: (
;;   ("and$"      . "cond-let--and$")
;;   ("and>"      . "cond-let--and>")
;;   ("and-let"   . "cond-let--and-let")
;;   ("if-let"    . "cond-let--if-let")
;;   ("when-let"  . "cond-let--when-let")
;;   ("while-let" . "cond-let--while-let"))
;; End:

;; You can think of these file-local settings as import statements of
;; sorts.  If you do this, then this package's implementations shadow
;; the built-in implementations.  Doing so does not affect any other
;; libraries, which continue to use the built-in implementations.

;; Due to limitations of the shorthand implementation this has to be
;; done for each individual library.  "dir-locals.el" cannot be used.

;; If you use `and$' and `and>', you might want to add this to your
;; configuration:

;;   (with-eval-after-load 'cond-let
;;     (font-lock-add-keywords 'emacs-lisp-mode
;;                             cond-let-font-lock-keywords t))

;; For information about the individual macros, please refer to their
;; docstrings.

;; See also https://github.com/tarsius/cond-let/wiki.

;;; Code:
;;; Cond

(defun cond-let--prepare-clauses (tag sequential clauses)
  "Used by macros `cond-let*' and `cond-let'."
  (let (body)
    (dolist (clause (nreverse clauses))
      (cond
        ((vectorp clause)
         (setq body
               `((,(if (and sequential (length> clause 1)) 'let* 'let)
                  ,(mapcar (lambda (vec) (append vec nil)) clause)
                  ,@body))))
        ((let (varlist)
           (while (vectorp (car clause))
             (push (append (pop clause) nil) varlist))
           (push (cond
                   (varlist
                    `(,(pcase (list (and body t)
                                    (and sequential (length> varlist 1)))
                         ('(t   t ) 'cond-let--when-let*)
                         (`(t   ,_) 'cond-let--when-let)
                         ('(nil t ) 'cond-let--and-let*)
                         (`(nil ,_) 'cond-let--and-let))
                      ,(nreverse varlist)
                      ,(if body
                           `(throw ',tag ,(macroexp-progn clause))
                         (macroexp-progn clause))))
                   ((length= clause 1)
                    (if body
                        (let ((a (gensym "anon")))
                          `(let ((,a ,(car clause)))
                             (when ,a (throw ',tag ,a))))
                      (car clause)))
                   ((and (eq (car clause) t) (not body))
                    (macroexp-progn (cdr clause)))
                   (t
                    `(when ,(pop clause)
                       (throw ',tag ,(macroexp-progn clause)))))
                 body)))))
    body))

(defmacro cond-let* (&rest clauses)
  "Try each clause until one succeeds.

Each clause has one of these forms:
- a plain clause   (CONDITION BODY...)
- a binding clause ([SYMBOL VALUEFORM]... BODY...)
- a binding vector [[SYMBOL VALUEFORM]...]

A (CONDITION BODY...) clause works as for `cond'.  Evaluate CONDITION,
and if it yields non-nil, the clause succeeds.  Then evaluate BODY forms
sequentially and return the value of the last; or if there are no BODY
forms, return the value of CONDITION.  If CONDITION yields nil, do not
evaluate the BODY forms and instead proceed to the next clause.

A ([SYMBOL VALUEFORM]... BODY...) clause begins with one or more binding
vectors, followed by one or more BODY forms.  Bind SYMBOL to the value
of VALUEFORM.  Each VALUEFORM can refer to symbols already bound by this
VARLIST (as for `let*').

If all VALUEFORMs yield non-nil, evaluate BODY forms sequentially, with
VARLIST's bindings in effect, and return the value of the last form.

If any VALUEFORM yields nil, evaluate neither the remaining VALUEFORMs
nor the BODY forms, and proceed to the next clause.

A [[SYMBOL VALUEFORM]...] form creates bindings, which extend to all
remaining clauses and binding vectors.  Unlike for the previous form,
always bind all SYMBOLs, even if a VALUEFORM yields nil.  Always proceed
to the next clause."
  (declare (indent 0)
           (debug (&rest [&or
                          (vector &rest (vector symbolp form))
                          ([&rest (vector symbolp form)] body)
                          (form body)])))
  (let ((tag (gensym ":cond-let*")))
    `(catch ',tag
       ,@(cond-let--prepare-clauses tag t clauses))))

(defmacro cond-let (&rest clauses)
  "Try each clause until one succeeds.

Each clause has one of these forms:
- a plain clause   (CONDITION BODY...)
- a binding clause ([SYMBOL VALUEFORM]... BODY...)
- a binding vector [[SYMBOL VALUEFORM]...]

A (CONDITION BODY...) clause works as for `cond'.  Evaluate CONDITION,
and if it yields non-nil, the clause succeeds.  Then evaluate BODY forms
sequentially and return the value of the last; or if there are no BODY
forms, return the value of CONDITION.  If CONDITION yields nil, do not
evaluate the BODY forms and instead proceed to the next clause.

A ([SYMBOL VALUEFORM]... BODY...) clause begins with one or more binding
vectors, followed by one or more BODY forms.  Bind SYMBOL to the value
of VALUEFORM.  Evaluate all VALUEFORMs before binding their respective
SYMBOLs (as for `let').

If all VALUEFORMs yield non-nil, evaluate BODY forms sequentially, with
VARLIST's bindings in effect, and return the value of the last form.

If any VALUEFORM yields nil, evaluate neither the remaining VALUEFORMs
nor the BODY forms, and proceed to the next clause.

A [[SYMBOL VALUEFORM]...] form creates bindings, which extend to all
remaining clauses and binding vectors.  Evaluate all VALUEFORMs before
binding their respective SYMBOLs.  Unlike for the previous form, bind
all SYMBOLs, even if a VALUEFORM yields nil.  Always proceed to the
next clause."
  (declare (indent 0) (debug cond-let*))
  (let ((tag (gensym ":cond-let")))
    `(catch ',tag
       ,@(cond-let--prepare-clauses tag nil clauses))))

;;; Common

(defun cond-let--prepare-varlist (varlist)
  "Used by Cond-Let's `when-let*', `and-let*' and `while-let*'.
Also used by other macros via `cond-let--prepare-varforms'.
Return (VARLIST LASTVAR)."
  (let (prevvar)
    (list (mapcar (lambda (binding)
                    (unless (length= binding 2)
                      (signal 'error (cons "Invalid binding" binding)))
                    (pcase-let ((`(,var ,form) binding))
                      (when (string-prefix-p "_" (symbol-name var))
                        (setq var (gensym "anon")))
                      (prog1 (if prevvar
                                 `(,var (and ,prevvar ,form))
                               (list var form))
                        (setq prevvar var))))
                  varlist)
          prevvar)))

(defun cond-let--prepare-varforms (varlist &optional if-let)
  "Used by Cond-Let's `when-let', `and-let', `while-let' and `if-let'.
Return (ANON-VARLIST ANON-SETQ VARLIST LASTVAR), or if the length of
VARLIST is 1 and IF-LET is nil, return (nil nil VARLIST LASTVAR)."
  (if (and (not if-let)
           (length= varlist 1))
      `(nil nil ,@(cond-let--prepare-varlist varlist))
    (let ((triples
           (mapcar (lambda (binding)
                     (unless (length= binding 2)
                       (signal 'error (cons "Invalid binding" binding)))
                     (pcase-let ((`(,var ,form) binding))
                       (when (string-prefix-p "_" (symbol-name var))
                         (setq var nil))
                       (list (and var (gensym "anon"))
                             var
                             form)))
                   varlist)))
      (list (mapcan (pcase-lambda (`(,anon ,_ ,_))
                      (and anon (list anon)))
                    triples)
            (mapcar (pcase-lambda (`(,anon ,_ ,form))
                      (if anon
                          `(setq ,anon ,form)
                        form))
                    triples)
            (mapcan (pcase-lambda (`(,anon ,var ,_))
                      (and var `((,var ,anon))))
                    triples)
            (cadr (car (last triples)))))))

;;; And

(defmacro cond-let--and-let* (varlist &optional bodyform)
  "Bind according to VARLIST until one yields nil, else evaluate BODYFORM.

Each element of VARLIST is a list (SYMBOL VALUEFORM), which binds SYMBOL
to the value of VALUEFORM.  Each VALUEFORM can refer to symbols already
bound by this VARLIST (as for `let*').

Evaluate VALUEFORMs until on of them yields nil.  If that happens return
nil, and evaluate neither the remaining VALUEFORMs nor BODYFORM.  If all
VALUEFORMs yield non-nil, evaluate BODYFORM with the bindings in effect,
and return its value; or if there is no BODYFORM, the value of the last
VALUEFORM."
  (declare (indent 1)
           (debug ((&rest (symbolp form)) form)))
  (pcase-let ((`(,varlist ,lastvar)
               (cond-let--prepare-varlist varlist)))
    `(let* ,varlist
       ,(if bodyform
            `(and ,lastvar ,bodyform)
          lastvar))))

(defmacro cond-let--and-let (varlist &optional bodyform)
  "Bind according to VARLIST until one yields nil, else evaluate BODYFORM.

Each element of VARLIST is a list (SYMBOL VALUEFORM), which binds SYMBOL
to the value of VALUEFORM.  Evaluate all VALUEFORMs before binding their
respective SYMBOLs (as for `let').

Evaluate VALUEFORMs until on of them yields nil.  If that happens return
nil, and evaluate neither the remaining VALUEFORMs nor BODYFORM.  If all
VALUEFORMs yield non-nil, evaluate BODYFORM with the bindings in effect,
and return its value; or if there is no BODYFORM, the value of the last
VALUEFORM."
  (declare (indent 1) (debug cond-let--and-let*))
  (pcase-let ((`(,anon ,set ,bind ,lastvar)
               (cond-let--prepare-varforms varlist)))
    (cond (anon
           `(let ,anon
              (and ,@set
                   (let ,bind
                     ,(or bodyform lastvar)))))
          (t
           `(let ,bind
              ,(if bodyform
                   `(and ,lastvar ,bodyform)
                 lastvar))))))

(defmacro cond-let--and$ (varform bodyform)
  "Bind variable `$' to value of VARFORM and conditionally evaluate BODYFORM.

If VARFORM yields a non-nil value, bind the symbol `$' to that value,
evaluate BODYFORM with that binding in effect, and return the value of
BODYFORM.  If VARFORM yields nil, do not evaluate BODYFORM, and return
nil."
  (declare (debug (form form)))
  `(let (($ ,varform))
     (and $ ,bodyform)))

(defmacro cond-let--and> (form form2 &rest forms)
  "Bind variables according to each VARFORM until one of them yields nil.

Evaluate the first FORM and if that yields a non-nil value, bind the
symbol `$' to that value, and evaluate the next FORM with that binding
in effect.  Repeat this process with subsequent FORMs until one yields
nil, then return nil without evaluate the remaining FORMs.  If all
FORMs yield non-nil, return the value of the last FORM.

\(fn FORM FORM...)"
  (declare (debug (form form body)))
  `(,(if forms 'let* 'let)
    (($ ,form)
     ,@(and forms
            (mapcar (lambda (form)
                      `($ (and $ ,form)))
                    (cons form2 (butlast forms)))))
    (and $
         ,(or (car (last forms))
              form2))))

;;; If

(defmacro cond-let--if-let* (varlist then &rest else)
  "Bind variables according to VARLIST and evaluate THEN or ELSE.

Each element of VARLIST is a list (SYMBOL VALUEFORM), which binds SYMBOL
to the value of VALUEFORM.  Each VALUEFORM can refer to symbols already
bound by this VARLIST (as for `let*').

If all VALUEFORMs yield non-nil, evaluate THEN with VARLIST's bindings
in effect, and return its value.  THEN must be one expression.

If any VALUEFORM yields nil, evaluate ELSE sequentially and return the
value of the last form; or if there are no ELSE forms return nil.  The
bindings from VARLIST do _not_ extend to the ELSE forms.

\(fn VARLIST THEN [ELSE...])"
  (declare (indent 2)
           (debug ((&rest (symbolp form)) form body)))
  (pcase-let ((`(,varlist ,lastvar)
               (cond-let--prepare-varlist varlist))
              (tag (gensym ":if-let*")))
    `(catch ',tag
       (let* ,varlist
         (when ,lastvar
           (throw ',tag ,then)))
       ,@else)))

(defmacro cond-let--if-let (varlist then &rest else)
  "Bind variables according to VARLIST and evaluate THEN or ELSE.

Each element of VARLIST is a list (SYMBOL VALUEFORM), which binds SYMBOL
to the value of VALUEFORM.  Evaluate all VALUEFORMs before binding their
respective SYMBOLs (as for `let').

If all VALUEFORMs yield non-nil, evaluate THEN with VARLIST's bindings
in effect, and return its value.  THEN must be one expression.

If any VALUEFORM yields nil, evaluate ELSE sequentially and return the
value of the last form; or if there are no ELSE forms return nil.  The
bindings from VARLIST do _not_ extend to the ELSE forms.

\(fn VARLIST THEN [ELSE...])"
  (declare (indent 2) (debug cond-let--if-let*))
  (pcase-let* ((`(,anon ,set ,bind ,_)
                (cond-let--prepare-varforms varlist t))
               (set (if (length= set 1) (car set) (cons 'and set))))
    `(let ,anon
       (if ,set
           (let ,bind
             ,then)
         ,@else))))

;;; When

(defmacro cond-let--when-let* (varlist bodyform &rest body)
  "Bind variables according to VARLIST and conditionally evaluate BODY.

Each element of VARLIST is a list (SYMBOL VALUEFORM), which binds SYMBOL
to the value of VALUEFORM.  Each VALUEFORM can refer to symbols already
bound by this VARLIST (as for `let*').

If all VALUEFORMs yield non-nil, evaluate BODY forms sequentially, with
VARLIST's bindings in effect, and return the value of the last form.

If any VALUEFORM yields nil, evaluate neither the remaining VALUEFORMs
nor the BODY forms, and instead return nil.

BODY must be one or more expressions.  If VARLIST is empty, do nothing
and return nil.

\(fn VARLIST BODY...)"
  (declare (indent 1)
           (debug ((&rest (symbolp form)) form body)))
  (pcase-let ((`(,varlist ,lastvar)
               (cond-let--prepare-varlist varlist)))
    `(let* ,varlist
       (when ,lastvar
         ,bodyform ,@body))))

(defmacro cond-let--when-let (varlist bodyform &rest body)
  "Bind variables according to VARLIST and conditionally evaluate BODY.

Each element of VARLIST is a list (SYMBOL VALUEFORM), which binds SYMBOL
to the value of VALUEFORM.  Evaluate all VALUEFORMs before binding their
respective SYMBOLs (as for `let').

If all VALUEFORMs yield non-nil, evaluate BODY forms sequentially, with
VARLIST's bindings in effect, and return the value of the last form.

If any VALUEFORM yields nil, evaluate neither the remaining VALUEFORMs
nor the BODY forms, and instead return nil.

BODY must be one or more expressions.  If VARLIST is empty, do nothing
and return nil.

\(fn VARLIST BODY...)"
  (declare (indent 1) (debug cond-let--when-let*))
  (pcase-let ((`(,anon ,set ,bind ,lastvar)
               (cond-let--prepare-varforms varlist)))
    (cond (anon
           `(let ,anon
              (when (and ,@set)
                (let ,bind
                  ,bodyform ,@body))))
          (t
           `(let ,bind
              (when ,lastvar
                ,bodyform ,@body))))))

(defmacro cond-let--when$ (varform bodyform &rest body)
  "Bind variable `$' to value of VARFORM and conditionally evaluate BODY.

If VARFORM yields a non-nil value, bind the symbol `$' to that value,
evaluate BODY with that binding in effect, and return the value of the
last form.  If VARFORM yields nil, do not evaluate BODY, and return nil.
BODY must be one or more expressions.  If VARLIST is empty, do nothing
and return nil.

\(fn VARLIST BODY...)"
  (declare (debug (form form)))
  `(let (($ ,varform))
     (when $
       ,bodyform ,@body)))

;;; While

(defmacro cond-let--while-let* (varlist &rest body)
  "Bind variables according to VARLIST, conditionally evaluate BODY, and repeat.

Each element of VARLIST is a list (SYMBOL VALUEFORM), which binds SYMBOL
to the value of VALUEFORM.  Each VALUEFORM can refer to symbols already
bound by this VARLIST (as for `let*').

If all VALUEFORMs yield non-nil, evaluate BODY forms sequentially, with
VARLIST's bindings in effect, and repeat the loop.

If any VALUEFORM yields nil, evaluate neither the remaining VALUEFORMs
nor the BODY forms, and instead return, always yielding nil.

BODY can be zero or more expressions.

\(fn VARLIST [BODY...])"
  (declare (indent 1) (debug cond-let--if-let*))
  (pcase-let ((`(,varlist ,lastvar)
               (cond-let--prepare-varlist varlist))
              (tag (gensym ":while-let*")))
    `(catch ',tag
       (while t
         (let* ,varlist
           (if ,lastvar
               ,(macroexp-progn body)
             (throw ',tag nil)))))))

(defmacro cond-let--while-let (varlist bodyform &rest body)
  "Bind variables according to VARLIST, conditionally evaluate BODY, and repeat.

Each element of VARLIST is a list (SYMBOL VALUEFORM), which binds SYMBOL
to the value of VALUEFORM.  Evaluate all VALUEFORMs before binding their
respective SYMBOLs (as for `let').

If all VALUEFORMs yield non-nil, evaluate BODY forms sequentially, with
VARLIST's bindings in effect, and repeat the loop.

If any VALUEFORM yields nil, evaluate neither the remaining VALUEFORMs
nor the BODY forms, and instead return, always yielding nil.

BODY can be one or more expressions.

\(fn VARLIST BODY...)"
  (declare (indent 1) (debug cond-let--if-let*))
  (pcase-let ((`(,anon ,set ,bind ,lastvar)
               (cond-let--prepare-varforms varlist))
              (tag (gensym ":while-let")))
    (cond (anon
           `(catch ',tag
              (while t
                (let ,anon
                  (if (and ,@set)
                      (let ,bind
                        ,bodyform ,@body)
                    (throw ',tag nil))))))
          (t
           `(catch ',tag
              (while t
                (let ,bind
                  (if ,lastvar
                      ,(macroexp-progn (cons bodyform body))
                    (throw ',tag nil)))))))))

;;; Font-Lock

(defvar cond-let-font-lock-keywords
  '(("\\_<\\$\\_>" 0 'font-lock-variable-name-face))
  "Highlight `$' using `font-lock-variable-name-face'.
To add these keywords, add this to your configuration:
\(font-lock-add-keywords \\='emacs-lisp-mode cond-let-font-lock-keywords t)")

(provide 'cond-let)
;;; cond-let.el ends here
