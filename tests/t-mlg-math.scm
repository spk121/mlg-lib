(use-modules (srfi srfi-64)
             (mlg math))

(test-begin "t-mlg-math")

;; add-num-or-false
(test-equal "add-num-or-false no args returns 0"    0 (add-num-or-false))
(test-equal "add-num-or-false single number"        1 (add-num-or-false 1))
(test-equal "add-num-or-false single non-number"   #f (add-num-or-false #f))
(test-equal "add-num-or-false two numbers"          3 (add-num-or-false 1 2))
(test-equal "add-num-or-false number then non-number" #f (add-num-or-false 1 #f))
(test-equal "add-num-or-false three numbers"        6 (add-num-or-false 1 2 3))

;; binomial-coefficient
(test-equal "binomial-coefficient 1 choose 0"   1   (binomial-coefficient 1 0))
(test-equal "binomial-coefficient 1 choose 1"   1   (binomial-coefficient 1 1))
(test-equal "binomial-coefficient 13 choose 0"  1   (binomial-coefficient 13 0))
(test-equal "binomial-coefficient 13 choose 1"  13  (binomial-coefficient 13 1))
(test-equal "binomial-coefficient 13 choose 2"  78  (binomial-coefficient 13 2))
(test-equal "binomial-coefficient 13 choose 3"  286 (binomial-coefficient 13 3))
;; k > n must return 0
(test-equal "binomial-coefficient k > n returns 0" 0 (binomial-coefficient 3 5))

;; cast-int32-to-uint32
;; Bug fix: logand used #x7fffffff instead of #xffffffff, causing
;; INT32_MIN (-2147483648) to map to 4294967296 instead of 2147483648.
(test-equal "cast-int32-to-uint32 zero"       0          (cast-int32-to-uint32 0))
(test-equal "cast-int32-to-uint32 one"        1          (cast-int32-to-uint32 1))
(test-equal "cast-int32-to-uint32 INT32_MAX"  2147483647 (cast-int32-to-uint32 2147483647))
(test-equal "cast-int32-to-uint32 -1"         4294967295 (cast-int32-to-uint32 -1))
(test-equal "cast-int32-to-uint32 INT32_MIN"  2147483648 (cast-int32-to-uint32 -2147483648))

;; cast-uint32-to-int32
(test-equal "cast-uint32-to-int32 zero"       0           (cast-uint32-to-int32 0))
(test-equal "cast-uint32-to-int32 INT32_MAX"  2147483647  (cast-uint32-to-int32 2147483647))
(test-equal "cast-uint32-to-int32 INT32_MAX+1" -2147483648 (cast-uint32-to-int32 2147483648))
(test-equal "cast-uint32-to-int32 UINT32_MAX" -1           (cast-uint32-to-int32 4294967295))

;; legendre-polynomial
;; Hard-coded cases n=0..4.
(test-equal "legendre-polynomial P_0(0)"   1    (legendre-polynomial 0 0))
(test-equal "legendre-polynomial P_1(0)"   0    (legendre-polynomial 1 0))
(test-equal "legendre-polynomial P_1(1)"   1    (legendre-polynomial 1 1))
(test-equal "legendre-polynomial P_2(0)"  -1/2  (legendre-polynomial 2 0))
(test-equal "legendre-polynomial P_2(1)"   1    (legendre-polynomial 2 1))
(test-equal "legendre-polynomial P_3(0)"   0    (legendre-polynomial 3 0))
(test-equal "legendre-polynomial P_3(1)"   1    (legendre-polynomial 3 1))
(test-equal "legendre-polynomial P_4(0)"   3/8  (legendre-polynomial 4 0))
(test-equal "legendre-polynomial P_4(1)"   1    (legendre-polynomial 4 1))
;; General case n>=5: bug was (expt 1 ...) instead of (expt x ...), which
;; always evaluated to 1 regardless of x, giving wrong results.
(test-equal "legendre-polynomial P_5(0) general case"  0    (legendre-polynomial 5 0))
(test-equal "legendre-polynomial P_5(1) general case"  1    (legendre-polynomial 5 1))
(test-equal "legendre-polynomial P_6(0) general case" -5/16 (legendre-polynomial 6 0))
(test-equal "legendre-polynomial P_6(1) general case"  1    (legendre-polynomial 6 1))

;; gauss-legendre-quadrature
;; Bug fix 1: n=4 node table had only 3 entries (missing one node and had a
;; wrong sign), causing an out-of-range error when n=4 was used.
;; Bug fix 2: a debug (format #t ...) call was removed.
;; Integrate the constant function 1 over [-1,1]; exact result is 2.
(test-assert "gauss-legendre-quadrature n=2 integral of 1"
  (< (abs (- (gauss-legendre-quadrature (lambda (x) 1.0) 2) 2.0)) 1e-9))
(test-assert "gauss-legendre-quadrature n=3 integral of 1"
  (< (abs (- (gauss-legendre-quadrature (lambda (x) 1.0) 3) 2.0)) 1e-9))
(test-assert "gauss-legendre-quadrature n=4 integral of 1"
  (< (abs (- (gauss-legendre-quadrature (lambda (x) 1.0) 4) 2.0)) 1e-9))
;; Integrate x^2 over [-1,1]; exact result is 2/3.
(test-assert "gauss-legendre-quadrature n=4 integral of x^2"
  (< (abs (- (gauss-legendre-quadrature (lambda (x) (* x x)) 4) (/ 2.0 3.0))) 1e-9))

;; Numerical differentiation
;; deriv2F: forward two-point formula  f'(x) ~= (f(x+h) - f(x)) / h
;; Bug fix: was computing (f(x-h) - f(x)) / h (backward difference, negated).
;; Using f(x)=x^2, f'(x)=2x; at x=3 the derivative is 6.
(test-assert "deriv2F forward two-point approximates x^2 derivative"
  (< (abs (- (deriv2F (lambda (x) (* x x)) 3.0 1e-5) 6.0)) 1e-4))

;; deriv2: centered two-point formula  f'(x) ~= (f(x+h) - f(x-h)) / (2h)
(test-assert "deriv2 centered two-point approximates x^2 derivative"
  (< (abs (- (deriv2 (lambda (x) (* x x)) 3.0 1e-5) 6.0)) 1e-8))

;; deriv3F: forward three-point formula
(test-assert "deriv3F forward three-point approximates x^2 derivative"
  (< (abs (- (deriv3F (lambda (x) (* x x)) 3.0 1e-4) 6.0)) 1e-6))

;; array-absolute-sum-of-slice
;; 3x2 array:  row 0: [1, -2]   row 1: [3, -4]   row 2: [5, -6]
(let ((arr (make-array 0 3 2)))
  (array-set! arr  1 0 0) (array-set! arr -2 0 1)
  (array-set! arr  3 1 0) (array-set! arr -4 1 1)
  (array-set! arr  5 2 0) (array-set! arr -6 2 1)
  (test-equal "array-absolute-sum-of-slice row 0"  3  (array-absolute-sum-of-slice arr 0 0))
  (test-equal "array-absolute-sum-of-slice row 1"  7  (array-absolute-sum-of-slice arr 0 1))
  (test-equal "array-absolute-sum-of-slice row 2" 11  (array-absolute-sum-of-slice arr 0 2))
  (test-equal "array-absolute-sum-of-slice col 0"  9  (array-absolute-sum-of-slice arr 1 0))
  (test-equal "array-absolute-sum-of-slice col 1" 12  (array-absolute-sum-of-slice arr 1 1)))

;; array-rotate-slice-pairs!
;;
;; Identity rotation (theta=0): both slices must be unchanged.
(let ((arr (make-array 0.0 2 3)))
  (array-set! arr 1.0 0 0) (array-set! arr 2.0 0 1) (array-set! arr 3.0 0 2)
  (array-set! arr 4.0 1 0) (array-set! arr 5.0 1 1) (array-set! arr 6.0 1 2)
  (array-rotate-slice-pairs! arr 0 0 1 0.0)
  (test-assert "array-rotate-slice-pairs! identity preserves A[0]" (< (abs (- (array-ref arr 0 0) 1.0)) 1e-14))
  (test-assert "array-rotate-slice-pairs! identity preserves A[2]" (< (abs (- (array-ref arr 0 2) 3.0)) 1e-14))
  (test-assert "array-rotate-slice-pairs! identity preserves B[0]" (< (abs (- (array-ref arr 1 0) 4.0)) 1e-14))
  (test-assert "array-rotate-slice-pairs! identity preserves B[2]" (< (abs (- (array-ref arr 1 2) 6.0)) 1e-14)))

;; Quarter-turn (theta=pi/2): new A = B, new B = -A.
;; A = row 0 = [1, 2], B = row 1 = [3, 4]
;; Expected: row 0 -> [3, 4], row 1 -> [-1, -2]
(let ((arr  (make-array 0.0 2 2))
      (pi/2 (* 2.0 (atan 1.0))))
  (array-set! arr 1.0 0 0) (array-set! arr 2.0 0 1)
  (array-set! arr 3.0 1 0) (array-set! arr 4.0 1 1)
  (array-rotate-slice-pairs! arr 0 0 1 pi/2)
  (test-assert "array-rotate-slice-pairs! quarter-turn new-A[0]"  (< (abs (- (array-ref arr 0 0)  3.0)) 1e-10))
  (test-assert "array-rotate-slice-pairs! quarter-turn new-A[1]"  (< (abs (- (array-ref arr 0 1)  4.0)) 1e-10))
  (test-assert "array-rotate-slice-pairs! quarter-turn new-B[0]"  (< (abs (- (array-ref arr 1 0) -1.0)) 1e-10))
  (test-assert "array-rotate-slice-pairs! quarter-turn new-B[1]"  (< (abs (- (array-ref arr 1 1) -2.0)) 1e-10)))

;; Quarter-turn with idx2 < idx1 (idx1=1, idx2=0).
;; A = row 1 = [1, 2], B = row 0 = [3, 4], theta=pi/2
;; Expected: row 1 -> [3, 4], row 0 -> [-1, -2]
;; This exercises the "save both slices" logic: without saving B before the
;; rotation pass, B (row 0) would be overwritten before the A (row 1) elements
;; are processed, because row 0 < row 1 in iteration order.
(let ((arr  (make-array 0.0 2 2))
      (pi/2 (* 2.0 (atan 1.0))))
  (array-set! arr 3.0 0 0) (array-set! arr 4.0 0 1)   ; row 0 = B
  (array-set! arr 1.0 1 0) (array-set! arr 2.0 1 1)   ; row 1 = A
  (array-rotate-slice-pairs! arr 0 1 0 pi/2)
  (test-assert "array-rotate-slice-pairs! idx2<idx1 new-A[0]"  (< (abs (- (array-ref arr 1 0)  3.0)) 1e-10))
  (test-assert "array-rotate-slice-pairs! idx2<idx1 new-A[1]"  (< (abs (- (array-ref arr 1 1)  4.0)) 1e-10))
  (test-assert "array-rotate-slice-pairs! idx2<idx1 new-B[0]"  (< (abs (- (array-ref arr 0 0) -1.0)) 1e-10))
  (test-assert "array-rotate-slice-pairs! idx2<idx1 new-B[1]"  (< (abs (- (array-ref arr 0 1) -2.0)) 1e-10)))

;; make-2d-f32-array and friends
;; Bug fix: the exported names had no matching definitions because the
;; internal function was named f32-2d-make-array instead of f32d2-make-array,
;; and no aliases existed for the exported names.
(test-assert "make-2d-f32-array returns a typed array"
  (typed-array? (make-2d-f32-array 3 4) 'f32))
(test-equal "make-2d-f32-array shape"
  '((1 3) (1 4)) (array-shape (make-2d-f32-array 3 4)))
(test-equal "make-2d-f32-column-vector shape"
  '((1 5) (1 1)) (array-shape (make-2d-f32-column-vector 5)))
(test-equal "make-2d-f32-row-vector shape"
  '((1 1) (1 6)) (array-shape (make-2d-f32-row-vector 6)))
(test-equal "transpose-2d-f32-array swaps dimensions"
  '((1 4) (1 3)) (array-shape (transpose-2d-f32-array (make-2d-f32-array 3 4))))

;; Finish the testsuite, and report results.

;; real->integer, a pure Scheme version of the C function
(test-equal "real->integer truncates positive" 3 (real->integer 3.7))
(test-equal "real->integer truncates negative" -3 (real->integer -3.7))
(test-equal "real->integer exact rational" -3 (real->integer -7/2))
(test-equal "real->integer is exact" #t (exact? (real->integer 2.0)))
(test-equal "real->integer largest fixnum"
  most-positive-fixnum (real->integer most-positive-fixnum))
(test-error "real->integer too large" 'out-of-range (real->integer 1e19))
(test-error "real->integer NaN" 'out-of-range (real->integer +nan.0))
(test-error "real->integer infinity" 'out-of-range (real->integer -inf.0))
(test-error "real->integer non-number" 'wrong-type-arg (real->integer "1"))

(test-end "t-mlg-math")
