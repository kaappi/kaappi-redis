(define-library (kaappi redis commands)
  (import (scheme base) (kaappi redis net) (kaappi redis resp))
  (export redis-connect redis-disconnect! redis-connected?
          redis-command redis-ping redis-auth redis-select redis-flushdb
          ;; Strings
          redis-set redis-get redis-del redis-exists
          redis-expire redis-ttl redis-incr redis-decr redis-keys
          redis-mset redis-mget redis-setnx redis-setex
          redis-append redis-strlen
          ;; Lists
          redis-lpush redis-rpush redis-lpop redis-rpop
          redis-lrange redis-llen redis-lindex redis-lset
          ;; Hashes
          redis-hset redis-hget redis-hdel redis-hgetall
          redis-hexists redis-hkeys redis-hvals redis-hlen
          ;; Sets
          redis-sadd redis-srem redis-smembers redis-sismember redis-scard
          ;; Sorted sets
          redis-zadd redis-zrem redis-zrange redis-zrangebyscore
          redis-zscore redis-zcard redis-zrank
          ;; Pub/Sub
          redis-publish redis-subscribe
          ;; Pipelining
          redis-pipeline
          ;; Server
          redis-dbsize redis-info redis-type)
  (begin

    ;; --- Connection record ---

    (define-record-type <redis-connection>
      (%make-redis-connection fd buf host port)
      redis-connection?
      (fd   redis-conn-fd  set-redis-conn-fd!)
      (buf  redis-conn-buf)
      (host redis-conn-host)
      (port redis-conn-port))

    (define (redis-connect host port . args)
      (let* ((password (if (pair? args) (car args) #f))
             (timeout  (if (and (pair? args) (pair? (cdr args)))
                           (cadr args) 5000))
             (fd  (tcp-connect host port timeout))
             (buf (make-resp-buffer fd))
             (conn (%make-redis-connection fd buf host port)))
        (when password
          (redis-auth conn password))
        conn))

    (define (redis-disconnect! conn)
      (when (redis-connected? conn)
        (tcp-close (redis-conn-fd conn))
        (set-redis-conn-fd! conn -1)))

    (define (redis-connected? conn)
      (>= (redis-conn-fd conn) 0))

    ;; --- Generic command ---

    (define (redis-command conn . args)
      (unless (redis-connected? conn)
        (error "Redis connection is closed"))
      (resp-send-command (redis-conn-fd conn) args)
      (resp-read-reply (redis-conn-buf conn)))

    ;; --- Server ---

    (define (redis-ping conn)
      (redis-command conn "PING"))

    (define (redis-auth conn password)
      (let ((reply (redis-command conn "AUTH" password)))
        (unless (equal? reply "OK")
          (redis-disconnect! conn)
          (error "Redis AUTH failed" reply))
        reply))

    (define (redis-select conn db)
      (redis-command conn "SELECT" (number->string db)))

    (define (redis-flushdb conn)
      (redis-command conn "FLUSHDB"))

    (define (redis-dbsize conn)
      (redis-command conn "DBSIZE"))

    (define (redis-info conn . args)
      (if (pair? args)
          (redis-command conn "INFO" (car args))
          (redis-command conn "INFO")))

    (define (redis-type conn key)
      (redis-command conn "TYPE" key))

    ;; --- Strings ---

    (define (redis-set conn key value . args)
      (if (pair? args)
          (apply redis-command conn "SET" key value args)
          (redis-command conn "SET" key value)))

    (define (redis-get conn key)
      (redis-command conn "GET" key))

    (define (redis-del conn . keys)
      (apply redis-command conn "DEL" keys))

    (define (redis-exists conn key)
      (= 1 (redis-command conn "EXISTS" key)))

    (define (redis-expire conn key seconds)
      (= 1 (redis-command conn "EXPIRE" key (number->string seconds))))

    (define (redis-ttl conn key)
      (redis-command conn "TTL" key))

    (define (redis-incr conn key)
      (redis-command conn "INCR" key))

    (define (redis-decr conn key)
      (redis-command conn "DECR" key))

    (define (redis-keys conn pattern)
      (redis-command conn "KEYS" pattern))

    (define (redis-mset conn . pairs)
      (apply redis-command conn "MSET" pairs))

    (define (redis-mget conn . keys)
      (apply redis-command conn "MGET" keys))

    (define (redis-setnx conn key value)
      (= 1 (redis-command conn "SETNX" key value)))

    (define (redis-setex conn key seconds value)
      (redis-command conn "SETEX" key (number->string seconds) value))

    (define (redis-append conn key value)
      (redis-command conn "APPEND" key value))

    (define (redis-strlen conn key)
      (redis-command conn "STRLEN" key))

    ;; --- Lists ---

    (define (redis-lpush conn key . values)
      (apply redis-command conn "LPUSH" key values))

    (define (redis-rpush conn key . values)
      (apply redis-command conn "RPUSH" key values))

    (define (redis-lpop conn key)
      (redis-command conn "LPOP" key))

    (define (redis-rpop conn key)
      (redis-command conn "RPOP" key))

    (define (redis-lrange conn key start stop)
      (redis-command conn "LRANGE" key
        (number->string start) (number->string stop)))

    (define (redis-llen conn key)
      (redis-command conn "LLEN" key))

    (define (redis-lindex conn key index)
      (redis-command conn "LINDEX" key (number->string index)))

    (define (redis-lset conn key index value)
      (redis-command conn "LSET" key (number->string index) value))

    ;; --- Hashes ---

    (define (redis-hset conn key field value)
      (redis-command conn "HSET" key field value))

    (define (redis-hget conn key field)
      (redis-command conn "HGET" key field))

    (define (redis-hdel conn key . fields)
      (apply redis-command conn "HDEL" key fields))

    (define (redis-hgetall conn key)
      (let ((flat (redis-command conn "HGETALL" key)))
        (let loop ((lst flat) (acc '()))
          (if (or (null? lst) (null? (cdr lst)))
              (reverse acc)
              (loop (cddr lst)
                    (cons (cons (car lst) (cadr lst)) acc))))))

    (define (redis-hexists conn key field)
      (= 1 (redis-command conn "HEXISTS" key field)))

    (define (redis-hkeys conn key)
      (redis-command conn "HKEYS" key))

    (define (redis-hvals conn key)
      (redis-command conn "HVALS" key))

    (define (redis-hlen conn key)
      (redis-command conn "HLEN" key))

    ;; --- Sets ---

    (define (redis-sadd conn key . members)
      (apply redis-command conn "SADD" key members))

    (define (redis-srem conn key . members)
      (apply redis-command conn "SREM" key members))

    (define (redis-smembers conn key)
      (redis-command conn "SMEMBERS" key))

    (define (redis-sismember conn key member)
      (= 1 (redis-command conn "SISMEMBER" key member)))

    (define (redis-scard conn key)
      (redis-command conn "SCARD" key))

    ;; --- Sorted sets ---

    (define (redis-zadd conn key score member)
      (redis-command conn "ZADD" key (number->string score) member))

    (define (redis-zrem conn key . members)
      (apply redis-command conn "ZREM" key members))

    (define (redis-zrange conn key start stop . args)
      (if (and (pair? args) (car args))
          (redis-command conn "ZRANGE" key
            (number->string start) (number->string stop) "WITHSCORES")
          (redis-command conn "ZRANGE" key
            (number->string start) (number->string stop))))

    (define (redis-zrangebyscore conn key min max)
      (redis-command conn "ZRANGEBYSCORE" key min max))

    (define (redis-zscore conn key member)
      (redis-command conn "ZSCORE" key member))

    (define (redis-zcard conn key)
      (redis-command conn "ZCARD" key))

    (define (redis-zrank conn key member)
      (redis-command conn "ZRANK" key member))

    ;; --- Pub/Sub ---

    (define (redis-publish conn channel message)
      (redis-command conn "PUBLISH" channel message))

    (define (redis-subscribe conn channel handler)
      (resp-send-command (redis-conn-fd conn) (list "SUBSCRIBE" channel))
      (let ((buf (redis-conn-buf conn)))
        (let loop ()
          (let ((reply (resp-read-reply buf)))
            (when (and (list? reply) (>= (length reply) 3))
              (let ((type (car reply)))
                (cond
                  ((equal? type "message")
                   (let ((ch  (cadr reply))
                         (msg (caddr reply)))
                     (when (handler ch msg)
                       (loop))))
                  (else (loop)))))))))

    ;; --- Pipelining ---

    (define (redis-pipeline conn . command-lists)
      (let ((fd (redis-conn-fd conn))
            (buf (redis-conn-buf conn)))
        (for-each
          (lambda (cmd) (resp-send-command fd cmd))
          command-lists)
        (map (lambda (_) (resp-read-reply buf))
             command-lists)))))
