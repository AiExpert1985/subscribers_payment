# Task: Accounts Screen

## Goal
Implement the Accounts management screen with full CRUD for subscriber groups and their account numbers, accessible via a new bottom navigation bar.

## Scope
✓ Included:
- Bottom navigation bar (Payments, Accounts tabs — Reports placeholder for later)
- Accounts screen listing subscriber groups by name
- Add group button (auto-generates ID, empty name)
- Inline-editable subscriber name (tap to edit)
- Add account number to group via "+" button
- Inline-editable account numbers (tap to edit)
- Delete group with confirmation dialog
- Delete individual account numbers
- Search by account number → shows containing group
- Import auto-creates group with subscriber_name from payment (already exists in `findOrCreateAccountAndGroup`)

✗ Excluded:
- Reports screen (future task)
- Drag-and-drop account reordering
- Move account between groups
- Bulk operations

## Constraints
- **Contracts to preserve:**
  - Payment Immutability — no payment records touched
  - Global Account Uniqueness — enforced at DB level
  - Deletion Rules — cascade deletes accounts, never touches payments
  - **NEW:** Delete Confirmation — all destructive delete actions must show confirmation dialog
- **Design constraints:**
  - Arabic-only RTL interface
  - Clean, compact layout with hover-reveal controls
  - Feature-first folder structure (`lib/accounts/`)
  - Riverpod 3 state management
  - Follow existing code patterns from Payments screen

## Open Questions
- None
