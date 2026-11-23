---
id: TASK-4
title: Build the Android app in CI
status: Done
assignee: []
created_date: '2026-11-23T08:28:00Z'
updated_date: '2026-11-23T08:43:00Z'
labels: []
dependencies: []
ordinal: 4000
---

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A workflow builds the debug APK on pushes and PRs that change app/
- [x] #2 The workflow passes on the session branch
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
First run green (run 45138878468): ~9 min, 6 of them the cold Gradle build. Caching Gradle could cut that if it starts to hurt.
<!-- SECTION:NOTES:END -->
