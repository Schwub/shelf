#!/usr/bin/env bash
# Adds the test albums in test_albums.sql to one account's shelf.
# Usage: test-albums.sh <email> [--remote]   (--remote: the linked project)
set -euo pipefail
email="${1:?usage: test-albums.sh <email> [--remote]}"
# The email goes into SQL: allow only plain addresses.
if ! [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+$ ]]; then
  echo "Not a plain email address: $email" >&2
  exit 1
fi
sql="$(mktemp)"
trap 'rm -f "$sql"' EXIT
sed "s/__EMAIL__/$email/g" "$(dirname "$0")/test_albums.sql" > "$sql"
supabase db query --file "$sql" ${2:+--remote --yes}
