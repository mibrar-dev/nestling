# P12 · 2 BUILD (integrate, iteration 3)

## Outcome

**Zero code changes required.** `dart format` 0 changed, `flutter analyze` →
`No issues found!`, full suite **1909 passed / 1 skipped / 0 failed**. No edit
was made to `app/**` by this stage.

Iteration 2 exited `test=PASS bugs=PASS ui=PASS` with only `review=FAIL`, so
this iteration's real integration risk was **not** the logic/UI seam — it was
that main had just merged a *shared design-system* change into a screen that
consumes it:

```
0cdb53c Merge shared/segmented_semantics: one semantics node per segmented option
        → lib/core/design_system/components/nest_segmented.dart  (+6)
          lib/core/design_system/semantics_actions_test.dart    (+63/−5)
          docs/screens/_shared/segmented_semantics_REPORT.md
74a0312 Shared brief: segmented semantics
```

`MoneyLedgerView` renders `NestSegmented<String>` (the Maya/Leo picker), and
that fix changed the semantics tree of a component P12 both uses and asserts on.
It merged clean — no P12 assertion went stale, no per-option node regressed.

## Summary of 2a (logic, iteration 3)

**No contract change**: no state, event, entity or `watchLedgerData` shape
moved. The only behavioural change is the owed-math rule.

- **Finding 4 (same-second tie in `summarise`) — fixed.** `summarise()` is now
  order-independent: it locates the latest `payout` instant first, then sums
  `weekly_base` + `quest_bonus` rows with `date >= payout`, so a row sharing the
  payout's second is counted as unsettled instead of depending on row order.
  Same rule mirrored into `_owedFromEntries` in the shared test fallback, so
  production and fake agree. New regression test pins **both** input orders
  (payout-first and bonus-first → quests 25 / base 0 / total 25). Values on
  untied data are unchanged (Maya 420, Leo 210).
- Belt-and-braces `rowid desc` tie-break in core's `watchLedger` filed as
  `SHARED_REQUEST.md` §4 — core, non-blocking, P12 is correct without it.
- **Finding 7 (raw exception suffix) retained deliberately**: stripping the
  raw cause would break ~12 pinned `contains(...)` expectations across P06,
  P12 and the states suites, and the friendly `We couldn’t…` lead (U+2019) is
  already the parent-facing part. Documented, not silently dropped.
- Finding 5 (`next_payout.dart` in `domain/`) kept — `1_plan.md` §b mandates
  the path, the view and `next_payout_test.dart` import it, and P13 imports
  the same path.
- Finding 9 (`setup` coupling) accepted trade-off; finding 8 (P13 hand-off)
  carried, with the note that 2a cannot write into P13's docs under RULES §1.

## Summary of 2b (UI, iteration 3)

- **Finding 1 (MAJOR) — the status-bar band is now pinned above the scroller.**
  Verified in the merged code, not just reported: `_LoadedBody.build` (view:306)
  and `_EmptyBody.build` (view:582) are both
  `Column[NestStatusBar, Expanded(ListView)]`, so the 47 px reserve is a
  **preceding sibling** of the scroller exactly as `P12-money.html:17-20`
  and `components.css:46/65` define it. Previously it was `ListView` child 0,
  so the longer-than-fold ledger scrolled the reserve away and painted the
  white history cards under the OS clock. P12 was the only screen doing it.
  At rest nothing moves — anchors stay title 55 / segmented 105 / owed 173 /
  `Payout time` 312 / goal 400 / history 504 — and because both layouts are
  pixel-identical at scroll 0, 2b added a guard that **drags the list 120 px**
  and asserts the band is still at top 0, the scroller still starts at 47, and
  the first history row paints at `>= 47`.
- **Finding 2 — the sheet now uses the shared `NestTextField.errorText`.** The
  hand-rolled `SizedBox` + `Semantics(liveRegion)` + `Text` error block (which
  sat under the *Note* field rather than the field it described) is gone; the
  component's own invalid state and its own live region are used instead, so
  the error is announced once and attaches to Amount.
- **Finding 3 — the armed write confirmation carries its child id.** The single
  nullable tuple became a list of `_PendingWrite { childId, count, message }`;
  the listener now requires `pending.childId == state.selectedChildId` and its
  `listenWhen` also fires on selection change, so a write armed for Maya retires
  when the parent taps Leo, and two submits before the first emission no longer
  clobber each other. The regression test uses a gated repository fake so the
  switch-before-round-trip state is reachable, not a race.

## FIXES

| Item | Status |
|---|---|
| Shared `NestSegmented` semantics change vs P12's assertions | **Not needed** — merged clean; P12's states suite still asserts `hasAction(tap)` + `performAction` drives real state (lines 303/312/695/732/744) |
| Finding 1 (MAJOR) status bar scrolling away | Fixed by 2b; **re-verified by me** in the merged source (306/582) plus the new scrolled-state guard |
| Finding 2 (sheet inline error) | Fixed by 2b — shared `errorText` |
| Finding 3 (toast misattribution across a child switch) | Fixed by 2b — `_PendingWrite` list with child id |
| Finding 4 (`summarise` same-second tie) | Fixed by 2a in production **and** the test fallback; both input orders pinned |
| Finding 7 (raw exception suffix) | Retained **deliberately** by 2a with rationale (≈12 pinned `contains` expectations); friendly lead shipped |
| Findings 5, 8, 9 (`next_payout` path, P13 hand-off, `setup` coupling) | Left open with documented rationale — plan-mandated path / RULES §1 / declined for P06 single-subscription compat |
| Finding 6 (private `_PageTitle`, 4th copy) | Left open — needs `core/`; `SHARED_REQUEST.md` §2 |
| `SHARED_REQUEST.md` §4 (core `watchLedger` tie-break) | Filed by 2a, non-blocking |
| Mismatched BLoC states / events | Not needed — no shape changed; 2b coded against iteration-2 shapes |
| Imports / renamed members | Not needed — analyze clean on the first run |
| Failing tests caused by the merge | Not needed — 1909/1909 pass unedited (was 1895; +14 from the new guard, tie and toast tests) |
| `dart format` drift | Not needed — 437 files, 0 changed |
| Skipped tests | 1, intentional: **P12-BUG-04** (shared `NestSegmented` 44 px floor at 320 dp, `SHARED_REQUEST.md` §3). main's shared brief fixed *semantics*, not the tap-target floor, so the skip correctly stands — P12 must not fork a shared control |

No redesign, no refactor, no scope expansion.

## Verification (merged halves, this worktree)

```
$ dart format .
Formatted 437 files (0 changed) in 1.22 seconds.
```

```
$ flutter analyze
Analyzing app...
No issues found! (ran in 3.7s)
```

```
$ flutter test
00:37 +1909 ~1: All tests passed!
```

```
$ flutter test test/features/pocket_money
00:07 +316 ~1: All tests passed!

$ flutter test test/features/pocket_money/money_ledger_geometry_test.dart
00:01 +11: All tests passed!
```

The `~1` is the single documented `P12-BUG-04` skip. The drift
"created the database class AppDatabase multiple times" `WARNING`s in the raw
output are pre-existing `test_scope.dart` notices (present in main's runs), not
failures.

## Scope

Committed-since-main plus uncommitted changes, filtered against RULES §1
(`app/lib/features/pocket_money/**`, `app/test/features/pocket_money/**`,
`docs/screens/P12/**`) → **no file outside it**. `git diff main -- app/lib/core
app/lib/app tools/` → **empty**: P12 touched no shared code, and `analysis_options.yaml`
is byte-identical to main. No simulator booted, installed on, screenshotted or
driven. No image attached.

## Handed to stage 4/5

1. **Stage 5 must re-shoot light + dark.** 2b's status-bar pin is
   deliberately pixel-identical **at rest**, so `cmp_*_2` should show no band
   movement — if it does, the pin regressed geometry. The scrolled state has
   never been pixel-compared; it is now covered by a widget guard instead
   (drag 120 px → band stays at 0, scroller at 47, first row `>= 47`).
2. Still blocked on `core/`, not on P12 — do not re-report as P12 defects:
   `SHARED_REQUEST.md` §2 (`.ptitle` → shared `NestPageTitle`), §3
   (`NestSegmented` 44 px floor, the skipped BUG-04), §4 (core `watchLedger`
   tie-break).
3. Deliberately open with rationale: findings 5 (plan-mandated path), 7
   (retained diagnostics), 8 (**P13 hand-off** — `state.items` is the
   *selected* child's ledger), 9 (declined coupling).
4. `/payout` (P13) is still the 1.5 KB placeholder that `Payout time` pushes to
   — other screen's loop.

VERDICT: PASS
