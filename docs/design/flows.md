# User flows (M1)

M1 covers core use cases 1 and 2 from `docs/project.md`: add an album by
search or by sharing a link, and give it tags, a rating and a comment.
Tags are designed in [../features/tags.md](../features/tags.md); their
flows are at the end of this file.
Screens are listed in [screens.md](screens.md).

## Sign in (emailed code or link)

Done: the user is signed in and sees their shelf; they stay signed in
across app restarts. A new email signs up in the same way.

```mermaid
flowchart TD
  open([Open app]) --> session{Signed in?}
  session -- yes --> shelf([My shelf])
  session -- no --> signin[Sign in: enter email]
  signin --> valid{Valid email?}
  valid -- no --> invalidErr[Inline error: Enter a valid email address] --> signin
  valid -- yes --> send[Send sign-in code: button shows progress]
  send --> sent{Sent?}
  sent -- no network / server error --> sendErr[Error: Couldn't send the email. Check your connection and try again.] --> signin
  sent -- too many emails --> limitErr[Error: Too many sign-in emails. Wait a few minutes and try again.] --> signin
  sent -- yes --> check[Check your email: enter the 6-digit code]
  check -- Sign in --> code{Code right?}
  code -- yes --> shelf
  code -- not 6 digits --> digitsErr[Enter the 6-digit code from the email.] --> check
  code -- wrong or expired --> codeErr[That code isn't right or has expired. Check it, or send a new one.] --> check
  check -- Resend code, after 60 s countdown --> send
  check -- Use a different email / back --> signin
  check -- taps the link in the email, web or Android --> link{Link valid?}
  link -- yes --> shelf
  link -- expired, used or other device --> linkErr[Sign in with a note: send a new one] --> signin
```

Notes:
- The email carries both the code and the link (staging: only the link,
  see docs/architecture.md). The code works on any device; the link signs
  in where it was requested: the web app, or the Android app through
  `de.schwubware.shelf://login` (iOS: TASK-20). An expired, used or
  other-device link returns to Sign in with the note "This link has
  expired or was already used. Send a new one below."
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
  menu([⋮ Tags]) --> list[Tags: groups in order, built-ins marked]
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

Done: the album is on the user's shelf with the friend's tags they tapped;
new ones are ordinary, editable tags.

```mermaid
flowchart TD
  friend([Friend's shelf: album]) -- Add to my shelf --> entry[Album entry: add, no tags set; row: Anna's tags, N on this album]
  entry -- Choose --> list[Anna's tags: one line per tag with its path and where it goes]
  list -- Add: I have it --> list
  list -- Copy: I don't; her path is created --> list
  list -- Use my X: my nearest tag above --> list
  list -- Undo --> list
  list -- error --> err[Couldn't copy the tag. Try again.] --> list
  list -- Done --> entry
  entry -- Add to shelf --> done([My shelf + snackbar: Added to your shelf])
```

Notes:
- Built-in tags match by their key; like all tags, they are set only when tapped.
- Other tags match by name, ignoring case: in the matching group first,
  else anywhere in the user's tags.
- If your group of the same name is "several" while the friend's is "one",
  your group's type wins.
- A tag in a sub-group brings its parent tag along, created if needed.
- Tags in or under a built-in group you hide are not offered.
- A new group takes the friend's type (one or several per album).
- New tags and groups stay even if the user then cancels adding the album.
- The album remembers whose shelf it came from: "Added from Anna's shelf"
  under the artist, kept even if Anna's account is deleted.

# User flows (M2: friends)

M2 covers core use cases 3 and 4: invite a friend and view their shelf, and
read a feed of what friends add and rate. Friendships are mutual and start
from an invite. Friends see the whole shelf except entries hidden from
them. Screens: [screens.md](screens.md); wireframes:
[friends](wireframes/friends.html), [friend's shelf](wireframes/friend-shelf.html),
[feed](wireframes/feed.html).

## Your name (first sign-in)

Done: the user has a display name that friends see; they can change it
later.

```mermaid
flowchart TD
  signedin([Signed in]) --> has{Has a name?}
  has -- yes --> shelf([My shelf])
  has -- no --> name[Your name: What should friends call you?]
  name -- Continue --> valid{1–40 characters?}
  valid -- no --> nameErr[Enter a name friends will recognise.] --> name
  valid -- yes --> save{Saved?}
  save -- yes --> shelf
  save -- no network / error --> saveErr[Couldn't save your name. Try again.] --> name
  friends([Friends: Your name · Change]) --> name
```

Notes:
- Asked once, right after the first sign-in, before My shelf; an invite
  being accepted waits until the name is set.
- No uniqueness: two friends may both be "Anna".

## Invite a friend

Done: the friend received a link (and a code) through any app on the
inviter's phone; the invite shows as waiting until it is used or expires.

```mermaid
flowchart TD
  friends([Friends]) -- Invite a friend --> create{Invite created?}
  create -- no network / error --> createErr[Snackbar: Couldn't create an invite. Try again.] --> friends
  create -- yes --> sheet[Invite sheet: link, code, valid 7 days, used once]
  sheet -- Share --> system[System share sheet: link and code in one message] --> waiting([Friends: invite waiting])
  sheet -- Copy link --> copied[Snackbar: Link copied] --> waiting
  sheet -- Close --> waiting
  waiting -- Cancel invite --> cancelled[Snackbar: Invite cancelled] --> friends
```

Notes:
- The message reads: "Anna invites you to shelf:
  de.schwubware.shelf://invite/K7Q2-M9XD (or open shelf and enter the code
  K7Q2-M9XD under Friends)". The link opens the Android app (decided
  2026-11-26: we own no web domain); iPhones and chat apps that don't make
  such links tappable use the code.
- Several invites can wait at once; each makes one friend.

## Accept an invite

Done: inviter and invitee are friends; the invitee sees the inviter's shelf.

```mermaid
flowchart TD
  link([Opens the invite link: Android app]) --> signed{Signed in?}
  code([Friends: Have a code? Enter it]) --> enter[Enter code] --> check
  signed -- no --> signin[Sign in; the invite waits on the device] --> named
  signed -- yes --> named{Has a name?}
  named -- no --> name[Your name] --> check
  named -- yes --> check{Invite still valid?}
  check -- yes --> accept[Anna invited you: Accept / Not now]
  check -- expired or used --> gone[This invite has expired or was already used. Ask Anna for a new one.]
  check -- unknown code --> wrong[That code isn't right. Check it and try again.] --> enter
  check -- your own --> own[That's your own invite. Send it to a friend.]
  check -- already friends --> already[You and Anna are already friends.] --> fshelf
  accept -- Accept --> ok{Accepted?}
  ok -- yes --> fshelf([Anna's shelf + snackbar: You and Anna are friends])
  ok -- no network / error --> acceptErr[Couldn't accept the invite. Try again.] --> accept
  accept -- Not now --> friends2([Friends; the link still works until it expires])
```

Built (TASK-36): the sign-in screen doesn't name the inviter (looking up an
invite needs a signed-in user); Close on an expired, own or already-friends
invite returns to Enter code, to try another; a cancelled invite reads as
unknown ("That invite doesn't exist"), since cancelling deletes it.

## Friends and their shelves

Done: the user browses a friend's shelf, opens an album and can add it to
their own shelf; or removes the friend.

```mermaid
flowchart TD
  tab([Friends tab]) --> load{Loaded?}
  load -- loading --> skel[Skeleton rows]
  load -- error --> err[Couldn't load your friends. Try again.]
  load -- no friends --> empty[No friends yet. Invite a friend to see their shelf.]
  load -- yes --> list[Friends: name, albums, waiting invites]
  list -- friend --> fshelf[Anna's shelf: covers or list, their filter bar]
  fshelf -- empty --> fempty[Anna hasn't added any albums yet.]
  fshelf -- album --> falbum[Anna's album: her rating, comment, tags, favorite tracks]
  falbum -- Add to my shelf --> addflow([Add from a friend])
  falbum -- On your shelf · Open --> entry([Album entry: edit])
  list -- ⋮ Remove --> confirm[Remove Anna? You stop seeing each other's shelves.]
  confirm -- Remove --> removed([Friends + snackbar: Anna removed])
  confirm -- Cancel --> list
```

Notes:
- A friend's shelf is read-only and shows their own filter bar (changed
  2026-11-26 from built-in filters only) and the viewer's sort order.
- Removing a friend is mutual and immediate; albums already added from
  them stay, with "Added from Anna's shelf".

## Feed

Done: the user sees what friends added and rated, newest first, and can
open any of those albums.

```mermaid
flowchart TD
  tab([Feed tab]) --> load{Loaded?}
  load -- loading --> skel[Skeleton items]
  load -- error --> err[Couldn't load the feed. Try again.]
  load -- no friends --> nofriends[See what friends add and rate. Invite a friend under Friends.]
  load -- friends, nothing yet --> quiet[Nothing yet. When friends add or rate albums, they show here.]
  load -- yes --> items[Items: Anna added Kid A · 2 h; Ben rated Blue ★★★★½ · yesterday]
  items -- scroll to end --> more{More?}
  more -- yes --> items
  more -- error --> moreErr[Couldn't load more. Try again.]
  items -- pull to refresh --> load
  items -- item --> falbum([Friend's album])
```

Notes:
- Two kinds of items: an album added, and a rating set or changed (one
  item per album and friend: a later rating replaces the earlier one).
- Hidden entries never appear; hiding an entry removes its items.

## Hide an entry from friends

Done: friends don't see the album on the user's shelf or in the feed; the
user still sees it, marked as hidden.

```mermaid
flowchart TD
  entry([Album entry: edit]) -- Hide from friends: on --> save[Save]
  save --> ok{Saved?}
  ok -- yes --> shelf([My shelf: album marked hidden])
  ok -- no --> err[Couldn't save. Try again.] --> entry
  add([Album entry: add]) -- Hide from friends: on --> added([Added, hidden from the start])
```

## Edit several albums (TASK-40)

Done: the chosen tags, hidden state or removal applies to every selected
album at once; anything else on them stays as it was.

```mermaid
flowchart TD
  shelf([My shelf]) -- ⋮ Select albums, or press and hold an album --> sel[Selecting: n selected]
  sel -- tap album --> sel
  sel -- Select all --> sel
  sel -- filter key --> sel
  sel -- ✕ or back --> shelf
  sel -- n = 0 --> off[Tags, Hide, Remove off]
  sel -- Tags --> sheet[Tags for n albums: ✓ on all, – on some]
  sheet -- tap tag --> sheet
  sheet -- Cancel --> sel
  sheet -- Apply --> save{Saved?}
  save -- yes --> done1[Tags changed on n albums; still selected] --> sel
  save -- no --> err[Couldn't change n albums. Try again] --> sel
  sel -- Hide / Show --> hide[n albums hidden from friends · Undo] --> sel
  sel -- Remove --> rm[n albums removed · Undo] --> shelf
```

- Tags follow the rules of one album: in a one-per-album group the new tag
  replaces the other; a sub-tag puts its parent tag on too; taking a tag off
  takes its sub-tags off.
- Hide shows as Show when every selected album is already hidden.
- Not now: rating several albums, export, selecting on a friend's shelf.

