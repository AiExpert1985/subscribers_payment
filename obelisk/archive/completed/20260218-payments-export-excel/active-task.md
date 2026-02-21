# Task: Payments Screen Export to Excel

## Goal
Add an "Export to Excel" action to the Payments Screen that exports all currently filtered payments (across all pages) into an Excel file, saved to a user-chosen path via a system save-file dialog.

## Scope
✓ Included:
- Export button added to the Payments Screen toolbar
- Fetches all filtered records (same filters currently active, no page limit)
- Writes an Excel file with 5 columns matching the screen: account number, subscriber name, date, amount, stamp number
- Opens a system save-file dialog (via file_picker `saveFile()`) for user to choose filename and path
- Uses existing `excel` package (already in pubspec.yaml) for writing
- Uses existing `file_picker` package (already in pubspec.yaml) for save dialog

✗ Excluded:
- PDF/print export (separate concern, not requested)
- Column customization or selection UI
- Auto-save or default path behavior
- Export from Reports screen

## Constraints
- Payment Immutability: export is read-only, no payment records are modified
- No new dependencies required — `excel` and `file_picker` are already present
- Follow feature-first structure: export logic lives in payments module
- Arabic column headers in exported file (matching on-screen labels)
- RTL awareness: data should be readable in standard Excel (no special RTL enforcement needed in file)
