# 2b — Build, UI chunk (iteration 1) — P13 Payout

## What I built

| File | State |
|---|---|
| `app/lib/features/pocket_money/presentation/widgets/payout_sheet.dart` | **new** — `.pay` sheet: grabber, `<Weekday> payout` title, sub, `PayoutChildRow`, `PayoutSaveRow`, `PayoutCheck`, CTA, caption, plus the feature-local `payoutWeekdayLabel`/`payoutSaveChildId` helpers |
| `app/lib/features/pocket_money/presentation/views/payout_view.dart` | **rewritten** — full-screen route (deleted the `const new` placeholder): dimmed P12 ledger + scrim + bottom sheet, loading/failure/empty states, submit → stream proof → toast → dismiss |
| `app/test/features/pocket_money/payout_view_test.dart` | **new** — 18 tests: copy, semantics actions, the write, navigation, states, 320 px / text-scale 1.3 / dark |
| `app/test/features/pocket_money/payout_widget_geometry_test.dart` | **new** — 7 real-font geometry tests pinning the design rects |
| `app/test/features/pocket_money/money_ledger_states_test.dart` | **1 line** (see the note below) |

`flutter analyze lib/features/pocket_money test/features/pocket_money` → **No
issues found**. `flutter test test/features/pocket_money` → **354 pass,
1 pre-existing skip, 0 fail**. `dart format` clean.

## Design geometry — measured design vs app

Measured off `design/screens/light/P13-payout.png` (÷3) by pixel-scanning the
PNG for the card fills, then rendered at 390×844 with the real bundled fonts
and measured with `tester.getRect`. **Zero drift on every element.**

| Element | Design | App | Δ |
|---|---|---|---|
| screen title `Pocket money` | 20, 55 · 350×34 | 20, 55 · 350×34 | 0 |
| dimmed summary card | 20, 101 · 350×50 | 20, 101 · 350×50 | 0 |
| `.pay` sheet top / height | 343 · 501 | 343 · 501 | 0 |
| sheet title box | 372 · h30 | 372 · h30 | 0 |
| `.sub` box | 406 · h20 | 406 · h20 | 0 |
| child row 1 (Maya) | 20, 440 · 350×76 | 20, 440 · 350×76 | 0 |
| child row 2 (Leo) | 20, 526 · 350×76 | 20, 526 · 350×76 | 0 |
| `.saverow` | 20, 612 · 350×72 | 20, 612 · 350×72 | 0 |
| CTA pill | 20, 698 · 350×52 | 20, 698 · 350×52 | 0 |
| footer caption | 758 · h36 | 758 · h36 | 0 |
| `.check` | 308, 454 · 48×48 | 308, 454 · 48×48 | 0 |
| `.avatar.s44` | 34, 456 · 44×44 | 34, 456 · 44×44 | 0 |

Two findings that came out of measuring rather than reading, and that are now
documented in the widget header so nobody "fixes" them later:

- **The 48×48 `.check` is what makes a `.child` row 76 px tall**, not the text.
  The avatar is 44 and `.who` is `22 + 18` = 40, so a padding-only row would
  render 72 and push every card below it 4 px up. The check is kept exactly
  48 px (no `Semantics`/`GestureDetector` padding around it) and pinned by a
  test. In the PNG the check top is `440 + 14` (flush), not centred, which is
  the same fact seen from the other side.
- **The dark PNG confirms the tick glyph is `--surface`, not `--onLeaf`** —
  sampled `#1F1C2E` on the `#3CC98A` fill at `1F1C2E` = dark `--surface`. The
  unticked state paints the glyph in `tokens.surface` on a `tokens.surface`
  fill (the token-only spelling of the CSS's `color: transparent`), and the
  glyph stays mounted in both states so the rect can never change between
  ticks.

## Owner rules applied

- **Bottom edge** — the sheet paints `tokens.paper` with a 50 px bottom pad
  (`home-h + 16`) and is bottom-anchored, so the paper owns the last pixel
  row. Measured `sheet.bottom == 844.0` exactly; no coloured strip in either
  theme (dark PNG also has paper to `y=2531`).
- **Alignment** — 20 px gutters everywhere: title, both child rows, saverow,
  CTA and the sheet all report `left = 20`, `right = 370`.
- **Child order** — rows and the saverow iterate `data.children`, i.e.
  creation order (Maya, then Leo). A test asserts the `PayoutChildRow` order
  and the vertical positions, so alphabetical ordering cannot creep back in.
- **Copy** — every string compared against
  `design/html-source/screens/P13-payout.html` character-for-character: ASCII
  `0x27` in `you've` / `Maya's`, U+00B7 (`kMoneyDot`) separators, U+2014 em
  dash in the success toast, `&` not `&amp;`. The saverow is the design
  string with only `{nick}` interpolated — the goal title is **not**
  interpolated (`her Lego fund`, not `her Lego Friends set fund`).
- **Tokens only** — no literal colour or size anywhere; the two size
  overrides the CSS needs (`.pay h2` 24/30 w900, `.nm` 16/22) are
  `copyWith` at the call site, and the `.child`/`.saverow` radius-16 cards are
  built from `surface` + `cardShadow` + `NestRadii.allM` because `NestCard`
  is fixed at `--r-l`.
- **DS components not re-implemented** — `NestStatusBar`, `NestCard`,
  `NestButton`, `NestToggle`, `NestAvatar`, `NestIcon`, `NestEmptyState`,
  `NestToast`, `CircularProgressIndicator` are all shared. `PayoutCheck` is
  feature-local because no DS component matches a 48×48 / r14 / 2 px check
  (the shared one is the kid's 56 px ring), which the plan also states.
- **No `google_fonts`**, no Material letter-spacing added.
- **`NestBalancedText` deliberately NOT used on the sheet title** — the brief
  scopes it to `.display`/`.h1`/`.kid-title`/`.kid-hero` and forbids it on
  `.h2`, and `.pay h2` sets no `text-wrap: balance`.
- **Semantics** — every control carries `hasAction(SemanticsAction.tap)`;
  the checks and the toggle are asserted both by `getSemanticsData()` and by
  `performAction` changing the real state/DB. The `excludeSemantics: true`
  wrappers all pass `onTap:`.

## Decisions worth flagging

1. **Default tick** — plan §b says `{data.children.first.id}`; §d says the
   default tick only applies to children with `owed > 0`. I implemented §d
   (first child in creation order with money owed, empty when nobody owes
   anything), which reproduces the design (Maya ticked, Leo not) *and* §d's
   just-paid case with one rule. The CTA is additionally disabled when no
   ticked child owes anything, so a £0 payout can never be submitted.
2. **`_goBack()` instead of `context.pop()`** — `/payout` is normally pushed
   on `/money`, but `shot.sh` launches it as `INITIAL_ROUTE`, where `pop()`
   throws `GoError("There is nothing to pop")` (this actually crashed a test
   before I guarded it). The scrim tap and the post-write dismissal both use
   `canPop() ? pop() : go('/money')`, the same pattern as `PaywallView` /
   `CreateAccountView`.
3. **Sheet scroll** — the `.pay` column sits in a `SingleChildScrollView`
   inside the `maxHeight: 88 %` container, so 320×568 and text scale 1.3
   scroll instead of overflowing (both covered).
4. **One out-of-boundary line, deliberately** — `money_ledger_states_test.dart`
   is a P12 file, so outside my chunk. Its "Payout time pushes /payout" test
   called `tester.pageBack()`, which used to find a back button because the
   placeholder `PayoutView` had an `AppBar`. The real P13 sheet has no app bar
   (the design has none), so that one line is now
   `await tester.binding.handlePopRoute()` — same assertion, same intent
   (P12's own navigation contract), mechanics only. Without it the feature
   suite is red, and I was not going to leave it that way or skip it.

## Contract with the logic builder

`2a_build_logic.md` reports **no CONTRACT CHANGES**, and the view codes against
`PocketMoneyPayoutSubmitted(childId, amountPence, savingsMovePence, goalId)`
exactly as the plan specifies. The savings rule implemented here matches §b:
the 100 p move goes to the first goal-bearing child **and only when that
child is ticked**; every other child gets `(0, null)`. Two tests write to the
real DB and assert the rows (`-420`/`-210` payouts, one `+100` savings_move on
`maya`, and zero `savings_move` rows when the toggle is off).

## LEFT FOR NEXT ITERATION

- `shot.sh` light + dark and `compare.py` band review — deliberately not run
  here (this stage must never touch a simulator); the geometry is already
  pinned by the widget tests above, so 5_ui should be a confirmation pass.
- The `_EmptyBody` copy (`No payouts yet`, `Add a child`) has no design PNG to
  check against — it follows plan §d and mirrors P12's empty body.
- Nothing in plan §a, §c, §d, §e or §f is outstanding for the UI chunk.

VERDICT: PASS