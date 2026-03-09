# Task: Account Import — Expanded Column Header Keywords

## Summary
Expanded the account-number and subscriber-name column detection keyword lists in the account import parser to match a broader set of real-world Excel/CSV column headers. The change is purely additive — no routing or pipeline logic was altered.

## Scope
✓ Included: Added "حساب", "قديم", "جديد", "account no" to account keyword list; added "اسم" to name alias list
✗ Excluded: Routing logic, name column's role in the pipeline, detection strategy (still substring/contains for accounts, exact-match for names)

## Design Decisions
- Account keyword detection continues to use substring/contains matching (case-insensitive) — new keywords follow the same pattern
- Name column remains exact-match detection; "اسم" added as an additional alias
- Existing keywords retained alongside new ones for safety (redundant but harmless)
- Name column is not used for account matching/routing — only for updating the group name when present

## New or Changed Contracts
None

## Constraints
- Must not alter routing logic or parser structural behavior
- Additive change only

## Risks & Notes
Adding "حساب" as a substring keyword means a column named "اسم الحساب" would be detected as an account column. Accepted: in practice account-import files won't have such a column, and even if they do, non-integer cell values are silently skipped — no data corruption.
