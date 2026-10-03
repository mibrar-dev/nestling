# P06 Pocket money setup — UI build (Stage 2b, iteration 6)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding
(P05 → P06 → P07). Owned in this stage:
`app/lib/features/pocket_money/presentation/{views,widgets}/**` and the
view/widget tests under `app/test/features/pocket_money/`.

## CONTRACT CHANGES (from `2a_build_logic.md`)

None — "No event/state/repository signature changes; no files in the logic
layer needed edits this iteration. The UI builder's contract is exactly as in
iterations 3–5." Re-read before finishing: nothing to migrate.

## Starting state

The loop merged `main` into `screen/P06` (`310514a`) **before** this stage, so
both shared fixes behind iteration 5's open bugs are now in the worktree:

* `shared/balanced_text_ellipsis` (`9ba19ab`) — `NestBalancedText` no longer
  hard-codes `ellipsis: '…'` in `lineCountFor` and defaults to
  `overflow: TextOverflow.clip`, which is what un-collapsed the H1.
* `P06WeeklyStepper` (feature-private, `presentation/widgets/`) already renders
  the design's `&minus;` (U+2212) paired with U+002B `+`.

Consequence: **P06-BUG-11 and P06-BUG-12 no longer need a skip.** Both proofs in
`p06_bugs_test.dart` were already un-skipped and green in the merged tree; I
verified there are **zero `skip:` occurrences** left anywhere in
`app/test/features/pocket_money/` and re-ran them (below). The orchestrator
rule "keep using `NestBalancedText`; do not work around it" is honoured —
`_SetupTitle` still renders the copy through `NestBalancedText`, no local
`maxLines`/overflow override was added.

## FIXES_5 — item by item

### From `4_review.md`

| # | Item | State after the `main` merge | Action this stage |
|---|---|---|---|
| 1 | **MAJOR** — H1 collapsed to one ellipsized line (`How does pocket mone…`), dragging the card 34 px up | **Fixed by shared `9ba19ab`**; the view already used `NestBalancedText`. Verified the rendered paragraph is 350×68, `didExceedMaxLines == false`, card back at 415–684 | No view edit (a local override would violate the rule). **Added a new guard**: the H1 must break *after "money"* in the balanced box — see tests below |
| 2 | **MAJOR** — no real-font geometry test pinning the 07:22 y values | `pocket_money_setup_view_geometry_test.dart` exists (real `FontLoader` Inter/Nunito) | **Extended** with an H1-break guard and a full dark-mode pass |
| 3 | **MAJOR** — stepper minus is `'-'` (U+002D), not `&minus;` (U+2212) | `P06WeeklyStepper` renders `kP06StepperMinusGlyph = '−'`; `p06_weekly_stepper_widget_test.dart` pins it | None needed; **SHARED_REQUEST item 4** stands (shared `NestStepper` still hard-codes `'-'`, no glyph override) |
| 4 | **MINOR** — the `role="group" aria-label="Payout day"` section label was dropped from the day strip | `_DayCell` already labels each cell `Payout day: Mon` … `Payout day: Sun` (no extra widget in the chain, so `NestChipWrap`'s ±5 px hit slop is untouched) | Verified; nothing to change |
| 5 | **MINOR** — invented empty-state copy `Add children to set weekly amounts.` | Unchanged — the review's own resolution is "Keep as a finding-to-be-ratified, not a fix"; no source exists in `DESIGN_SPEC.md §5` or the HTML | **Left as-is** (still open for orchestrator ratification). Swapping in any other sentence would be equally unratified. Re-confirmed green at 320 dp × 1.3 by `p06_bugs_test.dart` |

### From `5_ui.md`

Deviation 1 (H1) is the same shared fix as above. Deviations 2 (status bar),
5 (bottom strip — owner BOTTOM EDGE override, the app is right) and 6
(rasterisation artefact) are non-items per the brief. Deviation 3 (day-chip
glyph size) is resolved by `_DayPill` rendering the 13 px `NestType.fieldLabel`
directly instead of the shared `NestChip` + `FittedBox`; only de-duplication
remains (`SHARED_REQUEST` item 5). Deviation 4 (coin tile) now uses the design's
own `assets/coin.svg` via `NestlingIllustrations.coin`.

### From `6_bugs.md`

`P06-BUG-11` and `P06-BUG-12` proofs pass un-skipped. No new skips added.

## Design re-measure (PNG ÷3) vs the shipped view

I re-measured both design PNGs pixel-by-pixel with a colour-run scan and
compared against the iteration-5 app screenshot (`ui/app_light_5.png`) and the
code:

* **H1** design: glyph rows 113–172, line 1 x 21.7–350.7 (329 wide). App:
  box `x = 20`, balanced width **331.2**, break **"How does pocket money" /
  "work in your house?"** — the design's break, left-aligned at the 20 px
  gutter (BALANCED HEADINGS + ALIGNMENT satisfied).
* **Option cards** design 191/263/335, 64 tall, x 20–370. App identical; the
  only difference in iteration 5 was the 34 px shift inherited from the H1.
* **Settings card** design 415–684 (270 tall); label 431, chips 455–487,
  dividers 495 / 620, "Weekly base" 503, Maya 545, Leo 589, coin 650.
* **Day strip** — the design's pills run x 36–75.7 / 82–122.9 / … / 314–353.7
  with 6 px gaps; the app produces the same runs to within 0.3 px. Cell width
  `(390 − 2·20 − 2·16 − 6·6)/7 = 40.28` matches the CSS `repeat(7, 1fr)`
  `gap: 6`.
* **Selected radio** design: 22 px circle, 2 px `leaf` ring, 3.7 px `leafTint`
  ring, 9.7 px `leaf` centre (i.e. the `inset 0 0 0 4px leaf-tint` read).
  App: identical rects and colours to a 1-bit rounding difference.
* **Dark PNG** carries the same anchors as light (H1 113–172, cards
  191/263/335, card 415–684, chips 455–487, CTA border 685) — only colours
  change (page `21,19,31`, panel `31,28,46`).
* **CTA / BOTTOM EDGE**: the panel's `surface` reaches y 844 in the app
  screenshot; the design paints paper below 810 (its `.home-indicator` strip),
  which the owner BOTTOM EDGE rule overrides. App is correct.

## Changes made

`app/test/features/pocket_money/pocket_money_setup_view_geometry_test.dart`
(only file touched — the view/widgets needed no edit after the merge):

1. `_pumpOnboardingKids` takes a `theme` (`pumpAppRoute` already supported it).
2. **New test — the H1 break.** Asserts the heading's rendered box starts at the
   20 px gutter, is wider than 320 and never wider than the 350 px column, and
   that a `TextPainter` laid out at that rendered width produces exactly two
   lines whose first line ends after `"How does pocket money"` and does not
   contain `"work"`. This pins the BALANCED HEADINGS rule on *this* screen
   rather than trusting the shared component's defaults: it fails if the break
   orphans a word, if a future edit re-narrows the box, or if the component
   regresses back to ellipsis-collapsing.
3. **New group — dark mode.** The dark PNG has identical anchors, so the
   previously light-only pins are replayed under `ThemeMode.dark`
   (H1 107/68, card 415–684 x 20–370, chips 455/32, "Weekly base" 503, Maya
   545, Leo 589, coin 650, CTA bottom 844) plus token-colour checks: scaffold
   `= tokens.paper`, CTA panel decoration `= tokens.surface`, selected Sat pill
   `= tokens.leafTint`, and `takeException() == null`.

`docs/screens/P06/SHARED_REQUEST.md` — item 3 marked **CLOSED** (it was stale:
the component is merged and its defaults are fixed; the real remaining ask is
item 4, `NestStepper`'s U+2212).

## Checks run (stage-allowed only)

* `flutter analyze lib/features/pocket_money test/features/pocket_money` →
  **No issues found!** (two `unnecessary_non_null_assertion` warnings my first
  draft of the dark test raised were fixed, not ignored).
* `dart format` on the feature + its tests → 0 changed.
* `flutter test test/features/pocket_money/` → **+157: All tests passed!**
  (0 skips; BUG-11/BUG-12 included).
* No whole-app `flutter test`, no simulator booted/installed/screenshotted, no
  `flutter clean`, no `flutter run`, no files outside
  `presentation/{views,widgets}/` + `test/features/pocket_money/` + this
  screen's docs (RULES §1).

## LEFT FOR NEXT ITERATION

1. **Empty-state copy ratification** (review #5). `Add children to set weekly
   amounts.` still has no source in `DESIGN_SPEC.md §5` / the HTML. Needs an
   orchestrator yes/no; the branch cannot invent a replacement.
2. **`SHARED_REQUEST` items 4 and 5** (`NestStepper` U+2212 + glyph override,
   `NestChip` day-cell variant). Both are de-duplication/mitigation asks; the
   screen is correct and tested without them. When they land, delete
   `p06_weekly_stepper.dart` and `_DayPill` in one edit each.
3. **Confirmation screenshot.** This stage may not boot a simulator, so the
   restored two-line H1 has been verified only through real-font geometry pins,
   not through `shot.sh` + `compare.py`. The stage-5 UI check should re-shoot
   `app_light_6.png` / `app_dark_6.png`; the expected mean diff is back to the
   iteration-4 level (~2.2%) with bands 1–4 no longer inflated by the H1 shift.

VERDICT: PASS