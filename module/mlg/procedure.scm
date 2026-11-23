(define-module (mlg procedure)
  #:use-module (mlg logging)
  #:export (
	    ???
	    !!!))

(define (??? . args)
  "This is a stub procedure that prints a warning when called."
  (log-critical "Warning: stub procedure called with args ~s" args)
  *unspecified*)

(define (!!! . args)
  "This is a stub procedure that exits when called."
  (format (current-error-port) "Fatal Error: stub procedure called with args ~s~%" args)
  (primitive-exit 1))
