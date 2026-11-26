---
id: TASK-38
title: The feed (M2)
status: In Progress
assignee: []
created_date: '2026-11-26T10:05:00Z'
updated_date: '2026-11-26T11:38:00Z'
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
- [ ] #1 pgTAP: the feed shows friends' adds and ratings, newest first, one rating item per album, never hidden entries or strangers'; clients can't set created_at or rated_at
- [ ] #2 Widget tests cover every Feed state in screens.md, including loading more and its error
- [ ] #3 Integration test: a friend's add and rating appear in the feed in order
<!-- AC:END -->
