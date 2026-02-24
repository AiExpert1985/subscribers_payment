# Task: Implement Reports Screen With Navigation and Printing

## Goal
Add a Reports screen that generates a subscriber-level payment report from an account number and optional date range, shows a clear failure state when account is not found, and supports printing the exact on-screen report.

## Scope
- Included: Reports screen UI with account number field, optional from/to date fields, and "Generate Report" action
- Included: Account lookup by account number; if not found, show failure message ("user not found")
- Included: If found, resolve subscriber group and collect all group accounts, then load all related payments
- Included: Optional date filtering; empty from/to means full historical period
- Included: Report display with subscriber group name, account numbers, period, total amount, and detailed payments table
- Included: Print action that prints the same data shown in the generated report
- Included: App navigation wiring to add Reports as a tab/screen
- Excluded: Changes to existing import flow, payments table flow, or accounts management behavior outside report integration
- Excluded: New export formats, backup/sync, or unrelated architectural changes

## Constraints
- Preserve Payment Immutability and never auto-modify payment records.
- Preserve Dynamic Mapping Resolution for reports (mapping changes must reflect immediately).
- Preserve Global Account Uniqueness and existing duplicate-prevention behavior.
- Subscriber name in report must come from `subscriber_groups.name` (not `payments.subscriber_name`).
- Arabic-only RTL experience must remain consistent with current app design.

## Open Questions (if any)
- None.
