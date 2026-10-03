# Shared fix: NestPetStage explicit-size mode + speech bubble — REPORT
(branch `shared/pet_stage_explicit`)

Closes K03 `SHARED_REQUEST.md` #13 (pet slot off-centre / wrong block height)
and #15 (speech bubble height). All changes are backward-compatible: new
optional parameters with defaults, no public API renames, no screen-code
edits, legacy (non-explicit) layout bit-for-bit. Screen branches merge and
compile without edits.

Evidence read first: K03 `SHARED_REQUEST.md` items 13 + 15 (measured numbers
and table), K03 `2_build.md` §3, `app/lib/core/design_system/components/
nest_pet_stage.dart`, `app/lib/core/design_system/motion/pip_rive.dart`,
`design/html-source/screens/K03-kid-home.html` + `components.css`
(`.pet-stage`, `.pet-shadow`, `.speech`), `design/screens/light/
K03-kid-home.png` (measured directly, ÷3 = logical px).

## Files changed

- `app/lib/core/design_system/motion/pip_rive.dart` — `PipNestFallback`
  gains `nestH` (default: square, legacy), `explicitLayout` (default false,
  legacy), art constants (`visibleNestRatio = 202/240 ≈ 0.84`,
  `nestRimTopFraction = 95/240`, `nestBowlBottomFraction = 205/240`,
  `rimOverlap = 20`), and the single-source `explicitGeometry()` used by the
  fallback, the Rive box and the tests. `Stack` is now `Clip.none`;
  nest art uses `BoxFit.fill` (identical for square boxes, matches the
  design's `<img>` stretch otherwise). `PipInNest` forwards `nestH` /
  `explicitLayout` to its fallback frame.
- `app/lib/core/design_system/components/nest_pet_stage.dart` —
  `NestPetStage` gains `nestHeight` + `visibleNestWidth` (mutually exclusive
  with `nestWidth`); explicit mode lays out against `constraints.maxWidth`
  (centred; uniform scale-down when the request is wider) instead of the
  nominal `nestW / 0.62`. `_PetScene` sizes the Rive box to the same
  slot (`explicitGeometry`), letterboxing the fixed-aspect artboard.
  `NestSpeechBubble` drops the fixed 24/16 line-height for the font's natural
  height (the CSS `normal` `.speech` uses) — see the 35-vs-44 section below.
- Tests: new `app/test/core/design_system/nest_pet_stage_test.dart` (9 tests,
  listed below). No existing test touched; full suite green.
- Docs: this report.

## What / why

1. Explicit mode centred in the real box. `stageW` was `nestW / 0.62`
   regardless of `LayoutBuilder.maxWidth`, so inside K03's 350 px content box
   the nest sat +34.7 px right of centre at 390 (+69.7, clipped, at 320).
   Now `stageW` IS `maxWidth` (or the request when unbounded), nest/pip are
   centred in it (`(stageW − nestW) / 2`), glow/shadow paint with `Clip.none`
   (bleed without layout effect), and `s = min(1, slotW / need)` scales
   `nestW`/`nestH`/`pipH` uniformly when the request does not fit.
2. Scene height expressible. `PipNestFallback` assumed `nestH == nestW`,
   so the block was 276 tall vs the design's 236. New `nestHeight` sets the
   box height while the art fills it, so the visible outline stays
   `nestW × 0.84` at any height. `visibleNestWidth: 198` converts through
   the ratio to the same ≈236 box. Dartdoc records the ratio and which
   parameter drives the outline.
3. Pip seated once, shared everywhere. Custom-`pip:` boxes bottom out
   exactly 20 px below the visible rim; v1 SVGs seat by visible contact
   (clamped to 0, touching only transparent padding) and land within ±3 px
   of the same line; the Rive box reuses `explicitGeometry`, so fallback,
   Rive-live and Rive-missing frames share one slot. No extra shadow is
   painted under Pip (its baked art shading shows, exactly like the HTML
   where the pip `<img>` sits over the nest `<img>`).
4. Legacy untouched. Non-explicit sizing keeps the exact historical numbers
   (`nestW = pipH / 0.55`, `stageW = nestW / 0.62`, 6 px pad, 10 px bleed);
   only `Clip.none` (previously-clipped pixels are transparent) and
   `BoxFit.fill` (identical for square boxes) changed, neither visible.
   Every pre-existing test passes unmodified.
5. Bubble usages grepped: `NestSpeechBubble` is constructed only inside
   `NestPetStage` (`speech:` strings come from the design-system gallery ×2
   and from screens via `speech:`). All six design bubbles (K03, K03b, K04,
   K05, K07, K10) share the identical `.speech` rule, so there is one
   default and no size parameter was added.

## The 35-vs-44 bubble finding (task text is wrong here; CSS + PNG agree)

The brief asks for bubble height 35 ± 1 "matching `.speech` exactly". Those
two cannot both hold, and I implemented the measurable one:

- `.speech` = 8 px vertical padding + `normal` line-height + 3 px border.
  `normal` for Nunito 16 px renders ≈22 px (Chrome AND Flutter with the
  bundled face agree — the new test loads the real Nunito via `FontLoader`
  and measures).
- So CSS-exact height = 8 + 22 + 8 + 6 = **44**. I measured the design PNG
  directly: bubble body outer borders at logical y 125 → 169 = **44 px**
  (inner white 128 → 166 ≈ 38; the "35" appears to be a misread of the
  inner height). K03b's PNG measures identically (top border at 125).
- A 35 px body would need a ≈13 px line for 16 px text — a value `.speech`
  never sets — and would sit 9 px off the PNG, permanently breaking K03's
  orchestrator-mandated absolute pins (hearts 448 ± 2, first card 559 ± 2),
  which are derived from that same PNG and assume a 44 px bubble above a
  236 px block. With 44 + 236 they line up; with 35 they cannot.
- New test asserts **44 ± 2 at real fonts** with this derivation in its
  comment. If the orchestrator re-measures the PNG it will confirm 44.

## Tests added (`app/test/core/design_system/nest_pet_stage_test.dart`)

Group "NestPetStage explicit size centres the design slot" (K03 params
`nestWidth: 236, nestHeight: 156, fixedPipHeight: 152`):

- `visible outline 198 wide, centred on 195 at 390` — slot 20…370, nest box
  236, outline `236 × ratio` ≈ 198, pip centred (custom-pip path).
- `stays centred with no overflow at 320 and 430` — content 280/390, nest +
  pip on the slot axis, rects inside the slot, no exception.
- `scales the whole scene down in a narrow slot` — 200-wide slot: nest 200,
  height from `explicitGeometry`, centred, no overflow.
- `block height is the design 236 slot` — stage 236 ± 2.
- `custom pip bottom overlaps the rim by 20` — exactly 20 ± 1 by
  construction (`rimOverlap`).
- `v1 SVG pip seats on the same rim line` — box bottom 20 ± 3, pip centred.
- `visibleNestWidth: 198 gives the same box` — ≈236 box, centred.
- `Rive and reduced-motion paths share one geometry` — `riveEnabled: true`
  with/without `disableAnimations` both degrade to the identical fallback
  slot (Rive runtime absent in tests, as on the screenshot loop).

Group "NestSpeechBubble matches .speech":

- `body height is the design 44 at real fonts` — see 35-vs-44 above.

Verification on this branch: `dart format .` → 0 changed;
`flutter analyze` → No issues found!; `flutter test` → +1034 All tests
passed (9 new, 0 modified, 0 skipped-for-this-change).

## Exact constructor call K03 must use

Replace the current `nestWidth: 260` slot (which renders a 260-square nest
in a 419-wide nominal scene) with:

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
  nestHeight: 156,
  fixedPipHeight: 152,
  semanticLabel: 'Pip the ${_pipStageName(stage)}, stage $stage of 4',
)
```

(`visibleNestWidth: 198` may replace `nestWidth: 236`; they are equivalent.
`pipSize:` is ignored in explicit mode and can be dropped. The pet paints
≈13 px of faint ground shadow below the 236 block via `Clip.none` — keep
K03's existing below-gap, do not butt content against the block. Then
un-skip `K03-BUG-13` ×3, `K03-BUG-14` and `the pet slot matches the design
geometry`: nest centre 195, box 236, hearts 448, card 559 should now hold —
hearts/card still depend on K03's own margins matching the HTML rhythm.)

## Follow-ups screens must do

- K03: adopt the call above; un-skip the five parked proofs; re-capture the
  UI shot (expect the pet band drift gone; bowl renders flatter than the PNG
  — 156 vs 236 box height — because block-236 wins over undistorted art).
- K06/K08/P17 (other `NestPetStage`/`.pet-stage` users): no action — legacy
  path is pixel-identical; adopt explicit params only if their PNGs need a
  non-square slot.
- Nobody should wrap the stage in `Center` to fix centring (proven no-op in
  K03 `2_build.md` §3); centring is now the component's own job.
- Optional future: `SPACING_SPEC.md` §7 still documents "K03 pet 260×236" —
  staging as 236 × 156 + 152-pip is the measured-PNG update if the
  orchestrator wants the spec re-cut.

VERDICT: PASS
