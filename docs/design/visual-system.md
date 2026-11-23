# Visual system

Locked 2026-11-23, colours and keys updated the same day (colours V3, key
C4, pressed state B). Mockups: [visual/variations/c4-final-sheet.html](visual/variations/c4-final-sheet.html)
and [visual/variations/c4-final-entries.html](visual/variations/c4-final-entries.html) for the key and screens; [visual/system.html](visual/system.html) for the spines view
and, for layout, [visual/system.html](visual/system.html)
(earlier directions A–B5 are kept next to it for reference). Screens and
states are in [screens.md](screens.md); this file decides how they look.

## Idea
The shelf is the product. Modern and flat, with a few cues from an 80s
living room and hi-fi that you feel rather than notice: covers standing on
teak shelf lines, divider tabs, wide type, a small indicator light on
selected keys, a five-segment rating meter. Nothing else is decorative: no
textures, bevels, glows, round buttons or illustrations.

## Colour
Two themes; the app follows the system setting.

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
| off | #8C7C6A | #A39482 | Unlit light outlines, empty meter segments (≥ 3:1) |

One accent: the warm amber-to-coral gradient, like a level meter warming
up; backgrounds stay flat. Cover colours are the only other colour on screen; the
album entry tints the wall behind the cover with the cover's colour
(`ColorScheme.fromImageProvider`, `DynamicSchemeVariant.fidelity`), at
33 % (evening) or 25 % (daylight).

Contrast (WCAG): text ≥ 4.5:1, signal and off ≥ 3:1 on bg and surface
in both themes (daylight signal #B06A00: 3.7:1 on bg, 4.0:1 on surface);
bright amber is only used as a fill under dark text (8:1).

## Type
Five sizes only: 24, 15, 14, 13, 12.
- **Archivo** width 125 (Expanded) 700, 24: screen and album titles.
  Width 112, 600, 13: keys, tabs and tab counts (tabular figures).
- **IBM Plex Sans**: 15/600 pulled-spine title; 14 body and fields;
  13/600 cover titles; 12 artist, labels (600) and spine text.
- Sentence case everywhere; no all-caps labels.

## Shape and space
- **Corners:** controls and fields 4 px on all corners; covers and spines
  2 px. No pills, no mixed corners.
- **Sizes:** every control 44 × 44 px or taller; icon keys 44 × 44 with
  20 px line icons (1.5 px stroke), no Unicode glyphs.
- **Spacing:** 4 px grid only (4, 8, 12, 16, 20, 24, 28); 20 px side
  margin; 8 px between keys; 12 px between covers; 4 px between tabs and
  spines.

## Components
- **Key** (the only control), modelled on a cassette recorder's piano
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
    highlight above). Options carry a light window before the label: 10 × 6
    px, 2 px corners, recessed (#0E0907 / #E4D8C8).
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
- **Divider tabs** (shelf filters): 44 px keys standing on a 4 px teak
  baseline, bottom tucked 8 px behind it, label plus count. Selected: a
  pressed key, like every other selection. The row scrolls sideways and
  fades out over the last 32 px.
- **Shelf board:** a 4 px teak line (1 px lighter top edge) across the
  full width under each row of three covers, a 10 px soft shadow below,
  and a 2 px contact shadow under each cover; title, artist and meter
  under the board.
- **Rating meter:** five bars, one per star; half a star fills half a
  bar. Small: 76 × 6 px, 4 px gaps. On the album entry: five 44 px keys,
  each with a 6 px bar; tap a key for a full star, again for a half.
- **Fields** are recessed like a cassette window: 1 px line outline and a
  soft inner shadow at the top, no lip.
- **Status without a rating:** signal light plus "Want" or "To listen" in
  signal colour, 12/600.
- **Spines view:** the list alternative; spines coloured from the cover,
  artist and title rotated, full width, standing on shelf boards; heights
  vary per album, pale spines get a 1 px line outline. Tapping a spine
  pulls it up 8 px with a signal light at its foot and shows its details
  below; tapping again opens it.

## Motion
Short and functional only: keys press in 100 ms (the face slides down and right as the sides shrink); a pulled spine slides
150 ms. No looping or decorative animation.

## Later ideas (not in M1)
- The album entry opens by lifting the cover off its shelf board.
- A "Queue" section on the shelf for albums you want to listen to.
