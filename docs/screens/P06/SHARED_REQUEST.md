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

3. ~~BALANCED HEADINGS (orchestrator rule) is blocked on a main merge.~~
   **CLOSED (iteration 6).** The component landed (`58b42de`, merged as
   `88c2132`) and the orchestrator's follow-up shared batch
   `shared/balanced_text_ellipsis` (main `9ba19ab`) fixed the defect this item
   was really about — `NestBalancedText.lineCountFor` hard-coded
   `ellipsis: '…'` and the widget defaulted to `overflow:
   TextOverflow.ellipsis`, so a heading with `maxLines: null` collapsed to one
   ellipsized line (P06-BUG-11). On this branch's `main` merge
   (`310514a`) the H1 is two 34 px lines again with the design's break
   ("How does pocket money" / "work in your house?"), and
   `pocket_money_setup_view_geometry_test.dart` pins the break plus the
   absolute y anchors (107/175, 191/263/335, 415–684, 455, 503, 545, 589,
   650, CTA 685). No further shared work needed for this item.

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
