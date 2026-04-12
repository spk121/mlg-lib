(define-module (ryu printf)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 match)
  #:use-module (system foreign)
  #:use-module (srfi srfi-1)
  #:export (asprintf
	    fprintf
	    printf
	    ))

(define ERROR_ON_OVERFLOW #t)
(define ERROR_ON_MISMATCH #t)

;;; Let's make up some limits.  I'm using Linux x86_64 values.  This
;;; is all for the lulz, so the actual architecture doesn't really
;;; matter.
(define CHAR_MIN                   -128)
(define CHAR_MAX                    127)
(define WCHAR_MIN           -2147483648)
(define WCHAR_MAX            2147483647)
(define WINT_MAX             4294967295)
(define UCHAR_MAX                   255)
(define SHRT_MIN                 -32768)
(define SHRT_MAX                  32767)
(define USHRT_MAX                 65535)
(define INT_MIN             -2147483648)
(define INT_MAX              2147483647)
(define UINT_MAX             4294967295)
(define LONG_MIN   -9223372036854775808)
(define LONG_MAX    9223372036854775807)
(define ULONG_MAX  18446744073709551615)
(define LLONG_MIN  -9223372036854775808)
(define LLONG_MAX   9223372036854775807)
(define ULLONG_MAX 18446744073709551615)
(define INT8_MIN                   -128)
(define INT8_MAX                    127)
(define UINTPTR_MAX 18446744073709551615)
(define PTRDIFF_MIN -9223372036854775808)
(define PTRDIFF_MAX 9223372036854775807)



;; Yeah, a regular expression.
;; The sub-matches are
;; 1. Zero or more flags
;; 2. An optional field width
;; 3. An optional precision
;; 4. An optional length modifier
;; 5. A mandatory conversion specifier

;; N.B. This regex has some problem to be fixed up "in post".
;; Duplicate flags are harmless but strictly invalid.
(define *conversion-specification-match*
  (make-regexp
   "%([-+ #0]*)([0-9]*|\\*)(\\.\\*|\\.[0-9]+|)(hh|ll|[ljztL]|)([diouxXfFeEgGaAcspn%])"))

(define *flags-table*
  '((#\- . left-justified)
    (#\+ . signed)
    (#\space . space-signed)
    (#\# . alternative)
    (#\0 . zero-padded)))

(define (parse-flags str)
  (let* ((out '())
	 (add (lambda (x)
		(unless (member x out)
		  (set! out (append! out (list x)))))))
    (string-for-each
     (lambda (c)
       (add (assoc-ref *flags-table* c)))
     str)
    (when (and (member 'space-signed out)
	       (member 'signed out))
      (set! out (delete 'space-signed out)))
    (when (and (member 'left-justified out)
	       (member 'zero-padded out))
      (set! out (delete 'zero-padded out)))
    out))

(define *specifier-table*
  '((#\% . percent)
    (#\d . decimal-signed)
    (#\i . decimal-signed)
    (#\o . octal-unsigned)
    (#\u . decimal-unsigned)
    (#\x . lowercase-hexadecimal-unsigned)
    (#\X . uppercase-hexadecimal-unsigned)
    (#\f . lowercase-decimal-float)
    (#\F . uppercase-decimal-float)
    (#\e . lowercase-scientific-float)
    (#\E . uppercase-scientific-float)
    (#\g . lowercase-float)
    (#\G . uppercase-float)
    (#\a . lowercase-hexadecimal-float)
    (#\A . uppercase-hexadecimal-float)
    (#\c . character)
    (#\s . string)
    (#\p . pointer)
    (#\n . output-count)))

(define (parse-specifier str)
  (assoc-ref *specifier-table* (string-ref str 0) ))

(define *default-length-modifier*
  '((decimal-signed . INT)
    (octal-unsigned . UINT)
    (decimal-unsigned . UINT)
    (lowercase-hexadecimal-unsigned . UINT)
    (uppercase-hexadecimal-unsigned . UINT)
    (lowercase-decimal-float . DBL)
    (uppercase-decimal-float . DBL)
    (lowercase-scientific-float . DBL)
    (uppercase-scientific-float . DBL)
    (lowercase-float . DBL)
    (uppercase-float . DBL)
    (lowercase-hexadecimal-float . DBL)
    (uppercase-hexadecimal-float . DBL)
    (character . UCHAR)
    (string . STRING)
    (pointer . POINTER)
    (output-count . NULL)
    (percent . NULL)))

(define (default-length-modifier specifier)
  (assoc-ref *default-length-modifier* specifier))

(define (parse-length-modifier str specifier)
  (let ((default (default-length-modifier specifier)))
    (cond
     ((string-null? str)
      default)
     
     ((string=? str "hh")
      (cond
       ((eqv? specifier 'decimal-signed)
	'INT8)
       ((member specifier (list 'octal-unsigned
				'decimal-unsigned
				'lowercase-hexadecimal-unsigned
				'uppercase-hexadecimal-unsigned))
	'UINT8)
       (else
	default)))
     
     ((string=? str "h")
      (cond
       ((eqv? specifier 'decimal-signed)
	'SHRT)
       ((member specifier (list 'octal-unsigned
				'decimal-unsigned
				'lowercase-hexadecimal-unsigned
				'uppercase-hexadecimal-unsigned))
	'USHRT)
       (else
	default)))

     ((string=? str "l")
      (cond
       ((eqv? specifier 'decimal-signed)
	'LONG)
       ((member specifier (list 'octal-unsigned
				'decimal-unsigned
				'lowercase-hexadecimal-unsigned
				'uppercase-hexadecimal-unsigned))
	'ULONG)
       ((eqv? specifier 'character)
	'WCHAR)
       ((eqv? specifier 'string)
	'WSTRING)
       (else
	default)))
     
     ((string=? str "ll")
      (cond
       ((eqv? specifier 'decimal-signed)
	'LLONG)
       ((member specifier (list 'octal-unsigned
				'decimal-unsigned
				'lowercase-hexadecimal-unsigned
				'uppercase-hexadecimal-unsigned))
	'ULLONG)
       (else
	default)))
     
     ((string=? str "j")
      (cond
       ((eqv? specifier 'decimal-signed)
	'INTMAX)
       ((member specifier (list 'octal-unsigned
				'decimal-unsigned
				'lowercase-hexadecimal-unsigned
				'uppercase-hexadecimal-unsigned))
	'UINTMAX)
       (else
	default)))

     ((string=? str "z")
      (cond
       ((eqv? specifier 'decimal-signed)
	'SIZE)
       ((member specifier (list 'octal-unsigned
				'decimal-unsigned
				'lowercase-hexadecimal-unsigned
				'uppercase-hexadecimal-unsigned))
	'SIZE)
       (else
	default)))

     ((string=? str "t")
      (cond
       ((eqv? specifier 'decimal-signed)
	'PTRDIFF)
       ((member specifier (list 'octal-unsigned
				'decimal-unsigned
				'lowercase-hexadecimal-unsigned
				'uppercase-hexadecimal-unsigned))
	'PTRDIFF)
       (else
	default)))

     ((string=? str "L")
      (cond
       ((member specifier (list 'lowercase-hexadecimal-float
				'uppercase-hexadecimal-float
				'lowercase-decimal-float
				'uppercase-decimal-float
				'lowercase-scientific-float
				'uppercase-scientific-float
				'lowercase-float
				'uppercase-float))
	'LDBL)
       (else
	default)))

     (else
      default))))

(define (parse-field-width str)
  (cond
   ((string-null? str)
    0)
   ((string=? str "*")
    'star)
   (else
    (string->number str))))

(define *default-precision-table*
  '((decimal-signed . 1)
    (octal-unsigned . 1)
    (decimal-unsigned . 1)
    (lowercase-hexadecimal-unsigned . 1)
    (uppercase-hexadecimal-unsigned . 1)
    (lowercase-decimal-float . 6)
    (uppercase-decimal-float . 6)
    (lowercase-scientific-float . 6)
    (uppercase-scientific-float . 6)
    (lowercase-float . 6)
    (uppercase-float . 6)
    (lowercase-hexadecimal-float . 8)
    (uppercase-hexadecimal-float . 8)
    (character . 0)
    (string . 0)
    (pointer . 1)
    (output-count . 0)
    (percent . 0)))
  
(define (parse-precision str specifier)
  ;; (format #t "in parse-precision ~S ~S~%" str specifier)
  (cond
   ((string-null? str)
    (assoc-ref *default-precision-table* specifier))
   ((string=? str ".")
    0)
   ((string=? str ".*")
    'star)
   (else
    (string->number (substring str 1)))))

(define (format-string-parser str)
  "Finds the first string or conversion specification in STR.  Return a
list of conversion specification properties."
  (let ((match1 (regexp-exec *conversion-specification-match* str))
	(flags '())
	(field-width #f)
	(precision #f)
	(length-modifier #f)
	(specifier 'literal))
    (cond
     ((not (regexp-match? match1))
      ;; This is just a literal string
      (list str flags field-width precision length-modifier specifier))
     ((not (zero? (match:start match1 0)))
      ;; It does match, but there is some plain string before the conversion specifier.
      (list (substring str 0 (match:start match1 0))
	    flags field-width precision length-modifier specifier))
     (else
      ;; It does match and begins with the conversion specifier
      (let ((flags (parse-flags (match:substring match1 1)))
	    (field-width (parse-field-width (match:substring match1 2)))
	    (specifier (parse-specifier (match:substring match1 5))))
	(let ((length-modifier (parse-length-modifier (match:substring match1 4)
						      specifier))
	      (precision (parse-precision (match:substring match1 3) specifier)))

	  (list (match:substring match1 0)
		flags field-width precision length-modifier specifier)))))))

(define (format-argument-count field-width precision specifier)
  "Given the output of format-string-parser, this return the number of arguments
required."
  (cond
   ((eqv? specifier 'percent)
    0)
   ((eqv? specifier 'literal)
    0)
   (else
    (+ (if (eqv? field-width 'star) 1 0)
       (if (eqv? precision 'star) 1 0)
       1))))


(define (format-literal flags field-width precision length-modifier specifier val)
  ;; (format #f "format-literal ~S" val)
  val)

(define (format-percent flags field-width precision length-modifier specifier val)
  "%")

(define (format-decimal-signed flags field-width precision length-modifier specifier _val)
  "Prints VAL as a base-10, signed integer.
FLAGS is a list with zero or more of 'signed 'space-signed 'left-justified
 'zero-padded
FIELD_WIDTH is the minimum output string length.
PRECISION is the minimum number of digits displayed; leading
 zeros are added if necessary.
Cannot be both 'signed and 'space-signed. 'signed has precedence.
Cannot have a PRECISION > 0 and be 'zero-padded. PRECISION has precedence."
  (let ((val (coerce-int _val length-modifier)))
    (let* ((numstr (if (and (zero? val) (zero? precision))
		       ""
		       ;; else
		       (number->string (abs val))))
	   (signstr
	    (cond
	     ((< val 0) "-")
	     ((member 'signed flags) "+")
	     ((member 'space-signed flags) " ")
	     (else "")))
	   (num-len (string-length numstr))
	   (num-sign-len (+ num-len
			    (string-length signstr)))
	   (precision-pad-len (max 0 (- precision num-len)))
	   (field-pad-len (max 0 (- field-width (+ num-sign-len
						   precision-pad-len)))))
      (if (and (zero? val) (zero? precision))
	  ;; There is a special case when val and precision are both
	  ;; zero where no digits are printed.
	  (make-string field-width #\space)
	  ;; else, at least one digit is printed.
	  (string-append
	   ;; left pad
	   (if (and (member 'zero-padded flags)
		    (not (member 'left-justified flags))
		    (= precision 0))
	       ;; left pad is zeros
	       (make-string field-pad-len #\0)
	       ;; else
	       (if (not (member 'left-justified flags))
		   ;; left pad is spaces
		   (make-string field-pad-len #\space)
		   ;; else
		   ""))
	   ;; sign
	   signstr
	   ;; precision padding
	   (make-string precision-pad-len #\0)
	   ;; the value
	   numstr
	   ;; right padding
	   ( if (member 'left-justified flags)
		(make-string field-pad-len #\space)
		""))))))

(define (format-unsigned flags field-width precision length-modifier specifier _val)
  "Prints VAL as an unsigned integer.
FLAGS is a list with zero or more of 'left-justified 'alternate 'zero-padded
FIELD_WIDTH is the minimum output string length.
PRECISION is the minimum number of digits displayed; leading
 zeros are added if necessary.
SPECIFIER is one of 'octal 'unsigned 'lowercase-hex or 'uppercase-hex
Cannot have a PRECISION > 0 and be 'zero-padded. PRECISION has precedence.
When 'octal, 'alternate increases the precision, if necessary, to ensure
  a leading zero.
When 'lowercase-hex or 'uppercase-hex and VAL != 0, a '0x' or '0X' prefix is added."
  (let ((val (coerce-unsigned _val length-modifier)))
    (let* (
	   ;; First, the base number
	   (numstr1 (if (and (zero? val) (zero? precision))
			""
			;; else
			(number->string (abs val)
					(cond
					 ((eqv? specifier 'octal-unsigned) 8)
					 ((or (eqv? specifier 'lowercase-hexadecimal-unsigned)
					      (eqv? specifier 'uppercase-hexadecimal-unsigned))
					  16)
					 (else 10)))))
	   ;; Then, the precision
	   (numstr2
	    (string-append (make-string
			    (max 0 (- precision (string-length numstr1)))
			    #\0)
			   numstr1))
	   ;; Then, any alternate text
	   (numstr3
	    (string-append
	     (cond
	      ((and (eqv? specifier 'octal-unsigned)
		    (member 'alternate flags)
		    (not (zero? (string-length numstr2)))
		    (not (char=? #\0 (string-ref numstr2 0))))
	       "0")
	      ((and (or (eqv? specifier 'uppercase-hexadecimal-unsigned)
			(eqv? specifier 'lowercase-hexadecimal-unsigned))
		    (and (not (zero? val))
			 (member 'alternate flags)))
	       "0x")
	      (else
	       ""))
	     numstr2))
	   ;; The proper casing
	   (numstr
	    (if (eqv? specifier 'uppercase-hexadecimal-unsigned)
		(string-upcase numstr3)
		numstr3))
	   (num-len (string-length numstr))
	   (precision-pad-len (max 0 (- precision num-len)))
	   (field-pad-len (max 0 (- field-width (+ num-len
						   precision-pad-len)))))
      (if (and (zero? val) (zero? precision))
	  ;; There is a special case when val and precision are both
	  ;; zero where no digits are printed.
	  (make-string field-width #\space)
	  ;; else, at least one digit is printed.
	  (string-append
	   ;; left pad
	   (if (and (member 'zero-padded flags)
		    (not (member 'left-justified flags))
		    (= precision 0))
	       ;; left pad is zeros
	       (make-string field-pad-len #\0)
	       ;; else
	       (if (not (member 'left-justified flags))
		   ;; left pad is spaces
		   (make-string field-pad-len #\space)
		   ;; else
		   ""))
	   ;; precision padding
	   (make-string precision-pad-len #\0)
	   ;; the value
	   numstr
	   ;; right padding
	   ( if (member 'left-justified flags)
		(make-string field-pad-len #\space)
		""))))))

(define (format-pointer flags field-width precision length-modifier specifier _val)
  "POINTER")

(define (format-decimal-float flags field-width precision length-modifier specifier _val)
  "Prints VAL as a floating-point number in decimal notation.
FLAGS is a list with zero or more of 'left-justified 'alternate 'zero-padded
FIELD_WIDTH is the minimum output string length.
PRECISION is the number of digits after the decimal point.
SPECIFIER is one of 'lowercase or 'uppercase, which affects the casing
  of INF and NAN.
When 'alternate and PRECISION = 0, a terminal decimal point appears.
"
  (let ((val (coerce-float _val length-modifier)))
    (let* ((signstr
	    ;; The sign string
	    (cond
	     ((< val 0) "-")
	     ((member 'signed flags) "+")
	     ((member 'space-signed flags) " ")
	     (else "")))
	   ;; First pass at the stringifying the number
	   (numstr
	    (cond
	     ((not (finite? val))
	      "inf")
	     ((nan? val)
	      "nan")
	     (else
	      (let* ((shift (* (expt 10 precision)))
		     (x (inexact->exact (round (* shift (abs val)))))
		     (left (quotient x shift))
		     (right (remainder x shift)))
		(string-append
		 (number->string left)
		 (if (or (> precision 0) (member 'alternate flags))
		     "."
		     "")
		 (if (> precision 0)
		     (number->string right)
		     ""))))))
	   ;; Fixing the case of the number
	   (numcasestr (if (eqv? 'uppercase-decimal-float specifier)
			   (string-upcase numstr)
			   numstr))
	   (num-len (string-length numcasestr))
	   (num-sign-len (+ num-len
			    (string-length signstr)))
	   ;; Number of spaces left in the field
	   (field-pad-len (max 0 (- field-width num-sign-len))))

      ;; Three cases
      ;; 1. sign, field-pad-zeros, numcasestr
      ;; 2. field-pad-space, sign, numcasestr
      ;; 3. sign, numcasestr, field-pad-space
      (cond
       ;; Case 1
       ((and (member 'zero-padded flags)
	     (not (member 'left-justified flags)))
	(string-append
	 signstr
	 (make-string field-pad-len #\0)
	 numcasestr))
       ;; Case 2
       ((not (member 'left-justified flags))
	(string-append
	 (make-string field-pad-len #\space)
	 signstr
	 numcasestr))
       ;; Case 3
       (else
	(string-append
	 signstr
	 numcasestr
	 (make-string field-pad-len #\space)))))))

(define (format-scientific-float flags field-width precision length-modifier specifier _val)
  "Prints VAL as a floating-point number in scientific notation.
FLAGS is a list with zero or more of 'left-justified 'alternate 'zero-padded
FIELD_WIDTH is the minimum output string length.
PRECISION is the number of digits after the decimal point.
SPECIFIER is one of 'lowercase or 'uppercase, which affects the casing
  of INF and NAN.
When 'alternate and PRECISION = 0, a terminal decimal point appears.
"
  (let ((val (coerce-float _val length-modifier)))
    (let* ((signstr
	    ;; The sign string
	    (cond
	     ((< val 0) "-")
	     ((member 'signed flags) "+")
	     ((member 'space-signed flags) " ")
	     (else "")))
	   ;; First pass at the stringifying the number
	   (numstr
	    (cond
	     ((not (finite? val))
	      "inf")
	     ((nan? val)
	      "nan")
         ((zero? val)
          (string-append
           "0"
           (if (or (> precision 0) (member 'alternate flags))
			   "."
			   "")
           (if (> precision 0)
			   (make-string precision #\0)
			   "")
           "e+00"))		 
	     (else
	      ;; It should be X.YYYYYeZZ
	      ;; X is 1 to 9
	      ;; Y has PRECISION digits
	      ;; Z has 2 or more digits
	      
	      (let* (
		     ;; The number of digits in the integer part of VAL
		     (_magnitude (inexact->exact (1+ (floor (log10 (abs val))))))
		     ;; We only want PRECISION fractional digits, so
		     ;; we shift the decimal point LEFT by (magnitude - 1) digits to get
		     ;;   down to 1 digit
		     ;; and then shift the decimal point RIGHT by PRECISION digits
		     (shift (* (expt 10 (+ precision (- (- _magnitude 1))))))
		     (x (inexact->exact (round (* shift (abs val)))))
		     ;; OK. Now X is our rounded integer digits.
		     ;; Now we shift the decimal point LEFT by PRECISION
		     ;; digits
		     (left (quotient x (expt 10 precision)))
		     (right (remainder x (expt 10 precision)))
		     )
		(string-append
		 (number->string left)
		 (if (or (> precision 0) (member 'alternate flags))
		     "."
		     "")
		 (if (> precision 0)
		     (number->string right)
		     "")
		 "e"
		 ;; Our exponent is _magnitude - 1
		 (if (< (1- _magnitude) 0)
		     "-"
		     "")
		 (if (< (abs (1- _magnitude)) 10)
		     "0"
		     "")
		 (number->string (abs (1- _magnitude))))))))
	   ;; Fixing the case of the number
	   (numcasestr (if (eqv? 'uppercase-scientific-float specifier)
			   (string-upcase numstr)
			   numstr))
	   (num-len (string-length numcasestr))
	   (num-sign-len (+ num-len
			    (string-length signstr)))
	   ;; Number of spaces left in the field
	   (field-pad-len (max 0 (- field-width num-sign-len))))

      ;; Three cases
      ;; 1. sign, field-pad-zeros, numcasestr
      ;; 2. field-pad-space, sign, numcasestr
      ;; 3. sign, numcasestr, field-pad-space
      (cond
       ;; Case 1
       ((and (member 'zero-padded flags)
	     (not (member 'left-justified flags)))
	(string-append
	 signstr
	 (make-string field-pad-len #\0)
	 numcasestr))
       ;; Case 2
       ((not (member 'left-justified flags))
	(string-append
	 (make-string field-pad-len #\space)
	 signstr
	 numcasestr))
       ;; Case 3
       (else
	(string-append
	 signstr
	 numcasestr
	 (make-string field-pad-len #\space)))))))


(define (two-normalize x)
  "Given a positive value X.
If it is zero, return 0 . 0
Otherwise, multiply or divide it by powers 
of two until the product begins with 1.0.
Return (X / 2^N) and N."
  (if (zero? x)
      (cons 0 0)
      ;; else
      (let* ((n (inexact->exact (floor (/ (log x) (log 2)))))
	     (y (/ x (expt 2 n))))

	;; The following block checks for float roundoff errors.
	(while (or (< y 1.0) (>= y 2.0))
	  (cond
	   ((< y 1.0)
	    (set! n (1- n))
	    (set! y (* x (expt 2 n))))
	   ((>= y 2.0)
	    (set! n (1+ n))
	    (set! y (* x (expt 2 n))))))
	
	(cons y n))))

(define (format-hexadecimal-float flags field-width precision length-modifier specifier _val)
  "Prints VAL as a floating-point number in hex scientific notation.
FLAGS is a list with zero or more of 'left-justified 'alternate 'zero-padded
FIELD_WIDTH is the minimum output string length.
PRECISION is the number of digits after the decimal point.
SPECIFIER is one of 'lowercase or 'uppercase, which affects the casing
  of INF and NAN.
When 'alternate and PRECISION = 0, a terminal decimal point appears.
"
  (let ((val (coerce-float _val length-modifier)))
    (let* ((signstr
	    ;; The sign string
	    (cond
	     ((< val 0) "-")
	     ((member 'signed flags) "+")
	     ((member 'space-signed flags) " ")
	     (else "")))
	   ;; First pass at the stringifying the number
	   (numstr
	    (cond
	     ((not (finite? val))
	      "inf")
	     ((nan? val)
	      "nan")
         ((zero? val)
          (string-append
           "0x0"
           (if (or (> precision 0) (member 'alternate flags))
               "."
               "")
           (if (> precision 0)
               (make-string precision #\0)
               "")
           "p+0"))		 
	     (else
	      ;; It should be X.YYYYYpZZ
	      ;; X is 1 to 9
	      ;; Y has PRECISION digits
	      ;; Z has 2 or more digits
	      
	      (let* (
		     ;; First, we find a power of two that make the 1st digit
		     ;; 0.0 or 1.0.
		     (twonor (two-normalize (abs val)))
		     (val2 (car twonor))
		     (_magnitude2 (cdr twonor))
		     
		     (log16 (lambda (x) (/ (log x) (log 16))))
		     (log2 (lambda (x) (/ (log x) (log 2))))

		     ;; The number of digits in the integer part of VAL
		     (_magnitude16 (inexact->exact (1+ (floor (log16 (abs val2))))))
		     ;; We only want PRECISION fractional digits, so
		     ;; we shift the decimal point LEFT by (magnitude - 1) digits to get
		     ;;   down to 1 digit
		     ;; and then shift the decimal point RIGHT by PRECISION digits
		     (shift (* (expt 16 (+ precision (- (- _magnitude16 1))))))
		     (x (inexact->exact (round (* shift (abs val2)))))

		     ;; OK. Now X is our rounded integer digits.
		     ;; Now we shift the decimal point LEFT by PRECISION
		     ;; digits
		     (left (quotient x (expt 16 precision)))
		     (right (remainder x (expt 16 precision)))
		     )
		(string-append
		 "0x"
		 (number->string left 16)
		 (if (or (> precision 0) (member 'alternate flags))
		     "."
		     "")
		 (if (> precision 0)
		     (number->string right 16)
		     "")
		 "p"
		 ;; Our exponent is _magnitude - 1
		 (if (< (1- _magnitude2) 0)
		     "-"
		     "")
		 ;; Unlike standard scientific, hex scientific
		 ;; can have 1-digit exponents.
		 (number->string (abs _magnitude2)))))))
	   ;; Fixing the case of the number
	   (numcasestr (if (eqv? 'uppercase-hexadecimal-float specifier)
			   (string-upcase numstr)
			   numstr))
	   (num-len (string-length numcasestr))
	   (num-sign-len (+ num-len
			    (string-length signstr)))
	   ;; Number of spaces left in the field
	   (field-pad-len (max 0 (- field-width num-sign-len))))

      ;; Three cases
      ;; 1. sign, field-pad-zeros, numcasestr
      ;; 2. field-pad-space, sign, numcasestr
      ;; 3. sign, numcasestr, field-pad-space
      (cond
       ;; Case 1
       ((and (member 'zero-padded flags)
	     (not (member 'left-justified flags)))
	(string-append
	 signstr
	 (make-string field-pad-len #\0)
	 numcasestr))
       ;; Case 2
       ((not (member 'left-justified flags))
	(string-append
	 (make-string field-pad-len #\space)
	 signstr
	 numcasestr))
       ;; Case 3
       (else
	(string-append
	 signstr
	 numcasestr
	 (make-string field-pad-len #\space)))))))

(define (format-float flags field-width precision length-modifier specifier _val)
  "Chooses one of decimal float or scientific float, depending
on the precision."
  (let ((val (coerce-float _val length-modifier)))
    (if (or (not (finite? val)) (nan? val) (zero? val))
        ;; Delegate special values — sub-formatters already handle these
        (format-decimal-float flags field-width precision length-modifier
                              (if (eqv? specifier 'uppercase-float)
                                  'uppercase-decimal-float
                                  'lowercase-decimal-float)
                              val)
        ;; Normal path — safe to call log10 now
        (let ((_magnitude (inexact->exact (1+ (floor (log10 (abs val)))))))
          (cond
           ((and (> precision (1- _magnitude))
                 (>= (1- _magnitude) -4))
            (format-decimal-float flags field-width (- precision _magnitude) length-modifier
                                  (if (eqv? specifier 'uppercase-float)
                                      'uppercase-decimal-float
                                      'lowercase-decimal-float)
                                  val))
           (else
            (format-scientific-float flags field-width (1- precision) length-modifier
                                     (if (eqv? specifier 'uppercase-float)
                                         'uppercase-scientific-float
                                         'lowercase-scientific-float)
                                     val)))))))

(define (format-string flags field-width precision length-modifier specifier val)
  "Prints the string VAL
FLAGS is a list containing zero or more of 'left-justified
FIELD_WIDTH is the padding."
  (let* ((charstr val)
	 (char-len (string-length charstr))
	 (field-pad-len (max 0 (- field-width char-len))))
    (cond
     ((member 'left-justified flags)
      (string-append
       charstr
       (make-string field-pad-len #\space)))
     (else
      (string-append
       (make-string field-pad-len #\space)
       charstr)))))

(define (format-character flags field-width precision length-modifier specifier _val)
  "Prints the single character VAL
FLAGS is a list containing zero or more of 'left-justified
FIELD_WIDTH is the padding."
  (let ((val (coerce-char _val length-modifier)))
    (format-string flags field-width precision length-modifier specifier (string val))))

(define *dispatch-table*
  `((literal . ,format-literal)
    (percent . ,format-percent)
    (decimal-signed . ,format-decimal-signed)
    (octal-unsigned . ,format-unsigned)
    (decimal-unsigned . ,format-unsigned)
    (lowercase-hexadecimal-unsigned . ,format-unsigned)
    (uppercase-hexadecimal-unsigned . ,format-unsigned)
    (lowercase-decimal-float . ,format-decimal-float)
    (uppercase-decimal-float . ,format-decimal-float)
    (lowercase-scientific-float . ,format-scientific-float)
    (uppercase-scientific-float . ,format-scientific-float)
    (lowercase-hexadecimal-float . ,format-hexadecimal-float)
    (uppercase-hexadecimal-float . ,format-hexadecimal-float)
    (character . ,format-character)
    (string . ,format-string)
    (pointer . ,format-pointer)))

(define (format-string-dispatch str flags _field-width _precision length-modifier specifier . _vals)
  "Call the appropriate dispatch function for the current specifier."
  (let* ((val _vals)
	 (field-width _field-width)
	 (precision _precision))

    ;; The %% form doesn't use any arguments
    (unless (or (eqv? specifier 'literal)
		(eqv? specifier 'percent))
      ;; Other forms use one to three arguments
      (when (eqv? 'star field-width)
	(set! field-width (car val))
	(set! val (cdr val)))
      (when (eqv? 'star precision)
	(set! field-width (car val))
	(set! val (cdr val)))
      (set! val (car val)))
    (when (eqv? specifier 'literal)
      (set! val str))

    (let ((dispatcher (assoc-ref *dispatch-table* specifier)))
      ;; (format #t "Dispatching specifier ~s field-width ~s precision ~s val ~s to ~s~%"
	;;      specifier field-width precision val dispatcher)
      (when dispatcher
	(dispatcher flags field-width precision length-modifier specifier val)))))

(define (coerce-int _val type)
  (let ((val (cond
	      ((exact-integer? _val) _val)
	      ((and (not ERROR_ON_MISMATCH) (real? _val))
	       (inexact->exact (round _val)))
	      ((and (not ERROR_ON_MISMATCH) (char? _val))
	       (char->integer _val))
	      ((and (not ERROR_ON_MISMATCH) (pointer? _val))
	       (pointer-address _val))
	      (else
	       (scm-error 'wrong-type-arg "coerce-int" "cannot convert ~S to ~a for printf" (list _val type) (list _val))))))
    ;; If I really wanted to, I could range check things here.
    val))

(define (coerce-unsigned _val type)
  (let ((val (cond
	      ((and (exact-integer? _val) (>= _val 0) _val)
	       _val)
	      ((and (not ERROR_ON_MISMATCH) (real? _val) (>= _val 0.0))
	       (inexact->exact (round _val)))
	      ((and (not ERROR_ON_MISMATCH) (char? _val))
	       (char->integer _val))
	      ((and (not ERROR_ON_MISMATCH) (pointer? _val))
	       (pointer-address _val))
	      (else
	       (scm-error 'wrong-type-arg "coerce-int" "cannot convert ~S to ~a for printf" (list _val type) (list _val))))))
    ;; If I really wanted to, I could range check things here.
    val))

(define (coerce-char _val type)
  (let ((val (cond
	      ((char? _val)
	       _val)
	      ((and (not ERROR_ON_MISMATCH) (exact-integer? _val))
	       (integer->char _val))
	      (else
	       (scm-error 'wrong-type-arg "coerce-char" "cannot convert ~S to ~a for printf" (list _val type) (list _val))))))
    ;; I could range check things here.
    val))

(define (coerce-float _val type)
  (let ((val (cond
	      ((inexact? _val) _val)
	      ((and (not ERROR_ON_MISMATCH) (number? _val) (exact? _val))
	       (exact->inexact _val))
	      (else
	       (scm-error 'wrong-type-arg "coerce-float" "cannot convert ~S to ~a for printf" (list _val type) (list _val))))))
    ;; I could range check things here.
    val))

(define (asprintf _format-str . _args)
  "Given a format string and associated arguments, this returns
a formatted string."
  (let loop ((output (string-copy ""))
	     (format-str _format-str)
	     (args _args))
    (match (format-string-parser format-str)
      ((str flags field-width precision length-modifier specifier)
       (let ((argcount (format-argument-count field-width precision specifier)))
	 ;;(format #t "output ~S format-str ~S args ~S~%"
	;;	 output format-str args)
	 ;;(format #t "str ~S flags ~S field-width ~S precision ~S length-modifier ~S specifier ~S argcount ~S~%"
	;;	 str flags field-width precision length-modifier specifier argcount)
    (when (< (length args) argcount)
      (scm-error 'wrong-number-of-args "asprintf"
                 "not enough arguments for format string: need ~a more, have ~a, format ~S"
                 (list argcount (length args) _format-str)
                 #f))         
	  (let ((substr
		 (apply format-string-dispatch
		        (append
			 (list str flags field-width precision length-modifier specifier)
			 (take args argcount)))))
	   (if (not (string-null? format-str))
	       (loop (string-append output substr)
		     (string-drop format-str (string-length str))
		     (drop args argcount))
	       ;; else, we're done
	       (string-append output substr))))))))

(define (printf _format-str . _args)
  (display (apply asprintf (append (list _format-str) _args))))

(define (fprintf port _format-str . _args)
  (display (apply asprintf (append (list _format-str) _args)) port))
