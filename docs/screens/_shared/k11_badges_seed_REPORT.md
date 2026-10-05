# Shared report — k11_badges_seed: demo seed badges match the K11 design

## Files changed
- `app/lib/core/data/seed.dart` — `_badgesDemo` now inserts exactly these nine
  badges, in this order: `first-quest` / First quest, `bed-maker-7` /
  Bed maker ×7 (U+00D7), `kind-helper` / Kind helper, `bookworm` / Bookworm,
  `bins-out` / Bins out, `biscuit-sitter` / Biscuit sitter, `tidy-hero` /
  Tidy hero, `early-bird` / Early bird, `plant-waterer` / Plant waterer.
  Removed `tidy-champion`, `super-saver`, `pet-friend`. Grep over `app/lib`
  confirms nothing else referenced those three ids. Earned rows untouched
  (Maya: first-quest, bed-maker-7, kind-helper, bookworm; Leo: first-quest,
  same timestamps). No schema or other seed-table changes.
- `app/test/core/data/repositories_test.dart` — `badges / shelf + happy days`:
  shelf count 8 → 9 (earned 4 and happy-days 4 unchanged); added
  `badges / demo seed badges match the K11 design order` asserting the exact
  nine ids and nine titles in order via `watchShelf('maya')`.

## What / why
The K11 badges screen design needs nine badges; the demo seed held eight with
three ids/titles (`tidy-champion`, `super-saver`, `pet-friend`) that do not
appear in the design. This change aligns the seed copy char-exact and keeps
the earned-row contract (Maya 4, Leo 1) intact.

## Test names added / changed
- Changed: `badges / shelf + happy days` (count 8 → 9).
- Added: `badges / demo seed badges match the K11 design order`.

## Verification
- `cd app && dart format .` — clean (formatted, no diff beyond this change).
- `flutter analyze` — `No issues found!`.
- `flutter test --timeout 120s` — all 4290 tests passed (`All tests passed!`).

## Follow-up for screens
- K11 badges screen: renders nine shelf cells from the badge repository in
  seed order; Maya shows 4 earned / 5 locked (`Keep going!`), Leo shows
  1 earned / 8 locked. No screen-code changes needed for this seed update.
- Other screens: no action; no other seed table, schema, or feature code
  was touched.

VERDICT: PASS
