# P06 Pocket money setup — UI build chunk (Stage 2b, iteration 5)

Route: `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding (P05 → P06 → P07).

## CONTRACT

Re-read `docs/screens/P06/2a_build_logic.md` (iteration 5): expected **no**
contract changes for my layer (logic chunk owns the `clearErrorMessage`
recovery + `watchSetup` stream semantics that were already in state from
iteration 4). UI built strictly against the BLoC events/states in
`1_plan.md` §2.

## Files changed (UI layer only)

- `app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart`
  - **FIXES_4 #3 / BUG report** — `_SetupTitle` now builds
    `NestBalancedText('How does pocket money work in your house?', style: context.nestText.h1, textAlign: TextAlign.left)`
    inside the existing `Semantics(header: true)` wrapper. Required by the
    BALANCED HEADINGS orchestrator rule (`.h1` is `text-wrap: balance` in
    `design/html-source/components.css:29`). `textAlign: left` keeps the
    heading left-aligned in the 20 px-glotted scroll — the widget defaults
    to center, which would silently break the ALIGNMENT owner rule.
  - **FIXES_4 #1** — the payout-day row is back at the design's **32 px**
    height with the pills painted at that band's top (owned full measured
    object height now emits 32, not 44). The row carries no tight
    `Padding`/`SizedBox`/`Semantics`/`LayoutBuilder`Ancestor between the
    card `Column` and `NestChipWrap` so ±5 px taps fall through to
    `RenderNestChipWrap.hitTest`'s hitSlop; the inset is done by the
    cell-width math (`(viewport - 2·padSide - 2·s4 - gaps) / 7`, baked in
    `_DayRow.build`, documented why direct `MediaQuery` is read instead of
    a `LayoutBuilder`), giving ~40 px cells at 390 and ~30 px cells at 320.
    The card stops at 270 (its design height); its 12 px bottom padding and
    bottom radius are no longer hidden under `NestBottomCta`. Kings: the
    two tight clips introduced by iteration 4 are gone; `_DayCell` paints
    `SizedBox(cellWidth × NestSpacing.s8)` directly (no more `Center`),
    and its hit band is the NestChipWrap slop's ±6 px.
  - **FIXES_4 #2** — the analyzer complaint at
    `pocket_money_setup_view_test.dart:2078` is mostly gone: the assertion
    now compares `decoration.borderRadius` to `NestRadii.allM` directly
    (no nullable cast).
  - **FIXES_4 #4** — all six hand-rolled teardowns in the view test
    (`pumpWidget(const SizedBox.shrink()); pump(); …`), including the one
    real-Drift-DB test, are replaced with `await disposeApp(tester);` so
    Drift's deferred stream-close timer drains before teardown.
  - **FIXES_4 #5** — the weekly-base child nickname and the `Coin value`
    label now use the design's `.amount-name`: `NestType.body(color: ink)`
    with `fontWeight: w600, height: 22/16` (the option-card titles keep
    their w700).
  - **FIXES_4 #6** — the loading spinner is `CircularProgressIndicator(color:
    tokens.leaf)` (dropped the `const` body), matching P08.
  - **FIXES_4 #7** — `SHARED_REQUEST.md` item 2 now also lists
    `minHeight: 60` and the `~300` weekly-base reflow breakpoint, plus
    notes the day variant's pill font is `NestType.fieldLabel` (13/18 w600).
  - **FIXES_4 #12/#9/#10** — repository `assert`-only validation, the
    unused `watchSetting` in `watchSetup`, and the missing `emit.isDone`
    guards: logic/data layer, owned by the logic chunk; not touched.
  - **FIXES_4 #11** — `'Add children to set weekly amounts.'` is still
    screen-authored copy (no design equivalent); flagged here for the
    orchestrator to ratify or replace.
- `app/test/features/pocket_money/pocket_money_setup_view_test.dart`
  - Day-cell height expectations flipped from `NestDevice.tapParent` to
    `NestSpacing.s8` in the three places that pinned the 44px regression
    ("every tap target is at least 44dp", "tap targets hold at 320dp…",
    the chip-containment test), because the design band is 32 high and the
    44px target is the `NestChipWrap` hitSlop tap path, not cell height.
    The geometry groups now assert the pill is 32, the wrap measures 32,
    all seven cells fit at 320/390/430, and the row starts on the same
    16 px inset as the other section labels.
- `app/test/features/pocket_money/p06_bugs_test.dart`
  - The stale `P06-BUG-04` (≥44 × ≥44 naments) proof is DELETED: its
    demand is superseded by ORCHESTRATOR_NOTES item 2 (7 chips inside the
    16 px inset), and the replacement geometry/slop coverage lives in the
    view file + the iteration-4 note guards below. Header updated.

## Items done (FIXES_4.md, UI-layer only)

- #1 — done above (32-high band, pills flush at design y, card 270).
- #2 — fixed (`borderRadius` vs `NestRadii.allM`).
- #3 — fixed (H1 is `NestBalancedText`, left-aligned).
- #4 — all six hand-rolled teardowns replaced with `disposeApp(tester)`.
- #5 — nickname + coin-value rows use w600 16/22.
- #6 — spinner `tokens.leaf`.
- #7/#8 — SHARED_REQUEST updated; `_DayPill` remains, annotated (shared
  `NestChip` day variant still parked); `NestRadii.allM` used as the
  shared r-m corner token.
- #13 — stale P06-BUG-04 44×44 test deleted, reason recorded.
- #14 — `BlocBuilder.buildWhen` filters ledger-only emissions.
- #9/#10/#12 — logic/data items, left to the 2a chunk (my layer heck kept
  around state surface interacting there).

## Checks run (stage-allowed only)

- `flutter analyze lib/features/pocket_money test/features/pocket_money`
  → `No issues found!`
- `flutter test test/features/pocket_money` → **+136: All tests passed!**
  (67 view, 30 bloc, 15 repo, 24 bug-guards).
- `dart format` on the feature + feature tests → the view file re-wrapped
  once, tests unchanged semantically.
- Full-app `flutter test` and the simulator NOT run (integrator owns them).

## LEFT FOR NEXT ITERATION

- Letter-spacing / copy / `NestBalancedText` already in place: no pending
  item. `'Add children to set weekly amounts.'` copy still needs the
  orchestrator's ratification or a design replacement — filed above with
  #11 but visible only at `Seed.empty`/`Seed.fresh`.

VERDICT: PASS
