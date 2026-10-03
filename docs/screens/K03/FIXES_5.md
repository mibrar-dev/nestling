# Fix list after iteration 5

## From 4_review.md
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


## From 5_ui.md
# K03 Kid home — UI check (Stage 5, iteration 5)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_5.png" <udid> light demo kid maya` -> `docs/screens/K03/ui/app_light_5.png` (1170x2532). Same with `dark` -> `app_dark_5.png`.
- NOTE: absolute OUT paths used (`shot.sh` cds to `$APP_DIR`). First stable run: both shots printed `stable frame saved` (no stabilisation warning) — the shared `disableAnimations` fix works.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_5.png docs/screens/K03/ui/cmp_light_5.png` (and dark). Read both sheets. Logical px (PNG/3), tolerance ±2px.
- Rules applied: PIP (`PipAvatar` Mochi/sunny/stage 3), STATUS BAR (ignore), DATA OVER MOCKS + PERIODS (in-period counts win; seed anchored to today), BOTTOM EDGE owner rule (bar surface to the edge — FAIL any coloured strip; overrides design), ALIGNMENT owner rule (20px gutters, nothing visibly off), CHILD ORDER (no child list on this screen — n/a; quest order stays alphabetical per `1_plan.md` §a), COPY (typographic characters verified by codepoint below), ORCHESTRATOR_NOTES (all items incl. iter4 shared-component migration + iter5 QA targets), `1_plan.md`, SPACING_SPEC.

Results:
- light mean diff: 11.99% — bands: 0: 2.94% · 1: 5.06% · 2: 9.93% · 3: 7.79% · 4: 9.08% · 5: 23.45% · 6: 24.88% · 7: 12.80%
- dark mean diff: 10.95% — bands: 0: 3.00% · 1: 4.98% · 2: 9.48% · 3: 5.58% · 4: 8.07% · 5: 22.18% · 6: 22.81% · 7: 11.49%
- QA band target MET: bands 3-5 dropped clearly vs iter4 (light 13.18→7.79 / 13.20→9.08; dark 9.71→5.58 / 12.90→8.07). Band 7 residual is the required dock-surface-vs-outdated-PNG-green delta (override, not a defect).
- QA position targets (logical px): hearts top design 443 vs app 446 (+3, was +12) ✓; dock top 719-721 vs 713-715 (−6, unchanged); bottom edge dock-surface to y842 both themes (white light, navy (31,28,46) dark) ✓ no strip.

Fixed since iter4: bottom-edge strip gone both themes (was must-FAIL); hearts +12→+3; light green band now starts y536 (was 562); shared forks removed per notes #15-20 (visual result identical-or-better).

Accepted / overridden (NOT defects):
- A1 counts "4 done today" / "4 of 6 done" / ~66.7% vs PNG 3/50% — correct per DATA + PERIODS + notes #2.
- A2 2nd card "Hoover the stairs" (approved → "Done") vs PNG "Reading" sample — alphabetical data order wins (`1_plan.md` §a); same peek-above-dock presentation. CHILD ORDER ruling concerns children, not quests.
- A3 Pip drawing vs v1 SVG — MANDATED `PipAvatar`. A4 status bar (OS time only) — ignored (band 0 is this only).
- A5 tiles `surface2` vs tints — SHARED_REQUEST #1. A6 title ≈17/22 vs 18/24 — pre-declared token. A7 no OS pill in captures — expected.
- A8 COPY rule PASS: "Today's quests" and "Let's do some quests!" use U+0027 in BOTH the HTML source and the view (verified codepoint-by-codepoint); "Waiting for Mum", "Hi Maya!", "Pip is happy today" match; quest titles come from the DB seed (data wins).

Deviations (design value → app value + fix):
1. Dark lower-content background missing the meadow tint (moderate, dark-only — FAIL driver, carried from iter4). Design dark x=10 grades (37,52,88) at y540 → teal (33,64,72) at y700 behind progress/cards. App dark is flat navy (37,51,89) across y540-710, while light correctly renders its green band. Fix: dark meadow fills behind the lower content (dark `--kid-meadow`/`--horizon`, `hill-front` bake per SPACING §9.14) — light proves the layer works; dark renders nothing. For the iteration-6 builder; no code touched here.
2. Residual +10-13px excess in the hearts→progress span (moderate, both themes). Hearts bottom → progress top: design 75px vs app 85px; progress borders ≈+13 (527-542 vs 540-555); card-1 top +13 (559-561 vs 572-574, same 3px triplet; progress→card-1 gap correct at 17 both). Title/chip/progress show clear doubling in the diff. Fix: trim ≈10px from the section-title block/gaps (shared section style or K03 spacing), keeping hearts top at 443-446.
3. Dock top −6px (minor, ALIGNMENT): light 713-715 vs 719-721, unchanged from iter3/4. Fix: land exactly on y≈720 when owning the inset.
4. Dark pet glow circle present in app, absent in PNG (informational). App follows SPACING §7 (white@10% dark); the PNG omits it. Spec-compliant — orchestrator to rule if ever normalised; not counted toward the verdict.

Otherwise correct: header row, bubble, hearts 4/5 stroked + caption, section chip, kid progress geometry, card geometry/chips/checks per status, dock buttons (glyphs, labels, colours both themes), 20px gutters edge-aligned, no overflow/ellipsis issues, coins-only, all other dark token flips correct.

Iteration-6 fixes (local): #1 dark meadow behind lower content; #2 section-block trim (≈10px); #3 dock top to y≈720. Shared/pre-declared: tile tint, title size.

