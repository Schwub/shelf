#!/bin/sh
# Tests for guard.sh: each line is "<expected exit code> <command>".
cd "$(dirname "$0")" || exit 1
fail=0
while read -r want cmd; do
  printf '%s' "$cmd" | ./guard.sh 2>/dev/null
  got=$?
  [ "$got" = "$want" ] || { echo "FAIL: want $want, got $got: $cmd"; fail=1; }
done <<'EOF'
2 git reset --hard
2 git -C . reset --hard HEAD~1
2 bash -c 'git reset --hard'
2 cd x && git clean -fd
2 git checkout -- a.txt
2 git checkout .
2 git restore a.txt
2 git stash
2 git stash pop
2 git push origin main --force
2 git push -f
2 git push --force-with-lease
2 git push origin +main
2 git commit --no-verify -m x
2 git commit -nm x
2 git add -A
2 git add .
2 git add --all
2 git commit -am x
2 FOO=1 git add .
2 {"tool_input":{"command":"git add . && git commit -m \"x\""}}
0 git status
0 git reset HEAD a.txt
0 git reset --soft HEAD~1
0 git checkout main
0 git checkout -b feature
0 git checkout feature-f
0 git restore --staged a.txt
0 git stash list
0 git push -u origin feature
0 git push origin fix-f
0 git commit -m "clean up reset logic"
0 git commit --amend -m x
0 git commit -m "x" --author=me
0 git add .gitignore
0 git add ./a.txt src/b.txt
0 git log -n 3
0 npm run clean
0 {"tool_input":{"command":"git add README.md","description":"Stage file"}}
EOF
[ "$fail" = 0 ] && echo "guard tests passed"
exit "$fail"
