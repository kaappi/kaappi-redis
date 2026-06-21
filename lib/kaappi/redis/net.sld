(define-library (kaappi redis net)
  (import (scheme base) (kaappi ffi))
  (export tcp-connect tcp-send tcp-recv tcp-close tcp-last-error)
  (begin

    (define %lib (ffi-open "libkaappi_redis"))

    ;; kr_tcp_connect: (string, int, int) -> int
    (define %connect
      (ffi-fn %lib "kr_tcp_connect" '(string int int) 'int))

    ;; kr_tcp_send: (pointer, pointer, long) -> int
    (define %send
      (ffi-fn %lib "kr_tcp_send" '(pointer pointer long) 'int))

    ;; kr_tcp_recv: (pointer, pointer, long) -> int
    (define %recv
      (ffi-fn %lib "kr_tcp_recv" '(pointer pointer long) 'int))

    ;; kr_tcp_close: (int) -> int
    (define %close
      (ffi-fn %lib "kr_tcp_close" '(int) 'int))

    ;; kr_last_error: () -> int
    (define %last-error
      (ffi-fn %lib "kr_last_error" '() 'int))

    ;; Connect to host:port with optional timeout (default 5000ms).
    ;; Returns fd (integer) or raises error.
    (define (tcp-connect host port . args)
      (let ((timeout (if (pair? args) (car args) 5000)))
        (let ((fd (%connect host port timeout)))
          (if (< fd 0)
              (error "tcp-connect failed" host port (%last-error))
              fd))))

    ;; Send bytes from bytevector (or raw pointer) to fd.
    ;; C signature is (pointer buf, pointer fd_ptr, long len),
    ;; so we pass buf first, fd second.
    (define (tcp-send fd buf len)
      (let ((n (%send buf fd len)))
        (if (< n 0)
            (error "tcp-send failed" (%last-error))
            n)))

    ;; Receive up to len bytes into bytevector (or at raw pointer) from fd.
    ;; Returns bytes read (0 = EOF) or raises error.
    (define (tcp-recv fd buf len)
      (let ((n (%recv buf fd len)))
        (if (< n 0)
            (error "tcp-recv failed" (%last-error))
            n)))

    (define (tcp-close fd)
      (let ((rc (%close fd)))
        (if (< rc 0)
            (error "tcp-close failed" (%last-error))
            rc)))

    (define (tcp-last-error)
      (%last-error))))
