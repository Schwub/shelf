# Roadmap

Goal: a personal project blueprint. Clone it to start a new project with the
agentic layer included; adapt it once the tech stack is known.
Main purpose: learning. Decisions and lessons go in LEARNINGS.md.

## Topics

- [x] 0. Kickoff: repo purpose, name, structure, README, LEARNINGS.md
- [x] 1. Context & instructions: AGENTS.md template, global vs project,
        what belongs in it, how it grows
- [ ] 2. Harness & safety: harness-agnostic, Claude Code first, pi next (pi
        needs an API key or another provider: subscription login isn't allowed
        in third-party tools); shared layer in AGENTS.md and `.agents/`, a thin
        adapter per harness; `.agents/guard.sh` and hooks enforcing the working
        agreements in AGENTS.md (pi adapter: `.pi/extensions/`, when pi is used), sandboxing,
        secrets, models & cost, integrations (MCP vs CLI); Docker Sandboxes
        (sbx, clone mode) as the default for real tasks, a kit carrying the
        personal layer into the sandbox; `mise run agent` as the launcher
- [ ] 3. Workflow loop: explore → plan → implement → verify → review;
        skills, prompts, subagents; git & PR flow; codebase health:
        review pass per change, architecture-review skill (proposes
        refactorings; manual or scheduled → Topic 5), intended architecture in docs/architecture.md,
        linters and dead-code checks in pre-commit/CI; first skills
        (done, refine in the pilot): kickoff (interview → docs/project.md,
        docs/architecture.md for products) and project-setup (app, check:*
        tasks, AGENTS.md from the template and guide bundled in the skill);
        instruction evals: headless agents (claude -p)
        on a throwaway test repo, one scenario per rule, checked by script,
        several runs each (check `claude plugin eval` before building our own);
        uniform project commands via mise tasks (`mise run test`, `mise run check`);
        CI (`mise run check` on every push) as the main quality gate (done)
- [ ] 4. Tasks & knowledge: tasks decided per project (project-management skill, research/04-tasks.md);
        still open: Obsidian vs alternatives for knowledge,
        agent memory across sessions; refactoring proposals become tasks
- [ ] 5. Terminal tools: parallel agents, worktrees, multiplexers,
        review tools, apps (e.g. hello-halo), unattended/scheduled agents
- [ ] 6. Blueprint lifecycle: `mise run init` (done: repo from the GitHub
        template, then init swaps in template AGENTS.md, README, feedback file,
        removes .blueprint/; tested in CI), how improvements flow back (blueprint as git
        remote vs copier); feedback from projects: harvest skill (done; run it
        on a weekly schedule once projects produce notes); optional `mise run feedback` in a project, run by me on the
        host, that opens one blueprint issue from the notes file (no token in
        a sandbox); publishing to GitHub; GitHub ruleset on main
        (PR only, CI required, no force-push/deletion) applied via `gh`;
        fine-grained token for sandboxes (contents + PRs, no Workflows/Admin); `mise bootstrap` for the host
        machine (packages, ~/.claude link), dry-run first, tested in a
        disposable sbx sandbox
- [ ] 7. Pilot project: create a repo from the template, create a Flutter app, feed lessons back;
        note every line of the working agreements in AGENTS.md an agent misreads or ignores;
        Flutter app: verify Flutter on Linux arm64 in sbx (analyze, unit and
        widget tests, codegen); iOS/Android builds and device tests on the host;
        hands-on sbx checks: login persistence, .env visibility, kit loading

## Open questions (review 2026-11-21)

- Pilot earlier? `init`, kickoff and project-setup exist; start the pilot
  before designing Topics 3–6 without a real project.
- Verify hands-on that sbx only sees project-level config and that
  `sbx run --clone claude .` works; the restructure depends on it. If a kit
  can carry personal config, do the working agreements belong in the project?
- Push policy: working agreements say never push from a sandbox; Topic 6
  plans a token with contents + PR rights.
- Environments: how does an agent know it is in a clone-mode sandbox? What
  applies in cloud sessions, whose harness says commit and push?
- How do working-agreement changes reach existing projects (copies go stale)?
- Repo is named `agentic`, README says `agentic-blueprint`.
- Updates: a clone is a snapshot. Decide before the second project how
  changes reach existing projects (copier update vs blueprint as git remote);
  moved up from Topic 6.
- Two products? Topics 4–5 and `mise bootstrap` configure my machine, not a
  project. Mark per topic what lands in the blueprint and what in a host setup.
- sbx is one vendor's sandbox and pi support is unknown; compare with a plain
  container before building more on it.
- Does Claude Code read `.agents/skills/` natively, or does it need a symlink?

## Ongoing

- Record every decision and its reason in LEARNINGS.md
- Stay current: revisit topics when tools or practices change
- At each model upgrade: rerun the instruction evals with and without
  individual lines of the working agreements in AGENTS.md; drop lines that no longer help

## Ideas for later

- Personas / specialist agents with their own tooling, e.g. a designer
  agent that always starts with wireframes and uses paper.design.
  To discuss and challenge (fits near Topic 3: skills, subagents).
