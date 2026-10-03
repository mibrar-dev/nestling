# P06 Pocket money setup — UI build (Stage 2b, iteration 7)

Scope of this stage: `app/lib/features/pocket_money/presentation/views/**` +
`presentation/widgets/**` and the view/widget tests. No domain/data/bloc file
touched (the logic builder worked in the same worktree in parallel — its
`2a_build_logic.md` reports review finding 4 done and **no contract changes**,
so the view codes against the same events/states as iterations 3–6).

All five UI items in `FIXES_6.md` (review findings 1, 2, 5, 6, 8) plus the
`ORCHESTRATOR_NOTES` 09:30 and 09:42 items are done. The coin-row fix also
turned **P06-BUG-13** green, so its skipped test is un-skipped: there is now
**no `skip:` anywhere** in `app/test/features/pocket_money/`.

## Files changed

| File | Change |
|---|---|
| `presentation/views/pocket_money_setup_view.dart` | findings 1, 2, 5, 6, 8 (+ BUG-13) |
| `test/features/pocket_money/pocket_money_setup_view_test.dart` | +2 tests (finding 2), `SemanticsAction` import |
| `test/features/pocket_money/p06_bugs_test.dart` | P06-BUG-13 un-skipped + its stale "this is the bug" comment rewritten |
| `docs/screens/P06/2b_build_ui.md` | this report |

## What changed, item by item

### Finding 1 / ORCHESTRATOR 09:30 — the coin value is now right-aligned

`_CoinValueRow`: the trailing value was a **loose** `Flexible`, so it took its
intrinsic width and its text ended at ≈322 instead of the card's content edge
(354 — the same edge as the `+` buttons and the Sun pill). It is now a tight
`Expanded` with `textAlign: TextAlign.end`, exactly the note's prescription.

The value's ink right edge now lands on `card.right − s4` (±1 px) in light,
dark and at 430 — the three tests that were red in `3_test.md` pass.

### P06-BUG-13 — the coin-value **label** no longer truncates at 320 × 1.3

`Expanded` + `TextAlign.end` alone is not enough: with two flex children the
row still splits 50/50, so at 320 dp × 1.3 the label's 98 px share was narrower
than `Coin value` at Inter 16 × 1.3 and it painted `Coin val…` (the reason
`p06_bugs_test.dart` carried the screen's only `skip:`). The label now has
`softWrap: true, maxLines: 2`, so it wraps instead of truncating and the
*value* — the one text `1_plan.md` §5 sanctions for ellipsis — takes the
shortfall. Above 320 dp the label still prints on one line, so the design is
unchanged (the 390 geometry guard, which pins the card at top 415 / height
270 and every y anchor, is unchanged and green).

Two layouts were tried and rejected on evidence, both recorded here so the
next maintainer does not repeat them:

- **label as a non-flex `Text`** (intrinsic width, value `Expanded`): in a
  widget test the fallback font is 1 em per glyph, so `Coin value` needs 208 px
  of the row's 196 px → `A RenderFlex overflowed by 12 pixels on the right` at
  320 × 1.3 (6 tests red). The real-font matrix was fine; the test font was
  not.
- **a narrow-width wrap branch** (value on its own line, like
  `_WeeklyBaseRow`): that would make the value print in full at 320 and force
  a rewrite of the `3_test.md` matrix assertions, for a width the design does
  not define. `maxLines: 2` fixes the label inside the design's own layout.

### Finding 2 / ORCHESTRATOR 09:42 — the screen's two primary controls are operable again

`_PocketOptionCard` and `_DayCell` both wrapped a `GestureDetector(onTap:)` in
`Semantics(excludeSemantics: true)`, which drops every descendant contribution
**including the tap action**: the probe in `4_review.md` showed
`tap=false actions=0` for all three cards and all seven day cells, i.e. a
screen reader could not activate the money-style or payout-day choice. One line
per widget — `onTap: onTap` on the `Semantics` node — restores
`SemanticsAction.tap` without adding a second semantics node (the single-node
announcement the rest of the suite relies on is preserved).

Two new tests:

1. **every option card and day cell exposes a tap action** — all ten cells
   `hasAction(SemanticsAction.tap) == true` and `isButton == true`; the three
   cards additionally assert the radiogroup flags (finding 6).
2. **performing the tap action really writes the choice** — `performAction`
   through `tester.semantics` on `Earn per quest` and `Payout day: Mon`, then
   asserts the selection flags moved. The action is proved *wired*, not just
   declared.

### Finding 6 — the options announce as radios, not generic buttons

The HTML source is a `role="radiogroup"` of `role="radio"` buttons with
`aria-checked`. The three cards now add `checked: selected` and
`inMutuallyExclusiveGroup: true` on top of the existing `selected:` (purely
additive; the existing `isSelected` assertions are untouched), so a screen
reader gets "radio, 3 of 3, selected" and can tell the group is single-select.

### Finding 5 — `_FailureBody` no longer re-subscribes to the bloc

It took its message from `context.watch<PocketMoneyBloc>().state` while being
built *inside* the `BlocBuilder` that filters with `buildWhen` — so it rebuilt
on every emission, including ledger-only ones the filter exists to drop. It now
takes `errorMessage` from the builder like `_LoadedBody` already does.

### Finding 8 — the radio dot's diameter is a size, not a gap

`_RadioDot._dotDiameter = 10` (private constant, CSS derivation in the
doc-comment) replaces `NestSpacing.gap10`, which read as "a 10 px gap" to the
next maintainer.

## Design / layout impact

None above the coin row: the option cards, the day strip, the weekly-base rows,
the dividers, the CTA and the bottom edge are untouched by this iteration, and
the real-font geometry guard still matches `design/screens/light|P06` ÷3
(H1 107–175, cards 191/263/335 at 64 tall, card 415–685, pills 455–487,
dividers 495/620, CTA border 685) in both themes. Owner rules re-checked
through the suite: bottom edge (CTA surface to the physical edge, light and
dark, OS inset 0 and 34), single 20 px gutter, `NestBalancedText` on the H1,
`NestChipWrap` for the day row, letterSpacing 0 everywhere, no hard-coded
colours, children in insertion order, no Pip, no `subscription_status`.

## Checks run (stage-allowed only)

- `flutter analyze lib/features/pocket_money test/features/pocket_money` →
  **No issues found!** (0 ignores).
- `dart format --set-exit-if-changed` on `lib/features/pocket_money` +
  `test/features/pocket_money` → 0 changed.
- `flutter test test/features/pocket_money` → **+176: All tests passed!**
  (view 92, geometry 6, stepper 5, bugs 28 — one more than iteration 6, the
  un-skipped BUG-13 — bloc 30, repository 15, 0 skips).
- Full-app `flutter test` and the simulator were **not** run — the integrator
  owns both, and only stage 5 may drive a simulator.

## Deliberately not done

- **Review finding 3** (`NestButton` / `NestChip` drop `SemanticsAction.tap`
  too, so the `Continue` button is affected). Shared core, forbidden by
  RULES §1, and the `09:42` note says it is being fixed on
  `shared/semantics_tap` and must **not** fail P06 — so no SHARED_REQUEST item
  was filed for it.
- **Review finding 4** (child-order query) — logic layer; the parallel 2a
  builder deleted `_watchChildrenInsertionOrder` in favour of
  `AppDatabase.watchChildren`. Nothing for the UI chunk.
- **Review finding 7** — the screen-authored empty-state copy
  `Add children to set weekly amounts.` still has no source in
  `DESIGN_SPEC.md §5` or the HTML and needs an orchestrator yes/no; it is
  mandated by `1_plan.md` §4, so the behaviour is right and the string is
  unchanged for the third iteration. This is the one item waiting on a
  decision, not on code.

## LEFT FOR NEXT ITERATION

- Stage 5 UI check: re-shoot `cmp_light` / `cmp_dark` — the coin value's ink
  right edge should now read 354, closing the last item of the 09:30 note
  (0.89 % drift). No other pixel should move.
- Orchestrator ratification of the empty-state copy (review finding 7).
- Once `shared/semantics_tap` lands on main, the `Continue` button joins the
  same `hasAction(SemanticsAction.tap)` guarantee the screen's own controls now
  have; no P06 change needed.

VERDICT: PASS
