# P13 · Payout (parent) — Stage 6 bug hunt (iteration 2)

Route `/payout` (feature `pocket_money`), build `bf9f239` ("P13: checkpoint
after build (iteration 2)"). This pass re-audits the iteration-2 fixes
(ORCHESTRATOR_NOTES items 1–3, P13-BUG-01…05, review findings 1–10) and hunts
for new defects in the changed code.

Method: every iteration-1 reproducer was re-run **unskipped** against the
iteration-2 build; then fresh probes exercised the new non-reentrant submit /
retry / partial-failure logic, the busy CTA, the full-screen scrim (light and
dark, plus its semantics), the inline 13 px amount, the saverow copy paths and
the restart/edge cases. **No simulator was used** (stage rule; only stage
5_ui may). No screen code was edited (stage rule) — the changes live in
`app/test/features/pocket_money/p13_bugs_test.dart`.

Guards: `p13_bugs_test.dart` — **20 tests (19 active, 1 skipped
reproducer)**. The 5 iteration-1 reproducers are now active regression tests
(the fixers promoted them once the fixes landed); the one new finding keeps a
`skip: true // P13-BUG-06` reproducer so the suite stays green. Every probe in
this stage was run against the real iteration-2 build and behaves exactly as
recorded below.

**VERDICT: PASS — no major bugs. One new minor finding (P13-BUG-06, open).**

---

## Findings status

| # | Sev | Status | Where / verified by |
|---|---|---|---|
| P13-BUG-01 | major | **FIXED** (it 2) | non-reentrant `_submit` + per-child `_payoutInFlight` in the bloc + `busy` CTA; active test passes |
| P13-BUG-02 | major | **FIXED** (it 2) | savings move clamped to `min(100 p, owed)`; ticked £0 children skipped; active test passes |
| P13-BUG-03 | major | **FIXED** (it 2) | scrim is a full-screen `Positioned.fill` layer over the dimmed chrome; rect `(0,0,390,844)` in both themes; active test passes |
| P13-BUG-04 | minor | **FIXED** (it 2) | bloc clears `errorMessage` before the write, so a repeated failure re-emits; active test passes |
| P13-BUG-05 | minor | **FIXED** (it 2) | dimmed chrome `ExcludeSemantics`-wrapped; scrim keeps a labelled `'Close payout'` node; active test passes |
| P13-BUG-06 | minor | **OPEN** | `PayoutSaveRow.label` still uses the design's "her" for a goal-bearing Leo when the goal title contains "Lego" |

## Verification of the iteration-1 fixes (fresh runs, all unskipped)

### P13-BUG-01 — double submit (major) — FIXED

- The gated reproducer passes: second tap 80 ms into the write → exactly one
  payout row (−420), one `savings_move` (100), goal **1650** (was 1750).
- New probe, same-frame double tap on the **real** repository:
  `payouts=1 savings=1 goal=1650 path=/money`.
- New probe, sibling still in flight + instant retry after the first child
  failed: `calls=[maya, leo, maya]` → `payouts=[leo:-210, maya:-420]`,
  `savings=[100]`, goal 1650, pops. The bloc's per-child guard drops the
  duplicate sibling event; the view's re-entrancy guard handles same-frame
  taps; the `busy` state disables and spins the CTA (`hasTap=false`, label
  still present, second tap ignored — probe N4).
- The retry path stays reachable: after the failure the listener clears
  `_submitted`, so the CTA re-arms (`P13-BUG-04`'s fix also keeps it
  informed).

### P13-BUG-02 — unclamped savings move (major) — FIXED

- 50p week reproducer passes: payout −50, move **50** (was 100), goal
  1550→1600, goal delta equals the ledger move exactly.
- New probe N9: after Maya is paid (owed £0.00), re-open `/payout`, tick the
  £0.00 Maya next to the £2.10 Leo, submit → **only** `leo:-210`; no
  `savings_move`, no `Paid £0.00` row, goal unchanged (1650). This also
  closes review finding 3 (the zero-owed row).

### P13-BUG-03 — scrim not `inset: 0` (major) — FIXED

- Reproducer passes: the scrim rect is `(0,0,390,844)`; a tap at (195, 60)
  over the title dismisses to `/money`.
- New probe N5 (dark theme): rect `(0,0,390,844)`, top tap pops.
- New probe N11: `find.bySemanticsLabel('Close payout')` has a real tap
  action; `performAction(tap)` lands on `/money` (a11y rule satisfied).
- New probe N12: scrim tap *mid-write* pops cleanly, the write still lands
  exactly once, no exception.
- The chrome (`Pocket money` / summary card) is now inside
  `ExcludeSemantics` — see BUG-05.

### P13-BUG-04 — repeated failure gave no feedback (minor) — FIXED

- Probe N10: two consecutive identical failures each surface one toast
  (`snack=1` after each settle, was 0 on the retry), then the third attempt
  succeeds → `/money`, `calls=[maya, maya, maya]`, one payout, one
  `savings_move`, goal 1650.
- Mechanism: the bloc now emits `clearErrorMessage` before writing whenever a
  stale error is present, so the repeat failure is a state change again; the
  view records `_lastFailure` and re-arms the submit only after a failure it
  actually surfaced.

### P13-BUG-05 — background in the semantics tree (minor) — FIXED

- Reproducer passes: with semantics on, `find.bySemanticsLabel('Pocket
  money')` and the summary-card label find **nothing** while the sheet is
  open; the sheet's header remains reachable; the scrim exposes
  `'Close payout'` with a tap action.

## New finding

### P13-BUG-06 — a goal-bearing Leo still gets the design copy's "her" (minor) — OPEN

**Where:** `app/lib/features/pocket_money/presentation/widgets/payout_sheet.dart`
(`PayoutSaveRow.label` — `title.toLowerCase().contains('lego')` selects the
design string).

**Repro.** Move the family's only goal (`goal-lego`, title "Lego Friends
set") to Leo, open `/payout`. The saverow now belongs to Leo and reads
**"Move £1.00 of Leo's to her Lego fund"** — a male child sent to "her" fund.
There is no gender column in the schema, so any gendered phrasing chosen from
data alone is unsafe.

**Evidence.** Probe N7, reproduced by the skipped test
`P13-BUG-06: a goal-bearing Leo still gets the design copy with "her"` —
measured copy `Move £1.00 of Leo's to her Lego fund`. The test stage
independently found the same defect as its own skipped reproducer
**P13-I2-01** (`p13_iter2_audit_test.dart:311-345`), so the two files pin it
twice. The review finding 7 fix covers a *non-Lego* goal (probe N8: "Move
£1.00 of Maya's money to their Holiday fund") but not a Lego goal held by
anyone other than Maya.

**Suggested fix.** Use the design string only for the exact seeded shape
(goal child Maya **and** title "Lego Friends set"), and the neutral
data-driven form for every other combination:
`"Move £1.00 of $name's money to their $title fund"`. Pin the four cell
combinations (Maya/Leo × Lego/other) in `payout_view_test.dart` or the
geometry test.

## Fresh probes (iteration 2) — all hold

- Same-frame double tap, real repo: one payout, one move, goal 1650, pops.
- Partial batch failure (Maya fails, Leo pays) then retry: first attempt
  stays on `/payout`, only `leo:−210`, no move, goal 1550, one toast; retry
  writes only the still-owing Maya (`calls=[maya, leo, maya]`), goal 1650,
  pops — no duplicates.
- Sibling in flight + instant retry: the bloc's per-child in-flight guard
  drops the duplicate; one row per child.
- Busy CTA: `hasAction(tap)` false, label retained, second tap ignored, no
  dispatch.
- Dark scrim: full-screen rect, top tap dismisses.
- Scrim tap mid-write: pops, write lands once, no exception.
- Inline amount: the amount span is **13 px / w700 / ink-2** (`NestType.money`
  at the `.caption` size), the row stays **76** tall; the updated real-font
  geometry test pins name top 458 / subtitle 480 (±1), Leo 544/566, and the
  scrim `(0,0)` — ORCHESTRATOR_NOTES items 1–3.
- Saverow neutral fallback for a non-Lego goal.
- Scrim semantics `'Close payout'` + `performAction(tap)` → `/money`.
- Iteration-1 held probes still green: six children at a real 320 dp × 1.3,
  real 320×568 scroll, one child, everyone £0.00 (disabled CTA), goal child
  unticked, back mid-write, kid-mode and fresh deep links, initial-route
  scrim dismissal, restart persistence (file-backed), dark/light contrast
  ≥ 4.5:1, integer-pence maths, no BST-sensitive path on this screen.

## Notes (not findings)

- The `pumpAppRoute` 390×844 override (iteration 1) is unchanged and already
  filed as `SHARED_REQUEST.md` by the test stage; the narrow-layout probes in
  `p13_bugs_test.dart` set the size after the first pump so they are real.
- The saverow label promises "£1.00" while the clamped edge case moves less;
  the invariant (never move more than was paid) takes precedence and the
  goal/ledger stay consistent. No money can be created.
- `p13_iter2_audit_test.dart` is the test stage's own iteration-2 audit file,
  left in place; no scratch/probe files remain from this stage.
- Cross-stage: the iteration-2 UI captures (`ui/app_light_2.png`,
  `app_dark_2.png`, compares) are present in the worktree; this stage did not
  read them (UI verdict belongs to stage 5).

## Hand-off state

- `dart format` clean; `flutter analyze` → **No issues found!**
- `flutter test test/features/pocket_money` → **436 passed / 3 skipped /
  0 failed** (skips: the pre-existing P12-BUG-04, this file's P13-BUG-06 and
  the test stage's P13-I2-01 — the same open minor, pinned twice).
- `p13_bugs_test.dart`: 20 tests — 19 active, 1 skipped (P13-BUG-06). The
  five iteration-1 reproducers are active regression tests.
- Build under test: `bf9f239` (iteration 2 checkpoint). Fix P13-BUG-06 (one
  small copy gate) and unskip both its reproducers; then this stage has no
  open findings.
- Environment note (not a finding): two earlier full-suite runs reported
  transient failures while concurrent stages were writing scratch files in
  the same worktree (`_unskip_probe_test.dart` failed to load, then
  vanished); every named test passes on its own and the final clean run is
  the 436/3/0 above.

VERDICT: PASS
