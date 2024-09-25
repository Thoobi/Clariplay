;; Define the contract owner
(define-data-var contract-owner principal tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ALREADY_REFERRED (err u101))
(define-constant ERR_INVALID_CONTENT (err u101))
(define-constant ERR_SELF_REFERRAL (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_CONTENT_NOT_FOUND (err u102))

;; Define data variable for reward amount
(define-data-var referral-reward uint u100)

;; Data Variables
(define-data-var next-content-id uint u0)


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

;; Add a map to store price change history
(define-map price-change-history
  uint
  { tier: (string-ascii 20),
    old-price: uint,
    new-price: uint,
    change-time: uint }
)

;; Add a variable to track the number of price changes
(define-data-var price-change-count uint u0)

;; Function to update tier prices (only contract owner)
(define-public (update-tier-price (tier (string-ascii 20)) (new-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (asserts! (or (is-eq tier "tier-1") (is-eq tier "tier-2") (is-eq tier "tier-3")) (err u104))
    (let
      ((old-price (if (is-eq tier "tier-1")
                      (var-get tier-1-fee)
                      (if (is-eq tier "tier-2")
                          (var-get tier-2-fee)
                          (var-get tier-3-fee)))))
      (if (is-eq tier "tier-1")
          (var-set tier-1-fee new-price)
          (if (is-eq tier "tier-2")
              (var-set tier-2-fee new-price)
              (var-set tier-3-fee new-price)))
      (map-set price-change-history (var-get price-change-count)
        { tier: tier,
          old-price: old-price,
          new-price: new-price,
          change-time: block-height })
      (var-set price-change-count (+ (var-get price-change-count) u1))
      (ok true)
    )
  )
)

;; Function to get the current price for a tier
(define-read-only (get-tier-price (tier (string-ascii 20)))
  (if (is-eq tier "tier-1")
      (ok (var-get tier-1-fee))
      (if (is-eq tier "tier-2")
          (ok (var-get tier-2-fee))
          (if (is-eq tier "tier-3")
              (ok (var-get tier-3-fee))
              (err u104))))
)

;; Update the purchase-access function to use time-based pricing
(define-public (purchase-access (tier (string-ascii 20)))
(let
(
(fee-response (get-time-based-price tier))
(duration (if (is-eq tier "tier-1")
u43200  ;; ~30 days
(if (is-eq tier "tier-2")
u86400  ;; ~60 days
u129600)))  ;; ~90 days
)
(match fee-response
fee (begin
(asserts! (is-ok (stx-transfer? fee tx-sender (var-get contract-owner))) (err u101))
(ok (map-set user-access tx-sender
{ tier: tier,
expiration: (+ (get-current-time) duration),
videos-watched: u0 })))
error (err u105)  ;; New error code for pricing calculation failure
)
)
)

(define-read-only (get-time-based-price (tier (string-ascii 20)))
  (let
    ((base-price-response (get-tier-price tier)))
    (match base-price-response
      base-price 
        (let
          ((current-time (get-current-time))
           (hour-of-day (mod current-time u24))
           (price-multiplier (+ u100 (/ (* hour-of-day u20) u24))))  ;; 0-20% increase based on hour
          (ok (/ (* base-price price-multiplier) u100)))
      error (err error))  ;; Wrap the error in (err ...) to make it a response type
    )
  )

;; Function to get price change history
(define-read-only (get-price-change-history (index uint))
  (map-get? price-change-history index)
)

;; Define constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant REFERRAL_REWARD u100) ;; Amount of reward for successful referral

;; Define data maps
(define-map referrals
  { referrer: principal }
  { referral-count: uint, total-rewards: uint }
)

(define-map referred
  { user: principal }
  { referred-by: (optional principal) }
)

;; Public functions

;; Function to refer a new user
(define-public (refer-user (new-user principal))
  (let 
    (
      (referrer tx-sender)
      (current-referral-data (default-to { referral-count: u0, total-rewards: u0 } (map-get? referrals { referrer: referrer })))
    )
    (asserts! (is-none (map-get? referred { user: new-user })) (err u1)) ;; Ensure user hasn't been referred before
    (asserts! (not (is-eq referrer new-user)) (err u2)) ;; Prevent self-referral

    ;; Update referrals map
    (map-set referrals
      { referrer: referrer }
      {
        referral-count: (+ (get referral-count current-referral-data) u1),
        total-rewards: (+ (get total-rewards current-referral-data) REFERRAL_REWARD)
      }
    )

    ;; Update referred map
    (map-set referred
      { user: new-user }
      { referred-by: (some referrer) }
    )

    ;; Here you would typically add logic to transfer the reward to the referrer
    ;; For simplicity, we're just tracking the reward amount in the map
    (ok true)
  )
)

;; Function to check referral count and total rewards for a user
(define-read-only (get-referral-info (user principal))
  (default-to 
    { referral-count: u0, total-rewards: u0 }
    (map-get? referrals { referrer: user })
  )
)

;; Function to check who referred a user
(define-read-only (get-referrer (user principal))
  (get referred-by (default-to { referred-by: none } (map-get? referred { user: user })))
)

;; Admin function to update reward amount
(define-public (update-reward-amount (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) (err u3))
    (var-set referral-reward new-amount)
    (ok true)
  )
)

;; Read-only function to get current reward amount
(define-read-only (get-current-reward)
  (var-get referral-reward)
)

;; Define Maps
(define-map contents
    { content-id: uint }
    {
        creator: principal,
        title: (string-ascii 100),
        description: (string-utf8 500),
        price: uint,
        likes: uint,
        created-at: uint
    }
)

(define-map creator-stats
    { creator: principal }
    {
        total-content: uint,
        total-earnings: uint,
        total-likes: uint
    }
)

(define-map user-purchases
    { user: principal, content-id: uint }
    { purchased: bool }
)

;; Public Functions

;; Function to publish new content
(define-public (publish-content (title (string-ascii 100)) (description (string-utf8 500)) (price uint))
    (let
        (
            (content-id (var-get next-content-id))
            (creator tx-sender)
        )
        (asserts! (> (len title) u0) ERR_INVALID_CONTENT)
        (asserts! (> (len description) u0) ERR_INVALID_CONTENT)
        
        (map-set contents
            { content-id: content-id }
            {
                creator: creator,
                title: title,
                description: description,
                price: price,
                likes: u0,
                created-at: block-height
            }
        )
        
        (map-set creator-stats
            { creator: creator }
            (merge
                (default-to
                    { total-content: u0, total-earnings: u0, total-likes: u0 }
                    (map-get? creator-stats { creator: creator })
                )
                { total-content: (+ u1 (get total-content (default-to { total-content: u0 } (map-get? creator-stats { creator: creator })))) }
            )
        )
        
        (var-set next-content-id (+ content-id u1))
        (ok content-id)
    )
)

;; Function to purchase content
(define-public (purchase-content (content-id uint))
    (let
        (
            (buyer tx-sender)
            (content (unwrap! (map-get? contents { content-id: content-id }) ERR_CONTENT_NOT_FOUND))
            (creator (get creator content))
            (price (get price content))
        )
        (asserts! (is-none (map-get? user-purchases { user: buyer, content-id: content-id })) ERR_CONTENT_NOT_FOUND)
        (try! (stx-transfer? price buyer creator))
        
        (map-set user-purchases
            { user: buyer, content-id: content-id }
            { purchased: true }
        )
        
        (map-set creator-stats
            { creator: creator }
            (merge
                (default-to
                    { total-content: u0, total-earnings: u0, total-likes: u0 }
                    (map-get? creator-stats { creator: creator })
                )
                { total-earnings: (+ price (get total-earnings (default-to { total-earnings: u0 } (map-get? creator-stats { creator: creator })))) }
            )
        )
        
        (ok true)
    )
)

;; Function to like content
(define-public (like-content (content-id uint))
    (let
        (
            (content (unwrap! (map-get? contents { content-id: content-id }) ERR_CONTENT_NOT_FOUND))
            (creator (get creator content))
            (current-likes (get likes content))
        )
        (map-set contents
            { content-id: content-id }
            (merge content { likes: (+ current-likes u1) })
        )
        
        (map-set creator-stats
            { creator: creator }
            (merge
                (default-to
                    { total-content: u0, total-earnings: u0, total-likes: u0 }
                    (map-get? creator-stats { creator: creator })
                )
                { total-likes: (+ u1 (get total-likes (default-to { total-likes: u0 } (map-get? creator-stats { creator: creator })))) }
            )
        )
        
        (ok true)
    )
)

;; Read-only Functions

;; Get content details
(define-read-only (get-content (content-id uint))
    (map-get? contents { content-id: content-id })
)

;; Get creator stats
(define-read-only (get-creator-stats (creator principal))
    (map-get? creator-stats { creator: creator })
)

;; Check if user has purchased content
(define-read-only (has-purchased (user principal) (content-id uint))
    (default-to
        false
        (get purchased (map-get? user-purchases { user: user, content-id: content-id }))
    )
)

;; Get total number of contents
(define-read-only (get-total-contents)
    (var-get next-content-id)
)