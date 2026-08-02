;;; es-hints.el --- Emacs Scope Hints

;; Copyright (C) 2026 Shams Parvez Arka
;; See end of file for extended copyright information

;; Author    : Shams Parvez Arka <parvez6826@gmail.com>
;; URL       : https://github.com/ShamsParvezArka/es-hints.el
;; Version   : 0.1
;; Commentary: "No matter how dim the light feels, your story is still playing
;;              and it's far from over"


(defgroup es-hints nil
  "NOTE(arka): prefix entry to customize group as `es-hints-`"
  :group 'convenience
  :prefix "es-hints-")

(defcustom es-hints-min-lines 1
  "NOTE(arka): minumum number of lines required to trigger es-hints"
  :type 'integer
  :group 'es-hints)

(defcustom es-hints-max-line-length 80
  "NOTE(arka): maximum length of es-hints. if line excied, will be contated as ..."
  :type 'integer
  :group 'es-hints)

(defface es-hints-face
  '((t :inherit font-lock-comment-face
       :height 0.8
       :background "unspecified-bg"
       :weight thin))
  "NOTE(arka): es-hints font configuration")

(defun es-hints--header-text (open-pos)
  (save-excursion
    (goto-char open-pos)
    (let* ((brace-line (string-trim
                        (buffer-substring-no-properties
                         (line-beginning-position) (line-end-position))))
           (brace-line-sans (string-trim (replace-regexp-in-string "{\\s-*$" "" brace-line))))
      (if (not (string-empty-p brace-line-sans))
          brace-line-sans
        (forward-line -1)
        (while (and (not (bobp))
                    (string-empty-p (string-trim (thing-at-point 'line t))))
          (forward-line -1))
        (string-trim (thing-at-point 'line t))))))

(defun es-hints--truncate (s)
  (if (> (length s) es-hints-max-line-length)
      (concat (substring s 0 es-hints-max-line-length) "…")
    s))

(defcustom es-hints-right-margin 1
  "NOTE(arka): right margin guard"
  :type 'integer
  :group 'es-hints)

(defun es-hints--place-for-close (close-pos)
  (save-excursion
    (goto-char close-pos)
    (condition-case nil
        (let* ((close-line (line-number-at-pos))
               (open-pos (progn (backward-sexp) (point)))
               (open-line (line-number-at-pos)))
          (when (>= (- close-line open-line) es-hints-min-lines)
            (let* ((header (es-hints--header-text open-pos))
                   (label (es-hints--truncate header)))
              (unless (string-empty-p label)
                (goto-char close-pos)
                (let* ((eol (line-end-position))
                       (ov (make-overlay eol eol))
                       (text (propertize label 'face 'es-hints-face)))
                  (overlay-put ov 'after-string
                               (concat " " text))
                  (overlay-put ov 'es-hints t))))))
      (scan-error nil))))

(defun es-hints--scope-chain ()
  (nth 9 (syntax-ppss (point))))

(defvar-local es-hints--last-state nil)

(defun es-hints--update (&rest _)
  (when es-hints-mode
    (let* ((chain (es-hints--scope-chain))
           (wstart (window-start))
           (wend (window-end nil t))
           (state (list chain wstart wend)))
      (unless (equal state es-hints--last-state)
        (setq es-hints--last-state state)
        (remove-overlays (point-min) (point-max) 'es-hints t)
        (dolist (open-pos chain)
          (when (eq (char-after open-pos) ?\{)
            (save-excursion
              (goto-char open-pos)
              (condition-case nil
                  (progn
                    (forward-sexp)
                    (let ((close-pos (point)))
                      (when (and (eq (char-before close-pos) ?\})
                                 (>= close-pos wstart) (<= close-pos wend))
                        (es-hints--place-for-close close-pos))))
                (scan-error nil)))))))))

(defun es-hints-refresh ()
  (interactive)
  (setq es-hints--last-state nil)
  (es-hints--update))

(define-minor-mode es-hints-mode
  "NOTE(arka): script entry point & update loop"
  :lighter "Scope Hint Mode"
  (if es-hints-mode
      (progn
        (add-hook 'post-command-hook #'es-hints--update nil t)
        (add-hook 'window-scroll-functions #'es-hints--update nil t)
        (es-hints--update))
    (remove-hook 'post-command-hook #'es-hints--update t)
    (remove-hook 'window-scroll-functions #'es-hints--update t)
    (setq es-hints--last-state nil)
    (remove-overlays (point-min) (point-max) 'es-hints t)))

(provide 'es-hints)


;; MIT License

;; Copyright (c) 2025-2026 Shams Parvez Arka

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.
