---
id: TASK-26
title: Add an album by hand
status: To Do
assignee: []
created_date: '2026-11-25T14:27:00Z'
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
- [ ] #1 Search offers 'Add it yourself'; the form needs title and artist, year and cover are optional
- [ ] #2 The album is added by the function with created_by and the photo stored as its cover; other users can't see it (pgTAP)
- [ ] #3 The album entry, tags, rating and comment work as for MusicBrainz albums
- [ ] #4 Tests: form validation, add with and without photo, function validation (size, type, missing fields)
<!-- AC:END -->
