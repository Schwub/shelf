---
id: TASK-36
title: Invites and friends (M2)
status: In Progress
assignee: []
created_date: '2026-11-26T10:05:00Z'
updated_date: '2026-11-26T10:35:00Z'
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
- [ ] #1 pgTAP covers every invite status, both friendship rows created and removed together, and profile access for friends and strangers
- [ ] #2 Invite, accept by code and by web link, cancel and remove work end to end (integration test)
- [ ] #3 Widget tests cover every Friends, Invite, Enter code and Invitation state in screens.md
<!-- AC:END -->
