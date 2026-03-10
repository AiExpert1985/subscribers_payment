# Task: Settings Screen — Unify Content into Dialog Buttons

## Summary
Redesigned the Settings screen to replace the inline alias sections and About block with compact buttons that open dialogs. The alias section gained a title and description consistent with the other three action sections. The About section was converted from a static card to a button-triggered dialog.

## Scope
✓ Included: Two separate `OutlinedButton` entries for payment and account column aliases, each opening a dialog with non-collapsible scrollable content
✓ Included: About section converted to a button opening an `AlertDialog`
✓ Included: Alias buttons section gained title ("أسماء أعمدة الاستيراد") and description text matching the style of the three existing action sections
✗ Excluded: Reset sections and unmatched accounts section — unchanged
✗ Excluded: Alias field internals (chips, add/delete, reset) — unchanged

## Design Decisions
- `AliasSectionCard` gained a `collapsible` parameter: when `false`, renders content directly as a flat column (title row + divider + fields) without `Card`/`ExpansionTile`, suitable for dialog use.
- `PaymentAliasSectionCard` and `AccountAliasSectionCard` thin wrappers expose `collapsible` so callers don't need to know internal parameters.
- Alias dialog uses `Dialog` with `ConstrainedBox` (maxWidth 600, maxHeight 80% viewport) + `SingleChildScrollView` — avoids overflow on large field lists.
- About dialog uses standard `AlertDialog` with a close button.
- `_AliasButtons` widget follows the same `Column(title, description, buttons)` pattern as `_ResetSection` and `_UnmatchedAccountsSection`.

## New or Changed Contracts
None

## Constraints
- No structural changes to alias data, providers, or DB access
- No new dependencies

## Risks & Notes
None
