---
name: deliver
description: Take the next piece of work from proposal to done - propose the next step, agree it with the user, then design, build, verify and review it, running only the steps the work needs. Use when the user asks what's next or invokes deliver.
---

# Deliver

Goal: the right next piece of work, done properly, with the user deciding
at the points that matter. Scale the process to the work: a label fix
doesn't need a design review; a new subsystem does.

## 1. Propose the next step
- Read the open tasks (the tracker named in AGENTS.md) or, without one, the
  "First steps" and milestones in `docs/project.md`. Also read
  `docs/features/` for work already in progress.
- Read `docs/tech-debt.md`. A review is due when its interval has passed
  since the last review (default: 4 weeks or 30 commits; without the file,
  counted from the first commit). Open debt items are candidates too.
- If the user named the work, use that. Otherwise propose the next step,
  or two or three options, with a reason for each. When a review is due,
  include running the tech-debt skill as one option and say why.
- **Stop:** the user picks.

## 2. Frame it
- Restate the goal and write acceptance criteria that can be checked.
- Pick the depth and say which steps you will run and why:
  - **Small** (a fix, a small change): understand → implement with a test → verify.
  - **Standard** (a feature, a new screen): + research, design, review.
  - **Large** (a new subsystem, payments, sync): + UX design, an
    architecture decision, a feature note, splitting into tasks.
- Discuss the details and open questions with the user.
- **Stop:** the user confirms goal, criteria and depth.

## 3. Research (Standard and Large)
- Read the code, tests and docs the work touches, and the docs of any
  library involved, especially APIs newer than your training.
- List risks, unknowns and the options you see.
- If the work brings a new library or platform, run the find-skills skill.

## 4. Design (Standard and Large)
- New screens or flows: run the ux-design skill.
- Run the software-design skill: it compares approaches, lets the user
  choose and writes the design, including decisions for
  `docs/architecture.md`.
- Large work gets a feature note in `docs/features/<name>.md` with the
  criteria, design and plan, so a fresh session can continue it; split it
  into tasks if the project tracks tasks.
- **Stop:** no code until the user agrees with the design. When
  software-design already got that agreement, don't ask again.

## 5. Implement
- Small steps, each leaving the code working. Write the test first where
  practical, otherwise alongside.
- Follow the design; if it turns out wrong, stop and discuss rather than
  drift.
- Building UI: apply the frontend-design skill if installed.

## 6. Verify
- Run `mise run check`. Run the app or the affected part where possible and
  check every acceptance criterion yourself.
- UI changes, in addition:
  - Compare the built screens with the wireframes in `docs/design/`,
    screen by screen and state by state (empty, loading, error, filled).
  - Take screenshots at the target sizes (phone, tablet if supported, dark
    mode if the app has it) and look at them; fix what looks wrong.
  - Run the stack's automated accessibility checks where it has them
    (e.g. Flutter's tap target, label and text contrast guidelines in
    widget tests); otherwise check those three by hand.
  - Keep the screenshots for the review and show them to the user.

## 7. Review (Standard and Large)
- Review in a fresh context that didn't write the code: a read-only
  subagent where the harness has one, otherwise a new session given the
  feature note or criteria and the diff.
- Check against the acceptance criteria, the design, AGENTS.md and the
  working agreements, and for maintainability: duplication, code in the
  wrong place, missing tests, anything that makes the next change harder.
  Fix what's found, then verify again.
- Debt that is accepted for now goes into `docs/tech-debt.md`, not into
  silence.

## 8. Finish
- Update the docs the work changed (`docs/design/`, `docs/architecture.md`,
  the feature note) and close the task.
- Commit according to the Git rules in AGENTS.md.
- Deploy only if AGENTS.md documents a deploy command, and only after the
  user says so. Without one, say how the work can be tried instead.
- If anything in this skill was wrong, missing or slowed you down, add a
  note to `docs/blueprint-feedback.md`.
