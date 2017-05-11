;; Helper functions for ed-like editing
(define-module (mlg ed)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 rdelim)
  ;; #:use-module (gano CBuffer)
  #:use-module (ryu core)
  #:use-module (mlg io)
  #:use-module (mlg utils)
  #:use-module (mlg re)
  #:export ())

(define-syntax set&get
  (syntax-rules ()
    ((_ var x)
     (begin
       (set! var x)
       var))))

;; Globals
(define EOF -1)
(define ERR -2)
(define EMOD -3)
(define FATAL -4)

;; Gflags
;; Global command
(define GLB #x01)
;; Print after command
(define GPR #x02)
;; List after command
(define GLS #x04)
;; Enumerate after command
(define GNP #x08)
;; Global substitute
(define GNP #x10)

(define ibuf (make-string 0))		; ed command-line buffer
(define ibufp 0)			; index into command-line-buffer

(define (ibufp++)
  (set! ibufp (1+ ibufp)))

(define (ibufp*)
  (string-ref-safe ibuf ibufp))

(define (ibufp*++)
  (let ((ret (ibufp*)))
    (ibufp++)
    ret))

(define (ibufp? c)
  "Test if the current character in ibuf is C."
  (char=? c (string-ref-safe ibuf ibufp)))

(define (ibufp++? c)
  "Test if the current character in ibuf is C.  Return
#t or #f.  Increment the current character location."
  (let ((ret (ibufp? c)))
    (++ ibufp)
    ret))

(define (ibufp-strtol-idx)
  "Return the integer encoded at the current position in the ibuf
string"
  (let ((str-and-index (strtol-idx (string-drop ibuf ibufp) 10)))
    (pk str-and-index)
    (set! ibufp (+ ibufp (cdr str-and-index)))
    (car str-and-index)))

(define garrulous #f)
(define interactive #t)
(define modified #f)
(define scripted #f)
(define errmsg #f)
(define prompt #f)
(define lineno #f)
(define current-addr 0)
(define addr-cnt 0)
(define addr-last 80)
(define first-addr 0)
(define second-addr 0)
(define sgflag 0)
(define sgnum 0)
(define old-filename #f)
(define isglobal #f)

;; If set, signals set flags.
(define mutex 0)
;; If set, sighup received when mutex set.
(define sighup #f)
;; If set, sigint received when mutex set.
(define sigint #f)
;; If set, signal handlers are enabled.
(define sigactive #f)

(define (SPL1)
  "Disable some interrupts"
  (set! mutex (1+ mutex)))
(define (SPL0)
  "Enable all interrupts and chack signal flags."
  (set! mutex (1- mutex))
  (when (= 0 mutex)
    (when sighup
      (handle-hup SIGHUP))
    (when sigint
      (handle-int SIGINT))))

(define home "") 			; home directory

(define cbuf #f)

(define (seterrmsg msg)
  (set! errmsg msg))

(define (main args)
  (let* ((option-spec '((prompt (single-char #\p) (value #t) (predicate string?))
			(scripted (single-char #\s) (value #f))))
	 (options (getopt-long args option-spec))
	 (argv (option-ref options '() '()))
	 (status 0))

    (set! home (get-home-dir))
    (pk 'home home)
    (set! prompt (option-ref options 'prompt "*"))
    (set! scripted (option-ref options 'scripted #f))

    (pk 'prompt prompt 'scripted scripted 'argv argv)

    ;; If one of the remaining arguments is a sole hyphen,
    ;; some versions of ed make this scripted mode.
    
    ;; Determine if we're interactive.
    ;; isatty  | file-port?  |
    ;; yes     | yes         | interactive
    ;; no      | yes         | input is piped into
    ;; no      | no          | probably running under repl
    (set! interactive (or (and (isatty? (current-input-port))
			       (file-port? (current-input-port)))
			  (and (not (isatty? (current-input-port)))
			       (not (file-port? (current-input-port))))))
    (pk 'interactive interactive)
    
    ;; Signal handler installation goes here.
    (when (isatty? (current-input-port))
      (signal-winch SIGWINCH)
      (sigaction SIGWINCH signal-winch))
    (sigaction SIGHUP signal-hup)
    (sigaction SIGQUIT SIG_IGN)
    (sigaction SIGINT signal-int)

    ;; FIXME: This is the big interrupt catch.
    ;; If I catch a sigint, I whoudl restart processing from here.
    
    ;; FIXME: this is where we make an empty buffer
    ;; (set! cbuf (make-empty-cbuffer))
    (set! cbuf (list))

    ;; Enable signal handlers
    (set! sigactive #t)
    
    ;; Load the file, if a filename is given
    (cond
     ((and (> (length argv) 0) (> (string-length (car argv)) 0))
      (let* ((fname (car argv))
	     (ret (read-file fname 0 current-addr scripted)))
	(if (and (< ret 0) (not interactive))
	    (quit 2)
	    ;; else
	    (if (not (char=? #\! (string-ref-safe fname 0)))
		(set! old-filename fname)))))
     (else
      (format (current-error-port) "?~%")
      (unless interactive
	(quit 2))))

    
    ;; This is the main loop
    (while #t
      (when (and (< status 0) garrulous)
	(format (current-error-port) "~a~%" errmsg))
      (display prompt (current-output-port))
      (force-output)

      (let ((n (get-tty-line)))
	(cond
	 ((< n 0)
	  (set! status ERR)
	  (continue))

	 ((= n 0)
	  (if (and (modified (not scripted)))
	      (begin
		(format (current-error-port) "?~%")
		(seterrmsg "warning: file modified")
		(unless interactive
		  (when garrulous
		    (format (current-error-port) "script, line ~a: ~a~%"
			    lineno errmsg))
		  (quit 2))
		;; FIXME: Is there a Guile equivalent C's clearerr() ?
		(set! modified #f)
		(set! status EMOD)
		(continue))
	      ;; else
	      (quit 0)))

	 ((char=? (string-ref-safe ibuf (1- n)) #\null)
	  ;; Discard line
	  (seterrmsg "unexpected end-of-file")
	  ;; clearerr STDIN
	  (set! status ERR)
	  (continue)))
	
	(set! isglobal #f)
	;; Here we parse the current command.  The exec-command
	;; call is where most of the operations magic happens.
	
	(if (and (>= (pk 'extract-addr-range-ret (set&get status (extract-addr-range))) 0)
		 (>= (pk 'exec-command (set&get status (exec-command))) 0))
	    
	    ;; exec-command returns zero if the exec-command didn't
	    ;; request an after-command print operation. A non-zero is
	    ;; a description of the type of after-command print
	    ;; operation requested.
	    (if (or (= status 0)
		    (and (!= status 0)
			 (>= (pk 'CC (set&get status (display-lines current-addr current-addr status))) 0)))
		(continue)))
	
	;; A status of less than zero is handled here
	(cond
	 ((= EOF status)
	  (quit 0))

	 ((= EMOD status)
	  (set! modified #f)
	  (display "?\n" (current-error-port))
	  (seterrmsg "warning: file modified")
	  (unless interactive
	    (when garrulous
	      (format (current-error-port)
		      "script, line ~a: ~a~%"
		      lineno errmsg))
	    (quit 2)))

	 ((= FATAL status)
	  (cond
	   ((not interactive)
	    (when garrulous
	      (format (current-error-port)
		      "script, line ~a: ~a~%"
		      lineno errmsg)))
	   
	   (garrulous
	    (format (current-error-port) "~a~%" errmsg)))
	  (quit 3))

	 (else
	  (format (current-error-port) "?~%")
	  (unless interactive
	    (when garrulous
	      (format (current-error-port)
		      "script, line ~a: ~a~%"
		      lineno errmsg))
	    (quit 2))))))))


(define (display-lines from to gflag)
  "Print a range of lines to stdout."
  (cond
   ((zero? from)
    (seterrmsg "invalid address")
    ERR)
   (else

    ;; FIXME display some lines
    0
    )))


(define (extract-addr-range)
  (let ((addr 0))
    (set! addr-cnt 0)
    (set! first-addr current-addr)
    (set! second-addr current-addr)

    ;; Loop over all the addresses that appear before the command
    ;; character in an ED command line.
    (while (>= (pk 'DD (set&get addr (next-addr))) 0)
      (++ addr-cnt)
      (set! first-addr second-addr)
      (set! second-addr addr)
      (cond
       ((and (not (ibufp? #\,)) (not (ibufp? #\;)))
	(break))
       ((ibufp++? #\;)
	(set! current-addr addr))))

    (set! addr-cnt (min addr-cnt 2))
    
    (when (or (= 1 addr-cnt)
	      (!= second-addr addr))
      (set! first-addr second-addr))
    (if (= addr ERR)
	ERR
	0)))

(define (get-marked-node-addr n)
  ;; FIXME: this is where I hook into CBuffer's bookmarks\
  (throw 'unimplemented)
  )

(define (get-matching-node-addr pat dir)
  (throw 'unimplemented)
  ERR)

(define (SKIP_BLANKS)
  (let ((count 0))
    (while (and (isspace? (ibufp*)) (not (ibufp? #\newline)))
      (set! count (1+ count))
      (ibufp++))
    (format #t "SKIP_BLANKS skipped ~a blanks~%" count)
    *unspecified*))

(define (next-addr)
  "Return the next line address in the command buffer."
  (let ((addr current-addr)
	(n 0)
	(first #t)
	(c 0)
	(ret 0))
    (SKIP_BLANKS)
    (let ((hd ibufp))
      (while #t
	(let ((c (ibufp*)))
	  (cond
	   ((member c (string->list "+ -^\t"))
	    (ibufp++)
	    (SKIP_BLANKS)
	    (cond
	     ((isdigit? (ibufp*))
	      (set! n (ibufp-strtol-idx))
	      (set! addr (+ addr (if (or (char=? c #\-) (char=? c #\^))
				     (- n)
				     n))))
	     ((not (isspace? c))
	      (set! addr (+ addr (if (or (char=? c #\-) (char=? #\^))
				     -1
				     1))))))
	   
	   ((member c (string->list "0123456789"))
	    (pk c first)
	    (unless first
	      (seterrmsg "invalid address")
	      (set! ret ERR)
	      (break))
	    (set! addr (ibufp-strtol-idx)))
	   
	   ((member c (string->list ".$"))
	    (unless first
	      (seterrmsg "invalid address")
	      (set! ret ERR)
	      (break))
	    (ibufp++)
	    (set! addr (if (char=? c #\.) current-addr addr-last)))
	   
	   ((member c (string->list "/?"))
	    (unless first
	      (seterrmsg "invalid address")
	      (set! ret ERR)
	      (break))
	    (cond
	     ((< (set&get addr (get-matching-node-addr (get-compiled-pattern) (char=? c #\/))) 0)
	      (set! ret ERR)
	      (break))
	     ((ibufp? c)
	      (ibufp++))))
	   
	   ((char=? c #\')
	    (unless first
	      (seterrmsg "invalid address")
	      (set! ret ERR)
	      (break))
	    (when (< (set&get addr (get-marked-node-addr (ibufp*++))) 0)
	      (set! ret ERR)
	      (break)))
	   
	   ((and first (member c (string->list "%,;")))
	    (ibufp++)
	    (++ addr-cnt)
	    (set! second-addr (if (char=? c #\;) current-addr 1))
	    (if (< (set&get addr (next-addr)) 0)
		(set! addr addr-last)))
	   
	   (else
	    (pk 'else ibufp hd addr addr-last)
	    (cond
	     ((= ibufp hd)
	      (set! ret EOF)
	      (break))
	     ((or (< addr 0) (< addr-last addr))
	      (seterrmsg "invalid address")
	      (set! ret ERR)
	      (break))
	     (else
	      (set! ret addr)
	      (break))))))
	(set! first #f))
      ret)))

(define (clear-undo-stack)
  (format #t "in clear-undo-stack UNIMPLEMENTED~%"))

(define (GET_COMMAND_SUFFIX)
  (format #t "Entering GET_COMMAND_SUFFIX~%")
  (let ((done #f)
	(gflag 0))
    (while (not done)
      (let ((c (ibufp*)))
	(cond
	 ((char=? c #\p)
	  (set! gflag (logior gflag GPR))
	  (ibufp++))
	 ((char=? c #\l)
	  (set! gflag (logior gflag GLS))
	  (ibufp++))
	 ((char=? c #\n)
	  (set! gflag (logior gflag GNP))
	  (ibufp++))
	 (else
	  (set! done #t)))))
    (let ((c (ibufp*++)))
      (if (not (char=? c #\null))
	  (begin
	    (seterrmsg "invalid command suffix")
	    (format #t "Leaving GET_COMMAND_SUFFIX FAIL gflag = ~a~%" gflag)
	    #f)
	  (begin
	    (format #t "Leaving GET_COMMAND_SUFFIX SUCCESS gflag = ~a~%" gflag)
	    gflag)))))

(define (exec-command)
  "Execute the next command in the command buffer; return
print request, if any."
  (format #t "entering exec-command~%")
  (let* (
	 ;; (tpat #f)
	 ;; (fnp 0)
	 (gflag 0)
	 ;; (sflags 0)
	 ;; (addr 0)
	 ;; (n 0)
	 )
    (SKIP_BLANKS)
    (let ((c (ibufp*++)))
      (cond

       ;; Append command
       ((char=? c #\a)
	(let ((suffix (GET_COMMAND_SUFFIX)))
	  (format #t "in append command suffix=~a~%" suffix)
	  (if suffix
	      (begin
		(unless isglobal
		  (clear-undo-stack))
		(let ((success (append-lines second-addr)))
		  (if (< success 0)
		      ERR
		      suffix)))
	      ;; else
	      ERR)))

       ;; Change command
       ((char=? c #\c)
	(cond
	 ((< (check-addr-range current-addr current-addr) 0)
	  ERR)
	 ((not (GET_COMMAND_SUFFIX))
	  ERR)
	 (else
	  (unless isglobal (clear-undo-stack))
	  (if (or (< (delete-lines first-addr second-addr) 0)
		  (< (append-lines current-addr) 0))
	      ERR
	      ;; else
	      gflag))))

       ;; Delete command
       ((char=? c #\d)
	(cond
	 ((< (check-addr-range current-addr current-addr) 0)
	  ERR)
	 ((not (GET_COMMAND_SUFFIX))
	  ERR)
	 (else
	  (unless isglobal (clear-undo-stack))
	  (if (< (delete-lines first-addr second-addr) 0)
	      ERR
	      ;; else
	      (if (!= (set&get addr (INC_MOD current-addr addr-last)) 0)
		  (begin
		    (set! current-addr addr)
		    gflag)
		  ;; else
		  gflag)))))

       ;; Edit command
       ((and (char=? c #\e) modified (not scripted))
	EMOD)

       ;; Edit without checking command
       ((or (and (char=? c #\e) (or (not modified) scripted))
	    (char=? c #\E))
	(cond
	 ((< addr-cnt 0)
	  (seterrmsg "unexpected address")
	  ERR)
	 ((not (isspace? (ibufp*)))
	  (seterrmsg "unexpected command suffix")
	  ERR)
	 ((not (set&get fnp (get-filename)))
	  ERR)
	 ((not (GET_COMMAND_SUFFIX))
	  ERR)
	 ((< (delete-lines 1 addr-last) 0)
	  ERR)
	 (else
	  (clear-undo-stack)
	  (cond
	   ((< (close-sbuf) 0)
	    ERR)
	   ((< (open-sbuf) 0)
	    FATAL)
	   (else
	    (when (and (> (string-length fnp) 0) (not (string=? fnp "!")))
	      (set! old-filename fnp))
	    (cond
	     ((< (read-file (if (> (string-length fnp) 0)
				fnp
				old-filename)
			    0 current-addr scripted)
		 0)
	      ERR)
	     (else
	      (clear-undo-stack)
	      (set! modified 0)
	      (set! u-current-addr -1)
	      (set! u-addr-last -1))))))))

       ;; Filename command
       ((char=? c #\f)
	(cond
	 ;; No arguments allowed.
	 ((> addr-cnt 0)
	  (seterrmsg "unexpected address")
	  ERR)
	 ;; No suffix allowed.
	 ((not (isspace? (ibufp*)))
	  (seterrmsg "unexpected command suffix")
	  ERR)
	 ((not (set&get fnp (get-filename)))
	  ERR)
	 ((string=? fnp "!")
	  (seterrmsg "invalid redirection")
	  ERR)
	 ((not (GET_COMMAND_SUFFIX))
	  (seterrmsg "invalid command suffix")
	  ERR)
	 ((> (string-length fnp) 0)
	  (set! old-filename fnp)
	  (display (strip-escapes old-filename))
	  (newline))))

       ;; Search
       ((member c (string->list "gGvV"))
	(cond
	 (isglobal
	  (seterrmsg "cannot nest global commands")
	  ERR)
	 ((< (check-addr-range 1 addr-last) 0)
	  ERR)
	 ((< (build-active-list (or (char=? c #\g) (char=? c #\G))) 0)
	  ERR)
	 ((and (!= 0 (set&get n (or (char=? c #\G) (char=? c #\V))))
	       (not (GET_COMMAND_SUFFIX)))
	  ERR)
	 (else
	  (++ isglobal)
	  (if (< (exec-global n gflag) 0)
	      ERR
	      ;; else
	      gflag))))

       ;; Help command
       ((char=? c #\h)
	(cond
	 ((> addr-cnt 0)
	  (seterrmsg "unexpected address")
	  ERR)
	 ((not (GET_COMMAND_SUFFIX))
	  ERR)
	 (errmsg
	  (format (current-error-port) "~a~%" errmsg)))
	gflag)

       ;; Help-mode-command
       ((char=? c #\H)
	(cond
	 ((> addr-cnt 0)
	  (seterrmsg "unexpected address")
	  ERR)
	 ((not (GET_COMMAND_SUFFIX))
	  ERR)
	 ((and (set&get garrulous (not garrulous)) errmsg)
	  (format (current-error-port) "~a~%" errmsg)))
	gflag)

       ;; Insert command
       ((char=? c #\i)
	(when (= second-addr 0)
	  (set! second-addr 1))
	(cond
	 ((not (GET_COMMAND_SUFFIX))
	  ERR)
	 (else
	  (unless isglobal (clear-undo-stack))
	  (when (< (append-lines (1- second-addr)) 0)
	    ERR))))

       ;; Join command
       ((char=? c #\j)
	(cond
	 ((< (check-addr-range current-addr (1+ current-addr)) 0)
	  ERR)
	 ((not (GET_COMMAND_SUFFIX))
	  ERR)
	 (else
	  (unless isglobal (clear-undo-stack))
	  (if (and (!= first-addr second-addr)
		   (< (join-lines first-addr second-addr) 0))
	      ERR
	      ;; else
	      gflag))))

       ;; Mark command
       ((char=? c #\k)
	(let ((c2 (ibufp*++)))
	  (cond
	   ((= 0 second-addr)
	    (seterrmsg "invalid address")
	    ERR)
	   ((not (GET_COMMAND_SUFFIX))'
	    ERR)
	   ((< (mark-line-node (get-addressed-line-node second-addr)) 0)
	    ERR)
	   (else
	    gflag))))

       ))))



(define (get-tty-line)
  "Read a line of text from stdin into the command line buffer.
Return line length."
  (let ((txt (read-line (current-input-port))))
    (cond
     ((eof-object? txt)
      (seterrmsg "cannot read stdin")
      ERR)
     (else
      (set! ibuf txt)
      (string-length txt)))))

(define (append-lines n)
  "Insert text from stdin to after line N. Stop when either a
single period is read or EOF.  Return status."
  (format #t "in append-lines n=~s~%" n)
  (let ((L 0)
	(lp ibufp)
	(eot #\null)
	(up #f)
	(ret #f))
    (set! current-addr n)
    (while #t
      (cond

       ;; If this is a regular append, and not part of a global
       ;; command, then get a line from the console.
       ((not isglobal)
	(cond
	 ((< (set&get L (get-tty-line)) 0)
	  (set! ret ERR)
	  (break))
	 (else
	  (set! lp 0))))

       ;; If this is part of a global command, but there is
       ;; no text left in the command buffer, we're done.
       ((char=? #\null (string-ref-safe ibufp (set&get lp ibufp)))
	0)

       ;; Else, if this is part of a global command, and there
       ;; is text left in the command buffer, figure out how much
       ;; text is left.
       (else
	(while (not (char=? #\null (ibufp*++))))
	(set! L (- ibufp lp))))

      ;; Now, either the text is '.' meaning quit, or
      ;; it is a line to be inserted
      (if (and (= L 1)
	       (char=? #\. (string-ref-safe ibuf lp)))
	  (begin
	    (set! ret 0)
	    (break)))
      (set! eot (1+ lp))
      (SPL1)
      ;; actually append the linebuffer here
      ;; (put-sbuf-line (string-drop ibuf lp))
      (SPL0)

      ;; loop, or something
      ;; set modified flag
      )))

(define (handle-hup signo)
  (unless sigactive
    (quit 1))				; signal race?
  (set! sighup #f)
  ;; Try to write the crash-out file here.  Or, failing that, in my
  ;; home directory.
  (if (and (not (zero? addr-last))
	   (< (write-file "ed.hup" "1" 1 addr-last) 0)
	   (not (string-null? home))
	   (char=? (string-ref-safe home 0) #\/))
      (write-file (string-append home "/ed.hup") "w" 1 addr-last))
  (primitive-_exit 2))

(define (handle-int signo)
  (unless sigactive
    (primitive-_exit 1))
  (set! sigint #f)
  ;; FIXME, here I somehow jump to the top of the main loop
  (throw 'interrupt))

(define (signal-winch signo)
  ;; When there is a way to check TIOCGWINSZ,
  ;; then set rows and cols here.
  *unspecified* )

(define (signal-int signo)
  (if (> mutex 0)
      (set! sigint #t)
      (handle-int signo)))

(define (signal-hup signo)
  (if (> mutex 0)
      (set! sighup #t)
      (handle-hup signo)))

;; a (append) + suffix
;; c (change) + suffix
;; d (delete) + suffix
;; e (edit) + blanks + filename-or-!
;; E (edit wo checking) + blanks + filename-or-!
;; f (filename) + blanks + filename
;; g (global) + regex + command list
;; G (global) + regex + suffix
;; h (help) + suffix
;; H (help-mode) + suffix
;; i (insert) + suffix
;; j (join) + suffix
;; k (mark) + bookmark + suffix
;; l (list) + suffix
;; m (move) + address + suffix
;; n (number) + suffix
;; p (print)  + suffix
;; P (prompt) + suffix
;; q (quit)
;; Q (quit w/o checking)
;; r (read) + blanks + filename-or-!
;; s (substitute) + regex + replacement + flags
;; t (copy) + address + suffix
;; u (undo) + suffix
;; v (non-match) + regex + command-list
;; V (non-match) + regex + suffix
;; w (write) + blanks + filename-or-!
;; = (line-no) + suffix
;; ! (shell) + command

(main (command-line))