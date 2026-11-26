---
id: TASK-41
title: Show and filter by when an album was added
status: Done
assignee: []
created_date: '2026-11-26T14:34:00Z'
updated_date: '2026-11-26T17:39:00Z'
labels: []
dependencies: []
ordinal: 42000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Show the date an album was added (shelf_entries.created_at, set by the database) on the album entry and in the list view, and let custom filters use it: added in the last N days or between two dates (docs/features/filters.md).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The album entry and the list view show the date added
- [x] #2 A custom filter can match albums added in the last N days or between two dates
- [x] #3 Database and widget tests cover the new condition
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-11-26: ShelfEntry.addedAt (created_at) shown on the album entry and in the list; filters: added_within_days or added_from/added_to (migration 20261126240000), editor section Added with the Material date range picker, described in the filters list.
<!-- SECTION:NOTES:END -->
