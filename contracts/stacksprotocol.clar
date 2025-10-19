;; Traits for external contracts
(define-trait dao-voting-trait 
  ((vote-on-proposal (uint) (response bool uint))
   (get-vote-result (uint) (response bool uint))))

(define-trait ai-oracle-trait
  ((grade-submission (uint uint (buff 32)) (response bool uint))
   (get-submission-grade (uint uint) (response uint uint))))

;; Data vars for counters
(define-data-var project-counter uint u0)
(define-data-var reputation-counter uint u0)

;; Map definitions
(define-map projects 
  { id: uint }
  {
    client: principal,
    title: (string-ascii 100),
    milestones: (list 10 (string-ascii 100)),
    budget: uint,
    selected-freelancer: (optional principal),
    status: (string-ascii 20),
    completed-milestones: uint
  })

(define-map submissions 
  { project-id: uint, milestone-id: uint }
  {
    freelancer: principal,
    submission-hash: (buff 32),
    score: (optional uint),
    approved: bool
  })

;; Helper functions
;; Helper functions

(define-map stakes { user: principal } uint)
(define-map reputations { user: principal } uint)
(define-map insurance-claims { project-id: uint } bool)

;; Constants for responses
(define-constant ERR_NOT_FOUND (err u100))
(define-constant ERR_UNAUTHORIZED (err u101))
(define-constant ERR_ALREADY_DONE (err u102))
(define-constant ERR_INVALID (err u103))
(define-constant OK_TRUE (ok true))

;; Project management functions
(define-public (post-project (title-str (string-ascii 100)) (milestones-list (list 10 (string-ascii 100))) (budget-val uint))
  (let 
    (
      (next-id (+ (var-get project-counter) u1))
      (project-data {
        client: tx-sender,
        title: title-str,
        milestones: milestones-list,
        budget: budget-val,
        selected-freelancer: none,
        status: "open",
        completed-milestones: u0
      })
    )
    (begin
      (var-set project-counter next-id)
      (map-set projects { id: next-id } project-data)
      (ok next-id))))

(define-public (apply-freelancer (project-id uint) (stake-amount uint))
  (begin
    (asserts! (and (> project-id u0) (> stake-amount u0)) ERR_INVALID)
    (map-set stakes { user: tx-sender } stake-amount)
    OK_TRUE))

(define-public (select-freelancer (project-id uint) (freelancer principal))
  (begin
    (asserts! (> project-id u0) ERR_INVALID)
    (let ((project (unwrap! (map-get? projects { id: project-id }) ERR_NOT_FOUND)))
      (begin
        (asserts! (is-eq tx-sender (get client project)) ERR_UNAUTHORIZED)
        (map-set projects
          { id: project-id }
          (merge project { selected-freelancer: (some freelancer) }))
        OK_TRUE))))

(define-public (submit-milestone (project-id uint) (milestone-id uint) (submission-hash (buff 32)))
  (begin
    (asserts! (and (> project-id u0) 
                   (> milestone-id u0)
                   (is-eq (len submission-hash) u32)) 
              ERR_INVALID)
    (map-set submissions
      { project-id: project-id, milestone-id: milestone-id }
      {
        freelancer: tx-sender,
        submission-hash: submission-hash,
        score: none,
        approved: false
      })
    OK_TRUE))

(define-public (score-milestone (project-id uint) (milestone-id uint) (score uint))
  (begin
    (asserts! (and (> project-id u0)
                   (> milestone-id u0)
                   (<= score u10))
              ERR_INVALID)
    (let ((submission (unwrap! (map-get? submissions 
                              { project-id: project-id, milestone-id: milestone-id })
                     ERR_NOT_FOUND)))
      (map-set submissions
        { project-id: project-id, milestone-id: milestone-id }
        (merge submission { score: (some score) }))
      OK_TRUE)))

(define-public (vote-approval (project-id uint) (milestone-id uint) (approve bool))
  (begin
    (asserts! (and (> project-id u0) (> milestone-id u0)) ERR_INVALID)
    (let ((submission (unwrap! (map-get? submissions 
                                { project-id: project-id, milestone-id: milestone-id })
                     ERR_NOT_FOUND)))
      (map-set submissions
        { project-id: project-id, milestone-id: milestone-id }
        (merge submission { approved: approve }))
      OK_TRUE)))

(define-public (release-funds (project-id uint) (milestone-id uint))
  (begin
    (asserts! (and (> project-id u0) (> milestone-id u0)) ERR_INVALID)
    (let ((project (unwrap! (map-get? projects { id: project-id }) ERR_NOT_FOUND))
          (submission (unwrap! (map-get? submissions 
                                { project-id: project-id, milestone-id: milestone-id })
                     ERR_NOT_FOUND)))
      (begin
        (asserts! (and (get approved submission)
                       (is-eq (some (get freelancer submission))
                             (get selected-freelancer project)))
                  ERR_INVALID)
        (map-set projects
          { id: project-id }
          (merge project { completed-milestones: (+ (get completed-milestones project) u1) }))
        OK_TRUE))))

(define-public (stake-reward (amount uint))
  (begin
    (asserts! (> amount u0) ERR_INVALID)
    (map-set stakes { user: tx-sender } amount)
    OK_TRUE))

(define-public (claim-reward (user principal))
  (let ((stake (map-get? stakes { user: user })))
    (if (is-none stake)
        ERR_NOT_FOUND
        (ok (* (unwrap-panic stake) u2)))))

(define-public (mint-reputation (project-id uint) (role (string-ascii 10)))
  (begin 
    (var-set reputation-counter (+ (var-get reputation-counter) u1))
    (map-set reputations 
      { user: tx-sender } 
      (+ (default-to u0 (map-get? reputations { user: tx-sender })) u1))
    OK_TRUE))

(define-public (report-dispute (project-id uint) (milestone-id uint) (reason (string-ascii 200)))
  OK_TRUE)

(define-public (insurance-claim (project-id uint))
  (begin
    (asserts! (> project-id u0) ERR_INVALID)
    (if (is-some (map-get? insurance-claims { project-id: project-id }))
        ERR_ALREADY_DONE
        (begin
          (map-set insurance-claims { project-id: project-id } true)
          OK_TRUE))))

