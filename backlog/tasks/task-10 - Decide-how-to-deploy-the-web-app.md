---
id: TASK-10
title: Decide how to deploy the web app
status: In Progress
assignee: []
created_date: '2026-11-23T17:42:00Z'
updated_date: '2026-11-23T18:00:00Z'
labels: []
dependencies: []
ordinal: 5500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A deployed web build gives faster debug and test cycles than phone builds. Compare hosts (e.g. Cloudflare Pages, Netlify, GitHub Pages, Vercel) on free tier, preview deploys per branch/PR, and Supabase auth redirects. Note what web can't do (no share target). Deploying is the user's call.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Options compared and a decision recorded in docs/architecture.md
- [x] #2 Deploy and preview commands documented in AGENTS.md
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Cloudflare Pages via the web workflow; waiting for the user to create the Pages project and the two repository secrets, then verify a PR preview and the production deploy.
<!-- SECTION:NOTES:END -->
