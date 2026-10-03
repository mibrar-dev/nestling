# Shared fix: NestPetStage seat-in-bowl + 198×86 outline — REPORT
(branch `shared/pet_stage_seat`)

Follow-up to `shared/pet_stage_explicit` (merged): in explicit mode the nest
was squashed (72 vs 86 tall) and too low (319 vs 278), and Pip stood ON the
rim instead of IN the bowl. All changes are backward-compatible: no public API
renames, no screen-code edits, legacy (non-explicit) layout bit-for-bit.
Screen branches merge and compile without edits.

Evidence read first: K03 `ui/cmp_light_8.png` + `cmp_dark_8.png` (K03 aligned
everywhere except the pet block), K03 `kid_home_view.dart` `_KidPetStage`
(call below) + `_kStageToHearts` 10.75 + `kid_home_geometry_test.dart` (nest
centre 195, box 236 → 198 visible, hearts 448, card 559),
`design/screens/light/K03-kid-home.png` (÷3 = logical px, measured directly),
`design/html-source/screens/K03-kid-home.html` (`.k3-pet` 260×236, `.pip`
152 bottom 96) + `components.css` (`.speech`, `.pet-stage`),
`app/lib/core/design_system/components/nest_pet_stage.dart`,
`app/lib/core/design_system/motion/pip_rive.dart` (`PipNestFallback` /
`PipInNest`), `app/assets/illustrations/nest.svg` (240-space, outer bowl
95…205) + `pip_v2/mochi/s3_idle_1.svg` (tuft 44.5, feet 206.5).

## Files changed

- `app/lib/core/design_system/motion/pip_rive.dart` — explicit-only:
  `rimOverlap` 20 → 44.2 (box 44.2 below the rim; v2 feet 21.2 above the box
  bottom → feet ≈23 inside the bowl), new `_explicitSlotH` 236 (fixed block
  so hearts never move) + `_explicitBleed` 31.4 (236 − 188 − 16.6; legacy
  keeps 10), `explicitGeometry()` now sets `nestTop = 236 − nestH − 31.4`
  independent of Pip (Pip may extend above the slot — negative top,
  transparent padding over the speech gap, `Clip.none` paints it) instead of
  `max(6, pipH − seat)` which forced the nest down to make room for the box;
  v1 seats its contact ≈23 below the rim (was ≈1, standing on it) via
  `rim + 23 − contact` with no clamp (still only transparent padding above).
  Removed unused `dart:math` import. Legacy branch (`explicitLayout: false`)
  untouched.
- `app/lib/core/design_system/components/nest_pet_stage.dart` — dartdoc only:
  `nestHeight` now documents K03 188 (198×86 outline: 202/240×236 by
  110/240×188) instead of 156 (198×72, squashed).
- Tests: rewrote `app/test/core/design_system/nest_pet_stage_test.dart` (11
  tests, listed below). No other test touched; full suite green.
- Docs: this report.

## What / why

1. Outline 198×86 (was 198×72, squashed). The art fills its box, so outline =
   box × (202/240 wide, 110/240 tall). 236×156 gives 198×72 (measured 72);
   236×188 gives 198×86 (measured design 86). K03 must pass 188 (new call
   below); old 156 still renders (better position, same 72 height, no
   overflow, hearts 448) so branches merge without edits.
2. Nest higher (was 41 too low). `nestTop = 236 − nestH − 31.4`: with 188 →
   16.6 within the slot (outline 91 → 278 absolute with slot top 187). Old
   `max(6, pipH − seat)` gave 70.25 (outline 132 → 319) to keep the 152 box
   inside the slot (pipTop ≥ 0). Pip now extends 16.8 above it (box
   173…323, transparent 28.2 above the head, 1.8 px of the 18 px speech gap
   left to the tail) instead of pushing the nest down 41.
3. Pip inside the bowl (was standing on the rim). Custom box 44.2 below the
   rim (was 20); v2 feet 44.2 − 21.2 = 23.0 below (301 vs 278); v1 contact 23
   below (was ≈1). Both feet lines coincide (114 within the slot); boxes
   differ by padding (custom 44.2, v1 40.1) as before. Front rim no longer
   gaps under the feet (app showed sky between feet 316 and rim 319); feet
   now overlap the back rim 23 deep, head 199 (box + 28.2), exactly the design
   199→301.
4. Slot 236, speech, hearts unchanged. Stage is always 236 (16.6 + 188 +
   31.4); slot top 187 (125 header/status + 62 speech) and bottom 423 put
   hearts centre 446.75 (≈448 ± 2) with K03's existing 10.75 gap. No screen
   margins change.
5. Layering unchanged (already back → Pip → front): `PipNestFallback`
   back-half ClipRect, Pip, front-half ClipRect; Rive `PipInNest` artboard
   letterboxes into the same `explicitGeometry` slot, so fallback, Rive-live
   and Rive-missing share one geometry.
6. Legacy untouched. Non-explicit keeps `nestTop` 6, bleed 10, `nestH ==
   nestW`, `BoxFit.fill` identical for square boxes; `shared_batch2` (explicit
   param plumbing) + `display` (legacy render) + full suite green unmodified.

## Tests added (`app/test/core/design_system/nest_pet_stage_test.dart`)

Group "explicit size centres the design slot" (K03 params 236/188/152):

- `visible outline 198×86, centred on 195 at 390` — slot 20…370, nest box
  236×188, outline 198 (202/240) × 86 (110/240), pip centred.
- `stays centred with no overflow at 320 and 430` — content 280/390, nest +
  pip on the slot axis, rects inside, no exception.
- `scales the whole scene down in a narrow slot` — 200-wide: nest 200,
  height from `explicitGeometry`, centred, no overflow (31.4/44.2 stay
  absolute, single source with the layout).
- `block height is the design 236 slot` — stage 236 ± 2.
- `PipAvatar feet sit 23 px inside the bowl` — K03 harness, box 44.2 below
  the rim, feet (box − 21.2) 23 below, centred.
- `v1 SVG pip seats its contact on the same feet line` — box 40 below,
  contact (213/240) 23 below, centred.
- `visibleNestWidth: 198 gives the same box` — ≈235 box, centred.
- `Rive and reduced-motion paths share one geometry` — `riveEnabled: true`
  with/without `disableAnimations` both degrade to the identical fallback
  slot (Rive runtime absent in tests, as on the screenshot loop).

Group "K03 harness pins the design rows (390×844, real fonts)" (125 +
speech 62 → slot 187; 236 + 10.75 → hearts 448):

- `nest 278, Pip 301, hearts 448 (Rive-disabled)` — outline 278→364 (86),
  PipAvatar feet 301 (box − 21.2) head 199 (box + 28.2) centred, Row 448.
- `nest 278, Pip 301, hearts 448 (Reduce Motion)` — same with
  `disableAnimations: true` (identical fallback frame).

Group "NestSpeechBubble matches .speech":

- `body height is the design 44 at real fonts` — unchanged (44 ± 2).

Verification on this branch: `dart format .` → 0 changed;
`flutter analyze` → No issues found!; `flutter test` → +1344 All tests
passed (11 in this file, 0 modified elsewhere).

## Exact constructor call K03 must use

Replace `nestHeight: 156` with 188 (everything else identical):

```dart
NestPetStage(
  pip: PipAvatar(
    style: _pipStyle(child.pipStyle),
    stage: stage,
    skin: _pipSkin(child.pipSkin),
    accessory: _pipAccessory(child.pipAccessory),
  ),
  speech: "Let's do some quests!",
  nestWidth: 236,
  nestHeight: 188,
  fixedPipHeight: 152,
  semanticLabel: 'Pip the ${_pipStageName(stage)}, stage $stage of 4',
)
```

(`visibleNestWidth: 198` ≡ `nestWidth: 236`; `pipSize:` stays ignored in
explicit mode. Old 156 still compiles and already seats feet 23 inside (nest
19 low, outline 72) — adopt 188 to land outline 86 at 278→364 exactly. Then
re-capture the UI shot: expect the pet-band drift gone; bowl 86 tall, Pip
199→301 in the bowl, hearts 448, card 559.)

## Follow-ups screens must do

- K03: adopt the call above (one number: 156 → 188); re-run
  `kid_home_geometry_test.dart` (nest centre 195, box 236×188 → 198×86
  visible, Pip centre 195, hearts 448, card 559) and the UI capture (light +
  dark, `DISABLE_ANIMATIONS=1`); no margin/gap changes needed (10.75 stays).
- K06/K08/P17 (other `NestPetStage`/`.pet-stage` users): no action — legacy
  path is pixel-identical; adopt explicit params only if their PNGs need a
  non-square slot (use 110/240 × height for the outline height).
- Nobody should wrap the stage in `Center` to fix centring or add negative
  margins to pull the nest up; centring and the 236 slot are the component's
  own job now.
- Optional future: `SPACING_SPEC.md` §7 still documents "K03 pet 260×236" —
  the measured-PNG slot is 236×188 + 152-pip (outline 198×86, feet 23) if the
  orchestrator wants the spec re-cut.

VERDICT: PASS
