(use-modules (srfi srfi-64)
	     (mlg characters))

(test-begin "t-mlg-characters")

(test-equal "ascii-isdigit? rejects letter"
  #f (ascii-isdigit? #\a))
(test-equal "ascii-isdigit? accepts ASCII digit"
  #t (ascii-isdigit? #\0))
;; U+0661 ARABIC-INDIC DIGIT ONE -- digit but not ASCII
(test-equal "ascii-isdigit? rejects non-ASCII digit"
  #f (ascii-isdigit? #\x0661))

(test-equal "U+ converts non-ASCII codepoint"
  (integer->char #x0661) (U+ #x0661))
(test-equal "U+ #x0020 is space"
  #\space (U+ #x0020))

;; characters-load-extension
;; WCWIDTH is now written in Scheme, so this is a no-op kept for
;; compatibility.  Calling it from user code must be harmless.
(test-assert "characters-load-extension is exported and idempotent"
  (begin (characters-load-extension) #t))

;; char-count-cells
;; These tests span all four branches of char-count-cells.

;; NUL takes 0 cells regardless of column or tab size.
(test-equal "char-count-cells NUL at col 0"
  0 (char-count-cells #\nul 0 8))
(test-equal "char-count-cells NUL at col 5 tabsize 4"
  0 (char-count-cells #\nul 5 4))

;; TAB fills to the next tab stop: (tabSize - (col mod tabSize)).
(test-equal "char-count-cells TAB at col 0 tabsize 8"
  8 (char-count-cells #\tab 0 8))   ; full tab stop
(test-equal "char-count-cells TAB at col 4 tabsize 8"
  4 (char-count-cells #\tab 4 8))   ; half way through
(test-equal "char-count-cells TAB at col 7 tabsize 8"
  1 (char-count-cells #\tab 7 8))   ; one before next stop

;; C0 control characters (other than NUL and TAB) are displayed as
;; "^X" and therefore take 2 cells: 1 for the caret plus 1 for the
;; letter.  This exercises both the caret-notation branch and wcwidth.
(test-equal "char-count-cells SOH (^A) is 2 cells"
  2 (char-count-cells #\x01 0 8))   ; SOH  -> ^A
(test-equal "char-count-cells ESC (^[) is 2 cells"
  2 (char-count-cells #\x1b 0 8))   ; ESC  -> ^[
(test-equal "char-count-cells US (^_) is 2 cells"
  2 (char-count-cells #\x1f 0 8))   ; US   -> ^_

;; DEL (U+007F) is also matched by ascii-iscntrl? and must yield 2
;; cells (displayed as ^?).
;; Bug fix: char-get-display-representation-of-control-char previously
;; used (+ code 64) which gives 191 for DEL instead of the correct
;; 63 (#\?).  The fix uses (logxor code 64).  Because wcwidth(191) and
;; wcwidth(63) both equal 1, the cell count is the same either way;
;; this test confirms correct handling of DEL as a control character.
(test-equal "char-count-cells DEL (^?) is 2 cells"
  2 (char-count-cells #\delete 0 8))

;; Ordinary printable ASCII falls through to (wcwidth chr) = 1.
;; This also exercises the else branch with a live wcwidth call.
(test-equal "char-count-cells letter is 1 cell"
  1 (char-count-cells #\a    0 8))
(test-equal "char-count-cells space is 1 cell"
  1 (char-count-cells #\space 0 8))
(test-equal "char-count-cells tilde is 1 cell"
  1 (char-count-cells #\~   0 8))

;; char-combining-mark?
;; U+0300 COMBINING GRAVE ACCENT has general category Mn (non-spacing mark).
(test-equal "char-combining-mark? COMBINING GRAVE ACCENT (Mn)"
  #t (char-combining-mark? #\x0300))
;; U+0308 COMBINING DIAERESIS -- also Mn.
(test-equal "char-combining-mark? COMBINING DIAERESIS (Mn)"
  #t (char-combining-mark? #\x0308))
;; Ordinary letters and digits are not combining marks.
(test-equal "char-combining-mark? rejects letter"
  #f (char-combining-mark? #\a))
(test-equal "char-combining-mark? rejects digit"
  #f (char-combining-mark? #\0))

;; Finish the testsuite, and report results.

;; wcwidth, a pure Scheme version of the C function.  Its results were
;; checked against glibc's wcwidth in C.UTF-8 for every code point.
(test-equal "wcwidth NUL" 0 (wcwidth #\nul))
(test-equal "wcwidth ASCII letter" 1 (wcwidth #\a))
(test-equal "wcwidth control character" -1 (wcwidth #\x1b))
(test-equal "wcwidth DEL" -1 (wcwidth #\delete))
(test-equal "wcwidth C1 control" -1 (wcwidth #\x85))
(test-equal "wcwidth combining acute accent" 0 (wcwidth #\x301))
(test-equal "wcwidth zero width space" 0 (wcwidth #\x200b))
(test-equal "wcwidth soft hyphen" 1 (wcwidth #\xad))
(test-equal "wcwidth Hangul medial vowel" 0 (wcwidth #\x1161))
(test-equal "wcwidth CJK ideograph" 2 (wcwidth #\x4e2d))
(test-equal "wcwidth Hangul syllable" 2 (wcwidth #\xac00))
(test-equal "wcwidth fullwidth A" 2 (wcwidth #\xff21))
(test-equal "wcwidth emoji" 2 (wcwidth #\x1f600))
;; U+2FFC is newer than Guile's Unicode tables, but is in glibc's.
(test-equal "wcwidth recent ideographic description character" 2 (wcwidth #\x2ffc))
(test-equal "wcwidth plane 2 noncharacter" -1 (wcwidth #\x2fffd))
(test-equal "wcwidth unassigned" -1 (wcwidth #\x378))
(test-equal "wcwidth line separator" -1 (wcwidth #\x2028))
(test-equal "char-count-cells CJK ideograph" 2 (char-count-cells #\x4e2d 0 8))

(test-end "t-mlg-characters")
