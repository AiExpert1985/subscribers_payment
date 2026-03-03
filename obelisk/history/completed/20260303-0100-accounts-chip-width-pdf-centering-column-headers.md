# Task: Accounts Chip Width, PDF Centering, and Column Headers

## Summary
Widened account number chips from 130px to 160px to prevent truncation of longer account numbers. Fixed the PDF report layout so the header is centered, each subscriber info line is rendered as a single centered RTL text, and table cells are center-aligned. Added static column headers (#, اسم المشترك, ارقام الحساب) above the Accounts screen list.

## Scope
✓ Included:
- `_kAccountChipWidth` increased from 130 → 160px (`accounts_screen.dart`)
- `_buildColumnHeaders()` method added; rendered above `ListView` inside a `Column` (`accounts_screen.dart`)
- PDF header `تقرير المشترك` wrapped in `pw.Center`
- `_pdfLine` rewritten: single `pw.Center → pw.Text('$title: $value')` centered RTL line (replaces 2-column Row layout)
- PDF table columns restored to natural order (رقم الحساب → رقم الختم); `cellAlignment` and `headerAlignment` changed to `pw.Alignment.center`
- `design-summary.md` chip width reference updated to 160px

✗ Excluded:
- Payments screen — untouched
- Data layer — untouched
- No new dependencies

## Design Decisions
- Account chip width 130 → 160px: provides enough text area (~110px after delete icon and padding) for 6-7 digit account numbers starting with '10'
- `_pdfLine` simplified to a single centered line: eliminates the manually-reversed `pw.Row` pattern; `pw.Center` + `textAlign: center` + `textDirection: rtl` produces a self-contained centered info line
- PDF table column order reverted to natural (title → stamp) rather than reversed; center alignment replaces previous `centerRight`
- Column headers row mirrors exact spacing of `_buildGroupRow` (40px #, 8px gap, 160px name, 12px gap, Expanded accounts); no header for the delete column

## New or Changed Contracts
None

## Constraints
- `pw.Row` has no `textDirection` param — RTL achieved via child order or explicit `textDirection` on `pw.Text`
- `Container` cannot combine `color:` and `decoration:` — not affected by this task
- Delete confirmation required for all destructive actions — not affected by this task

## Risks & Notes
- `design-summary.md` line 57 still contains the legacy "uniform 130px" text in the row description; line 59 is the corrected reference at 160px. The stale reference on line 57 should be reconciled during the next maintain-project run.
