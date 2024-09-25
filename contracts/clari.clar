;; Define the contract owner
(define-data-var contract-owner principal tx-sender)

;; Define access tiers
(define-data-var tier-1-fee uint u10000000) ;; 10 STX
(define-data-var tier-2-fee uint u20000000) ;; 20 STX
(define-data-var tier-3-fee uint u30000000) ;; 30 STX

;; Define map for user access information
(define-map user-access 
  principal 
  { tier: (string-ascii 20), 
    expiration: uint,
    videos-watched: uint }
)

;; Define map for video metadata
(define-map video-metadata 
  uint 
  { title: (string-ascii 100), 
    required-tier: (string-ascii 20) }
)

;; Helper function to get current time
(define-read-only (get-current-time)
  block-height
)

;; Function to check if a user has active access
(define-read-only (has-active-access (user principal))
  (match (map-get? user-access user)
    access (> (get expiration access) (get-current-time))
    false
  )
)

;; Function to get user's current tier
(define-read-only (get-user-tier (user principal))
  (match (map-get? user-access user)
    access (get tier access)
    "none"
  )
)

;; Function to purchase access
(define-public (purchase-access (tier (string-ascii 20)))
  (let 
    (
      (fee (if (is-eq tier "tier-1") 
                (var-get tier-1-fee)
                (if (is-eq tier "tier-2")
                    (var-get tier-2-fee)
                    (var-get tier-3-fee))))
      (duration (if (is-eq tier "tier-1") 
                    u43200  ;; ~30 days
                    (if (is-eq tier "tier-2")
                        u86400  ;; ~60 days
                        u129600)))  ;; ~90 days
    )
    (begin
      (asserts! (is-ok (stx-transfer? fee tx-sender (var-get contract-owner))) (err u101))
      (ok (map-set user-access tx-sender 
        { tier: tier, 
          expiration: (+ (get-current-time) duration),
          videos-watched: u0 }))
    )
  )
)

;; Function to add video metadata (only contract owner)
(define-public (add-video-metadata (video-id uint) (title (string-ascii 100)) (required-tier (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (ok (map-set video-metadata video-id { title: title, required-tier: required-tier }))
  )
)

;; Function to check if user can watch a specific video
(define-read-only (can-watch-video (user principal) (video-id uint))
  (match (map-get? user-access user)
    user-data (match (map-get? video-metadata video-id)
                video-data (and 
                             (has-active-access user)
                             (or 
                               (is-eq (get required-tier video-data) (get tier user-data))
                               (and 
                                 (is-eq (get required-tier video-data) "tier-1")
                                 (or (is-eq (get tier user-data) "tier-2") (is-eq (get tier user-data) "tier-3")))
                               (and
                                 (is-eq (get required-tier video-data) "tier-2")
                                 (is-eq (get tier user-data) "tier-3"))))
                false)
    false
  )
)

;; Function to record a video view
(define-public (record-video-view (user principal) (video-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (asserts! (can-watch-video user video-id) (err u102))
    (match (map-get? user-access user)
      user-data (ok (map-set user-access user 
                    (merge user-data { videos-watched: (+ (get videos-watched user-data) u1) })))
      (err u103)
    )
  )
)
