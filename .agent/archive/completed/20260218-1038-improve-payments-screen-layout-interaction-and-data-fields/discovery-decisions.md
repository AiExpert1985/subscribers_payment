## Improve Payments Screen Layout, Interaction, and Data Fields | 2026-02-18

**Summary:**
- Overhaul payments screen UX and surface `type` (existing DB field) and new `address` field across all payment flows

**Architecture / Design:**
- Inline edit-on-click is now the unified UX pattern for all app screens — no separate edit icon; clicking any field activates inline editing (established here, to be applied to other screens in future tasks)
- Search fields are positionally coupled to their columns (rendered above the column header, matching column width) rather than in a separate filter bar
- Date filter splits into two date-picker fields (from / to) rendered side-by-side, collapsing to vertical stack on narrow widths
- Row numbers are global sequence (not per-page restart), computed from page offset + local index

**Business Logic:**
- `type` and `address` are optional (nullable) — not part of duplicate detection constraint
- `address` DB migration increments schema version; existing records receive NULL
- Import alias mapping extended to recognise `type` and `address` column headers from Excel source files
