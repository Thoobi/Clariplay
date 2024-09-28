;; Define a map to store subscriptions
(define-map subscriptions
  ((user principal) (subscription-id uint))
  ((active? bool) (expiry uint)))

(define-public (subscribe (subscription-id uint) (duration uint))
  (let ((user (contract-caller)))
    ;; Check if the user already has an active subscription
    (if (is-none (map-get? subscriptions (list user subscription-id)))
      (begin
        ;; Create a new subscription
        (map-set subscriptions (list user subscription-id)
          { active?: true
            expiry: (+ (block-height) duration) }) ;; Set expiry based on current block height and duration
        (ok "Subscription created"))
      (err "User already has an active subscription"))))

(define-public (unsubscribe (subscription-id uint))
  (let ((user (contract-caller)))
    ;; Check if the user has an active subscription
    (match (map-get? subscriptions (list user subscription-id))
      ((some { active?: true expiry })
        ;; Deactivate the subscription
        (map-set subscriptions (list user subscription-id)
          { active?: false
            expiry: expiry }) ;; Keep the expiry for reference
        (ok "Subscription cancelled"))
      (_ 
        (err "No active subscription found")))))

(define-public (check-subscription-status (subscription-id uint))
  (let ((user (contract-caller)))
    ;; Retrieve the user's subscription status
    (match (map-get? subscriptions (list user subscription-id))
      ((some { active?: active? expiry })
        ;; Check if the subscription is still valid
        (if active?
          (if (> expiry (block-height))
            (ok "Subscription is active")
            ;; If expired, deactivate it
            (begin
              ;; Deactivate the expired subscription
              (map-set subscriptions (list user subscription-id)
                { active?: false 
                  expiry: expiry }) ;; Update to inactive status
              (ok "Subscription has expired")))
          (ok "Subscription is inactive")))
      (_ 
        (err "No subscription found")))))

(define-public (get-subscription-details (subscription-id uint))
  ;; Retrieve details of a user's subscription
  ;; Returns: { user: principal, active: bool, expiry: uint }
  (let ((user (contract-caller)))
    (match (map-get? subscriptions (list user subscription-id))
      ((some { active?: active? expiry })
        { user: user 
          active: active?
          expiry: expiry })
      (_ 
        { user: user 
          active: false 
          expiry: 0 })))) ; Default response if no details found