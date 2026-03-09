# Task: Fix Account Import — Decimal Parsing, CSV Support, Error Messages, Dialog Overflow

## Summary
Account import was silently skipping every row because Excel stores integers as decimal-formatted text (e.g. "1001.0") and the parser only tried `int.tryParse`, which returns null for such values. This was fixed alongside three related issues: CSV file support was added, error messages were made actionable with the column name and raw failing value, and the result dialog was restructured to prevent overflow.

## Scope
✓ Included: Fix int parsing for decimal-formatted account numbers; add CSV import support; improve parse error messages with column name and raw value; fix dialog overflow by consolidating all errors into a single scrollable table; add csv to file picker extensions
✗ Excluded: Changes to AccountImportService, AccountImportError, or DB logic

## Design Decisions
- `double.tryParse` fallback added after `int.tryParse` to handle "1001.0"-style values without changing the data model (account numbers remain int)
- CSV parsing added directly inside `AccountImportParser` via extension-based routing; reuses the same BOM-strip and delimiter auto-detect pattern already established in `CsvParser`; returns the same result type so the service is untouched
- Error messages now include which column failed and the raw cell value seen, making them useful for debugging without requiring a code change
- Dialog split between "parse errors" (unbounded text) and "row errors" (scrollable table) was the source of the overflow; replaced with a single scrollable table for all errors, showing `'-'` in account columns for parse-level entries

## New or Changed Contracts
None

## Constraints
- Minimum changes to existing code structure
- No new dependencies (csv package already present)
- Contract 8 (Account Import rules) unchanged

## Risks & Notes
- Account numbers that are genuinely non-numeric still correctly produce an error row
- The decimal-to-int conversion truncates (e.g. "1001.9" → 1001); this is correct for account numbers
