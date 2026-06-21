(define-library (kaappi redis net)
  (import (kaappi net))
  (export tcp-connect tcp-send tcp-recv tcp-close tcp-last-error))
