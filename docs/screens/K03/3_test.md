# K03 Kid home — Stage 3 (TEST), iteration 7

Scope: `kid_home` / `/kid-home`, kid mode. Tests in
`app/test/features/kid_home/` (`kid_home_bloc_test.dart`,
`kid_home_view_test.dart`, `k03_bugs_test.dart`, plus the build's parked
`kid_home_geometry_test.dart`). Per RULES §1 this stage only touched
`app/test/features/kid_home/**` and `docs/screens/K03/**` — **no screen code was
patched**.

**No simulator was booted, installed on or captured** (SIMULATORS rule: only the
UI-check stage may, and only `E7D5555E-…`).

## Verification run (in `app/`, this iteration)

- `dart format --set-exit-if-changed .` → **381 files, 0 changed**.
- `flutter analyze` → **No issues found!** (the scratch probe that made
  iteration 6's analyze red is gone; `analysis_options.yaml` untouched; no new
  suppressions).
- `flutter test` (whole app) → **exit 1, `+1160 ~6 -1`** — 1160 pass, 6 skip,
  **1 fail**.
- `flutter test test/features/kid_home/` → **exit 1, `+143 ~6 -1`** — 143 pass,
  6 skip, **1 fail**.

The single failure is this stage's new K03-BUG-15 proof. The 6 skips are all
parked-pending-shared items (3 × K03-BUG-13's width loop, K03-BUG-14, the bugs
stage's parallel finding-6 proof, and the build's geometry test) — see
"Parked proofs" below.

| File | Iteration 6 | Now |
| --- | --- | --- |
| `kid_home_view_test.dart` | 63 | **71** (+8, all pass) |
| `kid_home_bloc_test.dart` | 26 | **27** (+1 proof, fails: K03-BUG-15) |
| `k03_bugs_test.dart` | 43 pass + 4 fail (parked) | parked, +2 passing probes from the bugs stage |
| `kid_home_geometry_test.dart` | — | new, parked (build stage) |

## What the iteration-7 build changed (the surface under test)

The build closed review findings 1, 3, 4, 5 and 8:

1. **`NestBalancedText` for the section heading** (`kid_home_view.dart:483`) —
   review finding 4, and it finally makes the BALANCED HEADINGS rule satisfiable
   (the component landed on main; `Text` → `NestBalancedText` for
   `.kid-title "Today's quests"`, same copy, `NestType.kidTitle`, `maxLines: 2`,
   `textAlign: TextAlign.start`).
2. **`NestKidButton(wrapLabel: false)` on all three dock buttons**
   (`:593`, `:614`, `:635`) — review finding 5 / SHARED_REQUEST #9. The label
   now renders `softWrap: false, maxLines: 1` inside a `FittedBox(scaleDown)`.
3. **Per-quest tile tints** (`:836`, `tileBackground:`) — review finding 5 /
   SHARED_REQUEST #1: `dishwasher → skyTint`, `book → lilacTint`,
   `bed → peachTint`, anything else keeps the shared `surface2` default. This
   closes a drift this suite had carried as "accepted" since iteration 1.
4. **Hearts caption 2 px inset** (`:455-456`) — review finding 8
   (`margin-left: 2px` in `K03-kid-home.html:58`).
5. **A parked real-font geometry test** (`kid_home_geometry_test.dart`) pinning
   the orchestrator's 07:40 targets — verified: nest centre x 195 ±1, nest box
   236 ±2 (the box that paints the design's 198 px visible outline, ratio 0.84),
   Pip centre 195, hearts centre y 448 ±2, first card top 559 ±2, and the stage
   box inside the 20…370 gutters. Its numbers match the note and the
   SHARED_REQUEST #13 table.

## Tests added (this stage)

### `kid_home_view_test.dart` — new group `K03 iteration-7 chrome`

1. **`the .kid-title heading renders through NestBalancedText`** — the heading
   is a `NestBalancedText` carrying `"Today's quests"`, 28 px w900,
   `maxLines: 2`, `TextAlign.start`, tracking 0, still on the left gutter, and
   it is the **only** balanced text on the screen (the rule forbids it on
   body/caption copy).
2. **`dock labels stay on one line at 320px/1x, 390px/1.3x, 320px/1.3x,
   430px/1x`** (4 tests) — the three dock buttons keep equal heights and each
   label is `maxLines: 1, softWrap: false`. This is the comparison iteration 5
   had to skip: the fallback test font used to wrap "My jar" (80 vs 72 px), so
   button heights could not be compared.
3. **`the dock does not grow when the viewport narrows`** — the dock surface is
   the same height at 430 and 320, so no label wraps.
4. **`quest tiles carry the design per-quest tint`** — rendered tile colours:
   `Empty the dishwasher → skyTint`, `Reading – 20 minutes → lilacTint`,
   `Tidy your bedroom → peachTint`, `Hoover the stairs → surface2`
   (unmapped icon), each tile still 48×48.
5. **`the hearts caption keeps the design 10 px gap`** — the gap after the
   fifth heart is the row's 8 px plus the design's 2 px inset.

### `kid_home_bloc_test.dart` — new proof

6. **`K03-BUG-15: a retry must not stack a second live subscription`** — the
   review's exact invariant. It fails; see below.

## Bugs found

### K03-BUG-15 [moderate, OPEN, in scope] — retrying a load stacks live subscriptions

Review finding 6 (iteration 6), left open by the iteration-7 build and handed
to "the next bloc owner".

**Where:** `app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart:29`
(`await emit.forEach<KidHomeData>(_repository.watchHome(), …)`) reached from
`app/lib/features/kid_home/presentation/views/kid_home_view.dart:287` (the
failure state's "Try again" button dispatches `KidHomeLoadRequested` again).

**Cause:** `emit.forEach` over `watchHome()` never completes and the bloc's
default event transformer is concurrent, so every tap on "Try again" starts
another never-ending handler while the previous one is still subscribed. Each
one holds a live fan-out of the Drift watch queries (child row + quests +
completions) until the bloc itself closes.

**Measured:** three load dispatches → `activeChildSubscriptions == 3`
(expected 1); the same holds for `itemsSubscriptions`.

**Repro:**
```
cd app && flutter test test/features/kid_home/kid_home_bloc_test.dart --plain-name K03-BUG-15
```
→ `Expected: <1>  Actual: <3>`.

**Suggested fix** (the review's own smaller alternative, which the build
recommends over the full event refactor): early-return in `_onLoadRequested`
while a subscription is live — e.g. keep a `StreamSubscription<KidHomeData>?`
and cancel it at the top of the handler, or guard with a `_streaming` flag.

**Overlap note:** the iteration-7 bugs stage wrote a parallel proof for the same
review finding and parked it (`k03_bugs_test.dart:1350`, `skip: true`). I left
their file untouched and kept mine un-skipped, because the fix is in K03's own
scope and RULES forbid skipping a proof to keep the suite green. Either proof
fails until the guard lands.

### Parked proofs (shared-blocked, not new this iteration)

- **K03-BUG-13** (pet slot +34.7 px off-centre at 390, +69.7 at 320 with a
  59.7 px clip, +14.7 at 430) and **K03-BUG-14** (pet block 276 px vs the
  design's 236, pushing the lower stack down) — the orchestrator's 07:40 note
  confirms the root cause and that size vs centring are mutually exclusive with
  the shared stage ratio (0.62). SHARED_REQUEST #13 carries the arithmetic and
  the design targets; the build followed "write the request and stop".
  Repro when needed: `flutter test --run-skipped --plain-name "K03-BUG-1[34]"`.
- **Speech bubble 46 px vs the design's 35 px** — SHARED_REQUEST #15, shared.
- **`switchMapStream` living in the domain layer** (review finding 7) —
  architecture nit, shared (`core/data/stream_combine.dart` owns the combinators);
  the helper itself is covered by four tests in the bloc suite.

## Closed since iteration 6

Review findings 1 (the failing cross-frame double-tap test), 3 (the scratch
probe file — `flutter analyze` is clean again), 4 (`NestBalancedText`), 5
(`tileBackground` + `wrapLabel`) and 8 (the hearts caption inset) are all closed
and now pinned by tests. K03-BUG-7 (motion flag) and K03-BUG-12 (child order)
stay closed.

## Owner rules re-checked

- **BOTTOM EDGE:** the K03-BUG-10 proofs (light + dark, 34 px inset) still pass
  — the dock surface runs to the physical edge with no coloured strip, and the
  meadow ends at the dock's top border in both themes.
- **ALIGNMENT:** gutters, shared card/bar edges and the 3 px dock border pass.
  The dock is now *more* verifiable: with `wrapLabel: false` the three buttons
  keep equal heights at every width/scale, which removes the font artifact this
  report carried in iterations 1–6 ("dock button heights are not compared").
  The remaining misalignment is still the shared pet slot (K03-BUG-13).

## Rule coverage

| Rule | Status on K03 |
| --- | --- |
| BALANCED HEADINGS | **Now covered**: `.kid-title` renders through `NestBalancedText`, and no other copy uses it |
| CHIP ROWS (`NestChipWrap`) | Not applicable: K03's chips are the non-interactive `KidStatusChip`; no interactive `NestChip` row here |
| FONTS | No `google_fonts` / `GoogleFonts` in the feature or its tests; `flutter analyze` clean |
| LETTER SPACING | Pinned: every rendered K03 string asserts `letterSpacing == 0`, including the balanced heading |
| UI CHECK MEASURES SHAPES | Extended: dock label boxes, tile rects + tints, chip pill, card tile and check (all measured as background/border rects) |
| CHILD ORDER | No child list on this screen; pinned at the repository level (K03-BUG-12) |
| COPY | Re-verified: the K03 HTML source has 0 curly / 4 straight apostrophes; the app matches; no tracking/quote drift |
| TRIAL | No test writes `subscription_status` |
| PERIODS / DATA OVER MOCKS | Unchanged and green (counts come from the DB: "4 done today", "4 of 6 done") |
| SIMULATORS | None booted by this stage |

## Harness notes (unchanged from iteration 6)

- Direct Drift work inside `testWidgets` must run inside `tester.runAsync`;
  bottom insets are emulated via `tester.view.padding` / `viewPadding` at 3×
  physical px; never `pumpAndSettle` while a loading spinner is on screen;
  card assertions after a celebration need `tester.pageBack()`.
- Seed the DB **before** pumping: a Drift write in `runAsync` after the app is
  pumped does not repaint the screen in the fake-async harness (`quest_completions`
  writes do propagate, `app_state` writes did not in the probe), so tests that
  change children/quests write first and pump the route fresh.
- The section title wraps to two lines in the fallback test font, so the
  section→progress gap is asserted as `>= 16` rather than exactly; real-font
  geometry lives in the build's `kid_home_geometry_test.dart` instead.

VERDICT: FAIL
