;; Define error constants
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_CONTENT_NOT_FOUND (err u101))

;; Define data variables
(define-data-var referral-reward uint u100) ;; Reward for referrals
(define-data-var next-content-id uint u0)    ;; ID for the next content
;; Define the content map
(define-map contents 
  { content-id: uint } 
  { creator: principal, title: (string-ascii 100), description: (string-utf8 500), price: uint, likes: uint, created-at: uint })

;; Define a data variable to track the next content ID
(define-data-var next-content-id uint u0)

;; Public function to publish new content
(define-public (publish-content (title (string-ascii 100)) (description (string-utf8 500)) (price uint))
  (let ((content-id (var-get next-content-id))
        (creator tx-sender))
    ;; Ensure title and description are not empty
    (asserts! (> (len title) u0) ERR_CONTENT_NOT_FOUND)
    (asserts! (> (len description) u0) ERR_CONTENT_NOT_FOUND)
    
    ;; Store the content in the map
    (map-set contents 
              { content-id: content-id } 
              { creator: creator, title: title, description: description, price: price, likes: u0, created-at: block-height })
    
    ;; Increment the next content ID
    (var-set next-content-id (+ content-id u1))
    
    ;; Return the ID of the newly created content
    (ok content-id)))

;; Public function to like a piece of content
(define-public (like-content (content-id uint))
  ;; Check if the content exists
  (match (map-get? contents { content-id: content-id })
    ((some { creator: creator title: title description: description price: price likes: likes created-at: created-at })
      ;; Increment the likes count
      (map-set contents 
                { content-id: content-id } 
                { creator: creator, title: title, description: description, price: price, likes: (+ likes u1), created-at: created-at })
      ;; Return success message
      (ok "Content liked successfully"))
    (_ 
      ;; Return error if content is not found
      (err ERR_CONTENT_NOT_FOUND))))

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
    (ok "Video view recorded successfully"))
