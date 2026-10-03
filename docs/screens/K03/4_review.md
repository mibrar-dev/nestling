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

VERDICT: FAIL