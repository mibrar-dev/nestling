# Shared reward glyphs REPORT (K08 + P14 exact glyphs)

## Files changed

- `app/assets/icons/ic_reward_tv.svg` (new — exact K08 TV)
- `app/assets/icons/ic_reward_film.svg` (new — exact K08 film-strip)
- `app/assets/icons/ic_reward_moon.svg` (new — exact K08 crescent)
- `app/assets/icons/ic_reward_cake.svg` (new — exact K08 baking basket)
- `app/assets/icons/ic_reward_coffee.svg` (new — exact K08 takeaway cup)
- `app/assets/icons/ic_reward_plate.svg` (new — exact K08 dinner triangle)
- `app/lib/core/design_system/assets/nestling_assets.dart`
  (`NestlingIcons.rewardTv/Film/Moon/Cake/Coffee/Plate`)
- `app/lib/core/design_system/components/nest_icon.dart`
  (`NestIcons.rewardTv/Film/Moon/Cake/Coffee/Plate`)
- `app/lib/core/design_system/components/reward_icons.dart`
  (new — `rewardIconFor(key)` + `rewardIconKeys`, the ONE shared map)
- `app/lib/core/design_system/design_system.dart` (barrel export)
- `app/lib/features/rewards/presentation/widgets/p14_reward_meta.dart`
  (P14 art now delegates to `rewardIconFor`; tints stay screen-private;
  legacy `rewardIconSpecs` kept as a derived map for backward compat)
- `app/test/design_system/shared_reward_glyphs_test.dart` (new, 22 tests)

No other feature code touched. No existing icon asset modified.
`pubspec.yaml` unchanged (`assets/icons/` already covers the new files).

## 1. What / why

Reward rows store an icon key in the DB (`rewards.icon`: `tv`, `film`,
`moon`, `cake`, `coffee`, `plate` — `Seed.demo` writes all six).
K08 (`K08-shop.html`) and P14 (`P14-rewards.html`) each draw inline SVGs
per reward, and the app was showing look-alikes:

- Baking together showed `ic_chef_hat.svg` (which IS P14's three-lobe hat
  glyph, modulo path syntax) instead of K08's basket/bucket.
- Park café showed `ic_cafe.svg` (sit-down mug: handle + steam + saucer),
  which matches NEITHER design.
- Choose dinner showed `ic_pizza.svg` (crust band + filled dots) instead of
  K08's plain triangle + outline dots.

This change adds the six EXACT K08 `.k8-art` SVGs verbatim
(`viewBox 0 0 24 24`, `stroke-width 2`, `currentColor`) under NEW
`ic_reward_*` names so other screens keep their look-alike assets
(batch-7 precedent), and maps them in ONE shared function
`rewardIconFor(key)` in `core/design_system`. P14 now calls it; K08 must
switch to it (see below). Unknown keys fall back to `gift`, matching the
P14 fallback contract.

## 2. K08 vs P14 agreement (kid wins where they differ)

Source: `design/html-source/screens/K08-shop.html` cards 0–5 vs
`design/html-source/screens/P14-rewards.html` rows 0–4
(`design/screens/light|dark/K08-shop.png`, `P14-rewards.png` render the
same drawings; the HTML paths are the exact source).

- `tv` (screen time): SAME TV concept. K08 `rect 2.5/4/19/13 rx 2.5` vs
  P14 `rect 2/4/20/13 rx 2` + identical `M8 21h8M12 17v4` stand.
  Trivial 0.5 px coord difference; kid wins (`ic_reward_tv.svg`).
- `film` (Friday film): DIFFERENT concept. K08 film-strip
  (`rect 2.5/4/19/16` + `M7 4v16M17 4v16` + four sprocket ticks) vs P14
  play button (`rect 3/5/18/14 rx 3` + `m10 9 5 3-5 3V9z`). Kid wins.
- `moon` (stay up later): DIFFERENT concept. K08 crescent
  (`M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8Z`) vs P14 clock
  (`circle r 9` + `M12 7v5l3 2`). Kid wins.
- `cake` (Baking together): DIFFERENT object. K08 basket/bucket
  (`M8 10.5a4 4 0 0 1 8 0` + trapezoid
  `M5 10.5h14l-1.2 9.2A2 2 0 0 1 15.8 21.5H8.2a2 2 0 0 1-2-1.8Z` +
  `M12 4.5v3`) vs P14 three-lobe chef hat
  (`M6 13.5A3.5…H6z` + `M6 13.5V19h12v-5.5`, byte-identical to the old
  `ic_chef_hat.svg` modulo relative/absolute syntax). Kid wins.
  This is K08 5_ui deviation 1 (major).
- `coffee` (park café): DIFFERENT drawing. K08 takeaway cup
  (`M12 3.5a5 5 0 0 1 5 5H7a5 5 0 0 1 5-5Z` dome lid +
  `M9 8.5h6l-1.5 11.2a1.6 1.6 0 0 1-1.6 1.3h-.8…` tapered body, no
  handle/steam/saucer) vs P14 dome + box + legs
  (`M4 10a8 8 0 0 1 16 0` + `M7 10v8h10v-8` + `M9 18v2M15 18v2`).
  Kid wins. Neither matches old `ic_cafe.svg`. K08 5_ui deviation 2.
- `plate` (Choose dinner): P14 HAS NO dinner row (its HTML lists five
  rewards then `+ New reward`); K08 draws a plain triangle
  (`M12 3 3.2 18.8a1 1 0 0 0 .9 1.4h15.8a1 1 0 0 0 .9-1.4Z`) + three
  STROKED outline dots (`circle r 1.1`, inherit `fill:none stroke 2`).
  The seed `plate` key uses this K08 glyph on both screens. Distinct from
  old `ic_pizza.svg` (crust band + filled `currentColor` dots).
  K08 5_ui deviation 3 (minor).

P14 therefore adopts the K08 drawings for `film`, `moon`, `cake`,
`coffee`, `plate` (and the 0.5 px `tv` shift) — a deliberate fidelity
change on the parent side so the two screens agree on one map, per the
task ruling. Tints are unchanged (P14 `sky/lilac/peach/coin/leaf/leaf`;
K08 discs stay `coinTint`/`coinInk`).

## Tests added (`app/test/design_system/shared_reward_glyphs_test.dart`, 22)

- Constants: new `NestIcons`/`NestlingIcons.reward*` point at the new
  files; old `screenTime/film/filmStrip/clock/moon/chefHat/cafe/pizza`
  untouched.
- Exact glyphs (6): each new SVG contains `currentColor`/`stroke-width 2`/
  `viewBox 0 0 24 24` plus its verbatim K08 path data (see §2).
- Tinted render (12 widget tests): all six assets render light+dark via
  `NestIcon` with a `ColorFilter`, no exception.
- Single source: `rewardIconFor` covers all six seed keys + `gift`
  fallback; `Seed.demo` icons equal exactly that key set and every
  `rewardIconFor(row.icon)` file exists on disk; P14
  `rewardIconSpec(key).asset == rewardIconFor(key)` with the historical
  tints, legacy `rewardIconSpecs` agrees, unknown keys yield the neutral
  gift tile.

## Verification

- `cd app && dart format .` clean (0 changed on re-run).
- `flutter analyze` → `No issues found!` (no new ignores).
- `flutter test --timeout 120s test/design_system/shared_reward_glyphs_test.dart`
  → 22/22 pass.
- P14 pins (geometry must not move):
  `flutter test --timeout 120s test/features/rewards/` → all pass
  (117, incl. `reward_card_widget_test.dart` 122 px card / 40 px tile /
  25 px pill / 51×31 track / 44×44 edit rects).
- Full `flutter test --timeout 120s` → `All tests passed!`
  (3593, 4 pre-existing skips).

## What K08 must switch to (exact)

In `app/lib/features/kid_shop/presentation/widgets/` (NOT edited here —
K08 branch owns it): delete the screen-private
`shop_reward_icons.dart:20` map (`shopRewardIcon`) and call the shared
single source instead:

```dart
import 'package:nestling/core/design_system/design_system.dart';

// was: shopRewardIcon(item.icon)
final String art = rewardIconFor(item.icon);
```

which returns (all exact `K08-shop.html` `.k8-art` paths):

- `'tv'` → `NestIcons.rewardTv` (`assets/icons/ic_reward_tv.svg`)
- `'film'` → `NestIcons.rewardFilm` (film-strip, NOT `film`/`filmStrip`)
- `'moon'` → `NestIcons.rewardMoon` (crescent, NOT `moon` without Z)
- `'cake'` → `NestIcons.rewardCake` (basket/bucket, NOT `chefHat`/`basket`)
- `'coffee'` → `NestIcons.rewardCoffee` (takeaway cup, NOT `cafe`)
- `'plate'` → `NestIcons.rewardPlate` (plain triangle, NOT `pizza`)
- unknown → `NestIcons.gift`

Keep the `.k8-art` disc as-is (`56 px circle`, `coinTint`/`coinInk`,
`32 px` glyph) — only the asset string changes. Then delete
`shop_reward_icons.dart` (or leave it re-exporting `rewardIconFor` during
the merge window; do NOT keep two diverging maps). No seed change needed
(`cake`/`coffee`/`plate` keys are fine). Re-run `shot.sh` light+dark;
deviations 1–3 in `docs/screens/K08/5_ui.md` should clear.

VERDICT: PASS
