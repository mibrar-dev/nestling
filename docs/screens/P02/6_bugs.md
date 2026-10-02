# P02 Value tour — adversarial bug hunt (Stage 6, iteration 4)

Route `/value-tour`, feature `onboarding`, parent mode, seed `demo`, test
clock pinned to Sat 3 Oct 2026. `ORCHESTRATOR_NOTES.md` exists and is
mandatory (all 4 items verified by Stage 5). Iteration 4 closes the last
MAJOR: `ValueTourFitText` replaces the unbounded `FittedBox` shrink with a
measure-then-decide slot (fit while `slot/natural ≥ 0.92`, else full-size
ellipsis). **No open bugs remain.**

Proofs: `app/test/features/onboarding/p02_bugs_test.dart` — 13 tests, zero
skips, all enforced regressions. No screen code was changed by this stage
(tests + `docs/screens/P02/**` only).

| Id | Severity | Status |
|---|---|---|
| P02-BUG-1 | MAJOR (iter 1) | FIXED — pager 400dp, copy viewport ≥ design budget |
| P02-BUG-2 | MAJOR (iter 1) | FIXED — 38dp rows, 36dp tiles, 8dp gap, no row padding |
| P02-BUG-3 | MAJOR (iter 1) | FIXED — short screens scroll, no overflow |
| P02-BUG-6 | MINOR (iter 1) | FIXED — back → `/welcome` (in-flow + deep link) |
| P02-BUG-7 | MAJOR (iter 2) | FIXED — full titles at 390dp (device ink 81.0→243.7) |
| P02-BUG-8 | MAJOR (iter 2) | FIXED — design static copy + `Sat 4 Oct` chips |
| P02-BUG-9 | MAJOR (iter 2) | FIXED — curly quotes / em dash / U+2019 heads |
| P02-BUG-10 | MAJOR (iter 3) | FIXED — bounded fit; never paints below 0.92× |
| P02-BUG-4/5 | — | VOID — reversed by ORCHESTRATOR_NOTES 1 (→BUG-8) |

## P02-BUG-10 fix — independently verified

`ValueTourFitText` (`value_tour_preview_row.dart:106-171`) measures the
single-line natural width with a `TextPainter` at the ambient scaler:

- fit path (ratio ≥ 0.92): `FittedBox(scaleDown)` — device 390 row 1 ≈ 0.99,
  sub-perceptual, full title;
- starved path (< 0.92): full-size single-line ellipsis, **no shrink**.

Evidence this stage:

- Unit probe: slot 400 (natural 325) → fit with scale 1.0; slots 240/150
  (ratios 0.74/0.46) → no `FittedBox`, font stays 16.0, no exception.
- Screen matrix 320/375/390/430 × 1.0/1.3 and 320×568 / 375×667×1.3:
  every title renders at the full 15dp style (no shrink), no RenderFlex
  overflow, `takeException() == null`.
- Device shots `ui/app_light_5.png` / `app_dark_5.png` (both stable frames):
  row-1 title ink **x 81.3 → 243.7** (full `Empty the dishwasher`, no U+2026;
  design 81.3 → 240.7, pill starts 254), identical in both themes.
- `P02-BUG-10a/b/c` (un-skipped): effective scale 1.0 on every tested
  surface, i.e. the old 0.27/0.19/0.37 unbounded shrink cannot return.

The narrow-width fallback is full-size ellipsis rather than wrapping: the
review and UI stages both explicitly sanctioned it (review iteration 3
finding 1 fix text; review iteration 4 note 1 — a 38dp row cannot grow to
two lines inside the spec-fixed 400dp card), and the remaining text stays
legible at its token size instead of shrinking below it.

## Other checks this stage (all clean)

- **Test integrity (review finding 2):** the former tautological BUG-7 proof
  is gone; the contract test's `didExceedMaxLines == false` vacuous assertion
  was replaced by the build with a bounded starved-path assertion (no
  `FittedBox`, `didExceedMaxLines == true`, 15dp at 320×1.3).
- **Copy (owner rule):** rendered rows `Maya · weekly / Leo · once /
  Maya · daily / Maya · weekly`, chips `Sat 4 Oct`, body
  `…like “Put the bins out” — or make your own.` — character-exact to
  `P02-value-tour.html`.
- **Nav gutter/a11y:** Skip is a single semantics node (label `Skip`,
  `isButton`, tap action) at 89×44, right edge x=370 (20dp gutter);
  `NestNavBar(compact)` swap left no regression.
- **Rapid taps, back/deep links, kid guard, restart, dark tokens, money,
  timezone, async/dispose:** unchanged and covered (BUG-6 proof, P01 guard
  test, full suite); no new findings.
- **External:** the shared `test/app/router_push_test.dart` blocker was
  fixed on main (path-based contract, merge `cdd4cf5`) — the full suite is
  green, nothing outstanding for the orchestrator.

## Tracked minors (not bugs; already in the review's notes/backlog)

1. Shared `NestChip`'s 1.5dp border inflates the head row +3 (card-1 tile
   y173 vs design y170) and forces `NestSpacing.gap9` on card 2 —
   `SHARED_REQUEST.md` item 5; restore `gap10` when it lands.
2. Residual ~4px step-body ink offset vs the PNG is a browser-vs-Flutter
   Inter metric difference (box positions exact); no action.
3. `NestListRow(compact: true)` now has no callers — shared tidy-up backlog.

## Verification (run this stage, `app/`)

- `flutter test test/features/onboarding/p02_bugs_test.dart` — **13 passed,
  0 skipped, 0 failed**.
- `flutter test test/features/onboarding` — **141 passed**.
- `flutter test` (full) — **645 passed, 0 failed**.
- `flutter analyze` — `No issues found!`; `dart format` clean.
- Device evidence: `ui/app_light_5.png`, `ui/app_dark_5.png` (stable frames;
  full titles, design copy, geometry unchanged vs iteration 3).
- No screen code touched; only `p02_bugs_test.dart` and this file.

VERDICT: PASS
