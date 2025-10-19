# StacksProtocol

Minimal Stacks smart contract implementing a project / milestone marketplace with staking, submissions, scoring, reputation and insurance-claim tracking.

## Overview
This repository contains a single Clarity contract `contracts/stacksprotocol.clar` that provides primitive workflows for:
- Posting projects with milestones and budgets
- Freelancers applying and staking
- Selecting a freelancer
- Submitting and scoring milestones
- Voting/approving milestones and releasing funds (logical, no token transfer)
- Simple reputation minting and insurance-claim flagging

The contract is an early-stage prototype intended for local development and iteration. It does not include token transfer logic, advanced access control, off-chain integrations, or robust dispute resolution.

## Key files
- contracts/stacksprotocol.clar — main Clarity contract

## Main data structures
- project-counter, reputation-counter — uint counters
- projects (map) — project records: client, title, milestones, budget, selected-freelancer, status, completed-milestones
- submissions (map) — submission records: freelancer, submission-hash, score, approved
- stakes (map) — user stake amounts
- reputations (map) — user reputation points
- insurance-claims (map) — boolean flag per project

## Public functions (summary)
- post-project(title, milestones-list, budget) -> ok project-id
- apply-freelancer(project-id, stake-amount) -> ok true
- select-freelancer(project-id, freelancer) -> ok true (client-only)
- submit-milestone(project-id, milestone-id, submission-hash) -> ok true
- score-milestone(project-id, milestone-id, score) -> ok true
- vote-approval(project-id, milestone-id, approve) -> ok true
- release-funds(project-id, milestone-id) -> ok true
- stake-reward(amount) -> ok true
- claim-reward(user) -> ok amount
- mint-reputation(project-id, role) -> ok true
- report-dispute(project-id, milestone-id, reason) -> ok true
- insurance-claim(project-id) -> ok true / err already done

Note: Monetary transfers and token calls are not implemented — release-funds only updates project state.

## Error codes
- ERR_NOT_FOUND (err u100)
- ERR_UNAUTHORIZED (err u101)
- ERR_ALREADY_DONE (err u102)
- ERR_INVALID (err u103)

## Example usage (Clarity calls)
- Post a project:
  (call .post-project "Website" ["Design" "Build"] u1000)

- Apply as freelancer:
  (call .apply-freelancer u1 u50)

- Client selects freelancer:
  (call .select-freelancer u1 'SPXXX... )

- Freelancer submits milestone:
  (call .submit-milestone u1 u1 (buffer 32 "Qm..."))

- Approve and release:
  (call .vote-approval u1 u1 true)
  (call .release-funds u1 u1)

## Development & testing
- Use Stacks local development tools (clarinet or equivalent) to deploy and run unit tests.
- Add token transfer logic and event logging for production.
- Add access control checks and dispute resolution flows where needed.


## License
Specify a license for your project (e.g., MIT) in a LICENSE file before production use.
