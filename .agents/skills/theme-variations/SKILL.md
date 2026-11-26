---
name: theme-variations
description: Design colour themes for shelf - a mockup page of candidates (My shelf and an album entry each, with bright test covers), then the chosen ones as ShelfColors in the app with contrast checked. Use when the user asks for new themes, palettes or colour variations.
---

# Theme variations

## 1. Candidates (design only)
1. Copy `example.json` and describe each candidate: `key`, `name`, `note`
   (one or two sentences on the idea), the colours (bg, surface, key faces
   and sides, text, muted, line, off, teak, accent, primary, meter …;
   `primary` and `meter` may be a CSS `linear-gradient`), `leds` (false for
   new themes) and `light: true` for light ones. Put the current default
   first for comparison.
2. `python3 mockup.py <themes.json> docs/design/visual/variations/<name>.html`
3. Screenshot each `<section>` with Playwright (deviceScaleFactor 1), look
   at every one: is the chosen key clear without a light window, does the
   accent compete with the covers?
4. Add a line to `docs/design/visual/README.md`, commit, and send the page.

Keep names generic: inspired by a guitar finish or a radio is fine, brand
names aren't.

## 2. Into the app (the ones the user picks)
1. `python3 dart.py <themes.json>` prints `ShelfColors` constants with the
   values the mockup leaves out derived (pressed tint 14 %, 10 % in light
   themes; side shades; five meter steps from a gradient).
2. Add them to `app/lib/theme/shelf_colors.dart` and to `AppTheme` with
   their `ThemeFamily` (Woodgrain, Finishes, Classic, or a new family).
3. `mise run check`: the accessibility tests run in every theme. Typical
   contrast failures and fixes (13 px labels need 4.5:1):
   - text on the primary key: dark text on bright oranges and yellows;
   - chosen labels in the accent: lighten it on dark themes, darken it on
     light ones;
   - a gradient end that's too dark or light for the key's text.
   Compute ratios before changing a colour, change only what fails, and
   note the changes in `docs/design/visual-system.md`.
4. Look at them in the real app with the visual-check skill.
