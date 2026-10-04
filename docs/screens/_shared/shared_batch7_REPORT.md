# Shared batch 7 REPORT (K06 Pip SHARED_REQUEST §§1,2,3,5,6)

## Files changed

- `app/assets/icons/ic_wardrobe_scarf.svg` (new)
- `app/assets/icons/ic_wardrobe_wellies.svg` (new)
- `app/lib/core/design_system/assets/nestling_assets.dart`
  (`NestlingIcons.wardrobeScarf`, `wardrobeWellies`)
- `app/lib/core/design_system/components/nest_icon.dart`
  (`NestIcons.wardrobeScarf`, `wardrobeWellies`)
- `app/lib/core/data/seed.dart` (`_wardrobeDemo` prices)
- `app/lib/core/design_system/motion/pip_rive.dart`
  (`PipNestFallback` + `PipInNest`: `slotHeight`, `pipBottom`, `nestFit`,
  `showGlow`, `showGroundShadow`; `explicitGeometry` extended)
- `app/lib/core/design_system/components/nest_pet_stage.dart`
  (`NestPetStage` + `_PetScene`: same five params, forwarded)
- `app/lib/core/design_system/components/nest_kid_button.dart`
  (`Widget? trailing`)
- `app/lib/core/design_system/components/nest_dashed_border.dart` (new:
  `NestDashedBorder` + `NestDashedBorderPainter`)
- `app/lib/core/design_system/design_system.dart` (barrel export)
- `app/test/core/data/repositories_test.dart` (seed-price pin 75 → 85)
- `app/test/design_system/shared_batch7_test.dart` (new, 20 tests)

No feature code touched. No existing icon asset modified.
`pubspec.yaml` unchanged (`assets/icons/` already covers the new files).

## 1. Wardrobe glyphs (§5)

Added the design's exact Scarf and Wellies SVGs verbatim from
`design/html-source/screens/K06-pip.html` (`.k6-ward` lines 73/75,
`viewBox 0 0 24 24`, `stroke-width 2`) under NEW names so other screens
keep their look-alike assets:

- `NestIcons.wardrobeScarf` /
  `NestlingIcons.wardrobeScarf` → `assets/icons/ic_wardrobe_scarf.svg`
  (`M5 3h4v18H5z` + `M11 3h4v5a2 2 0 0 1-4 0z` + `M7 9v6`)
- `NestIcons.wardrobeWellies` /
  `NestlingIcons.wardrobeWellies` → `assets/icons/ic_wardrobe_wellies.svg`
  (`M8 3v8l-2 4.2A3 3 0 0 0 8.7 20h5.6A2.4 2.4 0 0 0 16.6 15l-2.6-4V3z`
  + `M6 3h4M14 3h4`)

`ic_scarf.svg`, `ic_wellies.svg`, `ic_sun_hat.svg`, `ic_crown.svg` are
byte-for-byte unchanged.

## 2. Wardrobe prices (§6)

Grep of `design/html-source` (all screens): Wellies/Crown prices appear in
exactly ONE design — `K06-pip.html` lines 75–76 (Wellies 30, Crown 60).
No other screen or HTML source prices these items (the `30/60/40/120`
hits elsewhere are coin pills, quest coins, and Leo's scarf 30).

Seed mirrors the designs, so `_wardrobeDemo` now writes the design
numbers for both children:

- Maya wellies 40 → 30, crown 120 → 60
- Leo wellies 40 → 30, crown 120 → 60
- (Leo scarf 30 and both owned 0 prices untouched)

One merged test pinned the old seed value and was updated (seed pin only,
no behaviour weakened):

- `app/test/core/data/repositories_test.dart` `pip care, wardrobe and
  look`: Maya 120 − feed 5 − wellies = 75 → 85.

## 3. NestPetStage K06 slot (§1)

`NestPetStage` / `PipNestFallback` / `PipInNest` / `_PetScene` gain five
optional params, the same pattern as K03's explicit mode (all defaults
reproduce K03 bit-for-bit):

- `slotHeight` (default null → 236 block): K06 passes 206
  (`.k6-pet { height: 206px }`; nest sits flush `slotHeight − nestH`).
- `pipBottom` (default null → rim-seated `rimOverlap` 44.2): K06 passes 81
  (`.k6-pet .pip { bottom: 81px }`; both pip boxes seat
  `slotH − pipBottom − pipH` = −9, the design's 9 px overhang, `Clip.none`).
- `nestFit` (default `BoxFit.fill` = K03 stretch): K06 passes
  `BoxFit.contain` (square `nest.svg` fits uniformly into 230 × 206 →
  206 × 206, 12 px letterbox each side, as the browser `<img>` does).
- `showGlow` (default true): K06 passes false (its markup has no
  `.pet-stage`, so no `::before` glow even in dark).
- `showGroundShadow` (default true): K06 passes false (relies on the baked
  shadow inside `nest.svg`, no extra blurred ellipse).

`PipNestFallback.explicitGeometry` takes optional `slotHeight`/`pipBottom`;
nulls return the exact K03 numbers (nestTop 16.6, stage 236). K03 geometry
pins still pass (see Verification).

## 4. NestKidButton third row (§2)

`NestKidButton` gains `Widget? trailing` (default null → historical
icon + label layout unchanged). Rendered after the label with the SAME
`gap` as the icon/label pair in both axes (K06 passes `axis: vertical,
gap: 3`); visual-only (`ExcludeSemantics`, include the meaning in
`semanticLabel`, e.g. "Feed Pip, costs 5 coins"); same 3 px ink border,
`--r-l`, `--sh-kid`, `translateY(4px)` press, disabled `opacity .45`.

## 5. Dashed border (§3)

New shared `NestDashedBorder` (plus public `NestDashedBorderPainter`):
3 px dashed `--ink-2` stroke on `--surface-2` with no shadow, dash 6 /
gap 3 (measured off the design PNG), honouring the card radius
(default `--r-l` 24, inset half-stroke like CSS `border`). Paints as
`CustomPaint.foregroundPainter` so the stroke lands ON the fill, exactly
where CSS puts a dashed `border` (a background painter is hidden under an
opaque fill — the K06-BUG-6 trap). Defaults (`color: ink2`,
`strokeWidth: kid.borderWidth`, `dashLength: 6`, `dashGap: 3`,
`borderRadius: 24`) ARE the locked-tile style; overrides available.

K06 can delete: the entire screen-local
`app/lib/features/pip/presentation/widgets/pip_wardrobe_tile.dart`
`_DashedBorderPainter` class (≈45 lines: `_kDashLength`, `_kDashGap`,
`_DashedBorderPainter`) plus its `foregroundPainter:` wiring, replacing
it with `NestDashedBorder`. Keep the tile's own fill/padding/shadow logic;
only the border painter goes.

## Tests added (`app/test/design_system/shared_batch7_test.dart`, 20)

- Glyphs: constants point at new files + old untouched; both SVGs contain
  the exact K06 paths and `currentColor`/`stroke-width 2`; light+dark tinted
  render (4 widget tests).
- Prices: `Seed.demo` writes wellies 30 / crown 60 for Maya+Leo, owned 0
  and Leo scarf 30 untouched.
- PetStage: defaults unchanged; `explicitGeometry` K06 (0/−9/206) and K03
  unchanged; K06 slot lays out 230×206 nest flush bottom + 134 pip 81 up
  with no glow; both nest halves use `contain`.
- KidButton: defaults null; vertical trailing 3 px under label; trailing is
  semantics-excluded (one announcement); enabled keeps the tap action.
- DashedBorder: defaults 6/3/r-l; foreground (not background) r-l stroke;
  default colour ink-2 at 3 px kid border.

## Verification

- `cd app && dart format .` clean (0 changed on re-run).
- `flutter analyze` → `No issues found!` (no new ignores).
- `flutter test --timeout 120s test/design_system/shared_batch7_test.dart`
  → 20/20 pass.
- K03 pins (must not move):
  `flutter test --timeout 120s
  test/features/kid_home/kid_home_geometry_test.dart
  test/core/design_system/nest_pet_stage_test.dart
  test/core/data/repositories_test.dart
  test/design_system/shared_batch2_test.dart` → all pass.
- Full `flutter test --timeout 120s` → `All tests passed!`
  (+3413 ~4, 4 pre-existing skips).

## What K06 must switch to (exact)

In `app/lib/features/pip/presentation/`:

1. Wardrobe icons: `pip_look.dart` (or wherever `NestIcons.scarf` /
   `wellies` feed the wardrobe tiles) → `NestIcons.wardrobeScarf` and
   `NestIcons.wardrobeWellies`. Sun hat and crown stay (`sunHat`, `crown`
   already match the design geometry).
2. Pet slot: delete `widgets/pip_nest_slot.dart` (`PipNestSlot`,
   `kPipSlotWidth/Height`, `kPipNestArtWidth/Height`,
   `kPipSlotPipHeight/Bottom`) and render:
   ```dart
   NestPetStage(
     riveEnabled: false,
     nestWidth: 230,
     nestHeight: 206,
     fixedPipHeight: 134,
     slotHeight: 206,
     pipBottom: 81,
     nestFit: BoxFit.contain,
     showGlow: false,
     showGroundShadow: false,
     pip: PipAvatar(...),
   )
   ```
   (needs `import 'package:flutter/material.dart'` for `BoxFit` if not
   already imported). Centring/margins (`margin: 9px auto 0`) stay in the
   screen.
3. Care buttons: delete `widgets/pip_care_button.dart` (`PipCareButton`,
   `kPipCareButtonHeight/IconSize/LabelSize`) and render each as:
   ```dart
   NestKidButton(
     label: 'Feed', // / 'Play' / 'Bath'
     axis: Axis.vertical,
     gap: 3,
     minHeight: 91, // kPipCareButtonHeight
     fontSize: 17, // kPipCareLabelSize
     contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
     color: NestKidButtonColor.peach, // / sky / white
     icon: NestIcon(NestIcons.feedBowl, size: 24),
     semanticLabel: 'Feed Pip, costs 5 coins', // etc.
     onPressed: ...,
     trailing: <coin row or Free pill>,
   )
   ```
4. Wardrobe locked border: delete `_DashedBorderPainter`, `_kDashLength`,
   `_kDashGap` in `widgets/pip_wardrobe_tile.dart` and wrap the locked tile
   in `NestDashedBorder(child: ...)` (defaults already are the locked
   style). Owned tiles keep their solid `Border.all` path.
5. Prices: nothing to change in the view — it already renders
   `watchWardrobe(item).priceCoins`; the seed now supplies 30/60. Any K06
   test that pinned 40/120 must follow the seed (see `repositories_test`
   75 → 85 precedent).

VERDICT: PASS
