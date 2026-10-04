# P17 Parental gate — 2 build (integrate, iteration 2)

Integration of the two iteration-2 builders. Scope: compile + green suite, no
redesign, no simulator, no `flutter clean`, no interactive run, no skipped or
weakened tests.

## Summary of 2a (logic)

- Contract unchanged from iteration 1 (same three events, same state fields and
  helpers) — so again no shape conflict with 2b. Two additive internals:
  `ParentalGateState.copyWith` gained optional `clearError: false` (PaywallState
  precedent, no call-site change) and `challengeFor(utc)` now reads the
  calendar day in the family zone (Europe/London) instead of UTC — P17-BUG-2.
- `onData` (P17-BUG-3): resets `entered`/`attempts`/`unlocked` when the live
  challenge id changes, keeps the half-typed entry on same-challenge re-emits,
  and clears a stale `errorMessage` on loading/loaded (3_test §3.3.3 sticky-error
  minor).
- Tests: `parental_gate_bloc_test.dart` 25, `parental_gate_repository_test.dart`
  13 (shared memory DB per 4_review finding 3, + BST London-day split proof),
  and the `p17_bugs_test.dart` `skip:`s on the BUG-2/BUG-3 proofs removed (both
  green now). P17-BUG-1 stays skip-marked — shared `router.dart`, request #2.

## Summary of 2b (UI)

- FIXES_1 §3.1 closed: `_unlock` now pops **before** flipping `AppModeController`,
  because flipping the mode mid-pop made the router's refreshListenable re-parse
  and resurrect `/parental-gate`. The root deep-link branch keeps the old order
  (nothing to pop, redirect must not re-fire).
- ORCHESTRATOR_NOTES addressed: card anchored at the design's top **66** instead
  of centred (the uniform-shift failure), `NestStatusBar` reserve added as the
  first child of the dimmed backdrop so the header sits below the OS status bar,
  CSS vertical rhythm restored (lock→12→title→8→instr→4→question→16→digits→16
  →keypad→12→cancel→10→caption→20), loading question placeholder resized to the
  h3 line box (no jump), leaf caret on every empty box per `.digit.empty::after`.
- Keypad pitch: **not** fixed — shared `NestKeypad` hard-codes 24/16 gaps where
  the CSS grid is `gap:10` + `padding:8 24 0`. Filed as SHARED_REQUEST #3.

## Merge check — no integration breakage

No mismatched BLoC states/events, no import fixes, no renamed members, no test
collisions. 2b consumed exactly the iteration-1 contract that 2a extended
additively. The two halves needed no reconciliation.

## FIXES items

| Item | Status |
|---|---|
| `dart format .` | DONE — `517 files (1 changed)`: the one change was an unrelated shared file (`test/design_system/list_row_trailing_test.dart`, unformatted on `main`), **reverted** — RULES §1. My scope: `Formatted 18 files (0 changed)` |
| `flutter analyze` (whole app) | DONE — `No issues found! (ran in 4.0s)` |
| `parental_gate` suite | 90 pass · 1 skip (shared-router proof, request #2) · **2 red** |
| `flutter test` (whole app) | **NOT GREEN** — `+2811 ~2 -9: Some tests failed.` |
| Integration fixes in scope | NONE FOUND — nothing to fix |
| 2 reds in `parental_gate_geometry_test.dart` | BLOCKED on shared core — marked `TODO(P17)` in code, request #3 |
| 7 reds in `kid_home` (K03) | OUT OF SCOPE — request #1, unfixed |

Iteration 1 had 41 reds; this merge of `main` cleared the 34 pre-existing ones
(K03 layout matrix, P11 approvals copy/semantics, P08-B11). **9 remain: 7 + 2.**

### The 2 reds in my own suite — why I could not fix them

Both are the ORCHESTRATOR_NOTES item 11 pins that 2b added, and both fail on the
keypad alone:

```
card height: app 738.0 vs design 712.0 (Δ26.0)
keypad row 2 centre: app 468.0 vs design 462.0 (Δ6.0)   ← already +6 inside the keypad
keypad row 3 centre: app 556.0 vs design 544.0 (Δ12.0)
keypad row 4 centre: app 644.0 vs design 626.0 (Δ18.0)
"Back to Pip" centre: app 728.0 vs design 702.0 (Δ26.0)
caption centre: app 775.0 vs design 749.0 (Δ26.0)
Expected: 82.0 (±0.5) / Actual: <88.0>
```

The card top is now correct (66) and keypad row 1 matches, so the whole Δ26 is
the shared component: `nest_keypad.dart` uses `SizedBox(s4)`=16 row gaps and
`EdgeInsets.all(s2)` (8 all round) ⇒ 352 tall, where the CSS grid
(`gap:10`, `padding:8 24 0`) gives 326. **No call-site change can fix it** —
row 2's centre is already 6 px low inside `NestKeypad`, so nothing P17 does
around it moves that row, and the alternative (a local keypad) is forbidden by
plan §g and by "never re-implement components". The fix is in
`app/lib/core/**`, which RULES §1 puts off-limits to me.

I did **not** skip or relax those two pins — the red is the honest signal the
orchestrator needs. Per RULES §2 I recorded the block in code as `TODO(P17)` at
the `NestKeypad` call site and refreshed request #3 with the exact numbers,
the reasoning, and the concrete patch (three `Expanded` columns with the 72 px
key centred, row gap `NestSpacing.gap10`, `padding: EdgeInsets.only(top: 8)`),
which also fixes K02's pitch.

### The 7 reds outside my scope

`kid_home` K03 tests navigate to `/parental-gate` and assert the v1 scaffold
title `P17 Parental gate`; the real gate renders design copy `Grown-ups only`.
Failure: `Found 0 widgets with text "P17 Parental gate": []`. Still present after
the `main` merge (`k03_bugs_test.dart:1059,1531`;
`kid_home_view_test.dart:1243,1259,1275,1290,1989`). Those files are outside
RULES §1 for P17; the one-line fix each is `expect(find.text('Grown-ups only'),
findsOneWidget);`. Re-adding the scaffold string to the view is not an option —
it is not design copy and it would fail P17's own copy test. Request #1 updated
with the live line numbers and status.

## Change I made this stage

One, comment-only, in `parental_gate_view.dart`: the `TODO(P17)` block-quote at
the `NestKeypad` call site recording the shared-component gap conflict and
pointing at request #3 — the RULES §2 mechanism for building against the
foundation while blocked. No behaviour, no layout, no copy change. I also
reverted `dart format .`'s edit of the shared
`test/design_system/list_row_trailing_test.dart` so this stage touches nothing
outside `app/lib|test/features/parental_gate/**` and `docs/screens/P17/**`.

## Tails

`dart format .` → `Formatted 517 files (1 changed) in 3.62 seconds.` (that 1 was
the unrelated shared test; reverted). My scope:
`Formatted 18 files (0 changed) in 0.13 seconds.`

`flutter analyze`

```
Analyzing app...
No issues found! (ran in 4.0s)
```

`flutter test test/features/parental_gate`

```
00:05 +90 ~1 -2: .../parental_gate_view_test.dart: states Seed.empty: no child, but the gate still works
00:05 +90 ~1 -2: Some tests failed.
```

`flutter test` (whole app)

```
01:33 +2811 ~2 -9: Some tests failed.

Failing tests:
  app/test/features/kid_home/k03_bugs_test.dart: K03-BUG-9: double-tapping the lock stacks two gate routes
  app/test/features/kid_home/k03_bugs_test.dart: performAction(tap) on the lock opens the gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 grown-ups lock (every kid state) failure state: the lock still opens the parental gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 grown-ups lock (every kid state) loaded home: the lock opens the parental gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 grown-ups lock (every kid state) loading state: the lock is reachable and opens the gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 grown-ups lock (every kid state) no active child: the lock still opens the parental gate
  app/test/features/kid_home/kid_home_view_test.dart: K03 navigation lock opens the parental gate
  app/test/features/parental_gate/parental_gate_geometry_test.dart: ORCHESTRATOR_NOTES design pins (390×844, light, textScale 1.0) every band sits within ±2 px of the design PNG
  app/test/features/parental_gate/parental_gate_geometry_test.dart: ORCHESTRATOR_NOTES design pins (390×844, light, textScale 1.0) the keypad follows the HTML grid gap (pitch 82)
```

## For the orchestrator

Two shared changes clear the whole suite — no P17 product code is needed for
either:
1. `nest_keypad.dart`: CSS-grid gaps (request #3) → the 2 P17 design pins go
   green and the card returns to 712.
2. K03 tests: assert `Grown-ups only` instead of the scaffold title
   (request #1) → the 7 kid_home reds go green.

VERDICT: FAIL
