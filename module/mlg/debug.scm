(define-module (mlg debug)
  #:use-module (system repl repl)
  #:use-module (system repl debug)
  #:export (breakpoint
	    disable-breakpoints
	    enable-breakpoints))

(define *enable-traps* #t)
(define *disable-list* '())

(define-syntax breakpoint
  (syntax-rules ()
    ((_)
     (when *enable-traps*
       (start-repl #:debug (make-debug (stack->vector (make-stack #t))
				       0 "trap!" #t))))
    ((_ name)
     (when *enable-traps*
       (unless (member name *disable-list*)
	 (start-repl #:debug (make-debug (stack->vector (make-stack #t))
					 0 "trap!" #t)))))))

(define-syntax disable-breakpoints
  (syntax-rules ()
    ((_)
     (set! *enable-traps* #f))
    ((_ name)
     (unless (member name *disable-list*)
       (set! *disable-list* (append! *disable-list* (list name)))))))

(define-syntax enable-breakpoints
  (syntax-rules ()
    ((_)
     (set! *enable-traps* #t))
    ((_ name)
     (set! *disable-list* (delete! name *disable-list*)))))
