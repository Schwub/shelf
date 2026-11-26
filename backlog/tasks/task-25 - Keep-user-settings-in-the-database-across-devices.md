---
id: TASK-25
title: Keep user settings in the database, across devices
status: Done
assignee: []
created_date: '2026-11-25T08:02:00Z'
updated_date: '2026-11-26T08:18:00Z'
labels: []
dependencies: []
ordinal: 26000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
All user configuration lives in Supabase so it follows the user to every device (user decision 2026-11-25). Today two settings are kept on the device with shared_preferences: the shelf's covers/list choice (app/lib/shelf/shelf_page.dart) and the theme (app/lib/theme/theme_choice.dart); move them, and any later settings, to a user_settings table (one row per user, owner-only row-level security). Schema change: confirm the design first.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A user_settings table with owner-only access and pgTAP tests
- [x] #2 The app works offline with the last known settings and shared_preferences only caches them
- [x] #3 The covers/list choice and the theme are stored there and restored on any device, also when signed in on a new one
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
user_settings table (theme, shelf_view; owner-only, column grants) and app/lib/settings/ (Settings replaces ThemeChoice; SettingsRepository + Supabase). The device copy shows before sign-in and offline; My shelf syncs the saved row, skipping what the user changed meanwhile; each save sends only the changed column, one at a time. Tests: settings unit tests incl. both races, widget tests (theme and covers/list follow the user), pgTAP, integration. Not run in a browser or on a phone.
<!-- SECTION:NOTES:END -->
