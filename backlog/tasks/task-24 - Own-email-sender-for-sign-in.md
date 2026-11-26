---
id: TASK-24
title: Own email sender for sign-in
status: To Do
assignee: []
created_date: '2026-11-25T00:03:00Z'
updated_date: '2026-11-26T15:21:00Z'
labels: []
dependencies: []
priority: high
ordinal: 25000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Supabase's free built-in sender only reaches members of the Supabase organization, a few emails an hour, and refuses custom templates, so staging emails have no code. Add an SMTP sender (Gmail app password for staging, a domain with Resend before production) and push our template again.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Sign-in emails on staging carry the code and the link
- [ ] #2 Emails reach testers outside the Supabase organization
<!-- AC:END -->
