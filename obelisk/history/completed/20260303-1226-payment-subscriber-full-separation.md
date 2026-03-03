# Task: Payment / Subscriber Full Separation

## Summary
Fully decoupled payments from subscribers at the contract and code level. Payment import no longer creates accounts or subscriber groups — it stores `reference_account_number` as a raw fact only, which removed the N×3 per-account DB round-trips that were causing slow imports. A new "Import Accounts" feature was added to the Accounts screen: the user uploads an Excel with `الحساب القديم` / `الحساب الجديد` columns, and the system maps new accounts onto existing groups with full error reporting and Excel export of failed rows.

## Scope
✓ Removed auto-creation block from `ImportService` (~25 lines)
✓ `startsWith('10')` filter kept in place (data quality, not related to auto-creation)
✓ New `account_import_parser.dart`: alias-matched Excel parser for 2-column account mapping
✓ New `account_import_service.dart`: validates old/new accounts, inserts, collects errors
✓ New `DatabaseService.getGroupIdByAccountNumber()` helper
✓ Accounts screen: "استيراد حسابات" button, progress dialog, result dialog with error table, Excel error export
✓ Contract 5 replaced: Account Auto-Assign → Payment Isolation
✓ Contract 8 added: Account Import (Accounts screen only)
✓ Design summary updated

✗ No schema changes
✗ No changes to Reports screen or Payments screen UI
✗ `findOrCreateAccountAndGroup` and `getExistingAccountNumbers` kept in `DatabaseService` (still valid utilities)

## Design Decisions
- Parser follows the exact same alias-matching pattern as `ExcelParser` for consistency
- `AccountImportService` is a plain class injected with `DatabaseService` — no new providers needed
- Error model stores `oldAccount?`, `newAccount?`, and `reason` (Arabic string) so the same struct drives both the dialog table and the Excel export
- Excel export uses `excel` package (already a dependency); temp file via `Directory.systemTemp`, saved via `FilePicker.saveFile`
- `_TableCell` added as a private widget at the file level (not inside the state class) to avoid `const` limitations
- `excel` package's `Border` conflicts with Flutter's `Border` — resolved with `hide Border` on the import

## New or Changed Contracts
- Contract 5 replaced: **Payment Isolation** — payments store account numbers as raw facts; no account/group side effects ever
- Contract 8 added: **Account Import** — old→new Excel mapping; old must exist; new must not; errors reported in dialog + exportable to Excel

## Constraints
- No new dependencies (used existing `excel` + `file_picker`)
- All existing contracts (1–4, 6, 7) unchanged
- No schema changes

## Risks & Notes
- `flutter analyze` passed with no issues after implementation
- Payments with account numbers not in the Accounts screen will now appear as "unmapped" in Reports until manually added — this is the intended behavior under the new contract
