(define-module (mlg assert)
  #:use-module (ice-9 format)
  #:export (assert
            assert-type))

(eval-when (expand load eval)
  (define (source-file x)
    (let ((src (syntax-source x)))
      (or (and src (assq-ref src 'filename)) "(unknown file)")))
  (define (source-line x)
    ;; Guile counts lines from zero; error messages count from one.
    (let* ((src (syntax-source x))
           (line (and src (assq-ref src 'line))))
      (if line (1+ line) "(unknown line)"))))

(define-syntax assert
  (lambda (x)
    (syntax-case x ()
      ((_ expression)
       (with-syntax ((file (datum->syntax x (source-file x)))
                     (line (datum->syntax x (source-line x))))
         ;; EXPRESSION is evaluated only once.
         #'(unless expression
             (error
              (format #f "~a:~a: assertion failed: ~s"
                      file line 'expression))))))))

(define-syntax assert-type
  (lambda (x)
    (syntax-case x ()
      [(_ type var)
       #`(if (not (#,(datum->syntax #'var
				    (string->symbol (string-append 
						     (symbol->string (syntax->datum #`type)) 
						     "?")))
                   var))
             (scm-error 'wrong-type-arg
			#f
			(string-append "not type '" 
				       #,(symbol->string (syntax->datum #`type))
				       "': ~s")
			(list var)
			(list var)))])))
