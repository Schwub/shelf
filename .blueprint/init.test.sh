#!/bin/sh
# Runs init on throwaway copies of the working tree, as if just created from the template.
set -eu
src=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

fail() { echo "FAIL: $1" >&2; exit 1; }

# A one-commit repo with the working tree's files, like one made from the template.
fresh_repo() {
  mkdir "$1"
  (cd "$src" && git ls-files -z | tar --null -T - -cf -) | tar -xf - -C "$1"
  git -C "$1" init -q -b main
  git -C "$1" add .
  git -C "$1" commit -q -m "Initial commit"
}

repo="$tmp/my-app"
fresh_repo "$repo"
cd "$repo"

touch dirty
.blueprint/init.sh >/dev/null 2>&1 && fail "init ran with uncommitted changes"
rm dirty

.blueprint/init.sh >/dev/null

[ "$(git rev-list --count HEAD)" = 2 ] || fail "expected one init commit"
[ -z "$(git status --porcelain)" ] || fail "init left uncommitted changes"
[ ! -e .blueprint ] || fail ".blueprint/ still exists"
[ ! -e .agents/skills/harvest ] && [ ! -L .claude/skills/harvest ] || fail "harvest skill still exists"
head -1 AGENTS.md | grep -qx '# AGENTS.md' || fail "AGENTS.md does not start with the template"
grep -q '<command>' AGENTS.md || fail "AGENTS.md has no template placeholders"
grep -qx '# Working agreements' AGENTS.md || fail "working agreements missing"
grep -q '^# my-app' README.md || fail "README has no project name"
[ -f docs/blueprint-feedback.md ] || fail "feedback file missing"
! grep -q 'init\|Blueprint only' mise.toml || fail "blueprint-only tasks left in mise.toml"
grep -q 'check:guard' mise.toml || fail "shared check task removed"
.agents/guard.test.sh >/dev/null || fail "guard tests fail after init"
for s in kickoff project-setup project-management; do
  [ -f ".claude/skills/$s/SKILL.md" ] || fail "skill $s not reachable from .claude/skills/"
done

# Init must refuse anything that isn't a fresh template repo, such as the blueprint itself.
fresh_repo "$tmp/blueprint"
git -C "$tmp/blueprint" commit -q --allow-empty -m "Second commit"
"$tmp/blueprint/.blueprint/init.sh" >/dev/null 2>&1 && fail "init ran in a repo with history"
git clone -q --depth 1 "file://$tmp/blueprint" "$tmp/shallow"
"$tmp/shallow/.blueprint/init.sh" >/dev/null 2>&1 && fail "init ran in a shallow clone"
echo "init tests passed"
