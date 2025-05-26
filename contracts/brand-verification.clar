;; Brand Verification Contract
;; Validates and manages fashion company registrations

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-verified (err u101))
(define-constant err-not-verified (err u102))
(define-constant err-invalid-brand (err u103))

;; Brand verification status
(define-map verified-brands principal bool)
(define-map brand-details principal {
  name: (string-ascii 100),
  registration-date: uint,
  sustainability-score: uint,
  verified-by: principal
})

;; Brand verification events
(define-map verification-history uint {
  brand: principal,
  action: (string-ascii 20),
  timestamp: uint,
  verifier: principal
})

(define-data-var verification-counter uint u0)

;; Verify a fashion brand
(define-public (verify-brand (brand principal) (name (string-ascii 100)) (sustainability-score uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? verified-brands brand)) err-already-verified)
    (asserts! (<= sustainability-score u100) err-invalid-brand)

    (map-set verified-brands brand true)
    (map-set brand-details brand {
      name: name,
      registration-date: block-height,
      sustainability-score: sustainability-score,
      verified-by: tx-sender
    })

    (let ((counter (+ (var-get verification-counter) u1)))
      (var-set verification-counter counter)
      (map-set verification-history counter {
        brand: brand,
        action: "VERIFIED",
        timestamp: block-height,
        verifier: tx-sender
      }))

    (ok true)))

;; Revoke brand verification
(define-public (revoke-verification (brand principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (default-to false (map-get? verified-brands brand)) err-not-verified)

    (map-delete verified-brands brand)
    (map-delete brand-details brand)

    (let ((counter (+ (var-get verification-counter) u1)))
      (var-set verification-counter counter)
      (map-set verification-history counter {
        brand: brand,
        action: "REVOKED",
        timestamp: block-height,
        verifier: tx-sender
      }))

    (ok true)))

;; Check if brand is verified
(define-read-only (is-brand-verified (brand principal))
  (default-to false (map-get? verified-brands brand)))

;; Get brand details
(define-read-only (get-brand-details (brand principal))
  (map-get? brand-details brand))

;; Get verification history
(define-read-only (get-verification-history (id uint))
  (map-get? verification-history id))
