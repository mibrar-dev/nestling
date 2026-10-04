# K01 · Who's playing? — Stage 3 (TEST, iteration 2)

Route `/who-is-playing` · feature `kid_home` · branch `screen/K01` · base
`e195954` (main merged, iteration-2 build). No production code edited: every
finding is recorded, not patched (RULES §1 keeps this stage inside
`app/test/features/kid_home/**` and `docs/screens/K01/**`).

**Headline:** iteration 1's BUG-A (the title apostrophe) is **fixed and green** —
`k01_copy_parity_test.dart` went 11/2 → **13/13** with no test edit, exactly as
promised. D1/D2, BUG-1 and BUG-2 are verified and now pinned. One new real bug
is confirmed (K01-BUG-6, found independently and already filed by stage 6), and
one open finding is **re-classified**: K01-BUG-3's repro is a harness artifact,
so what is really left there is a latent race plus dead code, not a dead tile.

## 1. Tests added this iteration (16)

| File | was → is | Added |
|---|---|---|
| `k01_profile_picker_geometry_test.dart` | 4 → **8** | +4 D1/D2 vertical-rhythm pins (real bundled fonts) |
| `k01_profile_picker_matrix_test.dart` | 46 → **58** | +12: drained-navigation group (5), 3+ children (4), KID BACKGROUND (3) |
| `k01_bloc_paths_test.dart` | 19 → **20** | +1 parked K01-BUG-6 reproducer at the bloc's root cause |
| `k01_copy_parity_test.dart` | 13 → 13 | unchanged — BUG-A fixed by the view, not by the test |
| `k01_copy_fit_test.dart` | 7 → 7 | unchanged |

### 1.1 D1/D2 — the vertical rhythm is now pinned to the design PNG

Design values read from `design/screens/light/K01-profile-picker.png` ÷3 as
first/last dark ink rows (±0.5 anti-alias), asserted at ±2 px:

| Element | Design | App | Δ |
|---|---|---|---|
| title line box | 123…157 | 123…157 | 0 |
| sub line box | 173…199 | 173…199 | 0 |
| tiles band (border box) | 288.5…648.5 | 288.5…648.5 | **0** |
| caption box | 738…778 | 738…778 | **0** |
| gap below the caption | 32 + 34 (`--s8` + `--home-h`) | 32 + 34 | 0 |

Iteration 1 measured +16.5 / +34 and derived the cause in §4 of that report:
`NestHomeIndicator` reserves nothing in-app (P01 BUG-2) while the design's
`.screen.kid` reserves `--home-h: 34`, and the `flex: 1` band centres the
difference. The build's fix (a `SizedBox(NestDevice.homeH)` under the caption)
lands the band on the design to within 0.5 px, which is what my iteration-1
arithmetic predicted (288.5). The pins are now in the suite so a future
regression of either number fails immediately.

### 1.2 The harness correction that matters most

A tile tap is `await repository.setActiveChild(...)` then the bloc's `emit`, and
that write is **real Drift I/O**. `tester.pump` advances only the fake clock, so
without draining real async the future never completes, **no state is ever
emitted, and every tile looks dead** — for reasons that have nothing to do with
the screen. Measured on this build:

| Sequence | undrained (`pump` only) | drained (`runAsync` + `pump`) |
|---|---|---|
| states emitted | **1** (`maya`) | 4 (`maya, null, maya, null`) |
| tap Maya → back → tap Maya | no navigation | `/kid-pin` |
| tap Leo after back | no navigation | `/kid-home` |

`k01_profile_picker_matrix_test.dart` now has a `_settleAfterWrite` helper and a
group, *navigation that depends on the DB write*, whose five tests all go
through it. Green 5/5 repeat runs. Every navigation assertion in that file that
depends on the write was moved onto it.

## 2. Re-classified finding — K01-BUG-3 is not what the parked test says

`6_bugs.md` (iteration 2) lists K01-BUG-3 as **STILL OPEN, major**, with the
repro "tap Maya → `/kid-pin` → back → `selectedProfileId` is still `'maya'` →
tap Maya again → nothing happens", re-confirmed on `e195954`.

**That repro is a harness artifact.** The undrained row of the table above is
exactly it. With the write drained the picker's one-shot IS cleared — by the
`app_state` watch, which re-emits on the `UPDATE` that `setActiveChild` always
issues — and the repeated tap navigates again, 5 runs out of 5.

What is genuinely true, and what I would keep open:

1. **`KidHomeSelectionHandled` is dead code** (I agree with stage 6). `grep` finds
   the event, the handler (`kid_home_bloc.dart:154`), `copyWithSelectionHandled()`
   and three doc-comments that say the picker "dispatches" it — and no call site
   anywhere. So the intended fix was never wired.
2. **The one-shot's clearing is a race**, not a guarantee. It relies on the
   `app_state` re-emission landing *after* the selection emit. Observed order is
   always `sel → null` here; if a platform ever delivers them the other way round,
   `copyWithLoaded` clears first and `copyWithSelection` re-arms, leaving the
   tile dead. Dispatching `KidHomeSelectionHandled` after the push removes the
   dependence entirely — which makes that one-line call still the right fix, just
   for a different (and less dramatic) reason than "the tile is dead today".

So: **keep the fix, downgrade the severity, drop the repro.** The parked
`K01-BUG-3` proof in `k01_bugs_test.dart` should be replaced by the drained form
now in `k01_profile_picker_matrix_test.dart` (group *navigation that depends on
the DB write*, first test), which is green and states the same contract.

## 3. New real bug confirmed — K01-BUG-6 (major)

Found independently before reading stage 6's report; the mechanism and the
numbers agree exactly (`opened maya (/kid-pin) but persisted leo`).

**Files:** `app/lib/features/kid_home/presentation/views/profile_picker_view.dart:39`
(`if (_navPending) return;` — inside the `BlocListener`) and
`app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart:159-171`
(`_onProfileSelected` has no in-flight guard).

**Repro (deterministic, 3/3):** two fingers down on Maya and Leo before either
up → top route `/kid-pin` (Maya, `pinSet`) while `app_state.activeChildId` is
`'leo'`. The view single-flights the **navigation**; the bloc still runs
**every** `setActiveChild`. The user is asked for Maya's PIN and then lands in
Leo's home. Symmetric in reverse order.

**My parked reproducer is at the bloc's root cause**, so the fix has a green
target:
`k01_bloc_paths_test.dart` → *K01-BUG-6: a burst persists only the child whose
route is pushed* (`skip:` with the bug id).

```
flutter test --run-skipped \
  test/features/kid_home/k01_bloc_paths_test.dart --plain-name "K01-BUG-6"
# Expected: ['maya']
#   Actual: ['maya', 'leo']
```

It is written as a plain `test`, **not** a `blocTest`, because `blocTest(skip:)`
takes an `int` RETRY count in bloc_test 10.0.0 — a bug proof there runs and
fails in the green suite instead of parking. Worth knowing before someone parks
the next one there.

The green anchors around it are in `k01_profile_picker_matrix_test.dart`: a
single tap always leaves `activeChildId` on the route's child, and a burst
pushes exactly one route (one Navigator pop returns to the picker).

## 4. Verified fixed (iteration 1's findings)

| # | Evidence (mine) |
|---|---|
| **BUG-A** copy | `k01_copy_parity_test.dart` 13/13 — the title now equals the HTML source byte for byte (ASCII `'`), ages keep U+2013, caption keeps its ASCII hyphen. No test edit was needed. |
| **BUG-1** 3+ children | +4 tests: at 320/390/430 every tile keeps the **two-up** width (167 @390), height ≥ 336, the pet disc stays a circle, and the third child is reachable by horizontal scroll and navigates to `/kid-home` with `activeChildId == 'nina'`. |
| **BUG-2** burst stacking | latch-agnostic detector: one burst, one Navigator pop back to `/who-is-playing`. Green. (Which child *wins* the burst stays a product question, not a stacking question.) |
| **BUG-5** Try again | `the failure card… retry` and `the failure retry is reachable by its semantics tap action` both green. |
| **D1/D2** | §1.1 — 0 px. |
| **D3/D4** meadow | +2 painted-pixel tests: `y=770` is exactly `kidMeadow` (hill-back), `y=843` is exactly `kidHillFront(kidMeadow, surface)` (hill-front), light and dark, with a 34 px OS inset. A flat single hill fails the first probe. |
| **KID BACKGROUND** | +1 structural test: exactly one `KidScope`, and the one `NestMeadow` lives inside it — K01 paints no hills of its own. |

Plus one new invariant nobody had: **after a rejected `setActiveChild`, the next
selection still works** (the `_navPending` latch must be released by the
failure). Green.

## 5. Results

```
flutter analyze                      → No issues found!
dart format test/features/kid_home/  → 0 changed
flutter test test/features/kid_home/ → +326 ~3: All tests passed!
flutter test (whole app)             → +2876 ~4 -0: All tests passed!
```

Per file:

| File | Result |
|---|---|
| `k01_copy_parity_test.dart` | +13 |
| `k01_copy_fit_test.dart` | +7 |
| `k01_profile_picker_geometry_test.dart` | +8 |
| `k01_profile_picker_matrix_test.dart` | +58 |
| `k01_bloc_paths_test.dart` | +20 ~1 |
| `k01_profile_picker_view_test.dart` | +13 |
| `k01_bugs_test.dart` (stage 6's) | +21 ~2 |

The three skips are all parked open-bug proofs: two in `k01_bugs_test.dart`
(K01-BUG-3, K01-BUG-6) and my K01-BUG-6 bloc reproducer. Nothing in the suite
fails. The `quest_library_a11y_actions_test` flake that red the whole suite in
iteration 1 did not recur.

## 6. Bugs found this iteration

- **K01-BUG-6 (major, open, real)** — §3. Confirmed independently; the parked
  reproducer is in my bloc file at the root cause.
- **K01-BUG-3 (re-classified)** — §2. Dead code confirmed; the "dead tile" repro
  withdrawn as a harness artifact; a latent ordering race remains and the fix
  should stay (as belt-and-braces).
- Nothing else. No new copy, geometry, alignment, accessibility, bottom-edge or
  dark-mode defect surfaced at 320/390/430 × light/dark × 1.0/1.3.

## 7. Harness notes for the next stages

- **Drain real async after any tap that writes to the database.** `pump` alone
  makes the whole picker look dead. `k01_profile_picker_matrix_test.dart`'s
  `_settleAfterWrite` is the pattern:
  `await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)))`
  then `_settle(tester)`.
- **`blocTest(skip:)` is an int retry count** (bloc_test 10.0.0), not a marker.
  Park a bug proof with a plain `test(..., skip: '<bug id>')`.
- `testWidgets(skip:)` is `bool` in this SDK too; `test(skip:)` takes a reason
  string. There is no skip-with-reason for widget tests.
- The three italicised constants in `k01_copy_parity_test.dart`, `_title` in my
  matrix file and `_copy` in `k01_copy_fit_test.dart` all carry the ASCII `'`
  now — if a fix ever flips the title back, all three go red together.
- Bottom-edge pixel probes must sample where nothing is painted. At the
  iteration-2 geometry the caption is at 738…778, so `y ∈ {770, 838, 843}` are
  safe and `y ≈ 800` lands on the caption's glyphs.
- `NestMeadow` is mounted by `KidScope`, which sits INSIDE
  `ProfilePickerView`'s build — so "K01 must not mount its own meadow" has to be
  asserted as a COUNT (`find.byType(NestMeadow)` == 1, and it is a descendant of
  `KidScope`), not as "no `NestMeadow` below `ProfilePickerView`".
- **Process note:** stages 4, 5 and 6 have been running in this worktree while
  this stage works; `k01_bugs_test.dart` and `6_bugs.md` changed under me
  mid-pass (stage 6's iteration-2 rewrite landed at 04:15). I touched only my
  four files — the `k01_bugs_test.dart` entry in `git status` is stage 6's own
  rewrite (+168/−65, no `skip:` lines among them), not mine. The
  `zz_scratch_measure_test.dart` scratch that stage 6 flagged as making the
  whole-repo analyze red has been deleted.

## 8. Verdict basis

`flutter analyze` clean, `dart format` clean, and every test I own passes — but
this stage confirmed **K01-BUG-6**, a real defect where the picker single-flights
its navigation while the bloc persists *every* selected child, leaving
`app_state` naming a child whose route was never pushed. It is recorded, not
patched, per the brief, so stage 3 cannot pass.

VERDICT: FAIL