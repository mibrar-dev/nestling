# P13 · Payout (parent) — Stage 6 bug hunt (iteration 1)

Route `/payout` (feature `pocket_money`), build `c34904b` ("P13: checkpoint
after build (iteration 1)"). First adversarial pass over the shipped screen.

Method: widget and pure probes on the in-memory and file-backed Drift
databases, plus a **gated repository** that holds `recordPayout` mid-flight so
the double-tap race is deterministic instead of timing-dependent, a semantics
tree audit, and a restart persistence round-trip. **No simulator was used**
(stage rule; only stage 5_ui may). No screen code was edited (stage rule).

Guards: `app/test/features/pocket_money/p13_bugs_test.dart` — 17 tests
(12 active "attacks that hold" probes, 5 skipped reproducers, one per
finding). During the hunt every skipped test was run unskipped and fails
exactly as recorded below (12 passed / 5 failed); the quiet suite is green.

**VERDICT: FAIL — three open major findings (P13-BUG-01/02/03).**

Stages 4 (code review) and 5 (UI check) ran in parallel with this hunt and
independently reached the same majors: review #1 / UI deviation 1 = this
file's BUG-03 (scrim not `inset: 0`, UI measured +152 px), review #2 =
BUG-01 (double submit). Review #3 (a ticked £0.00 child still writes a
`Paid · <date> £0.00` row) shares its view-side root with BUG-02 here
(`_submit` dispatches for every ticked child without an owed guard); the two
should be fixed together. The review's finding 4 was the leftover
`zz_probe_test.dart` scratch file — it has been deleted (see the test-suite
note) so the loop cannot commit it or stall the suite.

---

## Findings

| # | Severity | Status | Failing test (skipped in the suite) |
|---|---|---|---|
| P13-BUG-01 | major | OPEN | `P13-BUG-01: a second tap while the payout write is in flight double-writes the payout, the savings move and the goal bump` |
| P13-BUG-02 | major | OPEN | `P13-BUG-02: the £1.00 savings move is not clamped to the amount paid` |
| P13-BUG-03 | major | OPEN | `P13-BUG-03: the scrim is not inset 0 — the P12 backdrop stays lit and the top of the screen does not dismiss the sheet` |
| P13-BUG-04 | minor | OPEN | `P13-BUG-04: a repeated identical write failure gives the parent no feedback at all` |
| P13-BUG-05 | minor | OPEN | `P13-BUG-05: the ledger behind the modal stays in the semantics tree` |

### P13-BUG-01 — a fast second tap double-writes the payout (major)

**Repro.** Open `/money` → "Payout time". Tap "Mark as paid & start the
celebration", then tap it again while the first write is still in flight
(80 ms later in the test; a real Drift round trip on device is longer).
The sheet shows no in-flight state — the CTA stays enabled and unchanged, so
nothing discourages the second tap.

**Evidence.** With the write gated, the second tap dispatches a second
`PocketMoneyPayoutSubmitted`. Result: `attempted = 2`; **two `payout` rows**
(−420 each), **two `savings_move` rows** (100 each) and the Lego goal at
**1750 instead of 1650** — a £2.00 move recorded for a £1.00 option, plus a
duplicate "Paid" row in the child's ledger. (Probe also confirmed the simpler
same-frame double tap gives the same state.)

**Suggested fix.** Make the submit non-reentrant: `if (_submitted.isNotEmpty)
return;` at the top of `_submit`, and pass a `submitting` flag into
`PayoutSheet` so the CTA disables (and, ideally, the checks/toggle are inert)
until the stream proof or a failure clears it. The failure path already
clears `_submitted`, so retries stay possible. A per-child idempotency key in
`recordPayout` would be belt-and-braces, but the view guard is the minimal
fix.

### P13-BUG-02 — the £1.00 savings move is not clamped to the payout (major)

**Repro.** A small week for the family: Maya is owed exactly **£0.50** (one
50p weekly-base row, everything before the last payout). Open `/payout`; Maya
is ticked by default and the saverow is ON by default. Tap "Mark as paid".

**Evidence.** Payout row **−50**, `savings_move` row **+100**, goal
**1550 → 1650**. £1.00 moved to savings on a £0.50 payout — the extra 50p
never existed in the child's jar (the jar's balance *is* "owed since the last
payout"). The same root hits the ticked-£0-child case: after a partial payout
a parent can tick a child who owes £0.00 next to a paying sibling and the
screen writes a −0 payout row **plus a £1.00 move** for that child.

**Suggested fix.** Clamp the move to the money actually being paid:
`savingsMovePence = min(PayoutSheet.savingsMovePence, owed)` (and skip the
move when `owed == 0`), or hide/disable the saverow while the goal child's
owed is below £1.00. `recordPayout` already bumps the goal by the value the
view passes, so the clamped value is the single source.

### P13-BUG-03 — the scrim is not `inset: 0` (major)

**Repro.** Open `/payout` from `/money`. Compare with either design PNG:
the whole backdrop (status-bar reserve, "Pocket money" title, "… is owed"
summary card) is behind the darkened scrim in the design, and
`docs/design/SPACING_SPEC.md` §5 defines `.scrim → absolute inset 0`. In the
app the scrim only paints the `Expanded` area *below* the summary card.

**Evidence.** The scrim rect measures **(0, 169, 390, 844)** (169 is the card
bottom in the test's unloaded-font metrics; ≈151 with the bundled fonts), so
the top band is undimmed. A tap over the title — inside the scrim in the
design and in `1_plan.md` §a (`Positioned.fill → Container(color: scrim);
tap = pop`) — does **not** dismiss the sheet (path stays `/payout`).

**Suggested fix.** Put the scrim in its own full-screen stack layer between
the ledger and the sheet: `Stack[Positioned.fill(ledger),
Positioned.fill(GestureDetector(scrim)), Align(sheet)]`, or wrap the ledger
content in the scrim while keeping a full-screen dismiss gesture. Do not grow
the existing `Expanded` scrim — it inherits the card's bottom edge.

### P13-BUG-04 — a repeated identical write failure gives no feedback (minor)

**Repro.** Force `recordPayout` to fail with the same error twice.
Tap "Mark as paid": the failure toast appears. Let it expire, tap again
(same failure): **nothing happens** — no toast, no state change, and
`_submitted` stays armed.

**Evidence.** The bloc's error path emits `copyWith(errorMessage: …)`; the
second identical message produces an **equal state, which Bloc suppresses**,
so the view's `listenWhen` (`previous.errorMessage != current.errorMessage`)
never fires. The failing test asserts a new `SnackBar` after the retry;
measured `0`.

**Suggested fix.** Give the retry a visible outcome: clear `errorMessage`
before the write (`emit(state.copyWith(clearErrorMessage: true))` ahead of
the `recordPayout` await) so a repeat failure is a state change again, or
have the view surface the retry directly (toast on tap once an error is
already on screen). Keep the in-flight guard from BUG-01 in mind: the guard
must clear on failure so this retry path stays reachable.

### P13-BUG-05 — the dimmed ledger stays in the semantics tree (minor)

**Repro.** Enable a screen reader, open `/payout`, swipe back from the sheet.

**Evidence.** With semantics enabled, `find.bySemanticsLabel('Pocket money')`
and `find.bySemanticsLabel('Maya is owed £4.20 · Leo is owed £2.10')` each
match a node *behind* the modal. `1_plan.md` §e requires the summary card
(and the whole dimmed backdrop) to be `ExcludeSemantics`, and
`_DimmedLedger`'s own doc comment claims it is — the build method never wraps
the column.

**Suggested fix.** Wrap the non-sheet subtree in `ExcludeSemantics` (the
title/card are not actionable). If the scrim's tap-to-dismiss should stay
announced, keep a separate semantics node with `onTap` outside the excluded
subtree; otherwise the system back gesture remains the accessible dismiss.

---

## Attacks that hold (active tests — no finding)

- **Gated single write**: one tap → one payout row (−420), one `savings_move`
  (100), goal 1650, pop to `/money`, toast
  `Payout recorded — enjoy the celebration`, no exception. (Positive control
  for BUG-01.)
- **Real 320 dp × text scale 1.3 with six children and
  "Maximilian-Alexander"**: rows in creation order (Maya, Leo, then the
  added four), no overflow exception, the sheet scrolls and the CTA is
  operable; one payout row lands (−420). NOTE: the width is set *after* the
  first pump because `pumpAppRoute` forces 390×844 (see the test-suite note).
- **Real 320×568**: the sheet scrolls to the CTA, the tap lands and the
  screen returns to `/money`; no exception.
- **Goal child unticked / sibling paid**: only `leo:−210` is written, no
  `savings_move`, goal stays 1550.
- **Everyone at £0.00**: two `Weekly + quests · £0.00` rows render and the
  CTA reports `enabled: false` with no tap action.
- **One-child family**: one row, no stale Leo copy, no exception.
- **Deep links**: kid mode `/payout` → `/parental-gate` (guard intact);
  fresh/never-onboarded `/payout` → `/welcome`; launched at `/payout` with
  nothing to pop, the scrim tap still reaches `/money` via `_goBack`.
- **System back mid-write**: no exception, exactly one payout row lands (the
  tap was already committed before the pop).
- **Restart persistence (file-backed)**: payout row, `savings_move` and the
  1550 → 1650 goal bump all survive a close/reopen; owed back to 0.
- **Dark/light contrast**: `ink/ink2` on `surface`/`paper` and
  `onLeaf/leaf` all ≥ 4.5:1 in both themes.
- **Money maths**: every P13 amount is an integer-pence value read from the
  ledger (`owedFor().totalPence`); no float parsing/rounding exists on this
  screen. The only money defect is BUG-02's *unclamped* move, not rounding.
- **Timezone/BST**: the sheet title is the `families.payout_day` integer
  (`kPayoutWeekdayNames[day − 1]`); no date arithmetic runs in P13, so there
  is no BST-sensitive path here. The repository's `formatDay(now, zone)` note
  is covered by the existing P06/P12 timezone tests.

## Test-suite note (not a screen bug)

`test_scope.pumpAppRoute` unconditionally sets `physicalSize = 390×844`, so
`payout_view_test.dart`'s "320 px" cases (`_pumpPayout(size: Size(320, …))`)
and its "short screen" case in fact run at **390×844** — the size is
overwritten before the first frame. The new bugs file sets the width after
the first pump so its 320 dp probes are real. Suggested follow-up (allowed
paths): give `pumpAppRoute` an optional `size` parameter, or set the size
post-pump in the responsive tests.

Worktree hygiene: the review stage's `zz_probe_test.dart` (untracked,
breaking `flutter analyze` and stalling the runner) was deleted in this
stage; its £0.00-row finding is carried by review #3 and by BUG-02 above, so
no coverage is lost. The quiet suite now contains only committed test files.

## How to reproduce the skipped failures

```bash
cd app
# the green suite (5 skips):
flutter test test/features/pocket_money/p13_bugs_test.dart
# prove the five findings (12 pass / 5 fail) — unskip a temp copy:
sed 's/^    skip: true, \/\/ P13-BUG-/    \/\/ skip: true, \/\/ P13-BUG-/' \
  test/features/pocket_money/p13_bugs_test.dart \
  > test/features/pocket_money/_unskip_test.dart
flutter test test/features/pocket_money/_unskip_test.dart   # 5 failures
rm test/features/pocket_money/_unskip_test.dart
```

## Hand-off state

- `dart format` clean; `flutter analyze` → **No issues found!**
- `flutter test test/features/pocket_money` → **366 passed / 6 skipped /
  0 failed** (the 5 reproducers above + the pre-existing P12-BUG-04 skip).
- `app/test/features/pocket_money/p13_bugs_test.dart`: 17 tests — 12 active,
  5 skipped reproducers. No product or shared code was touched; only the
  feature test path and `docs/screens/P13/**` (plus the stray scratch file
  removal above).
- Build under test: `c34904b` (iteration 1 checkpoint). Re-run the skipped
  tests after the iteration-2 fixes and unskip the ones that pass (P12's
  `p12_bugs_test.dart` is the precedent for retiring fixed findings).

VERDICT: FAIL
