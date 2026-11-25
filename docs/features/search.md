# Add albums by search (TASK-8)

Status: design, waiting for approval.

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
2. **Search** queries MusicBrainz directly from the app, 300 ms after
   typing stops. It shows cover, title, artist and year; albums already on
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
  about one request per second per IP. The 300 ms pause and one request in
  flight keep a single user well below that.
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
  on the shelf, no results, network error and Try again, the 300 ms pause,
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

## Open questions
1. **User-Agent contact for MusicBrainz:** an email address or a URL that
   MusicBrainz can use to reach us if the app misbehaves.
2. **Dropping the albums insert policy** (schema change): OK?
3. **Deploying the function from the staging workflow** (the project rules
   say to ask before `functions deploy`): OK for staging?
