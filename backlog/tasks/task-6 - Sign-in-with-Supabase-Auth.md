---
id: TASK-6
title: Sign in with Supabase Auth
status: Done
assignee: []
created_date: '2026-11-23T17:42:00Z'
updated_date: '2026-11-24T09:46:00Z'
labels: []
dependencies:
  - TASK-5
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add supabase_flutter (production dependency: ask first) and a sign-in screen; RLS needs a signed-in user.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Users can sign up, sign in and sign out; the session survives an app restart
- [x] #2 Widget tests cover sign-in and sign-out
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Email sign-in with a 6-digit code or the link in the same email (user decision); sign-up happens on first sign-in. Auth interface (lib/auth/auth.dart) with SupabaseAuth; AuthGate switches between sign-in and the start screen; sign out from the ⋮ menu with confirmation. Session persistence is supabase_flutter's (verified end to end against the local Supabase: sign-up, code, reload, link on web, sign-out). Hosted setup steps in docs/architecture.md (web deploys). App links on phones: TASK-20.
<!-- SECTION:NOTES:END -->
