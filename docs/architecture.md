# Architecture

## Intended structure
- **Flutter app** in `app/` (iOS, Android, web; package `shelf_app`, app ID
  `de.schwubware.shelf`): UI, album search, share target. Talks
  to Supabase through the official Flutter SDK and to MusicBrainz / Cover
  Art Archive for album data.
- **iOS share extension / Android share intent:** receive a shared link and
  hand it to the app.
- **Supabase** in `supabase/` (config, migrations, edge functions):
  - Postgres for users, albums, shelf entries, friendships and the feed.
  - Edge function `add-album` adds albums to the shared catalog from
    MusicBrainz and copies their covers into the public `covers` bucket;
    users can't add albums or covers themselves
    ([features/search.md](features/search.md)).
  - Edge function `resolve-link` turns a shared Spotify or Bandcamp link
    into a MusicBrainz album, or the page's own data when MusicBrainz
    doesn't know it ([features/sharing.md](features/sharing.md)).
  - Auth for accounts: email sign-in with a 6-digit code or the link in
    the same email; no passwords. The app reads `SUPABASE_URL` and
    `SUPABASE_PUBLISHABLE_KEY` from `--dart-define` and defaults to the
    local Supabase (`supabase start`).
  - Row-level security decides who sees what: your own shelf, and your
    friends' shelves and activity.

## Share-to-add
- `app/lib/share/share_receiver.dart` is the only code that imports the
  plugin; it yields the link that launched the app, then links shared while
  it runs. `shared_link.dart` takes the first http(s) URL from shared text
  (Spotify shares a sentence ending in the URL). `main.dart` puts the links
  into a `SharedLinkInbox` from the start; My shelf opens them with
  `ResolvePage` once it has loaded ([features/sharing.md](features/sharing.md)).
- Android: `SEND` `text/plain` intent filter on `MainActivity`; the plugin
  needs `compileSdk = 37`.
- iOS: `ShareExtension` target (principal class, no storyboard) subclasses
  `RSIShareViewController` and opens the app immediately. It links the
  `FlutterGeneratedPluginSwiftPackage` product, shares the App Group
  `group.de.schwubware.shelf` with Runner (`CUSTOM_GROUP_ID`), uses
  Runner's Flutter xcconfigs, and takes its version from `MARKETING_VERSION`
  / `CURRENT_PROJECT_VERSION` (set to the Flutter build name/number;
  without them the simulator refuses to install). Its embed phase must stay
  before "Thin Binary".
- Opening the app from a share extension is not an official iOS API; the
  plugin's workaround is widely used. Fallback if it breaks: save from the
  extension and show a confirmation instead of switching apps.
- On a real iPhone the App Group must be registered under the Apple team.

## Data model
- `albums`: shared catalog; `musicbrainz_id` (release group) is unique and
  nullable for links that don't resolve; `created_by` marks albums added
  by hand, visible only to that user. Signed-in users read; only the
  `add-album` function adds, and there are no client edits or deletes.
- `shelf_entries`: one per user and album. Optional `rating` 1–10 (half
  stars), `comment`, `updated_at` set by a trigger; for albums added from a
  friend's shelf (M2), `added_from_user_id` (cleared if that account is
  deleted) and `added_from_name` (kept). RLS: only the owner
  reads and writes; friends' read access comes with M2.
- Tags (`tag_groups`, `tags`, `entry_tags`): user-defined
  groups, exclusive or multiple choice, sub-groups under a tag, built-in
  groups Collection and Listening shared in meaning across users; suggested
  groups created for each new user. Details: `docs/features/tags.md`.
- `shelf_filters` and `shelf_filter_tags`: the filter bar's filters, one tag
  or combined conditions (tags any/all, minimum rating or unrated, favorite
  tracks). Owner-only. Details: `docs/features/filters.md`.
- `entry_tracks`: the user's own track list of a shelf entry, with a
  `favorite` flag per track; replaced as a whole by `set_entry_tracks` (one
  transaction). Owner-only. Details: `docs/features/tracks.md`.
- pgTAP tests in `supabase/tests/`, run by `mise run test:db` and the `db`
  workflow (only Postgres is started).

## Environments
- **Local:** `supabase start`; the app defaults to it.
- **Staging:** a hosted Supabase project. The `staging` workflow deploys
  it after the `db` workflow passes on `main` (or by hand from `main`):
  `supabase db push` for migrations, `supabase config push` for auth
  settings and the sign-in email. `[remotes.staging]` in
  `supabase/config.toml` holds its project ID and overrides the local
  URLs. The web app on `main` (TASK-22) and Android test builds (TASK-23)
  use it.
- Staging sends Supabase's own sign-in emails: the free plan's built-in
  sender doesn't allow custom templates, so the workflow leaves ours out.
  The built-in sender only reaches members of the Supabase organization,
  a few emails an hour. Other testers and production need an SMTP sender
  (then the workflow pushes our template again).
- **CI minutes:** the repository is private, so Actions minutes are limited
  (2,000 a month on the free plan; used up on 2026-11-25). Workflows run on
  pull requests and on `main` only, a newer push cancels a pull request's
  run in progress, and the `android` build runs only when the native side
  can break (`app/android`, pubspec, `mise.toml`).
- **Android on staging:** the `android-staging` workflow builds a release
  APK against staging on every push to `main` that touches the app and
  publishes it as a GitHub release (`v1.0.<run>`). Obtainium on the phone
  watches the releases and installs updates. Signed with a staging-only key
  committed in `app/android/app/staging.jks`, so updates install over each
  other; Play Store releases get their own private key. Firebase App
  Distribution was the plan, but the account hit its project limit.
- **Test albums:** `supabase/dev/test_albums.sql` puts nine albums with
  ratings and built-in tags on one account's shelf, for trying the app and
  screenshots without adding albums one by one. Locally `mise run dev:albums -- <email>`; on
  staging the `staging-test-albums` workflow (by hand, email as input). The
  account must have signed in once; running it again changes nothing.
- **Production:** later, a second hosted project the same way.

One-time Android setup (TASK-23):
1. GitHub repository variable `SUPABASE_STAGING_PUBLISHABLE_KEY`
   (Supabase → Project Settings → API Keys; not secret).
2. On the phone: install Obtainium (GitHub or F-Droid). The repository is
   private, so create a fine-grained GitHub token with read-only "Contents"
   access to `Schwub/shelf` and enter it in Obtainium's settings (GitHub
   source). Then add the app with the URL `https://github.com/Schwub/shelf`.

One-time staging setup (TASK-21):
1. Supabase dashboard → New project `shelf-staging` (free plan; it pauses
   after a week without use). Keep the database password.
2. GitHub → repository Settings → Secrets and variables → Actions:
   repository secrets `SUPABASE_ACCESS_TOKEN` (Supabase → Account →
   Access Tokens; one for all projects) and
   `SUPABASE_STAGING_DB_PASSWORD`; repository variable
   `SUPABASE_STAGING_PROJECT_ID` (the project ref from its URL).
3. Add `[remotes.staging]` with that `project_id`, the staging web URL as
   `site_url` and the preview URLs as redirect URLs to
   `supabase/config.toml`, then run the `staging` workflow.
4. Repository variable `MUSICBRAINZ_CONTACT`: the contact MusicBrainz asks
   for (an email address). The `staging` workflow stores it as a function
   secret; the Android and web builds pass it to the app.

## Error reporting
Decided 2026-11-25 (TASK-11): **Sentry**, free plan, EU data region.
Considered: our own `app_errors` table in Supabase (no grouping, alerts or
readable release stack traces without building them) and self-hosted
GlitchTip (a server to run).
- `app/lib/errors.dart` is the only code that imports `sentry_flutter`.
  `main.dart` runs the app inside it; crashes and unhandled errors are
  reported, and screens report the errors they handle and show as
  "Couldn't …" (`reportError`), except a user's own mistakes (a link from
  another site, a broken link).
- Breadcrumbs: every HTTP request (MusicBrainz, covers) through
  `reportingClient`; failed answers aren't reported on their own.
- Privacy: `sendDefaultPii` off (no IP addresses, emails or bodies); the
  user is only their Supabase account ID.
- Settings: the `SENTRY_DSN` repository variable (a DSN only allows sending
  events, so it isn't a secret) passed with `--dart-define`; without it
  nothing is sent (local builds, tests). `SENTRY_ENVIRONMENT`: `staging`
  (Android staging builds), `production` and `preview` (web), `development`
  otherwise.
- Not yet: readable web stack traces need source maps uploaded with a
  Sentry auth token from the `web` workflow; GitHub issues from new errors
  (TASK-13).

## Web deploys
- The `web` workflow builds `flutter build web` in GitHub Actions and
  uploads it to Cloudflare Pages (project `shelf`) with Wrangler: `main`
  deploys to production, every PR to a preview alias
  (`<branch>.<project>.pages.dev`) that the workflow posts on the PR.
- Pages serves `index.html` for unknown paths (no `404.html`), so app
  routes and auth redirects work without extra config.
- The web build has no share target; sharing stays a phone feature.
- Until the `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` repository
  secrets exist, the workflow skips the deploy. One-time setup:
  1. Cloudflare dashboard → Workers & Pages → Create → Pages → Direct
     Upload, project name `shelf`.
  2. My Profile → API Tokens → Create Token → Custom, permission
     Account · Cloudflare Pages · Edit.
  3. GitHub → repository Settings → Secrets and variables → Actions: add
     both secrets (the account ID is on the dashboard's overview page).
- The web build reads the Supabase project from the repository variables
  `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` (Project Settings → API
  keys); without them it talks to a local Supabase. Auth URLs and the
  sign-in email come from `supabase/config.toml` via the `staging`
  workflow (see Environments).

## Decisions
- **2026-11-24 – Sign in with an emailed code and link.** The email
  carries a 6-digit code and a link. The code works on any device from
  day one, including when the mail is read on another device; the link
  works on the web now, and on phones once app links are set up.
  Considered: link only (needs app links on iOS and Android and signs in
  wherever the mail is opened), passwords (more to build and forget).
- **2026-11-22 – Flutter for the app.** One codebase for iOS, Android and
  web; the author knows Dart; mature share-intent plugins.
  Considered: Compose Multiplatform (web still beta, community Supabase
  SDK, iOS share extension still needs Swift); web-only PWA (no share
  target on iOS).
- **2026-11-22 – Supabase as the backend.** Database, auth and access rules
  in one service, free tier for a hobby, official Flutter SDK. Considered:
  Firebase, an own backend (not evaluated in detail).
- **2026-11-22 – MusicBrainz for album data.** Free and open; Cover Art
  Archive for artwork.
- **2026-11-22 – Music (albums) first.** Other media types come after the
  first version.
- **2026-11-23 – `receive_sharing_intent` for share-to-add.** The system share
  sheet on iOS (share extension) and Android (`SEND` intent filter) hands
  links to the app. The only share plugin with Swift Package Manager support
  (the app has no CocoaPods); Apache-2.0, maintained. Considered: own native
  code (same Xcode setup, ~150 lines of Kotlin/Swift more), `share_handler`
  (CocoaPods only, last release 2025).
- **2026-11-24 – Generic tags instead of fixed statuses.** Tag groups,
  tags and a join table, with the rules (one tag per exclusive group,
  sub-tags need their parent, built-ins can't be deleted, owner only)
  enforced in Postgres. Works for every media type. Considered: tag IDs as
  an array on the entry (rules only via triggers, stale IDs), text labels
  (renaming rewrites every item). See `docs/features/tags.md`.
- **2026-11-23 – Visual system "subtle 80s".** Warm surfaces with a few
  cues (teak shelf lines, cassette-recorder keys in 3D seen from the bottom
  right, a filter bar with labels above its keys, wide Archivo type, light
  windows, five-bar rating meter, amber-to-coral accent), one control (the
  44 px key, 4 px corners; pressed keys sit lower, never sunk in), evening
  and daylight themes; see `docs/design/visual-system.md`. Considered: a
  top-down flat key (calmer, but loses the tactile feel), piano keys seen
  from the front (inconsistent with the other keys). Considered: five
  earlier directions in `docs/design/visual/` (staff picks, crate digging,
  inner sleeve, cover light, literal 80s hi-fi): too playful, too modern or
  too literal.
- **2026-11-23 – Cloudflare Pages for the web app.** Free, unlimited
  static bandwidth with no usage cap that pauses the site, a preview URL per
  branch, and the build stays in GitHub Actions so the host is replaceable.
  Pages rather than Workers static assets (Cloudflare's suggestion for new
  projects): Pages' branch preview aliases are mature and the deploy action
  returns them; moving a static site to Workers later is small.
  Considered: Firebase Hosting (PR previews built in, but ~360 MB/day
  transfer on the free plan), Netlify (free credits run out and pause the
  site), Vercel (Hobby is non-commercial), GitHub Pages (needs a paid plan
  for a private repository, no previews).
- **2026-11-22 – Backlog.md for tasks.** Markdown files in `backlog/`, a CLI
  that works offline in the agent sandbox, no auto-commits. Considered: the
  First steps list in project.md (too thin for three milestones), GitHub
  Issues (needs a token in the sandbox).

## Keep simple
- Visibility rules live in row-level security, not duplicated in app code.
- Model albums only; generalize the schema when the second media type
  arrives, not before.
- Edge functions only for what the client can't do (secrets, CORS).
- The feed is a query over friends' recent shelf changes; no separate
  event system until it is needed.
