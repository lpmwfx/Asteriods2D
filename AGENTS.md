# Repository Guidelines

## Project Structure & Modules
- Game entry points live in `main.lua` and `conf.lua`; core logic sits in `src/`.
- `src/core/` handles engine concerns (input, physics, viewport/display, game_state); keep reusable systems here.
- `src/entities/` owns gameplay objects (ship, meteor, railgun); keep their physics bodies and lifecycle logic local to each file.
- `src/render/` draws SDF visuals, background, and UI; avoid mixing game logic into render functions.
- `src/data/` stores settings and SDF definitions—add tunable numbers here instead of hardcoding.
- Assets: screenshots land in `screenshots/`; reference art in `assets/references/`; docs and specs in `docs/`.

## Build, Run, and Dev Commands
- Run locally: `love .`
- Automated screenshot (captures then quits after ~2s): `love . --screenshot` or `love . -s`
- Package distributable: `zip -r AxiumForge.love .` then `love AxiumForge.love`
- Use `F12` (via AxShot) for manual captures; output goes to `screenshots/`.

## Coding Style & Naming
- Language: Lua with 4-space indentation; keep comments and logs in English.
- Module pattern: return tables with colon-style methods (e.g., `GameState:update(dt)`); prefer `local` scope for helpers.
- Naming: PascalCase for module tables (`GameState`, `Physics`), snake_case for fields/functions, and descriptive IDs in data tables.
- Data-driven rule: route tunables (speeds, radii, thresholds) through `src/data/settings.lua` or `src/data/sdf_meteors.lua`.
- Avoid new ad-hoc screenshot code—reuse `axforge/axshot.lua`.

## Testing & QA
- No automated test suite yet; rely on manual playtests via `love .`.
- Smoke checklist: menu start (SPACE), thrust/rotation responsiveness, meteor spawn and fragmentation, protected-zone enforcement, railgun cooldown, pause/resume, fullscreen toggle (`F`/`F11`), and screenshot capture.
- When changing visuals or gameplay tuning, include an AxShot screenshot (`F12` or `--screenshot`) showing the scenario you touched.

## Commit & Pull Request Guidelines
- Commit messages: short, present-tense or imperative English summaries (e.g., “Fix protected zone rendering and add fullscreen toggle”).
- For PRs, include: what changed, why, how to reproduce (commands/keys), and screenshots for visual tweaks.
- Update `CHANGELOG` for user-visible changes and `TODO` if you add or finish planned work; keep entries concise.
- Link related issues/tasks when available and note any follow-up work left out of scope.
