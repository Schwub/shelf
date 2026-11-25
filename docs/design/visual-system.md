# Visual system

Final 2026-11-23: colours V3, key C4 with pressed state B, filter bar S2.
The final mockups of every M1 screen and state, evening and daylight, are
in [visual/screens/](visual/screens/); the key in close-up is
[visual/variations/c4-final-sheet.html](visual/variations/c4-final-sheet.html)
(option B). Everything else in [visual/](visual/) is exploration, kept for
reference ([visual/README.md](visual/README.md)). Screens and states are
in [screens.md](screens.md); this file decides how they look.

## Idea
The shelf is the product. Calm, warm surfaces with a few cues from an 80s
living room and hi-fi that you feel rather than notice: covers standing on
teak shelf lines, tactile keys like a cassette recorder's (seen from the
bottom right, light from the top left), a filter bar with labels printed
above its keys, wide type, a small light window on selected keys, a
five-segment rating meter. Nothing else is decorative: no textures, glows,
round buttons or illustrations.

## Colour
Three themes, chosen in the ⋮ menu (Theme) and remembered on the device;
the default is **Tobacco & copper** (2026-11-25, TASK-31). It's warmer and
calmer than the original: no gradients and no light windows, so the covers
carry the colour. A chosen key is pressed down, its face takes 14 % of the
signal colour and its label the signal colour; the primary key and the
rating bars are flat copper. Mockup:
[visual/variations/themes-warm.html](visual/variations/themes-warm.html),
2. Tokens: bg #231812, surface #2E2019, teak #94603F, text #F0E2D2, muted
#B79E8A, signal #C88A63, off #806B5C, primary key #B4764F (side #7A4A2E).
The original **Evening** and **Daylight** below stay selectable, with
their amber-to-coral gradient and light windows.

| Token | Evening | Daylight | Use |
|---|---|---|---|
| bg | #1F1510 | #F4EDE2 | Screen background (walnut / paper) |
| surface | #2A1D16 | #FBF7F0 | Keys, fields, unselected tabs |
| surfaceOn | #3A291E | #F6E7CC | Selected key and tab fill |
| teak | #A87445 | #A87445 | Shelf lines, tab baseline (decorative) |
| text | #F1E6D4 | #2A1D16 | Text |
| muted | #B5A28B | #665444 | Secondary text, labels |
| signal | #F0A830 | #B06A00 | Indicator lights, rating meter, selected outline, amber text |
| warm | #F2B13A → #E8743A | #B06A00 → #B4471C | The one gradient: rating bars (amber to coral across the five bars), indicator lights |
| amber | #F2B13A → #E8743A | same | Primary key face, left to right; lip #B4501E |
| onAmber | #1F1510 | #2A1D16 | Text on amber |
| line | text at 12 % | text at 15 % | Hairlines, key outlines |
| off | #8C7C6A | #857563 | Unlit light outlines, empty meter segments (≥ 3:1) |

One accent: the warm amber-to-coral gradient, like a level meter warming
up; backgrounds stay flat. Cover colours are the only other colour on screen; the
album entry tints the wall behind the cover with the cover's colour
(`ColorScheme.fromImageProvider`, `DynamicSchemeVariant.fidelity`), at
33 % (evening) or 25 % (daylight).

Contrast (WCAG): text ≥ 4.5:1, signal and off ≥ 3:1 on bg and surface
in both themes (daylight signal #B06A00: 3.7:1 on bg, 4.0:1 on surface);
bright amber is only used as a fill under dark text (8:1).

## Type
Six sizes only: 24, 18 (sheet, dialog and message titles), 15, 14, 13, 12.
Weights: Archivo 600–800, IBM Plex Sans 400 and 600 (no 700).
- **Archivo** width 125 (Expanded) 700, 24: screen and album titles.
  Width 112, 600, 13: keys, tabs and tab counts (tabular figures).
- **IBM Plex Sans**: 15/600 list and row titles; 14 body and fields;
  13/600 cover titles; 12 artist and labels (600).
- Sentence case everywhere; no all-caps labels.

## Shape and space
- **Corners:** controls and fields 4 px on all corners; covers 2 px. No pills, no mixed corners.
- **Sizes:** keys look 44 px high (icon keys 44 × 44, 20 px line icons
  with a 1.5 px stroke, no Unicode glyphs); an invisible margin makes
  every touch area at least 48 × 48 (Android's minimum), so rows of keys
  sit 4 px further apart than they look. Fields are 48 px high.
- **Spacing:** 4 px grid only (4, 8, 12, 16, 20, 24, 28); 20 px side
  margin; 8 px between keys; 12 px between covers; 4 px between tabs.

## Components
- **Key** (the only control besides text links such as "Add" on a tag
  group's label line), modelled on a cassette recorder's piano
  key, seen from the bottom right with light from the top left (mockup:
  [visual/variations/c4-final-sheet.html](visual/variations/c4-final-sheet.html), option B):
  - **Construction:** two layers, each a rounded rectangle with 4 px
    corners: the edge (the full key, side colour) and the face on top of
    it, inset 5 px from the right and 6 px from the bottom. Never draw the
    sides as inset shadows: their inner corners come out square.
  - **Shape:** 44 px high, 4 px corners. A slightly curved face (evening
    #3A2A20 → #2A1D16, daylight #FFFFFF → #F1E9DE, 160°) with a 1 px
    highlight on the top and left edges. Two visible sides: 5 px on the
    right, 6 px at the front (evening #1A110C, daylight #DCCFBE), ending in
    a 1 px dark contact line (#060403 / #A8957D) where the key meets the
    panel. Outline 1 px line, under the sides. Shadow 3 px right, 4 px down,
    5 px blur.
  - **Label:** Archivo 13/600, engraved (1 px shadow below, faint
    highlight above). Options carry a light window: 10 × 6
    px, 2 px corners, recessed (#0E0907 / #E4D8C8), always at the same spot
    at the start of the key: 10 px from the face's left edge, on the face's
    vertical centre, whatever the label. The label (or count) is centred in
    the space to the right of it. When pressed, the window moves with the
    face. Keys without a window (Save, Cancel, close, rating) centre their
    content on the face.
  - **Selected = pressed down, not sunk in:** the key gets lower but keeps
    standing on the panel; no opening around it. It loses 60 % of its
    height: sides 2 px right, 2.4 px front (the 5:6 ratio of the resting
    key), the face moves 3 px right and 3.6 px down, the shadow shrinks to
    1.2 / 1.6 / 2 px. The face shades like at rest, slightly darker
    (evening #33251C → #271B14, daylight #F7F2EA → #ECE3D6). Amber
    reflection: the top and left edges catch the light in signal colour
    instead of white; no line on the shadow side. A soft glow around the
    light window, which lights up amber.
  - **Light:** always from the top left. The right side is a little darker
    than the front side (evening #120B08 vs #1A110C, daylight #CDBFAC vs
    #DCCFBE), at rest and pressed.
  - **Primary:** the same key with the amber gradient face (#F2B13A →
    #E8743A), a coral side (#B4501E), a dark contact line (#7A3010),
    onAmber text, no light window.
  - Cancel and close are plain keys without a light window. Every press
    gives a light haptic click (`HapticFeedback.selectionClick`).
  - Used for every choice (each option a key), formats, toolbar,
    Save/Cancel, close and the rating keys.
- **Filter bar** (shelf filters: All, Own, Want, To listen, Listened;
  mockup [visual/variations/tabbar-c4.html](visual/variations/tabbar-c4.html),
  S2): the labels are printed on the panel above the keys (Archivo 12/600,
  muted, centred over each key); below them five equal C4 keys, 44 px
  high, 6 px apart, across the full width, each with its light window
  at the start and its count (13/600) centred in the rest. Up to five
  filters fill the width in equal keys; with more, keys keep the width of
  five and the row (labels with it) scrolls sideways, fading out over the
  last 32 px. Labels that don't fit their key end in an ellipsis. The selected filter is a pressed key
  (state B) with its light on. The row stands on a teak board that casts
  the usual 10 px shadow.
- **Shelf board:** a 4 px teak line (1 px lighter top edge) across the
  full width under each row of three covers, a 10 px soft shadow below,
  and a 2 px contact shadow under each cover; title, artist and meter
  under the board.
- **Rating meter:** five bars, one per star; half a star fills half a
  bar. Small: 76 × 6 px, 4 px gaps. On the album entry: five 44 px keys,
  each with a 6 px bar on its face (12 px from the face's left and right
  edges, on the face's vertical centre) that moves with the face. A key
  with a full star is pressed (state B, bar filled); a key with a half star
  is pressed halfway: sides 3.5 px right and 4.2 px front, face moved 1.5 /
  1.8 px, shadow halfway (2.1 / 2.8 / 3.5 px), bar half filled; empty keys
  are at rest. Tap a key for a full star, again for a half, a third time to
  clear.
- **Fields** are recessed like a cassette window: 1 px line outline and a
  soft inner shadow at the top, no lip.
- **Shelf tiles** show only title, artist and, if rated, the small rating
  meter. No status tags on the shelf (less clutter): listening and
  collection status live on the album entry and in the filter bar.
- **List view:** the alternative to covers (replaced the spines view,
  TASK-30, 2026-11-25): one row per album, a 56 px cover, title 15/600,
  artist 12 muted and the small rating meter if rated, a 1 px line below;
  tapping a row opens the album.

## Supporting elements
All M1 screens and states in this system: [visual/screens/](visual/screens/)
(sign-in, shelf, search, entry). Elements those screens add, built from the
same rules:
- **Wordmark:** "shelf" in Archivo Expanded 800, 34, sign-in only.
- **Disabled key:** the key at 45 % opacity, no press.
- **Note** (inline message): surface fill, 1 px line, 4 px corners, a
  signal-coloured warning icon, 13 px text. Errors use the note or a help
  line with the icon; there is no separate error colour.
- **Progress:** a 3 px track in off colour with a moving segment in the
  amber gradient; skeletons are surface-coloured blocks and lines.
- **Dialog:** background colour, 1 px line, 4 px corners, title in Archivo
  18, two keys side by side; the screen behind is dimmed to 45 %. The
  second key is primary (amber) for safe confirmations ("Discard", "Sign
  out"); destructive deletes use two plain keys and let the label say what
  happens ("Delete").
- **Snackbar:** always dark (#2A1D16, cream text, hairline outline) with
  the action in amber, 20 px from the sides, above the bottom bar.
- **Search field:** a recessed field like the comment field, with a 18 px
  search icon in muted colour.
- **Tag groups on the album entry:** each group has a label line (12/600,
  muted); multiple-choice groups add an "Add" action on the right of it
  (13/600, underlined, 44 px tall). Built-in two-tag groups fill the row
  with equal keys; other tags keep their natural width and wrap. A
  sub-group is indented 12 px with a 2 px line on its left.
- **List rows** (editor, filters, sheets): 56 px, 1 px line below, title
  15/600 and a 12 px muted second line; 44 × 44 icons for reorder (≡),
  more (⋯), remove (✕) and open (›); "Built-in" as muted 12/600 text.
  Selection in a list uses the light window (lit = chosen), unlit with a
  1 px off outline and lit exactly like on keys. "Add" rows put their + in
  the same 44 px slot as the reorder handle, so all titles line up. Dimmed
  rows (hidden group, "All") use muted text, never opacity.
- **Screen bar:** a 44 px back key and the title in Archivo 24.
- **Bottom sheet:** background colour, 4 px top corners, a hairline on top,
  a grab bar, title in Archivo 18; the screen behind is dimmed to 45 %.
- **Menu:** surface colour, 1 px line, 4 px corners, 48 px rows, under the
  ⋮ key, 4 px below it; rows 15/600.

## Motion
Short and functional only: keys press in 100 ms (the face slides down and right as the sides shrink). No looping or decorative animation.

## Later ideas (not in M1)
- The album entry opens by lifting the cover off its shelf board.
- A "Queue" section on the shelf for albums you want to listen to.
- Corridor palette (#553116, #7B3A24, #D2601E, #E2CA50, #6A6A2E): warmer
  browns, orange and olive, tried on all screens in
  [visual/variations/palette-corridor.html](visual/variations/palette-corridor.html).
  Kept as an idea; the current colours stay. Its daylight version needs
  contrast work (off and muted text below 3:1).
