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
  - Auth for accounts.
  - Row-level security decides who sees what: your own shelf, and your
    friends' shelves and activity.
  - Edge functions (TypeScript) for work the app can't do itself: Spotify
    OAuth and import, and resolving a shared link (Spotify, Bandcamp) to
    album data.

## Share-to-add
- `app/lib/share/share_receiver.dart` is the only code that imports the
  plugin; it yields the link that launched the app, then links shared while
  it runs. `shared_link.dart` takes the first http(s) URL from shared text
  (Spotify shares a sentence ending in the URL).
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

## Decisions
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
- **2026-11-22 – Backlog.md for tasks.** Markdown files in `backlog/`, a CLI
  that works offline in the agent sandbox, no auto-commits. Considered: the
  First steps list in project.md (too thin for three milestones), GitHub
  Issues (needs a token in the sandbox).

## Keep simple
- Visibility rules live in row-level security, not duplicated in app code.
- Model albums only; generalize the schema when the second media type
  arrives, not before.
- Edge functions only for what the client can't do (secrets, CORS, OAuth).
- The feed is a query over friends' recent shelf changes; no separate
  event system until it is needed.
