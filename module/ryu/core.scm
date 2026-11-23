(define-module (ryu core)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 i18n)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 iconv)
  #:use-module (ice-9 rdelim)
  #:use-module (rnrs bytevectors)
  #:use-module (system foreign)
  #:use-module (ryu printf)
  #:export (;; 5.1.2.2.1 Program startup
	    argc
	    argv

	    ;; 5.2.1.1 Trigraph sequences
	    trigraph->ascii
	    ascii->trigraph

	    ;; 6.5.3.1 Prefix increment and decrement operators
	    c++
	    ++
	    c--
	    --

	    ;; 6.5.3.3 Unary arithmetic operators
	    lognot-uint8
	    lognot-uint16
	    lognot-uint32
	    lognot-uint64

	    ;; 6.5.4 Cast operators
	    cast-int8-to-uint8
	    cast-uint8-to-int8
	    cast-int16-to-uint16
	    cast-uint16-to-int16
	    cast-int32-to-uint32
	    cast-uint32-to-int32
	    cast-int64-to-uint64
	    cast-uint64-to-int64

	    ;; 6.5.5 Multiplicative operators
	    c*
	    c/
	    c%

	    ;; 6.5.6 Additive operators
	    c+
	    c-

	    ;; 6.5.7 Bitwise shift
	    <<
	    >>
	    u8<<
	    u8>>
	    u16<<
	    u16>>
	    u32<<
	    u32>>
	    u64<<
	    u64>>

	    ;; 6.5.9 Equality operators
	    c==
	    ==
	    c!=
	    !=

	    ;; 6.5.10 Bitwise AND operator
	    bitand

	    ;; 6.5.11 Bitwise exclusive OR operator
	    bitxor

	    ;; 6.5.12 Bitwise inclusive OR operator
	    bitor

	    ;; 6.5.13 Logical AND operator
	    c-logical-and

	    ;; 6.5.14 Logical OR operator
	    c-logical-or

	    ;; 6.5.15 Contitional operator
	    c?:
	    ?:

	    ;; 6.5.16 Assignment operators
	    *=
	    /=
	    %=
	    +=
	    -=
	    <<=
	    >>=
	    &=
	    ^=
	    \|=

	    ;; 6.8.5 Iteration statements
	    for

	    ;; 6.10.8 Predefined macro names
	    __FILE__
	    __LINE__

	    ;; 7.2.1.1 The assert macro
	    cassert
	    assert

	    ;; 7.3.5 Trigonometric functions
	    cacos casin catan ccos csin ctan

	    ;; 7.3.6 Hyperbolic functions
	    cacosh casinh catanh ccosh csinh ctanh

	    ;; 7.3.7 Exponential and logarithmic functions
	    cexp clog

	    ;; 7.3.8 Power and absolute-value functions
	    cabs cpow csqrt

	    ;; 7.3.9 Manipulation functions
	    carg cimag CMPLX conj cproj creal

	    ;; 7.4 Character handling
	    locale-uint8->char

	    ;; 7.4.1.1 The isalnum function
	    cisalnum
	    isalnum?

	    ;; 7.4.1.2 The isalpha function
	    cisalpha
	    isalpha?

	    ;; 7.4.1.3 The isblank function
	    cisblank
	    isblank?

	    ;; 7.4.1.4 The iscntrl function
	    ciscntrl
	    iscntrl?

	    ;; 7.4.1.5 The isdigit function
	    cisdigit
	    isdigit?

	    ;; 7.4.1.6 The isgraph function
	    cisgraph
	    isgraph?

	    ;; 7.4.1.7 The islower function
	    cislower
	    islower?

	    ;; 7.4.1.8 The isprint function
	    cisprint
	    isprint?

	    ;; 7.4.1.9 The ispunct function
	    cispunct
	    ispunct?

	    ;; 7.4.1.10 The isspace function
	    cisspace
	    isspace?

	    ;; 7.4.1.11 The isupper function
	    cisupper
	    cissupper			; misspelled, kept for compatibility
	    isupper?

	    ;; 7.4.1.12 The isxdigit function
	    cisxdigit
	    isxdigit?

	    ;; 7.4.2.1 The tolower function
	    ctolower
	    tolower

	    ;; 7.4.2.2 The toupper function
	    ctoupper
	    toupper

	    ;; 7.8.2.1 The imaxabs function
	    imaxabs

	    ;; 7.8.2.2 The imaxdiv function
	    imaxdiv

	    ;; 7.8.2.3 The strtoimax and strtoumax functions
	    strtoimax
	    strtoimax-idx
	    strtoumax
	    strtoumax-idx

	    ;; 7.10 Sizes of integer types <limits.h>
	    INT_MIN
	    INT_MAX
	    UINT_MAX
	    LONG_MIN
	    LONG_MAX
	    ULONG_MAX

	    ;; 7.11.2.1 The localeconv function
	    localeconv

	    ;; 7.12.3.2 The isfinite macro
	    cisfinite
	    isfinite?

	    ;; 7.12.3.3 The isinf macro
	    cisinf
	    isinf?

	    ;; 7.12.3.4 The isnan macro
	    cisnan
	    isnan?

	    ;; 7.12.3.5 The isnormal macro
	    cisnormal
	    isnormal?

	    ;; 7.12.3.6 The signbit macro
	    csignbit
	    signbit

	    ;; 7.12.4.4 The atan2 functions
	    atan2

	    ;; 7.12.6.2 The exp2 functions
	    exp2

	    ;; 7.12.6.3 The expm1 functions
	    expm1

	    ;; 7.12.6.4 The frexp functions
	    frexp

	    ;; 7.12.11.1 The copysign functions
	    copysign

	    ;; 7.12.11.2 The nan functions
	    cnan

	    ;; 7.12.11 Manipulation functions
	    nextafter

	    ;; 7.12.14.5 The islessgreater macro
	    cislessgreater
	    islessgreater

	    ;; 7.14.1.1 The signal function
	    signal

	    ;; 7.18 Boolean type and values
	    ctrue
	    cfalse
	    ->cbool
	    cbool->bool

	    ;; 7.20.2.1 Limits of exact-width integers
	    INT8_MIN
	    INT8_MAX
	    UINT8_MAX
	    INT16_MIN
	    INT16_MAX
	    UINT16_MAX
	    INT32_MIN
	    INT32_MAX
	    UINT32_MAX
	    INT64_MIN
	    INT64_MAX
	    UINT64_MAX

	    ;; 7.21.4.1 The remove function
	    remove

	    ;; 7.21.4.2 The rename function
	    rename

	    ;; 7.21.5.1 The fclose function
	    fclose

	    ;; 7.21.5.2 The fflush function
	    fflush

	    ;; 7.21.5.3 The fopen function
	    fopen

	    ;; 7.21.6 Formatted input/output functions
	    snprintf
	    sprintf

	    ;; 7.21.7 Character input/output functions
	    fgetc
	    fgets

	    ;; 7.21.9.5 The rewind function
	    rewind

	    ;; <math.h>
	    ilogb
	    ldexp
	    log1p
	    log2
	    logb
	    modf
	    scalbn
	    cbrt
	    hypot
	    pow
	    erf
	    lgamma
	    tgamma
	    ceil
	    lround
	    trunc
	    fmod
	    remquo
	    fdim
	    fma

	    ;; <setjmp.h>
	    ;; <signal.h>
	    ;; <stdalign.h>
	    ;; <stdarg.h>
	    ;; <stdatomic.h>

	    ;; <stdint.h>

	    ;; <stdio.h>

	    ;; <stdlib.h>
	    EXIT_SUCCESS
	    EXIT_FAILURE
	    RAND_MAX
	    atof
	    atoi
	    strtod
	    strtol
	    strtol-idx
	    strtoul
	    strtoul-idx
	    strtof
	    rand
	    srand
	    calloc
	    malloc
	    realloc
	    abort
	    div
	    mblen


	    ;; <stdnoreturn.h>
	    ;; <string.h>
	    string-ref-safe
	    strcpy
	    strncpy
	    strncat
	    strlen
	    strnlen
	    strcmp
	    strncmp
	    strcoll
	    strchr
	    strchr-idx
	    strrchr
	    strrchr-idx
	    strspn
	    strcspn
	    strpbrk
	    strpbrk-idx
	    strstr
	    strstr-idx
	    strtok
	    memchr
	    memchr-idx
	    memcmp
	    memset
	    memcpy
	    memmove
	    ;; STRERROR is in core Guile.

	    ;; <tgmath.h>

	    ;; <threads.h>
	    ;; <time.h>
	    ;; <uchar.h>
	    ;; <wchar.h>
	    wctomb
	    mbtowc
	    mbstowcs
	    wcstombs

	    ;; <wctype.h>
	    iswctype
	    wctype
	    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5.1.2.2.1 Program Startup

;; ARGC and ARGV are the count of command-line arguments and pointers
;; to the those arguments.  The core Guile procedure COMMAND-LINE
;; returns the command line arguments as a list of strings.  So
;; approximately
(define (argc)
  "Return the number of command-line arguments for the current program."
  (length (command-line)))

(define* (argv #:optional (n #f))
  "Return the command-line arguments for the current program. If
N is specified, return the Nth command line argument."
  (if n
      (list-ref (command-line) n)
      (command-line)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5.2.1.1 Trigraph sequences

;; In C, there are trigraphs used for representing C code in
;; environments where the symbols "#[\]^{|}~" may not be available.
;; Guile has no concept of trigraphs.

;; Really, one is never going to see or use trigraphs. I wrote
;; these functions as a joke.

(define *tri:ascii*
  '((#\= . #\#)
    (#\( . #\[)
    (#\/ . #\\)
    (#\) . #\])
    (#\' . #\^)
    (#\< . #\{)
    (#\! . #\|)
    (#\> . #\})
    (#\- . #\~)))

(define *ascii:tri*
  '((#\# . #\=)
    (#\[ . #\()
    (#\\ . #\/)
    (#\] . #\))
    (#\^ . #\')
    (#\{ . #\<)
    (#\| . #\!)
    (#\} . #\>)
    (#\~ . #\-)))

(define (trigraph->ascii input-str)
  "Given a string, return a new string with trigraph sequences
replaced with the corresponding single characters."
  (let ((output-str (string-copy input-str))
	(char-set:tri (string->char-set "=(/)'<!>-")))
    (let loop ((input-index 0)
	       (output-index 0)
	       (state 0))
      (if (< input-index (string-length input-str))
	  (let ((c (string-ref input-str input-index)))
	    (if (eqv? c #\?)
		(cond
		 ((= state 2)
		  ;; We've already seen two question marks.
		  ;; Append one question mark to the output.
		  (string-set! output-str output-index #\?)
		  (loop (1+ input-index)
			(1+ output-index)
			state))
		 ((or (= state 1) (= state 0))
		  ;; We've see 1 question mark so far.  Wait
		  ;; for another one.
		  (loop (1+ input-index)
			output-index
			(1+ state))))
		;; Else, this is not a question mark
		(cond
		 ((and (= state 2) (char-set-contains? char-set:tri c))
		  ;; This is a trigraph.
		  (string-set! output-str output-index
			       (assv-ref *tri:ascii* c))
		  (loop (1+ input-index)
			(1+ output-index)
			0))
		 ((= state 2)
		  ;; This was a couple of question marks followed by
		  ;; a character that doesn't form a trigraph.
		  (string-set! output-str output-index #\?)
		  (string-set! output-str (1+ output-index) #\?)
		  (string-set! output-str (+ 2 output-index) c)
		  (loop (1+ input-index)
			(+ 3 output-index)
			0))
		 ((= state 1)
		  ;; This was a single question mark followed by a
		  ;; character.
		  (string-set! output-str output-index #\?)
		  (string-set! output-str (1+ output-index) c)
		  (loop (1+ input-index)
			(+ 2 output-index)
			0))
		 (else
		  (string-set! output-str output-index c)
		  (loop (1+ input-index)
			(1+ output-index)
			0)))))
	  ;; We've reached the end.  Return the output.
	  (begin
	    ;; There may still be unprocessed question marks that need
	    ;; to be appended.
	    (if (>= state 1)
		(string-set! output-str output-index #\?))
	    (if (= state 2)
		(string-set! output-str (1+ output-index) #\?))
	    (substring output-str 0 (+ output-index state)))))))


(define (ascii->trigraph input-str)
  "Given a string of ASCII test, return a new string, with the
required single characters replaced with trigraph sequences."
  (let* ((char-set:tri (string->char-set "#[\\]^{|}~"))
	 (n (string-count input-str (lambda (c)
					 (char-set-contains?
					  char-set:tri c))))
	 (output-str (make-string (+ (string-length input-str)
					(* 2 n))))
	 (input-length (string-length input-str)))
    (let loop ((input-index 0)
	       (output-index 0))
      (if (>= input-index input-length)
	  output-str
	  ;; else
	  (let ((c (string-ref input-str input-index)))
	    (if (char-set-contains? char-set:tri c)
		(begin
		  (string-set! output-str output-index #\?)
		  (string-set! output-str (1+ output-index) #\?)
		  (string-set! output-str (+ 2 output-index)
			       (assv-ref *ascii:tri* c))
		  (loop (1+ input-index)
			(+ 3 output-index)))
		;; else
		(begin
		  (string-set! output-str output-index c)
		  (loop (1+ input-index)
			(1+ output-index)))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5.2.2 Character display semantics

;; C has the alphabetic escape sequeces for alert (\a), backspace (\b,
;; form feed (\f), new line (\n), carriage return (\r), horizontal
;; tab (\t), and vertical tab (\v).

;; For Guile, the alphabetic escape sequences for those characters are
;; different, but, for the strings, they are similar.

;; C_ESCAPE   GUILE_CHARACTER   GUILE_STRING_ESCAPE
;; \a         #\alarm           \a
;; \b         #\backspace       \b
;; \f         #\page            \f
;; \n         #\newline         \n
;; \r         #\return          \r
;; \t         #\tab             \t
;; \v         #\vtab            \v

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.4.6 Punctuators

;; C has 6 digraph tokens.
;; <: :> <% %> %: and %:%:
;; behave as [ ] { } # and ##

;; But since these need to be in context as tokens, it
;; is not simple to extract them.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.2.1 Array subscripting

;; In C, the postfix expression in square brackets is a
;; subscripted designation of an array object.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.2.5.3 Structure and union members

;; In C, the '.' and '->' operators designates a member
;; of a structure or union object.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.3.1 Prefix increment and decrement operators

;; ++ -  The increment operator in C can be implemented as
;; a macro in Guile.  But, in Scheme, too much modification of
;; variables is discouraged.
(define-syntax c++
  (syntax-rules ()
    ((_ x)
     (set! x (c+ x 1)))))

(define-syntax ++
  (syntax-rules ()
    ((_ x)
     (set! x (1+ x)))))

(define-syntax c--
  (syntax-rules ()
    ((_ x)
     (set! x (c- x 1)))))

(define-syntax --
  (syntax-rules ()
    ((_ x)
     (set! x (1- x)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.3.3 Unary arithmetic operators

;; The unary tilde operator in C is the bitwise component of an
;; operand.  In core Guile, LOGNOT is the bitwise component.  But to
;; get behavior like C, you need to decide on the number of bits in
;; the integer.

(define (bytes-to-bits b)
  (* 8 b))

(define (signed-limit b)
  (1- (expt 2 (1- (bytes-to-bits b)))))

(define (unsigned-limit b)
  (1- (expt 2 (bytes-to-bits b))))

(define (signed-limit-neg b)
  (- (expt 2 (1- (bytes-to-bits b)))))

(define (lognot-uint x b)
  (- (unsigned-limit b) (logand (unsigned-limit b) x)))

(define (lognot-uint8 x)
  "Find the bitwise complement of an 8-bit unsigned integer."
  (lognot-uint x 1))

(define (lognot-uint16 x)
  "Find the bitwise complement of a 16-bit unsigned integer."
  (lognot-uint x 2))

(define (lognot-uint32 x)
  "Find the bitwise complement of a 32-bit unsigned integer."
  (lognot-uint x 4))

(define (lognot-uint64 x)
  "Find the bitwise complement of a 64-bit unsigned integer."
  (lognot-uint x 8))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.3.4 The sizeof and _Alignof operators

;; A version of 'sizeof' appears in (system foreign) but only
;; applies to a handful of predefined types.

;; And _ALIGNOF don't have any close analog in core Guile.

;; The unary asterisk in C denotes pointer indirection. There is no
;; close analog to that concept in Guile.  In core Guile, the unary
;; asterisk actually has the meaning of multiplying a value by 1.
;; e.g. (* val) = val.

;; The unary ampersand operator in C denotes taking the address of a
;; variable.  Ther is no close analog to that concept in Guile.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.4 Cast operators

;; A cast to an unsigned type of N bits reduces the value modulo 2^N.
;; A cast to a signed type of N bits does the same, then maps the upper
;; half of the range to negative values (two's complement).

(define (wrap-unsigned x bits)
  (logand x (1- (ash 1 bits))))

(define (wrap-signed x bits)
  (let ((u (wrap-unsigned x bits)))
    (if (logbit? (1- bits) u)
	(- u (ash 1 bits))
	u)))

(define (cast-int8-to-uint8 x)
  "Convert X to an 8-bit unsigned integer, as a C cast would."
  (wrap-unsigned x 8))

(define (cast-uint8-to-int8 x)
  "Convert X to an 8-bit signed integer, as a C cast would."
  (wrap-signed x 8))

(define (cast-int16-to-uint16 x)
  "Convert X to a 16-bit unsigned integer, as a C cast would."
  (wrap-unsigned x 16))

(define (cast-uint16-to-int16 x)
  "Convert X to a 16-bit signed integer, as a C cast would."
  (wrap-signed x 16))

(define (cast-int32-to-uint32 x)
  "Convert X to a 32-bit unsigned integer, as a C cast would."
  (wrap-unsigned x 32))

(define (cast-uint32-to-int32 x)
  "Convert X to a 32-bit signed integer, as a C cast would."
  (wrap-signed x 32))

(define (cast-int64-to-uint64 x)
  "Convert X to a 64-bit unsigned integer, as a C cast would."
  (wrap-unsigned x 64))

(define (cast-uint64-to-int64 x)
  "Convert X to a 64-bit signed integer, as a C cast would."
  (wrap-signed x 64))

;; No close analog in Guile.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.5 Multiplicative operators

;; In both C and Guile, when the operands of binary operators have
;; different numerical types, the result will be in the numerical type
;; that is higher in the numerical tower.  If one operand is integer
;; and the other is real, the result will be real.

;; Guile, however, includes the rarely-useful rational types is its
;; numerical tower.

;; Also, C allows math on pointers

(define (c* _a _b)
  "Multiply two values, either numbers or pointers, whilst promoting
any non-integer rational operands to real numbers."
  (let ((a (if (pointer? _a) (pointer-address _a) _a))
	(b (if (pointer? _b) (pointer-address _b) _b)))
    (cond
     ((and (exact-integer? a) (exact-integer? b))
      (* a b))
     (else
      (* (exact->inexact a) (exact->inexact b))))))

(define (c/ _a _b)
  "Divide two values, either numbers or pointers, whilst promoting
any non-integer rational operands to real numbers."
  (let ((a (if (pointer? _a) (pointer-address _a) _a))
	(b (if (pointer? _b) (pointer-address _b) _b)))
    (cond
     ((and (exact-integer? a) (exact-integer? b))
      (quotient a b))
     (else
      (/ (exact->inexact a) (exact->inexact b))))))

(define (c% _a _b)
  "Compute the remainder of two values, either numbers or pointers.
As in C, the result has the sign of the dividend, so that
(c+ (c* (c/ a b) b) (c% a b)) equals A."
  (let ((a (if (pointer? _a) (pointer-address _a) _a))
	(b (if (pointer? _b) (pointer-address _b) _b)))
    (remainder a b)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.6 Additive operators

(define (c+ _a _b)
  "Add two values, either numbers or pointers, whilst promoting any
non-integer rational operands to real numbers. If _a is a pointer
and _b is an integer, it returns a pointer."
  (cond
   ((and (pointer? _a) (exact-integer? _b))
    (make-pointer (+ (pointer-address _a) _b)))
   (else
    (let ((a (if (pointer? _a) (pointer-address _a) _a))
	  (b (if (pointer? _b) (pointer-address _b) _b)))
      (cond
       ((and (exact-integer? a) (exact-integer? b))
	(+ a b))
       (else
	(+ (exact->inexact a) (exact->inexact b))))))))

(define (c- _a _b)
  "Subtract two values, either numbers or pointers, whilst promoting
any non-integer rational operands to real numbers. If _a is a pointer
and _b is an integer, the return value is a pointer."
  (cond
   ((and (pointer? _a) (exact-integer? _b))
    (make-pointer (- (pointer-address _a) _b)))
   (else
    (let ((a (if (pointer? _a) (pointer-address _a) _a))
	  (b (if (pointer? _b) (pointer-address _b) _b)))
      (cond
       ((and (exact-integer? a) (exact-integer? b))
	(- a b))
       (else
	(- (exact->inexact a) (exact->inexact b))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.7 Bitwise shift operators

;; In C, '<<' and '>>' perform bitwise shift on integer types.  In
;; core Guile, 'ash' is the related procedure.

;; With 'A << B', the operand A is left shifted the indicated number
;; of bit positions, with vacated bits being zero filled.  In C,
;; integers have 1, 2, 4, or 8 bytes, so bits that are shifted off the
;; end are ignored. What happens with negative values of A is
;; undefined.

;; With 'A >> B', A is right shifted B positions.  What happens with
;; negative values of A is also undefined.

;; With core Guile's 'ash' procedure, integers are never left-shifted
;; off, since integers are unbounded.

(define (<< a b)
  "Left shift A by B bits."
  (ash a b))

(define (>> a b)
  "Right-shift A by B bits."
  (ash a (- b)))

(define (u8<< a b)
  "Left shift A by B bits, presuming A is limited to 8 bits.  If A is
negative, the behavior is unspecified."
  (let* ((a8 (logand #xff (if (>= a 0)
				 a
				 (cast-int8-to-uint8 a))))
	 (shift8 (ash a8 b)))
    (if (>= a 0)
	(logand #xff shift8)
	(cast-uint8-to-int8 (logand #xff shift8)))))

(define (u16<< a b)
  "Left shift A by B bits, presuming A is limited to 16 bits.  If A is
negative, the behavior is unspecified."
  (let* ((a16 (logand #xffff (if (>= a 0)
				 a
				 (cast-int16-to-uint16 a))))
	 (shift16 (ash a16 b)))
    (if (>= a 0)
	(logand #xffff shift16)
	(cast-uint16-to-int16 (logand #xffff shift16)))))

(define (u32<< a b)
  "Left shift A by B bits, presuming A is limited to 32 bits.  If A is
negative, the behavior is unspecified."
  (let* ((a32 (logand #xffffffff (if (>= a 0)
				 a
				 (cast-int32-to-uint32 a))))
	 (shift32 (ash a32 b)))
    (if (>= a 0)
	(logand #xffffffff shift32)
	(cast-uint32-to-int32 (logand #xffffffff shift32)))))

(define (u64<< a b)
  "Left shift A by B bits, presuming A is limited to 64 bits.  If A is
negative, the behavior is unspecified."
  (let* ((a64 (logand #xffffffffffffffff (if (>= a 0)
				 a
				 (cast-int64-to-uint64 a))))
	 (shift64 (ash a64 b)))
    (if (>= a 0)
	(logand #xffffffffffffffff shift64)
	(cast-uint64-to-int64 (logand #xffffffffffffffff shift64)))))

(define (u8>> a b)
  "Right shift A by B bits, presuming A is limited to 8 bits.  If A is
negative, the behavior is unspecified."
  (u8<< a (- b)))

(define (u16>> a b)
  "Right shift A by B bits, presuming A is limited to 16 bits.  If A is
negative, the behavior is unspecified."
  (u16<< a (- b)))

(define (u32>> a b)
  "Right shift A by B bits, presuming A is limited to 32 bits.  If A is
negative, the behavior is unspecified."
  (u32<< a (- b)))

(define (u64>> a b)
  "Right shift A by B bits, presuming A is limited to 64 bits.  If A is
negative, the behavior is unspecified."
  (u64<< a (- b)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.9 Equality operators

;; Guile has many type of equality.

;; C equality returns 0 or 1, not #t or #f
(define (c== _a _b)
  "Given two values, either numbers or pointers, return 1 if A and B
are numerically equal, or zero otherwise, whilst promoting any
non-integer rational operands to real numbers."
  (let ((a (if (pointer? _a) (pointer-address _a) _a))
	(b (if (pointer? _b) (pointer-address _b) _b)))
    ;; Use numeric equality, so that 0.0 == -0.0 and NaN != NaN.
    (if (= a b) 1 0)))

(define (== _a _b)
  (equal? _a _b))

(define (c!= _a _b)
  "Given two values, either numbers or pointers, return zero if A and B
are numerically equal, or one otherwise, whilst promoting any
non-integer rational operands to real numbers."
  (let ((a (if (pointer? _a) (pointer-address _a) _a))
	(b (if (pointer? _b) (pointer-address _b) _b)))
    ;; Use numeric equality, so that 0.0 == -0.0 and NaN != NaN.
    (if (= a b) 0 1)))

(define (!= _a _b)
  (not (equal? _a _b)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.10 Bitwise AND operator

;; Bitwise AND operator - called LOGAND in core Guile.
(define (bitand a b)
  "Compute the bitwise AND of two integers."
  (logand a b))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.11 Bitwise exclusive OR operator

;; Bitwise exclusive OR operator - called LOGXOR in core Guile.
(define (bitxor a b)
  "Compute the bitwise exclusive OR of two operands."
  (logxor a b))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.12 Bitwise inclusive OR operator

;; Bitwise inclusive OR operator - called LOGIOR in core Guile. But
;; the vertical bar has syntactical meaning in Guile, so here it is
;; slash-bar.
(define (bitor a b)
  "Compute the bitwise OR of two integers"
  (logior a b))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.13 Logical AND operator

;; Converting logical operations from C to Guile must handle how C
;; uses non-zero and zero integers for true and false, whilst Guile
;; has a boolean type.  Here we create a hybrid between C and Guile
;; where #f, numeric zero, and the null pointer are false.

(define (c-true? x)
  (cond
   ((not x) #f)
   ((number? x) (not (zero? x)))
   ((pointer? x) (not (null-pointer? x)))
   (else #t)))

(define (c-logical-and a b)
  "Compute the logical AND of two scalar operands, returning 1 if both
operands compare unequal to zero, and zero otherwise."
  (if (and (c-true? a) (c-true? b))
      1
      0))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.14 Logical OR operator

;; Logical OR operator - called 'or' in core Guile. But in C, the
;; exact integer zero indicates false.  Here we create a hybrid
;; between C and Guile where both #f and 0 are false.
(define (c-logical-or a b)
  "Compute the logical or of two scalar operands, returning 1 if either operand
compares unequal to zero, and zero otherwise."
  (if (or (c-true? a) (c-true? b))
      1
      0))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.15 Conditional operator

;; The '?:' ternary operator in C returns the second operand if the
;; first operand is unequal to zero. Otherwise it returns the third
;; operand.  It is analgous to the core Guile's 'if; procedure.  Here
;; we create a hybrid between C and Guile where both #f and 0 are
;; false.
(define (c?: test on-success on-failure)
  "If test is unequal to zero, return on-success.
Else return on-failure."
  (if (c-true? test)
      on-success
      on-failure))

(define (?: test on-success on-failure)
  "If test is unequal to #f, return on-success.
Else return on-failure."
  (if test
      on-success
      on-failure))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.16 ASSIGNMENT OPERATORS

;; These are = *= /= %= += -= <<= >>= &= ^= and |\

;; As always, Scheme programmers aren't big on assignment.
;; They'll tell you that you shouldn't be assigning variables
;; unless there is no other option.

;; Even so, here are some analagous syntax.

;; Plain old equal assignment is set! in core Guile.

(define-syntax +=
  (syntax-rules ()
    ((_ x a)
     (set! x (c+ x a)))))

(define-syntax -=
  (syntax-rules ()
    ((_ x a)
     (set! x (c- x a)))))

(define-syntax *=
  (syntax-rules ()
    ((_ x a)
     (set! x (c* x a)))))

(define-syntax /=
  (syntax-rules ()
    ((_ x a)
     (set! x (c/ x a)))))

(define-syntax %=
  (syntax-rules ()
    ((_ x a)
     (set! x (c% x a)))))

(define-syntax &=
  (syntax-rules ()
    ((_ x a)
     (set! x (bitand x a)))))

(define-syntax \|=
  (syntax-rules ()
    ((_ x a)
     (set! x (bitor x a)))))

(define-syntax ^=
  (syntax-rules ()
    ((_ x a)
     (set! x (bitxor x a)))))

(define-syntax <<=
  (syntax-rules ()
    ((_ x a)
     (set! x (<< x a)))))

(define-syntax >>=
  (syntax-rules ()
    ((_ x a)
     (set! x (>> x a)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.5.17 Comma operator

;; The C operator ',', is analagous to the core Guile procedure
;; 'begin'.  The operands are evaluated left-to-right, and the last
;; one is returned.

;; But, in C, the comma is also syntax used to separated items in a
;; list.

;; In Guile, the comma is the unquote operator.

;; So use 'begin' for comma.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.7.1 Storage-class specifiers

;; In C, a declaration has either an explicit or implied storage-class
;; specifier, and it is one of: 'extern', 'static', '_Thread_local',
;; 'auto', or 'register'

;; There is no easy one-to-one.

;; To create a thread-local storage, use a fluid.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.7.2.4 Atomic type specifiers

;; In C, the _Atomic type specifier can indicate that a declared
;; variable can be accessed by multiple threads, and that operations
;; on atomic variable will occur one at a time, and never
;; simultaneously by different threads.

;; In Guile, 'make-atomic-box', 'atomic-box-ref', and 'atomic-box-set!'
;; can be used.

;; To define a function or variable at module level, use 'define'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.7.4 Function specifiers

;; In C, the 'inline' function specifier indicates that calls
;; to an inline function can, at compile time, be replaced with
;; the code for that function itself.

;; To define an 'inline' procedure in Guile, use 'define-inlinable'

;; There is no analog for the '_Noreturn' function specifier in Guile.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.7.5 Alignment specifier

;; Typically in Guile, one doesn't control the details of how
;; objects are stored.  There is no easy analog to C's '_Alignas'
;; specifier.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.7.6 Declarators

;; In Guile, 'define' or 'let' are the basic declaration
;; mechanisms.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.8.4.1 The 'if' statement

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.8.4.2 The 'switch' statement

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.8.5 Iteration statements

;; The C iteration statements are 'while', 'do' and 'for'.

;; Guile is big on telling you that named 'let' and recursion
;; is the right thing to do.  But many named 'let' loops are difficult
;; to interpret by those that didn't write them.

;; Sometimes, I use Guile's 'do', which is as close as one can get to
;; a C 'for' loop in core Guile.


;; A simple 'for' loop for a single variable.
;; call like this
;; (for (i 0) (< i 10) (1+ i)
;;      ...)
;; It supports 'break' and 'continue' syntax.

(define-syntax for
  (lambda (x)
    (syntax-case x ()
      ((for (init-var init-val) cond iterator body ...)
       (with-syntax ((break (datum->syntax #'for 'break))
		     (continue (datum->syntax #'for 'continue)))
	 #'(let ((break-tag (make-prompt-tag "break"))
		 (continue-tag (make-prompt-tag "continue")))
	     (call-with-prompt
		 break-tag
	       (lambda ()
		 (define-syntax break
		   (lambda (x)
		     (syntax-case x ()
		       ((_ arg (... ...))
			#'(abort-to-prompt break-tag arg (... ...)))
		       (_
			#'(lambda args
			    (apply abort-to-prompt break-tag args))))))
		 (define-syntax continue
		   (lambda (x)
		     (syntax-case x ()
		       ((_)
			#'(abort-to-prompt continue-tag))
		       ((_ . args)
			(syntax-violation 'continue "too many arguments" x))
		       (_
			#'(lambda ()
			    (abort-to-prompt continue-tag))))))
		 (let lp ((init-var init-val))
		   (if cond
		       (begin
			 ;; CONTINUE skips the rest of the body, but
			 ;; still performs the iteration step.
			 (call-with-prompt
			     continue-tag
			   (lambda () body ... (if #f #f))
			   (lambda (k) #f))
			 (lp iterator))
		       #f)))
	       (lambda (k . args)
		 (if (null? args)
		     #t
		     (apply values args))))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.8.6 Jump statements

;; The C jump statements are 'goto', 'continue', 'break',
;; 'return'.

;; The best analog to 'goto' in core Guile is
;; call-with-current-configuration, aka call/cc, but, they
;; are very different concepts in practice.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.10 Preprocessing directives

;; Any attempt at multiplatform C is littered with
;; prepreocessing directives like '#if' '#ifdef' '#ifndef'
;; '#elif' '#else' and '#endif'.

;; There is also '#include' '#define' '#undef' '#line'
;; '#error' and '#pragma'

;;;;
;; For '#if' '#ifdef' '#ifndef' '#elif' '#else' and '#endif'.

;; There isn't really a Guile preprocessor, as such.

;; The SRFI-0 procedure 'cond-expand' provides conditionals
;; different versions of guile, and the presence of different
;; SRFI's, so this may help replace #ifdef for code that is
;; dependent on different versions of guile.

;; There is also the core Guile 'provided?' procedure that can
;; check if certain platform-dependent features are available.

;; Lastly, the M4 macro processor can be used on Guile, if one
;; really more features than 'cond-expand', 'include' and
;; 'provided?' provide.

;; For '#include'

;; In core Guile is an 'include' and 'include-from-path' which
;; acts much like #include does. It inserts the contents of
;; another file at compile time.

;; For including a file only a run-time, 'load' and 'load-from-path'
;; will work.

;; There is also the standard 'use-modules' directive.

;; Be aware of the cases that may require a call to 'eval-when'.

;; For '#define' of macros

;; In modern C++, they encourage inline functions over defines
;; where possible.  Thus for a #define replacement, consider
;; core Guile's 'define-inlineable'.

;;;;
;; For '#line'

;; In C '#line' is a pre-processor directive that indicates
;; the line number of the current source line.  Theoretically,
;; once could mess about with core Guile's 'set-source-properties!',
;; but it doesn't seem useful.

;;;;
;; For '#error'

;; In C, "#error" is used to terminate compilation. Usually,
;; it appears within certain combinations of #if and #ifdef
;; directives.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6.10.8 Predefined macro names

;; In C, there compile-time predefined macros include
;; __FILE__, __LINE__, __DATE__, and __TIME__.

;; For compiled Guile objects, the file name and line number
;; may appear in their source properties.  Here are a couple
;; of analagous procedures that may work, depending on how
;; the code was interpreted or compiled.
;; Both may be used either as (__FILE__) or as a bare __FILE__.
(define-syntax __FILE__
  (lambda (x)
    (let ((src (syntax-source x)))
      (datum->syntax
       x
       (or (and src (assq-ref src 'filename))
	   "(unknown file)")))))

(define-syntax __LINE__
  (lambda (x)
    (let* ((src (syntax-source x))
	   (line (and src (assq-ref src 'line))))
      ;; Guile counts lines from zero, C counts from one.
      (datum->syntax x (if line (1+ line) "(unknown line)")))))

;; There is also the core Guile 'current-filename' procedure.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.2.1.1 The assert macro

(eval-when (expand load eval)
  (define (__file-of x)
    (let ((src (syntax-source x)))
      (or (and src (assq-ref src 'filename)) "(unknown file)")))
  (define (__line-of x)
    (let* ((src (syntax-source x))
	   (line (and src (assq-ref src 'line))))
      (if line (1+ line) "(unknown line)"))))

;; If expression compares equal to zero, the cassert macro writes
;; information about the call that failed, and then calls abort.

(define-syntax cassert
  (lambda (x)
    (syntax-case x ()
      ((_ expression)
       (with-syntax ((file (datum->syntax x (__file-of x)))
		     (line (datum->syntax x (__line-of x))))
	 #'(let ((ret expression))
	     (unless (c-true? ret)
	       (format (current-error-port) "~a:~a: assertion failed: ~s~%"
		       file line 'expression)
	       (force-output (current-error-port))
	       (abort))))))))

;; If the expression is false, signal an error with a message about
;; the failing expression.
(define-syntax assert
  (lambda (x)
    (syntax-case x ()
      ((_ expression)
       (with-syntax ((file (datum->syntax x (__file-of x)))
		     (line (datum->syntax x (__line-of x))))
	 #'(let ((ret expression))
	     (unless ret
	       (error
		(format #f "~a:~a: assertion failed: ~s"
			file line 'expression)))))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.5.1 The cacos functions

(define (cacos x) (acos x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.5.2 The casin functions

(define (casin x) (asin x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.5.3 The catan function

(define (catan x) (atan x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.5.4 The ccos function

(define (ccos x) (cos x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.5.5 The csin functions

(define (csin x) (sin x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.5.6 The ctan function

(define (ctan x) (tan x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.6.1 The cacosh function

(define (cacosh x) (acosh x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.6.2 The casinh functions

(define (casinh x) (asinh x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.6.3 The catanh functions

(define (catanh x) (atanh x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.6.4 The ccosh functions

(define (ccosh x) (cosh x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.6.5 The csinh functions

(define (csinh x) (sinh x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.6.6 The ctanh function

(define (ctanh x) (tanh x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.7.1 The cexp functions

(define (cexp x) (exp x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.7.2 The clog functions

(define (clog x) (log x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.8.1 The cabs functions

(define (cabs x) (magnitude x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.8.2 The cpow functions

(define (cpow x y) (expt x y))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.8.3 csqrt functions

(define (csqrt x) (sqrt x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.9.1 The carg functions
(define (carg z) (angle z))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.9.2 The cimag functions

(define (cimag z)
  "Computes the imaginary part of a complex number."
  (imag-part z))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.9.3 The CMPLX macros

(define-syntax CMPLX
  (syntax-rules ()
    ((_ x y)
     (make-rectangular x y))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.9.4 The conj function

(define (conj z)
  "Computes the complex conjugate of z."
  (make-rectangular (real-part z) (- (imag-part z))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.9.5 The cproj function

(define (cproj z)
  "Computes the projection fo z onto the Riemann sphere.
That is, returns z, unless z is infinite."
  (cond
   ((or (inf? (real-part z)) (inf? (imag-part z)))
    ;; Infinities project to positive infinity, keeping the sign of
    ;; the imaginary part on a zero.
    (make-rectangular +inf.0 (if (signbit (imag-part z)) -0.0 0.0)))
   (else
    z)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.3.9.6 The creal function

(define (creal z)
  "Computes the real part of a complex number."
  (real-part z))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4 8-bit Character handling

;; The functions is ctype are for either 8-bit characters or the EOF
;; value, and they are affected by the current locale.

(define-inlinable (%cchar->char x)
  (false-if-exception
   (string-ref (bytevector->string (make-bytevector 1 x)
				   (locale-encoding %global-locale)
				   'error)
	       0)))

(define-inlinable (%char->cchar x)
  (let ((bv (false-if-exception
	     (string->bytevector (string x)
				 (locale-encoding %global-locale)
				 'error))))
    (if (and bv (= (bytevector-length bv) 1))
	(bytevector-u8-ref bv 0)
	#f)))

(define (locale-uint8->char x)
  "Given an 8-bit integer, return a character.  Make the conversion
using the current locale. Return #f on failure.  For the common case
of UTF-8, values between 128 and 255 will return #f."
  (if (and (exact-integer? x)
	   (<= 0 x)
	   (<= x UINT8_MAX))
      (%cchar->char x)
      #f))

(define-inlinable (%cchar x)
  (cond
   ((char? x)
    x)
   ((and (exact-integer? x) (<= 0 x) (<= x UINT8_MAX))
    (%cchar->char x))
   (else
    #f)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.1.1 The isalnum function
(define (cisalnum _c)
  "Return 1 if the 8-bit integer C maps to an alphanumeric character
in the current locale, else 0"
  (let ((c (%cchar _c)))
    (if (and c (char-set-contains? char-set:letter+digit c))
	1 0)))

(define (isalnum? c)
  "Return #t if the character C is alphanumeric."
  (char-set-contains? char-set:letter+digit c))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.1.2 The isalpha function

(define (cisalpha _c)
  "Return 1 if the 8-bit integer C maps to an alphabetic character
in the current locale, else 0"
  (let ((c (%cchar _c)))
    (if (and c (char-set-contains? char-set:letter c))
	1 0)))

(define (isalpha? c)
  "Return #t if the character C is alphabetic."
  (char-set-contains? char-set:letter c))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.1.3 The isblank function

(define (cisblank _c)
  "Return 1 if the 8-bit integer C maps to an blank character
in the current locale, else 0"
  (let ((c (%cchar _c)))
    (if (and c (char-set-contains? char-set:blank c))
	1 0)))

(define (isblank? c)
  "Return #t if the character C is a blank (space or tab)."
  (char-set-contains? char-set:blank c))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.1.4 The iscntrl function

(define (ciscntrl _c)
  "Return 1 if the 8-bit integer maps C is a control character, else 0."
  (let ((c (%cchar _c)))
    (if (and c (char-set-contains? char-set:iso-control c))
	1 0)))

(define (iscntrl? c)
  "Return true if C an ISO C0 or C1 control character"
  (char-set-contains? char-set:iso-control c))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.1.5 The isdigit function
(define (cisdigit _c)
  "Return 1 if the 8-bit integer maps C is a decimal digit character, else 0."
  (let ((c (%cchar _c)))
    (if (and c (char-set-contains? char-set:digit c))
	1 0)))

(define (isdigit? c)
  "Return #t if the character C is a digit, else #f"
  (char-set-contains? char-set:digit c))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.1.6 The isgraph function

(define (cisgraph _c)
  "Return 1 if the 8-bit integer maps C is a printing character, else 0."
  (let ((c (%cchar _c)))
    (if (and c (char-set-contains? char-set:graphic c))
	1 0)))

(define (isgraph? c)
  "Return #t if the character C is a printing character, else #f"
  (char-set-contains? char-set:graphic c))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.1.7 The islower function

(define (cislower _c)
  "Return 1 if the 8-bit integer C maps to a small character, else 0."
  (let ((c (%cchar _c)))
    (if (and c (char-set-contains? char-set:lower-case c))
	1 0)))

(define (islower? c)
  "Return #t if C a lowercase letter."
  (char-set-contains? char-set:lower-case c))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.1.7 The isprint function

(define (cisprint  _c)
  "Return 1 if the 8-bit integer C maps to a printing character, else 0."
  (let ((c (%cchar _c)))
    (if (and c (isprint? c))
	1 0)))

(define (isprint? c)
  "Return #t if C a printing character: a graphic character or space.
Unlike Guile's char-set:printing, this excludes tabs and newlines."
  (or (char=? c #\space)
      (char-set-contains? char-set:graphic c)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.1.8 The ispunct function

(define (cispunct  _c)
  "Return 1 if the 8-bit integer C maps to a punctuation character, else 0."
  (let ((c (%cchar _c)))
    (if (and c (ispunct? c))
	1 0)))

(define (ispunct? c)
  "Return #t if C a punctuation character.  As in C, this is any
graphic character that is not alphanumeric, so it includes symbols such
as $, + and ~."
  (and (char-set-contains? char-set:graphic c)
       (not (char-set-contains? char-set:letter+digit c))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.1.10 The isspace function

(define (cisspace  _c)
  "Return 1 if the 8-bit integer C maps to a whitespace character, else 0."
  (let ((c (%cchar _c)))
    (if (and c (char-set-contains? char-set:whitespace c))
	1 0)))

(define (isspace? c)
  "Return #t if C is a whitespace character."
   (char-set-contains? char-set:whitespace c))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.1.11 The isupper function

(define (cisupper _c)
  "Return 1 if the 8-bit integer C maps to an uppercase character, else 0."
  (let ((c (%cchar _c)))
    (if (and c (char-set-contains? char-set:upper-case c))
	1 0)))

(define (isupper? c)
  "Return #t if C is an uppercase character."
   (char-set-contains? char-set:upper-case c))

(define cissupper cisupper)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.1.12 The isxdigit function

(define (cisxdigit _c)
  "Return 1 if the 8-bit integer C maps to a hexadecimal-digit
character, else 0."
  (let ((c (%cchar _c)))
    (if (and c (char-set-contains? char-set:hex-digit c))
	1 0)))

(define (isxdigit? c)
  "Return #t if C is a hexadecimal digit."
   (char-set-contains? char-set:hex-digit c))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.2.1 The tolower function

(define (ctolower _c)
  "Return the 8-bit integer representation of the lower-case letter
to which the 8-bit integer maps.  As in C, if there is no such letter,
the argument is returned unchanged."
  (let* ((c (%cchar _c))
	 (L (and c (%char->cchar (char-downcase c)))))
    (or L _c)))

(define (tolower c)
  (char-downcase c))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.4.2.2 The toupper function

(define (ctoupper _c)
  "Return the 8-bit integer representation of the upper-case letter
to which the 8-bit integer maps.  As in C, if there is no such letter,
the argument is returned unchanged."
  (let* ((c (%cchar _c))
	 (L (and c (%char->cchar (char-upcase c)))))
    (or L _c)))

(define (toupper c)
  (char-upcase c))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.5 Errors <errno.h>

;; ERRNO - There isn't really a good way to directly access
;; the underlying errno.

;; E2BIG, EACCESS, ..., EXDEV - most of these contstants
;; exist in core Guile.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.6 Floating-point environment <fenv.h>

;; Almost everyting in <fenv.h> has no analog in core Guile.
;; Access to the details of floating point numbers is hidden.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.7 Characteristics of floating types <float.h>

;; Details about the floating point numbers in core Guile is
;; supposed to be hidden.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.8 Format conversion of integger types <inttypes.h>

;; Some of these format specifiers might be useful for
;; a fully specified printf command

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.8.2.1 The imaxabs function

(define (imaxabs j)
  "Compute the absolute value of integer j."
  (abs j))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.8.2.2 The imaxdiv function

(define (imaxdiv numer denom)
  "Return a pair containing the quotient and the remainder of the
integer division of NUMER by DENOM.  As in C, the quotient is truncated
toward zero."
  (cons (quotient numer denom) (remainder numer denom)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.8.2.3 The strtoimax and strtoumax functions

(define* (strtoimax-idx _str #:optional (base 0))
  "Convert STR to an integer, assuming BASE. BASE is either 0, or 2 to
36, with a default value of 0.

If BASE is 0, the number will assumed to be base-16 if it starts with
0x or 0X, base 8 if it starts with 0, or base 10 otherwise.

Will return a a pair.  The car is the integer value, or zero if no
conversion can be returned.  The cdr is the number of characters
processed.  Values out of range are clamped to INT64_MIN or INT64_MAX."
  (%strto-idx _str base INT64_MIN INT64_MAX))

(define* (strtoimax _str #:optional (base 0))
  "Convert STR to an integer, assuming BASE. BASE is either 0, or 2 to
36, with a default value of 0.

If BASE is 0, the number will assumed to be base-16 if it starts with
0x or 0X, base 8 if it starts with 0, or base 10 otherwise.

Will return an integer value, or zero if no conversion can be
returned."
  (car (strtoimax-idx _str base)))

(define* (strtoumax-idx _str #:optional (base 0))
  "Like STRTOIMAX-IDX, but for unsigned values.  As in C, a negative
number is negated in the unsigned type, and values out of range
are clamped to UINT64_MAX."
  (%strto-idx _str base #f UINT64_MAX))

(define* (strtoumax _str #:optional (base 0))
  "Like STRTOIMAX, but for unsigned values."
  (car (strtoumax-idx _str base)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.9 Alternative spellings <iso646.h>

;; This syntactic sugar is rarely used.
;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.10 Sizes of integer types <limits.h>

;; Details about the limits of integers isn't often relevant
;; in Guile.

(define INT_MIN (signed-limit-neg (sizeof int)))
(define INT_MAX (signed-limit (sizeof int)))
(define UINT_MAX (unsigned-limit (sizeof unsigned-int)))
(define LONG_MIN (signed-limit-neg (sizeof long)))
(define LONG_MAX (signed-limit (sizeof long)))
(define ULONG_MAX (unsigned-limit (sizeof unsigned-long)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.11 Localization <locale.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.11.1.1 The setlocale function

;; SETLOCALE - there is a good SETLOCALE in core Guile

;; LC_ALL, LC_COLLATE, LC_CTYPE, LC_MONETARY, LC_NUMERIC,
;; and LC_TIME are all defined in core Guile.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.11.2.1 The localeconv function

;; LOCALECONV - in C, this returns a pointer to a structure
;; with locale information.  Of course, pointers to structures
;; don't translate well to Guile.  One could return a list
;; of locale information, like in the procedure below.
(define (localeconv)
  "Return a list that contains numeric and monetary formatting
rules for the current locale."
  (let ((loc %global-locale))
    (list
     (cons 'decimal-point (locale-decimal-point loc))
     (cons 'thousands-separator (locale-thousands-separator loc))
     (cons 'grouping (locale-digit-grouping loc))
     (cons 'mon-decimal-point (locale-monetary-decimal-point loc))
     (cons 'mon-thousands-sep (locale-monetary-thousands-separator loc))
     (cons 'mon-grouping (locale-monetary-grouping loc))
     (cons 'positive-sign (locale-monetary-positive-sign loc))
     (cons 'negative-sign (locale-monetary-negative-sign loc))

     (cons 'currency-symbol (locale-currency-symbol #f loc))
     (cons 'monetary-fractional-digits
	   (locale-monetary-fractional-digits #f loc))
     (cons 'p-cs-precedes
	   (locale-currency-symbol-precedes-positive? #f loc))
     (cons 'n-cs-precedes
	   (locale-currency-symbol-precedes-negative? #f loc))
     (cons 'p-sep-by-space
	   (locale-positive-separated-by-space? #f loc))
     (cons 'n-sep-by-space
	   (locale-negative-separated-by-space? #f loc))
     (cons 'p-sign-posn (locale-positive-sign-position #f loc))
     (cons 'n-sign-posn (locale-negative-sign-position #f loc))

     (cons 'int-curr-symbol (locale-currency-symbol #t loc))
     (cons 'int-frac-digits
	   (locale-monetary-fractional-digits #t loc))
     (cons 'int-p-cs-precedes
	   (locale-currency-symbol-precedes-positive? #t loc))
     (cons 'int-n-cs-precedes
	   (locale-currency-symbol-precedes-negative? #t loc))
     (cons 'int-p-sep-by-space
	   (locale-positive-separated-by-space? #t loc))
     (cons 'int-n-sep-by-space
	   (locale-negative-separated-by-space? #t loc))
     (cons 'int-p-sign-posn (locale-positive-sign-position #t loc))
     (cons 'int-n-sign-posn (locale-negative-sign-position #t loc)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.12.3.2 The isfinite macro

(define (cisfinite x)
  "Return 1 if X is finite, else 0."
  (if (finite? x) 1 0))

(define (isfinite? x)
  "Return #t if X is finite, else #f."
  (finite? x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.12.3.3 The isinf macro

(define (cisinf x)
  "Return 1 if X is infinite, else 0."
  (if (inf? x) 1 0))

(define (isinf? x)
  "Return #t if X is infinite, else #f."
  (inf? x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.12.3.4 The isnan macro

(define (cisnan x)
  "Return 1 if X is +nan.0, else 0."
  (if (nan? x) 1 0))

(define (isnan? x)
  "Return #t if X is +nan.0, else #f."
  (nan? x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.12.3.5 The isnormal macro

(define DBL_MIN 2.2250738585072014e-308) ; smallest normal double

(define (isnormal? x)
  "Return #t if the number X is neither zero, subnormal, infinite,
or NaN.  Else #f"
  (and (not (nan? x))
       (not (inf? x))
       (>= (abs x) DBL_MIN)))

(define (cisnormal x)
  "Return 1 is X is neither zero, subnormal, infinite, or NaN.
Else 0."
  (if (isnormal? x) 1 0))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.12.3.6 The signbit macro

(define (signbit x)
  "Return #t if the sign of X is negative.  Unlike (< x 0), this is
true for -0.0 and for NaNs with the sign bit set."
  (if (and (inexact? x) (real? x))
      (let ((bv (make-bytevector 8)))
	(bytevector-ieee-double-set! bv 0 x (endianness big))
	(logbit? 7 (bytevector-u8-ref bv 0)))
      (< x 0)))

(define (csignbit x)
  "Return 1 if the sign of X is negative. Else 0."
  (if (signbit x) 1 0))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.12.4.1 The acos functions
;; 7.12.4.2 The asin functions
;; 7.12.4.3 The atan functions
;; 7.12.4.4 The atan2 functions

(define (atan2 y x)
  "Computes the arctangent of y/x."
  (atan y x))

;; 7.12.4.5 The cos functions
;; 7.12.4.6 The sin functions
;; 7.12.4.7 The tan functions
;; 7.12.5.1 The acos functions
;; 7.12.5.2 The asinh functions
;; 7.12.5.3 The atanh functions
;; 7.12.5.4 The cosh functions
;; 7.12.5.5 The sinh functions
;; 7.12.5.6 The tanh functions
;; 7.12.6.1 The exp functions
;; 7.12.6.2 The exp2 functions

(define (exp2 x)
  "Compute the base-2 exponential of x."
  (expt 2.0 x))

;; 7.12.6.3 The expm1 functions

(define (expm1 x)
  "Computes the base-e exponential of the argument, minus 1.  This is
accurate even when X is close to zero."
  ;; Kahan's trick: the rounding errors in U and in (log U) cancel.
  (let ((u (exp (exact->inexact x))))
    (cond
     ((= u 1.0) (exact->inexact x))
     ((= (- u 1.0) -1.0) -1.0)
     ((inf? u) u)
     (else (/ (* (- u 1.0) x) (log u))))))

;; 7.12.6.4 The frexp functions

(define (binary-exponent q)
  "For a positive exact rational Q, return the integer E such that
2^E <= Q < 2^(E+1)."
  (let loop ((e (- (integer-length (numerator q))
		   (integer-length (denominator q)))))
    (cond
     ((< q (expt 2 e)) (loop (1- e)))
     ((>= q (expt 2 (1+ e))) (loop (1+ e)))
     (else e))))

(define (frexp val)
  "Returns VAL broken into a normalized fraction and an integral power
of 2, as a pair (FRACTION . EXPONENT).  The magnitude of FRACTION is
in [0.5, 1), and VAL = FRACTION * 2^EXPONENT.  If VAL is zero, infinite,
or NaN, FRACTION is VAL and EXPONENT is 0."
  (let ((x (exact->inexact val)))
    (if (or (zero? x) (inf? x) (nan? x))
	(cons x 0)
	(let* ((q (inexact->exact (abs x)))
	       (e (1+ (binary-exponent q)))
	       (frac (exact->inexact (/ q (expt 2 e)))))
	  (cons (if (< x 0) (- frac) frac) e)))))

;; 7.12.11.1 The copysign functions

(define (copysign x y)
  "Return a value with the magnitude of X and the sign of Y. Y should not be
complex."
  (let ((m (magnitude x)))
    (if (signbit y)
	(- m)
	m)))

;; 7.12.11.2 The nan functions
;; In C, nan returns a double-valued NaN.
;; nanf returns a float-valued NaN.
;; nanl returns a long-double-valued NaN.
;; Guile only has +nan.0, and has a procedure (nan)
;; that generates one.
(define (cnan tag)
  "Returns a not-a-number of type TAG.  But, Guile +nan.0
values don't have a tag, so it just returns +nan.0,
and the string TAG is ignore."
  (nan))

;; 7.12.14.5 The islessgreater macro
;; This is a type of not equals function for floating point
;; numbers
(define (cislessgreater x y)
  "Return 1 if the inexact numbers X and Y are not equal
within floating point precision.  Otherwise return 0."
  (let ((x2 (if (exact? x)
		(exact->inexact x)
		x))
	(y2 (if (exact? y)
		(exact->inexact y)
		y)))
    (if (or (< x2 y2) (> x2 y2))
	1
	0)))

(define (islessgreater x y)
  "Return #t if the inexact numbers X and Y are not equal within
floating point precision. Otherwise return #f."
  (let ((x2 (if (exact? x)
		(exact->inexact x)
		x))
	(y2 (if (exact? y)
		(exact->inexact y)
		y)))
    (or (< x2 y2) (> x2 y2))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.13 Nonlocal jumps
;;
;; jmp_buf and setjmp are rather like
;; call-with-prompt and abort-to-prompt

;; 7.13.1.1 The setjmp macro
;; 7.13.2.1 The longjmp function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.14 Signal handling

;; 7.14.1.1 The signal function
(define (signal sig func)
  "Install FUNC as a signal handler for SIG.
FUNC may be SIG_DFL or SIG_IGN. Returns the previous signal
handler."
  (let ((prev (car (sigaction sig))))
    (sigaction sig func)
    prev))

;; 7.14.2.1 The raise function
;; The C version of raise returns 0 on success or nonzero on error.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.15 Alignment <stdalign.h>
;;
;; The alignas macro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.16 Variable arguments <stdarg.h>
;;
;; Lots of ways to work around this in Scheme

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.17 Atomics <stdatomic.h>
;;
;; Use atomic-box functions from (ice-9 atomic)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.18 Boolean type and values
(define ctrue 1)

(define cfalse 0)

(define (->cbool x)
  "Returns 0 if x if #f, else it returns 1."
  (if x 1 0))

(define (cbool->bool x)
  "Returns #f if x is zero. Else returns #t."
  (if (zero? x) #f #t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.19 Common definitions <stddef.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.20 Integer types <stdint.h>

;; 7.20.2.1 Limits of exact-width integers

(define INT8_MIN (signed-limit-neg (sizeof int8)))
(define INT8_MAX (signed-limit (sizeof int8)))
(define UINT8_MAX (unsigned-limit (sizeof uint8)))

(define INT16_MIN (signed-limit-neg (sizeof int16)))
(define INT16_MAX (signed-limit (sizeof int16)))
(define UINT16_MAX (unsigned-limit (sizeof uint16)))

(define INT32_MIN (signed-limit-neg (sizeof int32)))
(define INT32_MAX (signed-limit (sizeof int32)))
(define UINT32_MAX (unsigned-limit (sizeof uint32)))

(define INT64_MIN (signed-limit-neg (sizeof int64)))
(define INT64_MAX (signed-limit (sizeof int64)))
(define UINT64_MAX (unsigned-limit (sizeof uint64)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7.21 Input/output <stdio.h>

;; 7.21.4.1 The remove function
;; The remove function in C is the same as the delete-file
;; function in core Guile.  There is an SRFI-1 'remove'
;; which operates on lists.
(define (remove fname)
  "Delete the file whose path is specified by FNAME."
  (delete-file fname))

;; 7.21.4.2 The rename function
(define (rename old new)
  "Rename causes the file whose name is the string OLD to
be known by the name NEW."
  (rename-file old new))

;; 7.21.4.3 The tmpfile function
;; Returns a file pointer opened for update in "wb+" mode
;; and that will be closed if the program terminates normally.

;; 7.21.4.4 The tmpnam function
;; In core Guile

;; 7.21.5.1 The fclose function
(define (fclose port)
  (if (not (file-port? port))
      (error "not a file port: ~a" port)
      (begin
	(when (output-port? port)
	  (force-output port))
	(close-port port))))

;; 7.21.5.2 The fflush function
;; Causes any unwritten data to be delivered.
(define (fflush port)
  (if (not port)
      (flush-all-ports)
      ;; else
      (begin
	(if (not (file-port? port))
	    (error "not a file port: ~a" port))
	(when (output-port? port)
	  (force-output port)))))

;; 7.21.5.3 The fopen function
(define (fopen filename mode)
  "Open a file port assuming the current global locale."
  (open-file filename mode #:encoding (locale-encoding
				       %global-locale)))

;; 7.21.5.4 The freopen function
;; 7.21.5.5 The setbuf function
;; 7.21.5.6 The setvbuf function

;; There is one in core Guile.

;; 7.21.6 Formatted input/output

;; 7.21.6.1 The fprintf functions
;; Defined in (ryu printf)

;; 7.21.6.2 The fscanf function

;; 7.21.6.3 The printf function
;; Defined in (ryu printf)

;; 7.21.6.4 The scanf function

;; 7.21.6.5 The snprintf function

;; Sets the variable S to the formatted output created by the format
;; string and its arguments, truncated to N - 1 characters (in C, the
;; Nth byte holds the terminating null).  Returns the length of the
;; untruncated formatted output.  N may be zero, in which case S is
;; not modified.

(define-syntax snprintf
  (syntax-rules ()
    ((_ s n format arg ...)
     (let* ((out (asprintf format arg ...))
	    (outlen (string-length out)))
       (unless (zero? n)
	 (set! s (substring out 0 (min outlen (1- n)))))
       outlen))))

;; 7.21.6.6 The sprintf function

;; Sets the string S to the formatted output created by the format
;; string and its arguments. Returns the length of the formatted
;; output.

(define-syntax sprintf
  (syntax-rules ()
    ((_ s format arg ...)
     (let ((out (asprintf format arg ...)))
       (set! s out)
       (string-length out)))))

#!
(define FLAG_GROUP 1)
(define FLAG_LEFT 2)
(define FLAG_SHOWSIGN 4)
(define FLAG_SPACE 8)
(define FLAG_ALT 16)
(define FLAG_ZERO 32)
(define FLAG_LOCALIZED 64)

(define ARG_NONE -1)

(define-record-type <format-directive>
  (make-format-directive dir-start dir-end flags width-start width-end
			 width-arg-index precision-start precision-end
			 precision-arg-index conversion arg-index)
  format-directive?
  dir-start
  dir-end
  flags
  width-start
  width-end
  width-arg-index
  precision-start
  precision-end
  precision-arg-index
  conversion
  arg-index)

(define (new-format-directive index)
  (make-format-directive index ARG_NONE ARG_NONE ARG_NONE ARG_NONE
			 ARG_NONE ARG_NONE ARG_NONE ARG_NONE))

(define (populatate-directives str)
  (let loop ((index 0))
    (if (not (eqv? #\null (string-ref-safe str index)))
	(let ((dp (new-format-directive)))))))
!#

;; 7.21.6.2 The fscanf function
;; 7.21.6.3 The printf function
;; 7.21.6.4 The scanf function
;; 7.21.6.5 The sprintf function
;; 7.21.6.6 The sprintf function
;; 7.21.6.7 The sscanf function
;; 7.21.6.8 The vfprintf function
;; 7.21.6.9 the vfscanf function
;; 7.21.6.10 The vprintf function
;; 7.21.6.11 The vscanf function
;; 7.21.6.12 The vsnprintf function
;; 7.21.6.13 The vsprintf function
;; 7.21.6.14 The vsscanf function
;; 7.21.7.1 The fgetc function
(define (fgetc port)
  (read-char port))

;; 7.21.7.2 The fgets function
(define (fgets str n port)
  "Read at most N - 1 characters from PORT, stopping after a newline,
which is kept.  Copy that text into the start of the mutable string
STR, as far as it fits.  Returns the text read, or #f if no characters
could be read before the end of file."
  (let loop ((chars '())
	     (count 0))
    (if (>= count (1- n))
	(%fgets-finish str chars)
	(let ((c (read-char port)))
	  (cond
	   ((eof-object? c)
	    (if (null? chars) #f (%fgets-finish str chars)))
	   ((char=? c #\newline)
	    (%fgets-finish str (cons c chars)))
	   (else
	    (loop (cons c chars) (1+ count))))))))

(define (%fgets-finish str chars)
  (let ((x (list->string (reverse chars))))
    (string-copy! str 0 x 0 (min (string-length str) (string-length x)))
    x))



;; 7.21.8.1 The fread function
;; 7.21.8.2 The fwrite function
;; 7.21.9.1 The fgetpos function
;; 7.21.9.2 The fseek function
;; 7.21.9.3 The fsetpos function

;; 7.21.9.4 The ftell function
;; This is in core Guile

;; 7.21.9.5 The rewind function
(define (rewind fd_port)
  "Sets the current position of a FD_PORT to the beginning of the
file."
  (seek fd_port 0 SEEK_SET))

;; 7.21.10.1 The clearerr function

;; 7.21.10.2 The feof function
;; Returns the end of file indicator for a stream.

;; 7.21.10.3 The ferror function
;; The ferror function returns non-sero if the error indicator
;; is set for a given FILE *stream.

;; 7.21.10.4 The perror function
;; There is no good way to access the current errno, so
;; it is hard to implement perror.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <stdlib.h>

;; 7.22
(define RAND_MAX 2147483647)

(define EXIT_SUCCESS 0)
(define EXIT_FAILURE 1)

;; 7.22.1.1 The atof function

(define (atof str)
  "Convert STR into a real number if STR begins with a base-10 real
number in the C locale representation. Initial whitespace is
ignored. Return 0.0 if STR does not begin with a number.  Any
characters after the number are ignored."
  (car (strtod str)))

;; 7.22.1.2 The atoi, atol, and atoll functions

(define (atoi _str)
  "Search the beginning of _str for a base-10 integer.  Return
the value if found, or 0 otherwise."
  (strtol _str 10))

;; 7.22.1.3 The strtod, strtof, and strtold functions
(define *infinity-match*
  (make-regexp
   "^[-+]?(INF|INFINITY)" regexp/icase))

(define *nan-match*
  (make-regexp
   "^[-+]?(NAN|NAN\\([_a-z0-9]+\\))" regexp/icase))

;; A regular expression for a base-10 floating point that may use 'e'
;; or 'E' as the exponent indicator.
(define *floating-point-match*
  (make-regexp
   "^[-+]?([0-9]+(\\.[0-9]*)?|\\.[0-9]+)(e[-+]?[0-9]+)?" regexp/icase))

(define *hex-floating-point-match*
  (make-regexp
   "^[-+]?0x([0-9a-f]+(\\.[0-9a-f]*)?|\\.[0-9a-f]+)(p[-+]?[0-9]+)?" regexp/icase))

(define (remove-zero-x str)
  "Strip a '0x' or '0X' from a potential hexadecimal number."
  (cond
   ((eqv? #\+ (string-ref str 0))
    (string-drop str 3))
   ((eqv? #\- (string-ref str 0))
    (string-append "-" (string-drop str 3)))
   (else
    (string-drop str 2))))

(define (hexstr->number _str)
  "Convert a string containing a hexadecimal floating point number
with optional exponent into a number."
  (let ((str (string-copy _str))
	(sign 1)
	(significand 0)
	(fractional 0)
	(exponent 0))
    ;; First, there may be a sign
    (let ((c (string-ref str 0)))
      (cond
       ((eqv? #\+ c)
	(set! sign 1)
	(set! str (string-drop str 1)))
       ((eqv? #\- c)
	(set! sign -1)
	(set! str (string-drop str 1)))))
    ;; Next, there is either a decimal point or the integer part of
    ;; the significand.
    (let ((decimal-point-location (string-contains str "."))
	  (exponent-location (string-contains-ci str "p"))
	  (significand-str "")
	  (fractional-str "")
	  (exponent-str ""))
      (cond
       ((and (not decimal-point-location) (not exponent-location))
	(set! significand-str str))
       ((and decimal-point-location (not exponent-location))
	(set! significand-str (substring str 0 decimal-point-location))
	(set! fractional-str (substring str (1+ decimal-point-location))))
       ((and (not decimal-point-location) exponent-location)
	(set! significand-str (substring str 0 exponent-location))
	(set! exponent-str (substring str (1+ exponent-location))))
       ((and decimal-point-location exponent-location)
	(set! significand-str (substring str 0 decimal-point-location))
	(set! fractional-str (substring str (1+ decimal-point-location) exponent-location))
	(set! exponent-str (substring str (1+ exponent-location)))))

      ;; Extract the numeric parts.
      ;; If there is no significand in the string, use zero.
      (set! significand (or (string->number significand-str 16) 0))

      ;; These may be #f if they don't appear
      (set! fractional (string->number fractional-str 16))
      (set! exponent (string->number exponent-str 10))

      (cond
       ((and (not fractional) (not exponent))
	;; Return an integer value
	(* sign significand))
       ((and fractional (not exponent))
	;; Return a floating point value
	(* sign (+ significand
		   (/ fractional
		      (expt 16 (string-length fractional-str))))))
       ((and (not fractional) exponent)
	;; Integer.  The exponent is a power of 2.
	(* sign significand (expt 2 exponent)))
       (else
	;; Floating point
	(* sign
	   (+ significand
	      (/ fractional (expt 16 (string-length fractional-str))))
	   (expt 2 exponent)))))))

(define (%c-whitespace? c)
  (memv c '(#\space #\tab #\newline #\vtab #\page #\return)))

(define (%skip-whitespace str)
  "Return the index of the first non-whitespace character in STR."
  (or (string-index str (lambda (c) (not (%c-whitespace? c))))
      (string-length str)))

(define (%negative-prefix? str)
  (and (> (string-length str) 0) (char=? (string-ref str 0) #\-)))

(define (%->inexact x negative?)
  "Convert the exact value X to a float, keeping the sign of zero."
  (let ((y (exact->inexact x)))
    (if (and negative? (zero? y)) -0.0 y)))

(define (%decimal->exact str)
  "Parse the decimal floating-point string STR exactly, so that rounding
to a float happens only once.  Huge exponents are clamped, since they
over- or underflow anyway."
  (let* ((epos (string-index str (char-set #\e #\E)))
	 (mant (string->number (string-append "#e" (if epos (substring str 0 epos) str))))
	 (ex (if epos (string->number (substring str (1+ epos))) 0)))
    (* mant (expt 10 (max -10000 (min 10000 ex))))))

(define (strtod str)
  "Convert STR into a real number, returning a pair of the number
and a string containing the unused characters after the number.
Leading whitespace is skipped. The number is one of the the following
forms
- an optional plus or minus followed by INF or INFINITY, ignoring case
- an optional plus or minus followed by NAN, ignoring case.
- A string of the form NAN(<type>), where <type> is a string containing
  alphanumeric or underscore characters.
- a base-10 decimal floating point
- a base-16 float starting with 0x or 0X and using p or P as
  the exponent separator.
If no number can be found, the result is 0.0, and the unused
characters are the whole of STR."
  (let* ((s (substring str (%skip-whitespace str)))
	 (neg (%negative-prefix? s)))
    (define (result m val)
      (cons val (substring s (match:end m))))
    (cond
     ((regexp-exec *hex-floating-point-match* s)
      => (lambda (m)
	   (result m (%->inexact
		      (hexstr->number (remove-zero-x (match:substring m)))
		      neg))))
     ((regexp-exec *floating-point-match* s)
      => (lambda (m)
	   ;; Parse the digits exactly, so that rounding happens only once.
	   (result m (%->inexact (%decimal->exact (match:substring m)) neg))))
     ((regexp-exec *infinity-match* s)
      => (lambda (m) (result m (if neg (- (inf)) (inf)))))
     ((regexp-exec *nan-match* s)
      => (lambda (m) (result m (nan))))
     (else
      (cons 0.0 str)))))

(define (strtof str)
  "Like STRTOD, but the number is rounded to single precision."
  (let ((ret (strtod str))
	(bv (make-bytevector 4)))
    (bytevector-ieee-single-native-set! bv 0 (car ret))
    (cons (bytevector-ieee-single-native-ref bv 0) (cdr ret))))

;; 7.22.1.4 The strtol, strtoll, strtoul, strtoull functions

(define (string-ref-safe str i)
  "A version of string-ref that returns a null character
if the index is out of bounds."
  (if (< i (string-length str))
      (string-ref str i)
      #\null))

(define (%digit-value c)
  (cond
   ((char<=? #\0 c #\9) (- (char->integer c) (char->integer #\0)))
   ((char<=? #\A c #\Z) (+ 10 (- (char->integer c) (char->integer #\A))))
   ((char<=? #\a c #\z) (+ 10 (- (char->integer c) (char->integer #\a))))
   (else #f)))

(define (%strto-idx str base lo hi)
  "Common code for the strtol family.  Parse an integer at the start of
STR in BASE, then clamp it to [LO, HI].  If LO is #f, the conversion is
unsigned: a negative value is negated modulo HI + 1.  Return a pair of
the value and the index just after the last character used, or
(0 . 0) if there is no number."
  (unless (or (= base 0) (<= 2 base 36))
    (scm-error 'out-of-range "strtol" "invalid base ~a" (list base) (list base)))
  (let* ((len (string-length str))
	 (start (%skip-whitespace str))
	 (neg (and (< start len) (char=? (string-ref str start) #\-)))
	 (i (if (and (< start len) (memv (string-ref str start) '(#\- #\+)))
		(1+ start)
		start))
	 (digit-at (lambda (k b)
		     (and (< k len)
			  (let ((v (%digit-value (string-ref str k))))
			    (and v (< v b) v)))))
	 ;; A 0x prefix only counts if a hex digit follows it.
	 (hex-prefix? (and (memv base '(0 16))
			   (< (1+ i) len)
			   (char=? (string-ref str i) #\0)
			   (char-ci=? (string-ref str (1+ i)) #\x)
			   (digit-at (+ i 2) 16)))
	 (base (cond
		(hex-prefix? 16)
		((not (= base 0)) base)
		((and (< i len) (char=? (string-ref str i) #\0)) 8)
		(else 10)))
	 (i (if hex-prefix? (+ i 2) i)))
    (let loop ((k i) (acc 0))
      (let ((v (digit-at k base)))
	(cond
	 (v
	  (loop (1+ k) (+ (* acc base) v)))
	 ((= k i)
	  ;; No digits at all.
	  (cons 0 0))
	 (else
	  (let ((val (if neg (- acc) acc)))
	    (cons (cond
		   ((not lo)
		    (if (> acc hi) hi (modulo val (1+ hi))))
		   ((< val lo) lo)
		   ((> val hi) hi)
		   (else val))
		  k))))))))

(define* (strtol _str #:optional (base 0))
  "Convert STR to an integer, assuming BASE. BASE is either 0, or 2 to
36, with a default value of 0.

If BASE is 0, the number will assumed to be base-16 if it starts with
0x or 0X, base 8 if it starts with 0, or base 10 otherwise.

Will return an integer value, or zero if no conversion can be
returned."
  (car (strtol-idx _str base)))

(define* (strtol-idx _str #:optional (base 0))
  "Convert STR to an integer, assuming BASE. BASE is either 0, or 2 to
36, with a default value of 0.

If BASE is 0, the number will assumed to be base-16 if it starts with
0x or 0X, base 8 if it starts with 0, or base 10 otherwise.

Will return a a pair.  The car is the integer value, or zero if no
conversion can be returned.  The cdr is the index in STR just after
the number, or zero if there is no number.  As in C, values out of
range are clamped to LONG_MIN or LONG_MAX."
  (%strto-idx _str base LONG_MIN LONG_MAX))

(define* (strtoul _str #:optional (base 0))
  "Like STRTOL, but for unsigned long values."
  (car (strtoul-idx _str base)))

(define* (strtoul-idx _str #:optional (base 0))
  "Like STRTOL-IDX, but for unsigned long values.  As in C, a negative
number is negated in the unsigned type, and values out of range are
clamped to ULONG_MAX."
  (%strto-idx _str base #f ULONG_MAX))

;; 7.22.2.1 The rand function
(define *local-random-state* #f)

(define (rand)
  "Retun a random number between 0 and RAND_MAX"
  (if *local-random-state*
      (random (1+ RAND_MAX) *local-random-state*)
      (random (1+ RAND_MAX))))

;; 7.22.2.2 The srand function

(define (srand x)
  "Seed the random state used by 'rand'."
  (set! *local-random-state* (seed->random-state x)))

;; 7.22.3.1 The aligned_alloc function

;; 7.22.3.2 The calloc function
(define (calloc size1 size2)
  "Return a bytevector, initialize to zero whose size
is size1 * size2."
  (make-bytevector (* size1 size2) 0))

;; 7.22.3.3 The free function

;; 7.22.3.4 The malloc function

(define (malloc len)
  "Return a bytevector containing SIZE bytes, whose values are not
specified."
  (make-bytevector len))

;; 7.22.3.5 The realloc function

(define (realloc bv len)
  "Return a new bytevector of length LEN, with the contents set
to the contents of the bytevector BV.  If BV is shorter than LEN,
the extra bytes in BV will be undetermined."
  (let ((bv2 (make-bytevector len)))
    (bytevector-copy! bv 0 bv2 0 (min (bytevector-length bv) len))
    bv2))

;; 7.22.4.1 The abort function

(define (abort)
  "This procedure causes abnormal program termination to occur,
unless the SIGABRT is being caught and the signal handler does not
return."
  (kill (getpid) SIGABRT)
  ;; Only reached if SIGABRT is caught and the handler returns.
  (primitive-_exit 134))

;; 7.22.4.2 The atexit function

;; 7.24.4.3 The at_quick_exit function

;; 7.22.4.4 The exit function

;; 7.22.4.5 The _Exit function

;; 7.22.4.6 The getenv function

;; 7.22.4.7 The quick_exit function

;; 7.22.4.8 The system function

;; 7.22.5.1 The bsearch function

;; 7.22.5.2 The qsort function

;; 7.22.6.1 The abs, labs, and llabs functions

;; 7.22.6.2 The div, ldiv, lldiv functions

(define (div num denom)
  (cons (quotient num denom)
	(remainder num denom)))

(define MB_LEN_MAX 16)

(define (%decode-first-char mbs)
  "Try to decode the first character of the bytevector MBS using the
current locale's encoding.  Return a pair of the character and the
number of bytes it uses, or #f."
  (let ((enc (locale-encoding %global-locale))
	(maxlen (min MB_LEN_MAX (bytevector-length mbs))))
    (let loop ((len 1))
      (if (> len maxlen)
	  #f
	  (let ((bv (make-bytevector len)))
	    (bytevector-copy! mbs 0 bv 0 len)
	    (let ((str (false-if-exception (bytevector->string bv enc 'error))))
	      (if (and str (= (string-length str) 1))
		  (cons (string-ref str 0) len)
		  ;; else, didn't convert, so keep looping
		  (loop (1+ len)))))))))

;; 7.22.7.1 The mblen function
(define (mblen mbs)
  "Compute the number of bytes required to extract the first
representation of a character in the current locale, or #f if the
first few bytes do not form a character in the current locale."
  (let ((ret (%decode-first-char mbs)))
    (and ret (cdr ret))))

;; 7.22.7.2 The mbtowc function
(define (mbtowc mbs)
  "Converts the first multibyte character byte sequence in the
bytevector into a corresponding character, interpreting the bytevector
bytes as an encoded string in the current locale.  It returns #f on a
conversion error."
  (let ((ret (%decode-first-char mbs)))
    (and ret (car ret))))

;; 7.22.7.3 The wctomb function
(define (wctomb wc)
  "Converts a character to a bytevector sequence of bytes that
represents the character in the current locale.  It returns #f on a
conversion error"
  (false-if-exception
   (string->bytevector (string wc)
		       (locale-encoding %global-locale)
		       'error)))

;; 7.22.8.1 The mbstowcs function
(define (mbstowcs mbs)
  "Converts the bytevector sequence of bytes mbs into a string and
returns the string.  It uses the current locale's encoding. It returns
#f on a conversion error."
  (false-if-exception
   (bytevector->string mbs (locale-encoding %global-locale) 'error)))

;; The wcstombs function

(define (wcstombs wcs)
  "Converts the string SRC to a locale-encoded bytevector in the
current global locale and returns the bytevector.  It returns #f on a
conversion error."
  (false-if-exception
   (string->bytevector wcs (locale-encoding %global-locale) 'error)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <stdnoreturn.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <string.h>

;; 7.24.2.1 The memcpy function
;; MEMCPY copies a block of raw memory from one location to another.
;; If we're using bytevector to hold raw blocks, it could be implemented
;; like the following.
(define (memcpy dest src count)
  (let ((end (min count (bytevector-length src) (bytevector-length dest))))
    (bytevector-copy! src 0 dest 0 end)
    dest))

;; 7.24.2.2 The memmove function
;; MEMMOVE copies a block of raw memory from one location to another, just
;; like MEMCPY, but, being smart about overlapping regions.  Since
;; BYTEVECTOR-COPY! already handles a bytevector copied onto itself,
;; MEMMOVE is the same as MEMCPY.
(define memmove memcpy)

;; 7.24.2.3 The strcpy function

(define (strcpy dest src)
  "Copies the contents of string SRC into string DEST.  If DEST is
shorter than SRC, then only (string-length DEST) characters of SRC are
copied.  If DEST is longer than SRC, the remaining characters of DEST
are unchanged.

Note that if DEST is not a writable string, such as one created with
'string-copy', this procedure will fail."
  (let ((srclen (string-length src))
	(destlen (string-length dest)))
    (substring-move! src 0 (min srclen destlen) dest 0)
    dest))

;; 7.24.2.4 The strncpy function

(define (strncpy dest src count)
  "Copies at most COUNT characters of the string SRC into DEST."
  (let ((srclen (string-length src))
	(destlen (string-length dest)))
    (substring-move! src 0 (min srclen destlen count) dest 0)
    ;; As in C, if SRC is shorter than COUNT, pad with nulls.
    (when (< srclen (min count destlen))
      (substring-fill! dest srclen (min count destlen) #\null))
    dest))

;; 7.24.3.1 The strcat function
;; strcat doesn't really work, since a string's storage is
;; the same as a string's length.  You can't copy past the end
;; of it.

;; 7.24.3.2 The strncat function
;; Since strings can't grow in place, this version returns a new
;; string.
(define (strncat dest src count)
  "Return a new string made of DEST followed by at most COUNT characters
of SRC."
  (string-append dest (substring src 0 (min count (string-length src)))))

;; 7.24.4.1 The memcmp function
;; MEMCMP is a binary comparison between two raw locations in memory.
;; If we're using bytevector to hold raw blocks, it could be
;; implemented like the following.
(define (memcmp a b count)
  "Compare the first COUNT bytes in bytevectors A and B, and return
-1, 0, or 1."
  (let ((alen (bytevector-length a))
	(blen (bytevector-length b)))
    (let loop ((i 0))
      (cond
       ((>= i count)
	0)
       ((>= i alen)
	-1)
       ((>= i blen)
	1)
       (else
	(let ((ach (bytevector-u8-ref a i))
	      (bch (bytevector-u8-ref b i)))
	  (cond
	   ((< ach bch)
	    -1)
	   ((> ach bch)
	    1)
	   (else
	    (loop (1+ i))))))))))

;; 7.24.4.2 The strcmp function
(define (strcmp a b)
  "Compares two strings lexicographically, returning -1, 0, or 1,
if A is less than, equal, or greater than B."
  (cond
   ((string<? a b)
    -1)
   ((string>? a b)
    1)
   (else
    0)))

;; 7.24.4.3 The strcoll function
;; Compares two strings using the current LC_COLLATE category
;; of the current locale, and returns -1, 0, or 1.
(define (strcoll a b)
  "Compares two strings using the current locale's collating rules,
 returning -1, 0, or 1, if A is less than, equal, or greater than B."
  (cond
   ((string-locale<? a b)
    -1)
   ((string-locale>? a b)
    1)
   (else
    0)))

;; 7.24.4.4. The strncmp function
(define (strncmp a b n)
  (strcmp (substring a 0 (min n (string-length a)))
	  (substring b 0 (min n (string-length b)))))

;; 7.24.4.5 The strxfrm function
;; strxfrm has no good analog with Guile strings.

;; 7.24.5.1 The memchr function

(define (memchr-idx bv c n)
  "Returns an index to the first location of the 8-bit unsigned byte C
in the bytevector BV.  If C doesn't occur in the first N bytes of BV,
#f is returned."
  (let ((maxlen (min (bytevector-length bv) n))
	(c2 (if (char? c)
		(char->integer c)
		c)))
    (let loop ((i 0))
      (if (>= i maxlen)
	  #f
	  ;; else
	  (if (eqv? c2 (bytevector-u8-ref bv i))
	      i
	      ;; else
	      (loop (1+ i)))))))

(define memchr memchr-idx)

;; 7.24.5.2 The strchr function
;; STRCHR doesn't really translate because it returns a pointer to the
;; first character, but, a good approimation is
;; (string-index STR CHAR)

(define (strchr-idx str c)
  "Return the index of the first occurrence of the character C in STR,
or #f."
  (string-index str c))

(define strchr strchr-idx)

;; 7.24.5.3 The strcspn function
(define (strcspn dest src)
  "Returns the length of the maximum initial segment of the DEST, that
consists of only the characters *not* found in SRC."
  (let ((charset (string->char-set src)))
    (or (string-index dest (lambda (c)
			     (char-set-contains? charset c)))
	(string-length dest))))

;; 7.24.5.4 The strpbrk function
;; STRPBRK doesn't translate because it returns a pointer.  It scans
;; the string DEST for any character in SRC, and returns a pointer
;; to that character.  Consider using the following version which
;; instead returns the index to the first matching character.  This
;; is identical to STRCSPN, above.
(define (strpbrk-idx dest src)
  "Return the index of the first character in DEST that is present
in SRC."
  (let ((charset (string->char-set src)))
    (string-index dest (lambda (c)
			 (char-set-contains? charset c)))))

(define strpbrk strpbrk-idx)

;; 7.24.5.5 The strrchr function
;; STRRCHR doesn't really translate bedcause it returns a pointer
;; to the last matching character.  A good approximation is
;; (string-index-right STR CHAR)
(define (strrchr-idx str c)
  "Locates the index to the last occurrence of c in the string STR."
  (string-index-right str c))

(define strrchr strrchr-idx)

;; 7.24.5.6 The strspn function
(define (strspn dest src)
  "Returns the length of the maximum intial segment (span) of DEST
that consists only of the characters that are found in SRC."
  (let ((charset (string->char-set src)))
    (or (string-index dest (lambda (c)
			     (not (char-set-contains? charset c))))
	(string-length dest))))

;; 7.24.5.7 The strstr function
;; STRSTR doesn't translate because it returns a pointer. It scans
;; DEST for an occurrence of the string SRC, returning a pointer
;; to the location of the beginning of the occurrence.  Consider
;; the following replacement
(define (strstr-idx dest src)
  "Return the index of the location where SRC appears in the string
DEST, or #f if the string STR can not be found in DEST."
  (string-contains dest src))

(define strstr strstr-idx)

;; 7.24.5.8 The strtok function
(define *strtok-rest* #f)

(define (strtok str delims)
  "Return the next token in STR, delimited by any character in the
string DELIMS, or #f if there are no more tokens.  As in C, call it
first with a string, and then with STR set to #f to get the following
tokens from the same string."
  (let* ((charset (string->char-set delims))
	 (s (or str *strtok-rest* ""))
	 (start (string-skip s charset)))
    (if (not start)
	(begin
	  (set! *strtok-rest* #f)
	  #f)
	(let ((end (string-index s charset start)))
	  (set! *strtok-rest* (and end (substring s (1+ end))))
	  (substring s start (or end (string-length s)))))))

;; 7.24.6.2 The memset function
;; MEMSET fills a raw location in memory.  If we're using bytevectors
;; to hold raw blocks, it could be implemented like the following.
(define (memset dest _ch count)
  "Fill the first COUNT bytes of bytevector DEST with CH, converted to
an unsigned 8-bit integer as in C.  Return DEST."
  (let ((end (min count (bytevector-length dest)))
	(ch (logand #xff (if (char? _ch) (char->integer _ch) _ch))))
    (do ((i 0 (1+ i)))
	((>= i end))
      (bytevector-u8-set! dest i ch))
    dest))

;; 7.24.6.2 The strerror function
;; STRERROR returns a text version of errno.  It exists in core Guile.

;; 7.24.6.3 The strlen function
(define (strlen str)
  "Return the length of STR."
  (string-length str))

(define (strnlen str n)
  "Return the length of STR, but at most N."
  (min n (string-length str)))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <math.h>





;; Most of these work on the exact rational value of a float, so that
;; they are exact, or correctly rounded.

(define (%finite-nonzero? x)
  (and (not (zero? x)) (not (inf? x)) (not (nan? x))))

(define (%float-exponent x)
  "For a finite, non-zero X, the exponent E such that 2^E <= |X| < 2^(E+1)."
  (binary-exponent (abs (inexact->exact x))))

(define FP_ILOGB0 INT_MIN)
(define FP_ILOGBNAN INT_MIN)

(define (ilogb x)
  "Return the binary exponent of X as an integer, so that 1 <= |X|/2^E < 2.
Returns FP_ILOGB0 for zero, FP_ILOGBNAN for NaN and INT_MAX for
infinities."
  (cond
   ((nan? x) FP_ILOGBNAN)
   ((inf? x) INT_MAX)
   ((zero? x) FP_ILOGB0)
   (else (%float-exponent x))))

(define (logb x)
  "Return the binary exponent of X as a float, so that 1 <= |X|/2^E < 2.
Returns -inf.0 for zero, +inf.0 for infinities, and NaN for NaN."
  (cond
   ((nan? x) x)
   ((inf? x) +inf.0)
   ((zero? x) -inf.0)
   (else (exact->inexact (%float-exponent x)))))

(define (ldexp x e)
  "Return X * 2^E, rounded once."
  (let ((x (exact->inexact x)))
    (if (%finite-nonzero? x)
	(let ((y (exact->inexact (* (inexact->exact x) (expt 2 e)))))
	  ;; Keep the sign of an underflow to zero.
	  (if (and (zero? y) (< x 0)) -0.0 y))
	x)))

(define (scalbn x n)
  "Return X * 2^N, rounded once.  The same as LDEXP, since floats are
binary."
  (ldexp x n))

;; With a real implementaion of log1p, it should be more accurate that
;; (log (1+ x))
(define (log1p x)
  "Compute the natural logarithm of X + 1.  This is accurate even when
X is close to zero."
  ;; The rounding errors in U and (log U) cancel.
  (let* ((x (exact->inexact x))
	 (u (+ 1.0 x)))
    (cond
     ((= u 1.0) x)
     ((inf? u) (log x))
     (else (* (log u) (/ x (- u 1.0)))))))

(define (log2 x)
  "Compute the base-2 logarithm of X.  It is exact for powers of two."
  (let ((x (exact->inexact x)))
    (cond
     ((nan? x) x)
     ((zero? x) -inf.0)
     ((< x 0) +nan.0)
     ((inf? x) x)
     ((< 0.5 x 2.0)
      ;; Near 1, x - 1 is exact, and log1p keeps the precision.
      (/ (log1p (- x 1.0)) (log 2.0)))
     (else
      (let* ((q (inexact->exact x))
	     (e (binary-exponent q))
	     (m (exact->inexact (/ q (expt 2 e)))))	; 1 <= m < 2
	(+ e (/ (log m) (log 2.0))))))))

(define (modf x)
  "Break X into its fractional and integral parts, both with the sign
of X.  Return them as a pair (FRACTION . INTEGER)."
  (let ((x (exact->inexact x)))
    (cond
     ((nan? x) (cons x x))
     ((inf? x) (cons (if (< x 0) -0.0 0.0) x))
     (else
      (let* ((i (truncate x))
	     (f (- x i)))
	(cons (if (signbit x) (- (abs f)) f)
	      i))))))

(define (cbrt x)
  "Compute the real cube root of X."
  (let ((x (exact->inexact x)))
    (if (not (%finite-nonzero? x))
	x
	;; Scale |x| by 2^(3k) into [1, 8), so that the Newton step can't
	;; overflow or underflow, then scale the root back by 2^k.
	(let* ((k (floor-quotient (%float-exponent x) 3))
	       (a (ldexp (abs x) (* -3 k)))
	       (y (expt a (/ 1.0 3.0)))
	       ;; One Newton step to fix the last bits.
	       (y (- y (/ (- (* y y y) a) (* 3.0 y y))))
	       (y (ldexp y k)))
	  (if (< x 0) (- y) y)))))

(define (hypot x y)
  "Compute the square root of X^2 + Y^2 without undue overflow or
underflow."
  (let ((x (abs (exact->inexact x)))
	(y (abs (exact->inexact y))))
    (cond
     ((or (inf? x) (inf? y)) +inf.0)
     ((or (nan? x) (nan? y)) +nan.0)
     (else
      (let ((a (max x y)))
	(if (zero? a)
	    0.0
	    ;; Scale by a power of 2 (which is exact) so that the
	    ;; exactly-computed sum of squares is near 1.
	    (let* ((k (%float-exponent a))
		   (qx (/ (inexact->exact x) (expt 2 k)))
		   (qy (/ (inexact->exact y) (expt 2 k))))
	      (ldexp (sqrt (exact->inexact (+ (* qx qx) (* qy qy)))) k))))))))

(define (pow x y)
  (expt x y))

(define (erf x)
  "Compute the error function of X."
  (let ((x (exact->inexact x)))
    (cond
     ((nan? x) x)
     ((zero? x) x)
     ((> (abs x) 6.0) (if (< x 0) -1.0 1.0))
     (else
      ;; erf(x) = 2/sqrt(pi) exp(-x^2) sum_{n>=0} 2^n x^(2n+1) / (1*3*...*(2n+1))
      ;; All terms are positive, so there is no cancellation.
      (let ((x2 (* x x)))
	(let loop ((n 0) (term x) (sum x))
	  (let* ((term (/ (* term 2.0 x2) (+ (* 2 n) 3)))
		 (sum2 (+ sum term)))
	    (if (= sum2 sum)
		(* (/ 2.0 (sqrt (* 4 (atan 1.0)))) (exp (- x2)) sum)
		(loop (1+ n) term sum2)))))))))

;; Lanczos approximation, g = 7, n = 9.
(define %lanczos-g 7)
(define %lanczos-coefficients
  '(0.99999999999980993
    676.5203681218851
    -1259.1392167224028
    771.32342877765313
    -176.61502916214059
    12.507343278686905
    -0.13857109526572012
    9.9843695780195716e-6
    1.5056327351493116e-7))

(define (%lanczos-sum z)
  "For Z = X - 1, the Lanczos series A(Z)."
  (let loop ((k 1)
	     (cs (cdr %lanczos-coefficients))
	     (acc (car %lanczos-coefficients)))
    (if (null? cs)
	acc
	(loop (1+ k) (cdr cs) (+ acc (/ (car cs) (+ z k)))))))

(define %pi (* 4 (atan 1.0)))

(define (%sinpi x)
  "Compute sin(pi X) accurately, even for large X near an integer."
  ;; X - 2 round(X/2) is exact, and lies in [-1, 1].
  (let ((r (- x (* 2.0 (round (/ x 2.0))))))
    (sin (* %pi r))))

(define (%zeta k)
  "The Riemann zeta function for integers K >= 2, by Euler-Maclaurin
summation."
  (let* ((n 50)
	 (head (let loop ((j 1) (acc 0.0))
		 (if (= j n) acc (loop (1+ j) (+ acc (expt (exact->inexact j) (- k)))))))
	 (nn (exact->inexact n)))
    (+ head
       (/ (expt nn (- 1 k)) (- k 1))
       (/ (expt nn (- k)) 2)
       (* (/ k 12) (expt nn (- (1+ k))))
       (- (* (/ (* k (+ k 1) (+ k 2)) 720) (expt nn (- (+ k 3)))))
       (* (/ (* k (+ k 1) (+ k 2) (+ k 3) (+ k 4)) 30240) (expt nn (- (+ k 5)))))))

(define %euler-gamma 0.57721566490153286)

(define %zetas
  ;; zeta(2) ... zeta(40)
  (let loop ((k 40) (acc '()))
    (if (< k 2) acc (loop (1- k) (cons (%zeta k) acc)))))

(define (%lgamma1p z)
  "lgamma(1 + Z) for small |Z|, by its Taylor series, which keeps the
relative precision near the zeros of lgamma at 1 and 2."
  (let loop ((k 2) (zs %zetas) (zk (* z z)) (acc (- (* %euler-gamma z))))
    (if (null? zs)
	acc
	(let ((term (/ (* (if (even? k) 1 -1) (car zs) zk) k)))
	  (if (< (abs term) (* 1e-18 (abs acc)))
	      acc
	      (loop (1+ k) (cdr zs) (* zk z) (+ acc term)))))))

(define (%stirling-series x)
  "The correction term of Stirling's series for lgamma, for X >= 10:
1/(12x) - 1/(360x^3) + 1/(1260x^5) - ..."
  (let ((x2 (* x x)))
    (/ (+ 1/12
	  (/ (+ -1/360
		(/ (+ 1/1260
		      (/ (+ -1/1680
			    (/ (+ 1/1188
				  (/ (+ -691/360360
					(/ 1/156 x2))
				     x2))
			       x2))
			 x2))
		   x2))
	     x2))
       x)))

(define (tgamma x)
  "Compute the gamma function of X.  For non-positive integers, which
are poles, it returns +inf.0 for zero and NaN otherwise."
  (let ((x (exact->inexact x)))
    (cond
     ((nan? x) x)
     ((= x +inf.0) x)
     ((= x -inf.0) +nan.0)
     ((zero? x) (if (signbit x) -inf.0 +inf.0))
     ((and (< x 0) (integer? x)) +nan.0)
     ((and (integer? x) (<= x 171))
      ;; Exact for positive integers.
      (exact->inexact
       (let loop ((k (inexact->exact x)) (acc 1))
	 (if (<= k 2) acc (loop (1- k) (* acc (1- k)))))))
     ((> x 171.7) +inf.0)
     ((< x 0.5)
      ;; Reflection: gamma(x) gamma(1 - x) = pi / sin(pi x)
      (/ %pi (* (%sinpi x) (tgamma (- 1.0 x)))))
     ((>= x 10.0)
      ;; Stirling: sqrt(2 pi) x^(x - 1/2) e^-x e^S(x).  The power is
      ;; split in two to avoid overflow.
      (let ((p (expt x (/ (- x 0.5) 2))))
	(* (sqrt (* 2 %pi)) p (/ p (exp x)) (exp (%stirling-series x)))))
     (else
      (let* ((z (- x 1.0))
	     (t (+ z %lanczos-g 0.5)))
	;; Split the power to avoid overflow for large X.
	(let ((p (expt t (/ (+ z 0.5) 2))))
	  (* (sqrt (* 2 %pi)) p (/ p (exp t)) (%lanczos-sum z))))))))

(define (lgamma x)
  "Compute the natural logarithm of the absolute value of the gamma
function of X.  It returns +inf.0 at the poles."
  (let ((x (exact->inexact x)))
    (cond
     ((nan? x) x)
     ((inf? x) +inf.0)
     ((and (<= x 0) (integer? x)) +inf.0)
     ((or (= x 1.0) (= x 2.0)) 0.0)
     ((< (abs x) 1e-8)
      ;; lgamma(x) = -log|x| - gamma x + O(x^2)
      (- (- (log (abs x))) (* %euler-gamma x)))
     ((< (abs (- x 1.0)) 0.25)
      (%lgamma1p (- x 1.0)))
     ((< (abs (- x 2.0)) 0.25)
      ;; lgamma(2 + z) = lgamma(1 + z) + log(1 + z)
      (let ((z (- x 2.0)))
	(+ (%lgamma1p z) (log1p z))))
     ((< x 0.5)
      ;; Reflection
      (- (log %pi)
	 (log (abs (%sinpi x)))
	 (lgamma (- 1.0 x))))
     ((>= x 10.0)
      ;; Stirling
      (+ (* (- x 0.5) (log x))
	 (- x)
	 (* 0.5 (log (* 2 %pi)))
	 (exact->inexact (%stirling-series x))))
     (else
      (let* ((z (- x 1.0))
	     (t (+ z %lanczos-g 0.5)))
	(+ (* 0.5 (log (* 2 %pi)))
	   (* (+ z 0.5) (log t))
	   (- t)
	   (log (%lanczos-sum z))))))))

(define (ceil x)
  (ceiling x))

(define (lround x)
  "Round X to the nearest integer, rounding halfway cases away from zero.
Returns an exact integer."
  (when (or (inf? x) (nan? x))
    (scm-error 'out-of-range "lround" "cannot round ~a to an integer"
	       (list x) (list x)))
  (let* ((q (abs (inexact->exact x)))
	 (r (floor (+ q 1/2))))
    (if (< x 0) (- r) r)))

(define (trunc x)
  "Round positive numbers down toward zero.  Round negative numbers
up toward zero."
  (truncate x))

(define (fmod x y)
  "Compute the floating-point remainder of X / Y, which has the sign
of X and is computed exactly: X - trunc(X / Y) * Y."
  (let ((x (exact->inexact x))
	(y (exact->inexact y)))
    (cond
     ((or (nan? x) (nan? y) (inf? x) (zero? y)) +nan.0)
     ((inf? y) x)
     (else
      (let* ((qx (inexact->exact x))
	     (qy (inexact->exact y))
	     (r (exact->inexact (- qx (* (truncate (/ qx qy)) qy)))))
	(if (zero? r) (if (signbit x) -0.0 0.0) r))))))

(define (remquo x y)
  "Compute the IEEE remainder of X / Y, X - n * Y where n is X / Y
rounded to the nearest integer, ties to even.  Return a pair of the
remainder and the low three bits of n, with the sign of X / Y."
  (let ((x (exact->inexact x))
	(y (exact->inexact y)))
    (cond
     ((or (nan? x) (nan? y) (inf? x) (zero? y)) (cons +nan.0 0))
     ((inf? y) (cons x 0))
     (else
      (let* ((qx (inexact->exact x))
	     (qy (inexact->exact y))
	     (n (round (/ qx qy)))	; exact round is ties-to-even
	     (r (exact->inexact (- qx (* n qy))))
	     (bits (modulo (abs n) 8)))
	(cons (if (zero? r) (if (signbit x) -0.0 0.0) r)
	      (if (eq? (signbit x) (signbit y)) bits (- bits))))))))

(define (fdim x y)
  "if x > y, returns x - y.  Otherwise, returns zero."
  (let ((x (exact->inexact x))
	(y (exact->inexact y)))
    (cond
     ((nan? x) x)
     ((nan? y) y)
     ((> x y) (- x y))
     (else 0.0))))

(define (fma x y z)
  "Compute X * Y + Z, rounded once."
  (let ((x (exact->inexact x))
	(y (exact->inexact y))
	(z (exact->inexact z)))
    (if (and (finite? x) (finite? y) (finite? z))
	(let ((r (exact->inexact (+ (* (inexact->exact x) (inexact->exact y))
				    (inexact->exact z)))))
	  ;; An exact zero result is -0.0 only if both parts are -0.0.
	  (if (zero? r)
	      (+ (* x y) z)
	      r))
	(+ (* x y) z))))

(define (nextafter x y)
  "Return the next representable float after X in the direction of Y."
  (let ((x (exact->inexact x))
	(y (exact->inexact y)))
    (cond
     ((or (nan? x) (nan? y)) +nan.0)
     ((= x y) y)
     ((zero? x) (if (> y 0) 5e-324 -5e-324))
     (else
      (let ((bv (make-bytevector 8)))
	(bytevector-ieee-double-set! bv 0 x (endianness big))
	(let ((bits (bytevector-u64-ref bv 0 (endianness big))))
	  ;; Moving away from zero increments the magnitude bits.
	  (bytevector-u64-set! bv 0
			       (if (eq? (> y x) (> x 0)) (1+ bits) (1- bits))
			       (endianness big))
	  (bytevector-ieee-double-ref bv 0 (endianness big))))))))

;; ABS - is in core Guile

;; DIV - returns a structure with quotient and remainder. One
;; could mock it up like this.

;; IMAXABS
;; IMAXDIV

;; FABS
;; FMOD
;; REMAINDER
;; REMQUO
;; FMA
;; FMAX
;; FMIN
;; FDIM
;; NAN
;; EXP
;; LOG
;; LOG10
;; LOG2
;; LOG1P
;; POW
;; SQRT
;; CBRT
;; HYPOT
;; SIN
;; COS
;; TAR
;; ASIN
;; ACOS
;; ATAN
;; ATAN2
;; SINH
;; COSH
;; TANH
;; ASINH
;; ACOSH
;; ATANH
;; ERF
;; ERFC
;; TGAMMA
;; LGAMMA
;; CEIL
;; FLOOR
;; TRUNC
;; ROUND
;; NEARBYINT
;; RINT
;; LRINT
;; LLRINT
;; FREXP
;; LDEXP
;; MODF
;; SCALBN
;; ILOGB
;; LOGB
;; NEXTAFTER
;; NEXTTOWARD

;; FPCLASSIFY
;; ISFINITE
;; ISINF
;; ISNAN
;; ISNORMAL
;; ISGREATER
;; ISGREATEREQUAL
;; ISLESS
;; ISLESSEQUAL
;; ISLESSGREATER
;; ISUNORDERED
;; HUGE_VALF
;; HUGE_VAL
;; HUGE_VALL
;; INFINITY
;; NAN
;; FP_FAST_FMAF
;; FP_FAST_FMA
;; FP_FAST_FMAL
;; FP_ILOGB0
;; FP_ILOGBNAN
;; MATH_ERRHANDLING
;; MATH_ERRNO
;; MATH_ERREXCEPT
;; FP_NORMAL
;; FP_SUBNORMAL
;; FP_ZERO
;; FP_INFINITE
;; FP_NAN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <setjmp.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <signal.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <stdalign.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <stdarg.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <stdatomic.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <stdbool.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <stddef.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <stdint.h>


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <stdio.h>



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <tgmath.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <threads.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <time.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <uchar.h>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <wchar.h>


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; <wctype.h>

;; The Guile analogs of ISWALNUM, ISWALPHA, ISWDIGIT, ISWXDIGIT,
;; ISWCNTRL, ISWGRAPH, ISWSPACE, ISWBLANK, ISWPRINT, and ISWPUNCT
;; would all be the same as ISALNUM, etc, because Guile doesn't
;; distinguish between 8-bit and 32-bit characters.

;; WCTYPE, and ISWCTYPE have the same functionality as core Guile's
;; char-general-category, except that core Guile uses a symbol for the
;; Unicode general category.  Rough analogs to the C routines would be
;; like the following.
(define (iswctype ch desc)
  "Return #t if the character CH is in the Unicode character category
describe by the integer DESC.  To get a value for DESC, use the
WCTYPE procedure."
  (case desc
    ((1)
     (isalnum? ch))
    ((2)
     (isalpha? ch))
    ((3)
     (isblank? ch))
    ((4)
     (iscntrl? ch))
    ((5)
     (isdigit? ch))
    ((6)
     (isgraph? ch))
    ((7)
     (islower? ch))
    ((8)
     (isprint? ch))
    ((9)
     (isspace? ch))
    ((10)
     (isupper? ch))
    ((11)
     (isxdigit? ch))))

(define (wctype str)
  "Returns an integer that identifies
the following categories.  STR should be one of the following strings:
'alnum', 'alpha', 'blank', 'cntrl', 'digit', 'graph', 'lower', 'print',
'space', 'upper', 'xdigit'."
  (cond
    ((string=? str "alnum") 1)
    ((string=? str "alpha") 2)
    ((string=? str "blank") 3)
    ((string=? str "cntrl") 4)
    ((string=? str "digit") 5)
    ((string=? str "graph") 6)
    ((string=? str "lower") 7)
    ((string=? str "print") 8)
    ((string=? str "space") 9)
    ((string=? str "upper") 10)
    ((string=? str "xdigit") 11)))
