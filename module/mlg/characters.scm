;;; -*- mode: scheme; coding: us-ascii; indent-tabs-mode: nil; -*-
;;; (mlg characters) - more helper functions for characters
;;; Copyright (C) 2017, 2018 Michael L. Gran <spk121@yahoo.com>
;;;
;;; This program is free software: you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundataion, either version 3 of
;;; this License, or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see
;;; <http://www.gnu.org/licenses/>

(define-module (mlg characters)
  #:use-module (mlg numval)
  #:export (
            ascii-isalnum?
            ascii-isalpha?
            ascii-iscntrl?
            ascii-isdigit?
            ascii-isgraph?
            ascii-islower?
            ascii-isprint?
            ascii-ispunct?
            ascii-isspace?
            ascii-isupper?
            ascii-isxdigit?
            ascii-is-portable-character-set?
            char->numeric-value
            isalnum?
            isalpha?
            iscntrl?
            isdigit?
            isgraph?
            islower?
            isprint?
            ispunct?
            isspace?
            isupper?
            isxdigit?
            is-portable-character-set?
            is-valid-posix-make-macro-name-char?
            tolower
            toupper
            U+
            char-count-cells
            char-combining-mark?
            characters-load-extension
            wcwidth
            ))

(define (ascii-isalnum? c)
  "Return true if C is both ASCII and a letter or digit."
  (and
   (char-set-contains? char-set:letter+digit c)
   (char-set-contains? char-set:ascii c)))

(define (ascii-isalpha? c)
  "Return true if C is both ASCII and a letter."
  (and
   (char-set-contains? char-set:letter c)
   (char-set-contains? char-set:ascii c)))

(define (ascii-iscntrl? c)
  "Return true if C is both ASCII and a control character"
  (and
   (char-set-contains? char-set:iso-control c)
   (char-set-contains? char-set:ascii c)))

(define (ascii-isdigit? c)
  "Return #t if C is both ASCII and a digit."
  (and
   (char-set-contains? char-set:digit c)
   (char-set-contains? char-set:ascii c)))

(define (ascii-isgraph? c)
  "Return #t if C is both ASCII and a graphic character."
  (and
   (char-set-contains? char-set:graphic c)
   (char-set-contains? char-set:ascii c)))

(define (ascii-islower? c)
  "Return #t if C is both ASCII and a lowercase letter."
  (and
   (char-set-contains? char-set:lower-case c)
   (char-set-contains? char-set:ascii c)))

(define (ascii-isprint? c)
  "Return #t if C is both ASCII and a printing character."
  (and
   (char-set-contains? char-set:printing c)
   (char-set-contains? char-set:ascii c)))

(define (ascii-ispunct? c)
  "Return #t if C is an ASCII graphical character that is not alphanumeric.
Note that this includes both punctuation and symbols."
  (and (char-set-contains? char-set:graphic c)
       (not (char-set-contains? char-set:letter+digit c))
       (char-set-contains? char-set:ascii c)))

(define (ascii-isspace? c)
  "Return #t if C is both ASCII and a whitespace character."
  (and
   (char-set-contains? char-set:whitespace c)
   (char-set-contains? char-set:ascii c)))

(define (ascii-isupper? c)
  "Return #t if C is both ASCII and an uppercase letter."
  (and
   (char-set-contains? char-set:upper-case c)
   (char-set-contains? char-set:ascii c)))

(define (ascii-isxdigit? c)
  "Return #t if C is both ASCII and a hexadecimal digit."
  (and
   (char-set-contains? char-set:hex-digit c)
   (char-set-contains? char-set:ascii c)))

(define (char->numeric-value c)
  "Given a character C, return a numeric value associated with that
character, or #f, if the character is not associated with a numeric
value."
  (assv-ref *unicode-numval-alist* c))

(define (isalnum? c)
  "Return #t if character C is alphabetic or numeric."
  (char-set-contains? char-set:letter+digit c))

(define (isalpha? c)
  "Return #t if character C is a letter."
  (char-set-contains? char-set:letter c))

(define (iscntrl? c)
  "Return true if C an ISO C0 or C1 control character"
  (char-set-contains? char-set:iso-control c))

(define (isdigit? c)
  "Return #t if C is a digit."
  (char-set-contains? char-set:digit c))

(define (isgraph? c)
  "Return #t if C is a graphic character."
  (char-set-contains? char-set:graphic c))

(define (islower? c)
  "Return #t if C a lowercase letter."
  (char-set-contains? char-set:lower-case c))

(define (isprint? c)
  "Return #t if C is a printing character."
   (char-set-contains? char-set:printing c))

(define (ispunct? c)
  "Return #t if C is a graphical character that is not alphanumeric.
Note that this includes both punctuation and symbols."
  (and (char-set-contains? char-set:graphic c)
       (not (char-set-contains? char-set:letter+digit c))))

(define (isspace? c)
  "Return #t if C is a whitespace character."
   (char-set-contains? char-set:whitespace c))

(define (isupper? c)
  "Return #t if C is an uppercase letter."
   (char-set-contains? char-set:upper-case c))

(define (isxdigit? c)
  "Return #t if C is hexadecimal digit."
  (char-set-contains? char-set:hex-digit c))

(define (is-portable-character-set? c)
  "Return #t if C is in the POSIX-defined Portable Character Set."
  (or (char=? c #\null)
      (char=? c #\alarm)
      (char=? c #\backspace)
      (char=? c #\tab)
      (char=? c #\return)
      (char=? c #\newline)
      (char=? c #\vtab)
      (char=? c #\page)
      (char=? c #\space)
      (and (char>=? c #\!) (char<=? c #\~))))

(define (is-valid-posix-make-macro-name-char? c)
  "Return #t is C is a character that would be valid is a POSIX
make macro name, e.g., that it is ASCII alphanumeric, period or underscore."
  (or (char=? c #\.)
      (char=? c #\_)
      (ascii-isalnum? c)))

(define (ascii-is-portable-character-set? c)
  "Return #t if C is in the POSIX-defined Portable Character Set."
  (is-portable-character-set? c))

(define (tolower c)
  "Return the lowercase character version of C"
  (char-downcase c))

(define (toupper c)
  "Return the uppercase character version of C"
  (char-upcase c))

(define (U+ x)
  "A shorthand for integer->char."
  (integer->char x))

(define (char-get-display-representation-of-control-char c)
  "The character to use when displaying controls in \"^X\" form"
  (integer->char (logxor (char->integer c) 64)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; wcwidth

;; The number of terminal columns a character occupies.  This is a pure
;; Scheme version of the C library's wcwidth.  Unlike the C function,
;; it does not depend on the current locale: it gives the results that
;; glibc gives in a UTF-8 locale.

;; Ranges of East Asian Wide and Fullwidth characters, which occupy two
;; columns, as pairs of first and last code points.  This table was
;; generated from the output of glibc 2.39's wcwidth in the C.UTF-8
;; locale.  It includes some code points that are assigned in glibc's
;; Unicode data but are still unassigned in Guile's.
(define %wcwidth-wide-ranges
  #(
  #x1100 #x115F #x231A #x231B #x2329 #x232A #x23E9 #x23EC #x23F0 #x23F0
  #x23F3 #x23F3 #x25FD #x25FE #x2614 #x2615 #x2648 #x2653 #x267F #x267F
  #x2693 #x2693 #x26A1 #x26A1 #x26AA #x26AB #x26BD #x26BE #x26C4 #x26C5
  #x26CE #x26CE #x26D4 #x26D4 #x26EA #x26EA #x26F2 #x26F3 #x26F5 #x26F5
  #x26FA #x26FA #x26FD #x26FD #x2705 #x2705 #x270A #x270B #x2728 #x2728
  #x274C #x274C #x274E #x274E #x2753 #x2755 #x2757 #x2757 #x2795 #x2797
  #x27B0 #x27B0 #x27BF #x27BF #x2B1B #x2B1C #x2B50 #x2B50 #x2B55 #x2B55
  #x2E80 #x2E99 #x2E9B #x2EF3 #x2F00 #x2FD5 #x2FF0 #x3029 #x302E #x303E
  #x3041 #x3096 #x309B #x30FF #x3105 #x312F #x3131 #x318E #x3190 #x31E3
  #x31EF #x321E #x3220 #xA48C #xA490 #xA4C6 #xA960 #xA97C #xAC00 #xD7A3
  #xF900 #xFA6D #xFA70 #xFAD9 #xFE10 #xFE19 #xFE30 #xFE52 #xFE54 #xFE66
  #xFE68 #xFE6B #xFF01 #xFF60 #xFFE0 #xFFE6 #x16FE0 #x16FE3
  #x16FF0 #x16FF1 #x17000 #x187F7 #x18800 #x18CD5 #x18D00 #x18D08
  #x1AFF0 #x1AFF3 #x1AFF5 #x1AFFB #x1AFFD #x1AFFE #x1B000 #x1B122
  #x1B132 #x1B132 #x1B150 #x1B152 #x1B155 #x1B155 #x1B164 #x1B167
  #x1B170 #x1B2FB #x1F004 #x1F004 #x1F0CF #x1F0CF #x1F18E #x1F18E
  #x1F191 #x1F19A #x1F200 #x1F202 #x1F210 #x1F23B #x1F240 #x1F248
  #x1F250 #x1F251 #x1F260 #x1F265 #x1F300 #x1F320 #x1F32D #x1F335
  #x1F337 #x1F37C #x1F37E #x1F393 #x1F3A0 #x1F3CA #x1F3CF #x1F3D3
  #x1F3E0 #x1F3F0 #x1F3F4 #x1F3F4 #x1F3F8 #x1F43E #x1F440 #x1F440
  #x1F442 #x1F4FC #x1F4FF #x1F53D #x1F54B #x1F54E #x1F550 #x1F567
  #x1F57A #x1F57A #x1F595 #x1F596 #x1F5A4 #x1F5A4 #x1F5FB #x1F64F
  #x1F680 #x1F6C5 #x1F6CC #x1F6CC #x1F6D0 #x1F6D2 #x1F6D5 #x1F6D7
  #x1F6DC #x1F6DF #x1F6EB #x1F6EC #x1F6F4 #x1F6FC #x1F7E0 #x1F7EB
  #x1F7F0 #x1F7F0 #x1F90C #x1F93A #x1F93C #x1F945 #x1F947 #x1F9FF
  #x1FA70 #x1FA7C #x1FA80 #x1FA88 #x1FA90 #x1FABD #x1FABF #x1FAC5
  #x1FACE #x1FADB #x1FAE0 #x1FAE8 #x1FAF0 #x1FAF8 #x20000 #x2A6DF
  #x2A700 #x2B739 #x2B740 #x2B81D #x2B820 #x2CEA1 #x2CEB0 #x2EBE0
  #x2EBF0 #x2EE5D #x2F800 #x2FA1D #x30000 #x3134A #x31350 #x323AF))

(define (%in-ranges? c ranges)
  "Return #t if the integer C is in one of the ranges in the vector
RANGES, which holds sorted pairs of first and last values."
  (let loop ((lo 0)
             (hi (1- (quotient (vector-length ranges) 2))))
    (and (<= lo hi)
         (let* ((mid (quotient (+ lo hi) 2))
                (first (vector-ref ranges (* 2 mid)))
                (last (vector-ref ranges (1+ (* 2 mid)))))
           (cond
            ((< c first) (loop lo (1- mid)))
            ((> c last) (loop (1+ mid) hi))
            (else #t))))))

;; Format characters (category Cf) that are nonetheless displayed with
;; a width of one: the soft hyphen, and the prepended concatenation
;; marks, such as ARABIC NUMBER SIGN.
(define %wcwidth-visible-format-chars
  '(#xAD #x600 #x601 #x602 #x603 #x604 #x605 #x6DD #x70F #x890 #x891
    #x8E2 #x110BD #x110CD))

(define (wcwidth chr)
  "Return the number of terminal columns needed to display the
character CHR: 0 for the null character and combining or other
zero-width characters, 2 for East Asian wide characters, -1 for control
characters and unassigned code points, and 1 otherwise."
  (let ((c (char->integer chr))
        (cat (char-general-category chr)))
    (cond
     ((zero? c) 0)
     ((memq cat '(Cc Zl Zp)) -1)
     ((memq cat '(Mn Me)) 0)
     ((eq? cat 'Cf)
      (if (memv c %wcwidth-visible-format-chars) 1 0))
     ;; Hangul Jamo medial vowels and final consonants combine with the
     ;; preceding initial consonant.
     ((and (eq? cat 'Lo)
           (or (<= #x1160 c #x11FF) (<= #xD7B0 c #xD7FF)))
      0)
     ((%in-ranges? c %wcwidth-wide-ranges) 2)
     ((eq? cat 'Cn) -1)
     (else 1))))

(define (char-count-cells chr x tabSize)
  "Number of cells a character CHR at column X would take up"
  (cond
   [(eqv? chr #\nul)
    0]
   [(eqv? chr #\tab)
    (- tabSize (modulo x tabSize))]
   [(ascii-iscntrl? chr)
    ;; Add 1 for the caret '^'
    (+ 1 (wcwidth (char-get-display-representation-of-control-char chr)))]
   [else
    (wcwidth chr)]))

(define (char-combining-mark? c)
  "Return #t if this is a combining mark, like an accent"
  (and (member (char-general-category c) '(Mn Mc Me)) #t))

(define (characters-load-extension)
  "Formerly loaded the C version of wcwidth.  WCWIDTH is now written in
Scheme, so this does nothing.  It is kept for compatibility."
  #t)
