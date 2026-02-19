# Review Outcome

**Status:** APPROVED

## Summary
`findOrCreateAccountAndGroup` now resolves the subscriber group by exact name match before creating a new group, for both import and manual payment entry paths. DB schema version incremented to 2 with a migration that adds a partial unique index enforcing non-empty subscriber group name uniqueness.

## Validation Results
1. Goal Achieved: ✓
2. Contracts Preserved: ✓
3. Scope Preserved: ✓
4. Intent Preserved: ✓
5. No Hallucinated Changes: ✓

## Files Verified
- `lib/data/database_service.dart`

## Notes
- `_resolveOrCreateGroup` (lines 412–430): queries `subscriber_groups` with `name = ?` (exact, case-sensitive), limit 1; returns existing group ID if found, inserts new group otherwise.
- Empty/null subscriber name bypasses the lookup (line 416 guard) and always creates a new group.
- Partial unique index `idx_subscriber_groups_name_nonempty` on `subscriber_groups(name) WHERE name != ''` created in `_onCreate` (fresh) and via `_onUpgrade` version 1→2 (existing installs).
- No changes to payments table, import parsing, UI, or call sites.
