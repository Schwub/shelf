---
id: TASK-16
title: Tag an album on its entry screen
status: Done
assignee: []
created_date: '2026-11-23T23:51:00Z'
updated_date: '2026-11-25T13:08:00Z'
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
- [x] #1 Tags save to entry_tags and the screen matches entry.html in evening and daylight
- [x] #2 Exclusive groups allow one tag; releasing a parent tag removes its sub-tags
- [x] #3 Widget tests cover keys, sub-group reveal, the Add sheet (search, tick, create, error)
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Album entry builds its tag section from the user's visible groups (hidden groups and their sub-groups left out): built-in two-tag groups as equal keys, groups up to six tags as keys, larger ones show the chosen tags; sub-groups indented under their parent tag; multiple-choice groups have Add, a sheet with search, tick and Create. Saving removes tags first, then adds them parents before sub-tags (one insert at a time, so the database's sub-tag check passes). Verified on the web build against local Supabase: Own + Vinyl + File saved; switching to Want removed Own and its formats; Shoegaze created and saved. 'Edit tags' waits for the tag editor (TASK-17).
<!-- SECTION:NOTES:END -->
