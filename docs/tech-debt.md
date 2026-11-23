# Tech debt

**Last review:** none yet (first review due 4 weeks or 30 commits after 2026-11-22).
**Interval:** every 4 weeks or 30 commits.

## Items

| What | Where | Why it hurts | Effort | Risk | Suggested action |
|---|---|---|---|---|---|
| Any signed-in user can add an album with a real MusicBrainz ID and wrong data (title, artist, a `cover_url` to any server); albums can't be edited from the client, so later users link to the bad row | `supabase/migrations/20261123120000_albums_and_shelf_entries.sql` (`albums` insert policy) | Bad catalog data spreads to friends; fixable only with service-role access | M | Low while only friends use it | Resolve MusicBrainz albums server-side (edge function) when share-to-add resolving lands, or before the public launch |
| Clients can set `created_at` / `updated_at` on insert (the trigger only runs on update) | same migration, `shelf_entries` | The M2 feed orders by recent changes; a future-dated entry would stick to the top | S | None until M2 | Set both on insert too (trigger or column grants) when building the feed |
