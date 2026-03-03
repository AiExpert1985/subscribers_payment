# Task: UI/UX Overhaul — Pagination, RTL Fixes, PDF, and Accounts Screen

## Summary
Comprehensive UI/UX enhancement across all three screens (Payments, Accounts, Reports). Added server-side pagination to both Payments and Accounts screens (20 rows/page), unified action bar layouts, introduced dual search filters on the Accounts screen, fixed Arabic PDF rendering in Reports, and resolved a Flutter Container crash on hover. All screens now share a consistent RTL-first visual language with compact row heights and a uniform X reset button pattern.

## Scope
✓ Included:
- Payments screen: action bar restructured (import/export far right, add-payment far left), X reset in search row
- Accounts screen: server-side pagination, dual filter (name + account), # row numbering, uniform 130px account chips, hover crash fixed, pen/edit icon removed, "إضافة مشترك" label
- Reports screen: filters in one row, X reset, centered "انشاء تقرير" button, Arabic PDF RTL fix
- All screens: X reset button (small, red, icon-only, appears only when filters are active, placed at far right)
- defaultPageSize changed globally from 50 → 20
- New DB methods: `getSubscriberGroupsPaginated`, `getTotalSubscriberGroupCount`
- New providers: `currentAccountPageProvider`, `accountNameSearchQueryProvider`, `accountSearchQueryProvider`, `totalAccountGroupsProvider`, `totalAccountPagesProvider`

✗ Excluded:
- No changes to data model or schema
- No changes to import pipeline
- No new navigation or routing

## Design Decisions

**RTL Row Layout Rule (codified):**
In Flutter RTL, first child of a `Row` = rightmost on screen; last child = leftmost. This rule is now consistently applied across all screens:
- Delete button → last child (visual left)
- X reset button → first child (visual right / "far right")
- Import/export → first children (far right)
- Add-payment → last child (far left)

**X Reset Button Pattern:**
`SizedBox(width: fixedWidth, child: condition ? IconButton(...) : null)` — the SizedBox always reserves its width, preventing layout shift when the button toggles. Button uses `Icons.close`, red, size 16, padding zero.

**Pagination Display:**
Both Payments and Accounts show "من $startRow إلى $endRow" (row range) instead of a page number. Navigation has four buttons: first, prev, next, last. Server-side LIMIT/OFFSET queries keep it performant on large datasets.

**PDF Arabic RTL:**
- `pw.MultiPage` must have `textDirection: pw.TextDirection.rtl`
- `pw.Row` does NOT support a `textDirection` parameter — RTL visual layout is achieved by reversing children manually (value Expanded first = left, label SizedBox last = right)
- Table columns reversed in `pw.TableHelper.fromTextArray` so the first column appears on the right in RTL reading order

**Account Chips Uniform Width:**
All account number chips in the Accounts screen are wrapped in `SizedBox(width: 130)` to prevent variable-width layout jitter when paging.

**Flutter Container Constraint:**
`Container` cannot have both a `color:` property and a `decoration:` property simultaneously. Color must be placed inside `BoxDecoration` when a border or other decoration is also needed.

## New or Changed Contracts
None.

## Constraints
- Arabic-only RTL interface maintained throughout
- No UI changes to import pipeline
- No schema or migration changes
- `dart analyze` must report zero issues

## Risks & Notes
- `pw.Row` is a known limitation of the `pdf` package — it does not mirror Flutter's `Row` fully. Document this if PDF layout is extended in future.
- Accounts screen no longer shows a hover pen/edit icon; inline editing (tap-to-edit) remains the only edit UX, consistent with the pattern established in the Payments screen improvement task.
