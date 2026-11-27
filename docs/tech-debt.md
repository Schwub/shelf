# Tech debt

**Last review:** 2026-11-27, commit 7f145aa (70 commits since dedcdf4).
**Interval:** every 4 weeks or 30 commits.

Facts at this review:
- Analyzer clean. `mise run check` passes (346 tests, web build);
  `mise run test:integration` passes.
- No TODO or FIXME, and no unused top-level classes or functions.
- Dependencies: `sentry_flutter` 10.6.0 → 10.7.0 (minor) is available.
  Five transitive ones are held back by the Flutter SDK.
- Largest files: `shelf_colors.dart` (863, theme data),
  `tag_group_page.dart` (787), `shelf_page.dart` (720),
  `supabase_shelf_repository.dart` (535), `entry_page.dart` (499).
- Most changed since the last review: the Supabase repository and its
  integration test, `friend_shelf_test.dart`, `fake_shelf.dart`,
  `main.dart`, `entry_page.dart` and `docs/architecture.md`.
- Edge functions unchanged since the last review.

Resolved since the last review: `shelf_data.dart` split into models,
interface and Supabase repository (TASK-34).

## Items

Ranked by value for effort.

| What | Where | Why it hurts | Effort | Risk | Suggested action |
|---|---|---|---|---|---|
| The data model in the architecture doc is behind: no `tag_group_destinations`, still says friends' read access "comes with M2", and nothing on friends' filters or the date-added filter | `docs/architecture.md`, "Data model" | Agents and readers plan against a schema that isn't there | S | Low | Update the section (quick cleanup) |
| Eight bottom sheets repeat the same chrome (root navigator, scroll control, background, barrier colour, 4 px top corners, line border) | `invite_sheet`, `theme_sheet`, `tag_picker`, `sort_sheet`, `copy_tags_page`, `tag_sheet`, `bulk_tags_sheet`, `tag_actions_sheet` | A change to the sheet look has to be made eight times, and new sheets copy it again | S | Low (no behaviour change) | One `showShelfSheet` helper in `app/lib/widgets/` (quick cleanup) |
| Creating a tag or group fires `ShelfRepository.changes`, and `TagImport.apply` also reloads the whole shelf after every tag it creates; copying k tags costs about 2k shelf loads plus k background reloads of My shelf and the friend's shelf | `app/lib/shelf/tag_import.dart` (`apply`), `supabase_shelf_repository.dart` (`createTag`, `createGroup`) | Extra queries on the free tier; harmless while shelves are small and copies are a few tags | S | Low | Reload only after creating a group (a new tag's ID comes back from `createTag`), and notify once after a copy, if it becomes noticeable |
| `_TagGroupPageState` is one ~670-line state class (editing, reordering, deleting, sub-groups, dialogs) | `app/lib/tags/tag_group_page.dart` | Hard to read and change | M | Medium (UI behaviour) | Extract the delete/rename dialogs and the tag list into widgets when the tag editor changes next |
| `_ShelfPageState` holds loading, filters, sort, both views, selection and bulk actions (~590 lines) | `app/lib/shelf/shelf_page.dart` | The most-used screen; each feature (TASK-39, 40, 41) grew it further | M | Medium | Move selection mode with its bar and actions into its own widget when the shelf screen changes next |
| The iOS share extension is never built in CI (fragile build-phase order, App Group) | `app/ios`, `.github/workflows/` | An iOS-only change can break share-to-shelf on iPhone unnoticed | M | Medium | An iOS build job on a macOS runner (about 10× the CI minutes of Linux); until then run the native build locally after `app/ios` changes |
| The two edge functions each have their own MusicBrainz client with different rate-limit and retry rules | `supabase/functions/*/musicbrainz.ts` | A fix to MusicBrainz handling has to be made twice | S | Low | A `supabase/functions/_shared/musicbrainz.ts` when either function changes next |
| `sentry_flutter` is one minor version behind (10.7.0) | `app/pubspec.yaml` | Small; misses fixes | S | Low | Update with the user's OK (minor version of a production dependency) |
