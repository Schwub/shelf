---
id: TASK-25
title: Keep user settings in the database, across devices
status: To Do
assignee: []
created_date: '2026-11-25T08:02:00Z'
labels: []
dependencies: []
ordinal: 26000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
All user configuration lives in Supabase so it follows the user to every device (user decision 2026-11-25). Today the shelf's covers/spines choice is kept on the device with shared_preferences (app/lib/shelf/shelf_page.dart); move it, and any later settings, to a user_settings table (one row per user, owner-only row-level security). Schema change: confirm the design first.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A user_settings table with owner-only access and pgTAP tests
- [ ] #2 The covers/spines choice is stored there and restored on any device, also when signed in on a new one
- [ ] #3 The app works offline with the last known settings and shared_preferences only caches them
<!-- AC:END -->
