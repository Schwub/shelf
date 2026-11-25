# Track lists and favorite tracks (TASK-27)

Status: built (TASK-27). Decisions from 2026-11-25: tracks from
MusicBrainz, used only once the user approves them; tracks can be entered
by hand for any album; track lists belong to the user's own entry, not the
shared catalog.

## Goal
See an album's tracks on its entry and mark the favorites.

## Where the track list comes from
- **MusicBrainz**, asked by the app itself like the search
  (`app/lib/tracks/track_source.dart`): the official releases of the
  release group, then the earliest release with the track counts most of
  them share. That is the original album, not a deluxe edition with a
  bonus disc (OK Computer: 39 official releases, 12 tracks). Two requests,
  through the app's shared MusicBrainz connection (paced, 503 retried;
  docs/features/search.md).
- **By hand**: "Enter tracks" / "Edit tracks" opens the track editor (add,
  rename, reorder, remove; empty tracks are left out). Favorites and
  lengths stay with their track; a moved track joins the disc of the track
  above it, and tracks are numbered again disc by disc.

## Flow on the album entry
- Adding an album from MusicBrainz (search or a shared link) looks up its
  track list right away and shows it as a suggestion: "Track list from
  MusicBrainz: 12 tracks", with **Use it** or **Not this one**. Nothing is
  used until approved.
- Albums without a track list (added before this, or the lookup failed or
  was declined) show "No track list yet." with **Get track list**; a failed
  lookup offers Try again; "MusicBrainz has no track list" when it has none.
  Albums added by hand only offer Enter tracks.
- Tracks show number, title, length and a star; disc headings when there's
  more than one disc. Lists longer than 12 show the favorites (or the first
  five) until "Show all N tracks".
- The track list and favorites are part of the entry's draft and save with
  Save (or Add to shelf), like tags and rating.

## Data
`entry_tracks` (migration `20261126090000_entry_tracks.sql`): entry, disc,
position, title, optional length, favorite. Owner-only; the entry must be
the user's own; deleted with the entry. `set_entry_tracks(entry, tracks)`
replaces the list in one transaction, so a failed save keeps the old one.
pgTAP: `supabase/tests/entry_tracks_test.sql`.

## Later
- Friends see favorite tracks on shared shelves (M2).
- Look up the track list of an album added by hand once MusicBrainz has it.
