# Task tracking: criteria and candidates

Last checked: 2026-11-22. Updated through blueprint feedback and harvest.

## Criteria (all must hold)
- **Sandbox:** agents can read and update tasks without network access or
  tokens. Agents run in a sandbox on a private clone, without GitHub access.
- **Any harness:** files or a CLI, not a feature of one agent tool.
- **Leaves agent files alone:** doesn't rewrite AGENTS.md, `.claude/` or
  install hooks, or can be told not to.
- **Git rules:** doesn't commit or push on its own, or can be told not to.
- **Pinnable:** a version can be pinned in `mise.toml`.

## Candidates

| Option | Fits | Notes |
|---|---|---|
| "First steps" list in `docs/project.md` | Small projects, a handful of steps, one person | No install. Weak once tasks depend on each other. |
| [Backlog.md](https://github.com/MrLesk/Backlog.md) | Products, one person or a small team | Recommended for products. One Markdown file per task in `backlog/`, CLI with `--plain`/`--json`, local web board. Needs Node. Tested 1.55.3. |
| [Beads](https://github.com/steveyegge/beads) (`bd`) | Agent-heavy work with many dependent tasks | Fails "leaves agent files alone" by default: init edits AGENTS.md and installs hooks (`--skip-agents`/`--stealth` exist). A database with migrations; not readable without the tool. |
| GitHub Issues | Teams, public projects | Fails "sandbox": needs a token in the sandbox. Fine if agents only read tasks outside the sandbox. |
| Linear | Teams with product planning | Fails "sandbox" like GitHub Issues; an account per person. |

## Backlog.md setup (tested 1.55.3)
- Pin in `mise.toml`: `node = "24"` and `"npm:backlog.md" = "1.55.3"`
  (if the stack pins Node already, keep one pin).
- `backlog init <name> --defaults --integration-mode none` writes only
  `backlog/config.yml` and no agent instructions.
- Then `backlog config set remoteOperations false`: otherwise it tries the
  git remote. `auto_commit: false` is the default; keep it.
- Task commands for AGENTS.md: `backlog task list --plain`,
  `backlog task view <id> --plain`, `backlog task edit <id> --check-ac <n> -s Done`,
  `backlog task create "<title>" --ac "<criterion>"`.
- Task files contain marker comments (`<!-- AC:BEGIN -->`); edit them with
  the CLI, not by hand.
