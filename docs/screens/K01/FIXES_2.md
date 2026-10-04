# Fix list after iteration 2

## From 3_test.md
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


## From 4_review.md
# K01 · Who's playing? — Stage 4 QA code review (iteration 2)

Reviewed the cumulative `git diff main...HEAD` after the iteration-2
build (K01-BUG-1..5 fixes, D1/D2 home-reserve, shared kid background).
Analyzer: `No issues found!`. `flutter test test/features/kid_home/`:
307 passed, 2 skipped.

## Findings

1. **major** — K01-BUG-3 is not actually fixed in product code. The
   `KidHomeSelectionHandled` event exists and the bloc consumes it
   (kid_home_bloc.dart:146-157, kid_home_state.dart:105-117), but nothing
   in `lib/` ever dispatches it — `_ProfilePickerViewState`'s selection
   listener (app/lib/features/kid_home/presentation/views/profile_picker_view.dart:35-63)
   pushes the route and never sends the event. The one-shot
   `selectedProfileId` therefore still clears only via a home-stream
   emission, and a repeated tap on the same tile is dropped by the
   `listenWhen: previous.selectedProfileId != current.selectedProfileId`
   guard. Proof: `flutter test --run-skipped --plain-name K01-BUG-3
   app/test/features/kid_home/k01_bugs_test.dart` fails —
   `bloc.state.selectedProfileId` is still `'maya'` after back and the
   second tap never navigates. **Fix:** in the listener, right after
   starting the push, dispatch
   `context.read<KidHomeBloc>().add(const KidHomeSelectionHandled());`
   (the handler keeps navigation out of the bloc), then un-skip the
   proof test. The current unit tests in
   `k01_bloc_paths_test.dart:495/527/556` only dispatch the event by
   hand, which is why suite-green hid this.

2. **minor** — the K01-BUG-5 view-level heal masks the wrong failure.
   `profile_picker_view.dart:80-85` renders `_PickerLoaded` whenever
   `state.status == failure && state.profiles.isNotEmpty`, but the bloc
   deliberately keeps `failure` when the *home* stream died while a
   stale roster is present (kid_home_bloc.dart:171-174 checks
   `state.child == null`, and `_onProfilesReceived` only restores
   `loaded` when `_homeSub != null`). In that case the picker shows the
   roster instead of "Oh no! Pip got lost.". **Fix:** gate the heal on
   the profiles-caused outage only — e.g. expose a
   `KidHomeState.loadErrorFrom`/`profilesFailed` flag from the bloc
   instead of re-deriving it from `profiles.isNotEmpty`.

3. **minor** — skipped proofs are now stale in both directions.
   `k01_bugs_test.dart:341` (K01-BUG-2) still asserts the pre-fix
   double navigation and fails now that `_navPending` works; invert it
   to assert single-flight (one top route) or drop it. K01-BUG-1/4/5
   proofs were converted to passing tests — this one wasn't.
   (`--run-skipped` currently reports exactly BUG-2 + BUG-3 failing.)

4. **minor** — title copy regressed from the plan's curly apostrophe to
   ASCII (`"Who's playing?"`, profile_picker_view.dart:278). All current
   K01 tests and `k01_copy_parity_test.dart` pass because they were
   updated to the fixture's ASCII, but `1_plan.md` §0 and the stage-2
   convention note (P02/P03/P04/P07 all ship U+2019) say the opposite.
   **Fix:** get the explicit orchestrator ruling recorded; whichever
   wins, update `1_plan.md` §0 vs `k01_copy_parity_test.dart` so the
   record stops contradicting itself.

5. **minor** — out-of-scope edit:
   `app/test/design_system/list_row_trailing_test.dart` (formatting
   only) was touched in this branch despite RULES.md §1 limiting K01 to
   `kid_home`. Harmless formatter sweep; fold it into a main update
   instead of this branch.

## Re-verified clean this pass

- K01-BUG-1: `_OverflowTileRow` keeps tiles at the design width
  (`(maxWidth - s4)/2` = 167 @390, 132 @320) and scrolls horizontally;
  the ellipse-clamp defect is gone.
- K01-BUG-4: empty nickname falls back to label `Kid`
  (profile_tile.dart:53-55).
- K01-BUG-5: bloc restores `loaded` via `copyWithProfilesRecovered`
  (kid_home_state.dart:206-221) and clears the stale load error; Try
  again now emits `loading` when the home subscription is still live
  (kid_home_bloc.dart:73-79). Both skipped-proof repro paths pass once
  the view-masking in finding 2 is accounted for.
- Streams cancelled on `close()`; `_profilesFailed` flag cleared on
  every healthy roster; no `DateTime.now()`/`google_fonts`/tracking
  additions; D1/D2 fix uses `NestDevice.homeH` and the shared
  `KidScope`/`kid_meadow` (no local hills — per the new
  ORCHESTRATOR_NOTES); CHILD ORDER and per-child `PipAvatar` intact;
  two-finger navigation single-flighted by `_navPending`.


## From 6_bugs.md
# K01 · Who's playing? — Stage 6 bug hunt (iteration 2)

Adversarial pass over `/who-is-playing` on the iteration-2 build
(`e195954`, main merged). Every proof lives in
`app/test/features/kid_home/k01_bugs_test.dart` and runs against the real
in-memory Drift database (Seed.demo), the real repository, or a
feature-local fake for the failure paths. No screen code was changed by
this stage.

```
flutter test test/features/kid_home/k01_bugs_test.dart
  → +21 ~2: All tests passed!       (2 proofs parked for the open bugs)

flutter test --run-skipped test/features/kid_home/k01_bugs_test.dart
  → 2 deterministic failures: K01-BUG-3, K01-BUG-6
```

## Status of the iteration-1 findings

| # | Severity | Iteration-2 status |
|---|---|---|
| K01-BUG-1 | major | **FIXED and verified** — `_OverflowTileRow` keeps 167 px tiles and scrolls |
| K01-BUG-2 | major | **FIXED and verified** — one burst pushes exactly one route |
| K01-BUG-3 | major | **STILL OPEN** — the new `KidHomeSelectionHandled` event is never dispatched |
| K01-BUG-4 | minor | **FIXED and verified** — blank nickname falls back to `Kid` |
| K01-BUG-5 | major | **FIXED and verified** — profiles retry restores the picker |
| K01-BUG-6 | major | **NEW, open** — the pushed route and the persisted active child disagree |

Also fixed this pass (tracked by the other stages, re-verified here):
5_ui D1/D2 — tiles and caption now sit at the design y (simulator 297.3 /
639.3 / caption ink 747; a widget-level regression probe compares the
corner-corrected design box: design centre 468.8, height 361.8), and the
title apostrophe now matches the HTML source (ASCII `'`).

---

## K01-BUG-3 — major — STILL OPEN — a tile is dead after returning from a kid route

The iteration-2 build added `KidHomeSelectionHandled`, its handler
(`kid_home_bloc.dart:154-159`), `copyWithSelectionHandled()` and updated
comments that say the picker "pushes the route, then dispatches"
`KidHomeSelectionHandled`. **No call site dispatches it.** `grep -rn
"KidHomeSelectionHandled" lib/` finds only the event definition, the state
doc-comment, the state method, and the bloc registration — never
`context.read<KidHomeBloc>().add(...)` in `profile_picker_view.dart` or
anywhere else. The mechanism is dead code.

**Repro (unchanged from iteration 1, re-confirmed on e195954):** Seed.demo
has `activeChildId == 'maya'`. Tap Maya → `/kid-pin`; back to the picker;
the picker's bloc still holds `selectedProfileId == 'maya'` (asserted);
tap Maya again → the path stays `/who-is-playing` — no navigation, no
toast. The equal `copyWithSelection('maya')` is dropped by the bloc.

**Failing test:** `K01-BUG-3: tapping the same tile after back does nothing`
(skipped; the first assertion pins the mechanism, the second the missed
navigation).

**Suggested fix (one line, in the picker's listener):** after
`context.push(...)` starts, dispatch
`context.read<KidHomeBloc>().add(const KidHomeSelectionHandled())` — or
consume the one-shot inside the bloc when the route push is acknowledged.
The bloc half already exists; only the view call site is missing.

## K01-BUG-6 — major — NEW — the pushed route and the persisted active child disagree

The new `_navPending` guard (K01-BUG-2 fix) single-flights the
**navigation**, but both `KidHomeProfileSelected` events still reach the
bloc: each awaits its own `setActiveChild` write and then emits. The first
emission pushes its route and sets the guard; the second emission is
swallowed — **but its write has already landed**, so `app_state` names the
other child. Every selection in the burst writes; only one navigates.

**Repro (deterministic, 3/3 runs):** two fingers down on Maya and Leo
before either up. Top route `/kid-pin` (Maya, whose PIN `1234` the child
would be asked for), `activeChildId == 'leo'`. When K02 finishes its PIN
flow, `watchHome` resolves `app_state.activeChildId` — the kid lands on
Leo's home after authenticating as Maya. The inverse order is symmetric
(`/kid-home` for Leo with `activeChildId == 'maya'`); the tapped route's
child and the persisted child can never agree while both writes run.

**Failing test:** `K01-BUG-6: route child and active child disagree`
(skipped). Measured: `opened maya (/kid-pin) but persisted leo`.

**Suggested fix:** drop the second selection’s **write** together with its
navigation — e.g. a synchronous `bool _selecting` in `KidHomeBloc` set
before the first `await` in `_onProfileSelected` and cleared on
completion/handled/failure, so concurrent events return early; or have the
picker disable all tiles with `IgnorePointer` for the burst. Combine with
the BUG-3 fix so the flag can never wedge.

---

## Iteration-2 regression checks (green, unskipped)

- **BUG-1** (4 proofs): 3 children keep 167 px tiles; 4+ children keep the
  avatar/pet discs circular; 6 children keep 167 px tiles and the row
  scrolls (the 6th tile is off the gutter until dragged, then reachable);
  a scrolled-to extra child (`Omar`) still selects and navigates to
  `/kid-home` with `activeChildId == 'omar'`.
- **BUG-2**: a two-finger burst pushes exactly one kid route and one
  Navigator pop returns to `/who-is-playing`.
- **BUG-5**: profiles-only failure → Try again → the recovered roster
  replaces the failure card and the title renders.
- **D1/D2**: widget probe (real bundled fonts) — tile centre 468.5 vs
  design 468.8, caption box top 738 (simulator ink row 747); 5_ui
  iteration 2 measured the simulator at 297.3/639.3/747 vs 297.7/640.0/747.
- **BUG-4**: an empty nickname renders the tile label `Kid, Age …`
  instead of an empty accessible name.
- **Copy**: the title is now the HTML source's ASCII `"Who's playing?"`
  (en dashes in the ages, ASCII hyphen in `Grown-ups` unchanged).
- Unchanged iteration-1 probes still green: 0 children / 1 child / long
  UK name at 320×1.3 / empty age band / no money or dates / same-tile and
  lock double taps / deep links kid+parent / restart persistence / 16
  contrast pairs / title-sub-caption fit at 320×1.3 / tap semantics.

## Process notes (not K01 findings)

- `app/test/features/kid_home/zz_scratch_measure_test.dart` (untracked,
  another stage's file, header says "deleted before commit") currently has
  one failing/timing-out test and 9 analyzer infos; while it exists, a
  whole-repo `flutter analyze` is red. `k01_bugs_test.dart` itself is
  analyzer-clean (`dart analyze` → No issues found).
- `k01_profile_picker_matrix_test.dart` et al. finished green
  (`flutter test test/features/kid_home/` → +310 ~2 −1, where the single
  failure is the scratch file above and the 2 skips are this file's open
  bugs).

