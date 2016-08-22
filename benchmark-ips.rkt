#lang racket/base

(provide benchmark/ips)

(require racket/format)
(require math/statistics)
(require syntax/parse/define)           ; define-syntax-parser
(require (for-syntax racket/base))      ; syntax

(require racket/function)

(define now current-inexact-milliseconds)

(define (~f w p f) (~r f #:min-width w #:precision `(= ,p) ))
(define (~str w s) (~a s #:min-width w #:align 'right))

(define log10
  (let ([LN10 (log 10)])
    (lambda (n) (/ (log n) LN10))))

(define (~num width precision value)
  (define scale (inexact->exact (floor (/ (log10 value) 3))))
  (define suffix (case scale
                   [(1) "k"] [(2) "M"] [(3) "B"] [(4) "T"] [(5) "Q"]
                   [else (set! scale 0) " "]))
  (format "~a~a" (~f width precision (/ value (expt 1000 scale))) suffix))

(define (format-stats name stats ms)
  (define sec (/ ms 1000))
  (format "~a: ~a (± ~a%) i/s - ~a in ~as"
          (~str 20 name)
          (~num 8 3 (/ (statistics-count stats) sec))
          (~f 5 1 (statistics-stddev stats))
          (~num 8 3 (inexact->exact (statistics-count stats)))
          (~f 9 6 sec)))

(define (format-compare name stats [fastest-count #f])
  (define count (statistics-count stats))
  (format "~a: ~a i/s~a"
          (~str 20 name)
          (~num 8 3 (inexact->exact count))
          (if fastest-count
              (format " - ~a x slower" (~num 8 2 (/ fastest-count count)))
              "")))

(define (benchmark/ips/1 name f #:time [seconds 2])
  (let ([max-ms     (* 1000 seconds)]
        [start-time (now)])
    (let-values ([(end-time stats)
                  (for/fold ([t0 start-time]
                             [s empty-statistics])
                            ([t1 (in-producer now)]
                             #:final (>= (- t1 start-time) max-ms))
                    (f)
                    (values t1 (update-statistics s (- t1 t0))))])
      (define total-time (- end-time start-time))
      (values stats total-time))))

(define (benchmark/ips/* benchmarks #:time [seconds 2])
  (printf "run:~n~n")
  (define stats (for/list ([(name thunk) (in-hash benchmarks)])
                  (define-values (stats ms) (benchmark/ips/1 name thunk #:time seconds))
                  (benchmark/report name stats ms)
                  (cons name stats)))
  (define sorted (sort stats
                       >
                       #:key (lambda (x) (inexact->exact (statistics-count (cdr x))))
                       #:cache-keys? #t))
  (benchmark/compare sorted))

(define (benchmark/report name stats ms)
  (printf "~a~n" (format-stats name stats ms)))

(define (benchmark/compare stats)
  (define fastest (car stats))
  (define fastest-name (car fastest))
  (define fastest-count (statistics-count (cdr fastest)))

  (printf "~ncomparison:~n~n")
  (printf "~a~n" (format-compare fastest-name (cdr fastest)))

  (for ([stat (cdr stats)])
    (define name (car stat))
    (printf "~a~n" (format-compare name (cdr stat) fastest-count))))

(define-syntax-parser benchmark/ips
  [(_ #:time seconds {~seq k v} ...)
   #'(benchmark/ips/* #:time seconds (make-hash (list (cons k (thunk v)) ...)))]
  [(_ {~seq k v} ...)
   #'(benchmark/ips/* #:time 2       (make-hash (list (cons k (thunk v)) ...)))])

(module+ main
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Implementation:

  (define (fib1 n)
    (if (<= n 1) n (+ (fib1 (- n 1)) (fib1 (- n 2)))))

  (define (fib2 n)
    (let fib-iter ([a 1] [b 0] [count n])
      (if (= count 0) b (fib-iter (+ a b) a (- count 1)))))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Benchmarks:

  (benchmark/ips
   "(fib1 12)" (fib1 12)
   "(fib2 12)" (fib2 12)
   "(fib1 35)" (fib1 35)
   "(fib2 35)" (fib2 35)))
