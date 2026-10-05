# 2 BUILD (INTEGRATE) — K03b Kid home all done (iteration 2)

## Result

`dart format .` clean, `flutter analyze` → **No issues found!**, full suite
`flutter test --timeout 120s` → **All tests passed!** (+4999 ~21).
One integration fix was required (a new `prefer_const` lint in a
logic-builder test edit). Nothing was renamed across halves, no import
broke, no BLoC state/event mismatch survived the merge.

## Summary of the two halves

### 2a (logic) — `2a_build_logic.md`, VERDICT: PASS

Contract changes (all in the feature's domain/data layers):

- `KidQuest` gains `needsApproval` (default `true`, in `props`) —
  mirrors the `quests.needs_approval` DB default and the P09 ON default.
- `KidQuestModel` round-trips the flag (`fromJson` absent → `true`).
- `_watchItemsFor` no longer re-sorts; `state.items` is
  `watchActiveQuests` creation order (dishwasher, reading, bins, tidy,
  hoover, table) — ROW ORDER owner rule, K03B-BUG-5 data half.
- Repository surfaces `needsApproval: q.needsApproval` — K03B-BUG-4
  data half; new `K03b row order + approval flag` group (3 tests).
- `kid_home_bloc_test.dart`: `_withStatus` carries the flag; new
  `needsApproval defaults true and shapes equality` test.

### 2b (UI) — `2b_build_ui.md`, VERDICT: PASS

View half, coded against 2a's contract (`needsApproval`, creation-order
`state.items`); owns only `presentation/views/**` + view tests:

- `_AllDoneBody` geometry (FIXES_1 finding 1 / K03B-BUG-1 / 04:52 D1):
  bubble → `SizedBox(s4=16)`, `Stack(clipBehavior: Clip.none)` so the
  absolute confetti never sizes the layout, `NestPetStage` in
  `Padding(top: gap14)` — bubble→pet = 16 + 14 = 30, confetti `top: 4`
  from the design stage origin.
- Nest art (K03B-BUG-3): all-done-local 226/226 constants; K03's
  236/188 untouched.
- Shared slot bug (K03B-BUG-2) worked around feature-side per D1:
  `pipBottom: 92` takes the `explicitGeometry` early return that honours
  `slotHeight` (226 − 92 − 152 = −18 → Pip −18…134 vs design −16…134).
- ROW META view branch on `status` + `needsApproval`: not-done → `+N`;
  done + no approval → `+N` (no status chip); `done_pending` + approval
  → `Waiting for Mum`; `approved` + approval → `Mum said yes!`.
  `_statusText` mirrors it. Approved demo rows move `Done` →
  `Mum said yes!` by mandate; waiting/to-do demo rows unchanged.
- View-test pins updated to creation order + new meta
  (`k03b_all_done_view_test.dart` 54 green, `kid_home_view_test.dart`
  88 green, K03 geometry/bugs suites green).

The halves dovetailed: 2b consumed 2a's `needsApproval` exactly as
specified; neither builder touched `k03b_bugs_test.dart` (bugs-stage
owned) or any shared file.

## Integration fixes applied by this stage

1. `app/test/features/kid_home/kid_home_bloc_test.dart:410` —
   `flutter analyze` flagged 2a's new test
   (`prefer_const_constructors`, then `prefer_const_declarations`):
   `final noApproval = KidQuest(...)` with all-constant args →
   `const noApproval = KidQuest(...)`. Lint-only; zero behaviour change.
   Re-ran analyze → No issues found.

No other merge repair was needed: the entity default keeps every
existing `KidQuest(...)` construction compiling, and the view's
`item.needsApproval` references resolve against 2a's field.

## FIXES_1 disposition (every item done/left)

| # | Item | Status |
|---|---|---|
| Review 1 (major) | bubble→pet gap 16 px short (14 vs 30) | DONE — 2b (`s4` + 14 px pet padding); BUG-1 proofs pass on demand (below) |
| Review 2 (minor) | `docs/ARCHITECTURE.md` route table still maps `/kid-home-done` to `KidHomeDoneView` | LEFT — shared doc, orchestrator owns (no branch edit per RULES §1) |
| 5_ui dev 1 (major) | section + cards shifted down ~15.3 px | DONE — title/progress/card1 geometry proofs pass on demand (BUG-1 second proof); card shapes/gutters already exact |
| 5_ui dev 2 (minor) | bubble `textAlign: center` vs design start | DONE on main via `shared/speech_align` (04:52 D2) — not this branch |
| K03B-BUG-1 | bubble→pet gap + rows below | DONE — both parked proofs green on demand |
| K03B-BUG-2 | `explicitGeometry` ignores `slotHeight` (shared) | SUPERSEDED by D1 feature-side correction (`pipBottom: 92`); the shared unit (no-`pipBottom` form) still returns 257.4 — LEFT, needs an orchestrator SHARED_REQUEST if the unit contract must change; this branch must not touch `core/**` |
| K03B-BUG-3 | nest art 236×188 vs design 226×226 | DONE — parked proof green on demand |
| K03B-BUG-4 | row meta (`Mum said yes!` / `+N` chip) | DONE in behaviour — no-approval `+15` proof green on demand; approved-proof renders the right copy but its `findsOneWidget` expectation is stale (see below) — LEFT for the bugs stage to update + un-skip |
| K03B-BUG-5 | creation order vs title sort | DONE — parked proof green on demand; LEFT skipped for the bugs stage to un-skip |

## Parked-proof on-demand runs (this stage, evidence for stage 6)

`skip: true` markers left untouched — the file is bugs-stage owned and
the full suite is green either way. Ran with `--run-skipped`:

- `K03B-BUG-1` (×2: 30 px gap; rows on design row) → **pass**.
- `K03B-BUG-3` (226×226 art) → **pass**.
- `K03B-BUG-5` (creation order) → **pass**.
- `K03B-BUG-4` no-approval (`+15` chip) → **pass**.
- `K03B-BUG-4` approved (`Mum said yes!`) → fails ONLY on the count:
  `Expected: exactly one matching candidate / Actual: Found 3 widgets`.
  The 3 are correct per ROW META — demo seeds q-bins + q-hoover
  `approved` (same London week, count for the period) and the test flips
  q-reading to `approved`; all three need approval. The expectation dates
  from iteration 1, when approved rendered `Done` (0 before the flip, 1
  after). Bugs stage: assert the reading card specifically or expect
  `findsNWidgets(3)`, then un-skip.
- `K03B-BUG-2` unit form → still 257.4 (shared code, superseded per D1;
  not re-run by this stage beyond 2b's evidence).

## Verification (run in `app/`)

```
$ dart format .
Formatted 665 files (0 changed) in 2.29 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.9s)

$ flutter test --timeout 120s test/features/kid_home
00:17 +755 ~12: All tests passed!

$ flutter test --timeout 120s
02:46 +4999 ~21: All tests passed!
```

(`~12` / `~21` are pre-existing `skip:`-marked tests, not failures.)

## Compliance spot-checks

- Scope: `git status --porcelain` paths all sit under RULES §1
  (`app/lib/features/kid_home/**`, `app/test/features/kid_home/**`,
  `docs/screens/K03b/**`) — nothing outside.
- No `google_fonts` import, no live `DateTime.now()` call in the
  feature (one comment mentions the ban; enforced by tests).
- No `flutter clean`, no simulator booted, no `pkill`, `clock.now()` /
  `appNowUtc()` untouched, `disposeApp` pattern kept, `newId` untouched.
- k03b diffs in `k03b_all_done_bloc_test.dart` are formatter reflow only.

VERDICT: PASS
