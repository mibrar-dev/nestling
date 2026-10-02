# K03 Kid home — QA code review (Stage 4, iteration 5)

Scope: `kid_home` / `/kid-home`, kid mode. Reviewed `git diff main...HEAD`
plus the current working tree, so the verdict reflects the code as it
stands. Per the orchestrator rule, uncommitted work / branch-vs-main /
merge order are **not** findings and are not reported.

## Verification run (in `app/`, this iteration)

- `dart format --set-exit-if-changed .` → 355 files, 0 changed.
- `flutter analyze` → **No issues found!** (no ignores; `analysis_options.yaml` untouched).
- `flutter test` → **`+593 ~1: All tests passed!`** (1 conditional skip, finding 5).
- RULES §1: only `app/lib/features/kid_home/**`,
  `app/test/features/kid_home/**`, `docs/screens/K03/**`. No `core/`, no
  `app/`, no other feature, no `tools/`. ✅
- Bottom edge (owner rule) still correct: `ui/app_light_8.png` x=5 shows the
  dock's surface `(255,255,255)` from y=716 to the physical edge y=843 with
  no green transition, and `ui/app_dark_8.png` likewise — the surface
  `Container` still wraps `SafeArea(top: false)` (view:471-478). ✅
- Mandates: PIP identity — `PipAvatar` only (no `pip_stage_*.svg` anywhere in
  the feature) and the child's DB `pip_style / pip_skin / pip_accessory /
  pip_stage` drive it in all three states; PERIODS ruling intact
  (`countsForCurrentPeriod` at `kid_home_repository_impl.dart:40` and `:118`);
  coins only, no `£`; UK spelling. ✅
- ARCHITECTURE: feature-first, domain = entities + abstract repository only,
  one bloc per feature with `emit.forEach` streams (no re-added load events),
  routes/DI untouched and per feature. ✅
- Children's Code: no analytics/ads/SDK/network, no child identifiers beyond
  nickname/coins/Pip look, parental gate reachable from every kid state. ✅

## Closed since the last review (verified in code)

- **Design-system forks removed.** `_SpeechBubble` / `_TailPainter` /
  `_HeartIcon` / `_HeartPainter` are gone from the view; the pet slot now uses
  the shared `NestPetStage(pip:, speech:, pipSize:, semanticLabel:)`
  (`kid_home_view.dart:686-698`, whose `pip` slot exists at
  `core/design_system/components/nest_pet_stage.dart:29`) and the hearts use the
  shared `NestHeart(filled:)` (`core/design_system/components/nest_heart.dart:8`).
  The one remaining local painter carries `TODO(K03)` + `SHARED_REQUEST` #6,
  which is the pattern RULES §2 prescribes.
- Semantics label is now stage-aware (`'Pip the Fledgling, stage 3 of 4'`, view:697).
- `showNestToast` replaces the inline `SnackBar` (view:158-160) — keeps the
  token toast's `liveRegion: true`.
- Parental-gate lock added to the loading, failure and no-child states
  (view:196-204, 246-254, 328-336); the test that asserted its absence is gone.
- The failure state renders the known child's Pip when one is loaded (view:260-271).
- `copyWithLoaded` no longer carries a stale `errorMessage`
  (`kid_home_state.dart:108-115`).
- `_awaitingCelebration` evicts entries whose quest vanished from the list
  (`kid_home_bloc.dart:40-47`), closing the silent-no-op latch.
- Slot geometry hoisted into cited named constants (`_kPipSlotSize`,
  `_kCrest*`, view:60-95).
- `SHARED_REQUEST.md` now carries the requested `KidScope` meadow band (#6),
  the missing `NestType` kid styles + the sub-17 px kid-copy exemption (#7),
  the `inNest` waiver against `ORCHESTRATOR_NOTES` #1 (#8), the
  `NestKidButton` label-wrap option (#9) and the card-count record (#10).

## Findings

### 1. [major] Pet slot shrank below the mandatory size in `ORCHESTRATOR_NOTES` #1
`kid_home_view.dart:686-698` (`NestPetStage(pipSize: _kPipSlotSize, …)`),
combined with `core/design_system/components/nest_pet_stage.dart:69-74` and
`core/design_system/motion/pip_rive.dart:468`.

The migration to the shared component is the right call, but the shared scene
sizes itself from the available width, and `pipSize` is only a **cap**:

```dart
var pipH = maxW * 0.62 * 0.55;      // 350 × 0.341 = 119.35
if (pipH > pipSize) pipH = pipSize; // 119.35 < 152 → unchanged
```

`PipNestFallback` then derives the nest (`pipH / 0.55` = 217) and the stage
(`nestW / 0.62` = 350) from `pipH`, and positions the `pip` slot from it, so
the screen cannot reach the note's ≈152 px Pip on a 390 px screen at all
(that would need `maxW ≈ 446`). Measured on the captures (logical px):

| | design PNG | app iter-5 (`app_light_8`) | app iter-4 (`app_light_5`) |
|---|---|---|---|
| nest, widest | 198.3 | **182.3** (−16) | 197.0 |
| Pip, widest | 93.7 | **79.7** (−14) | ~94 |
| Pip band (y) | 197–288 | 197–~265 | 211–288 |

So this iteration moved the hero slot ~15 % narrower and ~25 px shorter than
the design — a regression from iteration 4, which matched. The *position*
half of the note is met (Pip top y=197 vs design 197; nest rim y≈286-292 vs
design 288-294); only the absolute size is unmet, and the code comment
concedes it ("renders proportionally smaller — positions, not pixels are what
carry over"). The note is mandatory and states the numbers.

Fix (needs one shared change, then a one-line screen change):
1. `SHARED_REQUEST.md`: give `NestPetStage` a target instead of a cap —
   e.g. `nestWidth:` / `pipHeight:` (or a `stageWidth:` that no longer derives
   from `maxW`) so a screen can pin the design's 260×236 slot.
2. Until it lands, keep the shared `NestPetStage` (so the bubble/geometry stay
   in core) but give the stage the design's box so the shared math lands on
   152/260; if that is impossible with the current formula, restore the
   previous 260×236 composition with `TODO(K03)` + a request entry — the
   sanctioned RULES §2 pattern.
3. Re-measure with `compare.py` and re-check against `ORCHESTRATOR_NOTES` #1
   before closing.

### 2. [minor] `_MeadowPainter` is still a screen-local hill
`kid_home_view.dart:710-733`. Now sanctioned (`TODO(K03)` + `SHARED_REQUEST`
#6) and correctly token-coloured (`tokens.kidHorizon`), so this is a tracked
debt rather than a defect. Fix: delete it and its call site when the
`KidScope` meadow-band parameter lands; do not extend the painter meanwhile.

### 3. [minor] Typography fork: sanctioned, but not marked at the call sites
`kid_home_view.dart:407, 419, 468` and `widgets/kid_status_chip.dart:31` call
`GoogleFonts.nunito(...)` directly, bypassing `NestType`. `SHARED_REQUEST` #7
records the need (and the documented sub-17 px kid-copy exemption), so the
fork is legitimate — but unlike the meadow painter there is no `TODO(K03)` at
the four call sites, so a future reader cannot tell the fork is temporary.
Fix: add `// TODO(K03): use NestType.kidName / kidCaption / kidChipLabel when
SHARED_REQUEST #7 lands` at each call site.

### 4. [minor] The child stream is still watched twice per load
`kid_home_bloc.dart:30` combines `watchActiveChild()` with `watchItems()`,
but `watchItems()` already opens `watchActiveChild()`
(`kid_home_repository_impl.dart:22`). Every `app_state` / `children` change
drives two subscriptions and two `combineLatest2` emissions (the duplicate is
swallowed by `Bloc`'s equal-state check), and on a child switch there is one
frame where `child` is the new child while `items` are still the old child's
quests. Fix: a single combined stream from the repository
(`Stream<KidHomeData> watchHome()`), so child and items cannot disagree.

### 5. [minor] Shared motion flag still unfixed (open, not K03-fixable)
`bool.fromEnvironment('DISABLE_ANIMATIONS')` parses the documented `=1` as
false, so `shot.sh` captures keep running Rive and report "frame never
stabilised"; `ui/` PNGs are therefore live-animation frames, not stills.
`SHARED_REQUEST` #5 tracks it and the `K03-BUG-7` proof is conditionally
skipped (runs and fails with the documented flag). Fix is shared
(`core/data/env_flags.dart` + `core/app/launch_flags.dart`); K03 cannot edit
`core/`. Keep treating the `ui/` PNGs as non-deterministic until it lands —
which is why finding 1 is measured against the design PNG and the shared
geometry, not against a pixel diff of the captures alone.

### 6. [minor] Dock label can still wrap
`NestKidButton` gives the label `Flexible` + `Text` only, so "My jar" wraps to
two lines under wide fallback fonts and the dock grows. Cosmetic on device
with real Nunito; tracked as `SHARED_REQUEST` #9 (a `softWrap: false` +
`FittedBox(scaleDown)` option). Fix: land #9, or pass a shorter label
(consistent with the design's "My jar") if a screen-local mitigation is ever
needed.

## Verdict

Iteration 5 cleared the previous blocker: the design-system forks are gone in
favour of the shared `NestPetStage(pip:)` and `NestHeart`, the shared-request
trail is complete, seven of the eight earlier minor findings are fixed, and
the gates are green (`dart format` clean, `flutter analyze` clean,
`flutter test` `+593 ~1`, RULES §1 clean, bottom edge and PIP identity
verified on device). One major finding remains: the migration to the shared
pet stage left the hero slot ~15 % smaller than the design and ~25 px shorter,
which does not meet `ORCHESTRATOR_NOTES` #1 and regressed against iteration
4's capture. It needs one shared parameter (`NestPetStage` currently caps
instead of targeting `pipSize`) plus a re-measure — the same
request-then-interim pattern RULES §2 prescribes, which this screen has now
used correctly for every other gap.

VERDICT: FAIL
