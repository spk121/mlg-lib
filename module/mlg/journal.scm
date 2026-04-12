(define-module (mlg journal)
  #:export (send-alist-to-journal
            send-alist-to-syslog))

(load-extension "libmlg" "init_journal_lib")

  
