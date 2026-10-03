# P12 · 2 BUILD (integrate, iteration 1)

## Outcome

**Zero code changes were required.** The two halves compiled and tested clean
as merged — `flutter analyze` printed `No issues found!` on the first run and
the full suite passed 1814/1814 without a fix. This stage therefore made no
edit to `app/**`; it only re-verified the combined result and recorded it.

This is a real result, not a skipped stage: the checks below were run against
the *merged* worktree (both builders' files present simultaneously), which is
exactly the configuration that produces BLoC-state, import and renamed-member
breakages. None appeared. The one genuine seam between the halves —
`MoneyLedgerData.setup` and `ledgerDataFallback` — was absorbed by the UI
builder before integration, as its report documents.

## Summary of 2a (logic)

Contract from `1_plan.md` §a, with two additive deviations, nothing renamed:

- New entities `MoneyChild(id, nickname)`, `SavingsGoalData` (+`fraction`),
  `MoneyLedgerData` (`children, entries, oweds, goals, payoutDay, zoneId,
  setup?` + `firstChildId` / `childById` / `entriesFor` / `owedFor` /
  `goalFor`).
- `PocketMoneyEntry.dateTz` (default `'Europe/London'`), mapped in
  `_toEntity` and in the JSON model (`fromJson` falls back for old payloads).
- `next_payout.dart`: `nextPayoutDayUtc` + `payoutLabel` via `family_time`
  only (zone-midnight arithmetic, DST-safe).
- `watchLedgerData()` on the repository interface, plus the public top-level
  `ledgerDataFallback(setupStream, itemsStream)` so Dart's `implements`
  (which does not inherit concrete interface bodies) stays cheap in the six
  P06 test fakes.
- `PocketMoneyBloc` serves `/money` + `/pocket-money-setup` + `/payout` from a
  **single** `emit.forEach(watchLedgerData())` subscription — P06's
  `_pendingDay` / `_requestedBase` bookkeeping preserved, submit errors set
  `errorMessage` only so status stays `loaded` and the view toasts.
- New events `PocketMoneyChildSelected`, `PocketMoneyAddMoneySubmitted`,
  `PocketMoneySpendingSubmitted`; new state `data`, `selectedChildId`.
- New tests: repository (24), `next_payout` (7), ledger bloc (7); one-line
  `watchLedgerData` overrides added to three P06 test files' fakes.

## Summary of 2b (UI)

- `money_ledger_view.dart` rewritten (was the 1.5 KB `AppBar` + `ListTile`
  placeholder): `Scaffold(paper)` → `BlocListener` (submit-failure toast) →
  `BlocBuilder` → title / child `NestSegmented` / hero `NestCard(variant:
  hero)` / goal card / `History` + rows / two row buttons / footer caption.
- New `MoneyHistoryRow` (`.hrow` geometry, per-type copy/sign/tint, coin art on
  the quest tile), `MoneyEditSheet.addMoney` / `.recordSpending`, and
  `money_pounds.dart` (copy helpers + `−` U+2212 · `·` U+00B7 · `—` U+2014).
- Hero amount `NestType.kidHero` with `letterSpacing: -0.4` at the call site
  (the known P12 tracking case); payout date computed via `payoutLabel`, never
  the design's hard-coded `Sat 4 Oct`; goal card omitted entirely for a child
  with no goal; numbers read from `Seed.demo` (asserted `£4.20` / `£2.10` /
  62%).
- 12 new widget tests covering seeded copy, every history row, segment switch,
  `/payout` push, both write-through flows, sheet close, dark mode, empty
  state, a copy audit (no ASCII hyphen anywhere), a11y tap actions, 44 px
  semantics rects, 320-wide × 1.3 text scale.

## FIXES

| Item | Status |
|---|---|
| Mismatched BLoC states / events between halves | **Not needed** — 2b read `state.data` / `state.selectedChildId` / `state.items` as §b specified; no rename or state-shape mismatch |
| `MoneyLedgerData.setup` extra field | **Not needed** — additive and optional; P12 ignores it (P06's payload) |
| `ledgerDataFallback` new public helper | **Not needed** — production code never calls it; widget code uses `repository.watchLedgerData()` |
| Missing / stale imports in merged files | **Not needed** — `flutter analyze` clean on the first run |
| Renamed members across halves | **Not needed** — every name in `1_plan.md` exists |
| Failing tests caused by the merge | **Not needed** — 1814/1814 passed unedited, including P06's shared-bloc suites |
| `dart format` drift | **Not needed** — 431 files, 0 changed |
| Leftover `TODO(P12)` / placeholder in the P12 screen | **Not needed** — none (`payout_view.dart`'s `No items yet` is P13's screen, another stage's work) |
| `google_fonts` / `GoogleFonts.*` in the feature | **Not needed** — none |

No redesign, no refactor and no scope expansion was performed.

## Verification (run in this worktree, merged halves)

```
$ dart format .
Formatted 431 files (0 changed) in 1.43 seconds.
```

```
$ flutter analyze
Analyzing app...
No issues found! (ran in 3.6s)
```

```
$ flutter test
00:38 +1814: All tests passed!
```

```
$ flutter test test/features/pocket_money
00:05 +227: All tests passed!
```

(the drift `WARNING` lines in the raw output are the pre-existing
"created the database class AppDatabase multiple times" notices from
`test_scope.dart`; they appear in main's runs too and are not failures)

## Scope

`git status --porcelain` filtered against the §1 allow-list
(`app/lib/features/pocket_money/**`, `app/test/features/pocket_money/**`,
`docs/screens/P12/**`) → **no file outside it**. No `app/lib/core/**`, no
`app/lib/app/**`, no other feature, no `tools/screens/**`. No simulator was
booted, installed on, screenshotted or driven. No images attached.

## Handed to stage 4/5

1. Screenshot + `compare.py` in light and dark is still outstanding — no
   geometry has been checked against the 1170×2532 PNGs yet. 2b's UI tests
   assert geometry in widget space (20 px gutters, shared x edges), but the
   pixel band table has not been produced.
2. Per 2b, a UI check should measure the **background rects**, not just text:
   segmented thumb 173×44 at x 24, hero `Payout time` button 310×52, row
   buttons 170×48 (owner rule: shapes, not only text).
3. 2b observation 2 stands for the UI stage: the hero card's semantics node
   merges the whole card into one button (`Maya is owed\n£4.20\n…\nPayout time
   for Maya`). It is operable and matches shipped P08 behaviour, so it is a
   design-system note, not a P12 fix — but the UI stage should confirm it does
   not read badly.
4. `/payout` (P13) is still the 1.5 KB placeholder; the ledger's `Payout time`
   button pushes to it. Expected until P12/P13's loop builds it.

VERDICT: PASS
