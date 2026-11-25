---
id: TASK-26
title: Add an album by hand
status: Done
assignee: []
created_date: '2026-11-25T14:27:00Z'
updated_date: '2026-11-25T14:40:00Z'
labels: []
dependencies: []
ordinal: 27000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
For albums MusicBrainz doesn't have: 'Add it yourself' from search (results and no results) opens a form for title, artist, year and a cover from a photo (camera or gallery, image_picker). The add-album function adds it (no MusicBrainz ID, created_by = the user) and stores the cover in the covers bucket; manual albums are visible only to their creator (friends later, M2). Design in docs/features/search.md, 'Albums added by hand'.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Search offers 'Add it yourself'; the form needs title and artist, year and cover are optional
- [x] #2 The album is added by the function with created_by and the photo stored as its cover; other users can't see it (pgTAP)
- [x] #3 The album entry, tags, rating and comment work as for MusicBrainz albums
- [x] #4 Tests: form validation, add with and without photo, function validation (size, type, missing fields)
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Built as designed (docs/features/search.md, 'Albums added by hand'): albums.created_by with owner-only read and a not-both check (pgTAP), add-album manual path with field and photo checks (Deno tests; verified against local Supabase: added as the user's with the photo stored, missing title 400, bad token 401), form with photo from camera or gallery (image_picker, 500 px), EntryPage.manual. Search offers 'Add it yourself' under results, with no results and when MusicBrainz fails; search words are now ANDed so made-up titles find nothing. iOS: Info.plist got the camera and photo library texts; the iOS build isn't verified (needs a Mac).
<!-- SECTION:NOTES:END -->
