---
name: ux-design
description: Plan screens before building them - user flows with error and empty states, a screen list with navigation, and grayscale wireframes in docs/design/ for the user to review. Use when deliver calls it or the user asks.
---

# UX design

Goal: decide what the user can do, on which screens, and how they move
between them, while changes still cost minutes. Structure only: how it looks
is decided while building (e.g. with the frontend-design skill).

## 1. Read what is decided
- Read `docs/project.md` (users, core use cases, interface, platforms) and,
  if present, `docs/architecture.md` and `docs/design/`.
- For one feature, design only that feature, in the existing documents.
- Ask only what the docs leave open, such as which use case matters most.

## 2. User flows
In `docs/design/flows.md`, one Mermaid flowchart per core use case:
- Every step and decision, from entry point to done.
- The unhappy paths: errors, empty states, loading, no network,
  missing permissions, cancelling halfway. Most gaps hide here.
- One line per flow on what "done" means for the user.

## 3. Screens and navigation
In `docs/design/screens.md`:
- A table of screens: name, purpose, which flows use it, its states
  (empty, loading, error, filled).
- A Mermaid diagram of the navigation between screens.
- Follow the platform's conventions (e.g. Material or Cupertino on mobile,
  back behaviour, tabs vs drawer) unless the docs decide otherwise.

## 4. Wireframes
In `docs/design/wireframes/`, one self-contained HTML file per flow or
screen group:
- Grayscale boxes and system fonts only, sized to the target device (e.g.
  a phone frame). Inline CSS, no external files, no scripts beyond simple
  links between screens.
- Real labels and plausible content, never lorem ipsum: wording is part of
  the structure.
- One clear primary action per screen; show the important states next to
  the filled one.
- Touch targets of at least 48 px, every input labelled.
- Small projects: wireframe only screens whose layout isn't obvious.

## 5. Verify before showing it
- Coverage: every step of every flow has a screen, and every screen shows
  its empty, loading and error states where they can occur.
- Usability: check each screen against the common heuristics - visible
  status and feedback, familiar words, undo and cancel, consistency, error
  prevention and clear error messages, recognition over recall.
- Platform and accessibility: the platform's conventions, touch targets,
  labelled inputs, a sensible reading and focus order.
- Look at what you made: where a browser is available, open the wireframes
  at the target device size and take screenshots; fix what looks wrong.
  Don't judge HTML you haven't rendered.

## 6. Review
- Show the screenshots, then walk the user through the flows and
  wireframes, flow by flow. Ask what is missing or wrong, then update the
  documents.
- Record decisions that change scope or structure in the decisions of
  `docs/architecture.md`, or in `docs/project.md` if there is none.
- No feature code until the user agrees with the design.

## 7. Finish
- If the project tracks tasks, add one task per screen or flow.
- When building, keep `docs/design/` in step with what is built.
- If anything in this skill was wrong, missing or slowed you down, add a
  note to `docs/blueprint-feedback.md`.
