---
id: TASK-1
title: Spike share-to-add on iOS and Android
status: In Progress
assignee: []
created_date: '2026-11-22T22:05:00Z'
updated_date: '2026-11-23T03:55:00Z'
labels: []
dependencies: []
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Share a Spotify and a Bandcamp album link from another app into the Flutter app on both phones; the iOS share extension is the unknown.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A shared Spotify link reaches the app on iOS and Android
- [ ] #2 A shared Bandcamp link reaches the app on iOS and Android
- [x] #3 Findings noted in docs/architecture.md
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified: Android (Pixel 9a emulator) Spotify text cold start and Bandcamp warm start; iOS simulator Spotify link from Safari share sheet, cold start. Not verified: iOS warm start and Bandcamp on iOS (simulator too slow on this machine), real devices.
<!-- SECTION:NOTES:END -->
