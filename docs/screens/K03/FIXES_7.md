# Fix list after iteration 7

## From 3_test.md
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


## From 4_review.md
# K03 Kid home — QA code review (Stage 4, iteration 7)

Scope: feature `kid_home`, route `/kid-home`, kid mode, design (light + dark)
`design/screens/{light,dark}/K03-kid-home.png`. Reviewed `git diff main...HEAD`
**plus the current working tree**, so the verdict reflects the code as it
stands. Per the orchestrator rules, uncommitted work / being behind `main` /
merge order are not findings and are not reported.

## Gates run (in `app/`, this iteration)

| gate | command | result |
|---|---|---|
| format | `dart format --set-exit-if-changed --output=none .` | ✅ `Formatted 391 files (0 changed)` |
| analyze | `flutter analyze` | ✅ `No issues found!` — **but** at `HEAD` it reported 1 issue; fixed only in the working tree while this review was running (finding 2) |
| test | `flutter test` | ❌ **`+1160 ~6 -1: Some tests failed`** (full suite); feature-suite re-run `+143 ~6 -1` — one failure: `kid_home_bloc_test.dart: K03-BUG-15: a retry must not stack a second live subscription` (finding 1) |
| geometry (own) | pixel measurement of the committed captures with PIL, ÷3 to logical px | see findings 3 and 4 |
| skipped proofs | 6 parked (`K03-BUG-13` ×320/390/430, `K03-BUG-14`, `K03-BUG-15` in `k03_bugs_test.dart`, the geometry pin) | see finding 5 |

One of the three done-criteria gates (RULES §7.1) is red, and the reported
iteration-7 build verification is not reproducible: `2_build.md:186-191` claims
`flutter test` → `+1149 ~5: All tests passed!`, while the same command at HEAD
fails.

## Verified clean (no finding)

- **RULES §1 paths** — the diff and the working tree touch only
  `app/lib/features/kid_home/**`, `app/test/features/kid_home/**`,
  `docs/screens/K03/**`. No `core/`, no `app/`, no other feature, no
  `tools/screens/`, `analysis_options.yaml` untouched.
- **ARCHITECTURE** — feature-first; `domain/` = `kid_child`, `kid_quest`,
  `kid_home_data` entities + the abstract repository; one bloc for the feature;
  `kid_home_di.dart` / `kid_home_routes.dart` / `kid_home.dart` untouched from
  the foundation. Only finding 8 contests the domain layer, for a reason
  already requested in SHARED_REQUEST #14.
- **PIP rule** — every Pip on this screen is the active child's own
  `PipAvatar` fed from the DB row (`kid_home_view.dart:258, 703, 875`),
  `style/skin/accessory/stage` via `_pipStyle/_pipSkin/_pipAccessory`; no
  `pip_stage_*.svg`, no `PipRive`, no `riveEnabled` in the feature. The
  failure and empty states also show the known child's Pip.
- **PERIODS ruling** — `countsForCurrentPeriod` applied on the read path
  (`kid_home_repository_impl.dart:80-83`) and inside the write transaction
  (`:158-183`) with the family zone (`createdAtTz: Value(zone)`); the
  daily/weekly/once and London day/week proofs run un-skipped.
- **COPY** — `K03-kid-home.html` contains **zero** U+2019 (verified again
  this iteration), so the screen's straight `'` in `Let's do some quests!`,
  `Today's quests`, `Waiting for Mum`, `Mum's thumbs-up` is correct; the
  design's `&ndash;` is a real U+2013 and the seed title
  (`core/data/seed.dart:279`) carries exactly that. No curly quotes anywhere
  in `lib/features/kid_home/` (grep). UK spelling, coins only (never `£`).
- **CHILD ORDER** — `watchProfiles()` (`kid_home_repository_impl.dart:98-102`)
  passes the shared `watchChildren` (now `createdAt`-ordered) straight
  through, no local re-sort; the six-children probe runs un-skipped.
- **Bottom edge (owner rule)** — measured on the committed captures at x=30 and
  x=360: light `#FFFFFF` and dark `#1F1C2E` from logical y 722 to 843 with no
  meadow/sky strip and nothing coloured around the home indicator. The dock
  `SafeArea(top: false)` inside the surface box (`kid_home_view.dart:552-557,
  642`) is the right shape.
- **Gutters / alignment outside the pet chain** — the header, section row,
  cards and dock all use `NestSpacing.padSide` (20). Measured on the committed
  captures at y=760: dock buttons design `20.0…128.7 / 141.0…248.7 /
  261.0…369.7`, app `20.0…128.3 / 140.7…249.0 / 261.3…369.7` (≤0.5 px
  everywhere); dock top border 719 in both.
- **Design-system usage** — no hex colours, no hard-coded `Colors.*`, no
  `google_fonts`/`GoogleFonts`, no `letterSpacing` overrides, no
  `// ignore:`/`ignore_for_file:` anywhere in the feature (grep); the section
  heading now renders through `NestBalancedText` (`:483`) as the BALANCED
  HEADINGS rule requires, with the left edge preserved (`textAlign: .start`);
  tile tints (`tileBackground`) and `wrapLabel: false` are used;
  `KidStatusChip` (`widgets/kid_status_chip.dart`) is a justified leaf —
  the shared `NestChip` is parent-mode Inter 14 with a leaf border, while
  `.kchip` is Nunito 800 15/15 on `leaf-tint` with no border.
- **Accessibility** — `NestLockButton` 56 px, quest check 28 px ring + 8 px
  padding = 44 px, hearts/pet-stage/progress/header carry composed `Semantics`
  labels, dock labels pinned to one line at 1.3×, no raw error string is shown
  to a child (the toast is fixed copy). New iteration-7 tests assert all of it.
- **Children's Code** — no analytics, ads, SDK, network or `print` in the
  feature; only nickname, coins, happiness and Pip look of the **active**
  child are read, and nothing is written outside the child's own completions.
- **Trial rule** — no `subscription_status` write or read in the feature.
- **Quest order** — the repository sorts by title
  (`kid_home_repository_impl.dart:72-73`), which is also the design's order
  (dishwasher → reading → tidy), so the visible list matches.

---

## Findings

### 1. [blocker] `flutter test` is red: the new `K03-BUG-15` proof fails, and the product defect behind it is still unfixed

`app/test/features/kid_home/kid_home_bloc_test.dart:808` (assertion at `:821`):

```
Expected: <1>
Actual: <3>
the child row must be watched once per load; every extra handler keeps a whole watch fan-out alive
```

Reproduce: `flutter test test/features/kid_home/kid_home_bloc_test.dart --plain-name "K03-BUG-15"`.

The defect is in the bloc, not the test: `_onLoadRequested`
(`kid_home_bloc.dart:22-68`) awaits `emit.forEach(_repository.watchHome())`,
which never completes, and the bloc's default transformer is concurrent, so
every `KidHomeLoadRequested` starts another never-ending handler with its own
fan-out of Drift watch queries (one `app_state` + one `children` row + quests /
completions / family-zone). Three loads → three live subscriptions, none
cancelled until the bloc closes. The "Try again" button
(`kid_home_view.dart:286-288`) is the reachable path: each tap on the failure
card adds one.

Fix (in scope — this is the review's own smaller alternative, iteration-6
finding 6):

```dart
StreamSubscription<KidHomeData>? _home;

Future<void> _onLoadRequested(KidHomeLoadRequested e, Emitter<KidHomeState> emit) async {
  if (_home != null) return;              // a load is already live
  emit(state.copyWith(status: KidHomeStatus.loading));
  _home = _repository.watchHome().listen(
    (home) => add(KidHomeDataReceived(home)),
    onError: (Object e) => add(KidHomeStreamFailed(e)),
  );
}

@override
Future<void> close() async {
  await _home?.cancel();
  return super.close();
}
```

with `_onDataReceived` / `_onStreamFailed` emitting from the bloc's own
`emit`. Cancel `_home` in `close()` as well, so the retry path and bloc
teardown both release it. The suite must be green before review again.

### 2. [minor] `flutter analyze` was red at `HEAD`; the working tree now fixes it, but the fix must land

`app/test/features/kid_home/kid_home_bloc_test.dart:817-818` (at `HEAD`):

```dart
bloc.add(const KidHomeLoadRequested());
bloc.add(const KidHomeLoadRequested());
```

`flutter analyze` at `HEAD` → `1 issue found`
(`cascade_invocations`); RULES §7.1 requires "No issues found (no ignores)",
so the branch as committed does not meet the gate. While this review was
running the working tree picked up the cascade fix
(`bloc..add(...)..add(...)`) and `flutter analyze` now reports
**No issues found!** — so this is no longer a standing defect; it is only a
requirement that the fix be committed rather than left in the working tree.
Whatever survives finding 1's rewrite of this test must keep analyze clean.

### 3. [major] The pet slot is still 34.7 px off the centre axis and ~40 px too tall — the iteration-7 mandate did not land

`app/lib/features/kid_home/presentation/views/kid_home_view.dart:66`
(`const double _kNestWidth = 260;`) → `:711` `nestWidth: _kNestWidth`. The
shared explicit-size mode computes `stageW = nestW / 0.62 = 419.35`
(`core/design_system/components/nest_pet_stage.dart:105`) and `PipNestFallback`
positions the scene against that nominal width
(`core/design_system/motion/pip_rive.dart:461, 469, 470`), while the content
box is 350 px — every child shifts right by `(419.35 − 350) / 2 = 34.68` px,
and `nestH == nestW` makes the block 276 px tall instead of `.k3-pet`'s 236.

I re-measured the committed captures myself (PIL, ÷3), rather than trusting the
carried numbers:

| landmark (logical px) | design | app `app_light_7.png` | Δ |
|---|---|---|---|
| nest **visible outline** x | 96.0…294.0 (w 198.0, cx **195.0**) | 120.7…338.7 (w 218.0, cx **229.7**) | **+34.7** |
| pet block height (widget proof `K03-BUG-14`) | 236 (`.k3-pet`) | 276 | +40 |
| meadow band top @x30 | 524 | 579 | +55 |
| hearts row (coin ink) | 441…457 (centre 448) | 487…503 (centre 494) | +46 |
| section title ink | 484…503 | 530…549 | +46 |
| progress bar | 527…542 | 583…598 | +56 |
| quest card 1 top | 559 | 615 | +56 |
| quest card 2 | top 656, 63 of its 85 px visible above the dock | top 712, 7 of 85 px visible | effectively hidden |
| dock top border | 719 | 719 | 0 ✅ |

So the screen's hero (bubble, nest, Pip) is visibly right of the axis and the
quest column sits ~56 px low, which breaks the owner ALIGNMENT rule and hides
card 2. This is iteration-6 finding 2 unchanged, and the last-pass instruction
(`ORCHESTRATOR_NOTES` #35 DO 1) did not take effect in the running app.

Fix: not in K03's scope, and the build stage's arithmetic proving that no
`nestWidth` value reaches both targets is correct — SHARED_REQUEST #13 is
accurate, complete and the right ask (clamp `stageW` to the real box **and**
make the nest box ratio expressible; the 0.84 visible/box ratio is confirmed by
my measurement: 198 / 236 = 0.839 and 218 / 260 = 0.838). Land #13, then
un-skip `K03-BUG-13`, `K03-BUG-14` and `kid_home_geometry_test.dart` and
re-run the UI band table. Until then K03 cannot pass a UI check.

### 4. [major] The meadow band is still a feature-local painter although `KidScope` gained the K03 API on `main`, and its gradient never reaches the design's tone (dark reads flat navy)

`kid_home_view.dart:502-510` (`CustomPaint(painter: _MeadowPainter(...))`) and
`:718-755` (`TODO(K03)` + the painter).

1. **The shared API exists and names this screen.** `KidScope` grew
   `meadowHeight` / `meadowBottom` / `meadowColor`
   (`core/design_system/theme/kid_scope.dart:16-38`, shared batch `7eaa1f7`),
   and its doc comment says: *"screens whose design shows a taller band behind
   content (K03 progress + cards) pass a larger height instead of painting
   their own hill"* / *"K03's in-flow band measured `kidHorizon` on both design
   PNGs"*. K03 still paints its own and never calls them, so the request that
   produced the API (SHARED_REQUEST #6) is stale and the duplication
   `ORCHESTRATOR_NOTES` iteration 4 forbade ("rely on `KidScope`'s meadow …
   instead of painting a second hill") is still in the tree.
2. **The band is geometrically the wrong construct.** The design's green is the
   *screen* background gradient — `components.css:25`:
   `linear-gradient(180deg, kid-sky-top 0%, kid-sky-bottom 62%, kid-horizon 62%, kid-meadow 100%)`
   — so the tone at a given `y` is fixed by the screen, not by content height.
   K03 stretches its gradient over the whole in-flow panel (progress + all six
   cards, most of it below the fold), so inside the viewport it never leaves
   `kidHorizon`. Measured at x=30 (`design` vs `app_*_7.png`):

   | y | light design | light app | dark design | dark app |
   |---|---|---|---|---|
   | 580 | (226,244,217) | (233,246,225) | (35,55,83) | (36,50,88) |
   | 640 | (218,241,208) | (231,245,223) | (34,59,77) | (36,51,86) |
   | 712 | (208,238,196) | (229,244,220) | (32,64,70) | (35,52,85) |

   Worst case ΔRGB (21, 6, 24) light and (3, 12, 15) dark over a ~200 px band —
   in dark mode the meadow simply does not appear, which is `5_ui.md`
   deviation 2, now carried for the third iteration.

Fix (both halves): delete `_MeadowPainter` and pass
`KidScope(meadowHeight: <design>, meadowColor: tokens.kidHorizon)`; then update
SHARED_REQUEST #6 to the part that is still missing — `KidScope`'s background
gradient has only two stops (`kid_scope.dart:62-64`), so the design's 62%
horizon stop and horizon→meadow grade need to live in `core`. If the band has
to stay in flow for now, at least grade to `tokens.kidMeadow` (not
`lerp(horizon, meadow, 0.5)`) over the visible span so dark mode reads as the
design does, and mark #6 "partly landed".

### 5. [minor] One in-scope defect now carries two proofs with opposite conventions, and the iteration-6 replacement proof was never added

- `K03-BUG-15` is parked `skip: true` at `k03_bugs_test.dart:1350` even though
  the fix is **inside** K03 (`kid_home_bloc.dart`, finding 1) — while the
  duplicate at `kid_home_bloc_test.dart:808` runs red. Shared-blocked proofs
  (13/14/geometry) are parked; an in-scope one should not be. Keep one proof,
  un-skipped.
- The iteration-6 blocker test `a double tap across frames still completes
  exactly once` was deleted (`2_build.md:133`) instead of being re-expressed
  as the review asked. Cross-frame double dispatch is only covered on the
  *failure* path (`kid_home_bloc_test.dart:660-694`, `:697-729`); no proof
  asserts that two `KidHomeQuestCompleted` events one frame apart produce
  exactly one completion row and one celebration. Fix: add the bloc-level proof
  the review specified (add the event, `await tester.pump()`, add it again,
  then assert one `done_pending` row and one `justCompletedQuestId`).

### 6. [minor] A mid-session stream error replaces the whole screen with the failure card

`kid_home_bloc.dart:64-67` emits `KidHomeStatus.failure` from `onError` whether
or not a loaded screen exists, and `kid_home_view.dart:162-163` renders
`_KidFailure`, discarding the quest list the child was looking at. This is
inconsistent with the completion-failure path, which deliberately keeps the
list and only shows a toast (`:146-155`, and `copyWithLoaded`'s comment).
A single failed watch tick in kid mode currently replaces the screen with
"Oh no! Pip got lost." Fix: only enter the failure state when there is nothing
to keep — `status: state.child == null ? KidHomeStatus.failure : state.status`
— and let a healthy emission restore the list.

### 7. [minor] The geometry pin measures the nest *box* (236), not the mandated visible outline (198), so it can go green on a wrong-size paint

`kid_home_geometry_test.dart:96-107` (skip, real fonts) pins
`nest.center.dx 195 ±1` and `nest.width 236 ±2`, where 236 is "the box that
paints the design's 198 px visible outline". `ORCHESTRATOR_NOTES` #35 DO 2 asks
for the **outline** width `198 ±2`. A widget test cannot sample painted alpha,
so the honest split is: keep the box pin (it is exactly what the shared fix must
produce) but record the ratio as an assertion
(`expect(nest.width * 0.839, closeTo(198, 2))`), and let the UI stage measure
the painted outline on the device capture — which is what finding 3's table
does today.

### 8. [minor] `switchMapStream` still sits in `domain/` (carried, already requested)

`app/lib/features/kid_home/domain/kid_home_repository.dart:54-82` — a generic
stream combinator, not a domain abstraction; `ARCHITECTURE.md:71` keeps
`domain/` to "entities + abstract repository ONLY" and
`core/data/stream_combine.dart` already owns `combineLatest2/3/4`. Requested in
SHARED_REQUEST #14 (iteration-6 finding 7, unchanged). No action available in
K03; kept on the list so the record is complete.

---

## Verdict

The screen's craft is in good shape: PIP identity, the PERIODS ruling, COPY,
CHILD ORDER, the owner's bottom-edge rule, the 20 px gutters, the design-system
adoption (balanced title, per-quest tile tints, non-wrapping dock labels),
accessibility and Children's Code all hold, and the iteration-7 UI work is
correctly implemented and newly covered by real tests. But the suite is **red**
(finding 1 — an in-scope subscription leak on the retry path that nobody fixed,
against a build report claiming green), and two major design deviations remain
open: the hero pet slot is still 34.7 px off the centre axis with the quest
column 56 px low (finding 3, shared — request #13 is accurate and must land),
and the meadow band is still a duplicated local painter that renders flat navy
in dark mode where the design is teal (finding 4, part shared — request #6 is
stale). `2_build.md`'s green-suite verification does not reproduce at HEAD.
Fix 1 in this branch (and commit the analyze fix, finding 2), land shared
request #13 and update #6, then re-run the gates and the band table before
review again.


## From 5_ui.md
# K03 Kid home — UI check (Stage 5, iteration 7)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB only, per SIMULATORS rule; 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_7.png" <udid> light demo kid maya` -> `docs/screens/K03/ui/app_light_7.png` (1170x2532). Same with `dark` -> `app_dark_7.png`. Absolute OUT paths used. Both `stable frame saved`, no warnings.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_7.png docs/screens/K03/ui/cmp_light_7.png` (and dark). Read all four images. Logical px (PNG/3), tolerance ±2px.
- Rules applied: all orchestrator rules incl. new SIMULATORS rule (this stage used the designated simulator; nothing else in this stage did), PIP, STATUS BAR, DATA + PERIODS, BOTTOM EDGE, ALIGNMENT, CHILD ORDER (n/a — no child list), COPY (re-verified below), FONTS, LETTER SPACING, CHIP ROWS, SHAPES (rects), BALANCED HEADINGS, TRIAL (n/a), ORCHESTRATOR_NOTES (all incl. #35 last-pass targets), `1_plan.md`, SPACING_SPEC.

Results:
- light mean diff: 12.51% — bands: 0: 1.89% · 1: 4.36% · 2: 14.03% · 3: 22.84% · 4: 9.51% · 5: 22.33% · 6: 18.37% · 7: 6.73%
- dark mean diff: 11.22% — bands: 0: 1.87% · 1: 3.98% · 2: 14.54% · 3: 16.22% · 4: 9.65% · 5: 21.70% · 6: 16.35% · 7: 5.42%
- HEADLINE: the iteration-7 frames are visually UNCHANGED from iteration 6. Frame diff app_light_6→7: 0.17% mean, all tiny magnitudes (AA/clock noise); landmarks identical (hearts 489-498 both; card/progress border triplets identical). None of the #35 visual targets took effect in the running app. Everything below therefore carries over with fresh verification.

Target audit vs notes #35 exact geometry (logical px):
- Nest outline: target x96→294 (198 wide, cx195), y278→364. App (per orchestrator measurement, consistent with these frames): x120→338 (218 wide, cx229 = +34 off-centre), y299→414. MISS.
- Pip: target head top ≈201, bottom ≈301 overlapping rim ≈20px, no gap/shadow under feet. App: small Pip floating high with a daylight gap + detached shadow. MISS.
- Hearts centre 448 → app ≈493 (+45). Title 494 / progress 527-542 / card-1 559 → app progress ≈583-598 (+56), card-1 top 615-617 (+56, height correct ≈86). MISS.
- Dock 720 → app 719-721 EXACT ✓. Bottom edge dock-surface to y842 both themes ✓ (white light, navy dark — BOTTOM EDGE pass, no strip).
- Consequence: card-2 fully hidden below the dock; design shows it peeking. Hearts/progress/cards all strongly doubled in the diff.

Accepted / overridden (NOT defects): A1 counts 4/4-of-6 + fill (DATA+PERIODS); A2 2nd-card sample order (alphabetical wins); A3 Pip ART (mandated v2 — slot is the failure, not the art); A4 status bar (band 0 is clock only); A5 tiles (SHARED_REQUEST #1); A6 title size (pre-declared); A7 band-7 PNG delta (required by override); A8 COPY exact (U+0027 re-verified this iteration in both files); FONTS clean (no GoogleFonts in feature); no letterSpacing; chips display-only (CHIP ROWS n/a); shapes that pass — coin pill, lock 56, all 3 dock buttons within 1-2px, card-1 extents, 20px gutters, coins-only, other dark flips.
Fixed this iteration (code, not visible): `NestBalancedText` adopted for the kid-title (view l.483) — single-line so no visual change, as expected.

Deviations (design → app + fix):
1. Pet-slot geometry wrong (MAJOR, both themes — the last-pass blocker). Small floating Pip + oversized off-centre nest (+34 x, y299→414) instead of Pip ≈152 seated in the 198-wide centred nest with ≈20px rim overlap and no gap; +46-56px downstream shift hides card-2. Root cause already diagnosed in notes #35 (`nestWidth: 260` → `stageW = 419 > 390`, off-centre). Fix per notes #35: choose `nestWidth` for a 198 visible outline with a ≤390 centred stage box, seat PipAvatar in the bowl; pin with the geometry test (nest cx195±1 w198±2, hearts 448±2, card-1 559±2); if the shared component cannot do it without a core edit, file SHARED_REQUEST with these numbers and stop. No code touched in this stage.
2. Dark lower-content meadow still missing (moderate, dark-only, 3rd iteration). Design dark x=10: (37,52,88)@540 → teal (33,64,72)@700. App dark: flat navy (37,51,88)→(36,53,86). Light renders its band correctly. Fix: dark meadow fills behind the lower content.
3. Speech bubble 46 vs 35 tall, same x/y/w (minor, carried; contributes to the shift). Fix: `NestSpeechBubble` metrics vs HTML `.speech`.

Otherwise correct: header, bubble copy/tail, hearts 4/5 + caption, chips (full pills), progress geometry, card geometry/checks per status, exact dock, alignment outside the pet chain, no overflow/ellipsis.

Iteration-8 (or orchestrator shared fix): #1 geometry + test (or SHARED_REQUEST per #35.3), #2 dark meadow, #3 bubble height. Shared/pre-declared: tile tint, title size.


## From 6_bugs.md
# K03 Kid home — bug hunt (Stage 6, iteration 7)

Adversarial pass over `kid_home` K03 after the iteration-7 integration:
data edges, rapid double taps, back navigation, deep links, restart
persistence, mode guards, dark contrast, 320px + 1.3 scale, async gaps,
Europe/London periods, integer money, the owner rules, CHILD ORDER, COPY,
fonts and the newly landed shared components. No screen code was changed in
this stage.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 51 tests:
  46 run green, 5 skipped (`K03-BUG-13` ×3 widths, `K03-BUG-14`,
  `K03-BUG-15`).
- Run the skipped proofs:
  `cd app && flutter test --run-skipped --plain-name "K03-BUG"`.

## Open bugs

### K03-BUG-13 — Pet slot off-centre at every width, clipped at 320 (Major, shared)

Unchanged since iteration 6 and now **quantified by the iteration-7 build**:
the explicit `NestPetStage` mode reserves `stageW = nestW / 0.62` (419.35 px)
and lays the scene out against that nominal width, while the content box is
350 px (390 − 2×20) — every child shifts right by 34.68 px; at 320 px the
shift is 69.68 px and the nest overflows its slot by 59.7 px, cut by the
Stack (≈40 px past the screen edge). A 260×236 nest at the design's visible
size is unreachable from K03 without the shared component also gaining a
`nestHeight`/ratio change, so the build filed it rather than hacking:
SHARED_REQUEST #13 (with the arithmetic table) plus a real-font pin in
`kid_home_geometry_test.dart` (currently skipped) that reproduces the device
captures: nest centre 229.68 (+34.68 vs 195), hearts 494.0 (+46 vs 448),
first card 615.0 (+56 vs 559).

Failing tests (skipped so the suite stays green):
- `K03-BUG-13: the pet slot stays centred at 320px` / `390px` / `430px`

### K03-BUG-14 — Pet block 276 px vs the design's 236 px (Moderate)

The same mode renders a 260 px square nest; `PipNestFallback` is 276 px tall
instead of the design `.k3-pet` 236 px, shifting the whole lower stack down
(hearts ~505 instead of the ≈443 target). Same fix family as K03-BUG-13.

Failing test (skipped):
- `K03-BUG-14: the pet block keeps the design 236 px slot height`
  (`Expected within 2 of 236, Actual 276`).

### K03-BUG-15 — "Try again" stacks live stream subscriptions (Minor, new)

**Where:** `kid_home_bloc.dart` `_onLoadRequested` + the default
`watchHome()`/`switchMapStream` chain. Each failed load leaves its source
subscriptions live; the failure screen's "Try again" adds another chain.

**Repro (new proof):** a repository whose child/items streams error on
listen after being counted; add `KidHomeLoadRequested` three times on the
failure path. Actual: **peak = 3 concurrent source subscriptions** and
`active = 3` at the end, i.e. nothing is released; expected ≤ 2 (one child +
one items) with 0 live after the failure. This independently confirms review
finding 6 (the iteration-7 logic rewrite that fixed it was reverted).

Failing test (skipped):
- `K03-BUG-15: retry does not stack live stream subscriptions`
  (`Expected ≤ 2, Actual 3`).

Suggested fix: in `_onLoadRequested`, early-return while a load subscription
is live (the review's smaller alternative), or make `switchMapStream` cancel
its source/inner subscriptions when the consumer cancels after an error
(SHARED_REQUEST #14 — the helper sits in `domain/`).

## Fixed / verified this iteration

- **Iteration-7 UI landed and probed:** `NestBalancedText` renders the
  `.kid-title` with the 20 px left edge; quest tiles carry the per-quest
  tints (dishwasher `skyTint`, reading `lilacTint`, tidy `peachTint`, others
  neutral) — SHARED_REQUEST #1 closed; all three dock buttons have
  `wrapLabel: false` — SHARED_REQUEST #9 closed.
- **Earlier bugs 1–12 remain fixed and green** (period semantics, tap
  latches, celebration mapping, bottom edge light+dark, child order, fonts
  bundled with zero tracking, copy character-for-character).

## Carried items (owned elsewhere)

| Source | Severity | Item |
|---|---|---|
| 5_ui iteration 7 | Moderate | `NestSpeechBubble` is 46 px vs design 35 px — SHARED_REQUEST #15 |
| 5_ui iteration 7 | Moderate (dark only) | dark meadow band behind lower content still unverified (no simulator in this stage) |
| geometry pin | — | `kid_home_geometry_test.dart` stays skipped until SHARED_REQUEST #13 lands |

## Verified clean (probes)

| Category | Probe | Result |
|---|---|---|
| iteration-7 UI | balanced title + 20 px edge; per-quest tile tints; dock labels never wrap | pass |
| child order | `watchProfiles()` = Maya, Leo; six children in one second keep insertion order | pass |
| fonts | bundled Nunito, `letterSpacing: 0`, no `google_fonts` | pass |
| copy | strings match the HTML character-for-character | pass |
| bottom edge | light + dark surface to the physical edge under a 34px inset | pass |
| alignment | 20px gutters on bar, cards and dock | pass |
| periods | day/week boundaries, daily/weekly/once, BST switch days | pass |
| taps | same-frame double taps → one row / one route; silent no-op retry | pass |
| data edges | 0 / 1 / 6 children; long name + 9999 coins at 320/1.3; no `£` | pass |
| back nav / deep links / restart / guard / contrast / money / async gap | earlier probes | pass |

## Observations

1. Period rollover computes at stream-map time (no injectable clock).
2. Test wall-clock coupling (seed pinned, `DateTime.now()` not).
3. Parent-mode `/kid-home` deep link and PIN bypass remain product-level
   questions; debug gallery routes unguarded.
4. Static `PipAvatar` fallback omits accessories (no seed child equips one).

## Summary

| ID | Severity | Status |
|---|---|---|
| K03-BUG-13 | **Major (owner ALIGNMENT)** | **open (shared; SHARED_REQUEST #13, geometry pin)** |
| K03-BUG-14 | Moderate | **open (same fix family)** |
| K03-BUG-15 | Minor | **open (retry-stacked subscriptions; SHARED_REQUEST #14)** |
| K03-BUG-1..12 | Major..Moderate | fixed, proofs green |

The screen's functional behaviour remains in good shape (all iteration-1..6
fixes hold, the iteration-7 UI work is verified), but the pet slot is still
visibly off-centre at every width and clipped at 320 px — a major under the
owner ALIGNMENT rule — with the height knock-on and a small retry
subscription leak alongside it.

