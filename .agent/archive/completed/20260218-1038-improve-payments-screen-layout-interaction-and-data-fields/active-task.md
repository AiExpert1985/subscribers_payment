# Task: Improve Payments Screen Layout, Interaction, and Data Fields

## Goal
Overhaul the payments screen UX (search layout, edit interaction, hover, button positions, row density, numbering, pagination) and surface two data fields (type — already in DB; address — new DB column) across the payments table, search, add/edit form, import, and export.

## Scope

✓ Included:
- Column-aligned search fields: each search input sits directly above its column header, matching that column's width
- Date range search: two date-picker fields (from / to), side-by-side when space allows, stacked when narrow; replaces the existing single-date search field
- Hint text inside every search field indicating which column it filters
- Delete button moved to the right side of each row (leading position in RTL, i.e., before the row content when reading right-to-left)
- Remove pen/edit icon; rows become inline-editable on click (same pattern as accounts screen)
- Hover effect: entire row highlights light grey on mouse-over; each field shows an "edit" tooltip on hover
- Add Payment button relocated into the column-headers row, pinned to the far left (trailing edge in RTL)
- Row padding/margin reduced (rows are currently too tall)
- Global sequential row numbers displayed before each row, counting continuously across pages (page 2 starts where page 1 left off)
- Pagination navigation arrows reversed to correctly reflect RTL direction
- `type` field: already exists in DB — add to payments table display, search, add/edit form, import alias mapping, and Excel export
- `address` field: add as nullable TEXT column via DB migration, then add to payments table display, search, add/edit form, import alias mapping, and Excel export
- All search alignment, hint, and hover rules apply equally to `type` and `address` columns

✗ Excluded:
- No changes to Accounts or Reports screens in this task (unified edit-on-click rule noted as a design decision for future tasks)
- No changes to the duplicate-detection logic (type and address are not part of the uniqueness constraint)
- No new external dependencies

## Constraints
- Payment Immutability: only explicit manual user action (edit/delete) may change a payment record
- Duplicate Prevention contract unchanged: uniqueness enforced on (reference_account_number, payment_date, amount) — type and address are not added to this constraint
- `address` must be nullable (no NOT NULL constraint); existing records get NULL
- DB migration required for `address` (increment DB version)
- RTL layout must be preserved across all changes
- Inline edit pattern must match the accounts screen approach (tap/click field → field becomes editable)

## Open Questions
- None
