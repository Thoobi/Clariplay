(define-data-var referral-reward uint u100)

(define-map referrals
  { referrer: principal }
  { referral-count: uint, total-rewards: uint }
)

(define-map referred
  { user: principal }
  { referred-by: (optional principal) }
)

(define-public (refer-user (new-user principal))
  (let
    (
      (referrer tx-sender)
      (current-referral-data (default-to { referral-count: u0, total-rewards: u0 } (map-get? referrals { referrer: referrer })))
    )
    (asserts! (is-none (map-get? referred { user: new-user })) (err u101))
    (asserts! (not (is-eq referrer new-user)) (err u102))

    (map-set referrals
      { referrer: referrer }
      {
        referral-count: (+ (get referral-count current-referral-data) u1),
        total-rewards: (+ (get total-rewards current-referral-data) (var-get referral-reward))
      }
    )

    (map-set referred
      { user: new-user }
      { referred-by: (some referrer) }
    )

    (ok true)
  )
)

(define-read-only (get-referral-info (user principal))
  (default-to
    { referral-count: u0, total-rewards: u0 }
    (map-get? referrals { referrer: user })
  )
)

(define-read-only (get-referrer (user principal))
  (get referred-by (default-to { referred-by: none } (map-get? referred { user: user })))
)

(define-public (update-reward-amount (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (var-set referral-reward new-amount)
    (ok true)
  )
)

(define-read-only (get-current-reward)
  (var-get referral-reward)
)
