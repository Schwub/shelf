---
name: visual-check
description: See the real app before calling a UI change done - screenshots of the web build signed in with test albums, in any theme, after tapping through screens. Use after changing screens, themes or components, to compare with the mockups in docs/design/.
---

# Visual check

Widget tests check behaviour, not looks. This skill takes screenshots of
the real app (the web build against the local Supabase), so a screen can be
compared with its mockup before the work is called done.

## Run
From the repository root, with Docker running (`docker info`):

```bash
mise exec -- .agents/skills/visual-check/run.sh <out-dir> [theme] [steps.json]
```

- `out-dir`: where the PNGs go (use the scratchpad, not the repo).
- `theme`: an `AppTheme` name (`tobacco`, `surfGreen`, `evening` …);
  default `tobacco`.
- `steps.json`: what to do after sign-in, in order; default one shot of
  My shelf. `tap` finds a screen-reader label or text, `shot` saves
  `<theme>-<name>.png`, `wait` pauses (ms):

  ```json
  [{"tap": "OK Computer", "shot": "entry"}, {"tap": "Cancel"},
   {"tap": "Menu"}, {"tap": "Theme", "shot": "themes"}]
  ```

The script starts the local Supabase (auth, API, database only), signs in
`look@example.com` with a one-time link (no email), gives it the nine test
albums, builds and serves the web app on `127.0.0.1:3000` and runs
Playwright at 412 × 915. Look at the PNGs (Read shows them).

## Then
1. Compare each screenshot with its mockup (`docs/design/visual/screens/`
   or the variation page): layout, spacing, colours, states.
2. Fix differences, or say which ones are deliberate.
3. For the user, take the screenshots again at `deviceScaleFactor: 2`
   (edit `shoot.js` locally) and send them.

## Limits
- Web build: phone-only behaviour (sharing, the camera) isn't covered.
- The test albums have no covers, so covers show as blank tiles.
- Sign-in by link needs `127.0.0.1` in `additional_redirect_urls`
  (`supabase/config.toml`).
