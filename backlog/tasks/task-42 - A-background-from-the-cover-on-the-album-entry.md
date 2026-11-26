---
id: TASK-42
title: A background from the cover on the album entry
status: Done
assignee: []
created_date: '2026-11-26T14:34:00Z'
updated_date: '2026-11-26T16:56:00Z'
labels: []
dependencies: []
ordinal: 43000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Give the album entry a background drawn from its cover: the cover blurred and zoomed in behind it, or a gradient from its most prominent colours. Compare both in a mockup in the current themes (text contrast, light and dark), then build the chosen one; covers added by hand and missing covers need a fallback.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A mockup compares the blurred cover and the colour gradient, and one is chosen
- [x] #2 The album entry shows the chosen background, with readable text in every theme (contrast guideline in widget tests)
- [x] #3 Albums without a cover keep today's look
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Option A (blurred cover) chosen 2026-11-26. app/lib/widgets/album_stage.dart on the album entry and a friend's album (which got the entry's stage and a Back key on it). Contrast: the blur fades out before the text, so text stays on the plain background; the existing accessibility tests run on both screens. Checked in Evening and Daylight with the visual-check skill.
<!-- SECTION:NOTES:END -->
