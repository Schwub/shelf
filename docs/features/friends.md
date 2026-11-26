# Friends and the feed (M2)

Core use cases 3 and 4 from `docs/project.md`: invite a friend with a link,
view their shelf, and read a feed of what friends add and rate. With M2 the
first version is done.

UX: flows in [../design/flows.md](../design/flows.md) (M2 section), screens
and navigation in [../design/screens.md](../design/screens.md), wireframes
[friends](../design/wireframes/friends.html),
[friend's shelf](../design/wireframes/friend-shelf.html),
[feed](../design/wireframes/feed.html). Agreed 2026-11-26.

## Acceptance criteria
1. **Names:** after the first sign-in the user sets the name friends see
   (1–40 characters, not unique); it can be changed under Friends.
2. **Invite:** Friends → Invite a friend creates an invite with a link
   (`<web app>/invite/K7Q2-M9XD`) and the code, shared through the system
   share sheet or copied. An invite works once, for 7 days, and can be
   cancelled while it waits.
3. **Accept:** the link (web) or Friends → Enter code (any app) leads,
   after sign-in and naming, to "Anna invited you": Accept makes both
   friends at once. Expired, used, cancelled, own and already-friends
   invites and wrong codes say so.
4. **Friends:** the list shows each friend's name and album count; removing
   one asks first and ends access both ways. Albums added from them stay.
5. **A friend's shelf:** read-only, covers or list, built-in filters only;
   their album shows their rating, comment, tags and favorite tracks, with
   Add to my shelf (TASK-19 imports their tags) or Open on your shelf.
6. **Feed:** friends' albums added and ratings set or changed, newest
   first, one rating item per album and friend, paged as the user scrolls,
   pull to refresh; each item opens the friend's album.
7. **Hide from friends:** a switch on the album entry; hidden entries are
   marked on My shelf, invisible to friends and absent from the feed.
8. **Navigation:** a bar with Shelf, Feed and Friends; each tab keeps its
   own back stack.
9. **Privacy:** only friends read a user's profile, shelf, tags, tracks and
   manual albums, never hidden entries; strangers and removed friends see
   nothing. Enforced by row-level security and tested with pgTAP.

## Design

### Data (Postgres)
- `profiles`: `user_id` (pk, default `auth.uid()`, cascades with the
  account), `name` text, 1–40 characters after trimming. Read by the owner
  and their friends; insert and update by the owner (column grants).
- `friendships`: two rows per friendship, `(user_id, friend_id)` and the
  reverse, plus `created_at`. Read by `user_id`; written only by
  `accept_invite` and `remove_friend` (security definer), so both rows
  always exist together.
- `invites`: `code` (pk, 8 characters from an alphabet without 0/O/1/I/L,
  shown as `XXXX-XXXX`, case-insensitive), `inviter` (default
  `auth.uid()`), `created_at`, `expires_at` (+7 days), `accepted_by`,
  `accepted_at`. The owner reads and deletes (cancels) their own; created
  by `create_invite()`.
- Functions (security definer, `search_path` set, executable by
  `authenticated` only):
  - `is_friend(other uuid) returns boolean`, stable; used by policies.
  - `create_invite() returns text`: a new code; retries on collision.
  - `invite_preview(code) returns (status, inviter_name)`: status is
    `valid`, `gone` (expired or used), `own`, `friends` or
    `unknown` (also a cancelled one, which is deleted); the Invitation
    screen shows it before Accept.
  - `accept_invite(code) returns uuid` (the inviter): checks as above,
    then writes both friendship rows and marks the invite used, in one
    transaction; raises a named error otherwise. Needs the accepter's
    profile.
  - `remove_friend(friend uuid)`: deletes both rows.
- `shelf_entries`: new `hidden boolean not null default false` and
  `rated_at timestamptz`, set by a trigger when `rating` changes (null
  when cleared). `created_at` and `rated_at` are set by the database only
  (column grants), which closes the tech-debt item about client-set
  timestamps.
- Friends' read access, added to the existing owner policies:
  - `shelf_entries`: `is_friend(user_id) and not hidden`.
  - `entry_tags`, `entry_tracks`: the entry is a friend's and not hidden
    (an `exists` on `shelf_entries`, which applies its policy).
  - `tags`, `tag_groups`: `is_friend(user_id)` (needed to show their tag
    names; filters stay owner-only).
  - `albums`: also `created_by` is a friend (manual albums).
  - `profiles`: `is_friend(user_id)`.
- `feed` view (`security_invoker`, so the caller's RLS applies): one row
  per friend entry for "added" (`at = created_at`) and one for "rated"
  (`at = rated_at`, rating not null), with the friend's name, the album and
  the rating; `where user_id <> auth.uid()`. The app pages with
  `order by at desc, entry_id` and `lt` on the last row's `at` (keyset).
  An index on `shelf_entries (user_id, created_at)` and `(user_id,
  rated_at)` keeps it fast.

### App (`app/lib/`)
- **Own data must filter by owner.** Today the shelf, tags, filters and
  settings queries rely on RLS alone. With friends able to read, every own
  query adds `.eq('user_id', me)` (filters and settings stay owner-only but
  get it too, for one rule everywhere). An integration test signs in two
  friends and checks each sees only their own shelf on My shelf.
- `friends/`: `FriendsRepository` (my profile, save name, create, preview,
  accept and cancel invites, list friends with album counts and waiting
  invites, remove) with `SupabaseFriendsRepository` and a test fake;
  screens Your name, Friends, Invite sheet, Enter code, Invitation.
- `feed/`: `FeedRepository` (`page(before)`) with Supabase version and fake;
  the Feed screen.
- A friend's shelf: `ShelfRepository.loadFriend(String userId)` returns a
  `Shelf` through the same parsing as `load()`; `FriendShelfPage` and
  `FriendAlbumPage` reuse `CoversView`, `AlbumsListView` and the filter bar.
- Home shell (`home/home_page.dart`): `NavigationBar` with Shelf, Feed,
  Friends; an `IndexedStack` of one `Navigator` per tab so each keeps its
  back stack; system back pops the current tab first. No routing package.
- The auth gate adds a step: signed in without a profile → Your name.
- Invite links: on the web, `main.dart` reads `/invite/<code>` from
  `Uri.base` into a `PendingInvite` notifier (like `SharedLinkInbox`); the
  shell shows Friends, which opens the Invitation once signed in and
  named, then clears it. The code is kept in `shared_preferences`, since
  signing in by the emailed link reloads the app at its start page. Links
  use the web app's own origin on the web, else `--dart-define=SITE_URL`
  (default `https://shelf.pages.dev`, staging's `site_url`). Phones use the code until app links
  exist (TASK-20, web deploys TASK-22).
- Share sheet: the invite message goes through the platform share sheet
  (`share_plus`, BSD-3, Flutter Community; agreed 2026-11-26; supports
  Swift Package Manager). Copy link uses the clipboard.

### Errors
Each screen shows the wireframes' "Couldn't …" states and reports the
error (`reportError`), except a user's own mistakes (wrong or used codes),
following `docs/architecture.md`, "Error reporting". `accept_invite` errors
map to the Invitation screen's states by their error code.

## Test plan
- pgTAP: each table's policies from the owner's, a friend's, a stranger's
  and a removed friend's side; hidden entries and their tags and tracks
  invisible to friends; every invite status; both friendship rows created
  and removed together; `rated_at` and `created_at` not settable by
  clients; the feed view's rows and order.
- Integration (`app/test_integration/`): two signed-in users become friends
  by invite; each one's own shelf excludes the other's albums; a friend's
  shelf and the feed show what they should; hiding and removing take
  effect.
- Unit and widget tests with fakes: every screen state in the wireframes;
  the navigation shell (tabs keep their stacks); the pending invite after
  sign-in; accessibility guidelines on the new screens, as in
  `shelf_page_test.dart`.

## Plan
One task and pull request each, in this order:
1. TASK-35: names and the navigation shell.
2. TASK-36: invites and friends (list, invite, accept, remove).
3. TASK-37: a friend's shelf and album; hide an entry from friends.
4. TASK-38: the feed.
5. TASK-19: import a friend's tags (any time after TASK-37).
