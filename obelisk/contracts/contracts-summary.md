# Contracts Summary

Generated: 2026-03-03

## System Identity

Payment consolidation system for 11+ years of Excel-based historical payment records. Arabic-only, single-user, Windows desktop application.

## Active Contracts

**1. Payment Immutability**
Payment records are never auto-modified or auto-deleted. Only explicit manual user action (edit/delete) can change a payment record. No system process, import, or mapping change may alter existing payment data.

**2. Duplicate Prevention**
A payment is duplicate when the combination of `reference_account_number` + `payment_date` + `amount` already exists. Duplicates must be rejected during import and manual entry. Enforced via composite unique index at database level.

**3. Global Account Uniqueness**
Each `account_number` exists exactly once across all subscriber groups. Enforced via unique constraint at database level.

**4. Dynamic Mapping Resolution**
Account-to-subscriber-group mapping changes immediately affect all searches, reports, and display. Mapping changes never modify stored payment records.

**5. Account Auto-Assign** _(supersedes original Import Auto-Create)_
When a payment is added (via import or manual entry) with an unknown `reference_account_number`:
- The system first searches for an existing subscriber group whose name exactly matches the payment's subscriber name.
- If a match is found, the new account is added to that group.
- If no match is found (or subscriber name is empty), a new subscriber group is created.
- **Import-only constraint**: Only rows with an account number starting with '10' (after trimming spaces) are processed during Excel import. Rows with other prefixes are silently ignored.

**6. Subscriber Group Name Uniqueness**
Non-empty subscriber group names must be unique across all groups. Enforced at database level via partial unique index (`WHERE name != ''`). Prevents ambiguous group resolution during auto-assign.

**7. Delete Confirmation**
All destructive delete actions (group, account, payment) must present a confirmation dialog before executing. No silent deletes.

**Deletion Rules:**
- Delete subscriber group: Cascade deletes all accounts in the group. Never touches payments table.
- Delete account: Removes from group. Payments referencing it remain unchanged (become "unmapped").
- Delete payment: Manual user action only.

## Non-Goals

- Multi-language support (Arabic only)
- Audit trail or change history
- Multi-user or concurrent access
- Cloud sync, backup, or replication
- Automatic data backup mechanisms

## Unprocessed
