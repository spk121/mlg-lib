(use-modules (srfi srfi-64)
	     (rnrs bytevectors)
	     (rnrs io ports)
	     (mlg bytevectors))

(test-begin "t-mlg-bytevectors")

(define f32bv (list->f32vector (list -1.0 0.0 1.0)))
(test-equal "f32vector-max finds largest value"
  1.0 (f32vector-max f32bv))

;; bytevector-u8->escaped-string-full
;;
;; Bug: (= 127) instead of (= x 127) -- = was called with one argument,
;; causing an error whenever a byte with value 127 was processed.
(test-equal "bytevector-u8->escaped-string-full routes byte 127 to del-transformer"
  "DEL"
  (bytevector-u8->escaped-string-full
   #u8(127) 0 1
   (lambda (x) "C0") (lambda (x) "G0") (lambda (x) "DEL")
   (lambda (x) "C1") (lambda (x) "G1")))

;; Bug: (g1-transformer) called with no argument instead of (g1-transformer x),
;; causing an arity error whenever a byte in the range 160-255 was processed.
;; Also verifies the byte value is forwarded correctly.
(test-equal "bytevector-u8->escaped-string-full passes byte value to g1-transformer"
  "200"
  (bytevector-u8->escaped-string-full
   #u8(200) 0 1
   (lambda (x) "err") (lambda (x) "err") (lambda (x) "err")
   (lambda (x) "err") (lambda (x) (number->string x))))

;; bytevector-u8-fold
;;
;; Bug: (bytevector-u8-ref i result) transposed the arguments to
;; bytevector-u8-ref (index and bytevector were swapped), and the
;; accumulator was never passed as the second argument to proc.
(test-equal "bytevector-u8-fold sums all bytes"
  6
  (bytevector-u8-fold + #u8(1 2 3) 0))

;; With start/end to confirm iteration bounds are correct.
(test-equal "bytevector-u8-fold respects start/end bounds"
  9
  (bytevector-u8-fold + #u8(1 2 3 4 5) 0 1 4))

;; bytevector-u8-map-to-list
;;
;; Bug: (bytevector-u8-ref i result) transposed the arguments -- the
;; loop index and the result accumulator were passed instead of the
;; bytevector and the loop index.
(test-equal "bytevector-u8-map-to-list identity mapping"
  '(1 2 3)
  (bytevector-u8-map-to-list (lambda (x) x) #u8(1 2 3)))

;; With start/end, and a non-trivial transform.
(test-equal "bytevector-u8-map-to-list with transform and start/end"
  '(20 30)
  (bytevector-u8-map-to-list (lambda (x) (* x 10)) #u8(1 2 3) 1 3))

;; read-bytevector
;;
;; Bug: the fifth argument to bytevector-copy! (the byte count) was
;; passed as (+ output-len bytes-read) -- the total size of the new
;; output buffer -- rather than just bytes-read.  For a single-block
;; read output-len is 0 so the two values are equal and the bug is
;; invisible.  Only inputs larger than one block (16384 bytes) expose
;; the error, because then output-len > 0 on the second iteration and
;; the copy count overshoots the source buffer bounds.
(let* ((block-size (* 16 1024))
       (test-size  (+ block-size 100))
       (test-bv    (make-bytevector test-size 42))
       (port       (open-bytevector-input-port test-bv))
       (result     (read-bytevector port)))
  (test-equal "read-bytevector multi-block result has correct length"
    test-size (bytevector-length result))
  (test-equal "read-bytevector multi-block result has correct contents"
    test-bv result))

;; Finish the testsuite, and report results.
(test-end "t-mlg-bytevectors")
