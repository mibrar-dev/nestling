# P06 Pocket money setup — Stage 6 adversarial bug hunt (iteration 7)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding
(P05 → P06 → P07). All `ORCHESTRATOR_NOTES.md` items (04:05, 07:22, 07:58,
09:30, 09:42) are verified below. No screen code was changed by this stage —
only `app/test/features/pocket_money/p06_bugs_test.dart` and this report.

Suite state: `flutter test test/features/pocket_money/p06_bugs_test.dart` →
**+31, no skips: All tests passed!** (the five stable feature files together,
including this one, run `+87` in ~3 s).

## Open bugs

**None.**

## Iteration-7 targets — verified

| Target | Independent verification |
|---|---|
| ACCESSIBILITY ACTIONS on `_PocketOptionCard` / `_DayCell` (09:42) | new guard `every feature-owned control exposes SemanticsAction.tap`: all **3 cards + 7 days + 4 steppers** report `hasAction(tap)`; `performAction(tap)` on the `Earn per quest` card, the Sun cell and Maya's `+` moves the UI *and* the DB (`mode=per_quest`, `payoutDay=7`, `maya=350 p`) |
| Coin value right-aligned to the card content edge (09:30) | new guard: the `10 coins = 10p` box right edge equals `card.right − s4` **exactly** at 390, 320, 320 × 1.3 and 430 |
| Coin-value row at 320 × 1.3 (review #1 / P06-BUG-13) | label now wraps (`maxLines: 2`, no truncation — the unskipped P06-BUG-13 guard is green); only the trailing value may ellipsize, the plan-sanctioned text |
| Canonical child order (review #4, `watchChildren` now `createdAt, rowid`) | the 6-children guard now pins the rendered order end-to-end: Maya → Leo → Maximilian-Alexander → Noah → Ava → Ethan |
| Radio semantics (review #6), `_FailureBody` message (review #5), `_RadioDot` size token (review #8) | spot-checked in the view; previous guards stay green |

## Earlier findings — all still green (31 unskipped guards)

`P06-BUG-01/01b/01c` (stepper chains), `02/02b` (day guard), `03` (pill 32 px),
`05` (inline write error), `06` (stale message), `07` (unknown child),
`08` (day-row alignment), `09` (pending-day confirmation), `11` (two-line
balanced H1 + break after “How does pocket money”), `12` (stepper minus
U+2212 + plus), `13` (coin-label wrap). Plus the real-font geometry guard
(light + dark; H1 107/68, card 415/270, pills 455/32, coin row 640), the
retitle-anchored 07:58 offsets, and the attack holds (kid-mode guard, restart
persistence, 6 children at 320 × 1.3, £0.00/£20.00, async gap, WCAG 4.5:1).

## Notes, not bugs

- **Shared tap-action fix not in this branch yet.** `shared/semantics_tap`
  (`191be8f`: `NestButton`/`NestChip` expose `SemanticsAction.tap`) is on main
  but `git merge-base --is-ancestor 191be8f HEAD` is false — this branch last
  merged main at `c20e368`. Per the 09:42 note that gap is shared and must not
  fail P06; `Continue`/`Back` pick up the action with the next main merge.
  (The screen's own controls are covered by the new guard above.)
- `P06WeeklyStepper` and `_DayPill` remain feature-private copies pending
  `SHARED_REQUEST.md` items 4/5 (shared glyph override and chip day variant).
- `Add children to set weekly amounts.` (renders only under
  `Seed.empty`/`Seed.fresh`) still awaits orchestrator ratification.
- Method note for future stages: awaiting a **fresh** Drift stream
  (`repository.watchSetup().first`) inside a `testWidgets` body hangs on the
  fake clock — read the DB through `tester.runAsync` instead. The first draft
  of the `performAction` test hit this; the shipped version uses UI state plus
  `runAsync` and completes in seconds.

## Verdict rationale

Every mandatory note is independently reproduced with tests, the whole
previous guard set is green, and no defect with a repro is open. The only
outstanding items belong to the shared track or the orchestrator's copy
ratification, which the rules explicitly say are not P06 findings.

VERDICT: PASS
