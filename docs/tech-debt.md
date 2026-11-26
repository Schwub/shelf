# Tech debt

**Last review:** 2026-11-26, commit dedcdf4.
**Interval:** every 4 weeks or 30 commits.

Facts at this review: analyzer clean; `mise run check` passes (208 tests,
web build) and `mise run test:functions` passes (41 tests); no TODO/FIXME;
no unused classes or files; direct dependencies up to date (three
transitive ones held back by the Flutter SDK). The largest files have grown
from 114 lines to 827 (`shelf_data.dart`) and 786 (`tag_group_page.dart`);
`shelf_colors.dart` (863) is theme data. The most-changed files are
`main.dart`, `shelf_page.dart` and its test.

Resolved since the last review: users can no longer add albums themselves
(the `add-album` function does it, `20261125090000_covers.sql`); the
"shelf" cloud environment's setup script installs the toolchain (fixed
2026-11-26; still needs its first fresh session to confirm).

Done at this review: stale docs fixed (albums, test albums, the edge-function
bullet, covers/list in TASK-25 and the shelf wireframe, `test:functions` in
AGENTS.md); one `Message` widget (`app/lib/widgets/message.dart`) instead of
two copies. After the review: `shelf_data.dart` split into
`shelf.dart` (models), `shelf_repository.dart` and
`supabase_shelf_repository.dart` (TASK-34). TASK-38 made `created_at`, `updated_at` and `rated_at`
database-only.

## Items

Ranked by value for effort.

| What | Where | Why it hurts | Effort | Risk | Suggested action |
|---|---|---|---|---|---|
| `_TagGroupPageState` is one ~670-line state class (editing, reordering, deleting, sub-groups, dialogs) | `app/lib/tags/tag_group_page.dart` | Hard to read and change; the next tag feature (TASK-19 import) lands here | M | Medium (UI behaviour) | Extract the delete/rename dialogs and the tag list into widgets when TASK-19 touches it |
| The iOS share extension is never built in CI (fragile build-phase order, App Group) | `app/ios`, `.github/workflows/` | An iOS-only change can break share-to-shelf on iPhone unnoticed | M | Medium | An iOS build job on a macOS runner (about 10× the CI minutes of Linux, and minutes already ran out once); until then run the native build locally after `app/ios` changes |
| Creating a tag or group fires `ShelfRepository.changes`, so copying k friend's tags (TASK-19) reloads My shelf and the open friend's shelf about k times, and tag editor edits reload both in the background | `app/lib/shelf/supabase_shelf_repository.dart` (`createTag`, `createGroup`) | Extra queries on the free tier; harmless while shelves are small | S | Low | Notify once after a copy (e.g. a `copyTags` on the repository) if the reloads become noticeable |
| The two edge functions each have their own MusicBrainz client with different rate-limit and retry rules (`resolve-link` imports only the `Fetch` type from `add-album`) | `supabase/functions/*/musicbrainz.ts` | A fix to MusicBrainz handling has to be made twice | S | Low | A `supabase/functions/_shared/musicbrainz.ts` with one request helper, when either function changes next |
