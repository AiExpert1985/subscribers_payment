# Task: Account Import — Name Update on Silent Skip & Settings About Section

## Summary
Two independent improvements: (1) the account import "all already in same group" case previously did nothing; it now applies a name update if a non-empty `اسم المشترك` is present, with name-uniqueness conflicts silently ignored. (2) A static "About" section was added to the bottom of the Settings screen displaying the program title and authorship credit in styled Arabic text.

## Scope
✓ Included: Name update in the silent-skip routing case of account import; static About section at the bottom of SettingsScreen
✗ Excluded: Any changes to routing logic, error dialog, export, or other import pipeline behaviour

## Design Decisions
- Name conflict (Contract 6 uniqueness) in the silent-skip case is caught and silently swallowed — the row is still not reported as an error, consistent with the "silent skip" contract.
- About section is a static widget pinned to the bottom via `Spacer()`, rendered as a rounded container with theme-derived surface color and border. No dialog or interaction needed.

## New or Changed Contracts
Contract 8 updated — "All already exist in the same group" case now reads: update group name if present (name conflict silently ignored), then silent skip (not an error).

## Constraints
- RTL layout and Arabic-only text throughout
- No new dependencies

## Risks & Notes
None.
