# Task tracking for agent-driven projects (November 2026)

Outcome: no fixed tool. The criteria and candidates below moved into
`.agents/skills/project-management/candidates.md`, which projects use to decide.

Question: where do a project's tasks live, so that I and any agent (Claude
Code, pi) can read and update them, also inside a sandbox without a GitHub
token, for small one-off projects and for products alike?

## Constraints from earlier decisions
- Agents run in a sandbox on a private clone, without a token for GitHub.
- Harness-agnostic: files and CLIs, nothing that exists in one harness only.
- AGENTS.md is curated: no tool may rewrite it or `.claude/rules/`.
- Git rules: agents commit only when allowed, by explicit path.
- Same setup for small and product projects.

## Options

| | Plain Markdown | Backlog.md | Beads (`bd`) | GitHub Issues | Linear |
|---|---|---|---|---|---|
| Storage | a file in the repo | one Markdown file per task, YAML frontmatter, `backlog/` | Dolt database in `.beads/`, JSONL export | GitHub | Linear cloud |
| Readable without the tool | yes | yes | no (export only) | web | web |
| Works offline in the sandbox | yes | yes, local-first, `--no-git` possible | yes, with local-only settings | needs token | needs token |
| Board for humans | no | yes, local web UI and terminal board | community tools | yes | yes |
| Agent interface | read/edit file | CLI with `--json`, MCP server | CLI (`bd ready`, `bd create`), JSON | `gh`, MCP | MCP |
| Dependencies, acceptance criteria | by hand | yes | yes, a dependency graph | partly | yes |
| Install | none | npm/bun/brew/nix; 1.57.2 tested here, npm package with a native binary per platform | brew, npm, Go | `gh` | account |
| Touches agent files | no | init writes instructions unless `--agent-instructions none` | init edits AGENTS.md and installs Claude/Codex/Cursor hooks unless `--skip-agents`/`--stealth`; can merge `.claude/rules/*.md` | no | no |
| Maturity | — | MIT, ~7.5k stars, active | MIT, ~29k stars, very active; schema migrations, "pin an exact version" | stable | stable |

Sources: [Backlog.md README](https://github.com/MrLesk/Backlog.md/blob/main/README.md),
[beads README](https://github.com/steveyegge/beads),
[Linear vs GitHub Issues 2026](https://t0ggles.com/compare/linear-vs-github-issues),
`backlog init --help` (v1.57.2, run locally).

## Findings
- **Beads** is built for agent memory, not for people: a database with
  migrations, and by default it rewrites AGENTS.md and installs hooks in
  several harnesses. That clashes with a curated AGENTS.md and the guard.
- **Hosted trackers** (GitHub Issues, Linear) are best for collaboration but
  need a token in the sandbox, which we kept out on purpose.
- **Backlog.md** keeps tasks as Markdown in the repo, so an agent without
  the CLI can still read and edit them, and a human gets a board. Its init
  can skip writing agent instructions. Its options mention commits and git
  hooks; whether it commits by itself must be checked before use.
- **Plain Markdown** has no install and no structure: fine for a handful of
  tasks, weak once there are dependencies or more than one person.

## Verified (1.55.3 and 1.57.2, in a scratch repo)
- `auto_commit: false` is the default: creating and editing tasks commits nothing.
- Without a remote it warns about `remote_operations`; set to false.
- A task is one Markdown file with YAML frontmatter (id, title, status,
  dependencies) and a checkbox list of acceptance criteria.
- `backlog init --integration-mode none` writes only `backlog/config.yml`.

## Not verified
- Installing it through mise (`npm:backlog.md` with Node) in the sandbox;
  CI covers the GitHub runner.
