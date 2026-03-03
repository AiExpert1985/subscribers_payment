## 2026-02-17 | Accounts Screen

**Action:** create
- **Delete Confirmation**: All destructive delete actions (group, account, payment) must present a confirmation dialog before executing. No silent deletes.

---

## System Baseline

**System Identity:** Payment consolidation system for 11+ years of Excel-based historical payment records.

**Core Invariants (original):**
1. **Payment Immutability**: Payment records are never auto-modified or auto-deleted. Only explicit manual user action (edit/delete) can change a payment record. No system process, import, or mapping change may alter existing payment data.
2. **Duplicate Prevention**: A payment is duplicate when the combination of `reference_account_number` + `payment_date` + `amount` already exists. Duplicates must be rejected during import and manual entry. Enforced via composite unique index at database level.
3. **Global Account Uniqueness**: Each `account_number` exists exactly once across all subscriber groups. Enforced via unique constraint at database level.
4. **Dynamic Mapping Resolution**: Account-to-subscriber-group mapping changes immediately affect all searches, reports, and display. Mapping changes never modify stored payment records.
5. **Import Auto-Create (original)**: When importing a payment with an unknown `reference_account_number`, the system auto-creates a new subscriber group and account entry.

**Deletion Rules (original):**
- Delete subscriber group: Cascade deletes all accounts in the group. Never touches payments table.
- Delete account: Removes from group. Payments referencing it remain unchanged (become "unmapped").
- Delete payment: Manual user action only.

**Non-Goals (original):**
- Multi-language support (Arabic only)
- Audit trail or change history
- Multi-user or concurrent access
- Cloud sync, backup, or replication
- Automatic data backup mechanisms

---

## 20260219 | Auto-assign new accounts to existing subscriber groups by name match

**Action:** update — supersedes Contract #5 (Import Auto-Create)
- **Account Auto-Assign**: When a payment is added (via import or manual entry) with an unknown `reference_account_number`, the system first searches for an existing subscriber group whose name exactly matches the payment's subscriber name. If a match is found, the new account is added to that group. If no match is found (or subscriber name is empty), a new subscriber group is created.

**Action:** create
- **Subscriber Group Name Uniqueness**: Non-empty subscriber group names must be unique across all groups. Enforced at the database level (partial unique index where name != ''). Prevents ambiguous group resolution when auto-assigning accounts by name.

---

## 20260224-1335 | Filter Excel Import by Account Number Starting with 10

**Action:** update — amends Account Auto-Assign
- **Import Filter**: Only rows with an account number starting with '10' (after trimming spaces) are processed during Excel import. Rows with account numbers not starting with '10' are silently ignored.

---
