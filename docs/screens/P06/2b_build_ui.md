# P06 Pocket money setup — UI build chunk (Stage 2b, iteration 2)

Route: `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding (P05 → P06 → P07).

## CONTRACT

Re-read `docs/screens/P06/2a_build_logic.md` before finishing: **CONTRACT
CHANGES: None.** BLoC events/states match `1_plan.md` §2 exactly, so the UI
layer compiled against the committed contract with no edits needed:
`PocketMoneyState.setup`, `PocketMoneyModeChanged`, `PocketMoneyPayoutDayChanged`,
`PocketMoneyWeeklyBaseStepped(childId, deltaPence)`, 50p step, 0..2000 clamp.

## Files changed (UI layer only)

- `app/test/features/pocket_money/pocket_money_setup_view_test.dart`
  - Deleted `import 'package:google_fonts/google_fonts.dart';` and the
    `GoogleFonts.config.allowRuntimeFetching = false;` call. The orchestrator
    FONTS rule forbids both, and the package is removed from `pubspec.yaml`,
    so the file no longer compiled. Inter/Nunito are bundled assets;
    `setUpTestScope` needs no font setup.

No view/widget source edits were required — the committed
`pocket_money_setup_view.dart` already matches the plan and the design PNGs.

## UI layer state (verified, not rewritten)

- `Scaffold(backgroundColor: tokens.paper)`, no tab bar; `NestStatusBar`
  (height reserve only) → compact `NestNavBar` (back → `go(/add-children)`)
  → scroll (`padSide` 20px gutters) → dense `NestBottomCta` → `NestHomeIndicator`.
- Scroll: H1 (`nestText.h1`, header semantics), radiogroup of three
  token-built `_PocketOptionCard`s (60 min height, 2px line border, selected =
  leaf on leafTint, 22px radio with 10px leaf dot), then the settings card.
- Settings card: `NestCard` zero-padding with manual insets and full-bleed
  1px dividers (vertical 8), `Payout day` 7× `Expanded` cells (44-tall tap box,
  NestChip scaled down), `Weekly base` rows in insertion order (Maya → Leo)
  with `NestAvatar` s32 lilac/peach + `NestStepper` (HTML aria-labels verbatim,
  50p step), `Coin value` coin-tint tile row, trailing text Flexible so it
  ellipses instead of pushing the row.
- Weekly-base rows reflow below 300px row width (name line, then right-aligned
  stepper) so the 320dp × 1.3 matrix cannot overflow — verified green.
- `NestBottomCta(dense: true)`: caption (`NestType.caption(ink2)`, centred,
  maxLines 3) composed above `Continue` (`NestButton.primary`, minHeight 52)
  inside the `child` slot; its `SafeArea(top: false)` keeps the surface running
  to the physical edge (owner BOTTOM EDGE rule) in light and dark.
- Copy is the HTML verbatim (ASCII + `£` only): option titles/subs, `Payout
  day`, `Mon…Sun`, `Weekly base`, `Maya`/`Leo`, `£3.00`/`£1.50`, `Coin
  value`, `10 coins = 10p`, caption with `. You` single space, `Continue`,
  `Back`, `Add children to set weekly amounts.` for the empty-children state.
- Bottom-edge + alignment + child-order owner rules hold: 20px gutters on the
  scroll, cards, and CTA all share the same side edges; children are
  Maya-then-Leo; the area below the CTA to the home indicator is the CTA's own
  surface colour in both themes.

## FIXES_1 items (UI/layout/copy — mine only)

1. Weekly-base row overflow at 320dp + scale 1.3: already fixed in the
   committed `_WeeklyBaseRow` `LayoutBuilder` reflow; re-verified with the
   full `2 × 3 × 2` light/dark × width × scale test matrix (all green).
2. Selected-flag / day-tap / stepper interaction failures: test-only
   (`Tristate` comparisons, `RegExp` semantics labels, `ensureVisible`);
   already green.
3. No UI/layout/copy items remain open in FIXES_1. No skipped bug tests exist
   (`grep skip:` empty) — nothing to un-skip.
4. This iteration additionally cleared the last google_fonts violation (above).

## Checks run (stage-allowed only)

- `flutter analyze lib/features/pocket_money test/features/pocket_money` →
  `No issues found!`
- `flutter test test/features/pocket_money/pocket_money_setup_view_test.dart`
  → `All tests passed!` (26/26: copy light/dark, 390 dark, seed selection,
  12-way matrix, empty children, write-through taps, nav, loading/failure,
  semantics labels, 44dp targets, 320dp × 1.3 targets).
- `dart format` on the feature + tests → `Formatted 19 files (0 changed)`.
- Full-app `flutter test` and the simulator NOT run (integrator owns them).

## LEFT FOR NEXT ITERATION

Nothing in the UI layer.

VERDICT: PASS
