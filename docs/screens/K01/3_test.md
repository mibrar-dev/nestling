# K01 · Who's playing? — Stage 3 (TEST, iteration 3)

Route `/who-is-playing` · feature `kid_home` · branch `screen/K01` · base
`b9ba00a` (main merged; iteration-3 build: K01-BUG-3 wired, K01-BUG-6 bloc
gate, `profilesFailed`, `1_plan.md` copy correction). No production code
edited — every finding is recorded, not patched (RULES §1 keeps this stage
inside `app/test/features/kid_home/**` and `docs/screens/K01/**`).

**Headline:** iteration 2's K01-BUG-6 and K01-BUG-3 are **fixed and green**, and
the two previously-parked proofs in `k01_bugs_test.dart` now run live and pass.
I added 4 tests for the code paths the iteration-3 build introduced, found **no
new reachable defect**, and independently reached the one latent hardening hole
in the new guards — which stage 6 filed concurrently as **K01-BUG-7 (minor,
latent)** with a better-layered proof than mine, so I removed my duplicate.

## 1. Tests added this iteration (4)

| File | was → is | Added |
|---|---|---|
| `k01_profile_picker_matrix_test.dart` | 58 → **62** | +4 covering the iteration-3 `_select` gate |
| `k01_bloc_paths_test.dart` | 23 → **23** | net 0: wrote a latent-risk proof, then **removed it** — see §5 |
| `k01_profile_picker_geometry_test.dart` | 8 → 8 | unchanged |
| `k01_copy_parity_test.dart` / `k01_copy_fit_test.dart` / `k01_profile_picker_view_test.dart` | 13 / 7 / 13 | unchanged |

Everything the iteration-2 report promised as a regression pin is still green:
D1/D2 vertical rhythm (0 px), BUG-A copy parity, the two-tone meadow, the
overflow row, and the drained-navigation group.

### 1.1 The iteration-3 guard, exercised in its risky orderings

The build moved the single-flight out of the `BlocListener` into `_select`
(armed **before** the dispatch) and added a matching `selectedProfileId` gate in
the bloc. Two guards that both "drop" events are exactly the shape that wedges
when they disagree, so the new tests are about **orderings**, not single taps:

| Test | What it pins |
|---|---|
| *a burst right after a completed round-trip still writes once* | tap → back → **burst**: `_busy` and the one-shot are both back to their post-pop state; the second burst must still navigate and persist exactly the routed child. This is the ordering where an unreleased latch shows up. |
| *a burst after a rejected write still writes once* | a failed `setActiveChild` releases `_busy` via the toast path; the next burst must be fully applied, not half-applied. |
| *a burst on the overflow row persists only the routed child* | 2b noted both rows now route through `_select`, but **nothing proved the 3+ children row does**. A burst with three tiles must push one route, persist one child, and one Navigator pop must return to the picker. |
| *a scrolled-in overflow tile is still a 56px accessible button* | ACCESSIBILITY rule on new UI: a tile that only exists after a horizontal scroll still has `SemanticsAction.tap` and a ≥56 px target. (An off-stage control has **no** semantics node — a K03 iteration-1 lesson — so the test scrolls it in first.) |

`_burst` and `_routeChild` were generalised in the matrix file so a burst can
name any set of children and the route's owning child is derived from the
design's own contract (`pinSet ? /kid-pin : /kid-home`) rather than hard-coded
per test.

## 2. Re-verified — every earlier finding

| # | Status | Evidence |
|---|---|---|
| **BUG-A** copy | fixed | `k01_copy_parity_test.dart` 13/13 — title byte-identical to the HTML source (ASCII `'`), ages U+2013, caption ASCII hyphen |
| **BUG-1** 3+ children | fixed | 320/390/430 two-up width, discs circular, third child reachable + navigates, overflow-row burst (§1.1) |
| **BUG-2** burst stacking | fixed | one pop returns to the picker, on both rows |
| **BUG-3** dead tile after back | fixed | `k01_bugs_test.dart` "K01-BUG-3 regression" now un-skipped and passing; my drained equivalent in the matrix group also green |
| **BUG-4** empty nickname | fixed | stage 6's proof green |
| **BUG-5** Try again | fixed | failure → retry → roster green |
| **BUG-6** route child ≠ persisted child | fixed | stage 6's proof un-skipped and passing; my ordering tests (§1.1) green |
| **D1/D2** vertical rhythm | fixed | geometry pins 288.5 / 738 / 32+34, ±2 px |
| **D3/D4** meadow | fixed | `y=770` = hill-back, `y=843` = hill-front, light + dark |
| **5_ui** iteration 3 | **PASS** | "no visible deviation a designer would reject" — agrees with my geometry pins |

## 3. Results

```
flutter analyze                      → No issues found!
dart format test/features/kid_home/  → 0 changed
flutter test test/features/kid_home/ → +336 ~1: All tests passed!
flutter test (whole app)             → +2886 ~2: All tests passed!
```

| File | Result |
|---|---|
| `k01_copy_parity_test.dart` | +13 |
| `k01_copy_fit_test.dart` | +7 |
| `k01_profile_picker_geometry_test.dart` | +8 |
| `k01_profile_picker_matrix_test.dart` | +62 |
| `k01_bloc_paths_test.dart` | +23 |
| `k01_profile_picker_view_test.dart` | +13 |
| `k01_bugs_test.dart` (stage 6's) | +23 ~1 |

The single skip is stage 6's parked **K01-BUG-7** proof (§5).

One note on the run itself: an early full-suite run reported a failure in
`pocket_money/pocket_money_setup_view_geometry_test.dart` (P06 — another
screen's file). It passes in isolation and did not recur in three subsequent
full runs, so it was a flake from stages 4/5/6 editing the tree concurrently,
not a K01 regression.

## 4. Bugs found this iteration

**None.** No new reachable defect in the screen at 320/390/430 × light/dark ×
text scale 1.0/1.3, across copy, geometry, alignment, accessibility, tap
targets, routing, the three non-loaded states, or the shared background.

## 5. The one latent hole (not filed as a K01 bug — stage 6 owns it as K01-BUG-7)

The iteration-3 build introduced two "drop the event" guards:

- `ProfilePickerView._select` arms `_busy` **before** dispatching
  (`profile_picker_view.dart:38-44`), released on the push's `whenComplete` or
  by the failure toast.
- `_onProfileSelected` returns early while `selectedProfileId` is pending
  (`kid_home_bloc.dart:172-176`).

There is one window where both stay armed: the listener resolves the pending
profile against `state.profiles` and, if the id is **not there**, returns at
`profile_picker_view.dart:61-64` **without** dispatching
`KidHomeSelectionHandled`. The one-shot stays set, the bloc gate then drops
every later selection, and `_busy` was re-armed by the tap that got dropped —
the picker is dead with no feedback.

I reached this independently before reading stage 6's file, and wrote a proof
for it, then **deleted my proof**:

- it belongs to **stage 6's** bug-file and their bug id;
- more importantly, a **bloc-level** proof is the wrong layer to pin green. The
  fix is in the view (clear the one-shot on the not-found branch too, or don't
  arm `_busy` until the id resolves), so my proof would have stayed red after
  the correct fix landed. Theirs — `k01_bugs_test.dart`, *K01-BUG-7: an
  orphaned selection locks every tile* — drives the real view and goes green on
  the real fix.

Severity **minor / latent** is right: the view only ever dispatches an id it
just read off the roster, so the trigger needs the roster to change between a
tap and the listener (a parent editing the family, or the next sync/import/roster
write). No shipped flow does that while K01 holds a selection.

I left a short comment at that spot in `k01_bloc_paths_test.dart` pointing at
K01-BUG-7 so the next reader knows the case exists and why it is not pinned
here.

## 6. Also checked, clean

- **Copy** — `k01_copy_parity_test.dart` reads the HTML source (never
  transcribed) and compares byte-for-byte: title ASCII `'`, `Age 7–9` /
  `Age 4–6` with U+2013, caption with its ASCII hyphen, lock `aria-label`, both
  pet `alt` texts. `1_plan.md` §0 now agrees with the source, so the
  plan-vs-test contradiction from iteration 1 is closed.
- **Letter spacing** — every rendered string asserts `0`.
- **CHILD ORDER** — tiles render `state.profiles` in repository creation order;
  the 3-child tests place `Nina` last and find her last.
- **PIP** — per-child `PipAvatar` from the DB row, no `pip_stage_*.svg`.
- **KID BACKGROUND** — exactly one `KidScope`, and the single `NestMeadow` lives
  inside it; K01 paints no hills of its own.
- **Bottom edge** — no bar on this screen; the meadow reaches the physical edge
  with a 34 px OS inset, light and dark.
- **CLOCK / FONTS** — no `DateTime.now()`, no `google_fonts`, in feature code
  or feature tests.
- **`profilesFailed`** — stage 4 finding 1 (write-only in product code) is real
  but not a test-stage item; 2a's two tests pin set/clear and constructor
  behaviour, and the field is in `props`, so equality is honest either way.

## 7. Harness notes for the next stages

- **Drain real async after any tap that writes to the database.**
  `tester.pump` alone never completes the Drift `setActiveChild` future, so no
  state is emitted and the whole picker looks dead. Pattern:
  `await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)))`
  then pump — `k01_profile_picker_matrix_test.dart`'s `_settleAfterWrite`. Both
  my iteration-2 report and 2b's notes needed this; it is now the house pattern.
- **`blocTest(skip:)` is an `int` RETRY count** (bloc_test 10.0.0), not a
  marker — a bug proof parked there runs and fails in the green suite. Use a
  plain `test(..., skip: '<bug id>')`, which takes a reason string.
  `testWidgets(skip:)` is `bool` in this SDK; there is no skip-with-reason for
  widget tests.
- Bottom-edge pixel probes must sample where nothing is painted. At the
  iteration-3 geometry the caption is at 738…778, so `y ∈ {770, 838, 843}` are
  safe and `y ≈ 800` lands on the caption's glyphs.
- `NestMeadow` is mounted by `KidScope`, which sits **inside**
  `ProfilePickerView`'s build — "K01 must not mount its own meadow" has to be a
  COUNT (`find.byType(NestMeadow)` == 1, and a descendant of `KidScope`), not
  "no `NestMeadow` below `ProfilePickerView`".
- A tile's name/age/pip semantics **merge into the tile button node**, so
  `getSemantics(find.text('Maya'))` returns the button. Assert "no tap action"
  only outside a control; assert the tile's label and `isButton` instead.
- Off-stage controls have no semantics node — scroll a control into view before
  asserting or performing its semantics action.
- **Process note:** stages 4, 5 and 6 ran concurrently again this iteration
  (`k01_bugs_test.dart`, `4_review.md`, `5_ui.md` all changed under me). I
  touched only my three files and left `k01_bugs_test.dart` to stage 6.

## 8. Verdict basis

`flutter analyze` clean, `dart format` clean, every test in the app passing
(`+2886 ~2 −0`), every K01 finding from the previous two iterations verified
fixed, and **no new bug found** this iteration. The one latent hardening hole in
the new guards is recorded, correctly rated, and already owned by stage 6 as
K01-BUG-7 with a proof at the right layer — it is not a reachable defect and not
mine to re-file. Stage 3 passes.

VERDICT: PASS