# Task: Settings Tab, Subscribers Export, Payment Import Aliases

## Summary
Added a Settings screen (4th navigation tab) with two protected data-reset buttons — each requiring the user to type "reset" before the destructive action activates. Added a subscribers export button to the Accounts screen that writes all groups and their account numbers to an Excel file (one row per group). Extended the payment import column alias map with four new header names used by a legacy data source.

## Scope
✓ Included:
- Settings screen with "Reset Accounts" and "Reset Payments", each protected by a typed-confirmation dialog
- `resetAllAccounts()` and `resetAllPayments()` on DatabaseService
- 4th bottom-nav item (الإعدادات) with BottomNavigationBarType.fixed
- Subscribers Excel export: DatabaseService.getAllGroupsWithAccounts(), SubscribersExportService, "تصدير المشتركين" button on Accounts screen
- Payment import aliases: o_accountno, o_date, o_amount, o_txtusern

✗ Excluded:
- "Reset everything" combined button
- Filtered/partial subscribers export (always exports all groups)
- Audit trail or undo mechanism for reset operations

## Design Decisions
- Settings screen lives in `lib/settings/` as a new feature folder; does not hold any state (ConsumerWidget)
- Reset protection: typed word "reset" (case-insensitive) — simpler than a second confirmation click and harder to dismiss accidentally
- `_ConfirmResetDialog` is a private StatefulWidget scoped to the settings file; the delete button is disabled until the field matches, eliminating any possibility of premature activation
- Subscribers export uses a new `SubscribersExportService` in `lib/accounts/` (same pattern as `PaymentExportService`); variable-width rows — account columns expand horizontally per group
- `getAllGroupsWithAccounts()` uses sequential per-group queries (N+1) rather than a JOIN, consistent with the existing `subscriberGroupsProvider` approach
- `BottomNavigationBarType.fixed` required when nav items > 3 in Flutter Material

## New or Changed Contracts
- Contract 9 (Reset Operations): Reset Accounts deletes all subscriber_groups and accounts only; Reset Payments deletes all payments only. Neither operation touches the other table. Both require explicit user confirmation (typing "reset").

## Constraints
- Contract 1 (Payment Immutability): Reset Accounts must not touch payments table — enforced by only calling `DELETE FROM subscriber_groups`
- Contract 7 (Delete Confirmation): reset dialogs require typed confirmation before activation

## Risks & Notes
- Hot-reload from 3 → 4 IndexedStack children causes an `_AssertionError` crash — requires a full app restart (not a bug in the code)
- `dart analyze lib/` passes clean after implementation
