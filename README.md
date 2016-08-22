## benchmark-ips for racket

This is my port of @evanphx's benchmark-ips for ruby to racket.

### Example Usage:

```racket

(define (fib1 n)
  (if (<= n 1) n (+ (fib1 (- n 1)) (fib1 (- n 2)))))

(define (fib2 n)
  (let fib-iter ([a 1] [b 0] [count n])
    (if (= count 0) b (fib-iter (+ a b) a (- count 1)))))

(benchmark/ips
  "(fib1 12)" (fib1 12)
  "(fib2 12)" (fib2 12)
  "(fib1 35)" (fib1 35)
  "(fib2 35)" (fib2 35))
```

### Output:

```
run:

           (fib2 12):    3.780M (±   0.0%) i/s -    7.560M in  2.000000s
           (fib2 35):    2.782M (±   0.0%) i/s -    5.564M in  2.000000s
           (fib1 35):    6.839  (±  40.8%) i/s -   14.000  in  2.047093s
           (fib1 12):  433.626k (±   0.0%) i/s -  867.252k in  2.000000s

comparison:

           (fib2 12):    7.560M i/s
           (fib2 35):    5.564M i/s -     1.36  x slower
           (fib1 12):  867.252k i/s -     8.72  x slower
           (fib1 35):   14.000  i/s -   539.98k x slower
```
