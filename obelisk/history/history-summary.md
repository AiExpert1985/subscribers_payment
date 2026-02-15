# History Summary

Generated: 2026-02-15

## Project Timeline
_(empty — populated after first maintenance)_

## Recent Activity
_(empty — populated after first maintenance)_

## Active Patterns
_(empty — populated after first maintenance)_

## Unprocessed

## 2026-02-15 | Subscribers Payments System | INITIALIZED

**Summary:** Flutter Windows desktop app for consolidating 11+ years of heterogeneous Excel payment records into a unified SQLite database with dynamic account-subscriber mapping, Arabic-only UI.

**Decisions:**
- Platform: Flutter Windows desktop with SQLite (no backend)
- UI language: Arabic only (RTL)
- State management: Riverpod 3 (not legacy) + GoRouter
- Schema: 3 tables (`subscriber_groups`, `accounts`, `payments`)
- Account numbers: numeric, 9–12 digits, globally unique
- Payments immutable — no auto-modification on mapping changes
- Dynamic mapping: `payments.reference_account_number` has no FK, resolved at query time
- Duplicate rule: composite unique on (account, date, amount)
- Group/account deletion allowed; related payments remain untouched (unmapped)
- Import auto-creates group+account for unknown account numbers
- Pattern A parser: single hardcoded (details deferred)
- Pattern B parser: alias-based column matching

---

## 2026-02-15 | Database Schema Implementation | APPROVED

**Summary:** Implement SQLite database with 3 tables, Dart models, and Riverpod 3 integration

**Decisions:**
- Account numbers stored as INTEGER (not TEXT)
- Amounts stored as REAL with 3 decimal precision
- Dates stored as INTEGER timestamps
- Payments table has two additional fields: `type` and `collector_stamp` (both separate text fields)
- ON DELETE CASCADE: when subscriber_group deleted, cascade to accounts but leave payments untouched
- No runtime UI verification needed (app compilation sufficient for now)

**Deferred:**
- CRUD UI screens
- Excel import logic
- Search/reporting functionality

---