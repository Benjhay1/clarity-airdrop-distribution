;; Airdrop Distribution Contract
;; Handles token distribution with claiming periods and distribution caps

;; Define the SIP-010 trait
(use-trait ft-trait .sip-010-trait.sip-010-trait)

;; Constants and error codes
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-eligible (err u101))
(define-constant err-already-claimed (err u102))
(define-constant err-claim-period-ended (err u103))
(define-constant err-claim-period-not-started (err u104))

;; Data variables
(define-data-var total-tokens-distributed uint u0)
(define-data-var distribution-cap uint u1000000) ;; 1M tokens
(define-data-var claim-period-start uint u0)
(define-data-var claim-period-end uint u0)
(define-data-var token-contract principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.token-contract)

;; Maps to track eligibility and claims
(define-map eligible-addresses principal uint)  ;; Maps address to token amount
(define-map claimed-addresses principal bool)   ;; Tracks if address has claimed

;; Read-only functions
(define-read-only (get-token-balance (address principal))
    (default-to u0 (map-get? eligible-addresses address)))

(define-read-only (has-claimed (address principal))
    (default-to false (map-get? claimed-addresses address)))

(define-read-only (is-claim-period-active)
    (let (
        (current-block block-height)
        (start (var-get claim-period-start))
        (end (var-get claim-period-end))
    )
    (and (>= current-block start) (<= current-block end))))

;; Administrative functions
(define-public (set-claim-period (start uint) (end uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set claim-period-start start)
        (var-set claim-period-end end)
        (ok true)))

(define-public (set-token-contract (new-token-contract principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set token-contract new-token-contract)
        (ok true)))

(define-public (add-eligible-address (address principal) (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set eligible-addresses address amount)
        (ok true)))

(define-public (batch-add-eligible-addresses (addresses (list 200 principal)) (amounts (list 200 uint)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq (len addresses) (len amounts)) (err u105))
        (map add-eligible-address-internal addresses amounts)
        (ok true)))

;; Internal function for batch processing
(define-private (add-eligible-address-internal (address principal) (amount uint))
    (map-set eligible-addresses address amount))

;; Claiming function
(define-public (claim-tokens (token <ft-trait>))
    (let (
        (eligible-amount (get-token-balance tx-sender))
        (has-already-claimed (has-claimed tx-sender))
    )
    (begin
        ;; Check eligibility and conditions
        (asserts! (is-eq (var-get token-contract) (contract-of token)) (err u107))
        (asserts! (> eligible-amount u0) err-not-eligible)
        (asserts! (not has-already-claimed) err-already-claimed)
        (asserts! (is-claim-period-active) err-claim-period-not-started)
        
        ;; Check if within distribution cap
        (asserts! (<= (+ (var-get total-tokens-distributed) eligible-amount) 
                     (var-get distribution-cap)) 
                 (err u106))
        
        ;; Update state
        (map-set claimed-addresses tx-sender true)
        (var-set total-tokens-distributed 
                 (+ (var-get total-tokens-distributed) eligible-amount))
        
        ;; Perform token transfer
        (as-contract
            (contract-call? token transfer
                eligible-amount
                (as-contract tx-sender)
                tx-sender
                none))
    )))

;; Emergency functions
(define-public (update-distribution-cap (new-cap uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set distribution-cap new-cap)
        (ok true)))

(define-public (emergency-withdraw (token <ft-trait>) (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq (var-get token-contract) (contract-of token)) (err u107))
        (as-contract
            (contract-call? token transfer
                amount
                (as-contract tx-sender)
                contract-owner
                none))))