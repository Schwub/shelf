---
id: TASK-33
title: Fix search errors while typing
status: Done
assignee: []
created_date: '2026-11-25T18:39:00Z'
updated_date: '2026-11-25T18:39:00Z'
labels: []
dependencies: []
priority: high
ordinal: 34000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Searching often showed an error until typing again or Try again: MusicBrainz answers 503 to more than one request a second per IP, and the app sent one per pause in typing without pacing or retrying.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Typing a search with short pauses shows results, not an error
- [x] #2 Search and track lookups share one paced MusicBrainz connection that retries 503
- [x] #3 Tests cover pacing, retries and dropped searches
<!-- AC:END -->
