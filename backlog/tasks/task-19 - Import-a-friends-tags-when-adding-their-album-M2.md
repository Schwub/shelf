---
id: TASK-19
title: Import a friend's tags when adding their album (M2)
status: To Do
assignee: []
created_date: '2026-11-23T23:51:00Z'
updated_date: '2026-11-26T10:05:00Z'
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
- [ ] #1 Missing tags are offered and copied as designed
- [ ] #2 Tests cover matching by key and by name, the type rule and errors
- [ ] #3 The album stores and shows whose shelf it came from (added_from_user_id, added_from_name)
<!-- AC:END -->
