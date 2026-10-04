# Shared K06 glyphs REPORT (Pip nest: sun hat + Play, Feed/Bath audit)

Source of truth: `design/html-source/screens/K06-pip.html`
(`.k6-care` lines 67–69, `.k6-ward` lines 73–76, `viewBox 0 0 24 24`,
`stroke-width 2`). The sibling-worktree references in the brief
(`../nestling-screens/K06/docs/screens/K06/6_bugs.md` "ORCH item 2
residual", `ui/cmp_light_3.png`) are not present in this worktree, so
every path below was copied verbatim from the in-worktree HTML.

## Files changed

- `app/assets/icons/ic_wardrobe_sun_hat.svg` (new)
- `app/assets/icons/ic_kid_feed.svg` (new)
- `app/assets/icons/ic_kid_play.svg` (new)
- `app/lib/core/design_system/assets/nestling_assets.dart`
  (`NestlingIcons.wardrobeSunHat`, `kidFeed`, `kidPlay`)
- `app/lib/core/design_system/components/nest_icon.dart`
  (`NestIcons.wardrobeSunHat`, `kidFeed`, `kidPlay`)
- `app/test/design_system/shared_k06_glyphs_test.dart` (new, 12 tests)
- `docs/screens/_shared/k06_glyphs_REPORT.md` (this file)

No feature code touched. No existing icon asset modified.
`pubspec.yaml` unchanged (`assets/icons/` already covers the new files).

## 1. What / why

Added the design's exact glyphs verbatim from `K06-pip.html` under NEW
names so other screens keep their look-alike assets:

- `NestIcons.wardrobeSunHat` /
  `NestlingIcons.wardrobeSunHat` → `assets/icons/ic_wardrobe_sun_hat.svg`
  (line 74: `M3 16h18l-1.6 2.4H4.6z` brim + `M7 16a5 5 0 0 1 10 0z`
  dome). Distinct from `sunHat` (`ic_sun_hat.svg`: shifted geometry
  plus an extra `M7.4 11.6h9.2` band stroke the design has no trace of).
- `NestIcons.kidPlay` /
  `NestlingIcons.kidPlay` → `assets/icons/ic_kid_play.svg`
  (line 68: `circle 12/12/9` ring + `M5 7.5c4 1 7 3.5 8 7.5` /
  `M19 7.5c-4 1-7 3.5-8 7.5` seams — a ring with two curved seams, not
  a clock and not a play triangle). Distinct from `ball`
  (`ic_ball.svg`: same ring but a `m12 7.4…` star-panel centre).
- `NestIcons.kidFeed` /
  `NestlingIcons.kidFeed` → `assets/icons/ic_kid_feed.svg`
  (line 67: `M3 11h18a9 9 0 0 1-18 0Z` bowl + `M12 11V5` stem +
  `M9 5a3 3 0 0 1 6 0` morsel). Distinct from `feedBowl`
  (`ic_feed_bowl.svg`: bowl with a paw ellipse and three kibble dots).

Audited and deliberately NOT added:

- Bath (line 69: three bubbles `9/15/5` + `16/9.5/3.5` +
  `16.5/17.5/2.5`) is byte-identical to `ic_bubbles.svg` — K06 keeps
  using `NestIcons.bubbles`. Pinned by test so a redraw cannot drift.
- Wardrobe crown (line 76) is geometrically identical to
  `ic_crown.svg` (`M6 20h12` vs relative `m2 12h12` from the same
  start point; crown body identical modulo path-command case) — K06
  keeps using `NestIcons.crown`.
- `wardrobeScarf` / `wardrobeWellies` (batch 7) re-verified
  byte-identical to lines 73/75.

`ic_sun_hat.svg`, `ic_ball.svg`, `ic_feed_bowl.svg`,
`ic_bubbles.svg`, `ic_crown.svg`, `ic_scarf.svg`, `ic_wellies.svg`
are byte-for-byte unchanged.

## 2. Tests added (`app/test/design_system/shared_k06_glyphs_test.dart`)

- `asset constants point at the new files, old untouched`
- `new icon files exist on disk`
- `ic_wardrobe_sun_hat.svg is the exact K06 design glyph`
- `ic_kid_feed.svg is the exact K06 design glyph`
- `ic_kid_play.svg is the exact K06 design glyph`
- `Bath already matches the design: no new glyph needed`
- `light/dark: <each new asset> renders tinted` (6 widget tests:
  `NestIcon(asset, color: context.nest.ink)` pumps in both themes,
  asserts the `SvgPicture` carries a `ColorFilter` tint and no
  exception — i.e. assets exist and render with the theme colour)

No placeholder view texts asserted (router/keys only per the brief;
this file asserts asset paths and icon rendering).

## 3. Follow-up K06 must do (feature code, not touched here)

In its wardrobe tiles and care buttons, replace:

- sun-hat tile → `NestIcons.wardrobeSunHat`
  (keep `NestIcons.wardrobeScarf` / `wardrobeWellies` from batch 7;
  keep `NestIcons.crown` — it already matches)
- Feed button → `NestIcons.kidFeed`
- Play button → `NestIcons.kidPlay`
- Bath button → keep `NestIcons.bubbles` (exact already)

## 4. Verification

- `cd app && dart format .` — clean (3 files formatted, no further diff)
- `flutter analyze` — `No issues found!` (no new ignores)
- `flutter test --timeout 120s` — all pass (`+3605 ~4: All tests passed!`)

VERDICT: PASS
