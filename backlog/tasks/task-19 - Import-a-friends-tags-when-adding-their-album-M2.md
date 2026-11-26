---
id: TASK-19
title: Import a friend's tags when adding their album (M2)
status: Done
assignee: []
created_date: '2026-11-23T23:51:00Z'
updated_date: '2026-11-26T14:46:00Z'
labels: []
dependencies:
  - TASK-37
ordinal: 20000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
From docs/design/visual/screens/import.html and docs/features/tags.md: built-in tags match by key; missing tags offered (all, pick, skip) and copied into the user's groups; copied new groups take the friend's type; copies stay if the add is cancelled. Needs friends (M2).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Missing tags are offered and copied as designed
- [x] #2 Tests cover matching by key and by name, the type rule and errors
- [x] #3 The album stores and shows whose shelf it came from (added_from_user_id, added_from_name)
- [x] #4 The friend's track list is copied without their favorites; without one, MusicBrainz's is suggested as for a new album
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-11-26: app/lib/shelf/tag_import.dart (plan and copy), import_tags_sheet.dart, EntryPage.fromFriend/tracks. added_from written by add/addManual; the integration test checks the columns and load (add() itself needs the edge runtime, not running in test:integration). Reviewed by a fresh agent; fixes: no closing the sheet while copying, fresh shelf for each Add, sub-tags ticked with parents. Accepted debt: extra reloads per copy (docs/tech-debt.md).
<!-- SECTION:NOTES:END -->
