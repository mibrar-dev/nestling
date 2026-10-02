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
3. Need (Stage 6, K03-BUG-5): the kid-mode redirect guard in
   `app/lib/app/router.dart` matches `/today` and `/today/…` only, so
   `/today-empty`, `/quest-editor`, `/add-children` and
   `/pocket-money-setup` are still reachable from kid mode (deep link → no
   `/parental-gate`). Extend the `parentOnly` list, or better, put the flag
   on the routes so future screens cannot silently miss it. Files:
   `app/lib/app/router.dart`. Blocks: no for K03 itself (guard bypass is a
   shared/parent-screens concern); bug logged in `6_bugs.md`.

No schema/DI/token changes needed. No new assets needed (all icons +
`pipStage3`/`nest`/`coin`/`meadowHill` exist in `nestling_assets.dart`).
