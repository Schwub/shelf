# Add albums by search (TASK-8)

Status: built (TASK-8). Decisions from 2026-11-25: covers in our own
Storage, only the function adds albums, the function deploys to staging,
`http` for the app's requests, MusicBrainz contact from a setting.

## Goal
Find an album on MusicBrainz, see its cover, and add it to the shelf with a
rating and comment (tags: TASK-16). The cover is copied once into our own
Supabase Storage, so the shelf doesn't depend on the Cover Art Archive.

## Acceptance criteria
From TASK-8:
1. Searching shows matching albums with artist, year and cover.
2. Choosing a result creates a shelf entry.
3. Tests cover results, no results and network errors.
4. The cover of a newly added album is copied once into the `covers` bucket
   and `albums.cover_url` points to our copy.
5. Users can read covers but can't write or replace them; only the server
   function stores them (tested).
6. An album without a cover, or a failed download, still gets added and
   shows the blank cover.

## Flow
As in [../design/flows.md](../design/flows.md), "Add by search":
1. My shelf gets the "Add album" key in its bottom bar, which opens Search.
2. **Search** queries MusicBrainz directly from the app, 500 ms after
   typing stops, with a spinner in the field from the first letter. It
   shows cover, title, artist and year; albums already on
   the shelf are marked. States: idle, loading, results, no results, error
   with Try again.
3. Tapping a result opens the **Album entry in add mode**. It is the same
   screen as edit, with "Add to shelf" instead of Save and no Remove. An
   album already on the shelf opens in edit mode instead.
4. **Add to shelf** calls the server function `add-album` with the
   MusicBrainz ID. The function returns the album, and the app then creates
   the shelf entry with rating and comment. Back on the shelf, a snackbar
   says "Added to your shelf".

## Search (in the app)
- MusicBrainz web service:
  `GET https://musicbrainz.org/ws/2/release-group?query=<q> AND primarytype:album&fmt=json&limit=25`.
- Each result: release group ID, title, artist credit, first release year.
- MusicBrainz asks every client for a User-Agent with a contact and allows
  about one request per second per IP, answering 503 beyond that. The
  pause alone (then 300 ms) wasn't enough: typing with short pauses got 503s,
  shown as errors (fixed 2026-11-25, TASK-33). All MusicBrainz requests now
  go through `app/lib/search/musicbrainz.dart`: one at a time, at most one
  per 1.1 s, a 503 tried again twice, and a search replaced by a newer one
  dropped before it's sent. Shared mobile IPs make 503s more likely, and
  MusicBrainz is stricter with clients that send no contact
  (`MUSICBRAINZ_CONTACT`).
- Thumbnails in the results come straight from the Cover Art Archive
  (`/release-group/<id>/front-250`). Only added albums are copied.
- Web: browsers don't let the app set the User-Agent. MusicBrainz still
  answers, and the web app is a secondary target.

## The server function `add-album`
A Supabase Edge Function (TypeScript, `supabase/functions/add-album`),
called by signed-in users only.
1. If an album with that `musicbrainz_id` exists, return it. Albums are
   shared, so the second user who adds an album gets the same row and cover.
2. Otherwise fetch the release group from MusicBrainz (title, artist, year).
   It doesn't trust what the app sends.
3. Fetch `front-500` from the Cover Art Archive and store it as
   `covers/<album id>.jpg`. No cover (404) or a failed download leaves
   `cover_url` empty, and the album is still added.
4. Insert the album with the service role and return it.
5. An album whose `cover_url` is empty gets another cover attempt the next
   time someone adds it.

## Storage and access
- Bucket `covers`, public for reading (covers are not private). It is created
  by a migration, so `db push` creates it on staging too.
- No insert, update or delete policies for signed-in users on
  `storage.objects` in that bucket: only the function (service role) writes.
- Albums: today any signed-in user can insert albums. With the function, the
  app no longer needs to, so that policy is dropped and only the function
  adds albums. That keeps the shared catalog clean.
- pgTAP tests: users read covers, can't upload or replace them, and can't
  insert albums.

## Tests
- App (widget tests with a fake search and fake function): results, already
  on the shelf, no results, network error and Try again, the pause,
  add mode saving, add errors.
- Function (Deno tests with recorded MusicBrainz and Cover Art Archive
  responses): new album with cover, existing album, no cover, failed
  download, MusicBrainz error.
- MusicBrainz is blocked from the cloud session that builds this, so real
  searches are tested on the phone against staging.

## Deploying
- The `staging` workflow also deploys the function
  (`supabase functions deploy add-album`) after the migrations.
- The function needs no secrets beyond what Supabase gives every function.

## Settings
- `MUSICBRAINZ_CONTACT` (GitHub repository variable): the contact
  MusicBrainz asks for. The staging workflow stores it as the function's
  secret; the Android and web builds pass it with `--dart-define`. Without
  it, requests go out as plain `shelf/1.0`, which MusicBrainz throttles
  sooner.

## Verified
- Against local Supabase, running the function with Deno: an existing album
  is returned and its missing cover copied (a 500 × 500 JPEG, about 85 KB);
  a new album is fetched from MusicBrainz, added and its cover stored; a
  bad ID gives 400; a throttled MusicBrainz (503) gives 502 and adds
  nothing (now retried once first).
- The local edge runtime container can't load npm packages in the cloud
  session (its network proxy isn't trusted there); hosted Supabase and CI
  are not affected.

## Albums added by hand (TASK-26)
For albums MusicBrainz doesn't have (decision 2026-11-25).
- **Where:** "Add it yourself" under the search results and in the
  no-results state. It opens a form: title and artist (required), year,
  and a cover from a photo (camera or gallery, `image_picker`, scaled to
  500 px). Then the album entry in add mode, as for search results.
- **Adding:** the app sends `{ title, artist, year, cover }` (cover as a
  base64 JPEG or PNG, at most 2 MB) to `add-album`. The function checks the
  fields, inserts the album with `created_by` = the caller and no
  `musicbrainz_id`, and stores the cover as `covers/<album id>.jpg`. Only
  the function writes albums and covers, as before.
- **Visibility:** albums with `created_by` are readable only by their
  creator (friends' shelves come in M2). MusicBrainz albums stay readable by
  every signed-in user. A check keeps exactly one of `musicbrainz_id` and
  `created_by` set.
- **Not yet:** editing an album's details after adding it.
