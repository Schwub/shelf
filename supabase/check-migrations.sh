#!/usr/bin/env bash
# Guards staging data (AGENTS.md, TASK-43): fails when this branch adds a
# migration that drops or deletes data without saying how the data is kept,
# or edits a migration that is already on the base branch (staging never
# runs it again). Usage: check-migrations.sh <base-ref>   (from the repo root)
set -euo pipefail
base="${1:?usage: check-migrations.sh <base-ref>}"
dir=supabase/migrations
failed=0

while IFS= read -r file; do
  echo "::error file=$file::Applied migrations don't run again: put the change in a new migration."
  failed=1
done < <(git diff --name-only --diff-filter=MDR "$base"...HEAD -- "$dir")

while IFS= read -r file; do
  if grep -qiE '^\s*--\s*keeps data:' "$file"; then continue; fi
  # Function bodies ($$ … $$) run when called, not when the migration runs.
  if perl -0pe 's/\$(\w*)\$.*?\$\1\$//gs' "$file" |
    grep -iE '\b(drop\s+(table|column|schema)|truncate|delete\s+from)\b'; then
    echo "::error file=$file::This migration can lose data. Keep it (copy it first), or add a '-- keeps data: <how>' line that says why nothing is lost."
    failed=1
  fi
done < <(git diff --name-only --diff-filter=A "$base"...HEAD -- "$dir")

exit "$failed"
