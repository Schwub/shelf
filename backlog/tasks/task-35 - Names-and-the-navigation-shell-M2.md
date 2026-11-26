---
id: TASK-35
title: Names and the navigation shell (M2)
status: Done
assignee: []
created_date: '2026-11-26T10:05:00Z'
updated_date: '2026-11-26T10:31:00Z'
labels: []
dependencies: []
ordinal: 36000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
docs/features/friends.md, criteria 1 and 8. profiles table (owner-only for now; friends read it from TASK-36), Your name after the first sign-in (auth gate step) and changeable later, and the home shell: NavigationBar Shelf / Feed / Friends with one Navigator per tab (Feed and Friends show their empty states until TASK-36/38). Wireframes: docs/design/wireframes/friends.html (Your name).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 profiles table with pgTAP tests; a signed-in user without a profile sees Your name before My shelf
- [x] #2 The navigation bar switches tabs and each tab keeps its back stack
- [x] #3 Widget tests for Your name (states in screens.md) and the shell, with accessibility guidelines
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
profiles table (owner-only; friends read it from TASK-36), NameGate + NamePage, HomePage shell with one Navigator per tab; a shared link switches to Shelf; Your name and bottom sheets open over the bar. Feed and Friends show empty states until TASK-36/38. Also fixed: TextLink had no semantics tap action. Snackbars show in the outer Scaffold, so an Undo can stay up for a few seconds after switching tabs (accepted).
<!-- SECTION:NOTES:END -->
