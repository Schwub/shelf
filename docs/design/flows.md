# User flows (M1)

M1 covers core use cases 1 and 2 from `docs/project.md`: add an album by
search or by sharing a link, and give it tags, a rating and a comment.
Tags are designed in [../features/tags.md](../features/tags.md); their
flows are at the end of this file.
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

Done: the album is on the shelf with any tags chosen, and the user is
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
  add -- optional tags, rating and comment --> save{Saved?}
  save -- yes --> back([My shelf + snackbar: Added to your shelf · View])
  save -- error --> saveErr[Error on the entry screen: Couldn't save. Try again.] --> add
  add -- back / cancel --> results
  search -- back --> shelf
```

## Add by sharing a link

Done: the shared album is on the shelf.

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
  add -- optional tags, rating and comment → Save --> done([My shelf + snackbar: Added to your shelf])
  add -- Cancel --> shelf([My shelf])
```

## Tags, rating and comment

Done: the change is saved and visible on the shelf.

```mermaid
flowchart TD
  shelf([My shelf]) -- taps album --> edit[Album entry: edit, current values filled in]
  edit -- changes tags, rating or comment → Save --> saved{Saved?}
  edit -- Genre: Add --> sheet[Add tags: search, tick] -- no match → Create “…” --> sheet
  sheet -- Done --> edit
  edit -- Edit tags --> editor([Tag group])
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
  view -- filter key, e.g. Own --> filtered{Matches?}
  filtered -- none --> fempty[No albums marked Want yet. Show all]
  filtered -- some --> view
  view -- grid / list toggle --> view
```

## Tag editor

Done: the user's groups and tags are as they want them, and every album
screen and filter reflects the change.

```mermaid
flowchart TD
  menu([⋮ Tags, or Edit tags on an album: its unsaved changes are kept]) --> list[Tags: groups in order, built-ins marked]
  list -- loading --> lskel[Placeholder rows]
  list -- error --> lerr[Couldn't load your tags. Try again.]
  list -- New group --> newg[Tag group: new, name empty]
  list -- group --> group[Tag group]
  newg -- name, one or several per album, tags → Create group --> saved{Saved?}
  group -- rename / reorder / add tag / change type, saved at once --> saved
  saved -- yes --> list
  saved -- empty name --> nameErr[Give the group a name.] --> group
  saved -- name already used --> dupErr[You already have a group called “Mood”.] --> group
  saved -- error --> sErr[Couldn't save. Try again.] --> group
  group -- One per album, but albums have several --> exErr[3 albums have more than one Mood tag: list. Change them first.] --> group
  group -- tag → Add sub-group --> sub[Tag group: new, under that tag] --> saved
  group -- tag → Delete --> tdel{Delete “Rock”? Says how many albums, and any sub-group and filters that go too}
  tdel -- Delete --> group
  tdel -- Cancel --> group
  group -- Delete group --> gdel{Delete “Mood”? Its 6 tags are on 41 albums; 1 filter goes too}
  gdel -- Delete --> list
  gdel -- Cancel --> group
  group -- built-in --> builtin[No delete; note: Built-in groups can be renamed or hidden. Friends' shelves use them to compare.]
  builtin -- Hide --> list
```

Notes: changes save immediately; deletes ask first and take effect at once.
Tag names are unique within a group, ignoring case, and can't be empty;
the same inline errors apply to tags. Deleting a tag also deletes the
sub-group under it and any filter on it. Sub-groups go one level deep.
Only built-in groups can be hidden.

## Filters

Done: the filter bar shows the chosen filters in the chosen order.

```mermaid
flowchart TD
  menu([⋮ Filters]) --> list[Filters: All first, then the chosen ones with reorder handles]
  list -- loading --> skel[Placeholder rows]
  list -- error --> err[Couldn't load your filters. Try again.]
  list -- remove --> list
  list -- drag --> list
  list -- Add filter --> pick[Picker: all tags by group, already chosen ticked]
  pick -- tag --> list
  list -- none chosen --> empty[Only All. Add filters to sort your shelf quickly.]
  list -- Done --> shelf([My shelf: bar updated, scrolls after five])
```

## Add from a friend (M2)

Done: the album is on the user's shelf with the friend's tags they chose to
copy; copies are ordinary, editable tags.

```mermaid
flowchart TD
  friend([Friend's shelf: album]) -- Add to my shelf --> entry[Album entry: add; built-in tags pre-set from the friend]
  entry --> missing{Friend has tags you don't?}
  missing -- no --> entry
  missing -- yes --> sheet[Import tags sheet: missing tags ticked, grouped]
  sheet -- Add selected --> entry2[Album entry with the tags; new groups and tags created]
  sheet -- Skip --> entry
  entry2 -- Add to shelf --> done([My shelf + snackbar: Added to your shelf])
  sheet -- error --> err[Couldn't copy the tags. Try again.] --> sheet
```

Notes:
- Built-in tags match by their key and are never asked about.
- Other tags match by group and tag name, ignoring case.
- If your group of the same name is "several" while the friend's is "one",
  your group's type wins.
- A tag in a sub-group whose parent tag you don't have brings the parent
  along, ticked together.
- A match in a hidden built-in group is applied and stays hidden.
- A copied new group takes the friend's type (one or several per album).
- Copies stay even if the user then cancels adding the album.
- The album remembers whose shelf it came from: "Added from Anna's shelf"
  under the artist, kept even if Anna's account is deleted.
