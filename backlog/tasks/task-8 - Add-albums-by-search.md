---
id: TASK-8
title: Add albums by search
status: Done
assignee: []
created_date: '2026-11-23T17:42:00Z'
updated_date: '2026-11-25T08:44:00Z'
labels: []
dependencies:
  - TASK-5
  - TASK-6
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Search MusicBrainz release groups, show results with Cover Art Archive covers, add one to the shelf. Covers are stored in our own Supabase Storage (user decision 2026-11-25), not linked to the archive: when an album is first added, a server function (edge function) fetches its cover from the Cover Art Archive once, at about 500 px, and saves it as covers/<album id>.jpg in a public, read-only bucket; albums.cover_url points there. Only the server function writes covers, since albums are shared between users. Write up the design (bucket, function, policies, failure when an album has no cover) before building.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Searching shows matching albums with artist, year and cover
- [x] #2 Choosing a result creates a shelf entry
- [x] #3 Tests cover results, no results and network errors
- [x] #4 The cover of a newly added album is copied once into the covers bucket and albums.cover_url points to our copy
- [x] #5 Users can read covers but can't write or replace them; only the server function stores them (tested)
- [x] #6 An album without a cover, or a failed download, still gets added and shows the blank cover
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Built as in docs/features/search.md: covers bucket and no albums insert for users (migration, pgTAP), add-album edge function with Deno tests (mise run test:functions, in the db workflow), Search page and album entry add mode in the app (http package), deploy to staging in the staging workflow. Verified against local Supabase by running the function with Deno (new album from MusicBrainz with cover stored, existing album, bad ID, throttled MusicBrainz) and real MusicBrainz searches in the web build. Not verified here: Add to shelf through the local edge runtime (it can't load npm packages behind this session's proxy); staging will show it. Needs the repository variable MUSICBRAINZ_CONTACT.
<!-- SECTION:NOTES:END -->
