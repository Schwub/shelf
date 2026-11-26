#!/usr/bin/env bash
# Adds test data to one account: test_albums.sql (albums on its shelf) or
# test_friend.sql (a friend with albums and feed activity).
# Usage: test-data.sh <albums|friend> <email> [--remote]   (--remote: the linked project)
set -euo pipefail
kind="${1:?usage: test-data.sh <albums|friend> <email> [--remote]}"
email="${2:?usage: test-data.sh <albums|friend> <email> [--remote]}"
case "$kind" in albums | friend) ;; *) echo "Unknown test data: $kind" >&2; exit 1 ;; esac
# The email goes into SQL: allow only plain addresses.
if ! [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+$ ]]; then
  echo "Not a plain email address: $email" >&2
  exit 1
fi
sql="$(mktemp)"
trap 'rm -f "$sql"' EXIT
sed "s/__EMAIL__/$email/g" "$(dirname "$0")/test_$kind.sql" > "$sql"
supabase db query --file "$sql" ${3:+--remote --yes}
