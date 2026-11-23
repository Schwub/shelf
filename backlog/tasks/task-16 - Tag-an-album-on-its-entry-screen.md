---
id: TASK-16
title: Tag an album on its entry screen
status: To Do
assignee: []
created_date: '2026-11-23T23:51:00Z'
labels: []
dependencies:
  - TASK-14
  - TASK-6
ordinal: 9100
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Album entry built from the user's tag groups (docs/features/tags.md, docs/design/visual/screens/entry.html): groups up to six tags as keys, larger ones show chosen tags; multiple-choice groups have Add on their label line opening a searchable sheet with Create; sub-groups under their parent tag; Edit tags opens the Tags list and keeps the draft.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Tags save to entry_tags and the screen matches entry.html in evening and daylight
- [ ] #2 Exclusive groups allow one tag; releasing a parent tag removes its sub-tags
- [ ] #3 Widget tests cover keys, sub-group reveal, the Add sheet (search, tick, create, error)
<!-- AC:END -->
