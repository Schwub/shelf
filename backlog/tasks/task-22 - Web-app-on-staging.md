---
id: TASK-22
title: Web app on staging
status: To Do
assignee: []
created_date: '2026-11-24T10:50:00Z'
updated_date: '2026-11-24T10:50:00Z'
labels: []
dependencies:
  - TASK-10
  - TASK-21
ordinal: 23000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Cloudflare Pages deploys from main (and PR previews) built against the staging Supabase, so the latest app is one URL away.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 main deploys the web app built against staging Supabase
- [ ] #2 Signing in on the staging web app works, by code and by link
<!-- AC:END -->
