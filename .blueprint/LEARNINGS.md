# Learnings

Decision log. One entry per decision: what we chose, why, what else
we considered, and what we learned. Newest at the bottom.

## 2026-11-03 · Topic 0 · Two layers: personal vs project
**Decision:** Keep personal setup and project templates clearly apart.
**Why:** Personal config (how I work, everywhere) lives in my home folder;
project config (how this project works, for anyone) lives in each repo.
They are installed differently and change for different reasons.
**Superseded:** by "From dotfiles to a project blueprint" (Topic 2).
**Learned:** Mixing them is a common mistake: personal preferences leak
into shared repos, project rules end up global.

## 2026-11-03 · Topic 0 · Start with a plain ROADMAP.md, not a task tool
**Decision:** Track our topics in a plain markdown checklist.
**Why:** Choosing a task tool depends on Topics 1–3. Plain markdown
works with Backlog.md and Obsidian alike and locks nothing in.
**Alternatives:** Backlog.md now, Obsidian vault now (both premature).
**Learned:** Tasks (per project, structured) and knowledge (personal,
linked) are different problems and may need different tools.

## 2026-11-03 · Topic 0 · Grow the structure, don't plan it upfront
**Decision:** No empty folders. Each topic adds what it actually needs.
**Why:** Structure designed before use is usually wrong; structure that
grows from real needs stays small and understandable.

## 2026-11-03 · Topic 0 · Roadmap gaps added
**Decision:** Added verification, security & sandboxing, integrations
(MCP vs CLI) and packaging & reuse to the roadmap.
**Why:** Verification is the most important practice for agents (give
them a way to check their own work). The rest are needed for a workflow
that is safe and reusable in any project.

## 2026-11-03 · Topic 1 · One AGENTS.md per project, no CLAUDE.md
**Decision:** Projects get only an AGENTS.md.
**Why:** Claude Code reads AGENTS.md natively since v2.1.277 (Sept 2026),
like Codex, pi and OpenCode. One file, every agent.
**Watch out:** A CLAUDE.md or CLAUDE.local.md in the project makes Claude
Code ignore AGENTS.md (setting `claude-md-and-agents-md` loads both).
**Learned:** Check primary docs; most guides online were already outdated.

## 2026-11-03 · Topic 1 · Judge templates by content, not by name
**Decision:** Used the viral "Boris Cherny CLAUDE.md" as input, kept ~6 of ~35 rules.
**Why:** It's a fan compilation (Feb 2026), not his file; the Karpathy
guidelines weren't written by Karpathy either. Both had one or two good
ideas (concrete verification, surgical changes) among outdated advice.
**Learned:** Viral templates borrow authority. Check provenance and evidence.

## 2026-11-03 · Topic 1 · Only write what the agent can't discover
**Decision:** Short files; project template is facts-first (commands,
done means, gotchas, boundaries), no overviews or generic advice.
**Why:** Agents follow these files closely (tools named get used ~1.6x vs ~0),
but generic content barely moves success and adds ~20% cost (ETH study,
ICLR 2026). Non-discoverable facts are what helps (Vercel: 53% → 100%).
**Learned:** Length matters less than relevance: no study found a length cliff.

## 2026-11-03 · Topic 1 · Hard rules need enforcement, not prose
**Decision:** Rules that must never break get a hook or CI check (→ Topic 2).
**Why:** Prose rules work "most of the time, not every time" (Anthropic).
Git hooks and CI are the only enforcement every agent respects.

## 2026-11-03 · Topic 1 · Personal file built from my own frustrations
**Decision:** ~40 lines: communication, when to ask, scope, verification, git.
**Why:** Each new rule comes from a real frustration (changes I didn't ask
for, ignoring patterns, asking too little, long-windedness).
**Learned:** "Ask based on reversibility" alone wasn't enough. Creating files
is reversible, but I still want to agree on the approach for bigger work first.

## 2026-11-03 · Topic 1 · Instruction files are maintained, not finished
**Decision:** Add a rule on the second occurrence of a mistake, review it
like code, prune at each new model generation.
**Why:** Files tend to only grow. Instructions compensate for one model's
weaknesses and go stale with the next.

## 2026-11-03 · Topic 1 · Codebase health in four layers
**Decision:** Notice (agents list findings, never fix unasked) → review each
change → periodic architecture-review skill that proposes refactorings →
linters and dead-code checks in CI. Old code paths get deleted on refactor.
**Why:** "Is the architecture still good?" is too expensive for every task
and would cause scope creep. Each layer does what it's good at.
**Learned:** An agent can only judge architecture against a stated intent,
so projects need a short docs/architecture.md (→ Topic 3).

## 2026-11-03 · Topic 1 · Personal and project files stay separate
**Decision:** A project-setup skill (built in Topic 3) creates the project
AGENTS.md from the template; it never copies personal rules into it.
Personal rules reach Claude via a symlink ~/.claude/CLAUDE.md → personal/AGENTS.md.
**Superseded:** the symlink and the separation, by "From dotfiles to a project
blueprint" (Topic 2). The skill still never copies personal rules into AGENTS.md.
**Why:** Copies get loaded twice, go stale, and leak my preferences into
shared repos. Claude Code has no global AGENTS.md location, only ~/.claude/CLAUDE.md.
**Learned:** Native AGENTS.md support in Claude Code is project-level only.

## 2026-11-03 · Topic 1 · Independent reviews of the personal file
**Decision:** Four independent reviews (one, then three with different lenses:
red-team simulation, vendor docs & portability, minimalist editor). Stopped
after the second round; further improvement comes from real use.
**Why:** Round 1 found serious gaps I had missed (destroying uncommitted work,
test-gaming, contradicting end-of-turn rules). Round 2 found mostly edge cases
(headless runs, unread setup scripts, formatters overwriting my work).
**Learned:** Give reviewers different lenses and require a deletion for every
addition, or each round makes the file longer. When a reviewer's vendor claim
("models already follow patterns") contradicts my own experience, my
experience wins. Disabled the Karpathy plugin: it duplicated and partly
contradicted the file.

## 2026-11-03 · Topic 1 · Instruction files are specs, not prose
**Decision:** Kept the dense, imperative version over a "natural" rewrite.
**Why:** Short imperative bullets are faster to scan for humans and agents,
use fewer words, and stay checkable ("1–2 lines" vs "a short wrap-up").
**Learned:** Instruction files read best like a spec. If a single line feels
awkward, fix that line instead of rewriting the whole style.

## 2026-11-03 · Topic 2 · Claude Code as the only harness
**Decision:** Claude Code only; pi dropped for now.
**Why:** Claude subscriptions may only be used in Claude Code and Anthropic's
own apps (terms, enforced since April 2026). pi would need pay-per-use API
keys, and plugins that reuse the subscription risk the whole account.
**Superseded:** by "Harness-agnostic" (2026-11-21); the billing point stands.
**Learned:** Harness choice is also a billing and terms question, not only a
features question. Keeping files in open formats (AGENTS.md, skills, git
hooks) keeps the door open to other harnesses later.

## 2026-11-03 · Topic 2 · From dotfiles to a project blueprint
**Decision:** The repo becomes `agentic-blueprint`: cloned to start each new
project, agentic layer included. Working agreements move into the project
(`.claude/rules/working-agreements.md`); learning material moves to
`.blueprint/`, removed when a project starts. This reverses "personal and
project files stay separate".
**Why:** The goal changed from "my toolbox on every machine" to "every new
project starts complete". Docker Sandboxes only see project-level config, so
a self-contained project is the real test that all state lives in config.
**Learned:** Decisions depend on the goal; when the goal changes, revisit them
openly instead of working around them. Vision: only for me, agentic layer
only (no app scaffolding), new projects only, mostly solo.

## 2026-11-21 · Topic 2 · Setup review: deny rules are a net, not a wall
**Decision:** Fixed the clear defects (`.env.example` was git-ignored,
`settings.local.json` and `CLAUDE.local.md` were not; force-push with a remote
name and `git add -A`/`.` were not denied). Everything that needs argument
parsing (`git -C`, `bash -c`, `commit -n`, `+refspec`, stash) waits for a
PreToolUse hook. Structural questions went to the roadmap as open questions.
**Why:** Claude Code's docs call Bash patterns that constrain arguments
"fragile" and point to hooks and the sandbox. Read deny rules stop the Read
tool and `cat`, not `grep -r` or scripts.
**Learned:** Deny rules hold even in bypass-permissions mode, so they work in
the sandbox. Verify config claims against the docs: `Read(!.env.example)`
looked wrong and is valid. A review should also check the plan's order, not
only the files: the pilot was last although real use is what teaches most.

## 2026-11-21 · Topic 2 · Harness-agnostic: shared layer, thin adapters
**Decision:** The blueprint must work in most harnesses, first Claude Code and
pi. Shared: AGENTS.md (instructions), `.agents/` (guard, later skills), mise
tasks, git hooks and CI. Per harness only an adapter: `.claude/settings.json`
now, `.pi/extensions/` when I use pi. Reverses "Claude Code as the only harness".
**Why:** The setup should outlive one vendor. Only AGENTS.md is read by every
harness; pi reads `.agents/skills/` and has no permissions, deny rules or
sandbox, only extensions and containers.
**Learned:** Never add a CLAUDE.md: pi reads it too and Claude Code then skips
AGENTS.md. Skills must not depend on subagents or plan mode (pi has neither).

## 2026-11-21 · Topic 2 · Working agreements move into AGENTS.md
**Decision:** They are the last section of AGENTS.md, below the project
sections, changed only in the blueprint. `.claude/rules/` is gone. Reverses
"never copy personal rules into AGENTS.md".
**Why:** pi has no rules directory and no import syntax; a pointer line
("read file X first") is not reliable. One marked section can be replaced as
a block when the blueprint changes.
**Alternatives:** A neutral file linked into each harness (`.claude/rules/`,
`.pi/APPEND_SYSTEM.md`): keeps files apart, but needs wiring per harness and
doesn't reach harnesses that read only AGENTS.md.

## 2026-11-21 · Topic 2 · One guard script instead of deny patterns
**Decision:** `.agents/guard.sh` checks shell commands against the Git rules
(discarding changes, force-push, bypassing hooks, staging everything). Claude
Code calls it from a PreToolUse hook; the Bash deny patterns are removed.
Tests in `.agents/guard.test.sh`, run by `mise run check`. No git hooks yet:
there is no rule for them to enforce until projects define checks.
**Why:** The rules exist once and every harness can call them. Plain sh and
grep, so it needs no jq, Python or Node in a sandbox.
**Learned:** It matches text, so it is still a net: a commit message quoting
a blocked command is blocked too. My own test command was denied by the old
deny patterns because it contained the test cases; tests live in a file now.
It cannot enforce "never commit unless I ask": no script knows what I asked.

## 2026-11-21 · Topic 6 · Minimal init, built early
**Decision:** `mise run init` (`.blueprint/init.sh`) puts the template above
the working agreements in AGENTS.md, writes a README stub, removes
`.blueprint/` and its own task, and starts a fresh history whose first commit
names the blueprint commit it came from. It refuses to run with uncommitted
or unpushed work. Filling the placeholders stays manual until the
project-setup skill exists.
**Why:** The pilot needs it, and real use teaches more than more design.
Init applying the template settles "template vs init": the skill later
edits AGENTS.md in place and needs nothing from `.blueprint/`.
**Learned:** Recording the source commit costs one line and keeps every
update mechanism possible. A blueprint is workshop and product in one repo,
so the init script must protect the workshop: it deletes only what the
remote still has.

## 2026-11-21 · Topic 2 · Cloud sessions may commit and push their branch
**Decision:** New Git exception: in a cloud session, agents commit finished
work to the session's branch and push it without asking.
**Why:** The cloud harness asks for exactly that (its stop hook fired five
times in one session) and the container is temporary, so unpushed work is
lost. The branch is the review point; main stays protected by me.
**Learned:** Every environment an agent runs in (host, sandbox, cloud) needs
its own line in the Git rules, or the harness and my rules contradict.

## 2026-11-21 · Topic 6 · Feedback flows back as notes, not as edits
**Decision:** Agents note misleading or missing rules and reusable skills in
the project's `docs/blueprint-feedback.md`. I decide what moves to the
blueprint. No automatic issues or PRs against the blueprint.
**Why:** A project agent can't reach the blueprint, sees one case only, and
"always update" contradicts "add a rule on the second occurrence". A token
that lets every project sandbox write to the repo all future projects start
from is too much reach.

## 2026-11-21 · Topic 3 · CI runs `mise run check`, nothing else
**Decision:** One GitHub Actions workflow: checkout, install mise, `mise run
check`, on every push and pull request, read-only token. It ships into every
project; projects extend `check`, not the workflow.
**Why:** CI is the one gate every harness and every human passes. Keeping
the logic in the mise task means local and CI checks can't drift.
**Alternatives:** Per-stack workflows (belong to the project, not the blueprint).

## 2026-11-21 · Topic 6 · Projects start from a GitHub template
**Decision:** agentic is a GitHub template repository. `gh repo create
--template` creates the project with a fresh one-commit history; `init` then
only edits files and commits. It refuses to run unless the repo has exactly
one commit, which also keeps it out of the blueprint. Replaces the clone,
delete `.git`, re-init version.
**Why:** Starting without cloning the blueprint was the goal, and templates
are GitHub's built-in way. The script got shorter and no longer deletes
history.
**Lost:** The project no longer records which blueprint commit it came from
(a template copies content, not history). Add it back when updates need it.
**Caught by CI:** a shallow clone (as in GitHub Actions) also shows one
commit, so init checks for that too. The init test builds every case from
throwaway repos; it never runs init against the real checkout.
**Learned:** `mise` task `depends` accepts globs: `check` runs every
`check:*` task, so projects add checks without editing `check`, and init
strips the blueprint-only `check:init` with the rest of the blueprint section.

## 2026-11-21 · Topic 3 · Kickoff skill: interview first, one skill for all sizes
**Decision:** A `kickoff` skill interviews me and writes `docs/project.md`,
plus `docs/architecture.md` for products. It first settles whether the
project is small (one-off, prototype) or a product and asks accordingly.
It challenges vague answers and records "don't know" as open questions.
**Why:** The same blueprint serves small one-off projects and full products;
one skill with two depths beats two skills that drift apart. Anthropic's
advice for unclear work is interview → spec → implement in a fresh session.
Overviews don't belong in AGENTS.md, so the answers go to `docs/`.
**Learned:** Claude Code reads skills only from `.claude/skills/`; pi reads
`.agents/skills/`. Skills live in `.agents/skills/` with a per-skill symlink,
which Claude Code's docs explicitly support.

## 2026-11-21 · Topic 3 · Project-setup skill owns the AGENTS.md template and guide
**Decision:** A `project-setup` skill runs after kickoff: it creates the app
with the stack's generator, adds one `check:<name>` mise task per check,
fills in the AGENTS.md placeholders and runs every command it writes down.
The template and the guide moved into the skill's folder; `init` reads the
template from there. Small projects get the linter and tests; products add
formatting, type checks and a build.
**Why:** The instructions and the files they use stay in one place and
survive `init`, which removes `.blueprint/`. Tool installs outside the repo
still need my OK, so the skill proposes pinning tools in `mise.toml`, which
gives the sandbox and CI the same versions.
**Learned:** Both skills end by asking for a note in
`docs/blueprint-feedback.md`, so feedback doesn't depend on the agent
remembering one line in the working agreements.

## 2026-11-21 · Topic 6 · Harvest pulls feedback into the blueprint
**Decision:** A blueprint-only `harvest` skill finds my repos with
`docs/blueprint-feedback.md`, reads new entries and new skills, decides
adopt / watch / reject per finding, and opens one pull request on agentic.
It records what it read in `.blueprint/harvested.md` and never writes to
project repos. The feedback rule moved from "Engineering excellence" to
"Verification", so agents treat it as a finishing step.
**Why:** Reporting was built, collecting wasn't: notes would sit in each
project. Pulling centrally needs no token for agentic in any sandbox.
**Learned:** "Watch" encodes the second-occurrence rule across projects: one
project's complaint waits until a second project hits the same thing.

## 2026-11-22 · Topic 4 · Tasks live in the repo, with Backlog.md
**Superseded:** same day, by "Task tracking is decided per project".
**Decision:** Every project tracks tasks with Backlog.md: one Markdown file
per task in `backlog/`, a pinned version in `mise.toml` (1.55.3, with Node),
and a shipped `backlog/config.yml` with `auto_commit: false` and
`remote_operations: false`. Kickoff creates the first tasks; the AGENTS.md
template tells agents how to find, close and add tasks.
**Why:** Sandbox agents have no GitHub token, so tasks must be files. Any
harness can read them, with or without the CLI, and I still get a board.
**Alternatives:** Beads (a database with migrations; rewrites AGENTS.md and
installs hooks by default), GitHub Issues and Linear (need a token in the
sandbox; revisit when others join), a plain TODO file (no structure).
**Learned:** Pin a version that has been out for a while: four releases
came out the day I looked. Test the settings that touch git before adopting
a tool; the commit default was the deciding fact.

## 2026-11-22 · Topic 3 · Project-setup installs skills that fit the project
**Decision:** Kickoff records whether there is a user interface;
project-setup then proposes recommended skills from a table, starting with
Anthropic's `frontend-design` for UI projects, installed with the `skills`
CLI (pinned) after asking me.
**Why:** The blueprint stays stack-agnostic, and projects without a UI never
carry the skill. The `skills` CLI already uses our layout (`.agents/skills/`
plus a `.claude/skills/` link) and pins the source commit in `skills-lock.json`.

## 2026-11-22 · Topic 4 · Task tracking is decided per project
**Decision:** No task tool in the blueprint. A `project-management` skill,
called from project-setup, picks the tracking per project: fixed criteria
(sandbox without tokens, any harness, leaves agent files alone, no own
commits, pinnable) applied to a candidate list with a "last checked" date.
It researches again only when the list is older than three months. Backlog.md
is the current recommendation for products; small projects keep a list in
`docs/project.md`. Node, Backlog.md and `backlog/config.yml` left the blueprint.
**Why:** Making Backlog.md the default cost every project a Node install,
gave one-off projects a tool they don't need, and was decided before any real
project used it. Tools here change monthly; criteria don't.
**Learned:** When the field moves fast, put the criteria and the testing
procedure in the blueprint, not the choice. A dated candidate list avoids
re-researching in every project, and harvest keeps it current.
