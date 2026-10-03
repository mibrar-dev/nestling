# Shared fix: NestSpeechBubble tail matches `.speech::after` — REPORT
(branch `shared/speech_tail`)

The tail was an in-flow 18×10 box under the body with a surface-coloured
inner triangle; the CSS (`design/html-source/components.css:192`) is a solid
ink `::after` triangle, 18 wide × 9 tall, hanging 9 px below the bubble as
overflow. K03 dark measured the app tail ≈10 px too tall with a white fill
(23 px vs 13 px). The body was already correct and is untouched.

Evidence read first: `design/html-source/components.css:191-192`
(`.speech` + `.speech::after`), `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/design/SPACING_SPEC.md` (§7 pet-stage),
`tools/screens/stages/common.md` (owner rules),
`app/lib/core/design_system/components/nest_pet_stage.dart`
(`NestSpeechBubble`, `_TailPainter`),
`app/test/core/design_system/nest_pet_stage_test.dart`,
`app/test/features/kid_home/kid_home_view_test.dart`,
`app/test/features/kid_home/kid_home_geometry_test.dart`,
`design/html-source/screens/K03-kid-home.html`
(`.k3-stage` column, `.k3-pet` 14 px top margin — the 9 px tail fits inside
that gap as overflow, exactly as in CSS).

## Files changed

- `app/lib/core/design_system/components/nest_pet_stage.dart` —
  `NestSpeechBubble` is now a `Stack(clipBehavior: Clip.none)`: the body
  `Container` (unchanged: max-width 260, r18, 3 px ink border, 8×14 padding,
  Nunito 16 w800, ink) plus a `Positioned(bottom: -9, left: 0, right: 0)`
  `Center` holding a `CustomPaint(size: 18×9)`. Positioned children do not
  size the Stack, so the laid-out box is the body alone and nothing below
  is pushed — the CSS overflow behaviour. New `tailWidth = 18` /
  `tailHeight = 9` constants document the `::after` geometry.
  `_TailPainter` now takes only `inkColor` and paints one solid triangle
  `(0,0)–(18,0)–(9,9)`; the surface inner triangle is deleted. Light and
  dark both paint `tokens.ink`.
- `app/test/core/design_system/nest_pet_stage_test.dart` — new tail group
  (5 tests, below); the K03 harness pins move up ~9 px (rim 269, feet 292,
  hearts 438) with comments explaining the overflow shift; header comments
  updated (speech 62 → 52 = 44 body + 8 stage gap).
- `app/test/features/kid_home/kid_home_view_test.dart` — the
  `speech bubble matches .speech` test now asserts the overflow contract
  (bubble box == body box; 18×9 tail centred with top flush at body bottom)
  instead of the old in-flow `greaterThan`.
- `app/test/features/kid_home/kid_home_geometry_test.dart` — design-row
  pins move up ~9 px (rim 269, bowl 355, feet 292, head 190, hearts 438,
  first card 549) with `shared/speech_tail` notes.
- `app/test/features/kid_home/k03_bugs_test.dart` — one comment updated to
  the new geometry-test pins (no assertions changed).
- Docs: this report.

## What / why

1. Solid ink, exact CSS size. `border: 9px solid transparent` with
   `border-top-color: ink; border-bottom: 0` is an 18×9 downward triangle;
   the painter now draws exactly that — no second white path.
2. Top edge flush with the bubble's outer bottom edge. `bottom: -9px` puts
   the pseudo-element's top on the container's bottom edge; `Positioned(
   bottom: -tailHeight)` is the Flutter equivalent (the Container's
   border-box bottom, since Flutter paints the 3 px border inside the box).
3. Overflow, not layout. `::after` is absolutely positioned and adds no
   in-flow height; the `Positioned` tail likewise leaves the Stack sized to
   the body. The old `Column(Container + 18×10 paint)` added 10 px of layout
   that pushed the pet/hearts/cards down — the measured +10 px.
4. Backward-compatible: `NestSpeechBubble(text:)` signature unchanged; only
   additions are the two `tailWidth`/`tailHeight` constants. No screen code
   touched (`app/lib/features/**/presentation/**` untouched); screens pick
   the fix up by merging.

## Tests added (`app/test/core/design_system/nest_pet_stage_test.dart`)

Group `NestSpeechBubble matches .speech` (real Nunito fonts), all using
`pumpNest` + a paper-backed `RepaintBoundary` probe for raster sampling:

- `light: tail is 18x9, centred, flush with the body` — paint rect
  18 ±0.5 × 9 ±0.5, `CustomPaint.size == Size(18, 9)`, tail centre-x ==
  body centre-x == bubble centre-x, tail top == body bottom == bubble
  bottom; painter `inkColor == tokens.ink`.
- `dark: tail is 18x9, centred, flush with the body` — same in dark
  (dark ink token).
- `light: tail centre paints ink, 1px below tip paints background` —
  raster: tail-centre pixel == ink, 1 px below the tip == paper.
- `dark: tail centre paints ink, 1px below tip paints background` — same
  in dark.
- `laid-out height excludes the tail overflow` — `getSize(bubble) ==
  getSize(body)`; tail top == bubble bottom, tail bottom == bubble
  bottom + 9.

Verification on this branch: `dart format .` → 0 changed;
`flutter analyze` → No issues found!;
`flutter test` → All tests passed (1928 + ~1 skipped, 0 failed; 21 in the
shared file).

## Follow-up screens must do

- K03 (`kid_home`, K03b/K04/K05/K07/K10 use the same `.speech` bubble):
  re-capture light + dark UI shots (`shot.sh` + `compare.py`). Expect the
  white-filled 10 px tail gone, replaced by the solid 9 px ink triangle,
  and every row under the bubble ~9 px higher (rim ≈269, hearts ≈438,
  first card ≈549 at 390×844 real fonts). The geometry pins in
  `kid_home_geometry_test.dart` already carry the new values; confirm the
  side-by-side heat-map matches the design PNG tail (13 px region incl.
  border vs the old 23 px).
- K03b/K04/K05/K07/K10 + `design_system_gallery` (embed `NestPetStage`):
  no code action — rendering follows the shared widget. Re-shoot only if
  the loop's UI check measures the tail or absolute rows.
- Known pre-existing spacing (unchanged, out of scope): the stage gap below
  the bubble is 8 px (`NestSpacing.s2`) while K03's CSS uses a 14 px
  `.k3-pet` top margin, so the 9 px overflow tail overlaps the pet slot by
  ≈1 px in-app (5 px clearance in design). Filed here for the screens to
  confirm visually; widening the gap would move absolute rows again, so it
  needs an orchestrator call, not a silent tweak.

VERDICT: PASS
