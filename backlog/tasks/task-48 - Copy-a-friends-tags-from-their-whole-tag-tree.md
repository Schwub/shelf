---
id: TASK-48
title: Copy a friend's tags from their whole tag tree
status: To Do
assignee: []
created_date: '2026-11-27T00:10:00Z'
labels: []
dependencies: []
ordinal: 49000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replaces TASK-19's import sheet (docs/design/wireframes/copy-tags.html, agreed 2026-11-27): adding a friend's album opens their whole tag tree; each of their groups goes into one of the user's groups, a new one, or nowhere, remembered per friend (new table tag_group_destinations); ticking a sub-tag brings its path; copied album tags are set on the entry.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The friend's whole tag tree shows with marks (on this album, you have it, new); the album's new tags are ticked
- [ ] #2 Each of the friend's top-level groups has a destination (same-name group by default, any group of the user's, a new group, or none), remembered per friend in the database
- [ ] #3 Ticking a sub-tag ticks its parent; unticking a parent unticks its sub-tags
- [ ] #4 Copy creates the ticked tags in their destinations and sets the album's ones on the entry; with nothing to copy the screen is skipped and a link opens it
- [ ] #5 Database, unit, widget and integration tests cover destinations, copying and errors
<!-- AC:END -->
