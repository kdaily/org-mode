;;; org-infojs.el --- Support for org-info.js Javascript in Org HTML export

;; Copyright (C) 2004, 2005, 2006, 2007, 2008 Free Software Foundation, Inc.

;; Author: Carsten Dominik <carsten at orgmode dot org>
;; Keywords: outlines, hypermedia, calendar, wp
;; Homepage: http://orgmode.org
;; Version: 6.00pre-3
;;
;; This file is part of GNU Emacs.
;;
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:

;; This file implements the support for Sebastian Rose's Javascript
;; org-info.js to display an org-mode file exported to HTML in an
;; Info-like way, or using folding similar to the outline structure
;; org org-mode itself.

;; Documentation for using this module is in the Org manual. The script
;; itself is documented by Sebastian Rose in a file distributed with
;; the script.  FIXME: Accurate pointers!

;; Org-mode loads this module by default - if this is not what you want,
;; configure the variable `org-modules'.

;;; Code:

(require 'org-exp)

(add-to-list 'org-export-inbuffer-options-extra '("INFOJS_OPT" :infojs-opt))
(add-hook 'org-export-options-filters 'org-infojs-handle-options)

(defgroup org-infojs nil
  "Options specific for using org-info.js in HTML export of Org-mode files."
  :tag "Org Export HTML INFOJS"
  :group 'org-export-html)

(defcustom org-export-html-use-infojs 'when-configured
  "Should Sebasian Rose's Java Script org-info.js be linked into HTML files?
This option can be nil or t to never or always use the script.  It can
also be the symbol `when-configured', meaning that the script will be
linked into the export file if and only if there is a \"#+INFOJS_OPT:\"
line in the buffer.  See also the variable `org-infojs-options'."
  :group 'org-export-html
  :group 'org-infojs
  :type '(choice
	  (const :tag "Never" nil)
	  (const :tag "When configured in buffer" when-configured)
	  (const :tag "Always" t)))
  
(defconst org-infojs-opts-table
  '((path PATH "org-info.js")
    (view VIEW "info")
    (toc TOC :table-of-contents)
    (mouse MOUSE_HINT "underline")
    (runs MAX_RUNS "5")
    (buttons VIEW_BUTTONS "0")
    (ltoc LOCAL_TOC "1")
    (up LINK_UP :link-up)
    (home LINK_HOME :link-home))
  "JavaScript options, long form for script, default values.")

(defcustom org-infojs-options
  (mapcar (lambda (x) (cons (car x) (nth 2 x)))
	  org-infojs-opts-table)
  "Options settings for the INFOJS Javascript.
Each of the options must have an entry in `org-export-html/infojs-opts-table'.
The value can either be a string that will be passed to the script, or
a property.  This property is then assumed to be a property that is defined
by the Export/Publishing setup of Org."
  :group 'org-infojs
  :type
  '(repeat
    (cons (symbol :tag "Option")
	  (choice (symbol :tag "Publishing/Export property")
		  (string :tag "Value")))))

(defcustom org-infojs-template
  "<script type=\"text/javascript\" language=\"JavaScript\" src=\"%SCRIPT_PATH\"></script>
<script type=\"text/javascript\" language=\"JavaScript\">
/* <![CDATA[ */
%MANAGER_OPTIONS
org_html_manager.setup();  // activate after the parameterd are set
/* ]]> */
</script>"
  "The template for the export style additions when org-info.js is used.
Option settings will replace the %MANAGER-OPTIONS cookie."
  :group 'org-infojs
  :type 'string)

(defun org-infojs-handle-options (exp-plist)
  "Analyze JavaScript options in INFO-PLIST and modify EXP-PLIST accordingly."
  (if (or (not org-export-html-use-infojs)
	  (and (eq org-export-html-use-infojs 'when-configured)
	       (not (plist-get exp-plist :infojs-opt))))
      ;; We do not want to use the script
      exp-plist
    ;; We do want to use the script, set it up
  (let ((template org-infojs-template)
	p1 s p v a1 tmp e opt var val table default)
    (setq v (plist-get exp-plist :infojs-opt)
	  table org-infojs-opts-table)
    (while (setq e (pop table))
      (setq opt (car e) var (nth 1 e)
	    default (cdr (assoc opt org-infojs-options)))
      (and (symbolp default) (not (memq default '(t nil)))
	   (setq default (plist-get exp-plist default)))
      (if (string-match (format " %s:\\(\\S-+\\)" opt) v)
	  (setq val (match-string 1 v))
	(setq val default))
      (cond
       ((eq opt 'path)
	(and (string-match "%SCRIPT_PATH" template)
	     (setq template (replace-match val t t template))))
       (t
	(setq val
	      (cond
	       ((or (eq val t) (equal val "t")) "1")
	       ((or (eq val nil) (equal val "nil")) "0")
	       ((stringp val) val)
	       (t (format "%s" val))))
	(push (cons var val) s))))

    (setq s (mapconcat
	     (lambda (x) (format "org_html_manager.set(\"%s\", \"%s\");"
				 (car x) (cdr x)))
	     s "\n"))
    (when (and s (> (length s) 0))
      (and (string-match "%MANAGER_OPTIONS" template)
	   (setq s (replace-match s t t template))
	   (setq exp-plist
		 (plist-put
		  exp-plist :style
		  (concat (or (plist-get exp-plist :style) "") "\n" s)))))
    ;; This script absolutely needs the table of contents, to we change that
    ;; setting
    (if (not (plist-get exp-plist :table-of-contents))
	(setq exp-plist (plist-put exp-plist :table-of-contents t)))
    
    ;; Return the modified property list
    exp-plist)))

(provide 'org-infojs)

;;; org-infojs.el ends here