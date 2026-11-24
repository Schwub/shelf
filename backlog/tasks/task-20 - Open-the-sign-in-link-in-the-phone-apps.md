---
id: TASK-20
title: Open the sign-in link in the phone apps
status: To Do
assignee: []
created_date: '2026-11-24T09:46:00Z'
labels: []
dependencies: []
ordinal: 21000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The sign-in email's link works on the web; on Android and iOS it should open the app and sign in (app links / universal links or a custom scheme, plus the redirect URL in Supabase). Until then phones sign in with the code.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Tapping the link in the sign-in email on Android opens the app signed in
- [ ] #2 Same on iOS
- [ ] #3 An expired link shows the 'link expired' note on the sign-in screen
<!-- AC:END -->
