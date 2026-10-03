# Shared request — P06

Need: shared design-system follow-ups surfaced by the P06 pocket-money setup
screen (documented in `docs/screens/P06/FIXES_2.md` review item #6 and the
parked item from `docs/screens/P06/1_plan.md` §7):

1. `NestChip` day-cell variant. `PocketMoneySetupView` needs
   `.chip.day` from the design (`padding: 0`, centred 13 px label =
   `NestType.fieldLabel`, 7-up in a grid of Expanded cells) but the shared
   `NestChip` only offers 14 px label + `0 14px` padding with a FittedBox
   workaround shrinking the whole pill. P06 currently carries a
   feature-private `_DayPill` (TODO(P06)); a `labelStyle` / compact
   constructor on `NestChip` would let it retire.
2. Size tokens for the literal geometry the plan pins to the design:
   option-card vertical padding 13, radio circle 22, loading placeholder
   200, option-card `minHeight: 60`, and the weekly-base single-line /
   wrapped-row breakpoint ~300 (row content is ~318 wide at 390; the
   exact integer belongs with the shared scale). No matching entries exist
   in `NestSpacing` today. The pill label style for the day variant is
   `NestType.fieldLabel` (Inter 13/18 w600), which the shared variant
   should reuse verbatim.

Files: `app/lib/core/design_system/components/nest_chip.dart`,
`app/lib/core/design_system/tokens/spacing.dart`.
Blocks: no — P06 builds and tests green today with the feature-private
pill + the four literals.

## Iteration 4 — merge dependency, not a new component

3. **BALANCED HEADINGS (orchestrator rule) is blocked on a main merge.**
   `design/html-source/components.css:29` gives `.h1` `text-wrap: balance`,
   and P06's only heading is that `.h1`, so the orchestrator rule requires it
   to render through `NestBalancedText`. `NestBalancedText` **exists on main**
   (`app/lib/core/design_system/components/nest_balanced_text.dart`, shared
   batch 3 — commit `58b42de`, merged as `88c2132`), but it is **not in this
   worktree's HEAD** (`git merge-base --is-ancestor 58b42de HEAD` → false;
   this branch last merged main at `f579ff4`), so
   `pocket_money_setup_view.dart`'s `_SetupTitle` still builds a plain `Text`
   and cannot be migrated inside the screen worktree.
   Need: the loop's "merge main before each build" to pick up `88c2132`; the
   screen change itself is one line (`Text` → `NestBalancedText`, same copy,
   style and maxLines) and belongs to the next P06 build stage, not here.
   Files: none in the design system — `app/lib/core/design_system/components/
   nest_balanced_text.dart` is already on main; only
   `app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart`
   must adopt it.
   Blocks: no — the screen builds, tests and passes without it; it costs the
   balanced H1 break (design: "How does pocket money" / "work in your
   house?"; a greedy break can orphan a word). Recorded as a finding in
   `docs/screens/P06/3_test.md` (iteration 4).

## Iteration 6 — `NestStepper` glyph pair (the U+2212 fix landed locally)

4. **`NestStepper` must render U+2212 for decrease, and expose a glyph
   override.**
   `design/html-source/screens/P06-pocket-money.html:73,82` pairs `&minus;`
   (U+2212) with a U+002B `+` inside every `.stepper button`, so the two
   signs share weight and width.
   `app/lib/core/design_system/components/nest_stepper.dart:32` hard-codes
   `label: '-'` (U+002D) and the constructor has no glyph parameters, so a
   screen cannot correct it without forking the component.
   Need: render `'\u2212'` by default (keeping the existing semantics labels),
   and/or add `decreaseGlyph`/`increaseGlyph` params defaulting to U+2212 /
   U+002B.
   Files: `app/lib/core/design_system/components/nest_stepper.dart`.
   Blocks: **no** — P06 ships `presentation/widgets/p06_weekly_stepper.dart`
   this iteration: token-for-token identical to `NestStepper` (44 dp circles,
   1 px `line` border on `surface`, Inter 20 w700 glyphs, `s3` gaps, 64 dp
   `NestType.money` value, same `Semantics`/`Opacity` contract) except the
   two glyph strings. It is marked for deletion in one edit once the override
   lands; `test/features/pocket_money/p06_weekly_stepper_widget_test.dart`
   pins the behaviour (glyph is U+2212 and never `[0x2D]`, `+` is U+002B,
   both 44 dp, callbacks fire, disabled = 0.45 opacity).

5. **`NestChip` needs the P06 day-cell variant (open since iteration 3).**
   `_DayPill` in `pocket_money_setup_view.dart` still re-renders
   `.chip.day` (32 high, `padding: 0`, 13 px w600 centred label, no
   horizontal padding, fills its grid cell) from tokens because `NestChip`
   has no equivalent. Unchanged by this iteration — 5_ui's day-glyph
   deviation is resolved by `_DayPill` rendering the 13 px `fieldLabel`
   directly (no `FittedBox`), so the remaining ask is de-duplication only.
