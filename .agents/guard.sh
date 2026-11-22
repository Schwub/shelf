#!/bin/sh
# Blocks shell commands that break the Git rules in AGENTS.md.
# Reads the command (or a hook payload containing it) on stdin; exit 2 = block.
# Matches text, not parsed shell: a net, not a wall. A false positive (e.g. a
# quoted example) costs a rephrase, so the patterns stay simple.
input=$(cat)

# "git", optional global options (-C dir, -c k=v, --no-pager), then a subcommand
git='(^|[^[:alnum:]_./-])git([[:space:]]+(-[A-Za-z][[:space:]]+[^[:space:]]+|--[a-z-]+(=[^[:space:]]+)?))*[[:space:]]+'
rest='[^;&|]*'              # the rest of the same simple command
end='([^[:alnum:]_./-]|$)'  # end of an argument

has() { printf '%s' "$input" | grep -Eq -- "$1"; }
block() {
  echo "Blocked by .agents/guard.sh: $1 If I asked for this, tell me to run it myself." >&2
  exit 2
}

discard="discards uncommitted changes."
has "${git}reset[[:space:]]${rest}--hard" && block "git reset --hard $discard"
has "${git}clean${end}" && block "git clean $discard"
has "${git}checkout${rest}[[:space:]](--|\.)${end}" && block "git checkout of paths $discard"
has "${git}restore${end}" && ! has "${git}restore[[:space:]]${rest}--staged" && block "git restore $discard"
has "${git}stash${end}" && ! has "${git}stash[[:space:]]+(list|show)${end}" && block "git stash moves uncommitted changes away."
has "${git}push${rest}[[:space:]](--force[a-z-]*|-[a-zA-Z]*f[a-zA-Z]*|\+[^[:space:]]+)${end}" && block "force-push rewrites remote history."
has "${git}${rest}--no-verify" && block "--no-verify bypasses hooks."
has "${git}commit${rest}[[:space:]]-[a-zA-Z]*n[a-zA-Z]*${end}" && block "commit -n bypasses hooks."
has "${git}add${rest}[[:space:]](-A|--all|\.)${end}" && block "stage files by explicit path."
has "${git}commit${rest}[[:space:]](--all|-[a-zA-Z]*a[a-zA-Z]*)${end}" && block "stage files by explicit path."
exit 0
