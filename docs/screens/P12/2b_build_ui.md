# P12 · 2b BUILD (UI chunk, iteration 1)

## What this stage actually delivered

Iteration 1 of this stage **ended without writing its stage file and without
writing any UI code** — the previous run left
`presentation/views/money_ledger_view.dart` as the 1.5 KB placeholder
(`AppBar` + `ListTile` + `No items yet`), with no edit sheet, no view tests
and no stage file. This run re-read the brief, implemented the whole UI layer
against `1_plan.md` + `2a_build_logic.md`, and verified it.

## CONTRACT USED (from `2a_build_logic.md`, re-read before finishing)

Both additive deviations were absorbed with no code change needed:

1. `MoneyLedgerData.setup` — P12 ignores it (it is P06's payload).
2. `ledgerDataFallback` — never called from widget code; the view only reads
   `state.data` / `state.selectedChildId` / `state.items` through
   `PocketMoneyBloc`, exactly as §b planned. `PocketMoneyEntry.dateTz` is
   read by the history row (payout / weekly-base day labels).

## Files (UI chunk only)

- `lib/features/pocket_money/presentation/views/money_ledger_view.dart`
  (rewritten): `MoneyLedgerView` + private `_PageTitle`, `_LoadedBody`,
  `_GoalCard`, `_EmptyBody`, `_FailureBody`, `_openSheet`.
- `lib/features/pocket_money/presentation/widgets/money_history_row.dart`
  (new): `MoneyHistoryRow` — `.hrow` geometry, per-type copy/sign/tint, the
  coin illustration on the `quest_bonus` tile.
- `lib/features/pocket_money/presentation/widgets/money_edit_sheet.dart`
  (new): `MoneyEditSheet.addMoney` / `.recordSpending` + pounds→pence
  parsing and inline validation.
- `lib/features/pocket_money/presentation/widgets/money_pounds.dart` (new):
  the ledger's own copy helpers (`moneyPounds` / `moneyPlus` / `moneyMinus` /
  `moneyPence`, plus the U+2212 · U+00B7 · U+2014 constants).
- `test/features/pocket_money/money_ledger_view_test.dart` (new): 12 widget
  tests.

Not touched: `domain/`, `data/`, `presentation/bloc/**` (the logic builder's
edits are present in the worktree but are not mine),
`presentation/views/payout_view.dart`, `pocket_money_setup_view.dart`,
`app/lib/core/**`, routes, DI. No `google_fonts` anywhere. No simulator used.

## Implementation notes (per `1_plan.md` §a/§c/§d/§e)

- `Scaffold(backgroundColor: tokens.paper)` + `ListView` with
  `fromLTRB(padSide, 0, padSide, s8)`, every separator `s4` (16). `Scaffold`
  → `BlocListener` (submit-failure toast) → `BlocBuilder`
  (initial/loading spinner · failure body · empty body · loaded body).
- `const NestStatusBar()` first (reserves 47; OS draws the real bar). No
  `SafeArea` — `NestStatusBar` already reserves the OS inset, so both would
  double it. No `NestTabBar` in the view (owned by `ParentShell`).
- Title `Pocket money`, `NestType.h1`, `maxLines: 1` + ellipsis,
  `Padding(top: 8)`, `Semantics(header: true)`.
- `NestSegmented<String>` over `data.children` (creation order — Maya, then
  Leo), `semanticLabel: 'Child'`, `onChanged → PocketMoneyChildSelected`.
- Hero: `NestCard(variant: hero)` (so `heroBg`/`onHero`, never `ink`),
  `chipLabel` label, `kidHero + letterSpacing −0.4` amount
  (`maxLines 1`, `softWrap: false`, ellipsis), `chipLabel w400` breakdown with
  `SizedBox(4)` above and `SizedBox(gap14)` before `NestButton('Payout time',
  semanticLabel: 'Payout time for <Name>')`. The hero is **not** wrapped in
  `excludeSemantics` — the button has to stay reachable.
- Payout date comes from `payoutLabel(payoutWeekday: data.payoutDay,
  nowUtc: DateTime.now().toUtc(), zoneId: data.zoneId)` — never the design's
  hard-coded "Sat 4 Oct". With the test anchor the render is `Sat 3 Oct`.
- Goal card omitted entirely when the child has no goal (Leo) — no stub.
  Coin art is `SvgPicture.asset(NestlingIllustrations.coin)` (illustration
  keeps its own colours), `ExcludeSemantics`; title `'<goal> — £24.99'`,
  caption `'£15.50 saved · 62%'`, `SizedBox(8)` + `NestProgress(fraction,
  semanticLabel: 'Savings goal progress')`. Display-only.
- History: `h3` `History` + `SizedBox(4)`, then one `MoneyHistoryRow` per
  entry of the selected child in repository order (newest first), no
  dividers, `No history yet` when empty. Per-type icon/tint/title/sub/amount
  exactly per §a (payout amount unsigned `£3.80`; spend `−` U+2212; quests
  `+12p · Approved`; gift/savings-move notes verbatim incl. `→`).
  Tile tints reuse the shared `NestTileTint` mapping (no re-implemented
  palette). Every text row ellipsises; the amount is `softWrap: false`.
- Row buttons: two `Expanded` `NestButton(secondary, minHeight 48, fontSize
  15, horizontalPadding 12)` with a `gap10` gap → the sheet.
- Footer caption `Nestling keeps track — the real money stays with you.`
  (U+2014), centred.
- Bottom edge (owner rule): the view paints nothing below the shell tab bar;
  `Scaffold` background is `paper` and `NestTabBar` already fills its home
  reserve with `surface`.
- Interaction: `context.push(PocketMoneyRoutePaths.payout)` for Payout time
  (`push`, never `go` — the ledger is a tab root); `showNestBottomSheet` for
  the two sheets; submit → `PocketMoneyAddMoneySubmitted` /
  `PocketMoneySpendingSubmitted` → pop → `showNestToast('Added £X for
  <Name>')` / `'Spent £X recorded'`; empty-state CTA →
  `FamilyRoutePaths.addChildren`; failure CTA re-adds
  `PocketMoneyLoadRequested`.
- Copy the design does not specify (the sheet has no PNG): field labels
  `Amount` / `Note`, hints `£0.00` / `e.g. Birthday money`, inline errors
  `Enter an amount like £1.00` / `Enter an amount above 0`, empty-note
  fallbacks `Added money` / `Something else` (so a spend row never reads
  `Spent · Spending`).

## Deviations from `1_plan.md` (all deliberate, none blocking)

1. `NestButton` has **no** `primary`/`secondary` named constructors (only
   the default constructor + `NestButtonVariant`); the view uses
   `NestButton(variant: NestButtonVariant.secondary)`.
2. `NestTextField` exposes no `inputFormatters` / `onSubmitted`; the amount
   field keeps the decimal keypad via `keyboardType` and the parser strips
   non-numerics, which is what the formatters would have done.
3. History rows are `MoneyHistoryRow` (public, in `widgets/`), not a private
   `_HistoryRow` — the plan asked for a local widget but also for a separate
   `widgets/` file; a private class cannot be tested from a test file.
4. Two sizes have no token: `.goal img` 56 and `.hrow` `min-height: 56` are
   documented screen-local `static const` with the CSS source quoted (same
   approach `NestListRow` takes for its 40 px tile).
5. The sheet is one widget with two named constructors rather than a
   `mode` boolean at the call site.

## Owner-rule compliance

- No Pip on this screen (PIP N/A); no chips (CHIP ROWS N/A); no
  `text-wrap: balance` in the P12 CSS → `NestBalancedText` correctly unused.
- Tracking: only the hero amount sets `letterSpacing: -0.4` at the call site;
  nothing else adds Material tracking.
- Child order = creation order from `MoneyLedgerData.children`.
- Numbers come from the seeded database (`Seed.demo`), asserted in tests
  (`£4.20` / `£2.10` / 62%), never hard-coded in the view.
- 20 px side gutters everywhere; all cards/buttons share x = 20…370.
- Accessibility: `NestSegmented`, `NestButton` and the sheet close expose
  `SemanticsAction.tap` from the shared components; no
  `Semantics(excludeSemantics: true)` wrapper hides a control anywhere.
- Coins, gifts, bags, checks, pound coins are `NestIcon`/illustrations only —
  no `subscription_status`, no red.

## Verification

- `flutter analyze lib/features/pocket_money test/features/pocket_money` →
  No issues found.
- `dart format` clean (12 files, 0 changed).
- `flutter test test/features/pocket_money/money_ledger_view_test.dart` →
  **12/12 pass**: seeded copy + every history row, segment switch
  (`Leo is owed` / `£2.10` / goal card omitted), `Payout time` →
  `pushedPath == '/payout'`, add-money write + toast + new row, spending
  validation error then write, sheet close, dark mode, empty state →
  `/add-children`, copy audit (U+2014 ×2, U+00B7, U+2212, U+2192, and *no*
  ASCII hyphen anywhere in the screen's text), a11y tap-action + real state
  change on every control, 44 px semantics rects, and 320-wide × 1.3 text
  scale with no `RenderFlex overflowed`.
- `flutter test test/features/pocket_money` → **227/227 pass** (my 12 plus
  the P06/repository/bloc suites, so the shared-bloc edits are unregressed).
- Whole-app `flutter test` deliberately left to the integrator. No simulator
  booted, installed on or driven.

## Observations for the next stages (not defects in this layer)

1. **Plan watch-item resolved**: `NestSegmented` now renders
   `tapParent + s2` = **52 px**, matching the design CSS (padding 4 + 44
   button). The 44-vs-52 drift flagged in `1_plan.md` no longer exists, so no
   `SHARED_REQUEST.md` is needed for it.
2. **Merged semantics on the hero button**: the hero card's node carries the
   merged label `Maya is owed\n£4.20\nWeekly base … \nPayout time for Maya`
   with `isButton` + `tap`. It is operable (the test performs the tap and
   reaches `/payout`), but VoiceOver reads the card as one button. The
   shipped P08 approvals banner shows the identical merge
   (`3 quests waiting for your thumbs-up\n…\nReview`), so this is
   design-system behaviour, not a P12 regression — worth a shared note, not a
   screen fix. The test therefore locates that node with a `RegExp` label.
3. Two controls share the label `Record spending` (row button + sheet CTA)
   once the sheet is open; the test targets the CTA's node by id. Copy is
   unchanged from the design.

## LEFT FOR NEXT ITERATION

- Nothing in the UI layer is unfinished: view, history row, edit sheet and
  view tests are implemented, analysed and passing.
- Optional polish for stage 4/5: a UI check should confirm the pill/button
   **background rects** (segmented thumb 173×44 at x 24, hero button
   310×52, row buttons 170×48) rather than only text positions.
- Whole-app regression run and the `/payout` (P13) destination screen are
  the integrator's / P13's stage.

VERDICT: PASS