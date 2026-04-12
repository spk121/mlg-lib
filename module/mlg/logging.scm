;;; -*- mode: scheme; coding: us-ascii; indent-tabs-mode: nil; -*-
;;; (mlg logging) - a GLib-like logger
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
(define-module (mlg logging)
  #:use-module (ice-9 format)
  #:use-module (ice-9 threads)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (system repl repl)
  #:use-module (system repl debug)
  #:use-module (system vm frame)
  #:use-module (rnrs bytevectors)
  #:use-module (rnrs io ports)
  #:use-module (mlg assert)
  #:use-module (mlg debug)
  #:use-module (mlg journal)
  #:use-module (mlg math)
  #:use-module (mlg port)
  #:use-module (mlg strings)
  #:use-module (mlg time)
  #:use-module (mlg utils)
  #:export(
           __FILE__
           __LINE__
           __FUNC__
           __LOCALS__

           set-log-domain
           get-log-domain
           log-set-default-writer
           log-enable-color
           log-enable-stream-output
           log-enable-journal-output

           log-structured
           log-structured-alist

           log-error
           log-critical
           log-warning
           log-message
           log-info
           log-debug

           warn-if-false
           warn-val-if-false
           warn-if-used
           warn-if-reached

           log-debug-locals
           log-debug-pk
           log-debug-time
           %dump-log-globals
           ))

(cond-expand (guile-2.2
              )
             (else
              (define (frame-procedure-name F)
                (procedure-name (frame-procedure F)))))

(define-syntax __FILE__
  (syntax-rules ()
    ((_)
     (if (assv-ref (current-source-location) 'filename)
         (basename (assv-ref (current-source-location) 'filename))
         ;; else
         "(unknown file)"))))

(define-syntax __LINE__
  (syntax-rules ()
    ((_)
     (or (assv-ref (current-source-location) 'line)
         -1))))

(define-syntax __FUNC__
  (syntax-rules ()
    ((_)
     (let ((stk (stack->vector (make-stack #t))))
       (let loop ((i 1))
         (cond
          ((and (vector-ref stk i)
                (frame-procedure-name (vector-ref stk i)))
           (let ((pname (frame-procedure-name (vector-ref stk i))))
             (cond
              ((eqv? pname '%start-stack)
               "(top level)")
              ((eqv? pname 'save-module-excursion)
               "(top level)")
              (else
               (symbol->string pname)))))
          ((< i (vector-length stk))
           (loop (1+ i)))
          (else
           "(unknown func)")))))))

(define-syntax STRLOC
  (syntax-rules ()
    ((_)
     (let ((loc (assv-ref (current-source-location) 'line)))
       (if loc
           (number->string loc)
           "(unknown line)")))))

(define-syntax __LOCALS__
  (syntax-rules ()
    ((_)
     (let ((stk (stack->vector (make-stack #t)))
           (out "...\n"))
       (let loop ((i 1))
         (let* ((frame (vector-ref stk i))
                (name (frame-procedure-name frame)))
           (set! out
             (string-append out
                            (with-output-to-string
                              (lambda ()
                                (print-locals frame
                                              #:width 160
                                              #:per-line-prefix "**   ")))))
           (if (and (not name) (< i (vector-length stk)))
               (loop (1+ i))
               ;; else
               out)))))))
#|
(define-syntax (__BACKTRACE__)
(syntax-rules ()
((_)
(let ((stk (stack->vector (make-stack #t)))
(out "...\n"))
(let loop ((i 1))
(let* ((frame (vector-ref stk i))
(name (frame-procedure-name frame)))
(set! out
(string-append out
(with-output-to-string
(lambda ()
(print-locals frame
#:width 160
#:per-line-prefix "**   ")))))
(if (and (not name) (< i (vector-length stk)))
(loop (1+ i))
;; else
out)))))))
|#

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; From glib-init.c

(define *log-msg-prefix* #f)
(define *log-always-fatal* #f)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; gmessages.h (55): GLogLevelFlags

;; Internal flags
(define LOG_FLAG_RECURSION (ash 1 0))
(define LOG_FLAG_FATAL     (ash 1 1))
;; Log level for errors and assertion failures
(define LOG_LEVEL_ERROR    (ash 1 2))
;; Log level for serious warnings
(define LOG_LEVEL_CRITICAL (ash 1 3))
(define LOG_LEVEL_WARNING  (ash 1 4))
(define LOG_LEVEL_MESSAGE  (ash 1 5))
;; For informational messages
(define LOG_LEVEL_INFO     (ash 1 6))
(define LOG_LEVEL_DEBUG    (ash 1 7))
;; Mask for all log levels but no internal flags
(define LOG_LEVEL_MASK     (lognot-uint16 (logior LOG_FLAG_RECURSION
                                                  LOG_FLAG_FATAL)))

;; Mask for log levels that are considered fatal by default
(define LOG_FATAL_MASK    (logior LOG_FLAG_RECURSION LOG_LEVEL_ERROR))

;; 1139: ALERT_LEVELS
(define ALERT_LEVELS      (logior LOG_LEVEL_ERROR
                                  LOG_LEVEL_CRITICAL
                                  LOG_LEVEL_WARNING))

;; 1142: DEFAULT_LEVELS
;; These are emitted by the default log handler.
(define DEFAULT_LEVELS    (logior LOG_LEVEL_ERROR
                                  LOG_LEVEL_CRITICAL
                                  LOG_LEVEL_WARNING
                                  LOG_LEVEL_MESSAGE))
(define LOG_DOMAIN #f)

(define (set-log-domain str)
  (if (string? str)
      (set! LOG_DOMAIN str)
      (set! LOG_DOMAIN #f)))

(define (get-log-domain)
  LOG_DOMAIN)

;; gmessage.h: 246: G_DEBUG_HERE
(define-syntax log-debug-locals
  (syntax-rules ()
    ((_ ...)
     (log-structured LOG_DOMAIN LOG_LEVEL_DEBUG
                     "CODE_FILE" (__FILE__)
                     "CODE_LINE" (STRLOC)
                     "CODE_FUNC" (__FUNC__)
                     "MESSAGE" (string->format-escaped-string (__LOCALS__))))))

(define-syntax log-debug-time
  (syntax-rules ()
    ((_)
     (log-structured LOG_DOMAIN LOG_LEVEL_DEBUG
                     "CODE_FILE" (__FILE__)
                     "CODE_LINE" (STRLOC)
                     "CODE_FUNC" (__FUNC__)
                     "MESSAGE" "Time is ~6,5f"
                     (* 1e-6 (- (monotonic-time) *log-start-time*))))))

;; gmessages.h: 285: g_error
(define-syntax log-error
  (syntax-rules ()
    ((_ msg ...)
     (log-structured LOG_DOMAIN LOG_LEVEL_ERROR
                     "CODE_FILE" (__FILE__)
                     "CODE_LINE" (STRLOC)
                     "CODE_FUNC" (__FUNC__)
                     "MESSAGE" msg ...))))

;; gmessage.h: 293: g_message
(define-syntax log-message
  (syntax-rules ()
    ((_ msg ...)
     (log-structured LOG_DOMAIN LOG_LEVEL_MESSAGE
                     "CODE_FILE" (__FILE__)
                     "CODE_LINE" (STRLOC)
                     "CODE_FUNC" (__FUNC__)
                     "MESSAGE" msg ...))))

;; gmessage.h: 298: g_critical
(define-syntax log-critical
  (syntax-rules ()
    ((_ msg ...)
     (log-structured LOG_DOMAIN LOG_LEVEL_CRITICAL
                     "CODE_FILE" (__FILE__)
                     "CODE_LINE" (STRLOC)
                     "CODE_FUNC" (__FUNC__)
                     "MESSAGE" msg ...))))

;; gmessage.h: 303: g_warning
(define-syntax log-warning
  (syntax-rules ()
    ((_ msg ...)
     (log-structured LOG_DOMAIN LOG_LEVEL_WARNING
                     "CODE_FILE" (__FILE__)
                     "CODE_LINE" (STRLOC)
                     "CODE_FUNC" (__FUNC__)
                     "MESSAGE" msg ...))))

;; gmessage.h: 308: g_info
(define-syntax log-info
  (syntax-rules ()
    ((_ msg ...)
     (log-structured LOG_DOMAIN LOG_LEVEL_INFO
                     "CODE_FILE" (__FILE__)
                     "CODE_LINE" (STRLOC)
                     "CODE_FUNC" (__FUNC__)
                     "MESSAGE" msg ...))))

;; gmessage.h: 313: g_debug
(define-syntax log-debug
  (syntax-rules ()
    ((_ msg ...)
     (log-structured LOG_DOMAIN LOG_LEVEL_DEBUG
                     "CODE_FILE" (__FILE__)
                     "CODE_LINE" (STRLOC)
                     "CODE_FUNC" (__FUNC__)
                     "MESSAGE" msg ...))))

;; gmessage.h: 491: g_warn_if_reached

(define-syntax warn-if-reached
  (syntax-rules ()
    ((_)
     (log-structured LOG_DOMAIN LOG_LEVEL_CRITICAL
                     "CODE_FILE" (__FILE__)
                     "CODE_LINE" (STRLOC)
                     "CODE_FUNC" (__FUNC__)
                     "MESSAGE" "code should not be reached"))))

(define-syntax warn-if-used
  (syntax-rules ()
    ((_ val)
     (begin
       (log-structured LOG_DOMAIN LOG_LEVEL_CRITICAL
                       "CODE_FILE" (__FILE__)
                       "CODE_LINE" (STRLOC)
                       "CODE_FUNC" (__FUNC__)
                       "MESSAGE" "value '~a' should not be used"
                       val)
       val))))

(define-syntax warn-if-false
  (syntax-rules ()
    ((_ expr)
     (let ((ret expr))
       (or ret
           (begin
             (log-structured LOG_DOMAIN LOG_LEVEL_CRITICAL
                             "CODE_FILE" (__FILE__)
                             "CODE_LINE" (STRLOC)
                             "CODE_FUNC" (__FUNC__)
                             "MESSAGE" "'~a' is false"
                             (quote expr))
             #f))))))

(define-syntax warn-val-if-false
  (syntax-rules ()
    ((_ expr val)
     (let ((ret expr))
       (or ret
           (begin
             (log-structured LOG_DOMAIN LOG_LEVEL_CRITICAL
                             "CODE_FILE" (__FILE__)
                             "CODE_LINE" (STRLOC)
                             "CODE_FUNC" (__FUNC__)
                             "MESSAGE" "'~a' is false. '~a'='~a'"
                             (quote expr) (quote val) val)
             #f))))))


;; gmessages.h: 576: g_return_if_fail

;; gmessage.h: 585: g_return_val_if_fail

;; gmessage.h: 594: g_return_if_reached

;; gmessage.h: 603: g_return_val_if_reached

(define-syntax log-debug-pk
  (syntax-rules ()
    ((_ expr)
     (let ((ret expr))
       (log-structured LOG_DOMAIN LOG_LEVEL_DEBUG
                       "CODE_FILE" (__FILE__)
                       "CODE_LINE" (STRLOC)
                       "CODE_FUNC" (__FUNC__)
                       "MESSAGE" "'~s' is '~s'"
                       (quote expr) ret)
       ret))))



;; gmessages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; 505: variables
(define *messages-lock* (make-mutex))
(define *log-structured-depth*  (make-fluid 0))
(define *log-writer-func* #f)
(define *log-enable-color* #t)
(define *log-start-time* #f)
(define *log-stream-enabled* #t)
(define *log-journal-enabled* #t)

(define (%dump-log-globals)
  (format #t "log-structured-depth: ~a~%" (fluid-ref *log-structured-depth*))
  (format #t "log-writer-func: ~a~%" *log-writer-func*)
  (format #t "log-stream-enabled: ~a~%" *log-stream-enabled*)
  (format #t "log-journal-enabled: ~a~%" *log-journal-enabled*))

;; 523: aka _g_log_abort
(define (%log-abort breakpoint?)
  (assert-type boolean breakpoint?)
  (if breakpoint?
      (breakpoint 'log-abort)
      (exit 1)))

(define (log-set-default-writer writer_func)
  "Set the function to be used for logging.  WRITER_FUNC is a procedure
that takes two parameters: a log-level integer, and an alist of key/value
pairs.

As a special case, if WRITER_FUNC is the symbol 'standard, the default
standard streams writer will be used.  If WRITER_FUNC is 'journal,
the systemd journal writer will be used."
  (lock-mutex *messages-lock*)
  (cond
   ((eqv? writer_func 'standard)
    (set! *log-writer-func* log-writer-standard-streams))
   ((eqv? writer_func 'journal)
    (set! *log-writer-func* log-writer-journal))
   ((procedure? writer_func)
    (set! *log-writer-func* writer_func))
   (else
    (set! *log-writer-func* log-writer-standard-streams)))
  (unlock-mutex *messages-lock*))

(define (log-enable-color flag)
  "Given FLAG, which is #t or #f, this enables or disable colorization
when logging to the standard streams."
  (lock-mutex *messages-lock*)
  (set! *log-enable-color* flag)
  (unlock-mutex *messages-lock*))

;; 1151: mklevel_prefix
(define (mklevel-prefix log-level use-color?)
  (string-append
   (log-level->color log-level use-color?)
   (cond
    ((eqv? (logand log-level LOG_LEVEL_MASK) LOG_LEVEL_ERROR)
     "ERROR")
    ((eqv? (logand log-level LOG_LEVEL_MASK) LOG_LEVEL_CRITICAL)
     "CRITICAL")
    ((eqv? (logand log-level LOG_LEVEL_MASK) LOG_LEVEL_WARNING)
     "WARNING")
    ((eqv? (logand log-level LOG_LEVEL_MASK) LOG_LEVEL_MESSAGE)
     "Message")
    ((eqv? (logand log-level LOG_LEVEL_MASK) LOG_LEVEL_INFO)
     "INFO")
    ((eqv? (logand log-level LOG_LEVEL_MASK) LOG_LEVEL_DEBUG)
     "DEBUG")
    (else
     (if (not (zero? log-level))
         (format #f "LOG-~a" (logand log-level LOG_LEVEL_MASK))
         "LOG")))
   (color-reset use-color?)
   (if (logtest log-level LOG_FLAG_RECURSION)
       " (recursed)"
       "")
   (if (logtest log-level ALERT_LEVELS)
       " **"
       "")))

;; 1150: extracted fro mmklevel_prefix
(define (log-level->port log-level)
  (if (logtest log-level
               (logior LOG_LEVEL_ERROR
                       LOG_LEVEL_WARNING
                       LOG_LEVEL_CRITICAL
                       LOG_LEVEL_MESSAGE))
      (current-error-port)
      (current-output-port)))

;; 1406: log_level_to_priority
(define (log-level->priority log-level)
  "A one-byte name for a log level."
  (cond
   ((logtest log-level LOG_LEVEL_ERROR)    "3")
   ((logtest log-level LOG_LEVEL_CRITICAL) "4")
   ((logtest log-level LOG_LEVEL_WARNING)  "4")
   ((logtest log-level LOG_LEVEL_MESSAGE)  "5")
   ((logtest log-level LOG_LEVEL_INFO)     "6")
   ((logtest log-level LOG_LEVEL_DEBUG)    "7")))

;; 1436: log_level_to_color
(define (log-level->color log-level use-color?)
  (cond
   ((not (and use-color? *log-enable-color*))
    "")
   ((logtest log-level LOG_LEVEL_ERROR)
    "\x1b[1;31m")
   ((logtest log-level LOG_LEVEL_CRITICAL)
    "\x1b[1;35m")
   ((logtest log-level LOG_LEVEL_WARNING)
    "\x1b[1;33m")
   ((logtest log-level LOG_LEVEL_MESSAGE)
    "\x1b[1;32m")
   ((logtest log-level LOG_LEVEL_INFO)
    "\x1b[0;32m")
   ((logtest log-level LOG_LEVEL_DEBUG)
    "\x1b[0;37m")
   (else
    "")))

;; 1461: color_reset
(define (color-reset use-color?)
  (if (and use-color? *log-enable-color*)
      "\x1b[0m"
      ""))

;; 1665: g_log_structured
(define (%add-fields-from-list-to-alist _output rest)
  (let loop ((key #f)
             (cur (car rest))
             (rest (cdr rest))
             (output _output))
    (cond
     ((not key)
      (if (null? rest)
          (begin
            ;; We have a leftover key with no value.
            output)
          ;; Else, this element must be a key.
          (loop cur (car rest) (cdr rest) output)))
     ((not (string=? key "MESSAGE"))
      (if (null? rest)
          (begin
            ;; We have a key with no value.
            output)
          ;; Else, this element must be the value of a key/value pair.
          (begin
            (set! output (assoc-set! output key cur))
            (loop #f (car rest) (cdr rest) output))))
     (else
      ;; We have a "MESSAGE" key, so the remaining params are a format
      ;; specifier and its parameters.
      ;;(pk 'key key 'cur cur 'rest rest)
      (set! output (assoc-set! output key
                               (apply format (append (list #f)
                                                     (list cur)
                                                     rest))))
      output))))

(define (log-structured log-domain log-level . rest)
  "Log a message to structured data.  The message will be passed
through the log writer set by the application using
log-set-writer-func.  If the message is fatal, the program will be
aborted.

For each key to log, the procedure takes two parameters: a key
string and a value string.

There must always be a MESSAGE key, which must be the last entry in
the list.  For that key, the variables that follow the MESSAGE key
will be merged into a single string using (format #f param1 param2 ...)"
  (let ((fields-alist (acons "PRIORITY" (log-level->priority log-level) '())))
    (when log-domain
      (set! fields-alist (acons "DOMAIN" log-domain fields-alist)))
    (set! fields-alist (%add-fields-from-list-to-alist fields-alist rest))
    (log-structured-alist log-level fields-alist)))

(define (log-structured-alist log-level fields-alist)
  (unless (null? fields-alist)
    (let* ((depth (fluid-ref *log-structured-depth*))
           (recursion (> depth 0))
           (writer-func #f))
      (lock-mutex *messages-lock*)
      (set! writer-func (if recursion
                            %log-writer-fallback
                            *log-writer-func*))
      (unlock-mutex *messages-lock*)

      (fluid-set! *log-structured-depth* (1+ depth))
      (when (procedure? writer-func)
        (writer-func log-level fields-alist))
      (fluid-set! *log-structured-depth* depth)

      (when (logtest log-level LOG_FATAL_MASK)
        (%log-abort (not (logand log-level LOG_FLAG_RECURSION)))))))

;; 2168: g_log_writer_format_fields
(define (log-writer-format-fields log-level fields-alist use-color?)
  ;; Extract some common fields.
  (let ((message (assoc-ref fields-alist "MESSAGE"))
        (log-domain (assoc-ref fields-alist "DOMAIN"))
        (level-prefix (mklevel-prefix log-level use-color?))
        (gstring ""))
    (when (logtest log-level ALERT_LEVELS)
      (set! gstring (string-append gstring "\n")))
    (when (not log-domain)
      (set! gstring (string-append gstring "** ")))

    ;; Print the (progname:pid) prefix only when this log level is present
    ;; in *log-msg-prefix*.  The double (zero? ...) / eqv? idiom is
    ;; equivalent to testing membership: both sides are zero iff the level
    ;; is NOT in the mask, both are non-zero iff it IS.
    (when (eqv? (zero? (logand *log-msg-prefix*
                               (logand log-level LOG_LEVEL_MASK)))
                (zero? (logand log-level LOG_LEVEL_MASK)))
      (let ((prg-name (get-prgname))
            (pid (getpid)))
        (if (string-null? prg-name)
            (set! gstring (string-append gstring (format #f "(process:~a): " pid)))
            (set! gstring (string-append gstring (format #f "(~a:~a): " prg-name pid))))))

    (when log-domain
      (set! gstring (string-append gstring log-domain "-")))
    (set! gstring (string-append gstring level-prefix))

    (set! gstring (string-append gstring ": "))
    (let ((codefile (assoc-ref fields-alist "CODE_FILE"))
          (codeline (assoc-ref fields-alist "CODE_LINE"))
          (codefunc (assoc-ref fields-alist "CODE_FUNC")))
      (when codefile
        (set! gstring (string-append gstring codefile ":")))
      (when codeline
        (set! gstring (string-append gstring codeline ":")))
      (when codefunc
        (set! gstring (string-append gstring codefunc ":")))
      (when (or codefile codeline codefunc)
        (set! gstring (string-append gstring " "))))

    (if (not message)
        (set! gstring (string-append gstring "(NULL) message"))
        ;; else
        (set! gstring (string-append gstring message)))
    gstring))

;; journal writer: sends the structured fields directly to systemd journal
(define (log-writer-journal log-level fields-alist)
  (send-alist-to-journal fields-alist))

;; 2473: g_log_writer_standard_streams
(define (log-writer-standard-streams log-level fields-alist)
  (let ((port (log-level->port log-level)))
    (display (log-writer-format-fields log-level fields-alist
                                       (port-has-color? port))
             port)
    (newline port)
    (force-output port)
    #t))

;; 2542: g_log_writer_default
(define (log-writer-default log-level fields-alist)
  (unless (null? fields-alist)

    ;; If the log-level is not in the DEFAULT_LEVELS, it is only
    ;; logged if there is a DOMAIN key in the fields which matches a
    ;; string in the MESSAGES_DEBUG environment variable.
    (let ((domains (or (getenv "MESSAGES_DEBUG") ""))
          (domain-field (assoc-ref fields-alist "DOMAIN")))
      (when (or (logtest log-level DEFAULT_LEVELS)
                (string-contains domains "all")
                (and (string? domain-field)
                     (string-contains domains domain-field)))
        ;; Now send the alist to the journald and/or the stdout/stderr
        (when *log-stream-enabled*
          (log-writer-standard-streams log-level fields-alist))
        (when *log-journal-enabled*
          (false-if-exception (send-alist-to-journal fields-alist)))
        (when (or (logtest log-level LOG_FATAL_MASK)
                  (logtest log-level *log-always-fatal*))
          (%log-abort (not (logand (logior log-level LOG_FLAG_FATAL) LOG_FLAG_RECURSION))))
        #t))))

;; 2619: _g_log_writer_fallback
(define (%log-writer-fallback log-level fields-alist)
  "The most basic log message logging function.  It logs known keys to
the current error or output port."
  (let ((port (log-level->port log-level)))
    (for-each
     (lambda (entry)
       (let ((key (car entry))
             (val (cdr entry)))
         (if (member key '("MESSAGE"
                           "MESSAGE_ID"
                           "PRIORITY"
                           "CODE_FILE"
                           "CODE_LINE"
                           "CODE_FUNC"
                           "ERRNO"
                           "SYSLOG_FACILITY"
                           "SYSLOG_IDENTIFIER"
                           "SYSLOG_PID"
                           "GLIB_DOMAIN"))
             (format port "~a=~s~%" key val))))
     fields-alist)
    (format port "_PID=~s~%" (getpid))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (log-enable-stream-output flag)
  (when (eqv? flag #t)
    (set! *log-stream-enabled* #t))
  (when (eqv? flag #f)
    (set! *log-stream-enabled* #f)))

(define (log-enable-journal-output flag)
  (when (eqv? flag #t)
    (set! *log-journal-enabled* #t))
  (when (eqv? flag #f)
    (set! *log-journal-enabled* #f)))

(define (logging-reset)
  (set! *log-writer-func* log-writer-default)
  (set! *log-msg-prefix* (logior
                          LOG_LEVEL_ERROR
                          LOG_LEVEL_WARNING
                          LOG_LEVEL_CRITICAL
                          LOG_LEVEL_DEBUG))
  (set! *log-journal-enabled* #t)
  (set! *log-stream-enabled* #t)
  (set! *log-always-fatal* LOG_FATAL_MASK)
  (set! *log-start-time* (monotonic-time)))

(logging-reset)
