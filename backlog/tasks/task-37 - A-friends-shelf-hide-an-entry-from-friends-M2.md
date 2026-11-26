---
id: TASK-37
title: A friend's shelf; hide an entry from friends (M2)
status: Done
assignee: []
created_date: '2026-11-26T10:05:00Z'
updated_date: '2026-11-26T11:25:00Z'
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
- [x] #1 pgTAP: friends read a friend's visible entries, tags, tracks and manual albums; never hidden entries; strangers and removed friends nothing
- [x] #2 Integration test: two friends each see only their own albums on My shelf, and the other's visible albums on the friend's shelf
- [x] #3 Widget tests for Friend's shelf, Friend's album (on / not on your shelf) and the hide switch
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
hidden column; friends read visible entries, their tags and tracks, tag names and manual albums on visible entries; every own-data query filters by user_id. loadFriend (filters = built-in tags in My shelf's order), FriendShelfPage, FriendAlbumPage (add, manual copy matched by title/artist, open, remove with Undo), Hide from friends switch, HiddenMark, album counts by count query, ShelfRepository.changes reloads My shelf. Review fixes included.
<!-- SECTION:NOTES:END -->
