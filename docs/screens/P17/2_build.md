# P17 Parental gate — 2 build (integrate, iteration 1)

Stage 2 integration of the two parallel builders. Job was compile + green
suite only; no redesign, no simulator, no `flutter clean`, no interactive run.

## Summary of 2a (logic)

- Extended the existing per-feature contract only, no CONTRACT CHANGES:
  state `+entered`/`attempts`/`unlocked` (+`copyWith`/`props`, helpers
  `challenge`, `expectedLength`, `isComplete` where
  `isComplete = expectedLength > 0 && entered.length == expectedLength`);
  events `ParentalGateDigitEntered`, `ParentalGateDeletePressed`,
  `ParentalGateUnlockAcknowledged`; bloc handlers for append / auto-verify /
  clear-on-wrong / delete / acknowledge, all with the plan's guards.
- Repository untouched (existing `ParentalGateRepository` via Drift only).
- Tests: `parental_gate_bloc_test.dart` (17) + `parental_gate_repository_test.dart` (5).

## Summary of 2b (UI)

- `parental_gate_view.dart` rewritten from the scaffold to the full-bleed
  kid-mode gate: `Scaffold`(transparent) → `KidScope` → `Stack` of
  backdrop (`Hi {nickname}!` + `NestCoinPill` + `PipAvatar` 200, dimmed,
  `ExcludeSemantics`) / full-bleed `tokens.scrim` / centred `NestModal`
  (24 gutter, radius 32) containing `_LockTile` 52, `Grown-ups only` (h2),
  `Type the answer in numbers:`, repo-derived question (h3, maxLines 2),
  `_DigitsRow` 56×64 gap 12, `NestKeypad(kid: true)` in a 296 `FittedBox`
  slot, `Back to Pip` ghost (minHeight 56), caption.
- States: loading placeholders + leaf spinner; failure message + ghost
  `Try again`; disabled-gate pass-through (once).
- Listener: `unlocked` → `UnlockAcknowledged`, parent mode first
  (`AppModeController.selectMode(parent)` + `AppSession.setAppMode('parent')`
  + `refresh()`), then `pop()` else `go('/today')`; wrong answer announces
  `That wasn’t right — try again` (no danger styling).
- Tests: `parental_gate_view_test.dart` (9), `parental_gate_geometry_test.dart` (2),
  `parental_gate_states_test.dart` (5).

## Merge check — no breakage between the halves

The two halves did not collide: 2b was written against the exact contract 2a
reports, so there were **no** mismatched states/events, no import fixes, no
renamed members and no test conflicts to repair. Verified: the view consumes
only `state.challenge/expectedLength/entered/attempts/unlocked/status/items`
and adds only the three new events; the bloc never imports view code. Nothing
was changed by me in `lib/**` or `test/**` — the combined result is 2a + 2b as
handed over, and it is internally consistent (38/38 feature tests green).

## FIXES items

| Item | Status |
|---|---|
| `dart format .` whole app | DONE — `Formatted 489 files (0 changed)` (already clean) |
| `flutter analyze` whole app | DONE — `No issues found! (ran in 11.0s)` |
| `flutter test test/features/parental_gate` | DONE — `+38: All tests passed!` |
| `flutter test` (whole app) | **BLOCKED** — 41 failures; see below |
| Fix integration breakages in my scope | NONE FOUND — nothing to fix |
| Out-of-scope failures from the P17 view replacing the scaffold | FILED — `docs/screens/P17/SHARED_REQUEST.md` |

### Whole-suite failures — classified

Baseline measured by `git stash -u` (HEAD = main + the P17 wip merge, builders'
work removed) and compared failure-by-failure with the integrated tree:
**34 failing before, 41 after ⇒ exactly 7 new failures, all from this build**,
and 34 pre-existing and untouched by P17:

1. **7 new — caused by P17 replacing the v1 scaffold screen** (out of my edit
   scope, `app/test/features/kid_home/**`): K03 tests navigate to
   `/parental-gate` and assert the scaffold title `P17 Parental gate`, which
   the real gate (design copy `Grown-ups only`) no longer renders:
   `k03_bugs_test.dart` `performAction(tap) on the lock opens the gate`,
   `K03-BUG-9: double-tapping the lock stacks two gate routes`;
   `kid_home_view_test.dart` `K03 navigation lock opens the parental gate` and
   the four `K03 grown-ups lock (every kid state) …` cases. Failure text:
   `Expected: exactly one matching candidate / Actual:
   _TextWidgetFinder:<Found 0 widgets with text "P17 Parental gate": []>`.
   Fix belongs in the K03 tests (assert `Grown-ups only`), routed via
   `SHARED_REQUEST.md`. Re-adding the placeholder string to the view is not an
   option: it is not design copy and it breaks P17's own copy test.
2. **34 pre-existing on HEAD, other features' screens** (not P17, not mine to
   edit — no edits made to them): `kid_home` K03 layout matrix light/dark
   320/390/430 @1.0/1.3 overflow, K03 typography/shapes/copy pins, K03 bottom
   edge + a11y probes, `k03_bugs` edge-case probes; `approvals` P11 copy +
   semantics; `today` P08-B11 period scoping (both cases).

So the stage's "full suite passes" gate is not met — 41 red, 7 of them
introduced here (blocked on a cross-feature test the loop owns) and 34 already
red at HEAD. Analyze is clean and P17's own suite is fully green.

## Tails

`dart format .`

```
Formatted 489 files (0 changed) in 1.29 seconds.
```

`flutter analyze`

```
Analyzing app...
No issues found! (ran in 11.0s)
```

`flutter test test/features/parental_gate`

```
00:05 +38: .../parental_gate_geometry_test.dart: modal frame and children match the spec — dark
00:05 +38: All tests passed!
```

`flutter test` (whole app)

```
00:56 +2414 ~1 -41: Some tests failed.

Failing tests:
  app/test/features/approvals/approvals_view_states_test.dart: P11 approvals — copy the child quote is announced next to the card summary
  app/test/features/approvals/approvals_view_states_test.dart: P11 approvals — copy the screen uses the design's exact characters
  app/test/features/approvals/approvals_view_states_test.dart: P11 approvals — semantics each card announces one summary label, buttons stay live
  app/test/features/approvals/approvals_view_test.dart: P11 approvals screen title, helper copy and the three seeded cards
  ... and 37 more
```

(`~1` is one pre-existing skip; 2414 passed.)

## Notes for the next stage

- No simulator was booted by this stage. The `Center`/`LayoutBuilder` wrapper
  above `NestModal` is where 5_ui adjusts a uniform vertical shift if the modal
  band does not match the design's `y ≈ 66…778`; everything inside the card is
  token-exact and asserted by `parental_gate_geometry_test.dart`.
- `presentation/widgets/parental_gate_placeholder_card.dart` is now unused
  (no references in `lib` or `test`). Left in place — deleting it buys nothing
  and is not this stage's call.

VERDICT: FAIL
