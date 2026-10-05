# K10 · Payout day — 2 INTEGRATE (iteration 2)

Combined result of `2a_build_logic.md` (logic, iteration 2) + `2b_build_ui.md`
(UI, iteration 2). Stage scope: integration breakage only — no redesign, no
contract change, no shared file touched, no simulator booted or driven.

**No integration edit was required this iteration.** The only file I touched
was `docs/screens/K10/2_build.md` itself; `dart format` reported 0 changed and
`flutter analyze` was clean on the first run, so neither half left a mismatch
for the other.

## Summary of the two halves (iteration 2)

**2a (logic) — FIXES_1 logic items.** No contract changes (event/state/entity
shapes identical to what 2b coded against):

- K10-BUG-2: `PayoutCelebration.goalPercent` is now
  `(goalFraction * 100).round()` off the clamped fraction (K09 `JarGoalCard.percent`
  precedent) instead of dividing raw saved/target, so an overshoot reads
  `100% there!` with `£0.00 to go`, never `142% there!`. Seeded readings
  unchanged (62 / 66).
- K10-BUG-1: same-tick close guard on BOTH `_onPayoutRequested` and
  `_onLoadRequested`, via a private `_closing` flag set synchronously as the
  first line of `close()` — deliberately not `isClosed`, which still reads
  false while a same-tick queued load runs during close (verified: the
  `isClosed`-only attempt still leaked, `live=1`).
- Tests: K10-BUG-1 (+ its jar-handler twin, the K09-BUG-7 shape) and K10-BUG-2
  regressions added; the three logic-layer `skip:`s in `k10_bugs_test.dart`
  un-skipped.

**2b (UI) — FIXES_1 UI/layout/copy items.** Contract unchanged from the plan:

- K10-BUG-3 (major, the only major finding): `payout_note.dart` dropped the
  `maxLines: 2` cap on the `.k10-t` title so it wraps freely (the HTML sets no
  clamp on this screen; card grows with content like the CSS box model);
  `payout_fund_card.dart` wrapped each `.k10-amts b` amount in a left/right
  aligned `FittedBox(fit: BoxFit.scaleDown)` so `£9.49 to go` shrinks ~4 px
  instead of being cut mid-word at 320/1.3×. At 390/1.0 the seeded strings fit
  at scale 1.0, so the recorded geometry bands (note 2 top 509, fund top 613)
  are unchanged.
- Review finding 1 (`_PayoutPip` truncated doc comment) and finding 2
  (write-only `_PayoutFailure.message` param, with the fixed kid-voice copy
  deliberately not rendering the bloc error) fixed in `payout_day_view.dart`.
- `payout_day_matrix_test.dart`: `(320, 1.3)` added to the green copy-fit
  cells (now 6 widths/scales × 2 themes) and the parked `skip: true` proof
  deleted.

No BLoC state/event rename, no import break, no member rename between the
halves — 2b's diff touches no event/state/entity signature, so it is
compatible with either side of 2a's fix.

## FIXES items

| # | From | Item | Status |
|---|---|---|---|
| K10-BUG-3 | major | 320 px / 1.3× ellipsizes note-2 title and `£9.49 to go` mid-word | **DONE (2b)** — layout fix, no copy shortened; matrix proof un-skipped and green |
| K10-BUG-1 | minor, latent | payout handler missing same-tick close guard | **DONE (2a)** — `_closing` flag on both handlers; regression live |
| K10-BUG-2 | minor | `goalPercent` unclamped past target | **DONE (2a)** — clamped; entity + repo regressions live |
| review 1 | minor | truncated `_PayoutPip` doc comment | **DONE (2b)** |
| review 2 | minor | write-only `_PayoutFailure.message` | **DONE (2b)** |
| review 3 | minor | stale `errorMessage` during payout reload | **LEFT — deliberate (2a)**: kept the K03/K09 precedent (a loading retry keeps the error until a healthy emission clears it), pinned by 2a's retry tests AND the K09 equivalents; clearing only the payout half would fork the two handlers' contract for an invisible state. Revisit only if both handlers change together |
| review 4 | minor | newest- vs oldest-match companion savings move | **LEFT — deliberate (2a)**: kept the plan-specified semantics (`1_plan.md` §b: first/newest `Jar → …` at/after the payout instant). The bugs stage explicitly did not file it ("hardening, not a defect in the demo path") and changing match order would fork the contract both builders code against |
| iter-1 note-2 wrap | — | note 2 is 88 px with the DB copy, shifting fund top 591 → 613 | **still LEFT as-is, by rule** — DATA OVER MOCKS: the seeded DB's `£5.50 went into your Lego Friends set` wraps where the mock's shorter string did not, and the card grows with content. Recorded in the geometry test's bands; not "fixed" by hard-coding mock copy |
| iter-1 stub | — | `_CountingJarRepository.watchLatestPayout` missing | **already DONE** in iteration 1; still compiling clean |

No SHARED_REQUEST (nothing shared touched; plan §g holds). Remaining skips in
the suite are the 6 pre-existing K09 `skip: true` proofs in `k09_bugs_test.dart`
— none are K10, and no K10 proof is parked.

## Verification tails

`dart format .` →

```
Formatted 660 files (0 changed) in 2.40 seconds.
```

`flutter analyze` →

```
Analyzing app...
No issues found! (ran in 5.6s)
```

`flutter test --timeout 120s` (whole app) →

```
01:44 +4753 ~13: All tests passed!
```

(4753 passed, 13 skipped, 0 failed. Cross-check `flutter test --timeout 120s
test/features/kid_jar` → `+265 ~6: All tests passed!` — the 6 skips there are
the pre-existing K09 proofs; every K10 proof runs live.)

VERDICT: PASS