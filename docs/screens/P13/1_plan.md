# P13 · Payout (parent) — build plan · route `/payout` · feature `pocket_money`

Sources: `design/html-source/screens/P13-payout.html` (copy + CSS are truth),
`design/screens/light/P13-payout.png` + `design/screens/dark/P13-payout.png`
(1170×2532 = 390×844 logical, ÷3), DESIGN_SPEC §5 P13, SPACING_SPEC §§2/5/7,
existing `PocketMoneyBloc` / `PocketMoneyRepository.recordPayout` / P12
`MoneyLedgerView` patterns. No ORCHESTRATOR_NOTES file exists.

Copy rule: the HTML uses ASCII `'` (0x27) in `you've` / `Maya's` and U+00B7
`·` as separator — use those exact code points, never curly quotes.

Seed truth (DATA OVER MOCKS): Maya owed £4.20 (300 base + 120 quests),
Leo owed £2.10 (150 base + 60 quests), goal `goal-lego` (Maya, Lego Friends
set, 1550/2499p), `payoutDay` 6 = Saturday, avatars lilac M / peach L,
creation order Maya → Leo. Nothing is hard-coded except the fixed £1.00
savings option (design-fixed, see §2).

## (a) Widget tree, top → bottom (all logical px, tokens only)

`PayoutView` (StatefulWidget) renders a full-screen route (top-level
GoRoute, NOT inside `ParentShell` — no tab bar, matches design):

```
Scaffold(backgroundColor: tokens.paper)
└─ Stack
   ├─ Column                                  // dimmed P12 behind the scrim
   │  ├─ NestStatusBar()                      // 47 px reserve only
   │  ├─ Padding(20 sides, top 8)
   │  │  └─ Text('Pocket money', h1 ink, maxLines 1, ellipsis, header)
   │  └─ Padding(20 sides, top 12)
   │     └─ dimmed summary card: NestCard(padding 16)
   │        └─ Text('{Maya} is owed {£4.20} · {Leo} is owed {£2.10}',
   │             caption ink-2, centered, maxLines 2)
   │        // amounts via moneyPounds(), separator kMoneyDot, built from
   │        // data.oweds in creation order — NOT a fixed string.
   ├─ Positioned.fill → Container(color: tokens.scrim)   // .scrim; tap = pop
   │  // Scrim tap: GestureDetector onTap → context.pop() (back to /money).
   └─ Align(bottomCenter) → _PayoutSheet                  // .pay
```

`_PayoutSheet` (new `presentation/widgets/payout_sheet.dart`, feature-local —
`NestBottomSheet` does NOT match: its title is left h3 + close button and
its max-height is 92 %; `.pay` is max-height 88 %, centered 24/30 title, no
close):

```
Container(
  decoration: BoxDecoration(color: paper,
    borderRadius: BorderRadius.vertical(top: Radius.circular(32))), // r-xl
  padding: EdgeInsets.fromLTRB(20, 8, 20, 34 + 16),  // 8/20/50; paper runs
  constraints: BoxConstraints(maxHeight: 844 * 0.88),// to the edge (OWNER)
  child: Column(mainAxisSize: min, crossAxisAlignment: stretch, children: [
    Center(Container(40×5, pill, line)),              // grabber
    SizedBox(4),                                       // margin 4 auto 12
    // ↑ grabber block total = 4 + 5 + 12 = 21 (CSS margin 4/12)
    SizedBox(12),
    Text('<Weekday> payout',                           // 'Saturday payout'
      _payTitle ink, center, maxLines 2),              // Nunito 24/30 w900:
      // NestType.h2.copyWith(fontSize: 24, height: 30/24, fontWeight: w900)
      // Semantics header: true. <Weekday> = full name of data.payoutDay
      // via feature-local const ['Monday',…,'Sunday'][payoutDay-1].
    SizedBox(4),                                       // .sub margin-top 4
    Text("Tick once you've handed over the cash",      // ASCII apostrophe
      body 14/20 ink-2, center),                       // NestType.body.copyWith
      // (fontSize: 14, height: 20/14)
    SizedBox(14),
    for each child (creation order):
      _PayoutChildRow(...)                             // .child
      if not last: SizedBox(10),
    SizedBox(10),
    _SaveRow(...)                                      // .saverow (if §2)
    SizedBox(14),
    NestButton.primary('Mark as paid & start the celebration', // min-h 52
      enabled iff ≥1 child ticked; disabled → onPressed null),
    SizedBox(8),
    Text('Your children will see a payout celebration next time they open '
         'Nestling.', caption ink-2, center),          // .cap
  ]))
```

`_PayoutChildRow` (`.child`: surface, radius **16** (r-m), sh-1, padding 14 —
`NestCard` fixes radius 24, so build with raw tokens: `Container(decoration:
BoxDecoration(color: surface, borderRadius: all 16, boxShadow: cardShadow),
padding: 14)`; tokens only, no hard-coded values):

```
Row(children: [
  NestAvatar(initial: nickname[0], s44, lilac|peach from avatarColour,
    ExcludeSemantics),
  SizedBox(12),
  Expanded(Column(crossAxisAlignment: start, mainAxisSize: min, children: [
    Text(nickname, bodyStrong.copyWith(height: 22/16), maxLines 1, ellipsis),
    // .nm 16/22 w700 — call-site height override, shared style untouched.
    Text.rich(TextSpan(children: [
      TextSpan('Weekly + quests · ', caption ink-2),   // U+00B7
      TextSpan(moneyPounds(owed.totalPence),
        money 18/22 w800 tabular ink),                 // .am 18px w800
    ]), maxLines 1, ellipsis, softWrap false),
  ])),
  SizedBox(12),
  _PayoutCheck(...)                                     // .check 48×48
])
```

`_PayoutCheck` (`.check`, feature-local; no DS component exists):
`Container(48×48, radius 14, border 2 leaf when ON else line, bg leaf when ON
else surface)` + 24 px tick glyph (stroke 2.5, `NestIcons.check` or SVG path
`m5 13 4 4L19 7`, surface when ON else transparent — glyph stays mounted so
the rect never changes). Wrapped: `Semantics(button: true, label:
'{Name} paid in cash', checked: ticked, enabled: true, onTap: toggle)` +
`GestureDetector(onTap: toggle)`. Tap target 48 ≥ 44.

`_SaveRow` (`.saverow`: same 16-radius surface container, padding 14):
`Row(Expanded(Text('Move £1.00 of {nick}\'s to her Lego fund',
bodySmallStrong ink, wraps)), SizedBox(12), NestToggle(value, onChanged,
semanticLabel: 'Move one pound of {nick}\'s money to savings'))`.
Copy template is the design string with only `{nick}` interpolated
(ASCII apostrophe). Shown only when a goal-bearing child exists (see §2).

Dark mode: zero branches — every colour from `context.nest`
(surface/paper/leaf/scrim flip per SPACING_SPEC §0; checked fill stays
`leaf`, glyph `surface`/`onLeaf` per token).

## (b) BLoC events / states / repository

No new state fields (ticked set + savings flag + submitted flag are
`PayoutView` State, initialised from the first loaded emission: ticked =
`{data.children.first.id}`, saveOn = true).

New event in `pocket_money_event.dart` (feature-owned, allowed):

```dart
final class PocketMoneyPayoutSubmitted extends PocketMoneyEvent {
  const new(this.childId, this.amountPence, this.savingsMovePence, this.goalId);
  final String childId; final int amountPence;
  final int savingsMovePence; final String? goalId;
}
```

Handler in `pocket_money_bloc.dart` (mirrors P12 add/spend: loaded stays,
error → `errorMessage`, view toasts it):

```dart
Future<void> _onPayoutSubmitted(PocketMoneyPayoutSubmitted e, Emitter emit) async {
  try {
    await _repository.recordPayout(childId: e.childId,
      amountPence: e.amountPence, savingsMovePence: e.savingsMovePence,
      goalId: e.goalId);
  } on Object catch (error) {
    if (emit.isDone) return;
    emit(state.copyWith(errorMessage: _submitErrorMessage(error)));
  }
}
```

`recordPayout` already exists on the repository (negative `payout` row +
optional `savings_move` + goal bump in one transaction) — NO domain/data
change, NO shared request. Load path unchanged (`PocketMoneyLoadRequested`
→ `watchLedgerData`, `emit.forEach`, selection defaults to first child in
creation order).

Submit flow (view): CTA tap → for each ticked child dispatch
`PocketMoneyPayoutSubmitted(childId, owed.totalPence,
saveOn && childId == saveChildId ? 100 : 0,
saveOn && childId == saveChildId ? goal.id : null)`; set `_submitted = true`.
`BlocListener`: when `_submitted && loaded && every ticked child owed == 0`
(stream proof, P12-finding-6 pattern) → `_submitted = false`,
`showNestToast('Payout recorded — enjoy the celebration')`,
`context.pop()`. Write failure → error toast (existing listener pattern),
`_submitted = false`, stay on sheet.

Savings Move rule: the £1.00 (100 p) move applies only to the goal-bearing
child AND only when that child is ticked (an unticked child's money is not
paid, so nothing may move). Goal = `data.goalFor(saveChildId)`.

`saveChildId` = first child (creation order) with `data.goalFor(id) != null`;
row hidden when none (e.g. Seed.empty — but that state shows `_EmptyBody`
anyway, see §d).

## (c) Interactions → navigation

| Control | Action | Destination |
|---|---|---|
| Scrim tap / system back | `context.pop()` | `/money` (P12 ledger) |
| `{Name} paid in cash` check | toggles local ticked set (`setState`) | — |
| Savings `NestToggle` | toggles local `saveOn` | — |
| `Mark as paid & start the celebration` (≥1 ticked) | dispatches payout event(s) per §b | on stream proof: `pop()` → `/money` + toast |
| CTA with 0 ticked | disabled (`onPressed: null`, opacity .45) | — |
| `Try again` (failure body) | `PocketMoneyLoadRequested` | — |
| `Add a child` (empty body) | `context.push(FamilyRoutePaths.addChildren)` | `/add-children` |

Route constants: `PocketMoneyRoutePaths.payout` (`/payout`), entry from P12
hero `context.push(PocketMoneyRoutePaths.payout)`. Router already registers
`payoutRoute` top-level with `BlocProvider + PocketMoneyLoadRequested` and
parent-only kid guard — no router change.

## (d) Empty / loading / error states

- `initial`/`loading`: `Center(CircularProgressIndicator(color: leaf))`
  (same as P12).
- `failure`: message (`state.errorMessage ?? 'Something went wrong'`,
  bodySmall ink-2, centered) + `NestButton.secondary('Try again',
  fullWidth: false)` → `PocketMoneyLoadRequested`. Write failures keep
  `loaded` + toast (no full-screen swap).
- Loaded with `data == null || children.isEmpty` (Seed.empty/fresh):
  `_EmptyBody` — `NestStatusBar` + title `Pocket money` + `NestEmptyState`
  (coin art, title `No payouts yet`, message
  `Add a child to start tracking pocket money.`, action `Add a child` →
  `/add-children`). No sheet, no scrim.
- Loaded with zero owed for all children (just paid): sheet renders with
  `£0.00` amounts, CTA disabled (nothing ticked by default — default tick
  applies only to children with owed > 0; if none, ticked starts empty).
- Sheet overflow (small heights): sheet content wrapped in
  `SingleChildScrollView` inside the max-height-88 % container so 320×568
  never overflows.

## (e) Accessibility

- Every check: `Semantics(button, checked, enabled, label, onTap:)` —
  `getSemanticsData().hasAction(SemanticsAction.tap)` true and
  `performAction(tap)` toggles the real ticked set (assert in tests).
- `NestToggle` / `NestButton` already expose tap actions; toggle carries
  the full `Move one pound of …` label; CTA label is its text.
- Sheet title `Semantics(header: true)`; sheet region labelled
  `<Weekday> payout` (role dialog equivalent: `Semantics(container: true,
  label:)` around the sheet).
- Decorative: avatars + tick glyph `ExcludeSemantics` (label lives on the
  control); summary card behind scrim `ExcludeSemantics` (not actionable,
  avoids focus trap behind modal).
- Tap targets: checks 48, toggle ≥59×44 (DS), CTA 52 full-width, scrim whole
  screen — all ≥ 44.
- Text scale 1.3 (clamped 1.0–1.3 app-wide): names/amounts `maxLines: 1 +
  ellipsis`; saverow + caption wrap freely; sheet scrolls if taller than
  88 %.
- Width 320: gutters stay 20; `Expanded` text columns absorb shrink; check
  48 + avatar 44 fixed; amount `softWrap: false + ellipsis`.
- Contrast: ink-2 on surface / on tinted avatars ≥ 4.5:1 both themes
  (inherited tokens); leaf-on-surface check glyph is large (24 px) + bold.

## (f) Test plan (new files, `app/test/features/pocket_money/`)

1. `payout_bloc_test.dart` — `PocketMoneyPayoutSubmitted` calls
   `recordPayout` with (childId, amount, 100, goal-lego); zero-save variant
   passes (0, null); repo throw → `errorMessage` contains
   `We couldn’t save that` (ASCII? P12 uses U+2019 — match
   `_submitErrorMessage` exactly) and status stays `loaded`.
2. `payout_repository_test.dart` (extend or new) — seeded DB `recordPayout`
   (maya, 420, savings 100, goal-lego): new `payout` row −420, `savings_move`
   +100, goal saved 1550→1650, `owed('maya')` → 0; Leo untouched (£2.10).
3. `payout_view_test.dart` — pumped at `/payout` via `pumpAppRoute` +
   `disposeApp` (RULES §7: drain Drift timer): renders `Saturday payout`
   (derived from `payoutLabel`-style weekday, pinned weekday 6 → Saturday),
   `Tick once you've handed over the cash`, Maya `£4.20` ticked / Leo
   `£2.10` unticked, `Move £1.00 of Maya's to her Lego fund` toggle ON,
   CTA + caption; check tap toggles `checked`; toggle tap flips;
   semantics: every control `hasAction(tap)` + `performAction` changes
   state; CTA with Maya ticked → DB payout row lands, owed £0.00, pops to
   `/money`; untick-all disables CTA; no `google_fonts` import anywhere.
4. `payout_geometry_test.dart` — pins the CSS stack: sheet side padding 20,
   bottom 50, radius-top 32, grabber 40×5, title 24/30, gaps 4/14/10/14/8,
   row padding 14, avatar 44, row-gap 12, check 48×48 r14, CTA min-h 52,
   status reserve 47. Fails on any drift.
5. `payout_responsive_test.dart` — 320×844 + textScale 1.3: no overflow
   (`tester.takeException` null), checks still tappable, sheet scrolls;
   dark theme: same copy, `leaf` CTA, scrim black@62% token.
6. Existing suites (`flutter test` whole repo) must stay green; `dart format`
   clean; `flutter analyze` → No issues found.

## (g) SHARED_REQUEST

None. All work is inside the allowed §1 paths:
`features/pocket_money/presentation/**` (view rewrite + new
`widgets/payout_sheet.dart`), `presentation/bloc/` (one event + one
handler), `test/features/pocket_money/**`, `docs/screens/P13/**`.
`recordPayout` exists; weekday full name is a feature-local const; the
radius-16 row uses raw surface/shadow tokens (no DS change — `NestCard`
stays radius-24 for its own call sites). No route/DI/schema/seed change.

Builder order: (1) event + bloc handler + bloc test; (2) `payout_sheet.dart`
widgets; (3) `PayoutView` rewrite (delete the `const new` placeholder);
(4) view + geometry + responsive tests; (5) `shot.sh` light + dark vs PNG,
`compare.py`, fix drift to ±2 px (title, first row, each card top, CTA
rect — shapes, not just text).

VERDICT: PASS
