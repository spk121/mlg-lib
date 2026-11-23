;;; -*- mode: scheme; coding: utf-8; indent-tabs-mode: nil; -*-
;;; (mlg journal) - send log entries to the systemd journal or syslog
;;;
;;; This is a pure Scheme replacement for the C functions that were in
;;; src/journal.c.  Rather than linking to libsystemd and calling
;;; syslog(3), it writes directly to the Unix-domain sockets that
;;; journald and the syslog daemon listen on.

(define-module (mlg journal)
  #:use-module (rnrs bytevectors)
  #:use-module (srfi srfi-1)
  #:use-module (system foreign)
  #:export (send-alist-to-journal
            send-alist-to-syslog
            journal-socket-path
            syslog-socket-path))

(define journal-socket-path
  ;; The socket for journald's native protocol.
  (make-parameter "/run/systemd/journal/socket"))

(define syslog-socket-path
  ;; The socket that syslog(3) writes to.
  (make-parameter "/dev/log"))

;; Log level bits, mirroring the constants defined in (mlg logging).
;; These must be kept in sync with that module.
(define MLG_LOG_LEVEL_ERROR    (ash 1 2))
(define MLG_LOG_LEVEL_CRITICAL (ash 1 3))
(define MLG_LOG_LEVEL_WARNING  (ash 1 4))
(define MLG_LOG_LEVEL_MESSAGE  (ash 1 5))
(define MLG_LOG_LEVEL_INFO     (ash 1 6))

;; Syslog priorities and facilities, from <syslog.h>
(define LOG_ERR 3)
(define LOG_WARNING 4)
(define LOG_NOTICE 5)
(define LOG_INFO 6)
(define LOG_DEBUG 7)
(define LOG_USER (ash 1 3))

(define (send-datagram path bv)
  "Send the bytevector BV as a single datagram to the Unix-domain socket
at PATH.  Return #t on success, or #f if it could not be sent."
  (let ((sock (false-if-exception (socket AF_UNIX SOCK_DGRAM 0))))
    (and sock
         (let ((ok (false-if-exception
                    (begin
                      (sendto sock bv AF_UNIX path)
                      #t))))
           (close-port sock)
           (and ok #t)))))

;; The name used when no SYSLOG_IDENTIFIER is given.  Like syslog(3)
;; and sd_journal_sendv(3), use glibc's program_invocation_short_name
;; (usually "guile"), and fall back to the name of the script.
(define (default-identifier)
  (or (false-if-exception
       (let ((name (pointer->string
                    (dereference-pointer
                     (dynamic-pointer "program_invocation_short_name"
                                      (dynamic-link))))))
         (and (not (string-null? name)) name)))
      (let ((args (program-arguments)))
        (if (and (pair? args) (string? (car args))
                 (not (string-null? (car args))))
            (basename (car args))
            "guile"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; systemd journal

(define (safe-char c)
  "Convert the character C to an ASCII uppercase letter, digit, or
underscore, for use in a journal field name."
  (let ((n (char->integer c)))
    (cond
     ((char=? c #\_) #\_)
     ((char<=? #\0 c #\9) c)
     ((char<=? #\A c #\Z) c)
     ((char<=? #\a c #\z) (char-upcase c))
     ((= n #xAA) #\A)
     ((= n #xB2) #\2)
     ((= n #xB3) #\3)
     ((= n #xB9) #\1)
     ((or (<= #xC0 n #xC6) (<= #xE0 n #xE6)) #\A)
     ((or (= n #xC7) (= n #xE7)) #\C)
     ((or (<= #xC8 n #xCB) (<= #xE8 n #xEB)) #\E)
     ((or (<= #xCC n #xCF) (<= #xEC n #xEF)) #\I)
     ((or (= n #xD1) (= n #xF1)) #\N)
     ((or (<= #xD2 n #xD6) (= n #xD8) (<= #xF2 n #xF6) (= n #xF8)) #\O)
     ((or (<= #xD9 n #xDC) (<= #xF9 n #xFC)) #\U)
     ((= n #xDF) #\S)
     ((or (= n #xFD) (= n #xFF)) #\Y)
     (else #\_))))

(define (variable-name-string str)
  "Convert STR into a name that is safe for use as a systemd journal
field name: only ASCII uppercase letters, digits, and underscores, and
not starting with an underscore.  Return #f if STR is empty."
  (if (string-null? str)
      #f
      (let ((name (string-map safe-char str)))
        (if (char=? (string-ref name 0) #\_)
            (string-append "X" name)
            name))))

(define (journal-field key value)
  "Encode one field in journald's native protocol.  KEY is a string and
VALUE is a non-empty bytevector."
  (let ((k (string->utf8 key))
        (len (bytevector-length value)))
    (if (not (memv 10 (bytevector->u8-list value)))
        ;; KEY=VALUE\n
        (u8-list->bytevector
         (append (bytevector->u8-list k) '(61)
                 (bytevector->u8-list value) '(10)))
        ;; A value containing newlines is sent as
        ;; KEY\n, a 64-bit little-endian length, VALUE, \n
        (let ((size (make-bytevector 8)))
          (bytevector-u64-set! size 0 len (endianness little))
          (u8-list->bytevector
           (append (bytevector->u8-list k) '(10)
                   (bytevector->u8-list size)
                   (bytevector->u8-list value) '(10)))))))

(define (alist-entry->journal-field entry)
  "Convert an alist entry into a pair of a field name and an encoded
journal field, or return #f if the entry should be ignored."
  (and (pair? entry)
       (let ((key (if (symbol? (car entry))
                      (symbol->string (car entry))
                      (car entry)))
             (val (cdr entry)))
         (and (string? key)
              (or (string? val) (bytevector? val))
              (let ((name (variable-name-string key))
                    (bv (if (string? val) (string->utf8 val) val)))
                (and name
                     (> (bytevector-length bv) 0)
                     (cons name (journal-field name bv))))))))

(define (send-alist-to-journal alist)
  "Given an alist of key/value pairs, this procedure reformats the data
to be accepted by the systemd journal and sends it to the systemd
journal.  The keys must be either strings or symbols, and are converted
to valid journal field names.  The values must be either strings or
bytevectors.  Entries with keys or values of the wrong type, or empty
values, are ignored.

It will return the number of entries actually logged, which is zero if
the journal could not be reached."
  (if (or (not (list? alist)) (null? alist))
      0
      (let* ((fields (filter-map alist-entry->journal-field alist))
             ;; Like sd_journal_sendv, add an identifier if there isn't one.
             (extra (if (assoc "SYSLOG_IDENTIFIER" fields)
                        '()
                        (list (journal-field
                               "SYSLOG_IDENTIFIER"
                               (string->utf8 (default-identifier)))))))
        (if (and (not (null? fields))
                 (send-datagram (journal-socket-path)
                                (u8-list->bytevector
                                 (append-map bytevector->u8-list
                                             (append (map cdr fields) extra)))))
            (length fields)
            0))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; syslog

(define (log-level->priority log-level)
  (cond
   ((logtest log-level MLG_LOG_LEVEL_ERROR) LOG_ERR)
   ((logtest log-level MLG_LOG_LEVEL_CRITICAL) LOG_WARNING)
   ((logtest log-level MLG_LOG_LEVEL_WARNING) LOG_WARNING)
   ((logtest log-level MLG_LOG_LEVEL_MESSAGE) LOG_NOTICE)
   ((logtest log-level MLG_LOG_LEVEL_INFO) LOG_INFO)
   (else LOG_DEBUG)))

(define (string->facility str)
  "Parse a facility code like C's atoi, and shift it into position."
  (let* ((s (string-trim str))
         (m (string-index s (lambda (c) (not (or (char-numeric? c)
                                                 (memv c '(#\- #\+)))))))
         (n (string->number (substring s 0 (or m (string-length s))))))
    (ash (if (exact-integer? n) n 0) 3)))


(define (send-alist-to-syslog log-level alist)
  "Send a log message to the system syslog daemon.

LOG-LEVEL is the integer log level (mlg LOG_LEVEL_* bits).  ALIST is a
string-keyed alist; the following fields are recognised:
  MESSAGE            - the text to log (required)
  SYSLOG_IDENTIFIER  - the program name shown in the log
  SYSLOG_FACILITY    - facility code (integer string, e.g. \"1\" for LOG_USER)

Returns #t if the message was sent, or #f if there is no MESSAGE field
or the syslog daemon could not be reached."
  (and (list? alist)
       (not (null? alist))
       (let ((message (assoc-ref alist "MESSAGE"))
             (ident (assoc-ref alist "SYSLOG_IDENTIFIER"))
             (facility (assoc-ref alist "SYSLOG_FACILITY")))
         (and (string? message)
              (let* ((pri (logior (if (string? facility)
                                      (string->facility facility)
                                      LOG_USER)
                                  (log-level->priority log-level)))
                     ;; The same format as glibc's syslog(3) with LOG_PID.
                     (stamp (strftime "%b %e %T" (localtime (current-time))))
                     (line (format #f "<~a>~a ~a[~a]: ~a"
                                   pri stamp
                                   (if (string? ident) ident (default-identifier))
                                   (getpid) message)))
                (send-datagram (syslog-socket-path) (string->utf8 line)))))))
