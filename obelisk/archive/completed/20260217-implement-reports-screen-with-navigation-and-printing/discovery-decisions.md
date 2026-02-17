## IMPLEMENT_REPORTS_SCREEN_WITH_NAVIGATION_AND_PRINTING | 2026-02-17

**Summary:**
- Add a Reports tab that generates and prints subscriber-level reports from account lookup plus optional date range.

**Architecture / Design (if applicable):**
- Reports is introduced as a first-class app module/screen and wired into app-level navigation.
- Report input UX is fixed: one account number field, then from/to date fields, then generate action.
- Printed output must mirror the on-screen report data.

**Business Logic (if applicable):**
- Report lookup starts from account number; missing account returns a clear "user not found" failure state.
- If account exists, resolve its subscriber group and include payments for all accounts in that group.
- Empty from/to dates mean all-time period.
- Subscriber display name in reports is sourced from current subscriber group mapping (`subscriber_groups.name`).

**Deferred:**
- None.
