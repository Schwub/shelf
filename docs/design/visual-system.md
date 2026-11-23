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
| surfaceOn | #3A291E | #F3E4C8 | Selected key fill |
| teak | #A87445 | #A87445 | Shelf lines, tab baseline (decorative) |
| text | #F1E6D4 | #2A1D16 | Text |
| muted | #B5A28B | #665444 | Secondary text, labels |
| signal | #F0A830 | #B06A00 | Indicator lights, rating meter, selected outline, amber text |
| amber | #F0A830 | #F0A830 | Primary action fill only |
| onAmber | #1F1510 | #2A1D16 | Text on amber |
| tab / onTab | #E9DAB7 / #2A1D16 | #2A1D16 / #F4EDE2 | Selected divider tab |
| line | text at 12 % | text at 15 % | Hairlines, key outlines |
| off | text at 18 % | text at 14 % | Unlit lights, empty meter segments |

One accent: amber. Cover colours are the only other colour on screen; the
album entry tints the wall behind the cover with the cover's colour
(`ColorScheme.fromImageProvider`, `DynamicSchemeVariant.fidelity`), at
33 % (evening) or 25 % (daylight).

Contrast (WCAG): text ≥ 4.5:1 and signal ≥ 3:1 on bg and surface in both
themes; checked with the mockup values.

## Type
- **Archivo**, width 125 (Expanded), weight 700: screen titles (26), album
  title (24). Width 112, weight 600, 13: keys and tabs.
- **IBM Plex Sans** 400/600: everything else. Body 14, labels 12/600,
  cover titles 13/600, artist 12. Tabular figures for counts.
- Sentence case everywhere; no all-caps labels.

## Shape and space
- **Corners:** controls and fields 4 px on all corners; covers and spines
  2 px. No pills, no mixed corners.
- **Sizes:** every control 44 px high (tabs 36, selected tab 42).
- **Spacing:** 4 px grid; 20 px side margin; 8 px between keys; 12 px
  between covers.

## Components
- **Key** (the only control): surface fill, 1 px line outline, 4 px
  corners, 44 px. Optional 6 px square light before the label (unlit:
  off). Selected: surfaceOn fill, 1 px signal outline, light on. Primary:
  amber fill, onAmber text, no light. Used for segmented choices (each
  option a key), formats, toolbar, Save/Cancel, close.
- **Divider tabs** (shelf filters): keys standing on a 3 px teak baseline,
  bottom tucked behind it, with a count in muted figures. Selected tab is
  taller (42 px) and filled with tab/onTab.
- **Shelf board:** a 3 px teak line across the full width under each row
  of three covers, with a 10 px soft shadow below; title, artist and meter
  under the board.
- **Rating meter:** five segments, one per star; half a star fills half a
  segment. Small (4 px high, 70 % of the tile) on the shelf; on the album
  entry five 44 px keys, each with its segment, tap twice for a half.
- **Status without a rating:** signal light plus "Want" or "To listen" in
  signal colour.
- **Spines view:** the list alternative; spines coloured from the cover,
  title and artist rotated, standing on a shelf board. Tapping a spine
  lifts it 12 px and shows its details below; tapping again opens it.

## Motion
Short and functional only: keys press in 100 ms; a lifted spine slides
150 ms. No looping or decorative animation.
