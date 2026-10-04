# Audience glyphs REPORT (parent vs kid — each screen matches its own design)

## Files changed

- `app/assets/icons/ic_reward_coffee_parent.svg` (new — exact P14 dome+box+legs)
- `app/assets/icons/ic_quest_bed_kid.svg` (new — exact K03/K04 bed)
- `app/assets/icons/ic_quest_dishes_kid.svg` (new — exact K03 dishwasher)
- `app/assets/icons/ic_quest_reading_kid.svg` (new — exact K03 open book)
- `app/lib/core/design_system/components/audience.dart` (new — `enum NestAudience { parent, kid }`)
- `app/lib/core/design_system/components/quest_icons.dart` (new — `questIconFor(key, audience:)` + `questIconKeys`)
- `app/lib/core/design_system/assets/nestling_assets.dart` (4 additive constants: `questBedKid/questDishesKid/questReadingKid/rewardCoffeeParent` + audience docs; no existing SVG touched)
- `app/lib/core/design_system/components/nest_icon.dart` (4 forwards)
- `app/lib/core/design_system/components/reward_icons.dart` (`rewardIconFor(key, {required audience})`: parent P14-exact, kid K08-exact)
- `app/lib/core/design_system/design_system.dart` (barrel exports `audience.dart`, `quest_icons.dart`)
- `app/lib/features/rewards/presentation/widgets/p14_reward_meta.dart` (P14 art → parent)
- `app/lib/features/kid_home/presentation/views/kid_home_view.dart` (K03 `_iconFor` → `questIconFor(kid)`)
- `app/lib/features/quests/presentation/widgets/quest_idea_meta.dart` (Ideas 4 tiles → `questBed/questBins/questDishes/questHoover`; `questIconAsset` → parent wrapper)
- `app/lib/features/today/presentation/widgets/today_loaded_body.dart` (`todayIconFor` → parent wrapper; `bag` unifies to `schoolBag`)
- `app/test/design_system/shared_reward_glyphs_test.dart` (updated to both audiences)
- `app/test/features/quests/quest_idea_meta_test.dart` (Ideas + Active expect parent exact)
- `app/test/design_system/audience_glyphs_test.dart` (new, 28 tests)

No other feature code touched. P09 picker already drew the parent exact (`questBed/questDishes/questHoover/book/questBins/paw`), so no P09 edit. `pubspec.yaml` unchanged (`assets/icons/` already covers the new files).

## 1. What / why

`shared/reward_glyphs` made `rewardIconFor(key)` return the K08 (kid) glyphs
everywhere, so P14 differed from ITS design for `film` (play vs film-strip),
`moon` (clock vs crescent), `cake` (hat vs basket), `coffee` (dome+box+legs
vs takeaway cup) and `tv` (0.5 px rect shift) — see `reward_glyphs_REPORT.md`
§2. Quests had the mirror problem: P09 uses `questBed` etc. from the P09
HTML, but K04 needs the K04 HTML bed (headboard post, pillow, base and legs:
`M2 18v-7 / M2 14h20v4 / …h-9v3 / M6 11V8h4v3` — K04 `5_ui.md` deviation 1),
and K03 renders dishwasher/reading/bed from legacy look-alikes instead of
its own HTML tiles.

Orchestrator decision: each screen matches its OWN design. Parent targets
come from P14/P09/P10/P08 HTML; kid targets from K03/K04/K08 HTML.

## 2. Per-key decisions

### Rewards (`rewardIconFor`)

| key | parent (P14) | kid (K08) |
|---|---|---|
| `tv` | `screenTime` (`rect 2/4/20/13 rx 2` + `M8 21h8M12 17v4`) | `rewardTv` (`rect 2.5/4/19/13 rx 2.5`) |
| `film` | `film` (play `rect 3/5/18/14 rx 3 + m10 9…`) | `rewardFilm` (film-strip + sprockets) |
| `moon` | `clock` (`circle r 9 + M12 7v5l3 2`) | `rewardMoon` (crescent, closing Z) |
| `cake` | `chefHat` (three-lobe hat) | `rewardCake` (basket/bucket) |
| `coffee` | `rewardCoffeeParent` (new: `M4 10a8 8…` + `M7 10v8…M9 18v2…` — neither old `cafe` mug nor K08 cup matches P14) | `rewardCoffee` (takeaway cup) |
| `plate` | `rewardPlate` — SINGLE SOURCE (P14 HTML has no dinner row; K08 triangle + 3 outline dots used for both) | `rewardPlate` |

Unknown keys → `gift` for both (P14 fallback contract).

### Quests (`questIconFor`)

Parent canonical keeps the batch-5 P09 exacts (`questBed` flat, `questDishes`
basket, `questHoover` with legs, `questBins` with clasp; `book`/`paw`
already byte-identical). P10 omits the bins clasp and hoover legs and P08
draws the bed WITH the headboard arc — those deltas are ≤ raster and the
P09 exact is kept (batch-5 follow-up). `table`/`schoolBag`/`sprout`/
`washingMachine` are the long-standing parent look-alikes P10 Ideas already
renders (no P09 tile exists); kept as parent canonical rather than adding
four near-duplicates.

Kid draws only three quests (K03 3 tiles + K04 hero, same bed paths):

| key | parent | kid |
|---|---|---|
| `bed` | `questBed` (flat) | `questBedKid` (K04 bed) — DIFFERENT, new file |
| `dishwasher` | `questDishes` (basket) | `questDishesKid` (K03 `rect 3/4/18/16 + M3 10h18…`) — DIFFERENT, new file |
| `book`/`reading` | `book` (closed) | `questReadingKid` (K03 open `M12 6v14…`) — DIFFERENT, new file |
| `bins`/`bin`, `hoover`, `paw`/`pet` | `questBins`/`questHoover`/`paw` | SAME (no K03/K04 row — single parent source, both use parent) |
| `plate`/`table`, `bag`/`schoolBag`, `leaf`/`plants`, `shirt`/`washing` | `table`/`schoolBag`/`sprout`/`washingMachine` | SAME (only P10 draws them — single source) |
| `sofa` (seed `q-living`) | `questCard` fallback — NO design draws it | SAME (`questCard` for both) |

Aliases (`reading→book`, `bin→bins`, `table→plate`, `schoolBag→bag`,
`plants→leaf`, `washing→shirt`, `pet→paw`) resolve in both audiences, mirroring
the old `questIconAsset`/`todayIconFor` switches. Unknown → `questCard`.

K03 therefore changes for `dishwasher` (appliance → rect), `book` (closed →
open) and `bed` (`bedSit` sitting child → K04 bed) — all differ from what it
rendered — plus `bins`/`hoover` (wheelie/rounded → `questBins`/`questHoover`
parent exact, single source). `plate`/`table` keeps `table` (no change).
Tile tints are untouched (dishwasher sky, reading lilac, tidy peach, rest
neutral).

## Tests added (`audience_glyphs_test.dart`, 28)

- Constants: 4 new `NestIcons`/`NestlingIcons` point at the new files; 4
  parent quest exacts untouched.
- Exact glyphs (4): new SVGs contain `currentColor`/`stroke-width 2`/
  `viewBox 0 0 24 24` plus verbatim design paths (see §2).
- Tinted render (8 widget tests): new assets render light+dark via
  `NestIcon` with a `ColorFilter`, no exception.
- Every seeded key resolves for both audiences (2): `rewardIconKeys` 6 +
  `questIconKeys` 11 (`Seed.demo` icons equal exactly those sets) to the
  tables in §2; aliases (`reading`/`bin`/`table`) + `gift`/`questCard`
  fallbacks for both.
- Files exist (1): every `Seed.demo` quest/reward icon × both audiences is a
  file on disk.
- Merged delegation (3): P14 `rewardIconSpec` == parent (film is `film`, not
  `rewardFilm`); P10 `questIconAsset` + P08 `todayIconFor` == parent
  (`questBed`/`questDishes`); K03 kid bed/dishes/reading are the new kid
  files, distinct from `dishwasher`/`book`/`bedSit`/`questBed`.

Updated: `shared_reward_glyphs_test.dart` (both audiences; P14 pins parent),
`quest_idea_meta_test.dart` (Ideas + Active expect `questBed/questBins/
questDishes/questHoover`).

## Verification

- `cd app && dart format .` clean (0 changed on re-run).
- `flutter analyze` → `No issues found!` (no new ignores).
- `flutter test --timeout 120s test/design_system/audience_glyphs_test.dart
  test/design_system/shared_reward_glyphs_test.dart
  test/features/quests/quest_idea_meta_test.dart` → all pass.
- P14/K03/P08/P10 pins (geometry must not move):
  `flutter test --timeout 120s test/features/rewards/ test/features/quests/
  test/features/today/ test/features/kid_home/kid_home_view_test.dart
  test/features/kid_home/kid_home_geometry_test.dart` → all pass (icon
  swaps are same 24 px boxes; only paths change).
- Full `flutter test --timeout 120s` → `All tests passed!`
  (3612, 4 pre-existing skips).

## What K04 / K08 must switch to (exact — NOT edited here)

K04 (`app/lib/features/kid_home/presentation/views/quest_detail_view.dart`,
K04 branch owns it): the hero tile must use the kid bed, not the P09 flat:

```dart
import 'package:nestling/core/design_system/design_system.dart';

// was: NestIcons.questBed (P09 flat M3 18v-8… + M3 18h18)
final String hero = questIconFor('bed', audience: NestAudience.kid);
// → NestIcons.questBedKid (assets/icons/ic_quest_bed_kid.svg:
//    M2 18v-7 / M2 14h20v4 / M22 18v-4a3…h-9v3 / M6 11V8h4v3)
```

Keep the 120 px `peachTint` tile, 3-px ink border and `sh-kid` as-is — only
the asset string changes. This clears K04 `5_ui.md` deviation 1 (major).
Other quests on K04 (if ever shown) use `questIconFor(icon, audience: kid)`
with the table in §2 (only bed/dishwasher/reading differ from parent).

K08 (`app/lib/features/kid_shop/presentation/widgets/`, K08 branch owns
it): delete the screen-private `shop_reward_icons.dart` map and call the
shared single source with the kid audience:

```dart
import 'package:nestling/core/design_system/design_system.dart';

// was: shopRewardIcon(item.icon)  — or: rewardIconFor(item.icon)
final String art = rewardIconFor(item.icon, audience: NestAudience.kid);
```

which returns (all exact `K08-shop.html` `.k8-art` paths):

- `'tv'` → `NestIcons.rewardTv`
- `'film'` → `NestIcons.rewardFilm` (film-strip, NOT `film`)
- `'moon'` → `NestIcons.rewardMoon` (crescent, NOT `clock`)
- `'cake'` → `NestIcons.rewardCake` (basket, NOT `chefHat`)
- `'coffee'` → `NestIcons.rewardCoffee` (takeaway cup, NOT `rewardCoffeeParent`/`cafe`)
- `'plate'` → `NestIcons.rewardPlate`
- unknown → `NestIcons.gift`

Keep the `.k8-art` disc as-is (56 px circle, `coinTint`/`coinInk`, 32 px
glyph) — only the asset string changes. Then delete `shop_reward_icons.dart`
(or leave it re-exporting `rewardIconFor(kid)` during the merge window; do
NOT keep two diverging maps). No seed change needed. Re-run `shot.sh`
light+dark; deviations 1–3 in `docs/screens/K08/5_ui.md` should clear
(they already matched the kid glyphs; this only pins them to the shared map).

P09 needs no change (picker already draws `questBed/questDishes/questHoover/
book/questBins/paw`, which equal `questIconFor(parent)`).

VERDICT: PASS
