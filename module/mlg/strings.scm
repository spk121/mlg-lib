;;; -*- mode: scheme; coding: us-ascii; indent-tabs-mode: nil; -*-
;;; (mlg strings) - more helper functions for strings
;;; Copyright (C) 2017, 2018, 2019 Michael L. Gran <spk121@yahoo.com>
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

(define-module (mlg strings)
  #:use-module (srfi srfi-1)
  #:use-module (mlg characters)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 format)
  #:use-module (rnrs bytevectors)
  #:use-module (mlg assert)
  #:use-module (mlg logging)
  #:export (string-base-length
            string-crc16
            string-cell-length
            string-ends-with?
            string->format-escaped-string
            string-get-first-digit
            string-ref-safe
            string-sed-substitute
            string-starts-with?
            string-strip-escapes
            string->ed-escaped-string
            string-x-cell->x-data
            string-is-valid-posix-make-macro-name?
            string-is-terminated?
            string-ensure-single-newline
            string-append-map))

(define (string-ends-with? str char)
  "Return #t is the last character in string STR
is CHAR."
  (assert (string? str))
  (assert (char? char))
  (if (string-null? str)
      #f
      (char=? char (string-ref str (1- (string-length str))))))

(define (string->format-escaped-string str)
  "Return a new string that has (ice-9 format) codes escaped."
  (string-fold
   (lambda (c prev)
     (cond
      ((char=? c #\~)
       (string-append prev (string #\~ #\~)))
      (else
       (string-append prev (string c)))))
   ""
   str))

(define (string-get-first-digit str)
  "Returns an integer from zero to nine which indicates
the first character '0' through '9' found in the string.
If there are no characters '0' through '9' in the string,
it returns #f."
  (let ((len (string-length str)))
    (let loop ((i 0))
      (if (= i len)
          #f
          ;; else
          (let ((x (char->numeric-value (string-ref str i))))
            (if x
                x
                (loop (1+ i))))))))

(define (string-ref-safe str i)
  "Returns the nth character in a string, or #\null if there is no
such character."
  (if (or (not (string? str))
          (not (and (integer? i) (>= i 0))))
      #\null
      ;; else
      (if (>= i (string-length str))
          #\null
          ;; else
          (string-ref str i))))

(define (_sed-substitute String MatchStruct ReplacementString)
  "Given a String and a MatchStruct, replace the matching characters
in String with ReplacementString, handling any escape sequences."
  ;; Handle the escape sequences in the replacement string
  (let loop ((j 0) (rstr ""))
    (let ((c (string-ref-safe ReplacementString j)))
      (cond
       ;; If we've reached the end of the replacement string,
       ;; we're done.
       ((char=? c #\null)
        rstr)

       ;; Backslash escapes in the replacement string, so look
       ;; ahead for the next character.
       ((char=? c #\\)
        (let ((c2 (string-ref-safe ReplacementString (1+ j))))
          (cond
           ((char=? c2 #\null)
            ;; Backslash at the end of the string is used as a
            ;; literal backslash.  We're done.
            (string-append rstr "\\"))

           ((char->numeric-value c2)
            ;; Backslash + digit means we're going to include
            ;; the Nth submatch here, then keep looping.
            (let ((n (char->numeric-value c2)))
              (loop (+ 2 j)
                    (string-append
                     rstr
                     (if (< n (match:count MatchStruct))
                         (match:substring MatchStruct n)
                         ;; else
                         "")))))

           ((char=? c2 #\n)
            ;; Backslash + n means we're going to
            ;; put a real newline here.
            (loop (+ 2 j)
                  (string-append rstr "\n")))

           (else
            ;; Backslash + anything else is an escape?  FIXME:
            ;; check if it is really an escape
            (loop (+ 2 j)
                  (string-append
                   rstr
                   (string c2)))))))

       ((char=? c #\&)
        ;; Ampersand is replaced by the entire match
        (loop (1+ j)
              (string-append
               rstr
               (match:substring MatchStruct))))

       (else
        ;; Otherwise, this character is not an escape
        ;; character.
        (loop (1+ j)
              (string-append
               rstr
               (string c))))))))

(define (_string-sed-substitute-one String Matches ReplacementString Occurrence)
  "Given a list of Matches, this replaces the Nth matching occurrence
in String with ReplacementString, handling any possible escapes in
ReplacementString."
  (let ((match-struct (list-ref Matches (1- Occurrence)))) ; sed matches are 1-indexed
    (string-append
     (match:prefix match-struct)
     (_sed-substitute String match-struct ReplacementString)
     (match:suffix match-struct))))

(define (_string-sed-substitute-global String Matches ReplacementString)
  "Given a list of Matches, this replaces all the  matching occurrences
in String with ReplacementString, handling any possible escapes in
ReplacementString."
  (let loop ((i 0) (output ""))
    (cond

     ;; The 1st iteration, the prefix is from the beginning
     ;; to the matching string.
     ((= i 0)
      (loop 1
            (string-append
             (match:prefix (first Matches))
             (_sed-substitute String (first Matches) ReplacementString))))

     ;; For other iterations, the prefix is in between the matching
     ;; strings.
     ((< i (length Matches))
      (loop (1+ i)
            (string-append
             output
             (substring String
                        (match:end (list-ref Matches (1- i)))
                        (match:start (list-ref Matches i)))
             (_sed-substitute String (list-ref Matches i) ReplacementString))))

     ;; To finish, add the suffix after the last match
     ((= i (length Matches))
      (string-append output (match:suffix (last Matches)))))))

(define (string-sed-substitute String RegexString ReplacementString FlagsString)
  "Given a regular expression string, a replacement string,
and flags, return a new string modified by the given subsitututon.

An amersand '&' in the replacement string shall be replaced by the
string matching the regular expression string.  Backslash + digit
in the replacement string shall be replaced by the corresponding
back reference in the regular expression string, or by an empty
string if there is no corresponding back reference.

Flags is a string consisting of one or more of
- 'g' - globally substitute all non-overlapping instances of the regular
  expression.
- '1' to '9' - substitute only the Nth occurrence of the regular expression
"
  ;; First, find all the matches.
  (let ((matches (list-matches RegexString String)))
    (if (null? matches)
        ;; No matches found, so just return the input string.
        String
        ;; else
        (let ((global? (and (string-contains FlagsString "g")
                            (> (length matches) 1)))
              (occurrence (or (string-get-first-digit FlagsString) 1)))
          ;; Unless the user has explicitly requested a specific
          ;; occurrence, we assume that we're matching the first
          ;; match, or, if a 'g' flag was given, we matching on all
          ;; matches.
          (if (and (not global?) (< (length matches) occurrence))
              ;; Not enough matches found, so just return the input
              ;; string.
              String
              ;; else
              (if global?
                  (_string-sed-substitute-global String matches ReplacementString)
                  ;; else
                  (_string-sed-substitute-one String matches ReplacementString occurrence)))))))

(define (string-starts-with? str char)
  "Return #t is the first character in string STR
is CHAR."
  (assert (string? str))
  (assert (char? char))
  (if (string-null? str)
      #f
      (char=? char (string-ref str 0))))

(define (string-strip-escapes str)
  "Returns a copy of STR with backslash string escapes removed."
  (let* ((esc #f)
         (newstr (string-fold
                  (lambda (c prev)
                    (cond
                     ((and (char=? c #\\) (not esc))
                      (set! esc #t)
                      prev)
                     (else
                      (set! esc #f)
                      (string-append prev (string c)))))
                  ""
                  str)))
    (if esc
        (string-append newstr (string #\\))
        newstr)))

(define (string->ed-escaped-string str)
  "Converts a string into another string. Non-printable characters
will be converted into the escape sequences that POSIX 'ed' prefers.
Dollar signs will be escaped, as well."
  (string-fold
   (lambda (c prev)
     (cond
      ((char=? c #\\)
       (string-append prev (string #\\ #\\)))
      ((char=? c #\alarm)
       (string-append prev (string #\\ #\a)))
      ((char=? c #\backspace)
       (string-append prev (string #\\ #\b)))
      ((char=? c #\page)
       (string-append prev (string #\\ #\f)))
      ((char=? c #\return)
       (string-append prev (string #\\ #\r)))
      ((char=? c #\tab)
       (string-append prev (string #\\ #\t)))
      ((char=? c #\vtab)
       (string-append prev (string #\\ #\v)))
      ((char=? c #\$)
       (string-append prev (string #\\ #\$)))
      ((not (char-set-contains? char-set:printing c))
       (string-append prev (format #f "\\~3,'0o" (char->integer c))))
      (else
       (string-append prev (string c)))))
   ""
   (string-normalize-nfc str)))

(define (string-base str)
  "Returns a string with any combining marks removed."
  (apply string
         (string-fold-right
          (lambda (c r)
            (if (char-combining-mark? c)
                r
                (cons c r)))
          '()
          str)))

(define (string-base-length str)
  "Returns the number of characters in the string, ignoring combining
marks."
  (string-length (string-base str)))

(define (string-base-indices str)
  "Returns a list of indices that indicate the positions of all
the codepoints in the string that are not combining marks."
  (let loop ([i 0]
             [str str]
             [indices '()])
    (if (string-null? str)
        indices
        ;; else
        (let ([c (string-ref str 0)])
          (if (char-combining-mark? c)
              (loop (+ i 1) (substring str 1) indices)
              (loop (+ i 1) (substring str 1) (append indices (list i))))))))

(define (string-count-base-codepoints-in-substring str start end)
  (string-base-length (substring str start end)))

(define (string-x-index->x-data n str)
  "Returns the count of the number of characters in the first N
codepoints of STR.  Characters formed from a combination of base
codepoints and combining-mark characters are counted as a single
character.  If N is equal to the number of base characters in the
string, the string length is returned.  If N is greater than the
number of base characters in the string, #f is returned."
  (cond
   [(> n (string-length str))
    #f]
   [(= n 0)
    0]
   [else
    (let loop ([ch (string-ref str 0)]
               [rest (substring str 1)]
               [pos 0]
               [i 1])
      ;; (format #t "char cur ~S next ~S base? ~S pos before op ~S"
      ;;         ch
      ;;         (if (string-null? rest) #f (string-ref rest 0))
      ;;         (if (string-null? rest) #f (char-base? (string-ref rest 0)))
      ;;         pos)
      (if (or (string-null? rest)
              (not (char-combining-mark? (string-ref rest 0))))
          (set! pos (+ 1 pos)))
      ;; (format #t " pos after op ~S~%" pos)
      (if (= i n)
          pos
          ;; else
          (loop (string-ref rest 0)
                (substring rest 1)
                pos
                (+ i 1))))]))

(define (string-x-index->x-cell n str tabsize)
  "Returns the character cell location of the Nth codepoint in the
string.  If N is equal to the string length, the character cell
location just after then end of the string is given.  If N is greater
than the string length, #f is returned.  Horizontal tabulation
characters are assumed to occupy cells up to the next tab stop.

Combining marks are presumed to occupy the same character cell as the
base character that they are attached to.  But this isn't the case for
all zero-width characters.  A non-combining zero width character that
follows non-zero-width character will begin in a new cell, and then
character that follows it will occupy the same cell."
  (cond
   [(> n (string-length str))
    #f]
   [(= n 0)
    0]
   [else
    (let loop ([ch (list (string-ref str 0))]
               [rest (substring str 1)]
               [cell 0]
               [i 1])
      ;; (format #t "char cur ~S next ~S base? ~S cell before op ~S"
      ;;         ch
      ;;         (if (string-null? rest) #f (string-ref rest 0))
      ;;         (if (string-null? rest) #f (char-base? (string-ref rest 0)))
      ;;         cell)
      (if (or (string-null? rest)
              (not (char-combining-mark? (string-ref rest 0))))
          ;; The next location is a new character, so sum of the width
          ;; of this character, including its base character and any
          ;; combining marks
          (cond
           [(char=? #\tab (car ch))
            (set! cell (* tabsize (quotient (+ cell tabsize) tabsize)))
            (set! ch '())]
           [else
            ;; Sum over the width of all the character in the previous
            ;; character, which might be a base character plus combining
            ;; marks, or which might be a standalone character.
            (set! cell (+ cell (apply + (map wcwidth ch))))
            (set! ch '())]))
      ;; (format #t " cell after op ~S~%" cell)
      (if (= i n)
          cell
          ;; else
          (loop (append ch (list (string-ref rest 0)))
                (substring rest 1)
                cell
                (+ i 1))))]))

;; aka string-find-index-of-nth-base-codepoint
(define (string-x-data->x-index n str)
  "Returns the string index that points to the Nth non-combining-mark
character in the string.  If N is equal to the number of non-combining-mark
characters in the string, the string length is returned.  If there are
fewer than N non-combining-mark codepoints in the string, #f is returned."
  (cond
   [(= n 0)
    0]
   [else
    (let*  ([base-list (string-base-indices str)]
            [len (length base-list)])
      (cond
       [(> n len)
        #f]
       [(= n len)
        (string-length str)]
       [else
        (list-ref base-list n)]))]))

(define (string-x-data->x-cell n str tabsize)
  "Finds the character cell location of the Nth base character in the
string.  Characters that are formed from a base character plus one or
more combining marks are counted as a single character.  If N is equal
to the number of base characters in the string, the character cell
location just after the end of the string is given.  If N is greater
than the number of base characters in the string, #f is returned."
  (let ([baselen (string-base-length str)])
    (cond
     [(> n baselen)
      #f]
     [(= n baselen)
      (last (string-compute-x-cell-list-from-string str tabsize))]
     [else
      (list-ref (string-compute-x-cell-list-from-string str tabsize)
                (string-x-data->x-index n str))])))

(define (string-x-cell->x-index n str tabsize)
  "Returns the string index of the first codepoint in STR that
occupies the Nth character cell. If N is the number of character cells
the entire string occupies, it returns the string length.  If N is
greater than the number of character cells that STR occupies, it
returns #f."
  ;; FIXME: This is very inefficient.
  (let* ([x-cell-list (string-compute-x-cell-list-from-string str tabsize)]
         [i-start (length (take-while (lambda (x) (<= x n)) x-cell-list))])
    (if (> n (last x-cell-list))
        #f
        (- i-start 1))))

(define (string-x-cell->x-data n str tabsize)
  "Returns the number of characters in the first N character cells of
the string.  Characters formed from a combination of a base character
plus one or more combining marks are counted as a single character.
If N is equal to the number of base characters in the string, the cell
after the end of the string is given.  If N is greater than the number
of base characters in the string, #f is returned."
  (let ([x-cell-list (string-compute-x-cell-list-from-string str tabsize)])
    (cond
     [(> n (last x-cell-list))
      #f]
     [(= n (last x-cell-list))
      (string-base-length str)]
     [else
      (string-x-index->x-data (string-x-cell->x-index n str tabsize) str)])))

(define (string-find-index-of-nth-base-codepoint str n)
  "Returns the string index that points to the Nth non-combining-mark
character in the string.  If N is equal to the number of
non-combining-mark characters in the string, the string length is
returned.  If there are fewer than N non-combining-mark codepoints in
the string, #f is returned"
  (let loop ([i 0]
             [n n]
             [str str])
    (cond
     [(= n 0)
      i]
     [(string-null? str)
      #f]
     [else
      (if (char-combining-mark? (string-ref str 0))
          (loop (+ i 1) n (substring str 1))
          (loop (+ i 1) (- n 1) (substring str 1)))])))


(define (string-find-index-of-nth-cell str n tabsize)
  "Returns the string index of the first codepoint in STR that
occupies the Nth character cell. If N is the number of character cells
the entire string occupies, it returns the string length.  If N is
greater than the number of character cells that STR occupies, it
returns #f."
  ;; FIXME: This is very inefficient.
  (let* ([x-cell-list (string-compute-x-cell-list-from-string str tabsize)]
         [i-start (length (take-while (lambda (x) (<= x n)) x-cell-list))])
    (if (> n (last x-cell-list))
        #f
        (- i-start 1))))

(define (string-compute-x-cell-list-from-string str tabsize)
  ;;(format #t "In string-compute-x-cell-list-from-string ~S ~S ~%" str tabsize)
  (let loop ([pp 0] [lst '()] [str str])
    (cond
     [(not (= 0 (string-length str)))
      (loop (+ pp (char-count-cells (string-ref str 0) pp tabsize))
            (append lst (list pp))
            (substring str 1))]
     [else
      ;; return list
       ;;(format #t "Exiting string-compute-x-cell-list-from-string = ~a~%" (append lst (list pp)))
       (append lst (list pp))])))

(define (string-cell-length str tabsize)
  "Returns the number of cells that the string occupies."
  (last (string-compute-x-cell-list-from-string str tabsize)))

(define (%string-render-line-tabs str tabsize)
  "Return a copy of STR with each tab expanded into
an appropriate number of spaces."
  (let* ([x-cell-list (string-compute-x-cell-list-from-string str tabsize)]
         [str2 ""])
    (string-for-each-index
     (lambda (i)
       (if (char=? (string-ref str i) #\tab)
           (set! str2 (string-append str2 (make-string (- (list-ref x-cell-list (+ i 1))
                                                          (list-ref x-cell-list i))
                                                       #\space)))
           (set! str2 (string-append str2 (string (string-ref str i))))))
     str)
    str2))

(define* (string-render-line str #:key (tabsize 8)
                             (x-cell-start 0) (x-width 80)
                             (pad? #t))
  "Return the substring of str beginning at the x-cell cell position
and having x-width cells.  Tabs are converted to spaces, and
characters that would be clipped by the edges are replaced with
spaces.  If PAD is true, the end of the line is padded with spaces."
  (let* ([str (%string-render-line-tabs str tabsize)]
         [x-cell-end (+ x-cell-start x-width)]
         [x-cell-list (string-compute-x-cell-list-from-string str tabsize)]
         ;; The index of the first character past the start of the window
         [i-start (list-index (lambda (x) (>= x x-cell-start)) x-cell-list)]
         ;; The index of the first character past the end of the window
         [i-end (list-index (lambda (x) (> x x-cell-end)) x-cell-list)]
         ;; The number of left-side spaces needed
         [left-padding (min x-width
                            (if i-start
                                (- (list-ref x-cell-list i-start) x-cell-start)
                                0))]
         ;; #t if the last character straddles the frame
         [truncated-p (and i-end (> (list-ref x-cell-list i-end) x-cell-end))]
         ;; The number of cells that the windowed string occupies
         [str-x-size (cond
                      [(and (not i-start) (not i-end))
                       ;; window starts after string
                       0]
                      [(and i-start (not i-end))
                       ;; string starts in window and ends before window
                       (- (last x-cell-list) (list-ref x-cell-list i-start))]
                      [(= i-start i-end)
                       ;; string starts after window
                       0]
                      [(and (= i-start (- i-end 1))
                            truncated-p)
                       ;; the only character is truncated
                       0]
                      [else
                       ;; the normal case
                       (if truncated-p
                           (- (list-ref x-cell-list (- i-end 1))
                              (list-ref x-cell-list i-start))
                           ;; else
                           (- (list-ref x-cell-list i-end)
                              (list-ref x-cell-list i-start)))])]
         [right-padding (if (or pad? truncated-p)
                            (- x-width (+ left-padding str-x-size))
                            ;; else
                            0)])

    ;; (format (current-error-port) "~s ~s ~s~%" left-padding str-pp-size right-padding)
    (string-append
     ;; Space padding for initial truncated characters
     (make-string left-padding #\space)
     ;; Main list
     (cond
      [(not i-start)
       ""]
      [i-start
       (let ([inner-str ""])
         (do ([i i-start (+ i 1)]) ([>= i (- (or i-end (length x-cell-list)) 1)])
           (if (char=? #\tab (string-ref str i))
               (set! inner-str (string-append
                                inner-str
                                (make-string (- (list-ref x-cell-list (+ i 1))
                                                (list-ref x-cell-list i)) #\space)))
               (set! inner-str (string-append inner-str (string (string-ref str i))))))
         inner-str)])
     ;; End of line space padding
     (make-string right-padding #\space))))

(define (string-is-valid-posix-make-macro-name? str)
  "Return #t if STR would be a valid name for a macro in a POSIX makefile."
  (and (> (string-length str) 0)
       (not (string-index str
                          (lambda (c)
                            (not (is-valid-posix-make-macro-name-char? c)))))))

(define (string-is-terminated? str)
  "Returns #t if str has a line terminator at the end"
  (assert (string? str))
  (if (string-null? str)
      #f
      (let ((end-char (string-ref str (1- (string-length str)))))
        (if (any (lambda (c)
                   (char=? c end-char))
                 '(#\newline #\linefeed
                   #\x0085          ; NEL
                   #\x2028          ; Line separator
                   #\x2029          ; Paragraph separator
                   ))
            #t
            #f))))

(define (string-ensure-single-newline str)
  "Returns a copy of str with a newline at the end.  If the string
contains any other line terminators, they will be removed."
  (let ((terminators '(#\newline #\linefeed
                       #\x0085          ; NEL
                       #\x2028          ; Line separator
                       #\x2029          ; Paragraph separator
                       )))
    (string-append
     (string-fold (lambda (c s)
                    (if (member c terminators)
                        s
                        ;; else
                        (string-append s (string c))))
                  ""
                  str)
     "\n")))

(define (string-append-map f lst)
  "Equivalent to (apply string-append (map f lst)).
Maps the procedure F of the elements of a list of strings,
appending the results together as a single string."
  (apply string-append (map f lst)))

;; There are many versions of this algorithm out in the public
;; domain.  It claims to implement the CCITT X.25 version of CRC-16.
(define (string-crc16 str)
  "Compute a 16-bit CRC of the UTF-8 encoding of the string STR, using
the CCITT X.25 polynomial.  The two bytes of the result are swapped, as
in the original C version of this procedure."
  (assert (string? str))
  (let* ((bv (string->utf8 str))
         (len (bytevector-length bv))
         (crc (let loop ((i 0) (crc #xffff))
                (if (= i len)
                    crc
                    (loop (1+ i)
                          (let bitloop ((bit 0)
                                        (data (bytevector-u8-ref bv i))
                                        (crc crc))
                            (if (= bit 8)
                                crc
                                (bitloop (1+ bit)
                                         (ash data -1)
                                         (if (logtest 1 (logxor crc data))
                                             (logxor (ash crc -1) #x8408)
                                             (ash crc -1)))))))))
         (inv (logand #xffff (lognot crc))))
    ;; Swap the bytes.
    (logior (ash (logand inv #xff) 8)
            (ash inv -8))))
