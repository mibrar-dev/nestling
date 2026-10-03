# P05 · Add children — UI build (STAGE 2b, iteration 8)

Scope: `app/lib/features/family/presentation/views/**`,
`app/lib/features/family/presentation/widgets/**`, widget/view tests in
`app/test/features/family/**`. No `domain/`, `data/` or `bloc/` file touched
(`git diff --stat` shows only the two presentation files plus tests).

## CONTRACT

`2a_build_logic.md` (iteration 8) — **no contract changes**. Event/state API
stable (`FamilyLoadRequested`, `FamilyDraftChanged`,
`FamilyAddChildRequested({onSaved})`, all `FamilyState` fields and draft
defaults). No UI rework required. Re-read before finishing; the parallel logic
builder assigned the `Wrap`→`NestChipWrap` swap and the test un-skip to this
stage.

## FIXES_7.md dispositions — all three items closed

1. **Age-band pills are the design size now.** The shared `NestChip` fix
   (`shared/chip_pill_padding`, on main via `b466c96`) moves the 14 px padding
   *inside* the `DecoratedBox`, so the painted pill is `text + 28` wide and
   32 high. Measured with the **shipped** Inter faces (new
   `p05_view_metrics_test.dart`, faces loaded with `FontLoader`):

   | band | pill width (design ≈ 54 for 4–6) | height |
   |---|---|---|
   | 4–6 | 53.28 | 32 |
   | 7–9 | 52.02 | 32 |
   | 10–12 | 64.80 | 32 |
   | 13+ | 52.25 | 32 |

   No local padding hack was added; no P05 test pinned the old narrow width
   (the one place that asserted a chip `width >= 44` is satisfied by the padded
   pill and is now commented as such). New proofs pin the pill's
   **background/border rect** (the `DecoratedBox` rect must equal the chip box,
   so the fill is never narrower than the chip and the 1.5 px border is never
   painted outside it), the 8 px gaps, the left-aligned row on the card content
   edge and the single production run.
2. **P05-BUG-11 closed.**
   - Both interactive rows in `add_child_form_card.dart` now use
     `NestChipWrap` (age chips **and** swatches, per FIXES_7 item 2's main
     instruction). Layout is untouched (`RenderNestChipWrap extends RenderWrap`,
     no layout override) — the existing swatch proof (44×44 circles, 8 px gaps,
     one row, content edge x = 34) still passes unchanged.
   - `p05_bugs_test.dart`: `[P05-BUG-11]` **un-skipped** and rewritten to prove
     the two block edges (5 px above the first run, 5 px below the last run).
   - `add_children_test.dart`: the group at ~2282 is now the **functional**
     `atLeast44(chip)` proof the fix list asks for — taps 5 px above and below
     the run select the chip, a tap 7 px out changes nothing, plus the
     pill-shape/geometry test. The old "32-px effective target"
     characterisation test (which asserted the bug) is gone.
   - **Non-obvious blocker found and fixed** (this is why the swap alone did
     *not* work): the rows were wrapped in `Semantics(container: true, label:
     …)`. `RenderSemanticsAnnotations` is a `RenderProxyBox`, and
     `RenderBox.hitTest` stops at `size.contains(position)` — a `Semantics` box
     is *tight* around its child, i.e. exactly the 32-px run, so it clipped the
     widened hit test again and the taps above/below still did nothing (proved
     by dumping `hitTestInView` paths: the path contained no `RenderNestChipWrap`
     for those points). The design's `role="group" aria-label` now lives on the
     row's own `.lbl` heading (`Semantics(container: true, label: 'Age band',
     excludeSemantics: true, child: Text('Age band'))`), so the a11y group label
     is preserved and the card `Column` (whose `defaultHitTestChildren` forwards
     without a bounds check) hands the tap to `NestChipWrap`. The "chip and
     swatch groups are labelled containers" test is unchanged and green.
   - Answer to the logic builder's read-only question: every swatch's own box
     is already 44×44 (`.sw`), asserted by the existing test, so the row's hit
     widening changes no swatch geometry — the row would also have been legal
     as a plain `Wrap`; `NestChipWrap` was used anyway because FIXES_7 item 2
     says to convert both rows.
3. **Re-shoot `cmp_light_8/cmp_dark_8`** — stage 5 work, and this stage is
   simulator-forbidden. Not done here (see LEFT FOR NEXT ITERATION).

## Other owner rules touched in this iteration

- **BALANCED HEADINGS**: `.h1` in `components.css` is `text-wrap: balance`, so
  the heading now renders through `NestBalancedText` (same copy, style,
  `maxLines: 3`, ellipsis, left aligned). In the shipped Nunito the line is one
  34-px line, i.e. the design is unchanged; the gutter test measures the
  `NestBalancedText` band (350 px, x 20…370) instead of the `Text` box, because
  the balanced variant narrows its own box the way CSS does not — the band still
  shares the 20 px gutters with every other band (owner ALIGNMENT rule).
- COPY / PIP / LETTER SPACING / BOTTOM EDGE / CHILD ORDER / FONTS: unchanged
  and still green (copy code-unit asserts, no `google_fonts` anywhere, CTA panel
  runs to the physical edge, Maya then Leo from the repository).
- No `Wrap` of interactive items is left in the feature.

## Verified

- `flutter test test/features/family` → **130 passed, 0 skipped, 0 failed**
  (was 124 + 1 skipped; the skip is gone).
- `flutter analyze lib/features/family test/features/family` → No issues found.
- Regression check on files that render `/add-children` outside the feature:
  `test/app/routes_smoke_test.dart`, `router_push_test.dart`,
  `router_redirect_test.dart`, `test/design_system/shared_batch1_test.dart`,
  `shared_batch2_test.dart`, `onboarding_header_test.dart` → 76 passed.
- Production geometry re-measured (bundled fonts, 390×844): h1 350×34 one line;
  form card y 373…613; field y 421 h 76; "Age band" y 505; chip row y 527 h 32;
  swatch row y 629 (44 px, 8 px gaps); note y 679 — i.e. every gap still equals
  the HTML's `.field` 10 / `.lbl` 8 / `.chip-row` 4 / `.swatches` 4 /
  `.form-note` 6.

## LEFT FOR NEXT ITERATION

- **Stage 5 (UI check)**: re-shoot `app_light_8`/`app_dark_8` with seed
  `onboarding_kids` and build `cmp_light_8`/`cmp_dark_8`; confirm the chip pill
  backgrounds now measure ~53/52/65/52 px (not narrow ovals) and that the
  widened tap target did not shift any visible row.
- If the pixels disagree on the chip row, only the gaps are candidates: the
  proof pins 4 px above (`.chip-row { margin-top: 4px }`) and 8 px below
  (`.lbl { margin-top: 8px }`) from the CSS, and the production-metrics test
  pins the widths, so a diff should point at the shared component, not P05.

VERDICT: PASS