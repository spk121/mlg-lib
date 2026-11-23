(use-modules (srfi srfi-64)
             (mlg strings))

(test-begin "t-mlg-strings")

(test-equal "string-ref-safe nominal"
  #\b
  (string-ref-safe "abc" 1))

(test-equal "string-ref-safe out of range"
  #\null
  (string-ref-safe "abc" 3))

(test-equal "string-ref-safe out of range"
  #\null
  (string-ref-safe "abc" -1))

(test-equal "string-sed-substitute one exact match at beginning"
  "abc"
  (string-sed-substitute "xbc" "x" "a" ""))

(test-equal "string-sed-substitute one exact match in middle"
  "abc"
  (string-sed-substitute "axc" "x" "b" ""))

(test-equal "string-sed-substitute one exact match at end"
  "abc"
  (string-sed-substitute "abx" "x" "c" ""))

(test-equal "string-sed-substitute one multiple match at beginning"
  "axbc"
  (string-sed-substitute "xxbc" "x" "a" ""))

(test-equal "string-sed-substitute one multiple match in middle"
  "abxc"
  (string-sed-substitute "axxc" "x" "b" ""))

(test-equal "string-sed-substitute one multiple match at end"
  "abcx"
  (string-sed-substitute "abxx" "x" "c" ""))

(test-equal "string-sed-substitute match 2nd match at beginning"
  "xabc"
  (string-sed-substitute "xxbc" "x" "a" "2"))

(test-equal "string-sed-substitute match 2nd match in middle"
  "axbc"
  (string-sed-substitute "axxc" "x" "b" "2"))

(test-equal "string-sed-substitute match 2nd match at end"
  "abxc"
  (string-sed-substitute "abxx" "x" "c" "2"))

(test-equal "string-sed-substitute global adjoining match at beginning"
  "aabc"
  (string-sed-substitute "xxbc" "x" "a" "g"))

(test-equal "string-sed-substitute global adjoining match in middle"
  "abbc"
  (string-sed-substitute "axxc" "x" "b" "g"))

(test-equal "string-sed-substitute global adjoining match at end"
  "abcc"
  (string-sed-substitute "abxx" "x" "c" "g"))

(test-equal "string-sed-substitute global disjoint match at beginning"
  "XaXbc"
  (string-sed-substitute "xaxbc" "x" "X" "g"))

(test-equal "string-sed-substitute global disjoint match in middle"
  "aXbXc"
  (string-sed-substitute "axbxc" "x" "X" "g"))

(test-equal "string-sed-substitute global adjoining match at end"
  "abXcX"
  (string-sed-substitute "abxcx" "x" "X" "g"))

(test-equal "string-sed-substitute ampersand escape"
  "abxbc"
  (string-sed-substitute "axc" "x" "b&b" ""))

(test-equal "string-sed-substitute backslash ampersand escape"
  "ab&bc"
  (string-sed-substitute "axc" "x" "b\\&b" ""))

(test-equal "string-sed-substitute first back-reference"
  "abe"
  (string-sed-substitute "abcde" "(b)(cd)" "\\1" ""))

(test-equal "string-sed-substitute second back-reference"
  "acde"
  (string-sed-substitute "abcde" "(b)(cd)" "\\2" ""))


;; string-crc16, a pure Scheme version of the C function.
;; #x906E is the CRC-16/X.25 check value; the bytes are swapped.
(test-equal "string-crc16 check value" #x6E90 (string-crc16 "123456789"))
(test-equal "string-crc16 empty string" 0 (string-crc16 ""))
(test-equal "string-crc16 uses UTF-8" (string-crc16 "é") (string-crc16 "é"))
(test-assert "string-crc16 differs for different strings"
  (not (= (string-crc16 "a") (string-crc16 "b"))))
(test-assert "string-cell-length with wide characters"
  (= 5 (string-cell-length "a中文" 8)))

(test-equal "string-get-first-digit ignores other numerals" 3
  (string-get-first-digit "a\u00b23"))
(test-equal "string-get-first-digit none" #f (string-get-first-digit "abc"))
(test-equal "string-sed-substitute non-ASCII numeral is not a back-reference"
  "a[\u00bd]c" (string-sed-substitute "abc" "b" "[\\\u00bd]" ""))
(test-equal "string-sed-substitute numeric flag" "aXa"
  (string-sed-substitute "aaa" "a" "X" "2"))
(test-equal "string-cell-length with tab" 9 (string-cell-length "a\tb" 8))
(test-equal "string-x-cell->x-data" 2 (string-x-cell->x-data 3 "a\u4e2db" 8))
(test-end "t-mlg-strings")
