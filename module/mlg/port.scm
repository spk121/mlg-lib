;;; -*- mode: scheme; coding: us-ascii; indent-tabs-mode: nil; -*-
;;; (mlg port) - commands for reading from ports
;;; Copyright (C) 2017, 2019 Michael L. Gran <spk121@yahoo.com>
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

(define-module (mlg port)
  #:use-module (ice-9 rdelim)
  #:use-module (mlg strings)
  #:use-module (mlg characters)
  #:export (current-output-port-has-color?
            get-read-regex-string-err
            get-read-replacement-string-err
            format-error
            peek-char-safe
            peek-2nd-char-safe
            peek-char=?
            peek-char-ci=?
            peek-char-isalnum?
            peek-char-isalpha?
            peek-char-iscntrl?
            peek-char-isdigit?
            peek-char-isgraph?
            peek-char-islower?
            peek-char-isprint?
            peek-char-ispunct?
            peek-char-isspace?
            peek-char-isupper?
            peek-char-isxdigit?
            port-has-color?
            read-char=?
            read-char-safe
            read-extended-line
            read-filter
            read-whitespace
            read-line-terminator
            read-integer
            read-regex-string
            read-replacement-string
            ))

(define format-error
  (lambda args
    (apply format `(,(current-error-port) . ,args))))

(define (peek-char-safe port)
  "Read a char from port, returning #\null if #<eof> is encountered."
  (let ((c (peek-char port)))
    (if (eof-object? c)
        #\null
        c)))

(define (peek-char=? port c2)
  "Compare the next character availablle from PORT to a given
character, without updating por to point to the following character.
If the port returns #<eof>, this procedure returns #f."
  (let ((c (peek-char port)))
    (if (eof-object? c)
        #f
        ;; else
        (char=? c c2))))

(define (peek-char-ci=? port c2)
  (let ((c (peek-char port)))
    (if (eof-object? c)
        #f
        ;; else
        (char-ci=? c c2))))

(define-syntax %peek-char-test
  (syntax-rules ()
    ((_ port func)
     (let ((c (peek-char port)))
       (if (eof-object? c)
           #f
           ;; else
           (func c))))))

(define (peek-char-isalnum? port)
  "Return #t if the next character to be read in port is alphanumeric."
  (%peek-char-test port isalnum?))

(define (peek-char-isalpha? port)
  "Return #t if the next character to be read in port is alphabetic."
  (%peek-char-test port isalpha?))

(define (peek-char-iscntrl? port)
  "Return #t if the next character to be read in port is a control character."
  (%peek-char-test port iscntrl?))

(define (peek-char-isdigit? port)
  "Return #t if the next character to be read in port is a numerical."
  (%peek-char-test port isdigit?))

(define (peek-char-isgraph? port)
  "Return #t if the next character to be read in port is graphical."
  (%peek-char-test port isgraph?))

(define (peek-char-islower? port)
  "Return #t if the next character to be read in port is lower-case."
  (%peek-char-test port isgraph?))

(define (peek-char-isprint? port)
  "Return #t if the next character to be read in port is a printing character."
  (%peek-char-test port isprint?))

(define (peek-char-ispunct? port)
  "Return #t if the next character to be read in port is punctuation."
  (%peek-char-test port ispunct?))

(define (peek-char-isspace? port)
  "Return #t if the next character to be read in port is whitespace."
  (%peek-char-test port isspace?))

(define (peek-char-isupper? port)
  "Return #t if the next character to be read in port is upper-case."
  (%peek-char-test port isupper?))

(define (peek-char-isxdigit? port)
  "Return #t if the next character to be read in port is a hex digit character."
  (%peek-char-test port isxdigit?))

(define (peek-2nd-char-safe port)
  (let ((c (peek-char port)))
    (if (eof-object? c)
        #\null
        ;; else
        (begin
          (set! c (read-char port))
          (let ((c2 (peek-char port)))
            (unread-char c port)
            (if (eof-object? c2)
                #\null
                c2))))))

(define (port-has-color? port)
  "This procedure makes an educated guess as to whether the
given port can handle ANSI color escape codes.  It returns
#t or #f."
  ;; If the input port is not a tty or file port we are probably
  ;; running under the REPL, which does its own color handling.
  ;; If the output port is not a tty and a file port, then we are
  ;; probably not running in a terminal.

  (and (output-port? port)
       (file-port? port)
       (isatty? port)
       (file-port? (current-input-port))
       (isatty? (current-input-port))
       ;; Respect the NO_COLOR convention (https://no-color.org/).
       (not (getenv "NO_COLOR"))
       ;; COLORTERM=truecolor or 24bit is an explicit opt-in regardless of TERM.
       ;; Otherwise fall back to the TERM whitelist below.
       (or (member (getenv "COLORTERM") '("truecolor" "24bit"))
           (and
            (getenv "TERM")
            ;; I generated the following list with query_color.sh, which
            ;; searches the terminfo database for terminals that have ANSI
            ;; color capability.  Really I could trim this way down. For
            ;; example, 386at and atari, haha.  But I like to think that
            ;; somewhere out there somebody is using an old Atari as a
            ;; terminal to a machine running Guile...
            (member (getenv "TERM")
                    '(
                      "Apple_Terminal"
                      "Eterm-256color"
                      "Eterm-88color"
                      "absolute"
                      "alacritty"
                      "alacritty-direct"
                      "contour"
                      "contour-direct"
                      "contour-latest"
                      "domterm"
                      "dvtm-256color"
                      "fbterm"
                      "foot"
                      "foot-direct"
                      "gnome-256color"
                      "hpterm-color"
                      "hterm-256color"
                      "iTerm.app"
                      "iTerm2.app"
                      "iterm"
                      "iterm2"
                      "iterm2-direct"
                      "kitty"
                      "kitty-direct"
                      "konsole-256color"
                      "konsole-direct"
                      "mintty"
                      "mintty-direct"
                      "mlterm-256color"
                      "mlterm-direct"
                      "mosh-256color"
                      "mrxvt-256color"
                      "ms-terminal"
                      "nsterm"
                      "nsterm-256color"
                      "nsterm-build309"
                      "nsterm-build326"
                      "nsterm-build343"
                      "nsterm-build361"
                      "nsterm-build400"
                      "nsterm-build440"
                      "nsterm-direct"
                      "putty-256color"
                      "rio"
                      "rio-direct"
                      "rxvt-256color"
                      "rxvt-88color"
                      "rxvt-unicode"
                      "rxvt-unicode-256color"
                      "screen-256color"
                      "screen-256color-bce"
                      "screen-256color-bce-s"
                      "screen-256color-s"
                      "screen.konsole-256color"
                      "screen.mlterm-256color"
                      "screen.putty-256color"
                      "screen.vte-256color"
                      "screen.xterm-256color"
                      "scrt"
                      "securecrt"
                      "st-256color"
                      "st-direct"
                      "stterm-256color"
                      "teraterm-256color"
                      "terminator"
                      "terminology"
                      "terminology-0.6.1"
                      "terminology-1.0.0"
                      "terminology-1.8.1"
                      "termite"
                      "tmux-256color"
                      "tmux-direct"
                      "vscode"
                      "vscode-direct"
                      "vte-256color"
                      "vte-direct"
                      "wezterm"
                      "wy370"
                      "wy370-101k"
                      "wy370-105k"
                      "wy370-EPC"
                      "wy370-nk"
                      "wy370-rv"
                      "wy370-vb"
                      "wy370-w"
                      "wy370-wvb"
                      "wyse370"
                      "xterm+256color"
                      "xterm+256color2"
                      "xterm+256setaf"
                      "xterm+88color"
                      "xterm+88color2"
                      "xterm+direct"
                      "xterm+direct16"
                      "xterm+direct2"
                      "xterm+direct256"
                      "xterm+indirect"
                      "xterm-256color"
                      "xterm-88color"
                      "xterm-direct"
                      "xterm-direct16"
                      "xterm-direct2"
                      "xterm-direct256"
                      "xterm.js"
                      ))))))

(define (current-output-port-has-color?)
  "Returns #t if the current output port is a TTY for which
the TERM environment variable denotes a terminal that can handle
ANSI colors."
  (port-has-color? (current-output-port)))

(define (read-char=? port c2)
  "Read the next character available from PORT.  Return #t if it is
equal to the given character.  Return #f if it does not equal the
character, or if the port returned #<eof>."
  (let ((c (peek-char port)))
    (if (eof-object? c)
        #f
        ;; else
        (char=? c c2))))

(define (read-char-safe port)
  "Read a char from port, returning #\null if #<eof> is encountered."
  (let ((c (read-char port)))
    (if (eof-object? c)
        #\null
        c)))

(define* (read-extended-line #:optional (port (current-input-port)))
  "Reads a line of text from a port and returns a string.  If the line
of text ends with backslash, it reads an additional line which is
appended to the output."
  (let loop ((line (read-line port 'trim))
             (output ""))
    (cond
     ((eof-object? line)
      line)
     ((string-ends-with? line #\\)
      (loop (read-line port 'trim)
            (string-append output (string-drop-right line 1))))
     (else
      (string-append output line)))))

(define* (read-filter str #:optional (port (current-input-port)))
  "Read as many characters as possible from port, stopping
when #<eof> is found or when a character that is not in str
is found.  Return the charcters read as a string."
  (let loop ((out "")
             (char (peek-char-safe port)))
    (if (member char (string->list str))
        (begin
          (read-char port)
          (loop (string-append out (string char))
                (peek-char-safe port)))
        ;; else
        out)))

(define* (read-whitespace #:optional (port (current-input-port)))
  "Reads and returns any awating whitespace characters from port.
If whitespace is found, returns it as a string.  If no whitespace is
found, returns an empty string.  If the port is at EOF, returns EOF."
  (let loop ((output ""))
    (let ((c (peek-char port)))
      (if (eof-object? c)
          ;; We've reached the end
          (if (string=? output "")
              ;; We didn't find any whitespace, so return EOF
              c
              ;; Otherwise, we can return what we fond
              output)
          ;; There is a character to be read.
          (if (char-set-contains? char-set:whitespace c)
              ;; Found whitespace, keep going!.
              (loop (string-append output (string (read-char port))))
              ;; else, the next char is not whitespace, so we're done.
              output)))))

(define* (read-line-terminator #:optional (port (current-input-port)))
  "Reads and returns any awating line terminator characters from port.
The line terminators searched for are CR, LF, CRLF, NEL, LS and PS.
If a line terminator is found, returns it as a string.  If no
terminator is found, returns an empty string.  If the port is at EOF,
returns EOF."
  (let ((c (peek-char port)))
    (cond
     ((eof-object? c)
      ;; No chars available, so return EOF.
      c)

     ;; Search for the CRLF pattern.
     ((and (char=? c #\return)
           (char=? (peek-2nd-char-safe port) #\newline))
      (string (read-char port) (read-char port)))

     ;; Otherwise, search for one of the single character line terminators.
     ((member c (list #\return
                      #\newline
                      #\205
                      #\vtab
                      #\20050
                      #\20051))
      (string (read-char port)))

     ;; No line terminator found.
     (else
      ""))))

(define* (read-integer #:optional (port (current-input-port)) (base 0))
  "Read a string representation of an integer from PORT, assuming
BASE. BASE is either 0, or 2 to 36, with a default value of 0.

If BASE is 0, the number will assumed to be base-16 if it starts with
0x or 0X, base 8 if it starts with 0, or base 10 otherwise.

Will return the integer, or 0 if no integer was found, or EOF"
  (let ((ws (read-whitespace port)))
    (if (eof-object? ws)
        ;; Port is EOF; quit now
        ws

        (let ((neg #f)
              (txt (string)))
          ;; Look for a Guile style initializer of #x, #o #d or
          ;; #b, maybe followed by plus or minus.
          ;; FIXME
          ;;(if (char=? (peek-char-safe port) #\#)
          ;;    'fixme)
          ;; Otherwise,
          ;; Look for a C style initializer of plus or minus maybe
          ;; followed by 0x for hex.
          (if (char=? (peek-char-safe port) #\-)
              (begin
                (set! neg #t)
                (set! txt (string-append txt (string (read-char port)))))
              (if (char=? (peek-char-safe port) #\+)
                  (set! txt (string-append txt (string (read-char port))))))

          (if (and (= base 0)
                   (char=? (peek-char-safe port) #\0)
                   (char-ci=? (peek-2nd-char-safe port) #\x))
              (begin
                (set! txt (string-append txt (string (read-char port) (read-char port))))
                (set! base 16)))
          (if (and (= 0 base)
                   (char=? (peek-char-safe port) #\0))
              (set! base 8))
          (if (= base 0)
              (set! base 10))

          ;; If there isn't at least one good digit, we push
          ;; back the introducer string and quit.
          (let ((c (peek-char-safe port)))
            (let ((val (cond
                        ((and (char>=? c #\0) (char<=? c #\9))
                         (- (char->integer c) (char->integer #\0)))
                        ((and (char>=? c #\A)  (char<=? c #\Z))
                         (+ 10 (- (char->integer c) (char->integer #\A))))
                        ((and (char>=? c #\a)  (char<=? c #\z))
                         (+ 10 (- (char->integer c) (char->integer #\a))))
                        (else
                         #f))))
              (if (not val)
                  (begin
                    (unread-string txt port)
                    0)

                  ;; Otherwise, we loop, gathering digits.
                  (let loop ((c c)
                             (acc 0))
                    (let ((val (cond
                                ((and (char>=? c #\0) (char<=? c #\9))
                                 (- (char->integer c) (char->integer #\0)))
                                ((and (char>=? c #\A)  (char<=? c #\Z))
                                 (+ 10 (- (char->integer c) (char->integer #\A))))
                                ((and (char>=? c #\a)  (char<=? c #\z))
                                 (+ 10 (- (char->integer c) (char->integer #\a))))
                                (else
                                 #f))))
                      (if (or (not val) (>= val base))
                          ;; return
                          (if neg (- acc) acc)
                          ;; else continue
                          (begin
                            (set! txt (string-append txt (string (read-char port))))
                            (loop (peek-char-safe port)
                                  (+ (* acc base) val)))))))))))))

(define *read-regex-string-err* "")

(define (get-read-regex-string-err)
  "If the last call to read-regex-string returned #f, this will give a
text that describes the reason for the failure."
  *read-regex-string-err*)

(define* (read-regex-string #:optional (port (current-input-port)))
  "Extracts the text of a delimited regular expression.  The 1st
character (which should usually be '/') will be the delimiter.  It
searches forward for the matching delimiter, handling shell escapes.
The text of the delimited regular expression is returned.

Return #f if no delimited regular expression was found, or #<eof> if
the port is EOF.

If #f is returned, calling get-read-regex-string-err will return the
reason why no regex string was found."
  (set! *read-regex-string-err* "")
  (let ((delimiter (read-char port)))

    (cond
     ((eof-object? delimiter)
      (set! *read-regex-string-err* "eof")
      delimiter)

     ((eof-object? (peek-char port))
      ;; Only 1 char available.  Not a regex.
      (set! *read-regex-string-err* "only one char available")
      (unread-char delimiter)
      #f)

     ((char=? (peek-char port) delimiter)
      ;; Two delimiters in a row.  An empty regex.
      (read-char port)
      (string delimiter delimiter))

     (else
      (read-regex-pattern-string port delimiter)))))

(define (read-regex-pattern-string port delimiter)
  "Extracts a regex pattern string terminated by delimiter, handling
escapes and looking for errors.  Returns the pattern string, or #f if
no valid pattern string was found."
  (let loop ((c (peek-char port))
             (txt (string delimiter)))
    (cond
     ((char=? c #\[)
      (let ((cclass (read-char-set-string port)))
        (if (not cclass)
            (begin
              (unread-string txt port)
              #f)
            (loop (peek-char-safe port)
                  (string-append txt cclass)))))

     ((char=? c #\\)
      (if (char=? #\null (peek-2nd-char-safe port))
          (begin
            (set! *read-regex-string-err* "trailing backslash")
            (unread-string txt port)
            #f)
          ;; Else this is a character escape.
          (begin
            (read-char port)
            (let ((c2 (read-char port)))
              (loop (peek-char-safe port)
                    (string-append txt (string c c2)))))))

     ((char=? c #\null)
      ;; Never found matching delimiter
      (set! *read-regex-string-err*
            (format #f "no matching '~a' delimiter found" delimiter))
      (unread-string txt port)
      #f)

     ((char=? c delimiter)
      ;; Success
      (read-char port)
      (string-append txt (string c)))

     (else
      ;; Keep looking.
      (read-char port)
      (loop (peek-char-safe port)
            (string-append txt (string c)))))))

(define (read-char-set-string port)
  "Reads a POSIX regex character set string from PORT, returning
the string, or #f, if not valid character class string was found."
  (let ((opener (read-char port))
        (txt ""))
    (set! txt (string-append txt (string opener)))
    (let ((c (peek-char-safe port)))

      ;; '^' and ']' at the beginning of character classes need to
      ;; be treated differently.
      (when (char=? c #\^)
        (read-char port)
        (set! txt (string-append txt (string c)))
        (set! c (peek-char-safe port)))

      (when (char=? c #\])
        (read-char port)
        (set! txt (string-append txt (string c)))
        (set! c (peek-char-safe port)))

      ;; Now we just look for the closing bracket, but, if we find
      ;; another opening bracket for a predefined character class of
      ;; the form [:alpha:], we have to handle those nested
      ;; brackets, too.
      (let loop ((c c))
        (let ((d (peek-2nd-char-safe port)))
          (cond
           ((and (char=? c #\[)
                 (member d (string->list ".:=")))
            (begin
              (read-char port)
              (read-char port)
              (set! txt (string-append txt (string c d)))
              (let loop2 ((d2 (peek-char-safe port))
                          (c2 (peek-2nd-char-safe port)))
                (cond
                 ((or (char=? d2 #\null)
                      (char=? c2 #\null))
                  (set! *read-regex-string-err*
                        (format #f "premature termination of character class '~a'" txt))
                  (unread-string txt port)
                  #f)

                 ((and (not (char=? d2 d)) (char=? c2 #\]))
                  (set! *read-regex-string-err*
                        (format #f "mismatched character class delimiters ~a != ~a"
                                d d2))
                  (unread-string txt port)
                  #f)

                 ((and (char=? d2 d) (char=? c2 #\]))
                  ;; OK: matching predefined character class delimiters
                  (read-char port)
                  (read-char port)
                  (set! txt (string-append txt (string d2 c2)))
                  txt)

                 (else
                  ;; Keep looping
                  (set! txt (string-append txt (string (read-char port))))
                  (loop2 (peek-char-safe port) (peek-2nd-char-safe port)))))))

           ((char=? c #\null)
            (set! *read-regex-string-err* "premature termination or character set")
            (unread-string txt port)
            #f)

           ((char=? c #\])
            ;; Successful completion.
            (read-char port)
            (set! txt (string-append txt (string c)))
            txt)

           (else
            (read-char port)
            (set! txt (string-append txt (string c)))
            (loop (peek-char-safe port)))))))))

(define *read-replacement-string-err* "")

(define (get-read-replacement-string-err)
  "If the last call to read-replacement-string returned #f, this will
give a text that describes the reason for the failure."
  *read-replacement-string-err*)

(define* (read-replacement-string #:optional (Port (current-input-port))
                                  (Delimiter #\/))
  "Extracts the text of a delimited replacement expression,
as might appear in the 'ed' or 'sed' command 's/RE/replacement/flags'.
It is expected the the next character available on Port will be the
first character in the replacment string, and that it will be
terminated either by the Delimiter or by <eof>. It searches forward
for the delimiter, handling ed or sed replacement string escapes. The
text of the replacement expression is returned, including the
delimiter at the end of the string, if present.

Return #f if no valid replacment expression was found, or #<eof> if
the port is EOF.

If #f is returned, calling get-read-replacement-string-err will return
the reason why no replacement string was found."
  (set! *read-replacement-string-err* "")
  (let ((C (peek-char Port)))

    (cond
     ((eof-object? C)
      (set! *read-replacement-string-err* "eof")
      C)

     ((char=? C Delimiter)
      ;; An empty replacement string
      (read-char Port)
      (string Delimiter))

     ((and (char=? C #\%)
           (char=? (peek-2nd-char-safe Port) Delimiter))
      ;; We've receive a percent sign by itself, which has
      ;; the special meaning of using the previous replacement string.
      (read-char Port)
      (read-char Port)
      (string #\% Delimiter))

     (else
      (read-replacement-pattern-string Port Delimiter)))))

(define (read-replacement-pattern-string Port Delimiter)
  "Extracts a replacement pattern string terminated by delimiter, handling
escapes and looking for errors.  Returns the pattern string, or #f if
no valid pattern string was found."
  (let loop ((c (peek-char-safe Port))
             (txt ""))
    (cond
     ((char=? c #\\)
      (if (char=? #\null (peek-2nd-char-safe Port))
          (begin
            (set! *read-replacement-string-err* "trailing backslash")
            (unread-string txt Port)
            #f)
          ;; Else this is a character escape.
          (begin
            (read-char Port)
            (let ((c2 (read-char Port)))
              (loop (peek-char-safe Port)
                    (string-append txt (string c c2)))))))

     ((char=? c #\null)
      ;; EOF occurred before a delimiter was found, so we're done.
      txt)

     ((char=? c Delimiter)
      ;; A delimeter was found, so we're done.
      (read-char Port)
      (string-append txt (string c)))

     (else
      ;; We haven't hit a delimiter or EOF, so keep looking.
      (read-char Port)
      (loop (peek-char-safe Port)
            (string-append txt (string c)))))))
