---
id: TASK-23
title: Android staging builds on my phone
status: Done
assignee: []
created_date: '2026-11-24T10:50:00Z'
updated_date: '2026-11-25T00:03:00Z'
labels: []
dependencies:
  - TASK-21
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
CI builds a release Android app against staging Supabase on every push to main and publishes it as a GitHub release; Obtainium on the phone installs updates. (Firebase App Distribution was the first plan; the Firebase account is at its project limit.)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Each push to main that changes the app publishes a new release that Obtainium installs on the tester's phone
- [x] #2 New builds install over the previous one (one staging key); no production key in the repo
- [x] #3 The build talks to staging Supabase; signing in by the email's link works on the phone
<!-- AC:END -->
