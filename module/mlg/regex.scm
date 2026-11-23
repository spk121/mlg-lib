(define-module (mlg regex)
  #:use-module (ice-9 regex)
  #:use-module (ryu core)
  #:export (delimited-string->regexp))


(define (parse-char-class str i)
  "Given a string and a string position that may be the beginning of a
character class specifier, such as [:digit:], the procedure finds the
position of the end of the character class specifier, or #f if this
isn't a character class specifier."
  (let ((s (1+ i)))
   (when (char=? #\^ (string-ref-safe str s))
     (set! s (1+ s)))
   (when (char=? #\] (string-ref-safe str s))
     (set! s (1+ s)))

   ;; Start searching for close bracket.
   (while (not (member (string-ref-safe str s) '(#\] #\newline #\null)))
     ;; If we find "[." or "[:" or "[=", these subexpressions need
     ;; their own closing bracket, but, don't nest.
     (when (and (char=? #\[ (string-ref-safe str s))
		(member (string-ref-safe str (1+ s)) '(#\. #\: #\=)))
       (let ((subdelimiter (string-ref-safe str (1+ s))))
	 (set! s (+ s 2))
	 (while (not (member (string-ref-safe str s)
			     (list #\] subdelimiter #\null #\newline)))
	   (set! s (1+ s)))))
     (set! s (1+ s)))
   (if (char=? #\] (string-ref-safe str s))
       s
       #f)))

(define (extract-pattern str)
  "Given a string that begins with a valid single-character
delimiter (such as '/'), this procedure extracts a regular expression
pattern between the delimiter pairs, or will throw an error if no
valid regular expression pattern is found."
  (let ((delimiter (string-ref-safe str 0)))
    (let loop ((i 1))
      (let ((c (string-ref-safe str i)))
	(if (not (member c (list delimiter #\newline #\null)))
	    (cond
	     ((char=? c #\[)
	      ;; The beginning of a character class subexpression
	      (let ((end (parse-char-class str i)))
		(if (not end)
		    (error "unbalanced brackets in regex:" str)
		    ;; else
		    (loop (1+ end)))))
	     ((char=? c #\\)
	      (let ((next (string-ref-safe str (1+ i))))
		(if (member next '(#\null #\newline))
		    (error "trailing backslash in regex:" str)
		    ;; else skip both the backslash and the escaped character,
		    ;; which might be the delimiter.
		    (loop (+ i 2)))))
	     (else
	      (loop (1+ i))))
	    ;; else return the extracted pattern
	    (substring str 1 i))))))

(define *prev-pattern* #f)

(define (delimited-string->regexp str)
  "Given a string that begins with a single-character delimiter (such
as '/') and then contains a regular expression pattern between it and
a second delimiter, this extracts the regular expression, compiles it,
and returns the compiled expression.

If the string begins with a pair of consecutive delimiters with no
pattern in between, it returns the previously compiled expression, if
any.

Will throw a 'misc-error on exception."
  (let ((delimiter (string-ref-safe str 0)))
    (cond
     ((char=? delimiter #\space)
      (error "invalid regex delimiter:" delimiter))
     ((or (member delimiter '(#\newline #\null))
	  (member (string-ref-safe str 1) (list #\newline #\null delimiter)))
      ;; Return the previous pattern, if any.
      (or *prev-pattern*
	  (error "no regex pattern in:" str)))
     (else
      (let ((compiled-rx (make-regexp (extract-pattern str))))
	(set! *prev-pattern* compiled-rx)
	compiled-rx)))))

;; FIXME: an unfinished parser for ed-style line addresses.  It is kept
;; here, commented out, until it is completed.
#|
(define (next-addr str i current-addr addr-last)
  (let ((i (skip-blanks str i))
	(first #t)
	(addr current-addr))
    (let ((c (string-ref-safe str i)))
      (cond
       ((member c '(#\+ #\tab #\space #\- #\^))
	(let ((i2 (skip-blanks str (1+ i))))
	  (if (isdigit (string-ref-safe str i2))
	      (set! addr (+ addr
			    (if (or (char=? c #\-)
				    (char=? c #\^))
				(- (strtod (string-drop str i2)))
				(strtod (string-drop str i2)))))
	      ;; else
	      (if (not (isspace c))
		  (set! addr (+ addr
				(if (or (char=? c #\-)
					(char=? c #\^))
				    -1
				    1)))))))
       ((member c '(#\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9))
	(when (not first)
	  (error "invalid address"))
	(set! addr (strtod str i)))
       ((member c '(#\. #\$))
	(when (not first)
	  (error "invalid address"))
	(if (char=? #\. (string-ref-safe str (1+ i)))
	    (set! addr current-addr)
	    (set! addr addr-last)))
       ((member c '(#\/ #\?))
	(when (not first)
	  (error "invalid address"))
	;; get matching
	)
       ((char=? c #\\)
	(when (not first)
	  (error "invalid address"))
	;; get marked node address
	)
       ((member c '(#\% #\, #\;))
	(when first
		    
|#
