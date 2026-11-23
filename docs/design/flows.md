# User flows (M1)

M1 covers core use cases 1 and 2 from `docs/project.md`: add an album by
search or by sharing a link, and give it a listening and/or collection
status (with formats when owned), a rating and a comment.
Screens are listed in [screens.md](screens.md).

## Sign in (email magic link)

Done: the user is signed in and sees their shelf; they stay signed in
across app restarts.

```mermaid
flowchart TD
  open([Open app]) --> session{Signed in?}
  session -- yes --> shelf([My shelf])
  session -- no --> signin[Sign in: enter email]
  signin --> valid{Valid email?}
  valid -- no --> invalidErr[Inline error: Enter a valid email address] --> signin
  valid -- yes --> send[Send link: button shows progress]
  send --> sent{Sent?}
  sent -- no network / server error --> sendErr[Error: Couldn't send the link. Check your connection and try again.] --> signin
  sent -- yes --> check[Check your email]
  check -- Resend, after 60 s countdown --> send
  check -- Use a different email --> signin
  check -- taps link in email --> deep{Link valid?}
  deep -- yes --> shelf
  deep -- expired or used --> linkErr[Sign in: This link has expired. Send a new one.] --> signin
```

Notes:
- The link signs in on the device where it is tapped. If the user opens the
  mail on another device, they sign in there; the check-email screen says so.
- A pending shared link (see "Add by sharing") survives the sign-in and
  continues afterwards.
- Sign out lives in the shelf's overflow menu and asks for confirmation.

## Add by search

Done: the album is on the shelf with the chosen status, and the user is
back on the shelf with confirmation.

```mermaid
flowchart TD
  shelf([My shelf]) -- Add album --> search[Search: field focused, hint text]
  search -- types, 300 ms pause --> loading[Results loading]
  loading --> res{Result?}
  res -- matches --> results[Results: cover, title, artist, year]
  res -- none --> none[No albums found for 'query'. Check the spelling or try the artist's name.]
  res -- error / offline --> err[Couldn't search. Check your connection.] -- Try again --> loading
  none -- edits query --> loading
  results -- taps album already on shelf --> edit([Album entry: edit])
  results -- taps album --> add[Album entry: add]
  add -- chooses listening and/or collection status, optional formats, rating and comment --> save{Saved?}
  save -- yes --> back([My shelf + snackbar: Added to your shelf · View])
  save -- error --> saveErr[Error on the entry screen: Couldn't save. Try again.] --> add
  add -- back / cancel --> results
  search -- back --> shelf
```

## Add by sharing a link

Done: the shared album is on the shelf with the chosen status.

```mermaid
flowchart TD
  ext([Spotify / Bandcamp: Share → shelf]) --> app[shelf opens, cold or warm start]
  app --> session{Signed in?}
  session -- no --> signin([Sign in flow, link kept pending]) --> resolving
  session -- yes --> resolving[Album entry: Finding album… with the shared link shown]
  resolving --> kind{Result}
  kind -- album found --> onshelf{Already on shelf?}
  onshelf -- no --> add[Album entry: add]
  onshelf -- yes --> edit([Album entry: edit, note: Already on your shelf])
  kind -- track, playlist or artist link --> notAlbum[That's a track link. shelf adds whole albums: share the album instead, or search.] -- Search --> search([Search, prefilled when the title is known])
  kind -- not found --> notFound[Couldn't find this album. Search for it instead?] -- Search --> search
  kind -- error / offline --> err[Couldn't load the album. Check your connection.] -- Try again --> resolving
  add -- chooses listening and/or collection status, optional formats, rating and comment → Save --> done([My shelf + snackbar: Added to your shelf])
  add -- Cancel --> shelf([My shelf])
```

## Status, rating and comment

Done: the change is saved and visible on the shelf.

```mermaid
flowchart TD
  shelf([My shelf]) -- taps album --> edit[Album entry: edit, current values filled in]
  edit -- changes status, rating or comment → Save --> saved{Saved?}
  saved -- yes --> back([My shelf, updated])
  saved -- error --> err[Couldn't save. Try again.] --> edit
  edit -- back with unsaved changes --> discard{Discard changes?}
  discard -- Discard --> shelf
  discard -- Keep editing --> edit
  edit -- Remove from shelf --> back2([My shelf + snackbar: Removed · Undo])
```

## My shelf: browsing

Done: the user finds an album on their shelf.

```mermaid
flowchart TD
  shelf([My shelf]) --> state{Entries?}
  state -- loading --> skeleton[Placeholder covers]
  state -- none --> empty[Empty: Your shelf is empty. Search for an album or share one from Spotify or Bandcamp.]
  state -- error --> err[Couldn't load your shelf. Try again.]
  state -- some --> view[Grid or list, as last chosen]
  view -- filter chip Own / Want / Want to listen / Listened --> filtered{Matches?}
  filtered -- none --> fempty[No albums marked Want yet. Show all]
  filtered -- some --> view
  view -- grid / list toggle --> view
```
