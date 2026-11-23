# Tech debt

**Last review:** 2026-11-23, commit b19ab58.
**Interval:** every 4 weeks or 30 commits.

Facts at this review: analyzer clean, `mise run check` and `mise run test:db`
pass locally and in CI, no TODO/FIXME, largest file 114 lines.

## Items

Ranked by value for effort.

Done at this review: removed `cupertino_icons`, fixed stale docs (OAuth,
check duration), patch-updated `vector_math`, added an Android APK build to
CI (TASK-4).

| What | Where | Why it hurts | Effort | Risk | Suggested action |
|---|---|---|---|---|---|
| The iOS share extension is never built in CI (fragile build-phase order, App Group) | `app/ios`, `.github/workflows/` | An iOS-only change can break share-to-shelf on iPhone unnoticed | M | Medium | An iOS build job on a macOS runner (about 10× the CI minutes of Linux); until then run the native build locally after `app/ios` changes |
| Cloud sessions can't install the mise toolchain: `mise.run` is blocked, the Supabase CLI (aqua/GitHub API) and backlog (sigstore provenance) fail, so `mise run` needs `MISE_DISABLE_TOOLS` and manual installs | `mise.toml`, cloud environment | Every cloud session spends its first ~10 minutes on setup and may run checks differently | M | Low | A personal "shelf" cloud environment with a setup script (your decision; also noted in `docs/blueprint-feedback.md`) |
| Any signed-in user can add an album with a real MusicBrainz ID and wrong data (title, artist, a `cover_url` to any server); albums can't be edited from the client, so later users link to the bad row | `supabase/migrations/20261123120000_albums_and_shelf_entries.sql` (`albums` insert policy) | Bad catalog data spreads to friends; fixable only with service-role access | M | Low while only friends use it | Resolve MusicBrainz albums server-side (edge function) when share-to-add resolving lands, or before the public launch |
| Clients can set `created_at` / `updated_at` on insert (the trigger only runs on update) | same migration, `shelf_entries` | The M2 feed orders by recent changes; a future-dated entry would stick to the top | S | None until M2 | Set both on insert too (trigger or column grants) when building the feed |
