---
id: TASK-39
title: Sort the shelf
status: Done
assignee: []
created_date: '2026-11-26T14:28:00Z'
updated_date: '2026-11-26T17:17:00Z'
labels: []
dependencies: []
ordinal: 40000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
My shelf (and a friend's) shows albums newest first, with no other order. Let the user sort entries, e.g. by date added, title, artist, year or rating, ascending or descending; the choice is kept with the user's settings across devices.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The user can sort the shelf by date added, title, artist, year and rating, in either direction
- [x] #2 The chosen order is kept in the user's settings and applies on every device
- [x] #3 Tests cover each order and keeping the choice
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-11-26: ShelfSort in app/lib/shelf/shelf.dart (sorted in the app; date added is the load order until TASK-41 adds the date), sort sheet (sort_sheet.dart) from a key in My shelf's bottom bar, user_settings.shelf_sort (migration 20261126220000). Friends' shelves follow the user's order.
<!-- SECTION:NOTES:END -->
