---
id: TASK-38
title: The feed (M2)
status: Done
assignee: []
created_date: '2026-11-26T10:05:00Z'
updated_date: '2026-11-26T12:12:00Z'
labels: []
dependencies:
  - TASK-37
ordinal: 39000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
docs/features/friends.md, criterion 6. rated_at (trigger) and database-only created_at/rated_at; the feed view (security_invoker) with keyset paging; FeedRepository and the Feed screen with pull to refresh and loading more. Closes the tech-debt item on client-set timestamps. Wireframes: docs/design/wireframes/feed.html.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 pgTAP: the feed shows friends' adds and ratings, newest first, one rating item per album, never hidden entries or strangers'; clients can't set created_at or rated_at
- [x] #2 Widget tests cover every Feed state in screens.md, including loading more and its error
- [x] #3 Integration test: a friend's add and rating appear in the feed in order
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
feed view (security_invoker; added + rated-later items, cursor as text), rated_at trigger, database-only timestamps via column grants; FeedPage (pull to refresh, load more without auto-retry after a failure, refresh drops late pages), FriendAlbumLoader. Also: invite links switched to de.schwubware.shelf://invite/<code> via app_links (launch link via getInitialLink). Review fixes included.
<!-- SECTION:NOTES:END -->
