---
id: TASK-11
title: Add error reporting
status: To Do
assignee: []
created_date: '2026-11-23T17:42:00Z'
labels: []
dependencies: []
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Capture crashes and errors from the app on web, iOS and Android. Compare Sentry (free tier, sentry_flutter), self-hosted GlitchTip and others on cost, Flutter support, source maps/symbols and GDPR (data location, no personal data in events).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Options compared and a decision recorded in docs/architecture.md
- [ ] #2 Unhandled errors from web, iOS and Android show up with release and readable stack traces
- [ ] #3 Events contain no personal data beyond an anonymous user ID
<!-- AC:END -->
