---
id: TASK-13
title: Agents that handle reported errors
status: To Do
assignee: []
created_date: '2026-11-23T17:42:00Z'
labels: []
dependencies:
  - TASK-11
ordinal: 12000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Turn logged errors (error reporting) and user bug reports into GitHub issues, and let an agent triage them and propose fixes as PRs (e.g. Claude Code GitHub Action or a scheduled cloud session). Decide guardrails: what it may do alone, what needs review.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Design with options and guardrails agreed with the user and recorded in docs/architecture.md
- [ ] #2 A new error or user report creates a deduplicated GitHub issue
- [ ] #3 An agent triages new issues and opens a PR for at least one fixable case
<!-- AC:END -->
