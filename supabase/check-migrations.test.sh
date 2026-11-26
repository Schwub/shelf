#!/usr/bin/env bash
# Tests check-migrations.sh in a throwaway repository.
set -euo pipefail
check="$(cd "$(dirname "$0")" && pwd)/check-migrations.sh"
repo="$(mktemp -d)"
trap 'rm -rf "$repo"' EXIT
cd "$repo"
git init -q -b main
git config user.email test@example.com
git config user.name test
mkdir -p supabase/migrations
echo 'create table t (id int, old text);' > supabase/migrations/1_t.sql
git add . && git commit -qm base
pass=0 fail=0

# A branch "work" with one commit that writes <file> with <content>.
branch() {
  git switch -qc work
  printf '%b\n' "$2" > "supabase/migrations/$1"
  git add . && git commit -qm work
}

expect() { # <ok|fails> <description>
  if "$check" main >/dev/null 2>&1; then got=ok; else got=fails; fi
  if [ "$got" = "$1" ]; then pass=$((pass + 1)); else echo "FAIL: $2 ($got)"; fail=$((fail + 1)); fi
  git switch -q main && git branch -qD work
}

branch 2_add.sql 'alter table t add column note text;'
expect ok 'an additive migration passes'

branch 2_drop.sql 'alter table t drop column old;'
expect fails 'dropping a column fails'

branch 2_drop.sql '-- keeps data: old was copied to note in 2_copy\nalter table t drop column old;'
expect ok 'a reason that keeps the data lets it pass'

for statement in 'drop table t;' 'truncate t;' 'delete from t where id = 1;' 'DROP  TABLE t;'; do
  branch 2_x.sql "$statement"
  expect fails "'$statement' fails"
done

branch 2_fn.sql 'create function f() returns trigger language plpgsql as $$\nbegin delete from t where id = 0; return old; end $$;'
expect ok 'delete in a function body passes (it runs later, when called)'

branch 1_t.sql 'create table t (id int, old text, more text);'
expect fails 'editing an applied migration fails'

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
