---
id: TASK-14
title: Build the Flutter theme and components
status: To Do
assignee: []
created_date: '2026-11-23T22:44:00Z'
labels: []
dependencies: []
ordinal: 5800
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Turn docs/design/visual-system.md into the app's theme: colour tokens for evening and daylight, Archivo and IBM Plex Sans bundled under their open licences, and the shared widgets: the C4 key (rest, pressed state B, half-pressed for ratings, light window fixed at the start, haptic click), filter bar with labels above, shelf board, rating keys, recessed field. Built by one person before any screen work, since every screen depends on it.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Theme and widgets match visual-system.md in evening and daylight
- [ ] #2 Widget tests cover key states, rating keys and the filter bar, plus Flutter's tap-target, label and text-contrast guidelines
- [ ] #3 A preview page in the app shows every component in both themes
<!-- AC:END -->
