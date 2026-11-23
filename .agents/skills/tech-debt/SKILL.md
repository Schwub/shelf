---
name: tech-debt
description: Review the codebase for technical debt and drift from docs/architecture.md, record it in docs/tech-debt.md, and carry out the cleanups the user approves. Use when the user asks or deliver suggests a review.
---

# Tech debt

Goal: keep the codebase easy to change. Find what makes it harder, decide
with the user what to pay off now, and keep a record so nothing is lost.

## 1. Read the intent and the record
- `docs/architecture.md` (main parts, decisions, what must stay simple),
  `docs/project.md`, AGENTS.md.
- `docs/tech-debt.md` if it exists: the last review, the interval and the
  open items. Re-check open items rather than copying them forward.

## 2. Gather facts
Use tools first, judgement second:
- Analyzer and lint warnings, and whether `mise run check` passes cleanly.
- Outdated dependencies (the stack's command, e.g. `flutter pub outdated`)
  and unused ones.
- Unused code, TODO and FIXME comments.
- Hotspots: the largest files and the most often changed ones
  (`git log --format= --name-only | sort | uniq -c | sort -rn | head`).
- Test gaps: coverage if the stack reports it, otherwise important
  behaviour without tests.
- Drift: code that bypasses the intended structure, parts doing more than
  one job, duplication, coupling between parts that should be independent.
- Stale docs: AGENTS.md commands that no longer work, `docs/design/` or
  `docs/architecture.md` that no longer match the code.

## 3. Record
Write `docs/tech-debt.md`:
- **Last review:** date and commit. **Interval:** keep the existing one,
  default "every 4 weeks or 30 commits".
- **Items:** one row each with what, where, why it hurts, effort (S/M/L),
  risk, and a suggested action, ranked by value for effort. Remove items
  that are resolved.

## 4. Propose and decide
- **Quick cleanups:** safe and mechanical, no behaviour change (lint fixes,
  unused code, patch-level dependency updates, stale docs).
- **Refactorings and larger updates:** each one becomes a task or a note in
  `docs/tech-debt.md` for the deliver skill to pick up.
- Major dependency updates and anything that changes behaviour or the
  architecture are the user's decision.
- **Stop:** the user picks what to do now.

## 5. Clean up
- Do the approved quick cleanups in small commits, each with
  `mise run check` passing, following the Git rules in AGENTS.md.
- Update `docs/tech-debt.md`: what was done, what remains.
- If anything in this skill was wrong, missing or slowed you down, add a
  note to `docs/blueprint-feedback.md`.
