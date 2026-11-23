# Blueprint feedback

Notes for the blueprint this project started from, collected later.
One entry per finding: date, what happened, which rule or skill, suggestion.
Only what would help other projects; project-specific fixes go in AGENTS.md.

- 2026-11-22 – project-setup, step 2 (Tools): `flutter`/`dart` were shell
  aliases to fvm (a different global version) and mise wasn't activated, so
  plain `flutter` ran the wrong version. Suggestion: check `type <tool>` as
  well as `--version`, and write commands in AGENTS.md as `mise run` /
  `mise exec --` when mise isn't activated.
- 2026-11-22 – kickoff, step 4: "First steps" in docs/project.md listed
  "run the project-setup skill", which the skill already names as the next
  step; project-management then moves the list into the tracker anyway.
  Suggestion: tell kickoff to list only project work in First steps.
- 2026-11-22 – project-setup, step 7, and AGENTS.template.md: the template's
  placeholders (Install, Run all tests, Lint) led to lines that only repeated
  `mise.toml` tasks and generated files; four were cut on review.
  Suggestion: drop Install and Run all tests from the template when checks
  are mise tasks, and have the skill apply the guide's test ("would an agent
  get this wrong without it?") to each line before showing AGENTS.md.
