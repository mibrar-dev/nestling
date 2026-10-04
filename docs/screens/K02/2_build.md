# 2 BUILD (INTEGRATE) — K02 Kid PIN (`kid_home`, iteration 3)

Merge of the two FIXES_2 builders on top of the iteration-2 checkpoint
(`f8cf213`) with `main` already merged (`a967441`). The halves compiled,
analysed and passed as merged, so the only work was running the gates,
re-checking the merge for regressions, and one stale-comment correction.

## Summary of 2a (logic) — no code change

`presentation/bloc/**`, `domain/**`, `data/**` untouched; the iteration-1
contract (`KidHomePinSubmitted`, `pinChecking`/`pinWrongNonce`/`pinPassed`)
still holds and no new contract was needed.

FIXES_2 triage found **no logic-layer defect**: the `k02_bugs_test.dart` hang
(ORCHESTRATOR_NOTES 10:32) was already fixed by the test stage in a
view-layer file; K02-BUG-5's latch is the view-local `_noPinHandled` flag, so
no bloc/state change can fix it without a view edit; K02-TEST-BUG-A's sibling
`profile_tile.dart:96` / `kid_home_view.dart:364` sites and the permanent fix
are SHARED_REQUEST #3 (orchestrator-owned, `core/`); the new view tests and
the un-skipped K02-BUG-1..4 proofs are all in view-layer files.

## Summary of 2b (UI) — FIXES_2 applied

- **K02-BUG-5 [minor, latent] — the latch was never released.** The
  iteration-2 K02-BUG-3 fix declined the auto-advance but left
  `_noPinHandled == true`, so when a no-PIN child returned, K02 stayed on its
  `_KidLoading` spinner forever (the `!pinSet` branch renders loading, so
  there were no keys to advance with). One targeted statement on the decline
  path in `kid_pin_view.dart`: `setState(() => _noPinHandled = false)`. The
  navigation branch is untouched, so K02-BUG-3's PIN-bypass protection still
  holds (pinned by its own un-skipped proof).
- **K02-BUG-5 proof un-skipped** — `k02_bugs_test.dart` no longer carries any
  `skip: true`; K02-BUG-1..5 all run in the plain suite.
- **False-positive assertion retargeted** — the closing probe
  `find.byType(CircularProgressIndicator) == findsNothing` cannot hold in this
  harness (after `go('/kid-home')` the route supplies a fresh bloc whose
  broadcast-stream subscription has already consumed the fake's leo/maya
  emissions, so K03's own transient `_KidLoading` is legitimately mounted).
  It now pins the K02-side regression directly:
  `find.bySemanticsLabel('Loading your secret code') == findsNothing`, while
  the primary proof (`currentPath == '/kid-home'`) stays 20 lines above. The
  change narrows the assertion to the screen under test instead of dropping
  it.
- **Stale file header (this stage, mine)** — `k02_bugs_test.dart:3-10` still
  said K02-BUG-5 "is parked with `skip: true`" after the merge removed the
  park. Reworded to state BUG-1..5 all run un-skipped and to keep the
  `--run-skipped --plain-name K02-BUG` recipe as a conditional note for a
  future parked proof. Comment only — no assertion touched.

Mandatory notes: 10:32 hang — `k02_bugs_test.dart` finishes in **3 s**
(was 1 h+); 07:13 keypad pitch — still the shared component with
`fit: NestKeypadFit.shrinkWrap`, no local key spacing.

## FIXES_2 items — done / left

| item | owner | status |
|---|---|---|
| `k02_bugs_test.dart` hang (10:32) | 3_test | **done** (multi-cycle pumps complete; file runs in 3 s) |
| K02-BUG-5 latch never released | 2b | **done** (decline-path `setState`) + proof un-skipped and green |
| K02-BUG-5 false-positive CPI assertion | 2b | **done** (retargeted to the K02 loading semantics label) |
| 3_test's new view tests (47 → 54) + un-skipped BUG-1..4 / review #2 #4 / keypad proofs | 3_test | **done** |
| 3_test's 3 bloc proofs | 2a | **done** (pass unmodified) |
| K02-TEST-BUG-A sibling sites (`profile_tile.dart:96`, `kid_home_view.dart:364`) | orchestrator (SHARED_REQUEST #3) | **left (shared, `core/`)** — out of RULES §1 for a screen agent |
| SHARED_REQUEST #1 `NestType.kidSay` / `kidMark` | orchestrator | **left (open, shared)** — still `TODO(K02)` at the call site |

Nothing was left for this stage. No integration fixes were required: no
contract mismatch, no import/rename break, no failing test.

## Integration check (beyond the gates)

- **TEST TIMEOUTS rule** — every run above used `--timeout 120s`; no test file
  approaches it (whole suite 1 m 34 s wall).
- **No new skips / no weakened assertions** — `rg "skip: true" test/` returns
  2 executable hits, both pre-existing sibling parks
  (`k01_bugs_test.dart:569` K01-BUG-7, `p12_bugs_test.dart:321`), matching the
  `~2` in the run. `k02_bugs_test.dart` now has zero parks. Every K02 test
  count grew, none shrank (140 across the four K02-owned files vs 127 in
  iteration 2). `analysis_options.yaml` untouched.
- **Rule spot-checks on the merged diff**: no `GoogleFonts`; no
  `DateTime.now()`; no `subscription_status` write; no new id creation (IDS
  rule N/A); the new `setState` is view-local state only — no bloc, no
  navigation, no token/colour/size change; copy untouched; no local hills or
  meadow; no `pip_stage_*.svg`.
- **Scope**: `app/lib/features/kid_home/presentation/views/kid_pin_view.dart`
  (1 statement + comment), `app/test/features/kid_home/k02_bugs_test.dart`
  (1 removed `skip: true`, 1 retargeted assertion, header comment),
  `docs/screens/K02/**`. No `core/`, no `app/`, no other feature, no
  `tools/screens/`. **No simulator was booted, installed on, screenshot or
  driven by this stage.**

## Gates (`app/`)

`dart format .`

```
Formatted 540 files (0 changed) in 1.62 seconds.
```

`flutter analyze`

```
Analyzing app...
No issues found! (ran in 3.0s)
```

`flutter test --timeout 120s` (whole app)

```
01:29 +3234 ~2: .../value_tour_view_test.dart: P02 value tour — owner rule: alignment dark 320dp: 20px gutters on every edge
01:29 +3235 ~2: ... P02 value tour — owner rule: alignment dark 390dp: 20px gutters on every edge
01:29 +3236 ~2: ... P02 value tour — owner rule: alignment dark 430dp: 20px gutters on every edge
01:29 +3237 ~2: All tests passed!
```

3237 pass, 2 skipped (the pre-existing sibling parks), 0 failures, 1 m 34 s wall.

`flutter test --timeout 120s test/features/kid_home/k02_bugs_test.dart` (the
10:32 hang item)

```
00:03 +31: All tests passed!
```

`flutter test --timeout 120s test/features/kid_home`

```
00:11 +436 ~1: All tests passed!
```

(the `~1` is K01-BUG-7)

`flutter test --timeout 120s` on the four K02-owned files (view, bugs, bloc,
repository)

```
00:05 +140: All tests passed!
```

VERDICT: PASS