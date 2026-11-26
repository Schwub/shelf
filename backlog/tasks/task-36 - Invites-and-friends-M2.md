---
id: TASK-36
title: Invites and friends (M2)
status: Done
assignee: []
created_date: '2026-11-26T10:05:00Z'
updated_date: '2026-11-26T10:53:00Z'
labels: []
dependencies:
  - TASK-35
ordinal: 37000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
docs/features/friends.md, criteria 2-4 and 9 (profiles part). friendships and invites tables, is_friend, create_invite, invite_preview, accept_invite, remove_friend; friends read each other's profiles. Screens: Friends (list, invites waiting, remove), Invite sheet (share and copy; share_plus needs the user's OK as a new dependency), Enter code, Invitation; /invite/<code> on the web via a PendingInvite. Wireframes: docs/design/wireframes/friends.html.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 pgTAP covers every invite status, both friendship rows created and removed together, and profile access for friends and strangers
- [x] #2 Invite, accept by code and by web link, cancel and remove work end to end (integration test)
- [x] #3 Widget tests cover every Friends, Invite, Enter code and Invitation state in screens.md
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
friendships/invites + create_invite, invite_preview, accept_invite, remove_friend; friends read names. Friends tab, invite sheet (share_plus, copy), Enter code, Invitation, PendingInvite for /invite/<code> (kept across the email-link redirect, URL reset after use). Review fixes: used = accepted_at (survives the accepter's account deletion), codes from gen_random_bytes, on conflict for parallel accepts, mounted checks. Deviations in flows.md/screens.md: no inviter name on sign-in, cancelled reads as unknown, no Undo on cancel, album counts with TASK-37. Android APK not built locally (no SDK here); the android workflow builds it on the PR.
<!-- SECTION:NOTES:END -->
