# Contracts Summary

Generated: 2026-02-15

## System Identity
_(empty — populated after first maintenance)_

## Active Contracts
_(empty — populated after first maintenance)_

## Non-Goals
_(empty — populated after first maintenance)_

## Unprocessed

### System Identity & Boundaries

- **Platform:** Flutter Windows desktop application, SQLite local database, no backend
- **Language:** Arabic-only UI and data (RTL)
- **Tech stack:** Riverpod 3 (not legacy), GoRouter
- **Schema:** Exactly 3 tables — `subscriber_groups`, `accounts`, `payments`

---

### Core Invariants

- **Payments are immutable historical facts.** They are never auto-modified by mapping changes. Payments can only be edited or deleted manually from the Payments screen.
- **Account-to-subscriber relationships are dynamic.** `payments.reference_account_number` has no FK to `accounts` — mapping is resolved dynamically at query time.
- **Mapping changes immediately reflect** in searches, reports, and payment screen display.
- **Account numbers:** numeric only, 9–12 digits, globally unique (enforced at DB level via UNIQUE constraint).
- **No duplicate payments.** Composite unique constraint on (`reference_account_number`, `payment_date`, `amount`).
- **Group/account deletion is allowed.** Deleting a group or account does NOT delete related payments. Payments become unmapped.

---

### Import Rules

- **Pattern A (text column):** Single hardcoded parser for a known fixed format. Details TBD — user will provide examples.
- **Pattern B (structured table):** Column matching via predefined alias lists for account, amount, date, collector stamp, subscriber name.
- **Auto-creation:** If imported `reference_account_number` doesn't exist in `accounts`, system auto-creates a new `subscriber_group` + `account`.
- **Duplicate rejection:** Import must reject rows matching existing (`reference_account_number`, `payment_date`, `amount`).

---

### Search & Reporting

- **Group-based resolution:** Searching by any account number resolves its group, retrieves all sibling accounts, and fetches payments for all of them.
- **Reports:** Header shows subscriber name, all related accounts, period, total amount. Body shows payment details. Footer shows generation timestamp.

---

### Explicit Non-Goals

- No backend or server
- No multi-language support (Arabic only)
- No mobile or web deployment
- No multi-user or authentication

---

### Open Questions

- Pattern A parser details (deferred — user will provide Excel examples)

---