# kaappi-redis

Redis client library for [Kaappi Scheme](https://github.com/kaappi/kaappi).

Pure Scheme RESP2 protocol implementation over a thin C TCP helper.
No dependency on hiredis.

## Build

```bash
make                    # builds libkaappi_redis.dylib (macOS) or .so (Linux)
```

## Usage

```bash
export DYLD_LIBRARY_PATH=/path/to/kaappi-redis   # macOS
# export LD_LIBRARY_PATH=/path/to/kaappi-redis    # Linux

kaappi --lib-path /path/to/kaappi-redis/lib your-script.scm
```

```scheme
(import (kaappi redis))

(define conn (redis-connect "127.0.0.1" 6379))

(redis-ping conn)              ; => "PONG"

(redis-set conn "key" "value") ; => "OK"
(redis-get conn "key")         ; => "value"

(redis-lpush conn "list" "a" "b" "c")
(redis-lrange conn "list" 0 -1)  ; => ("c" "b" "a")

(redis-hset conn "hash" "field" "val")
(redis-hgetall conn "hash")   ; => (("field" . "val"))

;; Pipelining
(redis-pipeline conn
  '("SET" "x" "1")
  '("SET" "y" "2")
  '("GET" "x"))               ; => ("OK" "OK" "1")

(redis-disconnect! conn)
```

## API

### Connection

| Procedure | Description |
|---|---|
| `(redis-connect host port)` | Connect to Redis, returns connection object |
| `(redis-connect host port password)` | Connect with AUTH |
| `(redis-disconnect! conn)` | Close connection |
| `(redis-connected? conn)` | Check if connected |
| `(redis-command conn cmd arg ...)` | Send any Redis command |
| `(redis-ping conn)` | PING |
| `(redis-select conn db)` | SELECT database |
| `(redis-auth conn password)` | AUTH |

### Strings

`redis-set`, `redis-get`, `redis-del`, `redis-exists`, `redis-expire`,
`redis-ttl`, `redis-incr`, `redis-decr`, `redis-keys`, `redis-mset`,
`redis-mget`, `redis-setnx`, `redis-setex`, `redis-append`, `redis-strlen`

### Lists

`redis-lpush`, `redis-rpush`, `redis-lpop`, `redis-rpop`, `redis-lrange`,
`redis-llen`, `redis-lindex`, `redis-lset`

### Hashes

`redis-hset`, `redis-hget`, `redis-hdel`, `redis-hgetall`, `redis-hexists`,
`redis-hkeys`, `redis-hvals`, `redis-hlen`

### Sets

`redis-sadd`, `redis-srem`, `redis-smembers`, `redis-sismember`, `redis-scard`

### Sorted Sets

`redis-zadd`, `redis-zrem`, `redis-zrange`, `redis-zrangebyscore`,
`redis-zscore`, `redis-zcard`, `redis-zrank`

### Pub/Sub

`redis-publish`, `redis-subscribe`

### Pipelining

`redis-pipeline`

### Server

`redis-dbsize`, `redis-info`, `redis-flushdb`, `redis-type`

## Reply Mapping

| Redis reply | Scheme value |
|---|---|
| Simple string (`+OK`) | `"OK"` |
| Bulk string | string |
| Null | `#f` |
| Integer | exact integer |
| Array | list |
| Error | raises Scheme error |

## Requirements

- [Kaappi](https://github.com/kaappi/kaappi) (with `(kaappi ffi)` support)
- C compiler (for the TCP helper library)
- Redis server

## Tests

```bash
# Offline RESP codec tests (no Redis needed)
kaappi --lib-path lib tests/test-resp.scm

# Full command tests (requires Redis on 127.0.0.1:6379)
DYLD_LIBRARY_PATH=. kaappi --lib-path lib tests/test-commands.scm
```

## License

MIT
