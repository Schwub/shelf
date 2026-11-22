#!/bin/sh
# Turns a repo just created from the blueprint template into a project:
# project AGENTS.md from the template, README stub, feedback file,
# no .blueprint/, no blueprint-only tasks or skills. Commits the result.
# Usage: mise run init [project-name]   (default: the directory name)
set -eu
cd "$(dirname "$0")/.."
name=${1:-$(basename "$PWD")}

# A repo created from the template has exactly one commit; the blueprint
# itself has many, so this also stops init from running there. A shallow
# clone of the blueprint shows one commit too, hence the second test.
[ "$(git rev-list --count HEAD)" = 1 ] && [ "$(git rev-parse --is-shallow-repository)" = false ] || { echo "init: run this in a repo just created from the template (gh repo create --template)" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "init: uncommitted changes, aborting" >&2; exit 1; }

{
  cat .agents/skills/project-setup/AGENTS.template.md
  echo
  sed -n '/^# Working agreements$/,$p' AGENTS.md
} > AGENTS.md.new
mv AGENTS.md.new AGENTS.md

printf '# %s\n\nWhat and why: [docs/project.md](docs/project.md). Agent setup: [AGENTS.md](AGENTS.md).\n' "$name" > README.md

mkdir -p docs
cat > docs/blueprint-feedback.md <<'EOF'
# Blueprint feedback

Notes for the blueprint this project started from, collected later.
One entry per finding: date, what happened, which rule or skill, suggestion.
Only what would help other projects; project-specific fixes go in AGENTS.md.
EOF

sed '/^# Blueprint only/,$d' mise.toml > mise.toml.new
mv mise.toml.new mise.toml

git rm -rq .blueprint .agents/skills/harvest .claude/skills/harvest
git add AGENTS.md README.md mise.toml docs/blueprint-feedback.md
git commit -q -m "Init $name from the blueprint"
echo "Initialised '$name'. Next: push, start the agent (mise run agent) and run the kickoff skill, then project-setup."
