(import (scheme base) (scheme write) (kaappi redis))

(define conn (redis-connect "127.0.0.1" 6379))

(display (redis-ping conn))
(newline)

;; Strings
(redis-set conn "greeting" "hello from kaappi!")
(display (redis-get conn "greeting"))
(newline)

;; Counter
(redis-set conn "visits" "0")
(redis-incr conn "visits")
(redis-incr conn "visits")
(redis-incr conn "visits")
(display "visits: ")
(display (redis-get conn "visits"))
(newline)

;; Lists
(redis-del conn "fruits")
(redis-rpush conn "fruits" "apple" "banana" "cherry")
(display "fruits: ")
(display (redis-lrange conn "fruits" 0 -1))
(newline)

;; Hashes
(redis-hset conn "user:1" "name" "Alice")
(redis-hset conn "user:1" "email" "alice@example.com")
(display "user:1 = ")
(display (redis-hgetall conn "user:1"))
(newline)

;; Pipelining
(display "pipeline: ")
(display (redis-pipeline conn
           '("SET" "x" "100")
           '("SET" "y" "200")
           '("GET" "x")
           '("GET" "y")))
(newline)

;; Cleanup
(redis-del conn "greeting" "visits" "fruits" "user:1" "x" "y")
(redis-disconnect! conn)
