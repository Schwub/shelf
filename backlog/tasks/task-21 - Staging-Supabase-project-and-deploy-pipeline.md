---
id: TASK-21
title: Staging Supabase project and deploy pipeline
status: Done
assignee: []
created_date: '2026-11-24T10:50:00Z'
updated_date: '2026-11-25T00:03:00Z'
labels: []
dependencies: []
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A hosted Supabase project for staging. A staging workflow applies migrations (supabase db push) and auth settings (supabase config push, [remotes] block in config.toml) after the db tests pass on main.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The staging project exists and the workflow deploys migrations and auth settings to it after db tests pass on main
- [x] #2 docs/architecture.md describes the environments and the one-time setup
- [x] #3 Sign-in works against staging by the email's link (the code needs an SMTP sender; Supabase's free sender refuses custom templates)
<!-- AC:END -->
