(use-modules (srfi srfi-64)
	     (mlg characters))

(test-begin "t-mlg-characters")

(test-equal #f (ascii-isdigit? #\a))
(test-equal #t (ascii-isdigit? #\0))
;; U+0661 ARABIC-INDIC DIGIT ONE -- digit but not ASCII
(test-equal #f (ascii-isdigit? #\x0661))

(test-equal (integer->char #x0661) (U+ #x0661))
(test-equal #\space (U+ #x0020))

;; characters-load-extension
;; Bug fix: characters-load-extension was not exported and was not called
;; at module load time, leaving wcwidth unbound.  It is now called
;; automatically.  Calling it again from user code must be harmless.
(test-assert (begin (characters-load-extension) #t))

;; char-count-cells
;; These tests span all four branches of char-count-cells and also
;; confirm that wcwidth is available (i.e., the C extension was loaded).

;; NUL takes 0 cells regardless of column or tab size.
(test-equal 0 (char-count-cells #\nul 0 8))
(test-equal 0 (char-count-cells #\nul 5 4))

;; TAB fills to the next tab stop: (tabSize - (col mod tabSize)).
(test-equal 8 (char-count-cells #\tab 0 8))   ; full tab stop
(test-equal 4 (char-count-cells #\tab 4 8))   ; half way through
(test-equal 1 (char-count-cells #\tab 7 8))   ; one before next stop

;; C0 control characters (other than NUL and TAB) are displayed as
;; "^X" and therefore take 2 cells: 1 for the caret plus 1 for the
;; letter.  This exercises both the caret-notation branch and wcwidth.
(test-equal 2 (char-count-cells #\x01 0 8))   ; SOH  -> ^A
(test-equal 2 (char-count-cells #\x1b 0 8))   ; ESC  -> ^[
(test-equal 2 (char-count-cells #\x1f 0 8))   ; US   -> ^_

;; DEL (U+007F) is also matched by ascii-iscntrl? and must yield 2
;; cells (displayed as ^?).
;; Bug fix: char-get-display-representation-of-control-char previously
;; used (+ code 64) which gives 191 for DEL instead of the correct
;; 63 (#\?).  The fix uses (logxor code 64).  Because wcwidth(191) and
;; wcwidth(63) both equal 1, the cell count is the same either way;
;; this test confirms correct handling of DEL as a control character.
(test-equal 2 (char-count-cells #\delete 0 8))

;; Ordinary printable ASCII falls through to (wcwidth chr) = 1.
;; This also exercises the else branch with a live wcwidth call.
(test-equal 1 (char-count-cells #\a    0 8))
(test-equal 1 (char-count-cells #\space 0 8))
(test-equal 1 (char-count-cells #\~   0 8))

;; char-combining-mark?
;; U+0300 COMBINING GRAVE ACCENT has general category Mn (non-spacing mark).
(test-equal #t (char-combining-mark? #\x0300))
;; U+0308 COMBINING DIAERESIS -- also Mn.
(test-equal #t (char-combining-mark? #\x0308))
;; Ordinary letters and digits are not combining marks.
(test-equal #f (char-combining-mark? #\a))
(test-equal #f (char-combining-mark? #\0))

;; Finish the testsuite, and report results.
(test-end "t-mlg-characters")
