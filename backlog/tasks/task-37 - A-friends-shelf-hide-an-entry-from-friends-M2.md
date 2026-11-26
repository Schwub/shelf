---
id: TASK-37
title: A friend's shelf; hide an entry from friends (M2)
status: To Do
assignee: []
created_date: '2026-11-26T10:05:00Z'
updated_date: '2026-11-26T10:05:00Z'
labels: []
dependencies:
  - TASK-36
ordinal: 38000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
docs/features/friends.md, criteria 5, 7 and 9. hidden column; friends' read policies on shelf_entries, entry_tags, entry_tracks, tags, tag_groups and manual albums; every own-data query filters by user_id. ShelfRepository.loadFriend, Friend's shelf and Friend's album screens, the Hide from friends switch and the hidden mark. Wireframes: docs/design/wireframes/friend-shelf.html.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 pgTAP: friends read a friend's visible entries, tags, tracks and manual albums; never hidden entries; strangers and removed friends nothing
- [ ] #2 Integration test: two friends each see only their own albums on My shelf, and the other's visible albums on the friend's shelf
- [ ] #3 Widget tests for Friend's shelf, Friend's album (on / not on your shelf) and the hide switch
<!-- AC:END -->
