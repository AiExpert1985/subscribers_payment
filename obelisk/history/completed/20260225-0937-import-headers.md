# Task: Update Import Headers, Add yyyyMMDD Date Format, Fix Filter Heights

## Goal
Replace Excel import column aliases with strict new headers (ACCTNO, AMNT, DATER for required; single field-name placeholders for optional). Add yyyyMMDD date string parsing. Fix filter field height mismatch in payments screen.

## Scope
✓ Included: Replacing column aliases, adding yyyyMMDD date parsing, fixing filter heights
✗ Excluded: Database schema changes, other Excel parsing logic changes, UI changes beyond filter row

## Constraints
- **Contract: Import Auto-Create** — import logic and duplicate detection unchanged
- **Design: Excel Import** — alias matching remains case-insensitive and whitespace-trimmed
- Existing date parsing formats (DateCellValue, serial dates, dd/MM/yyyy) must continue working

## Execution Strategy
1. Replace all alias lists in `column_aliases.dart` with single entries (ACCTNO, AMNT, DATER for required; field names for optional).
2. Add yyyyMMDD (8-digit compact date) parsing to `_tryParseDateString` in `excel_parser.dart`.
3. Fix `_textSearchField` in `payments_screen.dart` — remove `isDense: true` and adjust `contentPadding` so TextField fills its 32px SizedBox to match the date picker Container.

## Affected Area
- **Module / Feature:** Import, Payments
- **Entry points:** `column_aliases`, `excel_parser`, `payments_screen`
- **Notes:** None

## Open Questions
- None

---

## Contract-Changes
**Date:** 2026-02-25
**Action:** update
**Change:**
- Excel column matching now strictly uses `ACCTNO`, `AMNT`, and `DATER` for the mandatory fields, preventing accidental matches with old aliases.

## Design-Changes
**Date:** 2026-02-25
- Import date parsing extended to support compact yyyyMMDD format (e.g., 20191029).
- Payment filter fields use uniform visual height through consistent padding/density settings.

## Discovery-Summary
**Intent:** The user requested strict Excel import headers, yyyyMMDD date format support, and visually aligned filter fields.
**Key Decisions:**
- Required aliases: ACCTNO, AMNT, DATER only.
- Optional aliases: single field-name placeholder each.
- yyyyMMDD added alongside existing date formats.
- Height fix via TextField padding/density adjustment.

## Implementation Notes

### Execution Summary
Implemented as specified with one additional adaptation:
- `column_aliases.dart`: replaced all lists with single entries.
- `excel_parser.dart`: added yyyyMMDD parsing in `_tryParseDateString`. Also added fallback on `IntCellValue` and `DoubleCellValue` in `_parseDate` so numeric yyyyMMDD values (e.g., 20191029 stored as int) fall back to string parsing when serial date parsing fails.
- `payments_screen.dart`: removed `isDense: true`, added `expands: true` + `maxLines: null`, adjusted `contentPadding` to `vertical: 6` so TextField fills its 32px SizedBox.

### Divergences
- Specified: only add yyyyMMDD to `_tryParseDateString`
- Actual: also added fallback from `IntCellValue`/`DoubleCellValue` → `_tryParseDateString` in `_parseDate`
- Reason: mechanically necessary because integer yyyyMMDD values (e.g., 20191029) exceed the serial date range check and would return null without this fallback.

## Review

**Status:** APPROVED

1. Goal Achieved: ✔ — `column_aliases.dart` has strict single aliases; `excel_parser.dart` parses yyyyMMDD as text and integer; `payments_screen.dart` TextField fills same height as date picker.
2. Constraints Preserved: ✔ — existing DateCellValue, serial date, and dd/MM/yyyy parsing untouched. Import auto-create and duplicate detection unchanged.
3. Scope Preserved: ✔ — only 3 files modified, all within Import and Payments modules.

**Files Modified:**
- `lib/import/column_aliases.dart`
- `lib/import/excel_parser.dart`
- `lib/payments/payments_screen.dart`

**Notes:** IntCellValue/DoubleCellValue fallback is a mechanical adaptation — serial date parsing still runs first, yyyyMMDD string parsing only runs if serial fails.
