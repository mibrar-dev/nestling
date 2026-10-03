# 2 — INTEGRATE (iteration 1) — P13 Payout

Loop stage: combine the two parallel builder halves (`2a_build_logic.md` +
`2b_build_ui.md`) into one tree that formats, analyzes and tests clean.
Scope of this stage: **compile + green suite only**. No redesign, no new
behaviour, no simulator (rule: only `5_ui` may drive
`BC440E48-B3A3-43BC-971B-0EF5DB621874`).

## Headline

The two halves met with **zero integration breakages**. Neither builder
reported a contract change against the other, and none was needed: `2a` says
"CONTRACT CHANGES: None" and `2b` coded against exactly the event shape `2a`
shipped. Nothing in the merged tree had to be renamed, re-imported or
patched. The three commands the stage is graded on were already satisfied on
arrival and are re-proved below.

```
dart format --output=none --set-exit-if-changed .   → Formatted 462 files (0 changed)   exit 0
flutter analyze                                       → No issues found! (ran in 5.3s)  exit 0
flutter test                                          → 01:46 +2165 ~1: All tests passed!  exit 0
```

## Summary of 2a (logic)

- `pocket_money_event.dart` — new `PocketMoneyPayoutSubmitted(childId,
  amountPence, savingsMovePence, goalId)`, exactly as `1_plan.md` §b.
- `pocket_money_bloc.dart` — `on<PocketMoneyPayoutSubmitted>` registered,
  `_onPayoutSubmitted` forwards to `recordPayout`; a throw keeps
  `status: loaded` and sets `errorMessage` via the existing
  `_submitErrorMessage` (so the view toasts instead of swapping the screen).
- `payout_bloc_test.dart` (4) + `payout_repository_test.dart` (4) — 8 new tests,
  all green. No domain/data change was required: `recordPayout` (negative
  `payout` row + optional `savings_move` + goal bump, one transaction)
  already exists on `PocketMoneyRepository`.

## Summary of 2b (UI)

- `widgets/payout_sheet.dart` (**new**) — the `.pay` sheet: grabber,
  `<Weekday> payout` title, `.sub`, `PayoutChildRow` per child (creation
  order), `PayoutSaveRow`, `PayoutCheck`, CTA, caption; plus the
  feature-local `kPayoutWeekdayNames` / `payoutSheetTitle` /
  `payoutSaveChildId` helpers.
- `views/payout_view.dart` (**rewritten**, placeholder deleted) — full-screen
  route: dimmed P12 ledger + scrim + bottom-anchored sheet, loading /
  failure / empty states, submit → stream proof → toast → dismiss.
- `payout_view_test.dart` (18 tests) and `payout_widget_geometry_test.dart`
  (7 real-font geometry pins).
- `money_ledger_states_test.dart` — 1 line, the cross-chunk seam (below).

## FIXES items

### Done

| # | Item | Where | Change |
|---|---|---|---|
| 1 | P12's "Payout time pushes `/payout`" test drove `tester.pageBack()`, which looks for a back button. The real P13 sheet has no app bar (the design has none), so the lookup no longer found one. | `app/test/features/pocket_money/money_ledger_states_test.dart:513` | `await tester.pageBack()` → `await tester.binding.handlePopRoute()`. Same assertion, same intent (P12's own navigation contract), mechanics only. Applied by `2b`, verified by me — the assertion `currentPath == '/money'` + `find.text('Maya is owed')` is unchanged. |

That is the **only** edit made during this stage — and it was already on disk.
I changed **no** source file: no import, no renamed member, no BLoC
state/event fix-up was needed.

### Left (deliberately — not an integration defect)

| # | Item | Why left | Owner |
|---|---|---|---|
| 1 | **A ticked child owing £0.00 writes a £0.00 `payout` ledger row.** `_submit` dispatches one event per entry in `_ticked` using `_owedOf(data, childId)`, and `recordPayout` inserts unconditionally (`amountPence: -amountPence.abs()` → `-0`). `canSubmit` only requires that *≥1* ticked child owes > 0, so ticking Maya (£4.20) **and** an already-paid child (owed £0.00) lands a stray "Paid · <date> £0.00" row in the P12 ledger. | Behaviour, not a merge breakage: `2a`'s handler forwards exactly what `2b`'s view sends, so the halves are consistent and this is a plan-level decision (§b says "for each ticked child"). Fixing it means changing what the screen writes — redesign territory for this stage. Repro: tick Leo, submit once, re-open `/payout`, tick Maya **and** Leo, submit → a second `-0` payout row exists for Leo. Suggested smallest fix for the bugs stage: skip children with `owed == 0` when building the dispatch list, and mirror that in `_submitted`. | 4_review / 6_bugs |
| 2 | **The `failure` body has no test.** `payout_view_test.dart` covers initial/loading (implicitly), loaded and the empty body, but nothing drives `PocketMoneyStatus.failure` to assert the copy + `Try again` → `PocketMoneyLoadRequested`. | Test-coverage gap in a chunk boundary neither half owned, not a merge breakage. | 3_test |
| 3 | **`shot.sh` light + dark + `compare.py`** were not run (correctly: no simulator at this stage). Geometry is already pinned to ±2 px by `payout_widget_geometry_test.dart` against `design/screens/light/P13-payout.png` ÷3, so `5_ui` should be a confirmation pass. | Stage rule. | 5_ui |

## Integration checks I ran (beyond the three graded commands)

- **Format/analyze/test**: as above. `dart format` 0 changed, so the two
  builders left the tree already formatted.
- **Feature suite**: `flutter test test/features/pocket_money` → `00:13 +354
  ~1: All tests passed!`. All five P13 test files are picked up by the run:
  `payout_bloc_test`, `payout_repository_test`, `payout_view_test`,
  `payout_widget_geometry_test`, plus the four pre-existing P12 files.
- **The single `~1` skip is pre-existing and not mine**: `p12_bugs_test.dart:320`
  `skip: true`. No test was skipped, ignored or `@`-disabled to reach green.
- **Scope (RULES §1)**: `git status --porcelain` outside
  `docs/screens/P13/`, `app/lib/features/pocket_money/` and
  `app/test/features/pocket_money/` is **empty**. Nothing in `app/lib/core/**`,
  `app/lib/app/**`, another feature, or `tools/screens/**` was touched.
  `analysis_options.yaml` untouched. No `flutter clean`, no `flutter run`, no
  simulator booted or screenshotted.
- **No SHARED_REQUEST filed by either half**, and none is needed: the route,
  the DI (`payoutRoute` already registers `BlocProvider +
  PocketMoneyLoadRequested`), the schema and the seed are all as the plan
  assumed.

### Orchestrator-rule spot-checks on the merged tree

- **FONTS** — `grep -rn "google_fonts\|GoogleFonts" lib/features/pocket_money
  test/features/pocket_money` → **no hits**.
- **LETTER SPACING** — the only `letterSpacing` in the feature is P12's own
  `money_ledger_view.dart:365` (`-0.4`, the documented case). P13 adds none.
- **CHILD ORDER** — both the child rows (`payout_sheet.dart:207`) and the
  `.saverow` child (`payoutSaveChildId`) iterate `data.children`, i.e.
  creation order. A test asserts the order and the row positions.
- **COPY** — checked character-by-character against
  `design/html-source/screens/P13-payout.html:22-33`: ASCII `0x27` in
  `you've` / `Maya's`, U+00B7 (`kMoneyDot`) in `Weekly + quests · ` and in the
  `is owed £4.20 · £2.10` summary, `&` (not `&amp;`) in the CTA, U+2014 EM
  DASH in the success toast, and the `.saverow` string with only `{nick}`
  interpolated (the goal title is *not*).
- **BOTTOM EDGE (owner)** — the sheet is `Align(alignment:
  Alignment.bottomCenter)` inside a full-screen `Stack`, and its padding
  bottom is `NestDevice.homeH + NestSpacing.s4` = 34 + 16 = 50, matching
  `.pay { padding: 8px 20px calc(home-h + 16px) }`. Paper therefore owns the
  last pixel row; no coloured strip in either theme.
- **ALIGNMENT (owner)** — every sheet element shares `left = 20` /
  `right = 370`; pinned by the geometry test's design rects
  (`Rect.fromLTRB(20, …, 370, …)`).
- **BALANCED HEADINGS** — not used here, correctly. `P13-payout.html:5`
  (`.pay h2`) sets no `text-wrap: balance`, and the orchestrator rule
  forbids `NestBalancedText` on `.h2`. The `.ptitle` behind the scrim is a
  separate class from `.h1` in the CSS and its copy is a single line
  (`maxLines: 1`), so it matches its sibling P12, which uses a plain `Text`
  with `NestType.h1` and has cleared UI review.
- **ACCESSIBILITY ACTIONS** — `PayoutCheck` is
  `Semantics(container: true, button: true, checked: …, enabled: true,
  label: '{name} paid in cash', onTap: …, excludeSemantics: true)`: the
  `excludeSemantics: true` wrapper **does** pass `onTap:`. The tests assert
  `hasAction(SemanticsAction.tap)` and `performAction(SemanticsAction.tap)`
  flipping the real ticked set / saverow, and the scrim `GestureDetector`,
  `NestToggle` and CTA all expose tap.
- **TRIAL / PERIODS / PIP / NestChipWrap** — not touched by P13: no
  `subscription_status` write, no quest period logic, no Pip on this screen,
  no `NestChip` row.

## Left for the next stages

- `5_ui`: `shot.sh` light + dark on `BC440E48-B3A3-43BC-971B-0EF5DB621874`
  and `compare.py` against both PNGs; report the measured y of the screen
  title, the first control and each card top, design vs app (UI-verdict rule
  allows ±2 px; a uniform vertical shift is a FAIL).
- `4_review` / `6_bugs`: FIXES-left item 1 (the £0.00 payout row) is the one
  concrete behaviour defect I found in the merged tree.
- `3_test`: the untested `failure` body (FIXES-left item 2).

VERDICT: PASS
