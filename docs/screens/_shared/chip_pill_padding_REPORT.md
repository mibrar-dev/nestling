# Chip pill padding — REPORT (branch `shared/chip_pill_padding`)

Scope: fix `NestChip` so the 14 px side padding paints INSIDE the pill
(P05 age-band chips `4–6`, `7–9`, `10–12`, `13+` rendered only as wide as
their text — the selected pill was a narrow vertical oval). Minimal,
backward-compatible shared change: one widget body reorder, no public API
change, no screen-code edits. Screen branches merge without edits.

## Files changed

- `app/lib/core/design_system/components/nest_chip.dart` — `pill()` was
  `ConstrainedBox(minWidth: 44) → Padding(horizontal: 14) → DecoratedBox →
  content`, with the padding OUTSIDE the decoration, so the background and
  the 1.5 px border painted only behind the text. Now
  `DecoratedBox → Padding(horizontal: 14) → content`: the decorated pill is
  text width + 28 wide and exactly 32 high (`.chip`: `height: 32px`,
  `padding: 0 14px`, `SPACING_SPEC` §6). The `minWidth: 44` on the visible
  pill is deliberately gone — CSS sets no min-width on `.chip`, so a pill
  narrower than 44 stays narrow visually and the 44 px minimum tap area
  comes from the existing `_ExpandedHitBox` (hit test only, no layout
  change). `NestChip.hitSlop`, `NestChipWrap`, and the 32 px layout height
  are untouched.
- Tests: NEW `app/test/core/design_system/nest_chip_test.dart` (9 tests,
  real Inter via `FontLoader` as `privacy_consent_geometry_test.dart` does).

## What / why

The padding sat outside the `DecoratedBox`, so `BoxDecoration` (surface-2
/ leaf-tint fill + 1.5 px transparent / leaf border) sized to the bare text
run instead of text + 28. Moving the `Padding` inside makes the decoration
span the full pill while the `SizedBox(height: 32)` content keeps the height
at exactly 32. `DecoratedBox` (not `Container`) still paints the border
inside the box, so no 35 px regression. Interactive chips keep the ≥44×44
tap target through `_ExpandedHitBox`; static chips lay out at the bare pill
size, matching CSS (no min-width).

## Tests added (`nest_chip_test.dart`)

Geometry group `NestChip pill geometry (real Inter)`:

- `light: pill is text width + 28 and 32 high`
- `dark: pill is text width + 28 and 32 high`
- `light: selected border spans the pill, not the text`
- `dark: selected border spans the pill, not the text`
- `narrow pill stays narrow visually, tap still spans 44` (label `A`:
  layout width < 44 and == paragraph + 28; tap 21 px off-centre selects,
  23 px falls through)

Tap group `NestChip tap targets stay ≥ 44×44`:

- `light: 5 px above/below the pill selects`
- `dark: 5 px above/below the pill selects`
- `light: 5 px above/below selects inside a NestChipWrap`
- `dark: 5 px above/below selects inside a NestChipWrap`

No test asserts placeholder view texts; geometry uses `DecoratedBox` /
`Text` rects and `TextPainter` paragraph widths only.

## Feature tests pinning the old width

None. Full suite green with the fix. The only existing width assertions
on chips are `expect(size.width, greaterThanOrEqualTo(44))` in
`app/test/design_system/shared_batch2_test.dart:26`
(`interactive chip lays out 32 tall`) and
`app/test/design_system/shared_batch1_test.dart:219`
(`chip lays out 32 high with an overlaid 44 hit area`); both use labels
whose text + 28 already exceeds 44 under the default test font, so they
still pass unmodified (verified in the full run). Do NOT edit them or any
feature code.

## Follow-up screens must do

Nothing mandatory. P05 age-band chips (`4–6`, `7–9`, `10–12`, `13+`) get
the correct 32-high, text + 28-wide pills automatically on merge — rebuild
screenshots against the design PNGs. Narrow pills (< 44 wide, e.g. single
characters) now stay narrow visually by design; the 44 px tap area is
hit-test only, so `Wrap`/`NestChipWrap` rows may measure a few px narrower
per chip than before — that is the CSS-correct layout, not a regression.

## Verification

`cd app && dart format .` clean (0 changed), `flutter analyze` →
No issues found!, `flutter test` → all pass (+990, 2 pre-existing skips).

VERDICT: PASS
