# Visual system

Locked 2026-11-23. Mockups: [visual/system.html](visual/system.html)
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
| amber | #F0A830 | #F0A830 | Primary action fill only |
| onAmber | #1F1510 | #2A1D16 | Text on amber |
| line | text at 12 % | text at 15 % | Hairlines, key outlines |
| off | #8C7C6A | #A39482 | Unlit light outlines, empty meter segments (≥ 3:1) |

One accent: amber. Cover colours are the only other colour on screen; the
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
- **Key** (the only control): surface fill, 1 px line outline, 4 px
  corners, 44 px. Options carry an 8 px square light before the label,
  unlit as a 1 px off outline. Selected: surfaceOn fill, 1.5 px signal
  outline, light filled with signal. Primary: amber fill, onAmber text, no
  light. Cancel and close are plain keys without a light. Used for every
  choice (each option a key), formats, toolbar, Save/Cancel, close.
- **Divider tabs** (shelf filters): 44 px keys standing on a 4 px teak
  baseline, bottom tucked 8 px behind it, label plus count. Selected: like
  a selected key, raised 4 px, with a 2 px signal top edge. The row
  scrolls sideways and fades out over the last 32 px.
- **Shelf board:** a 4 px teak line (1 px lighter top edge) across the
  full width under each row of three covers, a 10 px soft shadow below,
  and a 2 px contact shadow under each cover; title, artist and meter
  under the board.
- **Rating meter:** five bars, one per star; half a star fills half a
  bar. Small: 76 × 6 px, 4 px gaps. On the album entry: five 44 px keys,
  each with a 6 px bar; tap a key for a full star, again for a half.
- **Status without a rating:** signal light plus "Want" or "To listen" in
  signal colour, 12/600.
- **Spines view:** the list alternative; spines coloured from the cover,
  artist and title rotated, full width, standing on shelf boards; heights
  vary per album, pale spines get a 1 px line outline. Tapping a spine
  pulls it up 8 px with a signal light at its foot and shows its details
  below; tapping again opens it.

## Motion
Short and functional only: keys press in 100 ms; a pulled spine slides
150 ms. No looping or decorative animation.

## Later ideas (not in M1)
- The album entry opens by lifting the cover off its shelf board.
- A "Queue" section on the shelf for albums you want to listen to.
