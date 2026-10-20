;;; es-hints.el --- Emacs Scope Hints

;; Copyright (C) 2026 Shams Parvez Arka
;; See end of file for extended copyright information

;; Author    : Shams Parvez Arka <parvez6826@gmail.com>
;; URL       : https://github.com/ShamsParvezArka/es-hints.el
;; Version   : 0.2
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

(defun es-hints--hl-line-active-p ()
  "Non-nil if hl-line is highlighting the current buffer."
  (or (bound-and-true-p hl-line-mode)
      (bound-and-true-p global-hl-line-mode)))

(defun es-hints--region-covers-p (pos)
  "Non-nil if the active region highlight covers the newline at POS."
  (and (region-active-p)
       (not (bound-and-true-p rectangle-mark-mode))
       (not (bound-and-true-p cua--rectangle))
       (<= (region-beginning) pos)
       (< pos (region-end))))

(defun es-hints--place-for-close (close-pos &optional current-bol)
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
                       ;; NOTE(arka): faces from other overlays (region,
                       ;; hl-line) never reach overlay strings, so apply
                       ;; them ourselves. Region first: it wins over hl-line.
                       (bg (delq nil
                                 (list (and (es-hints--region-covers-p eol)
                                            'region)
                                       (and current-bol
                                            (= (line-beginning-position) current-bol)
                                            (es-hints--hl-line-active-p)
                                            'hl-line))))
                       (ov (make-overlay eol eol))
                       (space (if bg (propertize " " 'face bg) " "))
                       (text (propertize label 'face (cons 'es-hints-face bg))))
                  (overlay-put ov 'after-string (concat space text))
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
           (bol (line-beginning-position))
           (region (and (region-active-p)
                        (cons (region-beginning) (region-end))))
           (state (list chain wstart wend bol region)))
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
                        (es-hints--place-for-close close-pos bol))))
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
        ;; NOTE(arka): some commands (M-w) drop the region after
        ;; post-command-hook has run, so refresh when that happens too.
        (add-hook 'deactivate-mark-hook #'es-hints--update nil t)
        (es-hints--update))
    (remove-hook 'post-command-hook #'es-hints--update t)
    (remove-hook 'window-scroll-functions #'es-hints--update t)
    (remove-hook 'deactivate-mark-hook #'es-hints--update t)
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
