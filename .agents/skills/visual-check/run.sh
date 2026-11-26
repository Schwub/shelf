#!/usr/bin/env bash
# Screenshots of the real app (web build) against the local Supabase.
# Usage: run.sh <out-dir> [theme] [steps.json]   (from the repo root)
set -euo pipefail
out="${1:?usage: run.sh <out-dir> [theme] [steps.json]}"
theme="${2:-tobacco}"
steps="${3:-}"
here="$(cd "$(dirname "$0")" && pwd)"
email="look@example.com"

# Auth, the API gateway and the database are enough.
supabase start -x studio,imgproxy,mailpit,realtime,logflare,vector,supavisor,edge-runtime,postgres-meta >/dev/null
eval "$(supabase status -o env | grep -E '^(API_URL|SERVICE_ROLE_KEY)=')"
export API_URL SERVICE_ROLE_KEY

# The test user (made once) with the nine test albums.
curl -s -o /dev/null -X POST "$API_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_ROLE_KEY" -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H 'Content-Type: application/json' -d "{\"email\":\"$email\",\"email_confirm\":true}"
supabase/dev/test-albums.sh "$email" >/dev/null

# The web build, served where the local Supabase expects the app.
# The renderer comes with the build: cloud sessions can't reach its CDN.
(cd app && flutter build web --no-web-resources-cdn >/dev/null)
python3 -m http.server 3000 --bind 127.0.0.1 --directory app/build/web >/dev/null 2>&1 &
server=$!
trap 'kill $server' EXIT
sleep 1

node "$here/shoot.js" "$out" "$email" "$theme" $steps
