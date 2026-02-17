# Task: Payments Screen with Excel Import

## Goal
Build the Payments screen as the main application view, including paginated payment table with per-column search, inline editing, manual add/delete, and multi-file Excel import with duplicate detection. This is the first user-facing screen in the app.

## Scope
✓ Included:
- Payments screen UI (RTL, Arabic)
- Top action bar: "إضافة تسديد" (add payment) button + "استيراد ملف التسديدات" (import files) button
- Import result summary displayed near import button (success/fail counts, only non-zero rows)
- Per-column search fields above each table column (live filtering on each character)
- Paginated payments table with columns: account_number, subscriber_name, date, amount, stamp_number
- Delete button at end of each row
- Inline edit (small pen icon per cell, click to toggle edit mode)
- Footer: last import timestamp ("تم تحديث البيانات في ----")
- Multi-file picker (multiple Excel files at once)
- Multi-tab (worksheet) support per Excel file
- Column validation via hardcoded aliases (file = successful if 3 key columns found: account_number, amount, date)
- Auto-create subscriber_group + account for unknown account numbers during import
- Duplicate detection via composite unique constraint (reference_account_number + payment_date + amount)
- DB schema changes: add subscriber_name to payments, rename collector_stamp → stamp_number

✗ Excluded:
- Accounts screen
- Reports screen
- Navigation/routing between screens (single screen app for now)
- Print/export functionality
- Date range filter (future task)

## Constraints
- Preserve Contract #1: Payment Immutability — payments never auto-modified
- Preserve Contract #2: Duplicate Prevention — composite unique enforced at DB level
- Preserve Contract #5: Import Auto-Create — unknown accounts auto-create group + account
- subscriber_name in payments is standalone (stored as-is from import, NOT resolved from groups)
- Pagination with server-side LIMIT/OFFSET for 100k+ records performance
- Arabic-only RTL interface
- Excel package needed for file parsing
- file_picker package needed for file selection dialog
