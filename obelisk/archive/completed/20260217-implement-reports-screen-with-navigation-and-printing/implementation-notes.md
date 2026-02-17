## active-plan: Implement Reports Screen With Navigation and Printing

### Goal
Add a Reports screen that generates a subscriber-level payment report from an account number and optional date range, shows a clear failure state when account is not found, and supports printing the exact on-screen report.

### Initial Plan

**Approach:**
Implement a dedicated `reports` feature module with a single screen that collects account number and optional date range inputs, then queries data through `DatabaseService` using dynamic mapping logic. Add focused database query methods to resolve the account's subscriber group, fetch all group account numbers, and return matching payments with optional date filtering. Render a report view with summary metadata and payment rows, plus an explicit "user not found" failure state when lookup fails. Integrate printing by generating a PDF from the same report data shown on screen and sending it to the platform print dialog. Wire the new screen into existing app tab navigation without modifying other feature behavior.

**Affected Modules:**
- `/lib/main.dart`
- `/lib/data/database_service.dart`
- `/lib/reports/`

**Files to modify:**
- `/lib/main.dart` - add Reports tab and screen wiring
- `/lib/data/database_service.dart` - add report query helpers and typed result model
- `/pubspec.yaml` - add print dependencies required for report printing

**Files to create:**
- `/lib/reports/reports_screen.dart` - reports UI, report generation flow, and print action

**Key Steps:**
1. Add report-focused read methods in `DatabaseService` for account lookup, group account resolution, and filtered payment retrieval.
2. Build `ReportsScreen` UI and state flow (inputs, generate action, not-found handling, report display, totals).
3. Add print support that renders the generated report data and opens the print dialog.
4. Wire Reports into app navigation and run static analysis to validate changes.

**Constraints:**
- Preserve contracts
- Respect design
- Do not expand scope

---

## Plan Revisions

---

## Execution Summary

**Final approach:** Implemented a new `reports` feature screen with account lookup, optional date range filtering, not-found handling, on-screen report rendering, and print support via PDF generation. Added a report-focused query helper in `DatabaseService` to fetch payments for all account numbers in a subscriber group with optional date bounds, then wired `ReportsScreen` into app-level bottom navigation as a third tab. Added `printing` and `pdf` dependencies and validated changes with `flutter analyze` (clean).

**Deferred items:** None.
