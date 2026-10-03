# P12 · 2 BUILD (integrate, iteration 2)

## Outcome

**Zero code changes were required again.** The halves merged clean:
`dart format` 0 changed, `flutter analyze` → `No issues found!`, full suite
**1895 passed / 1 skipped / 0 failed**. This is the *second* iteration to need
no integration fix, but it is not a repeat of iteration 1: this time the two
builders were working against a **moved baseline** (`ca654e6 Merge branch
'main' into screen/P12`, which brought K03 and other screens' merged work),
against **rewritten briefs** (`.brief_build_logic.md` / `.brief_build_ui.md`
both touched 12:21), and against a now-non-empty finding backlog
(`ORCHESTRATOR_NOTES.md`, `FIXES_1.md`, iteration 1 ran
`build=PASS test=FAIL review=FAIL ui=PASS bugs=FAIL`). Their edits landed on
top of each other without a single mismatch, and no regression leaked outside
the feature.

I made no edit to `app/**` — only re-verification and this report.

## Integration seam — the one real risk, checked

The seam between logic and UI was the same as iteration 1 (`MoneyLedgerData.setup`,
`ledgerDataFallback`, `PocketMoneyEntry.dateTz`). Iteration 2 moved pieces, so
I verified the move rather than trusting the notes:

- `lib/features/pocket_money/domain/pocket_money_repository.dart` is
  **abstract-only again** (interface methods only, no fallback body).
- `ledgerDataFallback` lives solely in the new
  `app/test/features/pocket_money/ledger_data_fallback.dart`; its five call
  sites are all test files.
- **No production file imports the test helper** (`grep -rn ledger_data_fallback lib/`
  → no hits), so nothing in `lib/` reaches into `test/`.
- No state/event shape changed: `data`, `selectedChildId`, `items` and the three
  P12 events keep their iteration-1 shapes, so 2b's view needed no adaptation.

## Summary of 2a (logic, iteration 2)

- Review 7 (raw `error.toString()` reaching the parent) **fixed in the bloc**:
  `_loadErrorMessage` → `We couldn’t load your ledger: <raw>` and
  `_submitErrorMessage` → `We couldn’t save that: <raw>` (curly ’ U+2019).
  The raw cause is retained after the colon so every pinned `contains(...)`
  still matches; three new `startsWith(...)` assertions lock the friendly copy
  in `pocket_money_ledger_bloc_test.dart`. P06's setup messages byte-identical.
- Review 9 (test helper in `domain/`) **fixed**: fallback + two private helpers
  moved to the test helper; the six P06 fake call sites gained an import each.
- Review 10 (`MoneyLedgerData.setup` coupling) **declined with reason** — a
  second stream re-breaks the P06 fakes' single-subscription stubs
  (`Bad state: Stream has already been listened to`). Single-stream is
  load-bearing for P06 compat; the field stays optional.
- Review 8 (`next_payout.dart` in `domain/`) **kept** — `1_plan.md` §b
  mandates that path and 2b's view + test import it; moving it mid-iteration
  would break the UI half.
- Review 13 recorded as a **P13 hand-off note**: `state.items` is now the
  *selected* child's ledger, not the *active* child's, and `payout_view.dart`
  reads it.

## Summary of 2b (UI, iteration 2)

All six `ORCHESTRATOR_NOTES.md` mandates met, and the iteration-1 finding
backlog closed:

- **The 16 px uniform shift is gone.** The `SizedBox(height: s4)` between
  `NestStatusBar` and the title was deleted in *both* the loaded and the empty
  body. Measured tops now match the design: title **55**, segmented **105**,
  owed card **173**, goal card **400**, history **504** — all within ±1 px,
  pinned by `money_ledger_geometry_test.dart` (7 tests/6 red → **10 tests/10
  green**), which loads **real fonts** via `FontLoader` so it can actually
  catch a metric drift.
- Review 1/2/3/11 and BUG-05 closed: goal card 88 px (`.goal .t` line box
  22/16), history tile radius `NestRadii.allM` + 40×40 pinned, `buildWhen`
  added. Review 4 (hero +3 px) closed by **measurement, not guesswork**: the
  arithmetic only closes on a 17 px `.hero .lab` line box (Inter `normal` at
  14 px), applied at the call site like `.hero .amt`'s −0.4 — hero height 211
  and `Payout time` top 312 are now pinned.
- Review 5 (`Semantics(liveRegion: true)` on the sheet's inline error, asserted
  with `SemanticsFlag.isLiveRegion`) and review 6 (success toast now fires from
  a second `BlocListener` on stream re-emit, so it cannot precede a rejected
  write).
- BUG-01/02/03 (amount parser) fixed: integer-pence arithmetic with no float
  multiply, validating regex `^\s*£?\s*(?:\d{1,9}(\.\d{1,2})?|\.\d{1,2})\s*$`
  capped at £1,000,000.00, plus an ellipsis-bounded amount as defence in depth.
  All four skipped reproducers in `p12_bugs_test.dart` un-skipped and green.
- `SHARED_REQUEST.md` filed with three non-blocking shared items (tile radius,
  a shared `NestPageTitle`, a `NestSegmented` 44 px floor). **P12-BUG-04 stays
  `skip: true` by design** — P12 must not fork the shared control; its inline
  comment says so. That is the run's only skip.

## FIXES

| Item | Status |
|---|---|
| Mismatched BLoC states / events between halves | Not needed — no shape changed in iteration 2; 2b's view compiled against 2a's state as-is |
| `MoneyLedgerData.setup` / `ledgerDataFallback` seam | Not needed — verified moved and absorbed (see above); no shim, no adapter |
| `ledgerDataFallback` leaking test code into `lib/` | Not needed — domain is abstract-only; `lib/` has zero references to the test helper |
| Imports broken by the helper's move to `test/` | Not needed — the six P06 fakes + ledger bloc test each gained an import; analyze clean first run |
| Renamed members across halves | Not needed — every `1_plan.md` name still exists |
| Failing tests caused by the merge | Not needed — 1895/1895 pass unedited (was 1814 in iteration 1; +81 from the new geometry/bug/repro tests) |
| `dart format` drift | Not needed — 436 files, 0 changed |
| ORCHESTRATOR_NOTES.md (6 items, mandatory) | Done by 2b; **re-verified by me** — geometry suite 10/10 green with the design values pinned at ±1 |
| Leftover `TODO(P12)` / placeholder in the P12 screen | Not needed — none |
| `google_fonts` / `GoogleFonts.*` in the feature | Not needed — none |
| `analysis_options.yaml` weakened | Not needed — byte-identical to main |
| Skipped tests | 1, intentional and documented (`P12-BUG-04`, shared `NestSegmented`, `SHARED_REQUEST.md` §3) |

No redesign, no refactor, no scope expansion.

## Verification (merged halves, this worktree)

```
$ dart format .
Formatted 436 files (0 changed) in 1.18 seconds.
```

```
$ flutter analyze
Analyzing app...
No issues found! (ran in 3.3s)
```

```
$ flutter test
00:33 +1895 ~1: All tests passed!
```

```
$ flutter test test/features/pocket_money
00:07 +308 ~1: All tests passed!

$ flutter test test/features/pocket_money/money_ledger_geometry_test.dart
00:01 +10: All tests passed!
```

The `~1` is the single intentional `skip` above. The drift
"created the database class AppDatabase multiple times" `WARNING`s in the raw
output are pre-existing notices from `test_scope.dart` (present in main's runs)
and are not failures.

## Scope

Committed-since-main plus uncommitted changes, filtered against RULES §1
(`app/lib/features/pocket_money/**`, `app/test/features/pocket_money/**`,
`docs/screens/P12/**`) → **no file outside it**. No `app/lib/core/**`, no
`app/lib/app/**`, no other feature, no `tools/screens/**`. No simulator was
booted, installed on, screenshotted or driven. No image attached.

## Handed to stage 4/5

1. **The 16 px translation is gone in widget space, but no screenshot has been
   taken since.** The orchestrator's ruling was based on `cmp_light_1`; stage 5
   must re-shoot light + dark and re-run `compare.py` to confirm the pixel band
   table now shows only accepted differences (status bar, DB rows).
2. **Per 2b, verify shape rects, not only text**: segmented thumb 173×44 at
   x 24, `Payout time` 310×52 at top 312, row buttons 170×48.
3. Three open review items are **deliberately deferred**, all documented in
   `SHARED_REQUEST.md` / the notes — do not re-report them as P12 defects:
   review 8 (`next_payout.dart` placement, blocked on a plan update), review 10
   (`setup` coupling, declined for a concrete P06 compat reason), review 13
   (`state.items` is now the *selected* child's ledger — a **P13** hand-off;
   `payout_view.dart` must set its own selection or keep an `activeChildItems`).
4. The hero card's semantics node still merges card + button into one button
   (iteration 1, 2b observation 2): operable, matches shipped P08, but worth a
   VoiceOver read in the UI check.
5. `/payout` (P13) is still the 1.5 KB placeholder the ledger's `Payout time`
   button pushes to — expected, other screen's loop.

VERDICT: PASS
