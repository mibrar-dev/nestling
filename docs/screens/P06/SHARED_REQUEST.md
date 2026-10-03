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
