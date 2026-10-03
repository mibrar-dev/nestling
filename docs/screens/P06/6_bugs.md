# P06 Pocket money setup — Stage 6 adversarial bug hunt (iteration 2)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding
(P05 → P06 → P07). No `ORCHESTRATOR_NOTES.md` exists. No Pip on this screen.

Method: adversarial testing against the committed screen (no source edits).
Executable repros live in `app/test/features/pocket_money/p06_bugs_test.dart`;
every bug test is `skip: true` so the default suite stays green (`flutter test
test/features/pocket_money/` → `+91 ~7: All tests passed!`). Removing the skips
makes all seven fail deterministically — verified this iteration:

```text
00:00 +0 -1  P06-BUG-01  Expected: <400>       Actual: <350>
00:01 +0 -2  P06-BUG-02  Expected: <6>         Actual: <7>
00:02 +0 -3  P06-BUG-03  Expected: >= <30>     Actual: <19.11864406779661>
00:02 +0 -4  P06-BUG-04  Expected: >= <44.0>   Actual: <40.285714285714285>
00:02 +0 -5  P06-BUG-05  "Weekly amount" not found (form blanked)
00:02 +0 -6  P06-BUG-06  Expected: null        Actual: 'Exception: database is locked'
00:02 +0 -7  P06-BUG-07  Expected: empty       Actual: [(childId: ghost, pence: 50)]
00:03 +8 -7  Some tests failed.
```

## Summary

| # | Severity | Area | One-line |
|---|---|---|---|
| 01 | **MAJOR** | bloc state race | weekly-base stepper loses rapid taps (lost update, –50p per lost tap) |
| 02 | minor | bloc state race | fast Sun→Sat payout-day correction silently dropped |
| 03 | minor | visual fidelity | day pills paint at ~55–63% of the design size via `FittedBox` |
| 04 | minor | accessibility | day cells are 40.3 dp wide at 390 (spec: ≥ 44×44) |
| 05 | minor | error handling | a failed write replaces the whole form with the load-failure body |
| 06 | minor | state hygiene | `errorMessage` is never cleared after recovery |
| 07 | minor | robustness | a stepper event for an unknown child id still writes ±50p |

---

## BUG-01 (MAJOR) — weekly-base stepper loses rapid taps

**Where:** `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart:79-97`
(`_onWeeklyBaseStepped` reads `state.setup?.childById(id)?.weeklyBasePence ?? 0`
and writes an *absolute* `current + delta`).

**Repro:** on `/pocket-money-setup`, tap `+` on Maya twice in quick succession
(the two `PocketMoneyWeeklyBaseStepped('maya', 50)` events are queued before the
`watchSetup` stream re-emits). Maya ends on **£3.50**, not £4.00 — one tap is
lost. The same race makes a correction tap land on a stale base.

**Failing test:** `P06-BUG-01: two quick "+" taps must each add 50p (real repo)`
(real Drift repository; 350 vs 400).

**Root cause:** the bloc's arithmetic is a read-modify-write on state that is
updated only by the independent `emit.forEach` subscription, while the event
handlers run to completion before the stream re-emits. Note: a widget-level
double `tester.tap` currently lands (see “attacks that hold”), because the test
crosses the pointer-event gaps the DB round-trip needs — the defect is timing-
dependent and real under load/slow storage, which is why it is rated major:
the amount the parent sets can silently differ from the amount stored.

**Suggested fix:** make the write atomic. Either (a) have the repository accept
a delta — `UPDATE children SET weekly_base_pence =
MIN(MAX(weekly_base_pence + Δ, 0), 2000) WHERE id = ?` — or (b) keep an
in-flight per-child pending delta on the bloc/state and add it to the last
confirmed base, clearing it when the stream confirms.

---

## BUG-02 (minor) — fast Sun→Sat payout-day tap is dropped

**Where:** `pocket_money_bloc.dart:61-77` (`_onPayoutDayChanged` guard
`if (event.day == state.setup?.payoutDay) return;`).

**Repro:** tap `Sun`, then tap `Sat` straight away. The first write stores 7;
the second event still sees `state.setup.payoutDay == 6` (stream not yet
re-emitted), matches the guard, and is dropped. The stored payout day stays
**Sunday** although the last tap was Saturday.

**Failing test:** `P06-BUG-02: a fast Sun→Sat correction must end on Saturday
(real repo)` (7 vs 6).

**Suggested fix:** guard against the last *requested* day (a pending value on
the bloc) or read the current value from the repository; alternatively drop
the guard and let the idempotent write run — re-tapping the selected day is
already a harmless no-op at the DB level.

---

## BUG-03 (minor, largest remaining visual deviation) — day pills render scaled down

**Where:** `pocket_money_setup_view.dart:504-527` — each day cell wraps a
standard `NestChip` (14 px label, `0 14px` padding, 32 px pill) in
`FittedBox(fit: BoxFit.scaleDown)` inside a 44-tall box.

**Repro:** at 390 dp the cell width is 40.3 dp while the chip’s intrinsic box
is 73.8 dp (test-metric font); the whole pill — label, radius and 1.5 px
border — is scaled to fit, so the painted pill is **19.1 dp high** (real-device
Inter metrics land ~20–22 dp) instead of the design’s 32 dp with 13 px labels.
The design `.chip.day` uses `padding: 0; font-size: 13px` and fills the grid
cell (SPACING_SPEC §10.3 “cells Expanded, font 13 … scaleDown”).

**Failing test:** `P06-BUG-03: a day pill must paint at the design height
(32, ±2)` (19.1 < 30).

**Suggested fix (shared, not screen scope):** add an optional `labelStyle` /
compact mode to `NestChip` (pre-agreed follow-up in `1_plan.md` §7,
`SHARED_REQUEST` candidate — do not fork the component) so the day cell can
use `padding: 0`, 13 px label, no `FittedBox`. UI stage records the same
deviation (its “deviation 3”); it needs the shared change to close.

---

## BUG-04 (minor) — day cell tap targets are 40.3 dp wide

**Where:** `pocket_money_setup_view.dart:461-489` — 7 `Expanded` cells across
318 dp of card content with 6 px gaps.

**Repro:** at 390 dp `tester.getSize(p06_day_1)` is `40.3 × 44`; DESIGN_SPEC
§0.9 requires parent tap targets ≥ 44×44 (height is correct at 44; width is
not). At 320 dp the cells are ~30.3 dp wide (worse).

**Failing test:** `P06-BUG-04: every day cell must be a 44×44 parent tap
target` (40.29 vs 44).

**Suggested fix:** keep the 7-up single-select look but give the row a
horizontal scroll (like P10 chips) or a two-line layout under a breakpoint so
each cell can reach 44 dp wide, or lift the day row out of the 16 px card
inset. Cross-check SPACING_SPEC §10.3, which assumes ≥44-tall cells.

---

## BUG-05 (minor) — a failed write blanks the whole setup form

**Where:** `pocket_money_bloc.dart:49-77` (write handlers emit
`status: failure`) + `pocket_money_setup_view.dart:57-58` (failure branch
renders `_FailureBody`, replacing the loaded body).

**Repro:** with a write that throws (`setMode`), tap `Weekly amount`: the
option cards, payout day and stepper rows all disappear and are replaced by
the error message + `Retry`, even though `state.setup` is still valid and only
one write failed. The parent loses the form until a later stream emission.

**Failing test:** `P06-BUG-05: a failed write must not blank the setup
controls` (finds 0 × “Weekly amount” after the failed tap).

**Suggested fix:** keep `status: loaded` for write errors and surface a
snackbar/inline error; reserve `_FailureBody` for load failures (or gate the
failure branch on `state.setup == null`).

---

## BUG-06 (minor) — stale `errorMessage` survives recovery

**Where:** `pocket_money_state.dart:23-35` (`copyWith` keeps `errorMessage`
when not passed; the loaded `onData` path never clears it).

**Repro:** let a `setMode` write throw (state `failure`,
`errorMessage: 'Exception: database is locked'`), then let `watchSetup`
re-emit (status back to `loaded`). `bloc.state.errorMessage` is still
`'Exception: database is locked'`. Any UI that renders `errorMessage`
irrespective of status (or a later failure branch) would show a stale error.

**Failing test:** `P06-BUG-06: errorMessage must clear when the setup
recovers` (non-null after recovery).

**Suggested fix:** clear `errorMessage` in the `onData` path
(`emit(state.copyWith(status: loaded, …, errorMessage: null))` via a
sentinel/`Value`-style parameter, since `copyWith` cannot express null today).

---

## BUG-07 (minor) — unknown child id still gets a stepper write

**Where:** `pocket_money_bloc.dart:83` — `?? 0` fallback when `childById`
returns null.

**Repro:** dispatch `PocketMoneyWeeklyBaseStepped('ghost', 50)`; the bloc
writes 50 pence for `ghost` instead of ignoring the event. Not reachable from
the current UI (rows are built from `setup.children`), but any future caller /
stale key hits a silent phantom write (the SQL UPDATE matches 0 rows, so the
visible effect is a failure only if the child reappears — still wrong).

**Failing test:** `P06-BUG-07: a stepper event for an unknown child must not
write` (records `(ghost, 50)`).

**Suggested fix:** `final child = state.setup?.childById(event.childId); if
(child == null) return;`.

---

## Attacks that hold (passing probes, same file, not skipped)

- **Kid-mode guard:** `GetIt → AppModeController.selectMode(kid)` then deep-link
  `/pocket-money-setup` → router redirects to `/parental-gate`; the setup H1 is
  not rendered. No guard bypass (also checked the expired-trial path: it
  redirects to `/paywall` then re-redirects through the kid gate).
- **Restart persistence (file-backed Drift):** mode `weekly`, payout day 2 and
  Maya £4.50 survive `db.close()` + reopen; children still come back in
  insertion order `[maya, leo]`.
- **6 children incl. “Maximilian-Alexander” at 320 dp × text scale 1.3:** no
  overflow, no exception, name ellipsized, insertion order kept (Maya first).
- **0 children (Seed.empty) at 320 dp × 1.3:** the `Add children to set weekly
  amounts.` caption renders; no £0.00 rows; no overflow.
- **£0.00 / £20.00 via the real repository:** render exactly, no rounding
  artifact (also brute-forced `(p/100).toStringAsFixed(2)` against exact pence
  formatting for **every pence value 0…2000** — zero mismatches).
- **Async gap / emit after close:** with a write pending, close the bloc and
  only then fail the write — `bloc.close()` completes and the late `emit` is a
  contained no-op (bloc 9 cancels the emitter), no `StateError`/unhandled
  exception.
- **Dark + light contrast:** P06’s text pairs (`ink`/`ink2` on `surface`,
  `ink2` on `leafTint`, `leafInk` on `leafTint`, `ink2` on `paper`) all pass
  WCAG 4.5:1 in both themes.
- **Widget-level quick taps:** two immediate `tester.tap`s on the real screen
  do land (`£4.00`), because the test crosses DB/stream turns between pointers
  — documented so the timing dependence of BUG-01 is explicit.

## Hunted and found clean / not applicable

- **One child:** row loop is child-count independent (demo path covers 2, the
  probe covers 6; no per-index assumptions).
- **£999.99 / 9999 coins:** unreachable on P06 — the repository clamps writes
  to 0…2000 pence by design (`pocket_money_repository_impl.dart:164`), and the
  screen renders no coin balance (the “Coin value” row is display-only from
  `coinValuePencePerCoin`, seed 1). No finding.
- **Empty lists:** covered above and by the existing suite.
- **Timezone / BST:** P06 stores a weekday index (1–7, DB `payout_day`) with no
  time-of-day or period math, and writes `updatedAt` as UTC + `updatedAtTz` —
  no DST-sensitive path on this screen. Not applicable.
- **Back navigation / deep link in parent mode:** `/add-children` back and
  `/paywall` continue are covered by the existing view suite; deep link loads
  the screen in both light and dark.

## Verdict rationale

One MAJOR defect stands: **P06-BUG-01** — a stepper tap can be silently lost,
so the saved weekly base may not match what the parent entered. Per the stage
rule (“PASS only if no major bugs”), the stage fails; BUG-02/03 share the same
stale-state class and should be fixed together. No files were changed outside
`app/test/features/pocket_money/p06_bugs_test.dart` and this report; the
temporary probe files were deleted.

VERDICT: FAIL
