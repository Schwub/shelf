---
id: TASK-35
title: Names and the navigation shell (M2)
status: In Progress
assignee: []
created_date: '2026-11-26T10:05:00Z'
updated_date: '2026-11-26T10:09:00Z'
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
- [ ] #1 profiles table with pgTAP tests; a signed-in user without a profile sees Your name before My shelf
- [ ] #2 The navigation bar switches tabs and each tab keeps its back stack
- [ ] #3 Widget tests for Your name (states in screens.md) and the shell, with accessibility guidelines
<!-- AC:END -->
