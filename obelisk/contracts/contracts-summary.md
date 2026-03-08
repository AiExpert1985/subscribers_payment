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

**5. Payment Isolation**
Payment import and manual payment entry store `reference_account_number` as a raw fact only. No account or subscriber group is ever created, modified, or looked up during any payment operation. Payments and subscribers are fully decoupled in both directions.

**6. Subscriber Group Name Uniqueness**
Non-empty subscriber group names must be unique across all groups. Enforced at database level via partial unique index (`WHERE name != ''`). Prevents ambiguous group resolution during auto-assign.

**7. Delete Confirmation**
All destructive delete actions (group, account, payment) must present a confirmation dialog before executing. No silent deletes.

**8. Account Import (Accounts screen only)**
An Excel file with columns `الحساب القديم` / `الحساب الجديد` and an optional `اسم المشترك` can be imported from the Accounts screen. For each row: if the old account exists in the DB, the new account is added to the same subscriber group. If `اسم المشترك` is present and non-empty, the subscriber group's name is overwritten with that value (regardless of any existing name). A blank/missing name cell leaves the group name unchanged. Rows where the old account is not found, the new account already exists, or required cell values are invalid are skipped. All skipped rows are collected and shown in a result dialog with an option to export them to Excel (columns: الحساب القديم, الحساب الجديد, السبب).

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

## New

## 20260303-1226 | Payment / Subscriber Full Separation

- Contract 5 (Account Auto-Assign) replaced by Contract 5 (Payment Isolation): payment import and manual entry never create or modify accounts/groups.
- Contract 8 added (Account Import): Excel-based old→new account mapping via Accounts screen only; old must exist, new must not; failures reported + exportable.

---

## 20260304-1358 | Settings Tab, Subscribers Export, Payment Import Aliases

- Contract 9 added (Reset Operations): Reset Accounts deletes all subscriber_groups and accounts only (cascade); Reset Payments deletes all payments only. Neither operation touches the other table. Both require explicit typed confirmation ("reset").

---
