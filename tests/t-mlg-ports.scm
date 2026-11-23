(use-modules (srfi srfi-64)
	     (mlg port))

(test-begin "t-mlg-port")

(test-assert "read-line-terminator empty string"
	    (eof-object? (read-line-terminator (open-input-string ""))))

(test-assert "read-line-terminator not at eol"
	    (string-null? (read-line-terminator (open-input-string "hello"))))

(test-equal "read-line-terminator RETURN only"
	    "\r" (read-line-terminator (open-input-string "\r")))

(test-equal "read-line-terminator NEWLINE only"
	    "\n" (read-line-terminator (open-input-string "\n")))

(test-equal "read-line-terminator NEL only"
	    "\x85" (read-line-terminator (open-input-string (string #\x85))))

(test-equal "read-line-terminator VTAB only"
	    "\v" (read-line-terminator (open-input-string "\v")))

(test-equal "read-line-terminator LS only"
	    "\u2028" (read-line-terminator (open-input-string (string #\x2028))))

(test-equal "read-line-terminator PS only"
	    "\u2029" (read-line-terminator (open-input-string (string #\x2029))))

(test-equal "read-line-terminator CR + LF"
	    "\r\n" (read-line-terminator (open-input-string "\r\n")))

(test-equal "read-line-terminator CR + CR"
	    "\r" (read-line-terminator (open-input-string "\r\r")))

(test-equal "read-line-terminator LF + CR"
	    "\n" (read-line-terminator (open-input-string "\n\r")))

(test-equal "read-line-terminator LF + LF"
	    "\n" (read-line-terminator (open-input-string "\n\n")))

;; Further fixes
(test-equal "peek-char-islower? uppercase" #f
  (peek-char-islower? (open-input-string "A")))
(test-equal "peek-char-islower? lowercase" #t
  (peek-char-islower? (open-input-string "a")))
(test-equal "read-char=? consumes the character" '(#t #\b)
  (let ((p (open-input-string "ab")))
    (list (read-char=? p #\a) (read-char p))))
(test-equal "read-regex-string pushes back onto its own port" '(#f #\/)
  (let ((p (open-input-string "/")))
    (list (read-regex-string p) (read-char p))))
(test-equal "read-regex-string delimited" "/a[b]c/"
  (read-regex-string (open-input-string "/a[b]c/d")))
(test-equal "read-integer keeps a sign with no digits" '(0 #\-)
  (let ((p (open-input-string "-z")))
    (list (read-integer p) (read-char p))))
(test-equal "read-integer hex" '(31 #\g)
  (let ((p (open-input-string "  0x1Fg")))
    (list (read-integer p) (read-char p))))
(test-end "t-mlg-port")
