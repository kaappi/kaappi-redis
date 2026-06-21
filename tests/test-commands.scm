;; Live Redis command tests (requires Redis on 127.0.0.1:6379)
(import (scheme base) (scheme write) (kaappi redis))

(define pass 0)
(define fail 0)

(define (check name expected actual)
  (if (equal? expected actual)
      (begin (set! pass (+ pass 1))
             (display "  PASS: ") (display name) (newline))
      (begin (set! fail (+ fail 1))
             (display "  FAIL: ") (display name) (newline)
             (display "    expected: ") (write expected) (newline)
             (display "    got:      ") (write actual) (newline))))

(define conn (redis-connect "127.0.0.1" 6379))
(redis-select conn 15)
(redis-flushdb conn)

;; --- PING ---
(display "=== Server ===") (newline)
(check "ping" "PONG" (redis-ping conn))
(check "dbsize" 0 (redis-dbsize conn))

;; --- Strings ---
(display "=== Strings ===") (newline)
(check "set" "OK" (redis-set conn "k1" "hello"))
(check "get" "hello" (redis-get conn "k1"))
(check "get missing" #f (redis-get conn "no-such-key"))
(check "strlen" 5 (redis-strlen conn "k1"))
(check "append" 11 (redis-append conn "k1" " world"))
(check "get after append" "hello world" (redis-get conn "k1"))
(check "setnx new" #t (redis-setnx conn "k2" "val"))
(check "setnx existing" #f (redis-setnx conn "k2" "other"))
(check "del" 1 (redis-del conn "k2"))
(check "exists yes" #t (redis-exists conn "k1"))
(check "exists no" #f (redis-exists conn "k2"))

(redis-set conn "counter" "10")
(check "incr" 11 (redis-incr conn "counter"))
(check "decr" 10 (redis-decr conn "counter"))

(check "expire" #t (redis-expire conn "k1" 60))
(check "ttl" #t (> (redis-ttl conn "k1") 0))

(redis-mset conn "a" "1" "b" "2" "c" "3")
(check "mget" '("1" "2" "3") (redis-mget conn "a" "b" "c"))

(check "type" "string" (redis-type conn "a"))

;; --- Lists ---
(display "=== Lists ===") (newline)
(check "rpush" 3 (redis-rpush conn "lst" "a" "b" "c"))
(check "lpush" 4 (redis-lpush conn "lst" "z"))
(check "llen" 4 (redis-llen conn "lst"))
(check "lrange" '("z" "a" "b" "c") (redis-lrange conn "lst" 0 -1))
(check "lindex" "b" (redis-lindex conn "lst" 2))
(check "lset" "OK" (redis-lset conn "lst" 2 "B"))
(check "lpop" "z" (redis-lpop conn "lst"))
(check "rpop" "c" (redis-rpop conn "lst"))

;; --- Hashes ---
(display "=== Hashes ===") (newline)
(check "hset" 1 (redis-hset conn "h" "f1" "v1"))
(redis-hset conn "h" "f2" "v2")
(check "hget" "v1" (redis-hget conn "h" "f1"))
(check "hget missing" #f (redis-hget conn "h" "nope"))
(check "hexists yes" #t (redis-hexists conn "h" "f1"))
(check "hexists no" #f (redis-hexists conn "h" "nope"))
(check "hlen" 2 (redis-hlen conn "h"))
(check "hkeys" '("f1" "f2") (redis-hkeys conn "h"))
(check "hvals" '("v1" "v2") (redis-hvals conn "h"))
(check "hgetall" '(("f1" . "v1") ("f2" . "v2")) (redis-hgetall conn "h"))
(check "hdel" 1 (redis-hdel conn "h" "f1"))

;; --- Sets ---
(display "=== Sets ===") (newline)
(check "sadd" 3 (redis-sadd conn "s" "x" "y" "z"))
(check "scard" 3 (redis-scard conn "s"))
(check "sismember yes" #t (redis-sismember conn "s" "x"))
(check "sismember no" #f (redis-sismember conn "s" "w"))
(check "srem" 1 (redis-srem conn "s" "x"))

;; --- Sorted sets ---
(display "=== Sorted Sets ===") (newline)
(redis-zadd conn "zs" 1 "a")
(redis-zadd conn "zs" 2 "b")
(redis-zadd conn "zs" 3 "c")
(check "zcard" 3 (redis-zcard conn "zs"))
(check "zscore" "2" (redis-zscore conn "zs" "b"))
(check "zrank" 0 (redis-zrank conn "zs" "a"))
(check "zrange" '("a" "b" "c") (redis-zrange conn "zs" 0 -1))

;; --- Pipelining ---
(display "=== Pipelining ===") (newline)
(redis-set conn "p1" "one")
(redis-set conn "p2" "two")
(let ((results (redis-pipeline conn
                 '("GET" "p1")
                 '("GET" "p2")
                 '("DBSIZE"))))
  (check "pipeline get 1" "one" (car results))
  (check "pipeline get 2" "two" (cadr results))
  (check "pipeline dbsize" #t (number? (caddr results))))

;; --- Keys ---
(display "=== Keys ===") (newline)
(let ((keys (redis-keys conn "p*")))
  (check "keys count" 2 (length keys)))

;; --- Cleanup ---
(redis-flushdb conn)
(redis-disconnect! conn)

(newline)
(display "=== Results: ")
(display pass) (display " passed, ")
(display fail) (display " failed ===")
(newline)

(when (> fail 0) (exit 1))
