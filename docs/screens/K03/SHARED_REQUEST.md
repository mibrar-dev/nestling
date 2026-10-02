# Shared request — K03 Kid home

1. Need: `NestKidQuestCard` icon tile is fixed `surface2`, but the K03 HTML
   tints tiles per quest (`sky-tint` dishwasher, `lilac-tint` reading,
   `peach-tint` tidy). An optional tile background parameter would close
   the drift. Files: `app/lib/core/design_system/components/nest_quest_card.dart`.
   Blocks: no — shipping with `surface2` tiles, drift noted for compare.
2. Need: stale design copy only — PNG/HTML say "3 of 6 done" but the demo DB
   yields 4 of 6 (dishwasher + table pending, bins + hoover approved). No
   seed change wanted (RULES §4); either accept live "4 of 6 done" or update
   the PNG copy. Blocks: no.
3. DONE on main (Stage 2 iteration 2 verified): commit `ded8eb9` gates
   `/today-empty`, `/quest-editor` (plus all `_onboardingLocations`) from
   kid mode, with a router test enumerating parent paths. K03-BUG-5 proofs
   un-skipped and passing. No action needed.
4. DONE on main (Stage 6 iteration 2 re-verified): the PERIODS ruling added
   `countsForCurrentPeriod` / `londonDayStartUtc` / `londonWeekStartUtc` and
   K03's `watchItems` now scopes status to the quest's current London period.
   The day-boundary proof runs un-skipped and passes (daily/weekly/once
   probes added; BST switch days covered). No action needed.
5. PARTIALLY fixed on main (Stage 6 iter-2, K03-BUG-7): `5eea2ad` wires
   `kDisableAnimations` into `MediaQuery.disableAnimations` app-wide, but
   `bool.fromEnvironment('DISABLE_ANIMATIONS')` still parses the documented
   `=1` as **false** (only `"true"` is true), so on device the Rive Pip keeps
   animating and `shot.sh` (which passes `=1`) reports "frame never
   stabilised". Still needed: parse `'1'` as true in
   `app/lib/core/data/env_flags.dart` (e.g.
   `String.fromEnvironment('DISABLE_ANIMATIONS') == '1' ||
   bool.fromEnvironment(...)`) and mirror it in `launch_flags.dart`.
   Files: `app/lib/core/data/env_flags.dart`, `app/lib/app/launch_flags.dart`,
   optionally `tools/screens/shot.sh` (passing `=true` also works).
   Blocks: K03's still-frame gate (RULES §6) and the UI screenshot pipeline.
   The `K03-BUG-7` proof stays conditionally skipped and is run with the
   documented flag to confirm the failure until this lands.

No schema/DI/token changes needed. No new assets needed (all icons +
`nest`/`coin`/`meadowHill` exist in `nestling_assets.dart`; Pip renders via
`PipAvatar` + `pip_v2/mochi` fallbacks).
