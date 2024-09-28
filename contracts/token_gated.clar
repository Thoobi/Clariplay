(define-constant required-token-contract 'SP2C2Y9BRJKZB4K04PYEYZ3K8N8E7VGAQMJ7MJA5H.token)
(define-constant required-token-amount u100) ;; The minimum token balance required to access the gated content

(define-map user-access-tokens
  { user: principal }
  { last-access: uint }
)

;; Function to check the user's token balance in the token contract
(define-read-only (has-required-tokens (user principal))
  (>= (ft-get-balance required-token-contract user) required-token-amount)
)

;; Public function to check access and update last access time
(define-public (request-access)
  (let ((user tx-sender))
    (if (has-required-tokens user)
        (begin
          ;; Grant access and update the user's last access time
          (map-set user-access-tokens { user: user } { last-access: block-height })
          (ok true)
        )
        ;; Return an error if the user doesn't have the required tokens
        (err u200))
  )
)

;; Read-only function to check if the user has access
(define-read-only (check-access (user principal))
  (if (is-some (map-get? user-access-tokens { user: user }))
      (ok true)
      (ok false))
)

;; Read-only function to get the user's last access time
(define-read-only (get-last-access (user principal))
  (default-to u0 (get last-access (map-get? user-access-tokens { user: user })))
)
