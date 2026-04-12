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
(test-end "t-mlg-math")
