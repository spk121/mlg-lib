(use-modules (srfi srfi-64)
             (mlg utils))

(test-begin "t-mlg-utils")

;; getpagesize, now called through the FFI instead of a C extension
(test-assert "getpagesize is a positive power of two"
  (let ((n (getpagesize)))
    (and (exact-integer? n) (> n 0) (zero? (logand n (1- n))))))

(test-end "t-mlg-utils")
