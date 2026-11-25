# Add albums by sharing a link (TASK-7)

Status: built (TASK-7). Decisions from 2026-11-25: a server function
resolves links (no Spotify developer app); albums MusicBrainz doesn't know
go to "Add it yourself", prefilled from the page, cover included.

## Goal
Share an album from Spotify or Bandcamp to shelf and land on its album
entry, ready to add. Flow: [../design/flows.md](../design/flows.md), "Add
by sharing a link".

## How a link is resolved
The `resolve-link` function (`supabase/functions/resolve-link/`), signed-in
users only:
1. `link.ts` reads what the link points to: `open.spotify.com/{album,
   track, playlist, artist}/<id>` (locale and `?si=` dropped),
   `<name>.bandcamp.com/album|track/<slug>`. `spotify.link` short links
   are followed first. Other sites: 400.
2. Albums: MusicBrainz URL lookup (`/ws/2/url?resource=…`, the release
   MusicBrainz links to that page, then its release group).
3. Otherwise the page's metadata (Spotify `og:title` "Listen to … - Album
   by … | Spotify" and `og:description`, Bandcamp's JSON-LD) and a
   MusicBrainz search by title, artist and type. The type keeps the single
   of the same name out.
4. Still nothing: `unknown` with the page's title, artist, year and cover
   URL.

MusicBrainz allows one request per second, so the function spaces its up
to three requests and backs off twice on a 503. Measured on 20 real links: 19
resolved (docs/project.md, Risks).

## App
- `SharedLinkInbox` (`app/lib/share/`) holds the latest shared link from
  app start; My shelf takes it once the shelf has loaded, so a link that
  launches the app signed out waits through the sign-in.
- `ResolvePage`: "Finding album…" with the link, then:
  - found, not on the shelf: the album entry to add;
  - found, on the shelf: its entry, with "Already on your shelf";
  - unknown: "Add it yourself", prefilled. The app downloads the page's
    cover and adds it like a picked photo, so `add-album` needs no new
    input;
  - track, playlist or artist: says so, offers the search;
  - other sites, broken links: says so, offers the search;
  - errors: Try again.
- Tests: Deno tests with recorded page snippets and MusicBrainz shapes;
  widget tests with a fake resolver. No live network.
