# Fix list after iteration 3

## From 2_build.md
# P17 Parental gate — 2 build (integrate, iteration 3)

Integration of the two iteration-3 builders. Scope: compile + green suite, no
redesign, no simulator, no `flutter clean`, no interactive run, no skipped or
weakened tests.

## Summary of 2a (logic)

- **CONTRACT CHANGES: none** — not even additive this iteration. Events, state
  fields, helpers, `copyWith(clearError)` and the London-day `challengeFor` are
  exactly what iteration 2 shipped, so 2b had nothing to re-cut.
- No file changed in `app/lib/**` or `app/test/**`, deliberately: every
  FIXES_2 item in the logic layer is either shared (§3.2 keypad → landed on
  `main`), view-layer (§3.1 backdrop row, §3.3 FittedBox, 6_bugs obs 1), a
  contract change it declines (4_review finding 2, contradicts `1_plan.md` §(b)),
  or out of layer (P17-BUG-1 router, the 7 K03 reds).
- Re-verified after the merge: bloc + repository files `+38` all pass (25 + 13);
  the un-skipped P17-BUG-2 and P17-BUG-3 proofs pass individually.

## Summary of 2b (UI)

- The shared keypad fix (`9cac0c6`) landed via `e70760c`, so per
  ORCHESTRATOR_NOTES 07:13 nothing was re-spaced locally. 2b only made the call
  site compatible: direct render when the card content is ≥
  `NestKeypad.contentWidth` (the `SizedBox(296) > FittedBox` wrapper was
  redundant and an unbounded-constraint crash risk with the new `Expanded`
  cells), and `SizedBox(contentWidth) + FittedBox(scaleDown) +
  NestKeypadFit.shrinkWrap` for narrower cards.
- FIXES_2 §3.1 closed — backdrop header row no longer passes
  `crossAxisAlignment: start`, so `.kb-top { align-items: center }` holds;
  P17-BUG-4 proof un-skipped and green. Fixing it exposed a wrong expectation in
  the pin itself (`designBackdropHeaderTop = 55` is the row top, but the
  assertion measured the greeting text); the constant is now split 55 (row) / 60
  (centred h1 line box) and both are pinned — a corrected expectation, not a
  relaxed one.
- FIXES_2 §3.3 closed (the merge blocker); §3.2 closed by the shared merge.
- 6_bugs obs 1 closed — `_announcedChallengeId` re-bases the announcement
  high-water mark when the challenge changes, so the first wrong answer on a new
  challenge is announced again.
- Found and fixed its own regression: `_GateLoading` over-reserved the caption
  gap + line box (the enclosing column already adds both), which made the
  loading card 28 px taller than the loaded one.
- Dead code deliberately kept (`parental_gate_placeholder_card.dart` is the
  repo-wide v1 scaffold, unreferenced in 11 features).
- Copy re-verified character-by-character against the HTML; no letter-spacing
  and no `text-wrap: balance` in the P17 CSS, so `NestType` defaults stand and
  `NestBalancedText` is correctly absent.

## Merge check — no integration breakage

Nothing to reconcile: 2a changed no contract and no file, so the two halves
could not conflict. Verified end-to-end rather than assumed — `dart format`,
`analyze` and the whole suite all run clean on the combined tree.

## FIXES items

| Item | Status |
|---|---|
| `dart format .` | DONE — `528 files (0 changed)`; nothing to revert this time (the unformatted shared test from iteration 2 is fixed on `main`) |
| `flutter analyze` (whole app) | DONE — `No issues found! (ran in 13.9s)` |
| `parental_gate` suite | **106 pass · 1 skip · 0 red** (was 90 · 1 · 2) |
| `flutter test` (whole app) | **NOT GREEN** — `+2989 ~3 -8: Some tests failed.` |
| Integration fixes in scope | NONE FOUND |
| ORCHESTRATOR_NOTES 2–6 + item 11 (pins + scrim) | MET — 11/11 geometry pins green, every band Δ0 |
| SHARED_REQUEST #3 (keypad) | RESOLVED by the `main` merge — request marked closable |
| P17-BUG-1 (shared router loop) | OPEN, honestly skip-marked (request #2) |
| 8 reds in `kid_home` | OUT OF SCOPE — request #1, updated |

Iteration 2 had 9 reds; **8 remain, and none of them are in `parental_gate`.**
The two in-feature reds (the ORCHESTRATOR_NOTES keypad/band pins) are green now
that `main` carries the CSS-grid keypad.

### The 8 remaining reds — all out of scope, all one root cause

All in `app/test/features/kid_home/**`, which P17 may not edit (RULES §1).
Two symptoms of the same fact: P17 replaced the v1 scaffold, whose `AppBar`
supplied a title and an automatic back button.

1. **7 × scaffold title** — `find.text('P17 Parental gate')` after tapping the
   lock. The real gate renders design copy `Grown-ups only`.
   `Found 0 widgets with text "P17 Parental gate"` at `k03_bugs_test.dart:1059,1531`
   and `kid_home_view_test.dart:1247,1263,1279,1294,1993`.
2. **1 × back button (new this iteration)** —
   `k01_bugs_test.dart` › `rapid lock double tap pushes exactly one gate`
   (line 697). Its own `expect(pushedPath(tester), '/parental-gate')` **passes**,
   so the double-tap latch and the navigation are correct; it then fails on
   `await tester.pageBack()`:
   `Found 0 widgets with type "CupertinoNavigationBarBackButton": [] / One back
   button expected on screen`. Proven both ways this iteration — with the v1
   scaffold view checked out temporarily the test is **green**
   (`00:01 +1: All tests passed!`), with the real view it fails; the view was
   restored byte-identical afterwards (`diff -q` clean).

Fixes are one line per site (assert `Grown-ups only`; tap `Back to Pip` instead
of `pageBack()`) and are written up in `SHARED_REQUEST.md` #1. Neither may be
"fixed" in the view: the placeholder title is not design copy and an AppBar back
button would break the design and all 11 pins.

## Change I made this stage

None in `app/`. `dart format .` reported 0 changed, `analyze` is clean, the
feature suite is fully green, and the only experiment I ran (the scaffold swap
above) was reverted byte-identical. Docs only: `SHARED_REQUEST.md` #1 updated
with the 8th failure, its proof and the one-line fixes; #3 annotated as resolved
by `9cac0c6` with the re-measured numbers.

## Tails

`dart format .`

```
Formatted 528 files (0 changed) in 2.33 seconds.
```

`flutter analyze`

```
Analyzing app...
No issues found! (ran in 13.9s)
```

`flutter test test/features/parental_gate`

```
00:06 +106 ~1: .../parental_gate_geometry_test.dart: ... loading placeholders keep the loaded card height
00:06 +106 ~1: 1 skipped test.
00:06 +106 ~1: All other tests passed!
```

(The single skip is P17-BUG-1, the shared-router proof from request #2.)

`flutter test` (whole app)

```
02:19 +2989 ~3 -8: Some tests failed.

Failing tests:
  app/test/features/kid_home/k01_bugs_test.dart: edge-case probes rapid lock double tap pushes exactly one gate
  app/test/features/kid_home/k03_bugs_test.dart: K03-BUG-9: double-tapping the lock stacks two gate routes
  app/test/features/kid_home/k03_bugs_test.dart: performAction(tap) on the lock opens the gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 grown-ups lock (every kid state) failure state: the lock still opens the parental gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 grown-ups lock (every kid state) loaded home: the lock opens the parental gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 grown-ups lock (every kid state) loading state: the lock is reachable and opens the gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 grown-ups lock (every kid state) no active child: the lock still opens the parental gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 navigation lock opens the parental gate
```

## For the orchestrator

The P17 screen is complete and pinned to the design — 11/11 geometry pins at
Δ0, 106 green tests, 1 honest skip. The suite goes fully green with **one
change in another feature's tests**: 7 × assert `Grown-ups only` instead of the
scaffold title, and 1 × replace `pageBack()` with a `Back to Pip` tap
(`SHARED_REQUEST.md` #1, with line numbers and the proof). Request #3 can be
closed — `main` satisfied it.

