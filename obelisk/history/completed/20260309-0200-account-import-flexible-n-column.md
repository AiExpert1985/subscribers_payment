# Task: Account Import — Flexible N-Column Account Detection

## Summary
Replaced the fixed two-column (old/new account) import model with a flexible N-column model. Any column whose header contains a known keyword is treated as an account-number column, enabling single-column files. Per-row routing is now based on DB existence across all account numbers found in the row, with conflict detection when accounts span multiple groups.

## Scope
✓ Included: AccountImportParser (N-column detection, partial keyword matching), AccountImportService (N-account routing logic), AccountImportError model (accounts list replaces oldAccount/newAccount), result dialog and error export (new 2-column layout), tooltip update, Contract 8 update
✗ Excluded: Payment import, Settings screen, any other feature

## Design Decisions
- Column detection uses case-insensitive substring match against 6 keywords: الحساب القديم, الحساب الجديد, account, old, new, account_no — any column containing any keyword qualifies.
- A file with at least one matching column is valid; rows with zero parseable account numbers are silently skipped.
- Per-row routing uses 4 cases keyed by the count of distinct existing group IDs: >1 = conflict error; 0 = create new group; 1 with absent accounts = add to existing group; 1 with no absent = silent skip.
- Error model uses `List<int> accounts` (joined with ، for display) replacing the old `oldAccount`/`newAccount` pair; error export reduced to 2 columns: الأرقام, السبب.

## New or Changed Contracts
Contract 8 updated — see contracts log.

## Constraints
- Contract 3 (Global Account Uniqueness) respected via DB unique constraint.
- Contract 6 (Subscriber Group Name Uniqueness) respected; constraint violations caught and surfaced as "فشل الحفظ".
- No new dependencies introduced.

## Risks & Notes
- "old" and "new" as partial-match keywords are broad — a column named "old_data" or "renewal" would match. Acceptable given the controlled import context.
- Name overwrite still applies whenever a target group is identified; a Contract 6 violation (duplicate name) surfaces as a row error rather than crashing the import.
