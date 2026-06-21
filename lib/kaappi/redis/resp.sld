(define-library (kaappi redis resp)
  (import (scheme base) (kaappi ffi) (kaappi redis net))
  (export make-resp-buffer resp-buffer?
          resp-encode-command resp-read-reply
          resp-send-command)
  (begin

    ;; --- Buffer record ---

    (define-record-type <resp-buffer>
      (%make-resp-buffer bv pos end fd)
      resp-buffer?
      (bv  resp-buf-bv)
      (pos resp-buf-pos  set-resp-buf-pos!)
      (end resp-buf-end  set-resp-buf-end!)
      (fd  resp-buf-fd))

    (define *buf-size* 8192)

    (define (make-resp-buffer fd)
      (%make-resp-buffer (make-bytevector *buf-size* 0) 0 0 fd))

    ;; --- Buffer operations ---

    (define (buffer-available buf)
      (- (resp-buf-end buf) (resp-buf-pos buf)))

    (define (buffer-refill! buf)
      (let* ((bv  (resp-buf-bv buf))
             (pos (resp-buf-pos buf))
             (end (resp-buf-end buf))
             (rem (- end pos))
             (cap (bytevector-length bv)))
        (when (> pos 0)
          (when (> rem 0)
            (bytevector-copy! bv 0 bv pos end))
          (set-resp-buf-pos! buf 0)
          (set-resp-buf-end! buf rem))
        (let* ((rem2 (resp-buf-end buf))
               (space (- cap rem2)))
          (when (<= space 0)
            (error "RESP buffer full"))
          (let* ((base (ffi-bytevector-ptr bv))
                 (ptr  (+ base rem2))
                 (n    (tcp-recv (resp-buf-fd buf) ptr space)))
            (when (= n 0)
              (error "Connection closed by Redis"))
            (set-resp-buf-end! buf (+ rem2 n))))))

    (define (buffer-read-byte! buf)
      (when (= (buffer-available buf) 0)
        (buffer-refill! buf))
      (let ((b (bytevector-u8-ref (resp-buf-bv buf) (resp-buf-pos buf))))
        (set-resp-buf-pos! buf (+ (resp-buf-pos buf) 1))
        b))

    (define (buffer-read-bytes! buf n)
      (let ((result (make-bytevector n 0)))
        (let loop ((offset 0) (remaining n))
          (if (= remaining 0)
              result
              (let ((avail (buffer-available buf)))
                (if (= avail 0)
                    (begin (buffer-refill! buf)
                           (loop offset remaining))
                    (let ((take (min avail remaining)))
                      (bytevector-copy! result offset
                                        (resp-buf-bv buf)
                                        (resp-buf-pos buf)
                                        (+ (resp-buf-pos buf) take))
                      (set-resp-buf-pos! buf (+ (resp-buf-pos buf) take))
                      (loop (+ offset take) (- remaining take)))))))))

    ;; --- RESP line reader ---

    (define (resp-read-line buf)
      (let ((out (open-output-string)))
        (let loop ()
          (let ((b (buffer-read-byte! buf)))
            (cond
              ((= b 13)
               (let ((b2 (buffer-read-byte! buf)))
                 (if (= b2 10)
                     (get-output-string out)
                     (begin (write-char (integer->char b) out)
                            (write-char (integer->char b2) out)
                            (loop)))))
              (else
               (write-char (integer->char b) out)
               (loop)))))))

    ;; --- RESP encoder ---

    (define (resp-encode-command parts)
      (let ((out (open-output-string)))
        (write-char #\* out)
        (display (length parts) out)
        (display "\r\n" out)
        (for-each
          (lambda (part)
            (let* ((s (cond ((string? part) part)
                            ((number? part) (number->string part))
                            ((symbol? part) (symbol->string part))
                            (else (error "resp-encode: invalid argument" part))))
                   (bv (string->utf8 s))
                   (blen (bytevector-length bv)))
              (write-char #\$ out)
              (display blen out)
              (display "\r\n" out)
              (display s out)
              (display "\r\n" out)))
          parts)
        (get-output-string out)))

    ;; --- RESP decoder ---

    (define (resp-read-reply buf)
      (let ((type-byte (buffer-read-byte! buf)))
        (case (integer->char type-byte)
          ((#\+) (resp-read-line buf))
          ((#\-) (let ((msg (resp-read-line buf)))
                   (error "Redis error" msg)))
          ((#\:) (string->number (resp-read-line buf)))
          ((#\$) (resp-read-bulk-string buf))
          ((#\*) (resp-read-array buf))
          (else  (error "Unknown RESP type" type-byte)))))

    (define (resp-read-bulk-string buf)
      (let ((len (string->number (resp-read-line buf))))
        (if (= len -1)
            #f
            (let ((data (buffer-read-bytes! buf len)))
              (buffer-read-byte! buf)   ; \r
              (buffer-read-byte! buf)   ; \n
              (utf8->string data)))))

    (define (resp-read-array buf)
      (let ((count (string->number (resp-read-line buf))))
        (if (= count -1)
            #f
            (let loop ((i 0) (acc '()))
              (if (= i count)
                  (reverse acc)
                  (loop (+ i 1) (cons (resp-read-reply buf) acc)))))))

    ;; --- Send helper ---

    (define (resp-send-command fd parts)
      (let* ((cmd-str (resp-encode-command parts))
             (cmd-bv  (string->utf8 cmd-str))
             (len     (bytevector-length cmd-bv)))
        (let loop ((offset 0) (remaining len))
          (when (> remaining 0)
            (let* ((ptr (+ (ffi-bytevector-ptr cmd-bv) offset))
                   (n   (tcp-send fd ptr remaining)))
              (loop (+ offset n) (- remaining n)))))))))
