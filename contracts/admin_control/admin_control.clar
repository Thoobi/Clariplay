;; Declare a map to store the list of admins
(define-map admins
  { user: principal }  ;; Key: The admin's account (principal)
  { is-admin: bool }   ;; Value: Boolean indicating if the user is an admin
)

;; Declare a variable for the contract owner (the account that deployed the contract)
(define-constant contract-owner tx-sender)

;; Function to check if a user is an admin (read-only)
(define-read-only (is-admin (user principal))
  (match (map-get? admins { user: user })
    admin-data (get is-admin admin-data)
    false
  )
)

;; Function to ensure only the contract owner or an admin can call certain functions
(define-private (assert-is-admin)
  (begin
    (if (or (is-eq tx-sender contract-owner) (is-ok (is-admin tx-sender)))
      (ok true)
      (err u100)  ;; Error code 100: Unauthorized access
    )
  )
)

;; Public function to add a new admin
(define-public (add-admin (user principal))
  (begin
    ;; Only the contract owner or current admins can add new admins
    (try! (assert-is-admin))
    
    ;; Check if the user is already an admin
    (if (is-ok (is-admin user))
      (err u101)  ;; Error code 101: User is already an admin
      (begin
        ;; Add the user as an admin
        (map-set admins { user: user } { is-admin: true })
        (ok true)
      )
    )
  )
)

;; Public function to remove an admin
(define-public (remove-admin (user principal))
  (begin
    ;; Only the contract owner or current admins can remove admins
    (try! (assert-is-admin))
    
    ;; Check if the user is actually an admin
    (if (is-ok (is-admin user))
      (begin
        ;; Remove admin privileges
        (map-delete admins { user: user })
        (ok true)
      )
      (err u102)  ;; Error code 102: User is not an admin
    )
  )
)

;; Function to transfer contract ownership (only current owner can transfer)
(define-public (transfer-ownership (new-owner principal))
  (begin
    ;; Only the contract owner can transfer ownership
    (if (is-eq tx-sender contract-owner)
      (begin
        ;; Transfer ownership by defining a new contract owner constant
        (define-constant contract-owner new-owner)
        (ok true)
      )
      (err u103)  ;; Error code 103: Unauthorized to transfer ownership
    )
  )
)

;; Admin-controlled action example: Admin can perform restricted actions (e.g., platform maintenance)
(define-public (perform-admin-action (action (string-ascii 128)))
  (begin
    ;; Ensure the caller is an admin
    (try! (assert-is-admin))

    ;; Perform the action (in this case, it's just a log)
    (ok (concat "Admin action performed: " action))
  )
)
