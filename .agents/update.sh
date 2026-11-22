#!/bin/sh
# Updates what this project shares with the blueprint: the paths in
# .agents/managed.txt and the "Working agreements" section of AGENTS.md.
# Stages the result for review and shows where project-owned files differ.
# Usage: mise run agentic:update [blueprint git URL]
# First time, in a project without this script:
#   git fetch <blueprint URL> main && git show FETCH_HEAD:.agents/update.sh | sh
set -eu
cd "$(git rev-parse --show-toplevel)"
src=${1:-https://github.com/Schwub/agentic}

[ ! -d .blueprint ] || { echo "update: this is the blueprint itself" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "update: uncommitted changes, aborting" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git clone -q --depth 1 "$src" "$tmp/bp"
bp="$tmp/bp"

# Managed paths the blueprint dropped since the last update.
if [ -f .agents/managed.txt ]; then
  grep -vxF -f "$bp/.agents/managed.txt" .agents/managed.txt | while read -r p; do
    git rm -rq --ignore-unmatch -- "$p"
  done
fi

while read -r p; do
  rm -rf "$p"
  mkdir -p "$(dirname "$p")"
  cp -RP "$bp/$p" "$p"
  git add --all -- "$p"
done < "$bp/.agents/managed.txt"

# Projects from before the working agreements moved into AGENTS.md.
git rm -q --ignore-unmatch .claude/rules/working-agreements.md
{
  sed '/^# Working agreements$/,$d' AGENTS.md
  sed -n '/^# Working agreements$/,$p' "$bp/AGENTS.md"
} > AGENTS.md.new
mv AGENTS.md.new AGENTS.md

git -C "$bp" rev-parse HEAD > .agents/blueprint-version
git add AGENTS.md .agents/blueprint-version

sed '/^# Blueprint only/,$d' "$bp/mise.toml" > "$tmp/mise.toml"
for f in mise.toml .claude/settings.json .gitignore; do
  theirs="$bp/$f"
  [ "$f" = mise.toml ] && theirs="$tmp/mise.toml"
  if ! git diff --no-index --quiet -- "$f" "$theirs" 2>/dev/null; then
    echo "== $f differs from the blueprint (project-owned, merge by hand if useful):"
    git --no-pager diff --no-index -- "$f" "$theirs" || true
  fi
done

echo "== Staged from the blueprint:"
git --no-pager diff --cached --stat
echo "Review with 'git diff --cached', then commit."
