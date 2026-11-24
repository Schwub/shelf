---
id: TASK-23
title: Android staging builds on my phone
status: To Do
assignee: []
created_date: '2026-11-24T10:50:00Z'
updated_date: '2026-11-24T10:50:00Z'
labels: []
dependencies:
  - TASK-21
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
CI builds a release-signed Android app against staging Supabase on every push to main and sends it to testers with Firebase App Distribution.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Each push to main delivers a new Android build to the tester's phone
- [ ] #2 The build talks to staging Supabase; sign-in works with the code
- [ ] #3 The signing key and Firebase credentials live only in GitHub secrets
<!-- AC:END -->
