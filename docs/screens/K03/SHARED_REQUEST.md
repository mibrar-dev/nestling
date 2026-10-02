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
5. Need (Stage 6 iter-2, K03-BUG-7): `--dart-define=DISABLE_ANIMATIONS=1`
   parses as **false** — `bool.fromEnvironment` only understands `"true"`, so
   `kDisableAnimations` (`app/lib/core/data/env_flags.dart`) and
   `LaunchFlags.disableAnimations` are off even though RULES §6 and
   `tools/screens/shot.sh` pass `=1`. On device the Rive Pip therefore keeps
   animating and `shot.sh` reports "frame never stabilised in 25 s" for K03
   (both iterations). Fix: parse `'1'` as true in `env_flags.dart` (e.g.
   `String.fromEnvironment('DISABLE_ANIMATIONS') == '1' ||
   bool.fromEnvironment(...)`) and, ideally, drive
   `MediaQueryData.disableAnimations` from it at the app root so every
   motion path obeys one switch; passing `=true` in shot.sh also works.
   Files: `app/lib/core/data/env_flags.dart`, `app/lib/app/launch_flags.dart`,
   optionally `app/lib/app/app.dart`, `tools/screens/shot.sh`.
   Blocks: K03's still-frame gate and the UI screenshot pipeline.

No schema/DI/token changes needed. No new assets needed (all icons +
`nest`/`coin`/`meadowHill` exist in `nestling_assets.dart`; Pip renders via
`PipAvatar` + `pip_v2/mochi` fallbacks).
