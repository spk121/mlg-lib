(define-module (mlg assert)
  #:use-module (ice-9 format)
  #:export (assert
            assert-type))

(define-syntax __FILE__
   (syntax-rules ()
     ((_)
      (or (assv-ref (current-source-location) 'filename)
	  "(unknown file)"))))

(define-syntax __LINE__
   (syntax-rules ()
     ((_)
      (or (assv-ref (current-source-location) 'line)
	  "(unknown line)"))))

(define-syntax assert
  (lambda (x)
    (syntax-case x ()
      ((_ expression)
       #'(let ((ret expression))
	   (unless ret
	     (error
	      (format #f "~a:~a: assertion failed: ~a = ~s"
		      (__FILE__) (__LINE__) 'expression expression))))))))

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
