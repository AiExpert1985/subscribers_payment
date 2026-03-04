# Task: UI Fixes — Payment Inline Editing, Button Color, Report Filter Height

## Summary
Three targeted UI fixes. Empty/null cells in the payments table were not responding to click because `GestureDetector` on Flutter desktop only hit-tests against visible pixels — `Text('')` renders none, so taps fell through. Fixed with `HitTestBehavior.opaque` + `BoxConstraints(minHeight: 36)`. The "Import Accounts" button color was changed from teal to the app's theme primary color to match the sibling "إضافة مشترك" button. The date filter fields in the reports screen were taller than the account number field because `_DateField`'s `InputDecorator` lacked `isDense: true` — adding it along with matching `contentPadding` aligns all three filters to the same height.

## Scope
✓ Included: Payment screen — empty cell tappability fix
✓ Included: Accounts screen — import button color normalized
✓ Included: Reports screen — date filter fields height aligned to account field
✗ Excluded: Any functional or data-layer changes

## Design Decisions
- `GestureDetector` on Flutter desktop requires `HitTestBehavior.opaque` for empty-content cells; default behavior only hits visible pixels
- `BoxConstraints(minHeight: 36)` ensures a stable minimum tap area for all payment cells regardless of value
- `_DateField` height alignment done via `isDense: true` + `contentPadding: symmetric(horizontal: 12, vertical: 12)` — same values as the account field — rather than wrapping in a `SizedBox` with fixed height, keeping the `InputDecorator`'s floating label behavior intact

## New or Changed Contracts
None

## Constraints
- No functional or data changes — purely widget-level visual/interaction fixes
- Design patterns followed: existing `_buildEditableCell` structure preserved; no new widgets introduced

## Risks & Notes
- `HitTestBehavior.opaque` on `GestureDetector` also captures taps that would otherwise pass through to widgets behind it — confirmed safe here since cells are non-overlapping table cells
