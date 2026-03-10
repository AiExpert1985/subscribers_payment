# Task: Top Bar UI Refresh — Action Bars, Button Layout, Tab Bar Color

## Summary
Wrapped the action buttons on the Payments and Accounts screens in a styled full-width top bar container with a light teal background and subtle shadow, visually separating controls from data. The Accounts screen button layout was aligned to match the Payments screen (import/export on the right, add-new on the far left). The bottom navigation bar was given a matching light teal background with a softer unselected item color.

## Scope
✓ Included: Payments screen top bar styling, Accounts screen top bar styling + button reorder, bottom nav bar color update
✗ Excluded: Reports and Settings screens, filter/search fields (remain column-aligned inside the table), screen titles in the top bar

## Design Decisions
- Top bar is a full-width Container (no outer padding) so it visually anchors to the screen edge like a real app bar; content below uses fromLTRB padding.
- Filters were deliberately kept column-aligned inside the scrollable table area to preserve the visual column-to-filter relationship.
- Color `#E0F2F1` (teal[50]) used consistently for both top bars and the bottom nav bar to create a unified light accent palette.

## New or Changed Contracts
None

## Constraints
RTL layout rule preserved: first Row child = rightmost on screen; last child = leftmost.

## Risks & Notes
None
