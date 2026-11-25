---
id: TASK-17
title: Build the tag editor
status: Done
assignee: []
created_date: '2026-11-23T23:51:00Z'
updated_date: '2026-11-25T17:26:00Z'
labels: []
dependencies:
  - TASK-14
  - TASK-6
ordinal: 9200
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Tags list and Tag group screens from docs/design/visual/screens/tags.html: create, rename, reorder, delete groups and tags; one or several per album; one level of sub-groups; hide built-in groups; changes save immediately; deletes ask with the albums, sub-groups and filters affected.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 All states in tags.html work against the database rules (errors shown as designed)
- [x] #2 Widget tests cover create, rename, reorder, delete, hide and the can't-switch case
<!-- AC:END -->
