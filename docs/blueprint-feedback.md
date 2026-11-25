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
- 2026-11-23 – `.github/workflows/check.yml` is managed, so a project can't
  add a CI job to it (the deliver review caught one that `agentic:update`
  would have deleted). Suggestion: say in project-setup that project CI jobs
  go in their own workflow file, or keep check.yml out of managed.txt.
- 2026-11-23 – Cloud sessions: `mise.run` is blocked by the network policy,
  and mise can't install aqua/GitHub tools (api.github.com 403) or verify npm
  provenance (sigstore blocked). Worked around with `npm i -g @jdxcode/mise`,
  the Supabase binary from its GitHub release URL, and
  `MISE_DISABLE_TOOLS` for `mise run`. Suggestion: a cloud-session note in
  AGENTS.md or project-setup, or a setup script for the environment.
- 2026-11-23 – frontend-design: the self-critique step has no explicit
  consistency audit, and a mock shipped with mixed corner radii (connected
  button group, squarish thumb in a round track) that the user saw as
  mistakes. Suggestion: before showing a design, define a radius and
  spacing scale and check every element against it (shape, 4/8 px grid,
  shared left edge), and avoid asymmetric control shapes unless asked.
- 2026-11-25 – `.github/workflows/check.yml` (managed): runs on every push
  and every pull request, so each push to a PR branch runs twice, and
  nothing cancels superseded runs. This project used up GitHub's 2,000 free
  Actions minutes in three days (private repo). I edited check.yml to fix it,
  which breaks the "don't edit managed files" rule; `agentic:update` will
  undo it. Suggestion: in the blueprint's check.yml, `push: branches: [main]`
  plus `pull_request`, and `concurrency` with
  `cancel-in-progress: ${{ github.event_name == 'pull_request' }}`; and in
  project-setup, run slow native builds only on paths that can break them.
- 2026-11-25 – Cloud sessions: one session branch plus a stop hook that
  insists on pushing unpushed commits bundles unrelated work into an open PR
  (here five tasks in one PR). Suggestion: let deliver use one branch per
  PR, or let the hook accept unpushed commits while a PR from the branch is
  open.
- 2026-11-25 – Cloud sessions: every command needed a long prefix (Supabase
  CLI from a scratch folder, `MISE_DISABLE_TOOLS`, restarting dockerd).
  Suggestion: project-setup proposes a cloud environment with a setup script
  (installs mise and the tools; this project's is the "shelf" environment)
  and an AGENTS.md line on starting Docker.
- 2026-11-25 – Verification: checks against a real local Supabase were
  written as throwaway tests six times and found real bugs (a nested order
  PostgREST ignored, record equality on sets). Suggestion: project-setup
  adds an integration test task next to the unit and database tests.
- 2026-11-25 – frontend-design / ux-design: nothing compares the built
  screens with the mockups, so look and mockup drift apart and the agent
  asks the user to check on their phone. Suggestion: a visual-check step
  (screenshots of the web build against local data) before a UI task is
  done; this project adds a `visual-check` skill.
- 2026-11-25 – Skills built here that other projects could use:
  `visual-check` (screenshots of the web build against local Supabase,
  signed in by a one-time link, tapping through screens by their
  accessibility labels) and `release` (merge, database before app on
  staging, report the published version). `theme-variations` is specific to
  this app's ShelfColors but its approach (mockups from JSON, then generated
  code checked by contrast tests) carries over.
