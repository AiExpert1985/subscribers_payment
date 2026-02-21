## Payments Screen Export to Excel | 2026-02-18

**Summary:**
- Add Excel export for all currently filtered payments via save-file dialog

**Architecture / Design:**
- Export scope is all filtered records (full dataset, not current page only)
- Save path determined by user via `file_picker.saveFile()` dialog
- Uses existing `excel` package for writing; no new dependencies introduced
- Export action lives in the payments feature module

**Deferred:**
- None
