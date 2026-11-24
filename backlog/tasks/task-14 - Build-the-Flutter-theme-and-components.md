---
id: TASK-14
title: Build the Flutter theme and components
status: Done
assignee: []
created_date: '2026-11-23T22:44:00Z'
updated_date: '2026-11-24T09:05:00Z'
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
- [x] #1 Theme and widgets match visual-system.md in evening and daylight
- [x] #2 Widget tests cover key states, rating keys and the filter bar, plus Flutter's tap-target, label and text-contrast guidelines
- [x] #3 A preview page in the app shows every component in both themes
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Theme in app/lib/theme (tokens as a ThemeExtension, Archivo and IBM Plex Sans bundled as variable fonts under the OFL), components in app/lib/widgets (ShelfKey with KeyGeometry, FilterBar, RatingKeys, ShelfBoard, ShelfField), preview as the start screen until sign-in (app/lib/preview). Keys look 44 px and touch 48 px (user decision). Icons are Material Icons for now; the 1.5 px line icon set is still open.
<!-- SECTION:NOTES:END -->
