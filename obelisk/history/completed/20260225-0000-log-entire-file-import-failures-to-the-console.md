# Task: Log entire file import failures to the console

## Goal
Print the failure reason in the console when an Excel file import fails at the file level.

## Scope
✓ Included: Catching whole-file import exceptions (e.g., corrupted file, missing required headers).
✓ Included: Logging the failure reason using `debugPrint` with only necessary information.
✗ Excluded: Logging individual row-by-row data errors.
✗ Excluded: Displaying the error in the UI.

## Constraints
- Use `debugPrint` for console logging.

## Execution Strategy
Update the import logic in `excel_parser.dart` or `import_service.dart` to catch file-level exceptions thrown during the parsing process. In the `catch` block, use `debugPrint` to output a concise message detailing why the entire file failed to import.

## Affected Area
- **Module / Feature:** Import Data
- **Entry points:** `excel_parser.dart`, `import_service.dart`
- **Notes:** None

## Open Questions
- None

---

## Contract-Changes
**Date:** 2026-02-25
**Action:** update
**Change:**
- None.

## Design-Changes
**Date:** 2026-02-25
- Use `debugPrint` for debugging import failures without persisting to a file or UI.

## Discovery-Summary
**Intent:** To improve developer visibility into why an Excel file import fails entirely by outputting a concise failure reason to the debug console.
**Key Decisions:** Log only file-level failures. Use `debugPrint`. Output only necessary information.
**Rejected / Deferred:** Row-level logging was rejected by the user.

## Implementation Notes

### Execution Summary
Two `debugPrint` calls added to cover the full scope of file-level failures:
1. `excel_parser.dart` catch block — for exception-based failures (corrupted file, decode error).
2. `import_service.dart` `!parseResult.isSuccessful` branch — for logical failures (missing required headers across all sheets).

Both files received `import 'package:flutter/foundation.dart'` for `debugPrint`.

### Divergences
- Specified: "In the `catch` block" (single location implied)
- Actual: Two locations — catch block in `excel_parser.dart` AND failure branch in `import_service.dart`
- Reason: Mechanically necessary because "missing required headers" does not throw an exception; it is a logical failure only detectable at the `!isSuccessful` check in `import_service.dart`. Covering only the catch block would miss that scope-included case.

## Review

**Status:** APPROVED

1. Goal Achieved: ✔ — `debugPrint` fires with the failure reason in both failure paths: `excel_parser.dart:56` (exception path) and `import_service.dart:46` (logical failure path).
2. Constraints Preserved: ✔ — `debugPrint` used exclusively; no `print`, no file logging, no UI changes.
3. Scope Preserved: ✔ — Corrupted file (exception path covered), missing required headers (logical path covered). Row-level logging not added. No UI display added.

**Files Modified:**
- `lib/import/excel_parser.dart`
- `lib/import/import_service.dart`

**Notes:** Two locations used instead of one to cover both exception-based and logical file-level failures, both of which are explicitly included in scope.
