# Task: Add اسم المشترك Column to Account Import + Tooltip Hint

## Summary
Added an optional `اسم المشترك` column to the account import Excel pipeline. When the old account is found and the name cell is non-empty, the subscriber group's name is overwritten unconditionally. Also added a tooltip to the "استيراد حسابات" button listing the expected Excel columns.

## Scope
✓ Included: `AccountImportParser` — optional name column detection (order-independent, alias-matched)
✓ Included: `AccountImportRow` typedef extended with `String? subscriberName`
✓ Included: `AccountImportService` — update group name before inserting new account
✓ Included: `accounts_screen.dart` — Tooltip on import button
✓ Included: Contract 8 updated
✓ Included: Design summary updated
✗ Excluded: No DB schema changes (subscriber_groups.name already exists)
✗ Excluded: No error reporting for name update failures

## Design Decisions
- Blank/missing name cell → null → no-op on group name (safer default, avoids accidental wipes)
- Name column matched by header alias (order-independent, consistent with existing parser pattern)
- Name update applied before new account insert so both old and new accounts share the updated name immediately
- Name failures are silent (non-critical — group and account insert still succeed)

## New or Changed Contracts
Contract 8 updated: account import now accepts optional `اسم المشترك` column; non-empty value overwrites the subscriber group name; blank/missing cell leaves name unchanged.

## Constraints
- No new dependencies introduced
- No DB migrations required
- Existing 2-column files import without regression

## Risks & Notes
None.
