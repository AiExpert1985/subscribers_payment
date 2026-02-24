## Payments Screen with Excel Import | 2026-02-17

**Summary:**
- Build first user-facing screen: Payments with integrated Excel import

**Architecture / Design:**
- Import is integrated into Payments screen (button), not a separate module — departs from design-summary's separate "Import Screen"
- subscriber_name in payments table is standalone, not resolved from subscriber_groups — payments are self-contained historical records
- Pagination with server-side queries for 100k+ record performance

**Business Logic:**
- Excel file is "successful" if it contains the 3 key columns (account_number, amount, date) via alias matching; other columns (subscriber_name, stamp_number) are optional
- Multi-file and multi-tab (worksheet) import supported
- File success is per-file: one successful tab makes the file successful

**Deferred:**
- Date range filter for payments table
- Print/export filtered view
- Accounts screen, Reports screen
