# K07 · Pip evolves — stage 4 QA review (iteration 5)

Branch `screen/K07`, HEAD = `160fa6f K07: checkpoint after build (iteration 5)`.
Reviewed `git diff main...HEAD` for the K07 feature (everything under
`app/lib/features/pip/**` + `app/test/features/pip/**` is in scope per RULES §1;
the working tree also contains `seed.dart`, but that change comes from
`b00fb00` on main and is a merge artifact, not a K07 edit).

## What iteration 5 changed (vs iteration 4 HEAD `7c29857`)

- `app/lib/features/pip/presentation/widgets/pip_evolution_stats.dart`:
  removed the per-cell `FittedBox(fit: BoxFit.scaleDown)` entirely. Numbers
  now share ONE style (`NestType.kidTitle(fontSize: 30, height: 34/30)`,
  `maxLines: 1, softWrap: false`) for all three cards; labels
  (`quests done` / `coins grown` / `of 4 stages`) are uncapped and wrap like
  CSS. `IntrinsicHeight` + `CrossAxisAlignment.stretch` kept.
- `app/lib/features/pip/presentation/views/pip_evolution_view.dart`:
  caption `.kcap` keeps its copy but loses the app-only `maxLines: 3` +
  ellipsis (K07-BUG-9); hero's balanced-text comment updated to drop the
  over-precise "3.16x" justification (the app clamps to ≤1.3 — see CORRECTION).
- Tests: `k07_bugs_test.dart` (+207 lines: K07-BUG-8/9 proofs now live and
  **passing**, 2 new controls),
  `pip_evolution_stats_scales_test.dart` (rewritten around the four contracts:
  equal card heights, ONE number type size at the design's own 30/34, cards
  GROW with text scale, no app-only clamps),
  `pip_evolution_widget_test.dart` (+67: the ORCHESTRATOR_NOTES 03:03 pinned
  equal-top test at 390/320 × 1.0/1.3 × up to 9999 coins),
  `app/test/core/data/repositories_test.dart` (+29: main's K11 seed-badges
  test — merge artifact, not K07 work).

## Gate results

| Gate | Result |
|---|---|
| `dart format --set-exit-if-changed .` | clean — 643 files, 0 changed |
| `flutter analyze` | No issues found! |
| `flutter test --timeout 120s test/features/pip` | +452, all passed |
| `flutter test --timeout 120s test/features/pip/k07_bugs_test.dart` | +34, all passed (BUG-8/9 proofs green, no skips) |

No `flutter clean`, no interactive `flutter run`, no simulator, no global kills.

## ORCHESTRATOR_NOTES 03:03 — compliance check

- ✅ Per-card `FittedBox` REMOVED; three numbers use ONE identical
  `NestType.kidTitle` style at the ambient scale.
- ✅ Numbers: `maxLines: 1`, `softWrap: false` (single line, no wrap).
- ✅ Labels: `maxLines`/ellipsis gone — wrap freely like CSS.
- ✅ Cards stay equal-height via `IntrinsicHeight` + `CrossAxisAlignment.stretch`.
- ✅ Caption: `maxLines: 3` + ellipsis removed (K07-BUG-9 fix).
- ✅ Pinned test "the three stat NUMBERS share one top edge and one type size
  at 390 and 320 px, scale 1.0 and 1.3, up to 9999 coins" present and green.
- ✅ 390/1.0 geometry unchanged: card row sits at y 579..663 on a 390 screen
  (probe-measured, matches iteration 4's 110×84 cards at x 20/140/260 with
  10 px gaps, and numbers at the design's 3+12 inset).
- ✅ Next-pass probe: no new major defects; remaining sub-pixel drift ≤ 2 px
  / nothing a child would report on a light notice.

## K07-BUG-8/9 — fixed and verified live

Ran `flutter test --timeout 120s test/features/pip/k07_bugs_test.dart`: the two
proofs that were skipped failing last iteration now PASS unmodified:
- **K07-BUG-8** — numbers no longer shrink per card; at 390/1.3 and 320/1.0
  the tops' drift is < 2.0 and all three numbers paint at ONE height
  (the fix (b) control pins 34.00 px = `30/34`).
- **K07-BUG-9** — caption cap is `isNull`; still reads "the same two lines the
  hero and the sub got rid of in the K07-BUG-7 fix are still here" → resolved.

## Root-cause + why the chosen fix is the right one

The iteration-4 approach (`FittedBox(fit: scaleDown)` per cell) asked every
card to shrink independently, so three cards with different text metrics painted
three different sizes. The design's answer is: fix the card at a third of the
row, give all `<b>` ONE size and all `<span>` ONE size, let labels wrap, and let
`align-items: stretch` (default) equalise box heights — which is exactly what
the iteration-5 code now does. `IntrinsicHeight` is the still-required
companion so `stretch` has a definite cross-axis inside the scroll view.
The alternative (matrix `scaleDown` on the whole row, or a fixed height) would
either shrink the whole row non-uniformly or freeze growth at accessibility
text scales — correctly rejected.

## a11y / Children's Code / perf / errors

- No new interactive elements; stat card row remains one
  `excludeSemantics` bubble with the merged VoiceOver summary sentence.
- No analytics/ads/£/network adds; kid-facing copy unchanged.
- Error handling still via the four named `_EvolutionLoading/_Failure/_NoChild`
  cards and bloc retry — untouched this iteration.

## Findings

1. **minor** — `pip_evolution_stats.dart:190-191`: the number Text is now
   `maxLines: 1, softWrap: false` with the default `TextOverflow.clip`, so a
   9-digit coin total (`999 999 999` = 162 px wide vs the ~92 px inner card
   box at 390) paints clipped with NO ellipsis/label. Design CSS has the same
   no-shrink behaviour (it would overflow the card box), so the rendering is
   parity with the design, but it has no affordance that digits are cut off.
   The demo seed's realistic values (`120`/`60`/`175`) are fine; only a
   pathological total hits this. Suggest a future shared request for a
   compact form (e.g. `1.2k`) or a tooltip — NOT scope for K07.
2. **minor** — `pip_evolution_view.dart:341-347` and the iteration-4
   `4_review.md` finding 2: both lean on iOS 3.16x / Android 2.0x reachability
   for K07-BUG-7 severity. Iteration 4 already corrected this: `app.dart:17-20`
   clamps the OS scaler to 1.0–1.3, and the BUG-7 reachability table in
   `6_bugs.md` (iteration 3) is now formally overstated. Not a product defect;
   no code change needed. Recorded for the loop's completion criteria only.
3. **minor** — `1_plan.md:139,150,207` still names `maxLines: 4` (hero),
   `maxLines: 2` (sub) and `maxLines: 3` (caption). The product code no longer
   uses any of them, and the deviation is documented in `2b_build_ui.md` +
   `ORCHESTRATOR_NOTES 03:03`, but the plan document itself is stale. Process
   note only; no severity for the product.

## Verification of "do not report process items as findings"

- Uncommitted work, branch-behind-main, merge order: the uncommitted
  `pip_evolution_stats_scales_test.dart` churn in the working tree is stage-3
  work in flight — not reported as a defect.
- `seed.dart` / `repositories_test.dart` diffs are a main merge artifact
  (`b00fb00`), present simply because the loop merges main before build.

VERDICT: PASS