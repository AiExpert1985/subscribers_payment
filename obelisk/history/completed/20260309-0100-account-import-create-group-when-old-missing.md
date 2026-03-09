# Task: Account Import — Create Group When Old Account Missing

## Summary
Changed account import behavior so "old account not found" no longer causes a skip/error. Instead it triggers group creation or group join depending on whether the new account already exists. This allows importing account mappings even when neither account has been registered yet.

## Scope
✓ Included: AccountImportService import logic (four-case routing)
✓ Included: Contract 8 updated in history-log.md
✗ Excluded: Parser — no changes to how rows are parsed
✗ Excluded: UI — result dialog unchanged

## Design Decisions
Four cases after parsing each row:
- Old exists, new free → add new to old's group (unchanged)
- Old exists, new taken → skip with error (unchanged)
- Old missing, new missing → create new group, insert both accounts
- Old missing, new exists → add old to new's group; skip re-inserting new

Subscriber name, if non-empty, is applied to the target group in all success cases. "Both inserted" counts as 2; "old only inserted" counts as 1.

## New or Changed Contracts
Contract 8 updated — "old account not found" no longer causes a skip; triggers group creation or group join instead. Full four-case behaviour documented in contract.

## Constraints
Contract 3 (Global Account Uniqueness) respected — old account is only inserted when confirmed absent; new account is only inserted when confirmed absent.

## Risks & Notes
None.
