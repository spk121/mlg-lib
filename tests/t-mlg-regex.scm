(use-modules (srfi srfi-64)
             (ice-9 regex)
             (mlg regex))

(test-begin "t-mlg-regex")

(define (match-in rx str)
  (let ((m (regexp-exec rx str)))
    (and m (match:substring m))))

(test-equal "delimited-string->regexp simple" "abc"
  (match-in (delimited-string->regexp "/b*abc/") "xxabcxx"))
(test-equal "delimited-string->regexp character class" "a123"
  (match-in (delimited-string->regexp "/a[[:digit:]]+/") "xa123y"))
(test-equal "delimited-string->regexp escaped delimiter" "a/b"
  (match-in (delimited-string->regexp "/a\\/b/") "xa/by"))
(test-equal "delimited-string->regexp ] first in class" "]x]"
  (match-in (delimited-string->regexp "/[]x]+/") "a]x]b"))
(test-equal "delimited-string->regexp other delimiter" "a/b"
  (match-in (delimited-string->regexp "|a/b|") "a/b"))
(test-equal "delimited-string->regexp empty reuses previous" "a/b"
  (match-in (delimited-string->regexp "||") "a/b"))
(test-error "delimited-string->regexp unbalanced bracket" #t
  (delimited-string->regexp "/[abc/"))
(test-error "delimited-string->regexp space delimiter" #t
  (delimited-string->regexp " a "))

(test-end "t-mlg-regex")
