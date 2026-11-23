---
id: TASK-7
title: Resolve shared album links
status: To Do
assignee: []
created_date: '2026-11-23T17:42:00Z'
labels: []
dependencies:
  - TASK-5
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Turn a shared Spotify or Bandcamp link into album data without a Spotify developer app: MusicBrainz URL lookup first, then oEmbed or page metadata (see Risks in docs/project.md). Needs musicbrainz.org and open.spotify.com allowed in the cloud environment (approve from a computer).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 MusicBrainz hit rate measured on at least 10 real shared links and noted in docs/project.md
- [ ] #2 A shared Spotify and Bandcamp link each resolve to title, artist and cover
- [ ] #3 Tests use recorded responses, no live network
<!-- AC:END -->
