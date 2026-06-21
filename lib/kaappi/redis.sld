(define-library (kaappi redis)
  (import (kaappi redis net)
          (kaappi redis resp)
          (kaappi redis commands))
  (export
    ;; Connection
    redis-connect redis-disconnect! redis-connected?
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
    redis-dbsize redis-info redis-type))
