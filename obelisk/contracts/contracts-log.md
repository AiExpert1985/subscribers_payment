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
An Excel or CSV file can be imported from the Accounts screen. Any column whose header contains (case-insensitive, substring) any of: `الحساب القديم`, `الحساب الجديد`, `account`, `old`, `new`, `account_no` is treated as an account-number column. A file must have at least one such column. The optional `اسم المشترك` column is detected by exact alias match. Rows with no parseable account numbers are silently skipped.

Per-row routing (using all account numbers found in the row):
- All absent from DB → create new subscriber group (with name if present), insert all accounts.
- Some/all exist in exactly ONE group, rest absent → add absent accounts to that group; update group name if present.
- Accounts found across MORE THAN ONE group → skip with error "تعارض في المجموعات".
- All already exist in the same group → silent skip (not an error).

If `اسم المشترك` is non-empty the target group's name is overwritten; a blank/missing cell leaves it unchanged. All skipped rows are collected and shown in a result dialog with an option to export them to Excel (columns: الأرقام, السبب).

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


20260309-0100 | Account Import — Create Group When Old Account Missing | UPDATE
Old: "Rows where the old account is not found, the new account already exists, or required cell values are invalid are skipped."
New: If old account doesn't exist and new account also doesn't exist → create new subscriber group, insert both accounts. If old account doesn't exist but new account exists → add old account to new's group; new is not re-inserted. Old-exists cases are unchanged.

20260309-0200 | Account Import — Flexible N-Column Account Detection | UPDATE
Old: "An Excel or CSV file with columns الحساب القديم / الحساب الجديد and an optional اسم المشترك can be imported from the Accounts screen. For each row: Old exists, new doesn't → new account added to old's group. Old exists, new already exists → skipped with error 'الحساب الجديد موجود مسبقاً'. Old doesn't exist, new doesn't exist → new subscriber group created; both accounts inserted into it. Old doesn't exist, new already exists → old account added to new's group; new is not re-inserted. If اسم المشترك is present and non-empty, the target group's name is overwritten. Rows with invalid/missing required cell values are skipped. All skipped rows are collected and shown in a result dialog with an option to export them to Excel (columns: الحساب القديم, الحساب الجديد, السبب)."
New: An Excel or CSV file can be imported from the Accounts screen. Any column whose header contains (case-insensitive, substring) any of: الحساب القديم, الحساب الجديد, account, old, new, account_no is treated as an account-number column. A file must have at least one such column. The optional اسم المشترك column is detected by exact alias match. Rows with no parseable account numbers are silently skipped. Per-row routing (using all account numbers found in the row): All absent from DB → create new subscriber group (with name if present), insert all accounts. Some/all exist in exactly ONE group, rest absent → add absent accounts to that group; update group name if present. Accounts found across MORE THAN ONE group → skip with error "تعارض في المجموعات". All already exist in the same group → silent skip (not an error). All skipped rows are collected and shown in a result dialog with an option to export them to Excel (columns: الأرقام, السبب).
