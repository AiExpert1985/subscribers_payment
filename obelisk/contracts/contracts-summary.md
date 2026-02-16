# Contracts Summary

Generated: 2026-02-16

## System Identity
_(empty — populated after first maintenance)_

## Active Contracts
_(empty — populated after first maintenance)_

## Non-Goals
_(empty — populated after first maintenance)_

## Unprocessed

### System Identity & Boundaries

- Payment consolidation system for 11+ years of Excel-based historical payment records
- Single-user Flutter desktop application (Windows primary target)
- Arabic-only (RTL) interface — no multi-language support
- Local SQLite database — no cloud, no multi-user, no sync
- Tech stack: Flutter, SQLite, Riverpod 3, go_router

### Core Invariants

1. **Payment Immutability**: Payment records are never auto-modified or auto-deleted. Only explicit manual user action (edit/delete) can change a payment record. No system process, import, or mapping change may alter existing payment data.

2. **Duplicate Prevention**: A payment is duplicate when the combination of `reference_account_number` + `payment_date` + `amount` already exists. Duplicates must be rejected during import and manual entry. Enforced via composite unique index at database level.

3. **Global Account Uniqueness**: Each `account_number` exists exactly once across all subscriber groups. Enforced via unique constraint at database level.

4. **Dynamic Mapping Resolution**: Account-to-subscriber-group mapping changes immediately affect all searches, reports, and display. Mapping changes never modify stored payment records.

5. **Import Auto-Create**: When importing a payment with an unknown `reference_account_number`, the system auto-creates a new subscriber group and account entry.

### Data Model Contracts

**Three tables only:**

- `subscriber_groups`: `id` (PK), `subscriber_name` (optional, editable)
- `accounts`: `id` (PK), `account_number` (UNIQUE, required), `subscriber_group_id` (FK → subscriber_groups, required)
- `payments`: `id` (PK), `reference_account_number` (required), `amount` (decimal, required), `payment_date` (date, required), `stamp_number` (optional), `subscriber_name` (optional), `type` (optional)

**Key constraint**: `payments.reference_account_number` has NO foreign key to `accounts`. Mapping is resolved dynamically at query time.

### Deletion Rules

- **Delete subscriber group**: Cascade deletes all accounts in the group. Never touches payments table.
- **Delete account**: Removes from group. Payments referencing it remain unchanged (become "unmapped").
- **Delete payment**: Manual user action only.

### Non-Goals

- Multi-language support (Arabic only)
- Audit trail or change history
- Multi-user or concurrent access
- Cloud sync, backup, or replication
- Automatic data backup mechanisms

### Open Contract Questions

_(none)_
