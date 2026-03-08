# Task: Unmatched Accounts in Settings

## Summary
Added a "الحسابات الغير مسجلة" action to the Settings screen that finds all distinct `reference_account_number` values in the payments table that have no matching entry in the accounts table. The result is shown in a dialog with a count, and the user can export the unmatched numbers to a single-column Excel file.

## Scope
✓ Included: New DB method `getUnmatchedPaymentAccountNumbers()`, new `UnmatchedAccountsExportService`, new `_UnmatchedAccountsSection` and `_UnmatchedAccountsResultDialog` widgets in the Settings screen
✗ Excluded: No '10' prefix filtering (payments already filtered at import), no payment metadata in export, no provider/reactive state (one-shot action)

## Design Decisions
- DB query uses `NOT IN (SELECT account_number FROM accounts)` — direct SQL, no application-side set diff
- Export reuses the existing single-column Excel pattern (header row + one value per row) via a dedicated `UnmatchedAccountsExportService` in `lib/settings/`
- Zero-unmatched case shows "جميع الحسابات مسجلة" with no export button

## New or Changed Contracts
None

## Constraints
- Contract 1 (Payment Immutability): operation is read-only, no payments modified
- Contract 5 (Payment Isolation): no accounts or groups created or looked up during the operation beyond the read query

## Risks & Notes
None
