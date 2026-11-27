---
id: TASK-49
title: Copy or map a friend's tags in their tree (v4)
status: To Do
assignee: []
created_date: '2026-11-27T10:31:00Z'
labels: []
dependencies: []
ordinal: 50000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Rework of the copy screen per docs/design/wireframes/copy-tags-4.html, agreed 2026-11-27: album tags shown with their paths in the friend's tree; one target per row (Copy keeps the friend's structure, or anywhere in my tree at any depth, built-ins included); default = remembered, else same name anywhere, else Copy; nothing ticked, tags taken before marked and counted; a tag sent elsewhere goes without its path; one-per-album: newer tick wins; summary of what is created; remembered per friend: group targets, tag targets and taken tags (new owner-only table).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Rows show the album's tags with their paths in the friend's tree, and each row's target (Copy, or any group, tag or sub-group position of mine)
- [ ] #2 Default targets: remembered, else same name anywhere, else Copy; nothing ticked, tags taken before marked and counted in the Tick button
- [ ] #3 A tag mapped out of its chain goes alone; in a one-per-album group the newer tick wins with a note
- [ ] #4 Group and tag targets and taken tags are remembered per friend (new table, pgTAP and integration tests)
- [ ] #5 A summary line lists what Use N tags creates
<!-- AC:END -->
