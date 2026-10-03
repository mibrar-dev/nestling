# K03 Kid home — UI chunk (2b), iteration 8

Scope (per the brief): `app/lib/features/kid_home/presentation/views/**` +
`presentation/widgets/**`, the K03 view/widget tests, and
`docs/screens/K03/**`. Domain / data / bloc / cubit are the logic builder's
(`2a_build_logic.md`) and were not edited by me. No simulator, no
`flutter run`, no `flutter clean`, no whole-app `flutter test`.

## 2a contract re-read (before finishing)

`2a_build_logic.md` "CONTRACT CHANGES" adds two **bloc-internal** events,
`KidHomeDataReceived` and `KidHomeStreamFailed` (the retry path is now a
guarded `StreamSubscription` instead of `await emit.forEach`). Checked
against the view: the only event the view sends is `KidHomeLoadRequested`
(`kid_home_view.dart:310`, the failure card's "Try again"), and the view
contains no reference to either internal event — `grep` confirms. No view
change was needed for the contract; the mid-session-error rule ("keep the
loaded list unless `child == null`") is entirely inside the bloc, so
`_KidFailure` still renders only for a real `failure` status.

## What changed in `kid_home_view.dart`

### 1. Pet slot — the exact mandated call (closes review finding 3, K03-BUG-13/14)

`ORCHESTRATOR_NOTES` UPDATE (08:32) and
`docs/screens/_shared/pet_stage_explicit_REPORT.md`:

```dart
NestPetStage(
  pip: PipAvatar(style: _pipStyle(child.pipStyle), skin: _pipSkin(...),
                  accessory: _pipAccessory(...), stage: child.pipStage),
  speech: "Let's do some quests!",
  nestWidth: 236, nestHeight: 156, fixedPipHeight: 152,
  semanticLabel: 'Pip the ${_pipStageName(stage)}, stage $stage of 4',
)
```

* `_kNestWidth = 260` is **deleted**; the numbers are now `_kNestBoxWidth =
  236`, `_kNestBoxHeight = 156`, `_kPipSlotSize = 152`, each commented with the
  design source (`.k3-pet` 236 px slot; 236 is the box that paints the
  design's 198 px visible outline through `PipNestFallback.visibleNestRatio`
  202/240 → 197.9).
* No `Center` wrapper around the stage (explicitly forbidden), and `pipSize`
  is no longer passed — explicit mode ignores it, so leaving it would have
  been a dead prop.
* The shared component's fix (`shared/pet_stage_explicit`, merged before this
  build) lays the scene out in the **real** content box and centres it there
  instead of against a nominal `stageW = nestW / 0.62 = 419`, which is what
  put the nest 34.7 px right of the axis at 390 px (+69.7 px and clipped at
  320).
* `PipAvatar` still comes from the **active child's** DB row (`pipStyle` /
  `pipSkin` / `pipAccessory` / `pipStage`) — PIP rule intact, and no
  `pip_stage_*.svg` / `PipRive` anywhere in the feature (`grep`).

### 2. The one remaining lever: `_kStageToHearts = 10.75`

The shared box changed the pet block's height (the design's 236 px slot plus
the shared 10 px ground-shadow bleed, 236.25 in practice) and the stage spends
18 px between the speech-bubble tail and the pet block where `.k3-pet` sets
`margin: 14px auto 0`. The HTML's `.scroll > * + *` is `s4` (16), so the
overshoot must come back out of the gap or every row below sits low — which
is precisely the iteration-6/7 finding (hearts 494 vs the design's 448). The
orchestrator sanctioned sizing the stage box rather than negative margins; the
box is shared-owned now, so the gap is the only lever: **10.75 px** puts the
hearts row on the design's y 448 ±2 (proven at real fonts, below). Every row
below keeps the design's `s4` rhythm, so nothing else moved.

### 3. Meadow band — the design's screen gradient, not a feature-local blend

`4_review.md` finding 4 / `5_ui.md` deviation 2 (dark mode read flat navy,
three iterations running):

* the grade now ends on `tokens.kidMeadow` (it was `lerp(horizon, meadow, 0.5)`,
  which never reaches the design's tone at all);
* `stops: [0, gradeSpan / h]` compresses the run into the **design's** span —
  `gradeSpan = 844 − 0.62 × 844 = 320.72` px, because `components.css` l.25 is
  `linear-gradient(180deg, kid-sky-top 0%, kid-sky-bottom 62%, kid-horizon 62%,
  kid-meadow 100%)`. Grading over the band's whole in-flow height (progress +
  every card ≈ 640 px) had only reached t ≈ 0.31 by the dock, which is why dark
  mode looked flat;
* the band's **top edge** is placed on the design's 62 % horizon stop: a
  `NestSpacing.s3` gap plus the band's own `NestSpacing.s1` top inset, which
  reproduces the HTML (where the band is the screen background and never pushes
  content) while keeping the progress bar exactly `s4` below the section title.

Design vs. computed band colour at x = 30 (design PNG ÷3, measured with PIL
this iteration; the app column is the painter's own lerp at that row):

| y | light design | light app | ΔRGB | dark design | dark app | ΔRGB |
|---|---|---|---|---|---|---|
| 540 | (231, 246, 223) | (232, 246, 223) | (1, 0, 0) | (36, 52, 87) | (37, 52, 87) | (1, 0, 0) |
| 600 | (223, 243, 214) | (224, 243, 214) | (1, 0, 0) | (35, 56, 81) | (35, 57, 82) | (0, 1, 1) |
| 660 | (215, 240, 204) | (216, 241, 205) | (1, 1, 1) | (34, 61, 75) | (34, 61, 76) | (0, 0, 1) |
| 700 | (210, 238, 198) | (210, 239, 198) | (0, 1, 0) | (33, 63, 72) | (33, 64, 72) | (0, 1, 0) |
| 712 | (208, 238, 196) | (209, 238, 197) | (1, 0, 1) | (32, 64, 70) | (33, 65, 71) | (1, 1, 1) |

Worst case **1 level per channel** across the whole visible band in both
themes, against the review's measured worst case of (21, 6, 24) light and
(3, 12, 15) dark for the shipped behaviour.

The painter itself stays (`TODO(K03)` re-scoped) because `KidScope` still
cannot express the design's construct: its background has only two gradient
stops (`kidSkyTop` → `kidSkyBottom`) and its hill SVG has a curved crest, while
the design's horizon stop is a **flat horizontal line 62 % down the screen**.
SHARED_REQUEST #6 is marked *partly landed* and re-scoped to exactly those two
missing pieces rather than left stale.

### 4. Nothing else in the view changed

Header, bubble copy, hearts + caption inset, status chip, progress bar, quest
cards (per-quest tints), celebration, failure/empty states, dock
(`wrapLabel: false`) and the bottom-edge handling are untouched and still
pinned by their existing proofs.

## FIXES_7 items (UI / layout / copy scope only)

| Finding | Severity | Status |
|---|---|---|
| 3 — pet slot 34.7 px off-axis, block 40 px too tall | major | **fixed** — §1 + §2; the real-font pin and all three `K03-BUG-13` widths + `K03-BUG-14` are un-skipped and green |
| 4 — meadow is a feature-local painter, flat navy in dark | major | **fixed in the interim the review itself allowed** (§3): grades to `kidMeadow` over the design's span, ≤1 level off both PNGs. Deleting the painter entirely needs the two shared gradient stops → SHARED_REQUEST #6 (partly landed) |
| 5 — duplicate proof parked / cross-frame proof missing | minor | duplicate un-skipped (`k03_bugs_test.dart`, now green); the cross-frame proof is the logic builder's |
| 7 — geometry pin measures the box, not the mandated 198 outline | minor | **done in the honest split** — the box pin stays (it is the shared fix's contract) and the ratio is now asserted: `nest.width * PipNestFallback.visibleNestRatio ≈ 198 ±2`; the painted outline stays the UI stage's job on the capture |
| 6 — mid-session error replaces the screen | minor | logic builder (bloc-only rule) |
| 1 / 2 — BUG-15 retry stacking, analyze at HEAD | blocker / minor | logic builder; `k03_bugs_test.dart` BUG-15 proof un-skipped by me and green, and `flutter analyze` is clean |
| 8 — `switchMapStream` in `domain/` | minor | carried, SHARED_REQUEST #14, no K03 action |

Also from `5_ui.md`: speech bubble (deviation 3) needs **no K03 code** — the
shared component now renders `.speech` with the browser-default line height
(`height: null`), which is the design's full ≈44 px bubble (the "35" was the
inner white area); SHARED_REQUEST #15 is **closed as no-change-wanted** and
K03's typography proof records the browser default instead of pinning 24/16.

## Tests (mine + the proofs the mandate asked me to un-skip)

* `kid_home_geometry_test.dart` — **un-skipped**, real fonts (`FontLoader`
  Inter/Nunito), `the pet slot matches the design geometry`: slot 20…370,
  nest centre **195 ±1**, nest box **236 ±2** (→ 198 visible), Pip centre
  195 ±1, hearts centre **448 ±2**, first card top **559 ±2**. Its header
  comment was rewritten from "PARKED, not passing" to the landed state with
  the before/after measurements.
* `k03_bugs_test.dart` — **un-skipped** `K03-BUG-13` at 320/390/430,
  `K03-BUG-14` (236 px block) and the bugs-stage `K03-BUG-15`; the nest finder
  follows the box to 236; the file's header/case comments rewritten from
  OPEN to FIXED with the shared fix named.
* `kid_home_view_test.dart` — `the nest box is 236×156 and the Pip exactly 152
  tall` (renders the rect, the 198-outline ratio, and asserts
  `explicitLayout`), and **two new painted-pixel proofs** (light + dark)
  `the painted grade reaches the dock row`, which run the real
  `_MeadowPainter` into a `ui.PictureRecorder` and read back the design's y 719
  row (UI CHECK MEASURES SHAPES: a shape/paint assertion, not a text one).
  Plus two meadow assertions (band top on the horizon stop, band bottom below
  card 1).
* Three stale expectations fixed, all consequences of the shared work rather
  than of a defect: the Pip test pinned `NestPetStage.pipSize == 152` (explicit
  mode ignores `pipSize`; the design cap is `fixedPipHeight`), the typography
  proof pinned `.speech` height 24/16 (the shared bubble now uses the browser
  default), and my own grade probe sampled `t × h` — past the 320.7 px run, so
  it could only ever prove the flat `kidMeadow` clamp; it now samples the row
  `intoRun` px below the band's top edge.

## Verification (in `app/`)

| gate | command | result |
|---|---|---|
| format | `dart format --set-exit-if-changed --output=none lib/features/kid_home test/features/kid_home` | ✅ `24 files (0 changed)` |
| analyze | `flutter analyze lib/features/kid_home test/features/kid_home` | ✅ **No issues found!** |
| my view tests | `flutter test test/features/kid_home/kid_home_view_test.dart` | ✅ **+73: All tests passed!** |
| real-font geometry | `flutter test test/features/kid_home/kid_home_geometry_test.dart` | ✅ **+1: All tests passed!** |
| un-skipped bug proofs | `flutter test test/features/kid_home/k03_bugs_test.dart` | ✅ **+51: All tests passed!** (was 46 pass + 5 skip) |
| feature suite (not whole-app) | `flutter test test/features/kid_home/` | ✅ **+154: All tests passed! — 0 skipped, 0 failed** (iteration 7: `+143 ~6 -1`) |

No whole-app `flutter test` and no simulator: the integrator's job.

## Owner rules re-checked on this chunk

* **ALIGNMENT** — the pet slot's +34.7 px offset is gone (nest and Pip on the
  195 axis at 320/390/430); the 20 px gutters, dock edges and card edges are
  untouched and still pinned.
* **BOTTOM EDGE** — untouched; the meadow still ends at the dock's top border
  and the dock's own surface fills to the physical edge (light + dark proofs
  green, including under a 34 px inset).
* **PIP** — child's own `PipAvatar` from the DB row, design slot size; no v1
  stage SVGs.
* **BALANCED HEADINGS** — `.kid-title` still `NestBalancedText`, and it is
  still the only balanced text on the screen.
* **COPY / FONTS / LETTER SPACING** — no string changed in this chunk;
  `grep` finds no `google_fonts`/`GoogleFonts` in the feature or its tests and
  no `letterSpacing` anywhere in the view.
* **DESIGN SYSTEM** — no hex colour, no `Colors.*` beyond the pre-existing
  `Colors.transparent`, no new component: colours are `tokens.kidHorizon` /
  `tokens.kidMeadow`, spacing is `NestSpacing.*`, and the three pet numbers are
  named, design-cited constants (the file's established pattern).
* **UI CHECK MEASURES SHAPES** — the new proofs read rects and painted pixels
  (nest box + ratio, band rect, band paint), not just text positions.

## LEFT FOR NEXT ITERATION

1. **`_MeadowPainter` deletion** — blocked on the two shared pieces re-scoped in
   SHARED_REQUEST #6: `KidScope`'s flat 62 % horizon stop and the
   horizon→meadow grade. The band is in-flow (it scrolls with the content), so a
   scrolled frame is not a pixel-exact match of a screen-fixed background; the
   first frame is what the UI stage measures and it now matches both PNGs.
2. **Crest detail** — the band's top edge is a 6 px hill curve (pre-existing,
   from FIXES_1); the design's horizon is a flat line. Same shared blocker as
   above; not re-requested separately.
3. **Painted-outline confirmation** — `K03-BUG-13/14` and the geometry pin are
   box/prop proofs plus a ratio; the **painted** 198 px outline on the device
   capture is the UI stage's measurement (review finding 7's split). No
   simulator used here.
4. Nothing else in my layer. K03-BUG-13/14/15, the geometry pin and the
   subscription guard are all green; the remaining open items (SHARED_REQUEST
   #14 `switchMapStream` location, review finding 8) are shared/architecture
   and owned elsewhere.

VERDICT: PASS