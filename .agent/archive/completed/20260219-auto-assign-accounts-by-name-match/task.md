# Task: Auto-assign new accounts to existing subscriber groups by name match

## Goal
When an unknown account number is encountered (via import or manual payment entry), look up an existing subscriber group by the payment's subscriber name (exact match) before creating a new group; if no match, fall back to creating a new group.

## Scope
✓ Included:
- Modify `findOrCreateAccountAndGroup` in `database_service.dart` to query existing subscriber groups by exact name match before creating a new group
- Add DB-level unique constraint (partial index) for non-empty subscriber group names
- DB schema version increment + migration

✗ Excluded:
- Changes to `AddPaymentDialog` UI or form fields
- Changes to import parsing or column alias mapping
- Changes to call sites in `payments_screen.dart` or `import_service.dart`

## Constraints
- Name matching must be exact (case-sensitive)
- Empty/null subscriber name bypasses the lookup and always creates a new group
- Non-empty subscriber group names must be unique across all groups (new contract)
- Payment Immutability contract must not be violated — no existing payment records touched

## Open Questions
- None

---

## Contract-Changes

## Auto-assign Accounts by Name Match | 2026-02-19

**Action:** update
**Change:**
- Contract #5 — Replace: "Import Auto-Create: When importing a payment with an unknown `reference_account_number`, the system auto-creates a new subscriber group and account entry."
  With: "Account Auto-Assign: When a payment is added (via import or manual entry) with an unknown `reference_account_number`, the system first searches for an existing subscriber group whose name exactly matches the payment's subscriber name. If a match is found, the new account is added to that group. If no match is found (or subscriber name is empty), a new subscriber group is created and the account is added to it."

**Action:** create
**Change:**
- **Subscriber Group Name Uniqueness**: Non-empty subscriber group names must be unique across all groups. Enforced at the database level. This prevents ambiguous group resolution when auto-assigning new accounts by name.

---

## Design-Changes

## Auto-assign Accounts by Name Match | 2026-02-19

**Summary:**
- Extend `findOrCreateAccountAndGroup` to match new accounts into existing groups by subscriber name before creating a new group.

**Business Logic:**
- Lookup order for unknown account: (1) exact-match existing group by non-empty subscriber name → assign account there; (2) no match or empty name → create new group as before.
- Non-empty subscriber group names are unique at DB level (partial unique index on `subscriber_groups.name WHERE name != ''`).
- DB schema version incremented; migration adds the partial unique index.

**Deferred:**
- None
