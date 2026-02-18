## active-plan: Payments Screen Export to Excel

### Goal
Add an "Export to Excel" action to the Payments Screen that exports all currently filtered payments (across all pages) into an Excel file, saved to a user-chosen path via a system save-file dialog.

### Initial Plan

**Approach:**
The `excel` package (v4.0.6) and `file_picker` (v10.3.10) are both already in pubspec.yaml — no new dependencies needed. A new `getPaymentsFiltered` method is added to `DatabaseService` that queries without pagination, reusing the existing `_buildWhereClause` helper. A `PaymentExportService` class handles building the Excel workbook from a payment list and writing bytes to disk. The payments screen gains an export button in the action bar and an `_exportToExcel` method that orchestrates: read filters → fetch all → build Excel → save dialog → write file.

**Affected Modules:**
- Data layer (`database_service.dart`)
- Payments feature (`payments_screen.dart`, new `payment_export_service.dart`)

**Files to modify:**
- `lib/data/database_service.dart` — add `getPaymentsFiltered` method (no pagination, same filter logic)
- `lib/payments/payments_screen.dart` — add export button, `_isExporting` state, `_exportToExcel` method

**Files to create:**
- `lib/payments/payment_export_service.dart` — builds Excel bytes from Payment list and writes to file

**Key Steps:**
1. Add `getPaymentsFiltered({Map<String, String> filters})` to `DatabaseService`
2. Create `PaymentExportService` with `buildExcelBytes(List<Payment>)` → `List<int>?` and `writeToFile(String path, List<int> bytes)`
3. Add `_isExporting` bool to `_PaymentsScreenState`
4. Add export `FilledButton.tonalIcon` to `_buildActionBar`
5. Implement `_exportToExcel`: fetch all filtered rows → build Excel → `FilePicker.platform.saveFile()` → write bytes → show SnackBar result

**Constraints:**
- Preserve contracts
- Respect design
- Do not expand scope

---

## Plan Revisions

---

## Execution Summary

**Final approach:** Added `getPaymentsFiltered` to `DatabaseService` (no pagination, reuses `_buildWhereClause`). Created `PaymentExportService` in `lib/payments/` to build Excel bytes via `excel` package and write to disk via `dart:io`. Added export button and `_exportToExcel` method to `payments_screen.dart` — reads current filters, fetches all matching rows, opens `FilePicker.saveFile()` dialog, writes file, shows SnackBar on success/failure.

**Deferred items:** None
