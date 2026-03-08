# Task: CSV Import Support for Payments

## Summary
Added CSV as a second accepted import format alongside Excel, motivated by severe performance problems with the `excel` package on 500k-row files. A new `CsvParser` mirrors the existing `ExcelParser` interface and returns the same `ExcelParseResult` type, keeping the rest of the import pipeline format-agnostic. The file picker and routing layer were updated to recognise `.csv` files.

## Scope
✓ Included: `CsvParser` class with auto-delimiter detection (comma / semicolon / tab), UTF-8 BOM stripping, same column-alias system as `ExcelParser`, same date format coverage
✓ Included: `ImportService._parseFile` routing by file extension
✓ Included: Payments screen file picker extended to accept `.csv`
✗ Excluded: CSV export (not requested)
✗ Excluded: Account-mapping import CSV support (not requested)
✗ Excluded: Streaming/chunked CSV parsing (full-file load is sufficient given isolate offloading)

## Design Decisions
- `CsvParser` returns `ExcelParseResult` directly — no new result type needed since the structure is identical.
- Delimiter auto-detected by counting candidate characters in the header line; most-frequent wins.
- `shouldParseNumbers: false` passed to `CsvToListConverter` so all values arrive as strings, handled uniformly by the same parsing helpers as Excel.
- Routing lives in the existing top-level `_parseFile` function (required by `compute()`) — a single extension check, no new entry points.

## New or Changed Contracts
None

## Constraints
- Must reuse the existing `compute()` isolate and `ImportService` pipeline without structural changes.
- Must honour the same column-alias system defined in `column_aliases.dart`.

## Risks & Notes
- The `csv` package was already present in `pubspec.yaml`.
- For very large files the full string is loaded into memory before parsing; acceptable because parsing already runs in an isolate.
- `syncfusion_flutter_xlsio` was evaluated and rejected: write-only in Flutter, no read support, requires a commercial license, no performance advantage over the existing `excel` package.
