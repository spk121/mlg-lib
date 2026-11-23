(use-modules (srfi srfi-64)
             (system foreign)
             (ryu printf))

(test-begin "t-ryu-printf")

;; Literals and %%
(test-equal "" (asprintf ""))
(test-equal "hello" (asprintf "hello"))
(test-equal "100%" (asprintf "100%%"))
(test-equal "a~a" (asprintf "a~a"))     ; tildes are literal
(test-equal "x=1, y=2" (asprintf "x=%d, y=%d" 1 2))

;; Signed integers
(test-equal "00042" (asprintf "%05d" 42))
(test-equal "-0005" (asprintf "%05d" -5))
(test-equal "+42" (asprintf "%+d" 42))
(test-equal " 42" (asprintf "% d" 42))
(test-equal "42   |" (asprintf "%-5d|" 42))
(test-equal "  042" (asprintf "%05.3d" 42))   ; precision disables 0 flag
(test-equal "" (asprintf "%.0d" 0))
(test-equal "+" (asprintf "%+.0d" 0))
(test-equal "   " (asprintf "%3.0d" 0))
(test-equal "-2147483648" (asprintf "%i" -2147483648))
(test-equal "-128" (asprintf "%hhd" -128))
(test-equal "-32768" (asprintf "%hd" -32768))
(test-equal "-9223372036854775808" (asprintf "%lld" -9223372036854775808))

;; Unsigned integers
(test-equal "ff" (asprintf "%x" 255))
(test-equal "FF" (asprintf "%X" 255))
(test-equal "0xff" (asprintf "%#x" 255))
(test-equal "0XFF" (asprintf "%#X" 255))
(test-equal "0x0000ff" (asprintf "%#08x" 255))
(test-equal "0" (asprintf "%#x" 0))
(test-equal "0377" (asprintf "%#o" 255))
(test-equal "0" (asprintf "%#.0o" 0))
(test-equal "4294967295" (asprintf "%u" 4294967295))
(test-equal "18446744073709551615" (asprintf "%llu" 18446744073709551615))

;; Star width and precision
(test-equal "   42" (asprintf "%*d" 5 42))
(test-equal "42   |" (asprintf "%*d|" -5 42))   ; negative width => left-justify
(test-equal "00042" (asprintf "%.*d" 5 42))
(test-equal "42" (asprintf "%.*d" -1 42))       ; negative precision => default
(test-equal "  3.14" (asprintf "%*.*f" 6 2 3.14159))

;; Decimal floats
(test-equal "3.141593" (asprintf "%f" 3.14159265))
(test-equal "1.05" (asprintf "%.2f" 1.05))
(test-equal "0.05" (asprintf "%.2f" 0.05))
(test-equal "2" (asprintf "%.0f" 2.5))          ; round half to even
(test-equal "4" (asprintf "%.0f" 3.5))
(test-equal "2" (asprintf "%.f" 2.5))
(test-equal "2." (asprintf "%#.0f" 2.0))
(test-equal "-0.000000" (asprintf "%f" -0.0))
(test-equal "-0.00" (asprintf "%.2f" -0.001))
(test-equal "+1.000000" (asprintf "%+f" 1.0))
(test-equal "-001.50" (asprintf "%07.2f" -1.5))
(test-equal "1.50   |" (asprintf "%-7.2f|" 1.5))
(test-equal "inf" (asprintf "%f" +inf.0))
(test-equal "-INF" (asprintf "%F" -inf.0))
(test-equal "nan" (asprintf "%f" +nan.0))
(test-equal "  inf" (asprintf "%05f" +inf.0))   ; no zero padding for inf

;; Scientific floats
(test-equal "1.234568e+04" (asprintf "%e" 12345.678))
(test-equal "1.0e+01" (asprintf "%.1e" 9.99))  ; carry into exponent
(test-equal "0.000000e+00" (asprintf "%e" 0.0))
(test-equal "1.000000E-10" (asprintf "%E" 1e-10))
(test-equal "1e+300" (asprintf "%.0e" 1e300))
(test-equal "4.940656e-324" (asprintf "%e" 5e-324))

;; General floats
(test-equal "0.0001" (asprintf "%g" 0.0001))
(test-equal "1e-05" (asprintf "%g" 0.00001))
(test-equal "100000" (asprintf "%g" 100000.0))
(test-equal "1e+06" (asprintf "%g" 1000000.0))
(test-equal "1e+06" (asprintf "%g" 999999.5))
(test-equal "0" (asprintf "%g" 0.0))
(test-equal "1.5" (asprintf "%g" 1.5))
(test-equal "1.50000" (asprintf "%#g" 1.5))
(test-equal "0.333333" (asprintf "%g" (/ 1.0 3.0)))
(test-equal "3E+10" (asprintf "%.1G" 3e10))
(test-equal "2" (asprintf "%.0g" 2.0))

;; Hexadecimal floats
(test-equal "0x1p+0" (asprintf "%a" 1.0))
(test-equal "0x1.8p+1" (asprintf "%a" 3.0))
(test-equal "0x1.999999999999ap-4" (asprintf "%a" 0.1))
(test-equal "-0X1.8P+1" (asprintf "%A" -3.0))
(test-equal "0x0p+0" (asprintf "%a" 0.0))
(test-equal "0x1.00p+0" (asprintf "%.2a" 1.0))
(test-equal "0x2p+0" (asprintf "%.0a" 1.9))
(test-equal "0x0.0000000000001p-1022" (asprintf "%a" 5e-324))
(test-equal "0x001.8p+1" (asprintf "%010a" 3.0))

;; Strings and characters
(test-equal "abc" (asprintf "%s" "abc"))
(test-equal "ab" (asprintf "%.2s" "abc"))
(test-equal "  abc" (asprintf "%5s" "abc"))
(test-equal "abc  |" (asprintf "%-5s|" "abc"))
(test-equal "" (asprintf "%.0s" "abc"))
(test-equal "A" (asprintf "%c" #\A))
(test-equal "  A" (asprintf "%3c" #\A))
(test-equal "A  |" (asprintf "%-3c|" #\A))
(test-equal "λ" (asprintf "%lc" #\λ))

;; Pointers
(test-equal "(nil)" (asprintf "%p" %null-pointer))
(test-equal "0x1234" (asprintf "%p" (make-pointer #x1234)))
(test-equal "  0x10" (asprintf "%6p" 16))

;; %n calls a procedure with the count so far
(test-equal 3
  (let ((n #f))
    (asprintf "abc%ndef" (lambda (x) (set! n x)))
    n))

;; Output procedures
(test-equal "x=7" (with-output-to-string (lambda () (printf "x=%d" 7))))
(test-equal "x=7"
  (call-with-output-string (lambda (port) (fprintf port "x=%d" 7))))

;; Errors
(test-error 'wrong-number-of-args (asprintf "%d %d" 1))
(test-error 'wrong-type-arg (asprintf "%d" "one"))
(test-error 'wrong-type-arg (asprintf "%f" 1))
(test-error 'wrong-type-arg (asprintf "%s" 1))
(test-error 'out-of-range (asprintf "%u" -1))
(test-error 'out-of-range (asprintf "%hhd" 200))

(test-end "t-ryu-printf")
