# P02 Value tour — test notes (Stage 3, iteration 4)

Route `/value-tour`, feature `onboarding`, parent mode. Tests live in
`app/test/features/onboarding/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every
router test ends with `disposeApp()`. No screen, bloc, route or design-system
code was changed by this stage.

Two blockers cleared since iteration 3, and this pass turns the new screen
behaviour into enforced contracts:

1. **The shared push/pop blocker is fixed** — `cdd4cf5` merged
   `router_push_test_fix`; that contract now asserts router paths instead of
   placeholder titles, so the full suite is green for the first time.
2. **P02-BUG-10 landed** — the unbounded `FittedBox` title slot (which the
   iteration-3 fix introduced) became `ValueTourFitText`: fit at
   `slot ÷ natural ≥ 0.92`, otherwise full-size with ellipsis, so the design's
   15/600 type never paints sub-perceptibly small.

## Tests added this stage

`value_tour_view_test.dart` — 137 → **141 tests** (4 added): a unit contract
for `ValueTourFitText` at text scale 1.0 and 1.3.

**Why a unit contract and not another screen test:** both halves of the title
contract are decided by the *ratio* of slot width to natural text width, so the
tests measure the natural width with a `TextPainter` at the ambient scaler and
then hand the widget an exact slot (1.00×, 0.95×, 0.92×, 0.50×). That makes
them independent of the ~2x-wide widget-test font — which cannot judge
fitting at all (a probe found 7 of 9 single-line paragraphs reporting
`didExceedMaxLines` at 390, and `p02_bugs_test.dart` P02-BUG-7 now relies on
the device shot for the 390dp "in full" evidence).

- **A slot at or above 0.92 scales, never truncates (×2 scales)** — at 1.00×,
  0.95× and 0.92× the title paints at exactly that scale and does not exceed
  its max lines. Pins the `≥ minScale` branch, the boundary value itself, and
  the "fitting is preferred over truncating" preference.
- **A starved slot ellipsises at full size (×2 scales)** — at 0.50× there is no
  `FittedBox` in the tree at all (a fit there *is* the BUG-10 shrink), the
  painted style is the 15dp token size (the ambient scaler is applied by
  `MediaQuery`, never baked in), and the paragraph truncates honestly.

Together these make a regression to an unbounded shrink fail in the test suite
rather than only on a device screenshot.

## Re-verified, unchanged and still green

- **P02-BUG-10a/b/c** in `p02_bugs_test.dart` (320×1.0, 320×1.3, 390×1.3)
  enforce the no-shrink rule through the screen at the real slots; **zero
  skips** in that file (13 proofs, including the new BUG-10 set and the
  rewritten, no-longer-tautological BUG-7).
- 18-combo width × scale × theme matrix; pager geometry and clamp; the three
  card contents and the design's static copy; the 5 bloc states;
  `Seed.empty`/`Seed.fresh` and the seed-independence snapshot; the copy
  character audit (U+2013/U+2019/U+00B7/U+201C/U+201D/U+2014 and the ASCII
  sweep) and the CHILD ORDER ruling; PipAvatar rule; navigation; PopScope back
  to `/welcome`; the owner-rule BOTTOM EDGE pixel proofs (light + dark, inset 0
  and 34dp) and the ALIGNMENT gutters.
- The build's rewrite of my earlier "no truncation at 320 × 1.3" test to the
  sanctioned contract (no `FittedBox` below the bound, full-size style, honest
  ellipsis) was reviewed and kept: it is more specific than what it replaced.

## Results (run by this stage, `app/`)

- `dart format .` — 364 files, 0 changed on final pass.
- `flutter analyze` — `No issues found!`
- `flutter test test/features/onboarding` — **141 passed, 0 failed,
  0 skipped**.
- `flutter test` (full suite) — **645 passed, 0 failed, 0 skipped**.

## Bugs found

**None.** No test exposed a defect in the screen this iteration, and no screen
code was patched.

Test-authoring corrections made before gating (not screen bugs): the initial
version of the fallback assertion contained a nonsense font-size expression
(`15 * textScale / 1.3 * …`), and the probe used a scaler that disagreed with
the widget's `MediaQuery` scaler, which would have made the 1.3 slot ratios
wrong; both were fixed before the suite was run.

Residual observations (non-blocking, carried):

- The 390dp "design names render in full on one line" requirement is verified
  on the device screenshot by the UI stage (title ink 81.0→244.0, pill at 254),
  not by a widget test — the test font cannot express it. The unit contract
  above covers the rule that governs it.
- The lazy route-level `BlocProvider` (`onboarding_routes.dart:36-40`) runs its
  load event only on the first read; unchanged and pinned deliberately.
- Uncommitted build work in the worktree (process item, per the stage rules).

VERDICT: PASS