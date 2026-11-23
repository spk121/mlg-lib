(use-modules (srfi srfi-64)
             (rnrs bytevectors)
             (ice-9 regex)
             (mlg journal))

(test-begin "t-mlg-journal")

;; The journal and syslog writers send datagrams to Unix-domain
;; sockets.  Point them at a temporary socket and check what arrives.
;; The expected bytes were checked against libsystemd's
;; sd_journal_sendv and glibc's syslog(3).

(define sock-path
  (string-append (or (getenv "TMPDIR") "/tmp")
                 "/t-mlg-journal-" (number->string (getpid))))

(define (call-with-test-socket proc)
  (let ((srv (socket AF_UNIX SOCK_DGRAM 0)))
    (when (file-exists? sock-path) (delete-file sock-path))
    (bind srv AF_UNIX sock-path)
    (let ((result
           (parameterize ((journal-socket-path sock-path)
                          (syslog-socket-path sock-path))
             (proc (lambda ()
                     (let* ((buf (make-bytevector 65536))
                            (n (car (recvfrom! srv buf)))
                            (out (make-bytevector n)))
                       (bytevector-copy! buf 0 out 0 n)
                       out))))))
      (close-port srv)
      (delete-file sock-path)
      result)))

(test-equal "send-alist-to-journal native protocol"
  '(2 "MESSAGE=hello\nPRIORITY=6\nSYSLOG_IDENTIFIER=me\n")
  (call-with-test-socket
   (lambda (recv)
     (let ((n (send-alist-to-journal '(("MESSAGE" . "hello")
                                       (priority . "6")
                                       ("SYSLOG_IDENTIFIER" . "me")))))
       (list (1- n) (utf8->string (recv)))))))

(test-equal "send-alist-to-journal sanitizes names and skips bad entries"
  "X_PRIVATE=u\nCODE_FILE=a.scm\nSYSLOG_IDENTIFIER=me\n"
  (call-with-test-socket
   (lambda (recv)
     (send-alist-to-journal '(("_private" . "u")
                              ("code-file" . "a.scm")
                              ("EMPTY" . "")
                              ("" . "nokey")
                              (5 . "badkey")
                              ("X" . 7)
                              notapair
                              ("SYSLOG_IDENTIFIER" . "me")))
     (utf8->string (recv)))))

(test-equal "send-alist-to-journal binary encoding for newlines"
  (u8-list->bytevector
   (append (bytevector->u8-list (string->utf8 "MESSAGE\n"))
           '(9 0 0 0 0 0 0 0)
           (bytevector->u8-list (string->utf8 "two\nlines\n"))
           (bytevector->u8-list (string->utf8 "SYSLOG_IDENTIFIER=me\n"))))
  (call-with-test-socket
   (lambda (recv)
     (send-alist-to-journal '(("MESSAGE" . "two\nlines")
                              ("SYSLOG_IDENTIFIER" . "me")))
     (recv))))

(test-equal "send-alist-to-journal empty alist" 0 (send-alist-to-journal '()))

(test-equal "send-alist-to-journal without a journal returns 0" 0
  (parameterize ((journal-socket-path "/nonexistent/socket"))
    (send-alist-to-journal '(("MESSAGE" . "m")))))

(test-assert "send-alist-to-syslog format"
  (call-with-test-socket
   (lambda (recv)
     (and (send-alist-to-syslog 4 '(("MESSAGE" . "disk is on fire")
                                    ("SYSLOG_IDENTIFIER" . "myprog")))
          (string-match
           (string-append "^<11>[A-Z][a-z][a-z] [ 0-9][0-9] [0-9:]{8} myprog\\["
                          (number->string (getpid))
                          "\\]: disk is on fire$")
           (utf8->string (recv)))))))

(test-assert "send-alist-to-syslog facility and info level"
  (call-with-test-socket
   (lambda (recv)
     (send-alist-to-syslog 64 '(("MESSAGE" . "m")
                                ("SYSLOG_IDENTIFIER" . "x")
                                ("SYSLOG_FACILITY" . "3")))
     (string-prefix? "<30>" (utf8->string (recv))))))

(test-equal "send-alist-to-syslog without MESSAGE" #f
  (send-alist-to-syslog 4 '(("X" . "y"))))

(test-equal "send-alist-to-syslog without a daemon" #f
  (parameterize ((syslog-socket-path "/nonexistent/socket"))
    (send-alist-to-syslog 4 '(("MESSAGE" . "m")))))

(test-end "t-mlg-journal")
