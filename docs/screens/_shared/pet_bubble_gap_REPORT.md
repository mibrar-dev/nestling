# Shared fix: NestPetStage bubbleGap + exact-44 bubble — REPORT
(branch `shared/pet_bubble_gap`)

SHARED_REQUEST K03 item 18: the shared pet stage put `NestSpacing.s2` (8)
between the bubble and the pet where K03's CSS has `.k3-pet { margin: 14px
auto 0 }`, and the bubble laid out 45 tall where the design measures 44 —
so the pet block sat at 178…414 (5 px high) and K03 compensated with a magic
21 px stage→hearts gap. All changes are backward-compatible: `bubbleGap`
defaults to the current 8 (other callers render pixel-identical except the
1 px bubble correction), no public API renames, no screen-code edits.

Evidence read first: K03 `SHARED_REQUEST.md` item 18 (design table:
`.speech` border box 125…169, `.k3-pet` 183…419 with margin 14, hearts row
435 / centre 448), the `_kStageToHearts` comment in K03
`kid_home_view.dart` (bubble 45 + gap 8 → block 178…414, gap 21 lands
hearts centre 447.75 ≈ 448), `design/html-source/components.css`
(`.speech`: padding `8px 14px`, no line-height → browser `normal`, 3 px
border, r18; `::after` 18×9 overflow tail), `SPACING_SPEC.md` §7,
`app/lib/core/design_system/components/nest_pet_stage.dart`,
`app/lib/core/design_system/motion/pip_rive.dart` (236-tall explicit slot),
`app/lib/core/design_system/tokens/spacing.dart` (`gap14` already exists).

## Files changed

- `app/lib/core/design_system/components/nest_pet_stage.dart`
  - `NestPetStage` grew `bubbleGap` (double, default `NestSpacing.s2` = 8):
    the `Padding` below the bubble now uses `EdgeInsets.only(bottom:
    bubbleGap)` instead of the hard-coded `s2`. Callers that do not pass it
    (gallery, legacy screens) keep the exact current gap.
  - `NestSpeechBubble` now lays out exactly 44 tall for one line
    (3 + 8 + 22 + 8 + 3). The 1 px was Text-widget rounding: with
    `height` omitted (browser `normal`), the painter reports 22.0 for
    "Let's do some quests!" at real Nunito ExtraBold 16 but the `Text`
    widget lays out 23.0 (measured in-test: body 45.0, text 23.0, painter
    22.0; an explicit `height: 22/16` lays out 22.0). The fix is a
    force-strut (`StrutStyle(Nunito, 16, w800, height: 22/16,
    forceStrutHeight: true)`) which pins the laid-out line to the
    browser-normal 22 while `style.height` stays null — so the K03
    typography pin (`height isNull` for `.speech`) keeps passing unchanged.
    Measured after: body 197.4×44.0, `style.height` null. Dartdoc updated
    (was "≈44").
- `app/test/core/design_system/nest_pet_stage_test.dart`
  - Tightened `NestSpeechBubble matches .speech / body height is the design
    44 at real fonts` from `closeTo(44, 2)` (which passed both 44 and the
    old 45) to `closeTo(44, 0.25)`, plus a `style.height isNull` lock.
  - New group `bubbleGap (shared/pet_bubble_gap)` with two tests (names
    below). Existing K03-harness pins (rim 269, feet 292, hearts 438, all
    ±2/±3) intentionally untouched: with the 44 px bubble they read 268 /
    291 / 437, still inside tolerance — zero churn for screen branches.
- No feature code touched (`kid_home_view.dart` still has its own
  `_kStageToHearts`; the K03 agent applies the revert below on merge).

## Verification

- `cd app && dart format .` clean (one file reformatted, no hand edits
  after), `flutter analyze` → "No issues found!" (4 new `prefer_const_*`
  infos in the added test block fixed with `const`).
- `flutter test` full suite green: 2132 passed, 1 skipped (pre-existing
  skip), "All tests passed!".
- New tests (in `app/test/core/design_system/nest_pet_stage_test.dart`,
  group `bubbleGap (shared/pet_bubble_gap)`, real Nunito via the file's
  existing `setUpAll`):
  - `bubbleGap 14 puts the K03 pet box at 183…419` — 390×844 frame, bubble
    top 125, K03 params (nestWidth 236, nestHeight 188, fixedPipHeight 152):
    bubble 125…169 (44), slot top 183 ±0.5, bottom 419 ±0.5, height 236.
  - `default gap is unchanged (s2, 8) for other callers` — constructor
    default `== NestSpacing.s2`; measured bubble→slot gap 8 ±0.5; an
    explicit `bubbleGap: s2` pump lays out bit-identical to the default
    pump (top/bottom within 0.01).

## Follow-ups screens must do

- K03 (`kid_home`, the only screen on the 14 px margin): apply both halves
  together, then re-shoot light + dark (`shot.sh` + `compare.py`) and
  re-run `kid_home_geometry_test.dart`:
  ```dart
  return NestPetStage(
    pip: PipAvatar(...),
    speech: "Let's do some quests!",
    nestWidth: _kNestBoxWidth, // 236
    nestHeight: _kNestBoxHeight, // 188
    fixedPipHeight: _kPipSlotSize, // 152
    bubbleGap: 14, // or NestSpacing.gap14 — the design's `.k3-pet` margin
    semanticLabel: 'Pip the ${_pipStageName(stage)}, stage $stage of 4',
  );
  ```
  and `_kStageToHearts` 21 → `NestSpacing.s4` (16): 125 + 44 + 14 → slot
  183…419, + 16 → hearts row 435, centre 448 — the design's own arithmetic,
  magic number gone. Known residual (out of scope, open request #16(a)):
  the nest rim then sits at ≈274 vs the design's 278 (the explicit slot's
  `_explicitBleed` 31.4 still assumes the old seat; the bleed fix moves it
  the last 4 px). Hearts and every row below are exact with this change
  alone; hero-centre geometry stays with `shared/pet_stage_seat`.
- K03b/K04/K05/K07/K10 + `design_system_gallery` (other `NestPetStage`
  users): no code action — default gap is unchanged and the bubble is 1 px
  shorter (45 → 44, inside the ±2 UI tolerance). Re-shoot only if the
  loop's UI check pins absolute rows to sub-2 px.
- Nobody should add local padding/margins around the bubble or the slot to
  recover the old 45 px body or the 8 px gap on K03; the component owns
  both numbers now (`bubbleGap`, 44 px body).

VERDICT: PASS
