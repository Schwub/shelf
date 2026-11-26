---
id: TASK-40
title: Edit several albums at once
status: Done
assignee: []
created_date: '2026-11-26T14:34:00Z'
updated_date: '2026-11-26T18:09:00Z'
labels: []
dependencies: []
ordinal: 41000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Select several albums on My shelf (long press, then tap more) and act on them together: add or remove tags, set the Collection or Listening status, hide from or show to friends, remove from the shelf (with Undo, as for one album). Other ideas to weigh while designing: select all in the current filter, export the selection, a count and a clear action bar.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Albums can be selected on My shelf and the selection cleared
- [x] #2 Tags can be added to and removed from all selected albums, following the one-per-group and sub-tag rules
- [x] #3 Selected albums can be hidden or shown to friends and removed together, with Undo
- [x] #4 Wireframes in docs/design/ and widget tests for each action
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-11-26: built as in docs/features/bulk-edit.md (no migration). Reviewed by a fresh agent; fixes: only selected albums in the current filter change, changes notified after a partial failure, fake follows the sub-tag rule, shared album count, SelectMark and SelectionHeader moved out of the page, integration cases for existing tags and parent removal.
<!-- SECTION:NOTES:END -->
