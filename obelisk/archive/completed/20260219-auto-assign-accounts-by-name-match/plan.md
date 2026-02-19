# Plan: Auto-assign new accounts to existing subscriber groups by name match

## Goal
When an unknown account number is encountered (via import or manual entry), look up an existing subscriber group by exact subscriber name match before creating a new group.

## Scope Boundaries
✓ In scope: `findOrCreateAccountAndGroup` logic change, DB migration for partial unique index on non-empty group names, schema version increment
✗ Out of scope: UI changes, import parsing, call sites in payments_screen or import_service

---

## Relevant Contracts

- **Account Auto-Assign (updated)** — Unknown account lookup must first match existing group by exact subscriber name; fall back to creating new group only if no match or name is empty.
- **Subscriber Group Name Uniqueness (new)** — Non-empty group names must be unique at DB level.
- **Payment Immutability** — No existing payment records may be touched.
- **Global Account Uniqueness** — Each account_number exists exactly once; the unique DB constraint already enforces this.

---

## Relevant Design Constraints

- **SQLite, single-user** — Partial unique index (`WHERE name != ''`) is supported by SQLite and is the correct mechanism for this constraint.
- **DB schema versioning** — Any schema change requires incrementing the DB version and adding a migration case.
- **Data integrity at DB level** — Uniqueness enforced via index, not only application code.

---

## Execution Strategy

The only change needed is inside `findOrCreateAccountAndGroup` in `database_service.dart`. After confirming the account does not exist, and before creating a new group, query `subscriber_groups` for an existing row whose `name` exactly matches the provided `subscriberName` (only when `subscriberName` is non-null and non-empty). If found, use that group's ID for the new account insert. If not found, proceed with creating a new group as before. Separately, add a DB migration that creates a partial unique index on `subscriber_groups.name WHERE name != ''` and increment the schema version.

---

## Affected Files

- `lib/data/database_service.dart` — Modify `findOrCreateAccountAndGroup`: add name-lookup query before new-group creation. Add migration case for new schema version: create partial unique index on `subscriber_groups(name) WHERE name != ''`. Increment `_kDbVersion`. No contract impact on payments table.
