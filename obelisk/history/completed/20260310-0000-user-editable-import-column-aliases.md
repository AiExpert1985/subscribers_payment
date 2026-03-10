# Task: User-Editable Import Column Aliases via Settings

## Summary
Replaced all hardcoded column header aliases in both import pipelines (payments and accounts) with a user-editable `column_aliases` SQLite table. Users can now add, remove, and reset aliases per field directly from the Settings screen without rebuilding the app. Aliases are fetched from the DB on the main isolate and passed into background isolate parsers as plain maps.

## Scope
✓ Included: `column_aliases` SQLite table with CRUD and per-section reset
✓ Included: DB version bumped 2→3; defaults seeded on first run and upgrade
✓ Included: ExcelParser, CsvParser, AccountImportParser accept aliases as constructor param
✓ Included: ImportService switched from compute() to Isolate.run() to support closure-captured aliases
✓ Included: Settings screen — two collapsible alias-editor cards (payment + account), per-field chip list with add/delete, per-section reset with confirmation
✓ Included: Required fields (payment: account_number/amount/date; account: account) block last-alias deletion
✓ Included: Account import column detection changed from substring to exact case-insensitive match
✗ Excluded: Migration of old hardcoded English aliases to DB (fresh Arabic defaults only)
✗ Excluded: Alias import/export

## Design Decisions
- Default aliases = Arabic translation of each DB column name (one per field), matching the app's Arabic-only identity
- Aliases are loaded on the main isolate before spawning the background parse isolate — avoids SQLite-across-isolate constraint
- Settings screen converted from Column+Spacer to SingleChildScrollView to accommodate new content
- `column_aliases.dart` retained as historical reference; no longer imported by any parser

## New or Changed Contracts
Contract 8 updated: account import column detection changed from substring (contains) to exact case-insensitive match against user-managed aliases in `column_aliases` table.

## Constraints
- No new external packages
- Aliases must be fetched before Isolate.run() — parsers cannot access DB inside isolate
- Existing DB migration pattern followed (onUpgrade version check)

## Risks & Notes
- Account import behavior change (substring → exact) may not match headers in files previously accepted — user accepted this trade-off during discovery
