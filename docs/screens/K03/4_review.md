# K03 Kid home — QA code review (Stage 4, iteration 5)

Scope: `kid_home` / `/kid-home`, kid mode. Reviewed `git diff main...HEAD`
plus the current working tree, so the verdict reflects the code as it
stands. Per the orchestrator rule, uncommitted work / branch-vs-main /
merge order are **not** findings and are not reported.

## Verification run (in `app/`, this iteration)

- `dart format --set-exit-if-changed .` → 361 files, 0 changed.
- `flutter analyze` → **No issues found!** (no ignores).
- `flutter test` → **`+641 ~1: All tests passed!`** (1 conditional skip, finding 5).
- RULES §1: only `app/lib/features/kid_home/**`,
  `app/test/features/kid_home/**`, `docs/screens/K03/**`. No `core/`, no
  `app/`, no other feature, no `tools/`. ✅
- Bottom edge (owner rule): still correct — `ui/app_light_9.png` at x=195
  reads the surface colour at y=810/820/835/843 (no coloured strip under the
  dock), same in dark. ✅
- PIP identity: `PipAvatar` only in the feature (pet slot, empty, failure,
  detail, complete); no `pip_stage_*.svg`. Child's DB look drives
  style/skin/accessory/stage. ✅
- PERIODS ruling intact (`countsForCurrentPeriod` at
  `kid_home_repository_impl.dart:40` and `:118`), day-boundary proof
  un-skipped and green. ✅
- Children's Code: no analytics/ads/SDK/network, no child identifiers beyond
  nickname/coins/Pip look. ✅
- ARCHITECTURE: feature-first, domain = entities + abstract repository only,
  one bloc per feature, routes/DI untouched and per feature. ✅

## Copy rule — checked, passing

Compared the screen's strings character-by-character with
`design/html-source/screens/K03-kid-home.html`:

- The HTML source itself uses **straight apostrophes** in `Let's do some
  quests!`, `Today's quests`, `Who's playing?` (verified with a hex dump:
  `27`, U+0027 — not U+2019). The screen now matches: view:264, 339, 492,
  696 and `_statusText` all use the straight `'`, and the three test files
  expect the same. The earlier curly `’` reads would have *diverged* from
  the source, so this direction is correct, not a regression.
- `Reading &ndash; 20 minutes` (HTML uses the `&ndash;` entity) → the seed
  title uses a real U+2013 en dash (`seed.dart` inserts `Reading – 20
  minutes`). ✅
- `Waiting for Mum's thumbs-up · +15` (repo `kid_home_repository_impl.dart`
  `_detail` line 168) uses a real middle dot `·` (U+00B7) and the chip
  label `Waiting for Mum` matches the HTML. ✅
- The screen's dock labels `Pip / Shop / My jar`, `Hi {name}!`, `{n} done
  today`, `{n} of {total} done`, the dock's `+15 / +10` coin pills and the
  lock's `aria-label="Grown-ups"` all match the source. ✅
- No `…`, `“`, `”` or NBSP appear in the K03 copy, so there is nothing to
  reproduce there. ✅

No copy finding.

## Closed since the last review (verified in code)

- The design-system forks are still gone in favour of shared components
  (`NestPetStage(pip:, speech:, pipSize:)` at `kid_home_view.dart:687-698`,
  `NestHeart(filled:)` at `:462`), and the one local painter carries
  `TODO(K03)` + `SHARED_REQUEST` #6 — the sanctioned RULES §2 pattern.
- Stage-aware pet semantics label, `showNestToast`, gate lock in all three
  non-loaded states, failure state uses the known child's Pip,
  `copyWithLoaded` drops the stale `errorMessage`
  (`kid_home_state.dart:108-115`), `_awaitingCelebration` evicts vanished
  quests (`kid_home_bloc.dart:40-47`), named constants for the slot
  geometry, and the full SHARED_REQUEST trail (#6–#10) all still hold.

## Findings

### 1. [major] The pet slot still does not meet the mandatory size in `ORCHESTRATOR_NOTES` #1
`kid_home_view.dart:687-698` + `core/design_system/components/nest_pet_stage.dart:69-74`.

The note requires "Pip ≈152 px tall on the 260×236 nest, nest top ≈ y 300".
The screen passes `pipSize: _kPipSlotSize = 152`, but that value is only a
**cap** in the shared math:

```dart
var pipH = maxW.isFinite ? maxW * 0.62 * 0.55 : pipSize; // 350 × 0.341 = 119.35
if (pipH > pipSize) { pipH = pipSize; }                  // 119.35 < 152 → stays
```

so on a 390 px screen the slot is fixed at a 119 px Pip on a 217 px nest,
and the API offers no way to reach 152 (that would need `maxW ≈ 446`). I
measured the captures twice now (logical px):

| | design PNG | app (iter-5 geometry, `app_light_8`) |
|---|---|---|
| nest, widest | 198.3 | **182.3** (−16) |
| Pip, widest | 93.7 | **79.7** (−14) |
| Pip band (y) | 197–288 | 197–~265 (−25 px tall) |

Position *is* met (Pip top y=197 = design 197; nest rim y≈286-292 vs design
288-294); the unmet half is the explicit numeric size, which regressed
against iteration 4's capture (nest ≈197, Pip ≈94). The code comment
concedes it ("renders proportionally smaller — positions, not pixels are
what carry over"), and `SHARED_REQUEST.md` #6–#10 still has **no** entry for
the pet-slot size — so the gap is neither closed nor formally requested.

Fix (request-then-interim, per RULES §2):
1. File a SHARED_REQUEST for `NestPetStage` to accept a **target** size —
   e.g. `nestWidth:` or `pipHeight:`, or a `stageWidth:` the scene stops
   deriving from `maxW` — so a screen can land the design's 260×236 slot.
2. Until it lands, restore the design-sized slot locally (the previous
   260×236 composition) behind `// TODO(K03)` + that request, keeping the
   shared bubble/semantics.
3. Re-measure with `compare.py` once the motion flag (finding 5) is fixed,
   because the current `ui/` captures are blank.

### 2. [minor] CHILD ORDER ruling is violated at the data layer
`app/lib/core/data/app_database.dart:307-310`: `watchChildren` applies
`..orderBy([(c) => OrderingTerm(expression: c.nickname)])`, i.e.
**alphabetical** — Leo before Maya. The seed inserts Maya first
(`seed.dart:185`, then `:207`), so insertion order is [Maya, Leo] and this
must be the UI order everywhere ("in every screen and repository").
`KidHomeRepositoryImpl.watchProfiles()`
(`kid_home_repository_impl.dart:58-62`) maps `watchChildren` unchanged, so
the kid_home repository hands out [Leo, Maya], and K01's profile picker is
exposed to the same wrong order. K03's own render is single-child, so there
is no visible effect on this screen today, and the `Children` table has no
order column (`ageBand`/`createdAt` don't express it), so the real fix is
shared.

Fix: file a SHARED_REQUEST to order `watchChildren` by insertion order —
add a `position` (or reuse `createdAt` if a column is added) — and remove
the `nickname` order. Do **not** paper over it by re-sorting in the K03
screen.

### 3. [minor] Typography fork sanctioned but unmarked at the call sites
`kid_home_view.dart:407, 419, 468` and `widgets/kid_status_chip.dart:31`
still call `GoogleFonts.nunito(...)` directly, bypassing `NestType`.
`SHARED_REQUEST` #7 records the need and the sub-17 px kid-copy exemption,
so the fork is legitimate — but unlike the meadow painter there is no
`// TODO(K03)` at the call sites, so a reader cannot tell it is temporary.
Fix: add the TODO line at each of the four sites.

### 4. [minor] The child stream is still watched twice per load
`kid_home_bloc.dart:30` combines `watchActiveChild()` with `watchItems()`,
and `watchItems()` already opens `watchActiveChild()`
(`kid_home_repository_impl.dart:22`). Each `app_state`/`children` change
therefore runs two subscriptions, and on a child switch there is one frame
where `child` is the new child while `items` still belong to the old one.
Fix: one combined repository stream (`Stream<KidHomeData> watchHome()`).

### 5. [minor] Shared motion-flag bug is open; the iteration-5 captures are blank
`core/data/env_flags.dart` still parses `DISABLE_ANIMATIONS=1` as false
(`SHARED_REQUEST` #5), so `shot.sh` frames are live animation — and this
iteration's `ui/app_light_9.png` / `ui/app_dark_9.png` / `ui/cmp_*_9.png`
came out as blank white frames (the harness grabbed no render, consistent
with the "frame never stabilised" warning). The tests are green, so this is
a capture-pipeline issue, not a screen defect — but it means the UI stage
cannot confirm the still frame, and my finding 1 rests on the unchanged
shared geometry plus iteration 4's measurement, not on a current capture.
Fix is shared; K03 cannot edit `core/`. Re-capture after #5 lands.

### 6. [minor] Dock label can still wrap
`NestKidButton` wraps its label in `Flexible` + `Text` only, so "My jar"
wraps to two lines under wide fallback fonts and the dock grows (there is no
`FittedBox`/`softWrap: false` in the shared component). Cosmetic on device
with real Nunito; tracked as `SHARED_REQUEST` #9. No screen-local fix
needed once #9 lands.

## Verdict

Everything else iterates cleanly: the design-system migration is complete
(shared `NestPetStage(pip:)`, `NestHeart`, `showNestToast`, stage-aware
semantics), the gates are green (`dart format` clean, `flutter analyze`
clean, `flutter test` `+641 ~1`, K03 block green),
bottom edge holds, PIP identity + PERIODS + COPY all verified character by
character against the source, RULES §1 is respected, and the
SHARED_REQUEST trail is complete for everything but two items below. Two
issues remain: the pet slot is measurably smaller than the mandatory
`ORCHESTRATOR_NOTES` #1 (no shared request filed for it yet — finding 1),
and the CHILD ORDER ruling is broken at the shared `watchChildren`
ordering (finding 2). Both need a shared change + a request entry, which is
exactly the path RULES §2 prescribes.

VERDICT: FAIL
