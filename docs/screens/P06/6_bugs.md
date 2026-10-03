# P06 Pocket money setup — Stage 6 adversarial bug hunt (iteration 3)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding
(P05 → P06 → P07). No `ORCHESTRATOR_NOTES.md`. No Pip on this screen. This
stage changed no screen code — only `app/test/features/pocket_money/
p06_bugs_test.dart` and this report.

Method: re-run every iteration-2 repro against the iteration-3 build, rewrite
the one proof whose subject was replaced (BUG-03's `FittedBox`/`NestChip` is
gone), then attack the new fix code. The seven iteration-2 bugs are now
UNskipped regression guards; the two new findings are kept `skip: true` with
their ids in the test names.

Unskipped run evidence (delete the two `skip:` flags to reproduce):

```text
00:03 +9 -1  P06-BUG-08  Expected: 36.0 (±1.0)   Actual: <22.0>
00:03 +9 -2  P06-BUG-09  Expected: [7, 6]        Actual: [7]
00:04 +17 -2  Some tests failed.
```

Default suite (skips in place): `flutter test test/features/pocket_money/
p06_bugs_test.dart` → `+17 ~2: All tests passed!`; full feature dir green;
`flutter analyze` → No issues found.

## Iteration-2 bugs — all fixed, independently re-verified

| # | Was | Fix (iteration 3) | Guard now green |
|---|---|---|---|
| 01 | **MAJOR** stepper lost rapid taps | `_requestedBase` accumulates each tap on the previous *request* (synchronous, pre-await) and the write is confirmed locally via `withChildBase` — `pocket_money_bloc.dart:28-35,113-160` | `P06-BUG-01 (fixed)` real repo 350→400; new **01b** three taps → 450; **01c** `+` then `−` → 300 |
| 02 | minor fast Sun→Sat dropped | guard compares against `_pendingDay`, the last *requested* day — `bloc:21-26,90-111` | `P06-BUG-02 (fixed)` → 6 |
| 03 | minor pill painted ~19dp | `NestChip`+`FittedBox` replaced by the token-built `_DayPill` (32dp pill, 13/18 w600 label, fills the cell) — `view:604-644` | **rewritten** `P06-BUG-03 (fixed)` measures the pill itself → 32 ± 2 and label 13px |
| 04 | minor day cells 40.3dp wide | `cellWidth = max(44, (available−6·gap6)/7)`, breakout inset, horizontal scroll below the 44dp width — `view:489-562` | `P06-BUG-04 (fixed)` → all 7 cells ≥44 at 390 **and** 320 |
| 05 | minor failed write blanked form | failure branch keeps `_LoadedBody` with an inline danger caption when `setup != null`; `_FailureBody`/Retry only for load failures — `view:59-72,199-231` | `P06-BUG-05 (fixed)` options + inline `database is locked`, no Retry |
| 06 | minor stale `errorMessage` | `copyWith(clearErrorMessage:)`; every load emission clears it — `state:29-40`, `bloc:60-65` | `P06-BUG-06 (fixed)` → null after recovery |
| 07 | minor unknown-child write | `childById` null → early return before any repository call — `bloc:117-120` | `P06-BUG-07 (fixed)` → no writes |

Note on BUG-03: the build left the old skip in place because the old finder
expected `NestChip`; the visual defect is fixed, so this stage rewrote the
proof to measure `_DayPill` and un-skipped it. The `NestChip` compact/day
variant is still a valid `SHARED_REQUEST.md` item (code hygiene, not a bug) —
closing it would retire the feature-private pill, not change what the user sees.

## New findings (iteration 3)

### P06-BUG-08 (minor, needs owner arbitration) — day row breaks out of the card's 16px inset

**Where:** `pocket_money_setup_view.dart:437-440` — `_DayRow` sits on a
`gap2` (2px) inset so each of the 7 cells can be ≥44dp wide; the label above
it still uses the card's 16px inset.

**Repro / measurement:** at 390 the first day cell's left edge is x=22.0 while
`Payout day` (and `Weekly base`, the avatar and coin tile) start at x=36.0 —
a 14px offset; the row spans 346px vs the design's 318px, so the pills sit
2px from the card border instead of 16px. Confirmed visually against the
design PNG (`docs/screens/P06/ui/cmp_light_3.png`: app chips run visibly
closer to both card edges than the design's).

**Failing test:** `P06-BUG-08: day chips must align with the card section
labels` (22.0 vs 36.0, skipped).

**Assessment:** deliberate and documented — the trade-off buys the ≥44dp
target that DESIGN_SPEC §0.9 asks for, and the UI builder pinned the new inset
in `pocket_money_setup_view_test.dart` (“the day row breaks out of the 16px
card inset to gap2”). It is symmetric, functional and inside the card, so this
stage rates it minor. The owner ALIGNMENT rule (“nothing a few px off … treat
visible misalignment as a UI failure”) may rank it higher; owner options:
(a) sanction the breakout for the larger tap target, or (b) restore the 16px
inset and scroll the row at every width (design-inherent 40.3dp cells return,
and the ≥44 width fix is dropped), or (c) two-line day grid under a breakpoint.

### P06-BUG-09 (minor) — a day correction is dropped when an unrelated re-emission lands mid-write

**Where:** `pocket_money_bloc.dart:53` — the load `onData` clears `_pendingDay`
on **every** emission (“the stream has caught up”), but an emission can arrive
while the day write is still in flight and still carry the old day.

**Repro (deterministic, fake repo with a held write):**
1. load (`payoutDay` 6); tap **Sun** → `_pendingDay = 7`, write in flight;
2. an unrelated emission arrives (ledger/children/another screen) still
   reporting day 6 → `_pendingDay` cleared, state shows Sat selected again;
3. the parent taps **Sat** to correct → guard compares 6 == 6 → no-op, tap lost;
4. the Sun write lands → stored day flips to **7** although the last tap was Sat.

**Failing test:** `P06-BUG-09: a day correction must survive an unrelated
re-emission` — expected day writes `[7, 6]`, observed `[7]` (skipped).

**Severity:** minor — needs an external/parallel write inside the few-ms write
window, but it is the same class as the fixed P06-BUG-02 and the same
incoming-day-versus-emitted-day confusion. **Suggested fix:** clear
`_pendingDay` only when the emitted `setup.payoutDay == _pendingDay` (the same
confirmation rule `_requestedBase` already uses), not unconditionally.

## Attacks that hold (passing probes, kept in the same file)

- **Fix guards:** every iteration-2 bug above, plus 3× `+` → £4.50 and quick
  `+`/`−` → £3.00 on the real repository (the new `_requestedBase` chain).
- **Kid-mode guard:** deep link `/pocket-money-setup` in kid mode →
  `/parental-gate`; expired-trial path re-redirects through the gate too.
- **Restart persistence (file-backed Drift):** mode/day/base survive
  `db.close()` + reopen; children stay in insertion order `[maya, leo]`.
- **6 children incl. “Maximilian-Alexander” at 320dp × 1.3:** no overflow, no
  exception, ellipsised, Maya first.
- **0 children at 320dp × 1.3:** `Add children to set weekly amounts.` renders,
  no fake £ rows, no overflow.
- **£0.00 / £20.00:** render exactly; `(p/100).toStringAsFixed(2)` brute-forced
  against exact pence formatting for **every value 0…2000** — zero mismatches.
- **Async gap:** closing the bloc with a write pending and failing the write
  afterwards completes cleanly (late `emit` is a cancelled-emitter no-op).
- **Contrast:** P06's text pairs pass WCAG 4.5:1 in light and dark.
- **Day row interaction:** at 320 the row scrolls and Sun can be dragged into
  view and tapped (UI suite's `day row geometry` group is green).

## Hunted, found clean / not applicable

- **1 child / 6 children / empty lists:** child-count-independent row loop;
  demo covers 2, probes cover 0 and 6.
- **£999.99 / 9999 coins:** unreachable on P06 — writes clamp to 0…2000p by
  design and the screen shows no coin balance (coin row is display-only).
- **Timezone / BST:** weekday index only, no time-of-day or period math;
  `updatedAt` is UTC + zone-tagged. Not applicable.
- **Back navigation / deep links in parent mode:** `/add-children` and
  `/paywall` covered by the feature suite; deep link renders light + dark.

## Verdict rationale

All seven iteration-2 bugs are independently confirmed fixed (17 green guards,
including three new rapid-tap chains). Two new findings remain: P06-BUG-08
(day-row inset, deliberate trade-off — owner arbitration suggested) and
P06-BUG-09 (narrow pending-day race, one-line fix suggested). Both are minor
and both have executable skipped repros. No major bug is open, so the stage
passes.

VERDICT: PASS
