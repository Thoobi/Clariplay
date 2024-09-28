(define-data-var contract-owner principal tx-sender)

;; Function to check if tx-sender is the contract owner
(define-read-only (is-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Function to transfer ownership (only contract owner can call this)
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
