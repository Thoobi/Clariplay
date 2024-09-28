;; Define constants for error handling
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_CONTENT (err u101))

;; Define data variables
(define-data-var referral-reward uint u100) ;; Reward for referrals
(define-data-var next-content-id uint u0)    ;; ID for the next content

;; Define maps for user access and video metadata
(define-map user-access 
  principal 
  { tier: (string-ascii 20), expiration: uint, videos-watched: uint })

(define-map video-metadata 
  uint 
  { title: (string-ascii 100), required-tier: (string-ascii 20) })

;; Public function to add video metadata
(define-public (add-video-metadata (video-id uint) (title (string-ascii 100)) (required-tier (string-ascii 20)))
  (begin
    ;; Check if the caller is authorized to add video metadata
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    
    ;; Store the video metadata in the map
    (map-set video-metadata video-id { title: title, required-tier: required-tier })
    
    ;; Return success message
    (ok "Video metadata added successfully")))

;; Public function to get the price for a specific tier
(define-public (get-tier-price (tier (string-ascii 20)))
  ;; Define tier prices
  (let ((tier-1-price u10000000) ;; Price for tier 1
        (tier-2-price u20000000) ;; Price for tier 2
        (tier-3-price u30000000)) ;; Price for tier 3
    ;; Return the price based on the tier provided
    (if (is-eq tier "tier-1")
      (ok tier-1-price)
      (if (is-eq tier "tier-2")
        (ok tier-2-price)
        (if (is-eq tier "tier-3")
          (ok tier-3-price)
          (err ERR_INVALID_CONTENT))))))

;; Function to check if a user has active access to a specific video based on their tier
(define-read-only (has-active-access? (user principal) (video-id uint))
  ;; Get user access details
  (match (map-get? user-access user)
    ((some { tier: user-tier expiration: expiration })
      ;; Check if the user's access is still valid
      (> expiration block-height))
    (_ false)))

;; Function to check if a user can watch a specific video based on their access level
(define-read-only (can-watch-video? (user principal) (video-id uint))
  ;; Get video metadata
  (match (map-get? video-metadata video-id)
    ((some { required-tier: required-tier })
      ;; Check if the user's current tier meets the video's required tier
      ;; Assuming we have a function get-user-tier that returns the user's current tier.
      (= required-tier (get-user-tier user)))
    (_ false)))

;; Function to record a video view and increment watched count
(define-public (record-video-view (user principal) (video-id uint))
  ;; Ensure the user has access to watch the video
  (asserts! (can-watch-video? user video-id) ERR_NOT_AUTHORIZED)
  
  ;; Increment videos watched count in user access map
  (let ((current-access-data 
          (unwrap! 
            (map-get? user-access user) 
            ERR_NOT_AUTHORIZED)))
        )
    ;; Update videos watched count in user access data
    (map-set user-access 
             user 
             { tier: current-access-data.tier 
               expiration: current-access-data.expiration 
               videos-watched: (+ current-access-data.videos-watched u1) })
    
    ;; Return success message
    (ok "Video view recorded successfully")))


