# Shared kid background — `kid_meadow` REPORT

Design source: `design/html-source/components.css:25` (`.screen.kid`) and
`design/html-source/screens/K01-profile-picker.html:8-11,37` (`.meadow`;
identical SVG on every kid screen K01–K11). Tokens from `tokens.css`
(light `:root`, dark `[data-theme="dark"]`). Read-only UI evidence:
`../K01/docs/screens/K01/5_ui.md` deviations D3/D4 (single flat hill
+106 px low, bottom colour hill-back only).

## Files changed (all shared-dirs only, no feature code touched)

- `app/lib/core/design_system/theme/kid_meadow.dart` (NEW) — exact
  transcription: `NestMeadowGeometry` (390×136 viewBox, 62 % horizon stop),
  `kidHillFront()` (bakes `color-mix(in srgb, kid-meadow 80%, surface)` in
  Dart), `NestMeadowPainter` (the two exact `d` paths, `preserveAspectRatio
  none` stretch), `NestMeadow` (full-width 136-tall `IgnorePointer` block),
  `NestKidStarsPainter` (dark-only `--kid-stars`, 8 positions from
  `tokens.css:134`; light sets `none` so it is never mounted there).
- `app/lib/core/design_system/theme/kid_scope.dart` — `KidScope` keeps its
  exact public API (`child`, `meadowHeight` = 136, `meadowBottom` = 0,
  `meadowColor`) but now paints: 4-stop sky gradient
  (`kidSkyTop 0 % → kidSkyBottom 62 % → kidHorizon 62 % → kidMeadow 100 %`,
  hard stop at 62 %, over a `kidSkyBottom` base like the CSS
  `background-color`), the dark stars layer, and the two-tone hills pinned
  to the scope bottom. All three layers are z 0 behind content and wrapped
  in `IgnorePointer` (CSS `pointer-events:none`). `meadowColor` now tints
  `.hill-back` and rebakes `.hill-front` from it (was: single flat tint).
  Drops the `flutter_svg` tint (which flattened both hills to one colour).
- `app/lib/core/design_system/design_system.dart` — exports `kid_meadow.dart`.
- `app/assets/illustrations/meadow_hill.svg` — exact design `d` paths
  (back path differed by up to 10 px; front fill was `#A8DC97`, darker than
  the back, where the design mixes toward white: now `#CCEDC0`). Nothing in
  `lib/` loads this file anymore (painter owns both themes); it is kept
  exact for any direct loader.
- `app/test/design_system/kid_meadow_test.dart` (NEW) — see below.

## What / why

D3: the old hill was the wrong shape (SVG `d`s drifted from the HTML) and a
single `srcIn` tint, so hill-front never rendered and the crest sat ≈ 106 px
low at the gutter. Now both exact paths paint at 390×136 pinned to the
physical bottom; a bottom bar in content (K03 dock) still covers them
opaquely, so the bottom-edge owner rule holds. D4: the old bottom row was
hill-back `(191, 232, 176)`; the design bottom row is hill-front
`(204, 237, 192)` light / `(30, 65, 56)` dark — now baked by `kidHillFront`
and asserted at 8-bit. The missing gradient half (horizon/meadow stops) and
the dark stars are now painted too. Pixel-verified against
`design/screens/light|dark/K01-profile-picker.png` ÷ 3 (back-crest /
front-crest / bottom rows match § appendix).

## Tests added (`app/test/design_system/kid_meadow_test.dart`, 14 tests)

- `kidHillFront`: light bakes to (204, 237, 192); dark to (30, 65, 56).
- `NestMeadowPainter pixels (390×136)`: light + dark back-only band /
  front overlay / bottom-row sampling; above-the-hills transparency (sky
  shows through).
- `KidScope background (390×844)`: light + dark 4-stop gradient colours and
  `[0, 0.62, 0.62, 1]` stops; dark stars present / light absent; hills use
  token colours with the 80/20 front; meadow pinned full-width 136 tall at
  the screen bottom (light + dark); background never takes taps (content
  button still receives them); `meadowColor` retints back and rebakes front
  (existing 320 px contract preserved).

## K03 regression check

- `flutter test test/features/kid_home/` — all 178 pass, including the
  `K03 meadow band` grade tests and `kid_home_geometry_test.dart` pins
  (hearts 438, first card 549). No simulator run here (only the 5_ui stage
  may boot one); visual side-by-side vs
  `design/screens/*/K03-kid-home.png` stays with K03's UI check.
- K03 paints its OWN in-flow meadow band (feature-private, NOT edited):
  `app/lib/features/kid_home/presentation/views/kid_home_view.dart` —
  `_MeadowPainter` (l.786), crest constants `_kCrestLeftY/_kCrestBend/
  _kCrestControlY/_kCrestRightY` (l.134-137), usage l.550-599. K03 should
  switch that band to the shared `NestMeadow`/gradient now that core owns
  the 62 % horizon stop (its TODO at l.776 says exactly this).

## Local meadow/hill code in features (listed, not edited)

- `kid_home/.../kid_home_view.dart` — `_MeadowPainter` + crest constants +
  in-flow band (K03, see above).
- `design_system_gallery/.../gallery_colors.dart:66` — `kid-meadow` colour
  swatch only (no hill painting; no action).

## How screens use it

Every K screen already wraps its `Scaffold` with `KidScope` — no screen
change needed: the exact sky, stars (dark), and hills render behind
existing content. Screens with a taller in-flow band (K03) keep passing
`meadowHeight`/`meadowColor`; new screens needing just the hills use
`KidScope(child: …)` with defaults. Direct hills (previews): `NestMeadow()`.

## Verification

- `cd app && dart format .` — 0 changed.
- `flutter analyze` — No issues found!
- `flutter test` — all pass (2724 passed, 1 skipped, 0 failed), incl. the
  14 new tests and the full K03 suite.

## Appendix — PNG pixel map (logical px, PNG ÷ 3, x 30 / 195 / 360)

Light: above-back-crest ≈ sky grade (207, 238, 195); back-only band
(191, 232, 176); below-front + bottom row (204, 237, 192). Dark: sky grade
to (33, 65, 70); back band (30, 74, 58); front + bottom (30, 65, 56).
Hill-back crest absolute y at x 30/195/360 = 752/729/724; hill-front =
793/781/770; `.meadow` box top = 708. Stars read bright on dark
(e.g. (36, 70) → (187, 189, 204) vs sky ≈ (28, 34, 81)).

VERDICT: PASS
