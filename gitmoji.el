;;; gitmoji.el --- Add a gitmoji selector to your commits.  -*- lexical-binding: t; -*-

;; Author: Tiv0w <https:/github.com/Tiv0w>
;; URL: https://github.com/Tiv0w/gitmoji-commit.git
;; Version: 0.1.1
;; Package-Requires: ((emacs "24.1") (ivy ""))
;; Keywords: emoji, git, gitmoji, commit

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
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

;; This package is intended to help people with adding gitmojis to their
;; commits when commiting through Emacs.

;; To load this file, add `(require 'gitmoji)' to your init file.
;;
;; To use it, simply use `M-x gitmoji-commit-mode' and you will be
;; prompted to choose a gitmoji when using git-commit.
;;
;; You could also want to insert a gitmoji in current buffer,
;; for that you would `M-x gitmoji-insert' and voilà!
;;; Code:

(require 'gitmojis-list)

(defcustom gitmoji--insert-utf8-emoji nil
  "When t, inserts the utf8 emoji character instead of the github-style representation.
Example: ⚡ instead of :zap:.
Default: nil."
  :type 'boolean
  :group 'gitmoji)

(defcustom gitmoji--display-utf8-emoji nil
  "When t, displays the utf8 emoji character in the gitmoji choice list.
Default: nil."
  :type 'boolean
  :group 'gitmoji)

;;;###autoload
(defun gitmoji-set-selection-backend (backend)
  "Set the backend for selecting emojis.

BACKEND is a valid backend name, see `gitmoji-selection-backend"
  (setq-default gitmoji-selection-backend backend))

(defcustom gitmoji-selection-backend
  '(helm ivy consult)
  "The backend for the selection of emojis.

These can have one of the following values

`helm'  - Use Helm
`ivy'   - Use Ivy
`consult'   - Use Consult"
  :type '(set
          (const :tag "Helm" helm)
          (const :tag "Consult" consult)
          (const :tag "Ivy" ivy))
  :set (lambda (_ value) (gitmoji-set-selection-backend value))
  :group 'gitmoji)

(defun gitmoji-insert--candidates ()
  (mapcar (lambda (x)
            (let ((description (car x))
                  (shortcode (cadr x))
                  (utf8 (caddr x)))
              (cons
               (concat
                (when gitmoji--display-utf8-emoji
                  (concat (string utf8) " - "))
                shortcode
                " — "
                description)
               x)))
          gitmojis-list))

(defun gitmoji-insert--action (x)
  "Insert either Gitmoji's symbol or shortcode.
Based on the value of gitmoji--insert-utf8-emoji global variable,
 followed by a space character.
It takes a single argument X, which is a list of selected Gitmoji's information."
  (if x
      (progn
        (let ((utf8 (cadddr x))
              (shortcode (caddr x)))
          (if gitmoji--insert-utf8-emoji
              (insert-char utf8)
            (insert shortcode)))
        (insert " "))))

(defun gitmoji-insert-ivy ()
  "Choose a gitmoji with ivy and insert it in the current buffer."
  (interactive)
  (let ((candidates (gitmoji-insert--candidates)))
    (condition-case nil
        (ivy-read
         "Choose a gitmoji: "
         candidates
         :action #'gitmoji-insert--action)
      (quit nil))))

(defun gitmoji-insert-helm ()
  "Choose a gitmoji with helm and insert it in the current buffer."
  (interactive)
  (condition-case nil
      (helm :sources `((name . "Choose a gitmoji:")
                       (candidates . ,(gitmoji-insert--candidates))
                       (action . (lambda (candidate) (gitmoji-insert--action (append '(" ") candidate))))))
    (helm-quit nil)))

(defun gitmoji-insert-consult ()
  "Choose a gitmoji with consult and insert it in the current buffer."
  (interactive)
  (let* ((candidates (gitmoji-insert--candidates))
         (candidate (assoc
                     (condition-case nil
                         (completing-read "Choose a gitmoji: " candidates)
                       (quit nil))
                     candidates)))
    (gitmoji-insert--action candidate)))

(defun gitmoji-insert ()
  "Choose a gitmoji and insert it in the current buffer."
  (interactive)
  (cond
   ((and (memql 'ivy gitmoji-selection-backend) (featurep 'ivy)) (gitmoji-insert-ivy))
   ((and (memql 'helm gitmoji-selection-backend) (featurep 'helm)) (gitmoji-insert-helm))
   ((and (memql 'consult gitmoji-selection-backend) (package-installed-p 'consult)) (gitmoji-insert-consult))
   (t (warn "No valid backend selected for Gitmoji."))))

;;;###autoload
(define-minor-mode gitmoji-commit-mode
  "Toggle gitmoji-commit mode.This is a global setting."
  :global t
  :init-value nil
  :lighter " Gitmoji"
  (if gitmoji-commit-mode
      (add-hook 'git-commit-mode-hook 'gitmoji-insert)
    (remove-hook 'git-commit-mode-hook 'gitmoji-insert)))

(provide 'gitmoji)
;;; gitmoji.el ends here
