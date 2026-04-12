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
  (member (char-general-category c) '(Mn Mc Me)))

(define (characters-load-extension)
  (load-extension "libmlg" "init_chars_lib"))

(characters-load-extension)
