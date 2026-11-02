# Noonvaei (نانوایی سنگک) — Godot

Persian idle/tycoon mobile game: run a sangak bakery, upgrade 4 sections, earn more.
Android-first, portrait. Migrated from Expo/React Native; the migration is DONE.
The old repo `Noonvaei` is reference only.

## Stack
- Godot 4.7, GDScript, GL Compatibility renderer.
- Viewport 1080x1920 portrait, stretch `canvas_items`, aspect `expand`.
- Persian UI (RTL): Labels use `language = "fa"`. Helpers: `UiKit`, `FaFormat`. Fonts in `assets/fonts/`.

## Layout
- `scenes/main.tscn` -> `scripts/main.gd` builds the whole UI in code.
- `scripts/game/` game logic: `economy.gd` (pure static funcs), `storage.gd`, `game_state.gd` (autoload `Game`).
- `scripts/config/` balance numbers and strings.
- `scripts/world/` map, camera, bakery, sidewalk, baker, cars, shop lighting, `world_config.gd` (all tunables).
- `scripts/scene/` iso projection + asset paths.
- `scripts/ui/` HUD, bottom bar, upgrade panel, offline card, shared widgets.
- `scripts/preview/` + `scenes/front_preview.tscn`, `compare_front.tscn`: dev-only 3D shop preview tools. Not part of the game.

## Architecture
- Logic and UI are separate. `Game` owns state and emits `changed` / `offline_report_changed`. UI only reads it and calls `Game.upgrade()`.
- main.gd layer order: WorldMap > TopGradient > Hud > UpgradePanel/ComingSoon > BottomBar > OfflineCard.
- Income = min(customers, sales, bread) x price. Bottleneck = weakest section.
- Offline income: after 10s away, cap 8h, 50% efficiency. Save file: `user://bakery_save.json`.
- Shop front is a 3D scene baked once to a texture (`shop_front_3d.gd`), shown by `bakery.gd`.
- Cars use `car_model_3d.gd`: loads `assets/vehicles/<id>.glb` if present, else a 3D placeholder. Movement: `car_physics.gd` + `car_driver.gd`.
- UI sizes use dp via `UiKit.dp_scale`.

## Conventions
- snake_case files, one `class_name` per file, typed GDScript, `##` doc comments.
- Code, comments and commit messages in English. Reply to the user in Persian.

## Working rules (save tokens)
- Never read a whole big file. Find the relevant function first, then edit only that part.
  Big files: `shop_front_3d.gd` (36KB), `front_env.gd` (30KB), `car_model_3d.gd` (21KB), `sidewalk.gd` (20KB), `compare_front.gd` (16KB).
- Don't touch `scripts/preview/` unless the task is about it.
- Make minimal edits. Don't rewrite whole files. One commit per task.
- Don't edit README.md or this file unless asked.
- If the game can't be run, say the change is untested and give 2-3 short manual test steps.
