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
(define DBL_MIN_EXP               -1022) ; exponent of the smallest normal double



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
   "%([-+ #0]*)([0-9]*|\\*)(\\.\\*|\\.[0-9]*|)(hh|ll|[hljztL]|)([diouxXfFeEgGaAcspn%])"))

(define *flags-table*
  '((#\- . left-justified)
    (#\+ . signed)
    (#\space . space-signed)
    (#\# . alternate)
    (#\0 . zero-padded)))

(define (parse-flags str)
  (let* ((out '())
	 (add (lambda (x)
		(unless (memq x out)
		  (set! out (append! out (list x)))))))
    (string-for-each
     (lambda (c)
       (add (assoc-ref *flags-table* c)))
     str)
    (when (and (memq 'space-signed out)
	       (memq 'signed out))
      (set! out (delete 'space-signed out)))
    (when (and (memq 'left-justified out)
	       (memq 'zero-padded out))
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
  (assoc-ref *specifier-table* (string-ref str 0)))

(define *unsigned-specifiers*
  '(octal-unsigned
    decimal-unsigned
    lowercase-hexadecimal-unsigned
    uppercase-hexadecimal-unsigned))

(define *float-specifiers*
  '(lowercase-decimal-float
    uppercase-decimal-float
    lowercase-scientific-float
    uppercase-scientific-float
    lowercase-float
    uppercase-float
    lowercase-hexadecimal-float
    uppercase-hexadecimal-float))

(define (uppercase-specifier? specifier)
  (memq specifier '(uppercase-hexadecimal-unsigned
		    uppercase-decimal-float
		    uppercase-scientific-float
		    uppercase-float
		    uppercase-hexadecimal-float)))

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

;; For each length modifier string, the type used for signed and for
;; unsigned integer conversions.
(define *integer-length-modifiers*
  '(("hh" INT8    . UINT8)
    ("h"  SHRT    . USHRT)
    ("l"  LONG    . ULONG)
    ("ll" LLONG   . ULLONG)
    ("j"  INTMAX  . UINTMAX)
    ("z"  SIZE    . SIZE)
    ("t"  PTRDIFF . PTRDIFF)))

(define (parse-length-modifier str specifier)
  (let ((default (default-length-modifier specifier))
	(int-entry (assoc-ref *integer-length-modifiers* str)))
    (cond
     ((and int-entry (eqv? specifier 'decimal-signed))
      (car int-entry))
     ((and int-entry (memq specifier *unsigned-specifiers*))
      (cdr int-entry))
     ((and (string=? str "l") (eqv? specifier 'character))
      'WCHAR)
     ((and (string=? str "l") (eqv? specifier 'string))
      'WSTRING)
     ((and (string=? str "L") (memq specifier *float-specifiers*))
      'LDBL)
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

(define (parse-precision str specifier)
  "Return #f when no precision was given, 'star for '.*', or the
precision as an integer.  A lone '.' means a precision of zero."
  (cond
   ((string-null? str)
    #f)
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
      (let* ((flags (parse-flags (match:substring match1 1)))
	     (field-width (parse-field-width (match:substring match1 2)))
	     (specifier (parse-specifier (match:substring match1 5)))
	     (length-modifier (parse-length-modifier (match:substring match1 4)
						     specifier))
	     (precision (parse-precision (match:substring match1 3) specifier)))
	(list (match:substring match1 0)
	      flags field-width precision length-modifier specifier))))))

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

;;; Helpers

(define (pad-field flags field-width prefix body zero-pad-ok?)
  "Pad PREFIX + BODY to FIELD-WIDTH.  PREFIX is the sign and/or radix
prefix.  When zero-padding, the zeros go between PREFIX and BODY."
  (let ((n (max 0 (- field-width (string-length prefix) (string-length body)))))
    (cond
     ((memq 'left-justified flags)
      (string-append prefix body (make-string n #\space)))
     ((and zero-pad-ok? (memq 'zero-padded flags))
      (string-append prefix (make-string n #\0) body))
     (else
      (string-append (make-string n #\space) prefix body)))))

(define (pad-left-zeros str len)
  (if (< (string-length str) len)
      (string-append (make-string (- len (string-length str)) #\0) str)
      str))

(define (negative-float? x)
  (or (< x 0) (eqv? x -0.0)))

(define (float-sign-string val flags)
  (cond
   ((negative-float? val) "-")
   ((memq 'signed flags) "+")
   ((memq 'space-signed flags) " ")
   (else "")))

(define (strip-trailing-zeros str)
  "Given a string of the form DIGITS.DIGITS, remove trailing zeros in the
fractional part, and the decimal point if nothing remains after it."
  (if (not (string-index str #\.))
      str
      (let* ((s (string-trim-right str #\0)))
	(if (string-suffix? "." s)
	    (substring s 0 (1- (string-length s)))
	    s))))

;; All float formatting is done on the exact rational value of the
;; float, so rounding is correct (round-half-even on the true binary
;; value, as glibc does).

(define (fixed-notation q precision alternate?)
  "Format the non-negative exact rational Q with PRECISION fractional
digits."
  (let* ((n (round (* q (expt 10 precision))))
	 (s (pad-left-zeros (number->string n) (1+ precision)))
	 (k (- (string-length s) precision)))
    (string-append (substring s 0 k)
		   (if (or (> precision 0) alternate?) "." "")
		   (substring s k))))

(define (decimal-exponent q)
  "For a positive exact rational Q, return the integer E such that
10^E <= Q < 10^(E+1)."
  (let loop ((e (inexact->exact (floor (log10 (exact->inexact q))))))
    (cond
     ((< q (expt 10 e)) (loop (1- e)))
     ((>= q (expt 10 (1+ e))) (loop (1+ e)))
     (else e))))

(define (scientific-digits q precision)
  "For a non-negative exact rational Q, return two values: a string of
PRECISION + 1 significant digits, rounded, and the decimal exponent."
  (if (zero? q)
      (values (make-string (1+ precision) #\0) 0)
      (let* ((e (decimal-exponent q))
	     (n (round (* q (expt 10 (- precision e))))))
	(if (>= n (expt 10 (1+ precision)))
	    ;; Rounding carried into a new digit, e.g. 9.99 -> 10.0
	    (values (number->string (round (* q (expt 10 (- precision (1+ e))))))
		    (1+ e))
	    (values (number->string n) e)))))

(define (exponent-string e min-digits)
  (string-append (if (< e 0) "-" "+")
		 (pad-left-zeros (number->string (abs e)) min-digits)))

(define (scientific-notation q precision alternate?)
  (call-with-values (lambda () (scientific-digits q precision))
    (lambda (digits e)
      (string-append (substring digits 0 1)
		     (if (or (> precision 0) alternate?) "." "")
		     (substring digits 1)
		     "e"
		     (exponent-string e 2)))))

(define (format-non-finite flags field-width specifier val)
  (let ((str (if (nan? val) "nan" "inf")))
    (pad-field flags field-width
	       (float-sign-string val flags)
	       (if (uppercase-specifier? specifier) (string-upcase str) str)
	       #f)))

(define (format-float-with proc flags field-width precision length-modifier specifier _val)
  "Common driver for floating-point conversions.  PROC receives the
absolute value of the number as an exact rational and returns the
digit string."
  (let ((val (coerce-float _val length-modifier)))
    (if (or (nan? val) (inf? val))
	(format-non-finite flags field-width specifier val)
	(let ((body (proc (inexact->exact (abs val)))))
	  (pad-field flags field-width
		     (float-sign-string val flags)
		     (if (uppercase-specifier? specifier) (string-upcase body) body)
		     #t)))))

;;; Formatters

(define (format-literal flags field-width precision length-modifier specifier val)
  val)

(define (format-percent flags field-width precision length-modifier specifier val)
  "%")

(define (format-integer flags field-width precision length-modifier specifier _val)
  "Prints VAL as an integer.
FLAGS is a list with zero or more of 'signed 'space-signed 'left-justified
 'alternate 'zero-padded
FIELD-WIDTH is the minimum output string length.
PRECISION is the minimum number of digits displayed, or #f.  When
 a precision is given, the 'zero-padded flag is ignored.
With 'alternate, octal output always begins with a zero, and non-zero
 hexadecimal output gets a 0x or 0X prefix."
  (let* ((signed? (eqv? specifier 'decimal-signed))
	 (val (if signed?
		  (coerce-int _val length-modifier)
		  (coerce-unsigned _val length-modifier)))
	 (prec (or precision 1))
	 (radix (case specifier
		  ((octal-unsigned) 8)
		  ((lowercase-hexadecimal-unsigned uppercase-hexadecimal-unsigned) 16)
		  (else 10)))
	 (hex? (= radix 16))
	 (digits1 (if (and (zero? val) (zero? prec))
		      ""
		      (pad-left-zeros (number->string (abs val) radix) prec)))
	 (digits (if (and (= radix 8)
			  (memq 'alternate flags)
			  (not (string-prefix? "0" digits1)))
		     (string-append "0" digits1)
		     digits1))
	 (prefix (cond
		  ((and signed? (< val 0)) "-")
		  ((and signed? (memq 'signed flags)) "+")
		  ((and signed? (memq 'space-signed flags)) " ")
		  ((and hex? (memq 'alternate flags) (not (zero? val))) "0x")
		  (else ""))))
    (if (eqv? specifier 'uppercase-hexadecimal-unsigned)
	(pad-field flags field-width (string-upcase prefix) (string-upcase digits)
		   (not precision))
	(pad-field flags field-width prefix digits (not precision)))))

(define (format-decimal-float flags field-width precision length-modifier specifier val)
  "Prints VAL as a floating-point number in decimal notation, [-]ddd.ddd.
PRECISION is the number of digits after the decimal point (default 6).
With 'alternate, the decimal point always appears."
  (format-float-with
   (lambda (q) (fixed-notation q (or precision 6) (memq 'alternate flags)))
   flags field-width precision length-modifier specifier val))

(define (format-scientific-float flags field-width precision length-modifier specifier val)
  "Prints VAL as a floating-point number in scientific notation, [-]d.ddde±dd.
PRECISION is the number of digits after the decimal point (default 6).
With 'alternate, the decimal point always appears."
  (format-float-with
   (lambda (q) (scientific-notation q (or precision 6) (memq 'alternate flags)))
   flags field-width precision length-modifier specifier val))

(define (format-float flags field-width precision length-modifier specifier val)
  "Prints VAL in decimal or scientific notation, depending on its
exponent.  PRECISION is the number of significant digits (default 6).
Trailing zeros are removed unless 'alternate is set."
  (let ((alternate? (memq 'alternate flags))
	(p (cond ((not precision) 6)
		 ((zero? precision) 1)
		 (else precision))))
    (format-float-with
     (lambda (q)
       (let* ((x (call-with-values (lambda () (scientific-digits q (1- p)))
		   (lambda (digits e) e)))
	      (str (if (and (> p x) (>= x -4))
		       (fixed-notation q (- p 1 x) alternate?)
		       (scientific-notation q (1- p) alternate?))))
	 (cond
	  (alternate? str)
	  ((string-index str #\e)
	   => (lambda (i)
		(string-append (strip-trailing-zeros (substring str 0 i))
			       (substring str i))))
	  (else (strip-trailing-zeros str)))))
     flags field-width precision length-modifier specifier val)))

(define (binary-exponent q)
  "For a positive exact rational Q, return the integer E such that
2^E <= Q < 2^(E+1)."
  (let loop ((e (- (integer-length (numerator q))
		   (integer-length (denominator q)))))
    (cond
     ((< q (expt 2 e)) (loop (1- e)))
     ((>= q (expt 2 (1+ e))) (loop (1+ e)))
     (else e))))

(define (hexadecimal-notation q precision alternate?)
  "Format the non-negative exact rational Q as 0xh.hhhp±d.  When
PRECISION is #f, use as many hex digits as needed to be exact.
Like glibc, subnormal doubles are printed as 0x0.hhhp-1022."
  (let* ((e (if (zero? q) 0 (max (binary-exponent q) DBL_MIN_EXP)))
	 (m (/ q (expt 2 e)))		; 1 <= m < 2, or 0 <= m < 1
	 (prec (or precision
		   (let loop ((p 0))
		     (if (integer? (* m (expt 16 p))) p (loop (1+ p))))))
	 (n (round (* m (expt 16 prec))))
	 (lead (quotient n (expt 16 prec)))
	 (frac (remainder n (expt 16 prec))))
    (string-append "0x"
		   (number->string lead 16)
		   (if (or (> prec 0) alternate?) "." "")
		   (if (> prec 0)
		       (pad-left-zeros (number->string frac 16) prec)
		       "")
		   "p"
		   (exponent-string e 1))))

(define (format-hexadecimal-float flags field-width precision length-modifier specifier _val)
  "Prints VAL as a floating-point number in hex scientific notation,
[-]0xh.hhhp±d.  PRECISION is the number of hex digits after the point;
by default, the value is printed exactly."
  (let ((val (coerce-float _val length-modifier)))
    (if (or (nan? val) (inf? val))
	(format-non-finite flags field-width specifier val)
	(let* ((str (hexadecimal-notation (inexact->exact (abs val))
					  precision (memq 'alternate flags)))
	       (str (if (uppercase-specifier? specifier) (string-upcase str) str)))
	  ;; Zero padding goes after the 0x prefix.
	  (pad-field flags field-width
		     (string-append (float-sign-string val flags) (substring str 0 2))
		     (substring str 2)
		     #t)))))

(define (format-string flags field-width precision length-modifier specifier _val)
  "Prints the string VAL
FLAGS is a list containing zero or more of 'left-justified
FIELD-WIDTH is the padding.
PRECISION, if given, is the maximum number of characters printed."
  (let* ((val (coerce-string _val length-modifier))
	 (str (if (and precision (< precision (string-length val)))
		  (substring val 0 precision)
		  val)))
    (pad-field flags field-width "" str #f)))

(define (format-character flags field-width precision length-modifier specifier _val)
  "Prints the single character VAL
FLAGS is a list containing zero or more of 'left-justified
FIELD-WIDTH is the padding."
  (let ((val (coerce-char _val length-modifier)))
    (pad-field flags field-width "" (string val) #f)))

(define (format-pointer flags field-width precision length-modifier specifier _val)
  "Prints the pointer VAL as a hexadecimal address, or (nil) for a null
pointer, as glibc does."
  (let ((addr (coerce-pointer _val length-modifier)))
    (pad-field flags field-width ""
	       (if (zero? addr)
		   "(nil)"
		   (string-append "0x" (number->string addr 16)))
	       #f)))

(define *dispatch-table*
  `((literal . ,format-literal)
    (percent . ,format-percent)
    (decimal-signed . ,format-integer)
    (octal-unsigned . ,format-integer)
    (decimal-unsigned . ,format-integer)
    (lowercase-hexadecimal-unsigned . ,format-integer)
    (uppercase-hexadecimal-unsigned . ,format-integer)
    (lowercase-decimal-float . ,format-decimal-float)
    (uppercase-decimal-float . ,format-decimal-float)
    (lowercase-scientific-float . ,format-scientific-float)
    (uppercase-scientific-float . ,format-scientific-float)
    (lowercase-float . ,format-float)
    (uppercase-float . ,format-float)
    (lowercase-hexadecimal-float . ,format-hexadecimal-float)
    (uppercase-hexadecimal-float . ,format-hexadecimal-float)
    (character . ,format-character)
    (string . ,format-string)
    (pointer . ,format-pointer)))

(define (format-string-dispatch str flags field-width precision length-modifier specifier . vals)
  "Call the appropriate dispatch function for the current specifier."
  (cond
   ((eqv? specifier 'literal)
    str)
   ((eqv? specifier 'percent)
    "%")
   (else
    ;; Other forms use one to three arguments
    (when (eqv? 'star field-width)
      (set! field-width (coerce-int (car vals) 'INT))
      (set! vals (cdr vals))
      ;; A negative field width is a '-' flag plus a positive width.
      (when (< field-width 0)
	(set! field-width (- field-width))
	(set! flags (cons 'left-justified (delete 'zero-padded flags)))))
    (when (eqv? 'star precision)
      (set! precision (coerce-int (car vals) 'INT))
      (set! vals (cdr vals))
      ;; A negative precision is taken as if it were omitted.
      (when (< precision 0)
	(set! precision #f)))
    ((assoc-ref *dispatch-table* specifier)
     flags field-width precision length-modifier specifier (car vals)))))

;;; Argument coercion

;; Ranges of the C integer types for each length modifier.
(define *signed-ranges*
  `((INT8    ,INT8_MIN    . ,INT8_MAX)
    (SHRT    ,SHRT_MIN    . ,SHRT_MAX)
    (INT     ,INT_MIN     . ,INT_MAX)
    (LONG    ,LONG_MIN    . ,LONG_MAX)
    (LLONG   ,LLONG_MIN   . ,LLONG_MAX)
    (INTMAX  ,LLONG_MIN   . ,LLONG_MAX)
    (SIZE    ,LONG_MIN    . ,LONG_MAX)
    (PTRDIFF ,PTRDIFF_MIN . ,PTRDIFF_MAX)))

(define *unsigned-ranges*
  `((UINT8   0 . ,UCHAR_MAX)
    (USHRT   0 . ,USHRT_MAX)
    (UINT    0 . ,UINT_MAX)
    (ULONG   0 . ,ULONG_MAX)
    (ULLONG  0 . ,ULLONG_MAX)
    (UINTMAX 0 . ,ULLONG_MAX)
    (SIZE    0 . ,ULONG_MAX)
    (PTRDIFF 0 . ,UINTPTR_MAX)))

(define (range-check val type ranges who)
  "Check that the integer VAL fits in TYPE.  If it doesn't, either
signal an error or wrap it as C would, depending on ERROR_ON_OVERFLOW."
  (let* ((range (assq-ref ranges type))
	 (lo (car range))
	 (hi (cdr range)))
    (cond
     ((<= lo val hi)
      val)
     (ERROR_ON_OVERFLOW
      (scm-error 'out-of-range who "value ~S is out of range for ~a in printf"
		 (list val type) (list val)))
     (else
      (+ lo (modulo (- val lo) (1+ (- hi lo))))))))

(define (mismatch-error who val type)
  (scm-error 'wrong-type-arg who "cannot convert ~S to ~a for printf"
	     (list val type) (list val)))

(define (coerce-exact-integer _val type who)
  (cond
   ((exact-integer? _val) _val)
   ((and (not ERROR_ON_MISMATCH) (real? _val) (finite? _val))
    (inexact->exact (round _val)))
   ((and (not ERROR_ON_MISMATCH) (char? _val))
    (char->integer _val))
   ((and (not ERROR_ON_MISMATCH) (pointer? _val))
    (pointer-address _val))
   (else
    (mismatch-error who _val type))))

(define (coerce-int _val type)
  (range-check (coerce-exact-integer _val type "coerce-int")
	       type *signed-ranges* "coerce-int"))

(define (coerce-unsigned _val type)
  (range-check (coerce-exact-integer _val type "coerce-unsigned")
	       type *unsigned-ranges* "coerce-unsigned"))

(define (coerce-char _val type)
  (cond
   ((char? _val)
    _val)
   ((and (not ERROR_ON_MISMATCH) (exact-integer? _val))
    (integer->char _val))
   (else
    (mismatch-error "coerce-char" _val type))))

(define (coerce-float _val type)
  (cond
   ((and (real? _val) (inexact? _val)) _val)
   ((and (not ERROR_ON_MISMATCH) (real? _val))
    (exact->inexact _val))
   (else
    (mismatch-error "coerce-float" _val type))))

(define (coerce-string _val type)
  (cond
   ((string? _val) _val)
   ((not ERROR_ON_MISMATCH) (format #f "~a" _val))
   (else
    (mismatch-error "coerce-string" _val type))))

(define (coerce-pointer _val type)
  (cond
   ((pointer? _val) (pointer-address _val))
   ((and (exact-integer? _val) (<= 0 _val UINTPTR_MAX)) _val)
   (else
    (mismatch-error "coerce-pointer" _val type))))

;;; Entry points

(define (asprintf _format-str . _args)
  "Given a format string and associated arguments, this returns
a formatted string.

For the %n conversion, the argument must be a procedure; it is called
with the number of characters output so far."
  (let loop ((output "")
	     (format-str _format-str)
	     (args _args))
    (if (string-null? format-str)
	output
	(match (format-string-parser format-str)
	  ((str flags field-width precision length-modifier specifier)
	   (let ((argcount (format-argument-count field-width precision specifier)))
	     (when (< (length args) argcount)
	       (scm-error 'wrong-number-of-args "asprintf"
			  "not enough arguments for format string: need ~a, have ~a, format ~S"
			  (list argcount (length args) _format-str)
			  #f))
	     (let ((substr
		    (if (eqv? specifier 'output-count)
			(let ((proc (last (take args argcount))))
			  (unless (procedure? proc)
			    (mismatch-error "asprintf" proc 'procedure))
			  (proc (string-length output))
			  "")
			(apply format-string-dispatch
			       str flags field-width precision length-modifier specifier
			       (take args argcount)))))
	       (loop (string-append output substr)
		     (string-drop format-str (string-length str))
		     (drop args argcount)))))))))

(define (printf _format-str . _args)
  (display (apply asprintf _format-str _args)))

(define (fprintf port _format-str . _args)
  (display (apply asprintf _format-str _args) port))
