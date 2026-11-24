---
id: TASK-23
title: Android staging builds on my phone
status: In Progress
assignee: []
created_date: '2026-11-24T10:50:00Z'
updated_date: '2026-11-24T22:35:00Z'
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
- [ ] #1 The build talks to staging Supabase; sign-in works with the code
- [ ] #2 Each push to main that changes the app publishes a new release that Obtainium installs on the tester's phone
- [ ] #3 New builds install over the previous one (one staging key); no production key in the repo
<!-- AC:END -->
