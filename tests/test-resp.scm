;; Offline RESP encoder tests (no Redis needed)
(import (scheme base) (scheme write) (kaappi redis resp))

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

(display "=== RESP Encoder Tests ===") (newline)

(check "PING"
  "*1\r\n$4\r\nPING\r\n"
  (resp-encode-command '("PING")))

(check "SET key value"
  "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n"
  (resp-encode-command '("SET" "key" "value")))

(check "GET key"
  "*2\r\n$3\r\nGET\r\n$3\r\nkey\r\n"
  (resp-encode-command '("GET" "key")))

(check "numeric args"
  "*3\r\n$6\r\nEXPIRE\r\n$3\r\nkey\r\n$2\r\n60\r\n"
  (resp-encode-command '("EXPIRE" "key" 60)))

(check "empty value"
  "*3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$0\r\n\r\n"
  (resp-encode-command '("SET" "key" "")))

(newline)
(display "=== Results: ")
(display pass) (display " passed, ")
(display fail) (display " failed ===")
(newline)

(when (> fail 0) (exit 1))
