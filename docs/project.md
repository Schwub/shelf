# shelf

## Goal
An app to catalog everything that used to stand on a shelf (music first;
later videos, movies, books and board games) and to see what friends have
on theirs. The point is one app for all media plus discovering what friends
like.

## Users
First: the author and a group of friends, on iPhone and Android.
Later: published for everyone.

## Problem and alternatives
Today each media type lives in its own service: Discogs for record
collections, Rate Your Music or Album of the Year for album ratings,
Goodreads for books, Letterboxd for movies, BoardGameGeek for board games.
None of them covers everything, and seeing what friends like means
following them in each one. shelf puts all media in one place, and social
discovery is the core feature, not an extra.

## Core use cases
1. Add an album by searching or by sharing a link (Spotify, Bandcamp) from
   another app.
2. Give an album a status (e.g. own, want, listened), a rating and a comment.
3. Invite a friend with a link and view their shelf.
4. See a feed of what friends add and rate.
5. Import a Bandcamp collection.

## Done means
The first version is done when M2 works: on iPhone and Android, users can
add albums (search or share), set status, rating and comment, invite
friends, view friends' shelves and read the feed.

## Out of scope
For the first version:
- Media other than albums (no tracks, artists, playlists, movies, books, games).
- Likes, replies, recommendations, notifications.
- Public profiles, user search, a public launch.
- Imports other than Bandcamp. A Spotify import was dropped on 2026-11-23:
  development mode caps it at 5 users, and sharing from Spotify covers the
  need.

## Constraints
- Private hobby project, no deadline.
- Free tiers only (Supabase free tier) while it is a hobby.
- Friends' activity is personal data; GDPR applies at the latest at the
  public launch.

## Stack
Flutter (Dart) app for iOS, Android and web, with Supabase as the backend
(Postgres, auth, row-level security, edge functions). Album data from
MusicBrainz and the Cover Art Archive.
Why: one codebase for both phones and the web, the author knows Dart,
share-to-add works on both phones through a plugin, and Supabase has an
official Flutter SDK. Details and alternatives in
[architecture.md](architecture.md).

## Interface
Mobile app (iOS, Android) with a share target to receive links from other
apps; the same Flutter app runs on the web.

## Success measures
One month after friends get access: at least 5 friends have each added 20
or more albums and look at the feed every week.

## Risks and assumptions
- **Resolving shared Spotify links.** Share-to-shelf from Spotify is the
  most important way to add albums. Assumption: a shared link resolves
  without a Spotify developer app, through MusicBrainz's URL lookup (it
  stores Spotify album links) with Spotify's public oEmbed or page metadata
  as a fallback. Test: look up a few real shared links in M1 and measure how
  many MusicBrainz finds. The Web API is the last resort: its development
  mode (checked 2026-11-23) allows only 5 users and needs a Premium owner.
- **Bandcamp has no public API for a fan's collection.** Assumption: a shared
  album link can be resolved from the page's metadata (title, artist,
  artwork). Importing a whole collection means reading the public
  collection page, which is fragile. Test: a small spike on both before M3.
- **Share-to-add on iOS** needs a share extension. Test: spike it on both
  phones at the start of M1.
- **Supabase free tier** pauses projects after about a week without activity.
  Acceptable for a hobby project; revisit before the public launch.

## Milestones
- **M1 – own shelf:** add albums (search or share), status, rating, comment,
  on iPhone and Android.
- **M2 – friends:** invite links, friends' shelves, activity feed.
  First version done.
- **M3 – imports:** Bandcamp collection.
- **Later:** public launch, then other media types.

## Open questions
- Record the format (vinyl, CD, digital) per album?
- Which statuses exactly (own, want, listened, …)?
- Rating scale (e.g. 1–5, half steps)?
