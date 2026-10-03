# P11 · Approvals — bug hunt (Stage 6, iteration 2)

Route `/approvals` · feature `approvals` · parent mode · seeds `Seed.demo()`
(3 pending: two with a child note, one NULL) and `Seed.empty()` (0) · tests
pinned to Sat 3 Oct 2026 by `test/flutter_test_config.dart`. Tree tested:
iteration-2 checkpoint `f2eb632`, including the merged shared
`completion_note` (`completions.kid_note`, schema v6, `b2bc5b1`/`8d23049`).
`ORCHESTRATOR_NOTES.md` (15:31/15:38) re-verified item by item below.

**Result: the two iteration-1 majors and both minors are FIXED, each guarded by
an un-skipped green proof; this iteration's adversarial probes found nothing
new.** The feature suite is fully green at the tested checkpoint
(**131 passed, 0 failed, 0 skipped** — the one repo-wide `skip:` is P12's
pre-existing test, untouched; see Gates for the live-tree note). The
concurrent iteration-2 UI check (`5_ui.md`) corroborates the orchestrator
items visually: card 1 with its quote is exactly 172 high at top 187, the
"Approve all" pill is exactly 734–785, and the mean diff halved to
6.39% / 5.55%. No screen code was changed by this stage; `p11_bugs_test.dart`
needed no new proof (its header was updated to say the nine proofs are now
green regression guards).

| Id | Status | Fix / evidence |
|---|---|---|
| BUG-P11-1 | **FIXED** | compare-and-set inside one transaction in `approve()` + guarded `markNotYet()` + bloc absorb (`busyIds`, `_decided`); all 4 proofs green |
| BUG-P11-2 | **FIXED** | guarded `UPDATE … WHERE status = 'done_pending'`; same-frame absorb; both proofs green |
| BUG-P11-3 | **FIXED** | date-only diff built with `DateTime.utc` (no host DST); both proofs green |
| BUG-P11-4 | **FIXED** | per-button `loading` from the card's pressed decision; proof green |

## What fixed each bug

- **BUG-P11-1.** `approvals_repository_impl.dart:63-106`: the claim
  (`UPDATE … status = 'approved' WHERE status = 'done_pending'`) and the
  `quest_bonus` insert are now one transaction; a lost claim updates 0 rows
  and returns before the ledger. `approvals_bloc.dart:64,96,127` adds the
  same-frame absorb (`busyIds` guard + `_decided` id set + `approveAllBusy`),
  and `_decided` is pruned when the row leaves the inbox (`:42`).
- **BUG-P11-2.** `approvals_repository_impl.dart:109-125`: the `not_yet`
  write only matches `done_pending` rows, so a racing/stale "Not yet" is a
  no-op and the status can never disagree with the ledger.
- **BUG-P11-3.** `approval_time.dart:41-43`: both date-only values use
  `DateTime.utc(y, m, d)`, so the day count is always whole days.
- **BUG-P11-4.** `approval_card.dart:99-104,218,231`: the card records which
  button was pressed and spins only that pill.

## Adversarial probes this iteration (all clean)

Every probe below was run on `f2eb632`; the observed values are from the
probe output, and none needed a failing proof.

| # | Probe | Result |
|---|---|---|
| 1 | 300-char child note, 320 px wide, textScale 1.3 | no overflow exception; card grows and scrolls (1038 high) |
| 2 | note `'   '` / `''` / `null` | no quote line, no gap — all three cards exactly 138.0 high |
| 3 | same-frame double "Not yet" (real DB) | `status = not_yet`, **0** new `quest_bonus` rows |
| 4 | same-frame double "Approve" and double "Approve all" | the iteration-1 proofs now pass: 1 call, total 330p (was 2 calls / 345p) |
| 5 | two cards busy at once (gated stub) | each card spins only its tapped pill (`approve.loading` XOR `notYet.loading`); 1 call each |
| 6 | `Future.wait([approveAll(), approve(table), markNotYet(dishwasher)])` | statuses `1:not_yet, 2:approved, 3:approved`; bonus total **315 = 300 + 15** — exactly one credit per approved row, none for not_yet |
| 7 | `Future.wait([approve(dishwasher), approveAll()])` | 12 bonus rows / 330p — the shared row is credited once |
| 8 | quote font (see item 1 below) | HTML inherits Inter; my own PNG ink measurement 246.67 logical matches Inter, not Nunito |
| 9 | geometry (existing real-font tests) | quoted 172 / NULL 138 / quoted 172 at tops 187 / 375 / 529; CTA pill 734–786, centre 760 under a 34 px inset; surface to the edge |

## Orchestrator-mandated items (all accounted for)

1. **Child quotes from `kid_note` — DONE.** `QuestCompletion.kidNote` is
   mapped through `Approval.kidNote` (`approvals_repository_impl.dart:56`,
   entity `:44`, in `props` `:60`) and rendered as `“$kidNote”`
   (U+201C … U+201D) in `17/24` w700 at `margin-top: 10`
   (`approval_card.dart:194-205`); NULL/blank renders nothing and no gap. The
   note's "(Nunito" parenthetical is contradicted by the HTML itself:
   `tokens.css:203 body { font-family: var(--font-ui) }` (Inter) and `.qn`
   sets no family; my independent measure of the light PNG quote ink is
   x 37.33–284.0 logical, width **246.67**, which matches Inter w700 @17
   (advance 249.2 ≈ 247 ink) and not Nunito @17 (232.4). Rendered Inter per
   the HTML; flagging in case the orchestrator still wants Nunito.
2. **Pending set from the DB — confirmed**, no change (Maya dishwasher 8:12 /
   Maya table 8:05 / Leo bed 7:58; `q-table` has no note, so the seeded inbox
   is 172/138/172).
3. **"Approve all (N)" position — DONE on this screen.** `ApprovalsBottomCta`
   pads `homeInset + s6` and keeps `surface` to the physical edge: 734–786 /
   centre 760 at the design's 34 px home inset (zero-inset: 24 above the
   edge). Shared `NestBottomCta` remains 8 px low for other screens —
   `SHARED_REQUEST.md` §3 carries the numbers and the requested pad. The
   local stopgap is tokens-only and documents its swap-back; flagged as an
   integrator cleanup, not a bug.
4. **Card geometry with and without a quote — DONE.** Real-font geometry test
   pins 172 (quote) and 138 (NULL) with tops 187 / 375 / 529, and `.qn`
   internals (top +70, height 24) plus the bare-card row at +74.

## Open items carried (not this stage's findings)

The iteration-1 review's minor items (error copy, toast vs the shared
`NestToast` and its bottom margin, stale test comment, grapheme-cluster avatar
initial, duplicated pending predicate in `approveAll`, geometry-header doc)
are unchanged and belong to the iteration-2 review stage; none is a major bug
and none affects the money paths this stage guards.

## Gates (run in this worktree, `app/`, at the tested checkpoint `f2eb632`)

```
$ dart format --output=none --set-exit-if-changed test/features/approvals
Formatted 8 files (0 changed) in 0.03 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.5s)

$ flutter test test/features/approvals
00:02 +131: All tests passed!

$ flutter test
00:48 +2267 ~1: All tests passed!   # the ~1 is P12's pre-existing skip
```

Re-run on the live tree during this stage (no `lib/` change since the
checkpoint):

```
$ flutter test test/features/approvals/p11_bugs_test.dart
00:01 +9: All tests passed!        # all nine proofs, un-skipped
```

Live-tree note (not a P11 product bug): while this stage ran, the TEST stage
was still writing new "decision absorb" probes into
`approvals_bloc_paths_test.dart` (mtime still moving at 17:08). Two of its
in-progress asserts currently fail on mocktail's verify-consumption semantics
(a first `verify` marks the call `[VERIFIED]`, so a later `verify(...).called(n)`
counts only unverified calls), not on the bloc: the absorb/release behaviour
they probe is correct (the repeat-after-write-out is absorbed; the
release-on-leave re-approve reaches the repository). Left to that stage.

No simulator was booted, installed on, screenshotted or driven in this stage
(UI-check stage only).

VERDICT: PASS
