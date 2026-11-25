---
id: TASK-11
title: Add error reporting
status: In Progress
assignee: []
created_date: '2026-11-23T17:42:00Z'
updated_date: '2026-11-25T21:42:00Z'
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
- [x] #1 Options compared and a decision recorded in docs/architecture.md
- [ ] #2 Unhandled errors from web, iOS and Android show up with release and readable stack traces
- [x] #3 Events contain no personal data beyond an anonymous user ID
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-11-25: Sentry integrated (app/lib/errors.dart), off until the SENTRY_DSN repository variable is set. Open for AC2: readable web stack traces need source maps uploaded from the web workflow (Sentry auth token); check Android and iOS traces once events arrive.

2026-11-25: Sentry project shelf (org schwubware-03, EU region) created; SENTRY_DSN repository variable set; a test error from a local web build arrived (minified trace). Project setting "Prevent Storing of IP Addresses" on: Sentry added the sender's IP despite sendDefaultPii off. Fixed the web zone mismatch (bindings now start in Sentry's zone). Web source maps upload from the web workflow once the SENTRY_AUTH_TOKEN secret exists; still to check on a deploy, plus Android and iOS traces.
<!-- SECTION:NOTES:END -->
