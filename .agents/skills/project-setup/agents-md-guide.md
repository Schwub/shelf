# How to fill in a project AGENTS.md

Every agent (Claude Code, Codex, pi, OpenCode, ...) reads AGENTS.md at the start
of every session and follows it closely. So each line changes behaviour and
costs context. Write down only what an agent can't work out from the repo.

**The test for every line:** would an agent get this wrong without it?
If not, delete it. Delete whole sections that have nothing non-obvious to say.

## Getting started
1. `mise run init` puts the template ([AGENTS.template.md](AGENTS.template.md))
   above the "Working agreements" section.
2. The project-setup skill fills in the placeholders by exploring the repo.
3. Edit the result down by hand. Unedited generated files measurably do worse
   than human-written ones; most of the work is removing lines.

## Sections
| Section | Put in | Leave out |
|---|---|---|
| Commands | Exact commands, incl. running a single test; how long slow ones take | Explanations of what the tools are |
| Done means | The command that must pass; what evidence to report | Generic "test your changes" |
| Conventions | Only deviations from common defaults, each with a reason; a pointer to an exemplar file | Style the linter or formatter enforces; pasted code |
| Gotchas | Misleading code, required env vars and services, generated files | Anything visible from reading the code |
| Boundaries | "Ask first" and "Never" rules, noting where each "Never" is enforced | Hard rules that exist only as prose |
| Git and PRs | Branch, commit and PR conventions | Copies of CONTRIBUTING.md (point to it) |
| Where to look | One-line pointers to docs for specific areas, or for APIs newer than the model | The docs themselves |

## Never put in
- Project overview, architecture tour, directory trees
- Status updates, progress, todos (they belong in the task system)
- Emphasis (IMPORTANT, ALL CAPS): a rule that must hold needs a hook or CI check
- Personas and generic advice ("be thorough", "write clean code")
- Tool-specific syntax (`@imports`, plan mode): Claude-only lines go in a
  CLAUDE.md that starts with `@AGENTS.md`
- Personal preferences in the project sections: those belong in the
  "Working agreements" section, which is changed only in the blueprint

## Keeping it alive
- Add a line the second time an agent makes the same mistake, not the first.
- Review additions like code, even when an agent drafted them.
- When a new model generation arrives, try removing behavioural lines and
  re-add only those whose absence causes a visible problem.
- A CLAUDE.md or CLAUDE.local.md in the project makes Claude Code ignore
  AGENTS.md, unless it imports it with `@AGENTS.md`.
- Monorepos: add a nested AGENTS.md per package with only that package's
  commands and gotchas.
