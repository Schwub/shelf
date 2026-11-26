---
name: release
description: Get merged work onto staging and the phone - merge a green PR, let the database deploy to staging before the app, wait for the Android release and report its version. Use when the user says merge, release or deploy, or after they approve merging a PR.
---

# Release

Order matters: the app may need the new database, so staging's database
goes first.

1. **Green PR.** Merge only with the user's go-ahead. Check every check run
   of the PR's head; the `android` and `integration` workflows run only
   when their paths change, so a missing one isn't a failure. Merge with
   the full 40-character head SHA as `expectedHeadSha`.
2. **What starts on `main`:**
   - `supabase/**` changed: `db` runs, then `staging` deploys migrations,
     auth settings and functions. Read the `staging` log's "Apply
     migrations" step to confirm the new migrations are listed.
   - `app/**` changed: `android-staging` builds the release APK and
     publishes it as GitHub release `v1.0.<run number>` (failed or
     cancelled runs use up numbers too, so read the run number, don't
     guess). Obtainium on the user's phone installs it.
   - Both start at once; the database is usually done in about 5 minutes,
     the APK in about 7. If the APK is first, tell the user to update only
     after the staging run has passed.
3. **Wait** with a scheduled check-in (about 9 minutes) instead of polling,
   then report: staging done (and which migrations), release version, what
   to try on the phone.
4. **If a workflow didn't run** (Actions minutes used up, a skipped
   trigger): start `staging` and `android-staging` by hand from `main`
   (`workflow_dispatch`), database first.

Repository variables the builds use: `SUPABASE_STAGING_PROJECT_ID`,
`SUPABASE_STAGING_PUBLISHABLE_KEY`, `MUSICBRAINZ_CONTACT`, `SENTRY_DSN`;
secrets `SUPABASE_ACCESS_TOKEN`, `SUPABASE_STAGING_DB_PASSWORD`.
