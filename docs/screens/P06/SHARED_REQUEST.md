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
   200. No matching entries exist in `NestSpacing` today.

Files: `app/lib/core/design_system/components/nest_chip.dart`,
`app/lib/core/design_system/tokens/spacing.dart`.
Blocks: no — P06 builds and tests green today with the feature-private
pill + the two literals.

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
