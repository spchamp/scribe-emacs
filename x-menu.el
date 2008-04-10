;;; x-menu.el --- menu support for X

;; Copyright (C) 1986, 2001, 2002, 2003, 2004, 2005,
;;   2006, 2007, 2008 Free Software Foundation, Inc.

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;;; Code:

(defvar x-process-mouse-hook)

(defun x-menu-mode ()
  "Major mode for creating permanent menus for use with X.
These menus are implemented entirely in Lisp; popup menus, implemented
with x-popup-menu, are implemented using XMenu primitives."
  (make-local-variable 'x-menu-items-per-line)
  (make-local-variable 'x-menu-item-width)
  (make-local-variable 'x-menu-items-alist)
  (make-local-variable 'x-process-mouse-hook)
  (make-local-variable 'x-menu-assoc-buffer)
  (setq buffer-read-only t)
  (setq truncate-lines t)
  (setq x-process-mouse-hook 'x-menu-pick-entry)
  (setq mode-line-buffer-identification '("MENU: %32b")))

(defvar x-menu-max-width 0)
(defvar x-menu-items-per-line 0)
(defvar x-menu-item-width 0)
(defvar x-menu-items-alist nil)
(defvar x-menu-assoc-buffer nil)

(defvar x-menu-item-spacing 1
  "*Minimum horizontal spacing between objects in a permanent X menu.")

(defun x-menu-create-menu (name)
  "Create a permanent X menu.
Returns an item which should be used as a
menu object whenever referring to the menu."
  (let ((old (current-buffer))
	(buf (get-buffer-create name)))
    (set-buffer buf)
    (x-menu-mode)
    (setq x-menu-assoc-buffer old)
    (set-buffer old)
    buf))

(defun x-menu-change-associated-buffer (menu buffer)
  "Change associated buffer of MENU to BUFFER.
BUFFER should be a buffer object."
  (let ((old (current-buffer)))
    (set-buffer menu)
    (setq x-menu-assoc-buffer buffer)
    (set-buffer old)))

(defun x-menu-add-item (menu item binding)
  "Add to MENU an item with name ITEM, associated with BINDING.
Following a sequence of calls to x-menu-add-item, a call to x-menu-compute
should be performed before the menu will be made available to the user.

BINDING should be a function of one argument, which is the numerical
button/key code as defined in x-menu.el."
  (let ((old (current-buffer))
	elt)
    (set-buffer menu)
    (if (setq elt (assoc item x-menu-items-alist))
	(rplacd elt binding)
      (setq x-menu-items-alist (append x-menu-items-alist
				       (list (cons item binding)))))
    (set-buffer old)
    item))

(defun x-menu-delete-item (menu item)
  "Delete from MENU the item named ITEM.
Call `x-menu-compute' before making the menu available to the user."
  (let ((old (current-buffer))
	elt)
    (set-buffer menu)
    (if (setq elt (assoc item x-menu-items-alist))
	(rplaca elt nil))
    (set-buffer old)
    item))

(defun x-menu-activate (menu)
  "Compute all necessary parameters for MENU.
This must be called whenever a menu is modified before it is made
available to the user.  This also creates the menu itself."
  (let ((buf (current-buffer)))
    (pop-to-buffer menu)
    (let (buffer-read-only)
      (setq x-menu-max-width (1- (frame-width)))
      (setq x-menu-item-width 0)
      (let (items-head
	    (items-tail x-menu-items-alist))
	(while items-tail
	  (if (car (car items-tail))
	      (progn (setq items-head (cons (car items-tail) items-head))
		     (setq x-menu-item-width
			   (max x-menu-item-width
				(length (car (car items-tail)))))))
	  (setq items-tail (cdr items-tail)))
	(setq x-menu-items-alist (reverse items-head)))
      (setq x-menu-item-width (+ x-menu-item-spacing x-menu-item-width))
      (setq x-menu-items-per-line
	    (max 1 (/ x-menu-max-width x-menu-item-width)))
      (erase-buffer)
      (let ((items-head x-menu-items-alist))
	(while items-head
	  (let ((items 0))
	    (while (and items-head
			(<= (setq items (1+ items)) x-menu-items-per-line))
	      (insert (format (concat "%"
				      (int-to-string x-menu-item-width) "s")
			      (car (car items-head))))
	      (setq items-head (cdr items-head))))
	  (insert ?\n)))
      (shrink-window (max 0
			  (- (window-height)
			     (1+ (count-lines (point-min) (point-max))))))
      (goto-char (point-min)))
    (pop-to-buffer buf)))

(defun x-menu-pick-entry (position event)
  "Internal function for dispatching on mouse/menu events"
  (let*	((x (min (1- x-menu-items-per-line)
		 (/ (current-column) x-menu-item-width)))
	 (y (- (count-lines (point-min) (point))
	       (if (zerop (current-column)) 0 1)))
	 (item (+ x (* y x-menu-items-per-line)))
	 (litem (cdr (nth item x-menu-items-alist))))
    (and litem (funcall litem event)))
  (pop-to-buffer x-menu-assoc-buffer))

(provide 'x-menu)

;; arch-tag: 889f6d49-c01b-49e7-aaef-b0c6966c2961
;;; x-menu.el ends here
