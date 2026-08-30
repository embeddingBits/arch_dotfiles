;;; typst-ts-editing.el --- Helper functions for editing Typst documents -*- lexical-binding: t; -*-

;; Copyright (C) 2023-2025 The typst-ts-mode Project Contributors

;; This file is NOT part of GNU Emacs.
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

;; For item node, it's recommended to use `+' rather than `<num>.'.  Operations
;; for `<num>.' may not be implemented comprehensively.

;;; Code:

(require 'outline)
(require 'typst-ts-core)
(require 'typst-ts-variables)
(require 'typst-ts-symbols)
(require 'seq)

(defun typst-ts-editing-heading-up ()
  "Switch the current heading with the heading above."
  (interactive)
  (call-interactively #'outline-move-subtree-up))

(defun typst-ts-editing-heading-down ()
  "Switch the current heading with the heading below."
  (interactive)
  (call-interactively #'outline-move-subtree-down))

(defun typst-ts-editing-heading-left ()
  "Increase the heading level."
  (interactive)
  (call-interactively #'outline-promote))

(defun typst-ts-editing-heading-right ()
  "Decrease heading level."
  (interactive)
  (call-interactively #'outline-demote))

(defun typst-ts-editing-heading--at-point-p ()
  "Whether the current line is a heading.
Return the heading node when yes otherwise nil."
  (let ((node (treesit-node-parent
               (treesit-node-at
                (save-excursion
                  (beginning-of-line-text)
                  (point))))))
    (if (string= (treesit-node-type node) "heading")
        node
      nil)))

(defun typst-ts-editing-grid-cell--index (cell grid-cells amount-of-columns)
  "Return a list in form of (row-index column-index) of CELL in GRID-CELLS.
AMOUNT-OF-COLUMNS specifies how many columns one row has.
Indeces are given in 0 index."
  (let ((index (seq-position grid-cells cell #'treesit-node-eq)))
    (list (/ index amount-of-columns)
          (mod index amount-of-columns))))

(defun typst-ts-editing-grid-row--move (direction)
  "Move grid row at point depending on DIRECTION up/down.
DIRECTION is one of following symbols:
`up', `down'."
  (let (to-switch current grid grid-cells row-index rows amount-of-columns cell)
    (seq-setq (grid cell grid-cells) (typst-ts-editing-grid-cell--at-point-p))
    (unless (and grid cell)
      (user-error "Not inside a grid with rows"))
    (setq amount-of-columns (typst-ts-editing-grid--column-number grid))
    (setq row-index
          (car (typst-ts-editing-grid-cell--index
                cell grid-cells amount-of-columns)))
    (setq rows (seq-partition grid-cells amount-of-columns))
    (setq current (seq-elt rows row-index))
    (setq to-switch
          (pcase-exhaustive direction
            ('up
             (progn
               (when (= row-index 0)
                 (user-error "Already on first row"))
               (seq-elt rows (1- row-index))))
            ('down
             (progn
               (when (length= rows (1+ row-index))
                 (user-error "Already on last row"))
               (seq-elt rows (1+ row-index))))))
    (let ((start1 (treesit-node-start (car current)))
          (end1 (treesit-node-end (car (last current))))
          (start2 (treesit-node-start (car to-switch)))
          (end2 (treesit-node-end (car (last to-switch)))))
      (transpose-regions start1 end1 start2 end2))))

(defun typst-ts-editing-grid-row-down ()
  "See `typst-ts-editing-grid-row--move'."
  (interactive)
  (typst-ts-editing-grid-row--move 'down))

(defun typst-ts-editing-grid-row-up ()
  "See `typst-ts-editing-grid-row--move'."
  (interactive)
  (typst-ts-editing-grid-row--move 'up))

(defun typst-ts-editing-grid-cell--move (direction)
  "Move grid cell at point depending on DIRECTION up/down, left/right.
DIRECTION is one of following symbols:
`left', `right', `up', `down'.

Up/down means moving the cell to another row while keeping the column index."
  ;; inside table.header is different from the rest
  (let (grid grid-cells cell to-switch)
    (seq-setq (grid cell grid-cells) (typst-ts-editing-grid-cell--at-point-p))
    (unless (and grid cell)
      (user-error "Not inside a grid cell"))
    (setq to-switch
          (pcase direction
            ((guard (and (memq direction '(down up))
                         (string= "table.header"
                                  (treesit-node-text
                                   (treesit-node-child-by-field-name grid "item")))))
             (user-error "A table.header only has one row"))
            ('left
             ;; skip the , prev twice
             (treesit-node-prev-sibling (treesit-node-prev-sibling cell)))
            ('right
             ;; skip the , that's why next twice
             (treesit-node-next-sibling (treesit-node-next-sibling cell)))
            ((or 'up 'down)
             (let ((amount-of-columns
                    (typst-ts-editing-grid--column-number grid))
                   (select-cell
                    (lambda (row column)
                      (seq-elt
                       (seq-elt
                        (seq-partition
                         grid-cells
                         (typst-ts-editing-grid--column-number grid))
                        row)
                       column)))
                   row column)
               (seq-setq (row column)
                         (typst-ts-editing-grid-cell--index
                          cell grid-cells amount-of-columns))
               (if (eq direction 'up)
                   (progn
                     (when (= 0 row)
                       (user-error "Already on first row"))
                     (funcall select-cell (1- row) column))
                 (when (= row amount-of-columns)
                   (user-error "Already on last row"))
                 (funcall select-cell (1+ row) column))))
            (_ (error "DIRECTION: %s is not one of: `right' `left', `up', `down'"
                      direction))))
    (when (or (not to-switch)
              (string= "tagged" (treesit-node-type to-switch))
              (string= "(" (treesit-node-text to-switch))
              (string= ")" (treesit-node-text to-switch)))
      (user-error "There is no cell in the %s direction" direction))
    (transpose-regions (treesit-node-start cell) (treesit-node-end cell)
                       (treesit-node-start to-switch) (treesit-node-end to-switch))))

(defun typst-ts-editing-item-list-change-type (type)
  "Change the list type of the item list at point to TYPE.
TYPE is a symbol one of: (numbered, ordered, bullet)

1. one
2. two

+ one
+ two

- one
- two"
  (interactive
   (list (intern (completing-read "Choose list type: "
                                  '("numbered" "ordered" "bullet")
                                  nil t))))
  (let ((item (typst-ts-editing-item--at-point-p))
        (previous-item nil)
        (current-type-p nil)
        (marker nil)
        (marker-start nil)
        (new-marker (pcase-exhaustive type
                      ('numbered 1)
                      ('ordered "+")
                      ('bullet "-")))
        (insert-fn nil))
    (unless item
      (user-error "Not on a item list"))
    (setq current-type-p (treesit-node-text (treesit-node-child item 0)))
    (cond
     ((string= "-" current-type-p)
      (setq current-type-p
            (lambda (x)
              (string= "-" (treesit-node-text
                            (treesit-node-child x 0))))))
     ((string= "+" current-type-p)
      (setq current-type-p
            (lambda (x)
              (string= "+" (treesit-node-text
                            (treesit-node-child x 0))))))
     (t
      (setq current-type-p
            (lambda (x)
              (not (= 0 (string-to-number
                         (treesit-node-text
                          (treesit-node-child x 0)))))))))
    (pcase-exhaustive type
      ('numbered
       (setq insert-fn
             (lambda ()
               (insert (format "%d." new-marker))
               (setq new-marker (1+ new-marker)))))
      ('ordered
       (setq insert-fn
             (lambda ()
               (insert "+"))))
      ('bullet
       (setq insert-fn
             (lambda ()
               (insert "-")))))
    ;; traverse the list up
    (setq previous-item (treesit-node-prev-sibling item))
    (while (and item
                (string= (treesit-node-type previous-item) "item")
                (funcall current-type-p previous-item))
      (setq item previous-item)
      (setq previous-item (treesit-node-prev-sibling item)))
    (atomic-change-group
      (save-excursion
        (while (and item
                    (string= (treesit-node-type item) "item")
                    (funcall current-type-p item))
          (setq marker (treesit-node-child item 0))
          (setq marker-start (treesit-node-start marker))
          (goto-char marker-start)
          (delete-region marker-start (treesit-node-end marker))
          (funcall insert-fn)
          ;; item is now invalid, need to revalidate it
          (setq item (treesit-node-next-sibling
                      (treesit-node-parent
                       (treesit-node-at marker-start)))))))))

(defun typst-ts-editing-item-list-renumber ()
  "Cleanup the numbered list at point.

   1. one
   2. two
   3. three

   Now remove 2.

   1. one
   3. three

   Run command

   1. one
   2. three"
  (interactive)
  (let ((current-item (typst-ts-editing-item--at-point-p)))
    (when (or (not current-item)
              (= (string-to-number
                  (treesit-node-text (treesit-node-child current-item 0)))
                 0))
      (user-error "Not on a numbered list"))
    (typst-ts-editing-item-list-change-type 'numbered)))

(defun typst-ts-editing-grid-cell-down ()
  "See `typst-ts-editing-grid-cell--move'."
  (interactive)
  (typst-ts-editing-grid-cell--move 'down))

(defun typst-ts-editing-grid-cell-up ()
  "See `typst-ts-editing-grid-cell--move'."
  (interactive)
  (typst-ts-editing-grid-cell--move 'up))

(defun typst-ts-editing-grid-cell-left ()
  "See `typst-ts-editing-grid-cell--move'."
  (interactive)
  (typst-ts-editing-grid-cell--move 'left))

(defun typst-ts-editing-grid-cell-right ()
  "See `typst-ts-editing-grid-cell--move'."
  (interactive)
  (typst-ts-editing-grid-cell--move 'right))

(defun typst-ts-editing-grid--at-point-p ()
  "Whether the current point is on a grid/table.
Return the call node if yes, otherwise return nil."
  (treesit-parent-until
   (treesit-node-at (point))
   (lambda (n)
     (and (string= "call" (treesit-node-type n))
          (let ((ident (treesit-node-text
                        (treesit-node-child-by-field-name
                         n "item"))))
            (or (string= "table" ident)
                (string= "grid" ident)
                (string= "table.header" ident)))))
   t))

(defun typst-ts-editing-grid-cell--at-point-p ()
  "Whether the current point is on a grid cell or not.
Return a list (grid-node cell-node grid-cells) if yes, otherwise return nil."
  ;; A grid cell is a node inside a grid node that is not a tagged node.
  (let* ((node (treesit-node-at (point)))
         (node-begin (treesit-node-start node))
         (node-end (treesit-node-end node))
         (inside-grid-p (typst-ts-editing-grid--at-point-p))
         (grid-cells
          (treesit-filter-child
           ;; the child number 1 is the argument list
           (treesit-node-child inside-grid-p 1)
           ;; a cell is not a tagged node, a comma or a parenthesis
           (lambda (n)
             (let ((type (treesit-node-type n)))
               (and (not (string= "tagged" type))
                    (not (string= "(" type))
                    (not (string= ")" type))
                    (not (string= "," type)))))))
         ;; a list of (cell-begin cell-end)
         (grid-cell-regions
          (mapcar
           (lambda (n)
             (list (treesit-node-start n) (treesit-node-end n) n))
           grid-cells))
         (cell-at-point
          ;; (begin end node)
          (caddr (seq-find (lambda (range)
                             (let (begin end _)
                               (seq-setq (begin end _) range)
                               (and (>= node-begin begin)
                                    (<= node-end end))))
                           grid-cell-regions))))
    (when (and inside-grid-p cell-at-point)
      (list inside-grid-p cell-at-point grid-cells))))

(defun typst-ts-editing-grid--column-number (node)
  "Return the number of columns the grid has.
NODE must be a call node with ident being grid or table.
When there is no columns field or the semantic meaning makes no sense return 1."
  (let* (
         ;; grammar guarantees that the child number 1 is group
         (group (treesit-node-child node 1))
         (columns-node (car (treesit-filter-child
                             group
                             (lambda (n)
                               (string= (treesit-node-text
                                         (treesit-node-child-by-field-name n "field"))
                                        "columns")))))
         ;; 0:field 1:':' 2:value from grammar
         (columns-value (treesit-node-child columns-node 2))
         (columns-value-type (treesit-node-type columns-value))
         (column-number nil))
    (cond
     ((and (string= "number" columns-value-type)
           (= (treesit-node-child-count columns-value) 0))
      (progn
        (setq column-number (string-to-number (treesit-node-text columns-value)))
        ;; it makes no sense to have columns: 0 or columns: 23% unit whatever
        (when (or (not (integerp column-number))
                  (= column-number 0))
          (setq column-number 1))))
     ((string= "group" columns-value-type)
      (setq column-number
            ;; discard punctuation nodes
            (length
             (treesit-filter-child columns-value
                                   (lambda (n)
                                     (let ((text (treesit-node-text n)))
                                       ;; TODO: use a regex instead
                                       (and (not (string= "," text))
                                            (not (string= ":" text))
                                            (not (string= "(" text))
                                            (not (string= ")" text)))))))))
     ;; when there is no columns field or the column value is a number with fraction
     (t (setq column-number 1)))
    column-number))

(defun typst-ts-editing-item--at-point-p ()
  "Return item node when point is on item.
Otherwise nil."
  (treesit-parent-until
   (treesit-node-at
    ;; do not be at last column
    (if (and (eolp) (/= (current-column) 0))
        (1- (point))
      (point)))
   (lambda (x) (string= (treesit-node-type x)
                        "item"))))

(defun typst-ts-editing-item--with-siblings ()
  "Return (prev current next numbered-p) items.

The last item in the last tells you if the list is numbered (t) or not (nil).

When current does not have a previous or next sibling,
the index for it will be nil.

Being a different item type does not count as sibling, ex:
1. foo
- bar

When point is not on an item node return nil."
  (when-let* ((node (typst-ts-editing-item--at-point-p))
              (get-item-type (lambda (x)
                               (treesit-node-text (treesit-node-child x 0))))
              (item-type (funcall get-item-type node))
              (node-numbered-p t)
              (same-item-type (lambda (x)
                                (let ((type (funcall get-item-type x)))
                                  (or (string= type item-type)
                                      ;; are they numbers?
                                      (and node-numbered-p
                                           (not (= (string-to-number type)
                                                   0)))))))
              (only-if (lambda (x) (and (string= (treesit-node-type x)
                                                 "item")
                                        (funcall same-item-type x)
                                        x))))
    (setq node-numbered-p (not (= (string-to-number item-type) 0)))
    (cond
     ((not node) node)
     (node (list (funcall only-if (treesit-node-prev-sibling node))
                 node
                 (funcall only-if (treesit-node-next-sibling node))
                 node-numbered-p)))))

(defun typst-ts-editing-item--move (direction)
  "Move item node up or down (swap).
DIRECTION should be `up' or `down'."
  (let* ( previous current next swap-with numbered-p
          (bind (lambda ()
                  (pcase-exhaustive direction
                    ('up
                     (setq swap-with previous))
                    ('down
                     (setq swap-with next))))))
    (seq-setq (previous current next numbered-p)
              (typst-ts-editing-item--with-siblings))
    (unless current
      (error "Point is not on an item"))
    (funcall bind)
    (unless swap-with
      (user-error "There is no %s item to swap with"
                  (if (eq direction 'up) "previous" "next")))
    ;; numbers may need to be swapped
    (when numbered-p
      (let* ((number1 (treesit-node-child current 0))
             (number2 (treesit-node-child swap-with 0))
             (current-begin (treesit-node-start number1))
             (current-end (treesit-node-end number1))
             (other-begin (treesit-node-start number2))
             (other-end (treesit-node-end number2)))
        (save-excursion
          (transpose-regions current-begin current-end
                             other-begin other-end))))
    ;; the nodes must be reinitialized
    (seq-setq (previous current next numbered-p)
              (typst-ts-editing-item--with-siblings))
    (funcall bind)
    (let ((current-begin (treesit-node-start current))
          (current-end (treesit-node-end current))
          (other-begin (treesit-node-start swap-with))
          (other-end (treesit-node-end swap-with))
          (column (current-column)))
      (transpose-regions current-begin current-end
                         other-begin other-end)
      (move-to-column column))))

(defun typst-ts-editing-item-up ()
  "Move the item at point up."
  (interactive)
  (typst-ts-editing-item--move 'up))

(defun typst-ts-editing-item-down ()
  "Move the item at point down."
  (interactive)
  (typst-ts-editing-item--move 'down))

(defun typst-ts-editing-meta-up ()
  "See `typst-ts-editing-meta--dwim'."
  (interactive)
  (call-interactively (typst-ts-editing-meta--dwim 'up)))

(defun typst-ts-editing-meta-down ()
  "See `typst-ts-editing-meta--dwim'."
  (interactive)
  (call-interactively (typst-ts-editing-meta--dwim 'down)))

(defun typst-ts-editing-meta-left ()
  "See `typst-ts-editing-meta--dwim'."
  (interactive)
  (call-interactively (typst-ts-editing-meta--dwim 'left)))

(defun typst-ts-editing-meta-right ()
  "See `typst-ts-editing-meta--dwim'."
  (interactive)
  (call-interactively (typst-ts-editing-meta--dwim 'right)))

(defun typst-ts-editing-meta--dwim (direction)
  "Return function depending on the context with meta key + DIRECTION.

When point is at heading:
`left': `typst-ts-editing-heading-left',
`right': `typst-ts-editing-heading-right',
`up': `typst-ts-editing-heading-up',
`down': `typst-ts-editing-heading-down'.

When point is at item list:
`up': `typst-ts-editing-item-up'
`down': `typst-ts-editing-item-down'

When point is at grid cell:
`left': `typst-ts-editing-grid-cell-left',
`right': `typst-ts-editing-grid-cell-right',
`up': `typst-ts-editing-grid-cell-up',
`down': `typst-ts-editing-grid-cell-down'.

The precedence is:
1. Heading
2. Item list
3. Grid cell

When there is no relevant action to do it will return the relevant function in
the `GLOBAL-MAP' (example: `right-word')."
  (let* ((prefix "typst-ts-editing-")
         (mid (cond
               ((typst-ts-editing-heading--at-point-p) "heading")
               ((and (typst-ts-editing-item--at-point-p)
                     ;; does not exist, maybe will exist at some point
                     (not (or (eq 'left direction)
                              (eq 'right direction))))
                "item")
               ((typst-ts-editing-grid-cell--at-point-p) "grid-cell")
               (t nil)))
         (end
          (pcase-exhaustive direction
            ('left
             "-left")
            ('right
             "-right")
            ('up
             "-up")
            ('down
             "-down"))))
    (if (not mid)
        (keymap-lookup global-map (substitute-command-keys
                                   (concat "\\[" prefix "meta" end "]")))
      (intern-soft (concat prefix mid end)))))

(defun typst-ts-editing-meta-return (&optional arg)
  "Depending on context, insert a heading or insert an item.
The new heading is created after the ending of current heading.
Using ARG argument will ignore the context and it will insert a heading instead."
  (interactive "P")
  (let ((item-node (treesit-parent-until
                    (treesit-node-at (line-beginning-position))
                    (lambda (node)
                      (string= "item" (treesit-node-type node)))))
        (node (typst-ts-core-get-parent-of-node-at-bol-nonwhite)))
    (cond
     (arg (typst-ts-editing-insert--heading nil))
     (item-node
      (typst-ts-editing-insert--item item-node))
     (t
      (typst-ts-editing-insert--heading node)))))

(defun typst-ts-editing-return (&optional arg)
  "RET behavior depending context.
Can be turned off by setting `typst-ts-electric-return' to nil.
When point is on end of line of a list item with content,
it will insert a list item without content on the next line.

When point is on a list item without content,
it will delete the list item.

When using prefix argument ARG, `typst-ts-electric-return' is nil,
 or no special context, call global RET function"
  (interactive "P")
  (let ((default-call
         (lambda ()
           (let ((global-ret-function (global-key-binding (kbd "RET"))))
             (if (not arg)
                 (call-interactively global-ret-function)
               (if (yes-or-no-p
                    (format
                     "Execute function `%s' without/with the given prefix argument?"
                     global-ret-function))
                   (let ((current-prefix-arg nil))
                     (call-interactively global-ret-function))
                 (call-interactively global-ret-function))))))
        (node (typst-ts-core-parent-util-type
               (typst-ts-core-get-parent-of-node-at-bol-nonwhite)
               "item" t t)))
    (cond
     ((or (not typst-ts-electric-return) arg) (funcall default-call))
     ((and node (eolp))
      (if (> (treesit-node-child-count node) 1)
          (typst-ts-editing-insert--item node)
        (delete-region (treesit-node-start node) (treesit-node-end node))))
     (t (funcall default-call)))))

(defun typst-ts-editing-insert--item (node)
  "Insert an item after NODE.
NODE must be an item node!
This function respects indentation."
  (let* (;; +, -, or <num>.
         (item-type (treesit-node-text
                     (treesit-node-child node 0)))
         (item-number (string-to-number item-type))
         (item-end (treesit-node-end node))
         (node-bol-column (typst-ts-core-column-at-pos
                           (typst-ts-core-get-node-bol node))))
    (goto-char item-end)
    (newline)
    (indent-line-to node-bol-column)
    (insert (if (= item-number 0)  ; not a number type
                item-type
              (concat (number-to-string (1+ item-number)) "."))
            " ")))

(defun typst-ts-editing-insert--heading (node)
  "Insert a heading after the section that NODE is part of.
When there is no section it will insert a heading below point."
  (let* ((section
          (treesit-parent-until
           node
           (lambda (node)
             (string= (treesit-node-type node) "section"))
           t))
         ;; first child is heading
         (heading (treesit-node-child section 0))
         (heading-level (treesit-node-type (treesit-node-child heading 0))))
    (if section
        (goto-char (treesit-node-end section))
      ;; no headings so far
      (setq heading-level "=")
      (forward-line 1))
    ;; something can be in the next line/section, the heading needs be on its own line
    ;; this has to be done after `goto-char' because it will invalidate the node
    (newline)
    (forward-line -1)
    ;; insert the heading and indent
    (insert heading-level " ")
    (indent-according-to-mode)))

(defun typst-ts-editing--indent-item-node-lines (node offset)
  "Indent lines covered by NODE by OFFSET."
  (let ((item-node-min-column
         (typst-ts-core-column-at-pos
          (typst-ts-core-line-bol-nonwhite-pos
           (treesit-node-start node)))))
    (if (< (+ item-node-min-column offset) 0)
        (setq offset (- item-node-min-column)))
    (typst-ts-core-for-lines-covered-by-node
     node
     (lambda ()
       (indent-line-to
        (+ (typst-ts-core-column-at-pos
            (typst-ts-core-line-bol-nonwhite-pos))
           offset))))))

(defun typst-ts-editing-cycle (&optional _arg)
  "Cycle."
  (interactive "P")
  (let (node)
    (or
     (when-let* ((cur-pos (point))
                 (cur-node (treesit-node-at cur-pos))
                 (cur-node-type (treesit-node-type cur-node))
                 (cur-line-nonwhite-bol-node
                  (typst-ts-core-get-node-at-bol-nonwhite))
                 (_ (treesit-node-type cur-line-nonwhite-bol-node))
                 (parent-node (treesit-node-parent cur-node)) ; could be nil
                 (parent-node-type (treesit-node-type parent-node)))
       (cond
        ((equal parent-node-type "raw_blck")
         (insert-tab)
         'success)

        ((setq node
               (typst-ts-core-parent-util-type
                cur-line-nonwhite-bol-node "item" t t))
         (let* ((cur-item-node node)
                (prev-significant-node
                 (typst-ts-core-prev-sibling-ignore-types
                  cur-item-node
                  "parbreak"))
                (prev-significant-node-type
                 (treesit-node-type prev-significant-node))
                prev-item-node)

           (if (equal prev-significant-node-type "item")
               (setq prev-item-node prev-significant-node)
             (if (equal
                  "item"
                  (treesit-node-type
                   (treesit-node-parent prev-significant-node)))
                 (setq prev-item-node (treesit-node-parent
                                       prev-significant-node))))

           ;; (message "%s, %s" cur-item-node prev-item-node)

           (when prev-item-node
             (let* ((cur-item-node-start-column
                     (typst-ts-core-column-at-pos
                      (treesit-node-start cur-item-node)))
                    (prev-item-node-start-column
                     (typst-ts-core-column-at-pos
                      (treesit-node-start prev-item-node)))
                    (offset
                     (- cur-item-node-start-column
                        prev-item-node-start-column)))
               (if (>= offset typst-ts-indent-offset)
                   (typst-ts-editing--indent-item-node-lines
                    cur-item-node
                    (- (+ offset typst-ts-indent-offset)))
                 (typst-ts-editing--indent-item-node-lines
                  cur-item-node
                  (- typst-ts-indent-offset (abs offset)))))

             'success)))))
     ;; execute default action if not successful
     (call-interactively (global-key-binding (kbd "TAB"))))))

(defun typst-ts-editing-calculate-fill-prefix ()
  "Calculate fill prefix."
  ;; see `do-auto-fill' function and `;; Choose a fill-prefix automatically.'
  ;; for default automatical fill-prefix finding algorithm
  (let (fill-prefix)
    ;; TODO: why is the variable bound and then returned?
    (setq
     fill-prefix
     (catch 'fill-prefix
       (cond
        ;; for condition that there are closely aligned line above
        ((typst-ts-core-parent-util-type
          (typst-ts-core-get-parent-of-node-at-bol-nonwhite)
          "item" t t)
         (throw 'fill-prefix (fill-context-prefix (line-beginning-position) (line-end-position)))))))
    fill-prefix))

(defun typst-ts-editing-auto-fill-function ()
  "Auto Fill Function for `auto-fill-mode'."
  (when-let* (((>= (current-column) (current-fill-column)))
              (fill-prefix (typst-ts-editing-calculate-fill-prefix))
              (adaptive-fill-mode (null fill-prefix)))
    (do-auto-fill)))

(defun typst-ts-editing-symbol-picker ()
  "Insert typst symbols.
Symbols are from `typst-ts-symbol-alist' `typst-ts-emoji-alist'.
In markup mode, it will prefix the selection with \"#\"
and its corresponding module (\"sym.\", \"emoji.\").
In math mode, symbols do not need a \"#\" prefix and \"sym.\" prefix.
In code mode, the selection needs to be prefixed with the module."
  (interactive)
  (let* ((all-symbols (append typst-ts-symbol-alist typst-ts-emoji-alist))
         (completion-extra-properties
          '(:annotation-function
            (lambda (key)
              (concat " " (cdr (assoc key minibuffer-completion-table))))))
         (value (completing-read
                 "Pick: " all-symbols
                 nil t))
         (node (treesit-node-at (point)))
         (inside-math (treesit-parent-until node
                                            (lambda (x)
                                              (string= (treesit-node-type x)
                                                       "math"))))
         (inside-code (treesit-parent-until node
                                            (lambda (x)
                                              (or
                                               (string= (treesit-node-type x)
                                                        "code")
                                               (string= (treesit-node-type x)
                                                        "content")))))
         (is-symbol-p (assoc value typst-ts-symbol-alist))
         (is-emoji-p (assoc value typst-ts-emoji-alist))
         (to-insert value))
    (cond
     ((string= (treesit-node-type inside-code) "code")
      (setq to-insert (concat
                       (if is-symbol-p "sym." "emoji.")
                       to-insert)))
     ((and is-symbol-p
           (not inside-math)
           (not (string= (treesit-node-type inside-code) "code")))
      (setq to-insert (concat "#sym." to-insert)))
     ((and is-emoji-p
           (not (string= (treesit-node-type inside-code) "code")))
      (setq to-insert (concat "#emoji." to-insert))))
    (insert to-insert)))

(provide 'typst-ts-editing)

;;; typst-ts-editing.el ends here
