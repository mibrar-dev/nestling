# K03 Kid home — QA code review (Stage 4, iteration 8)

Scope: feature `kid_home`, route `/kid-home`, kid mode, design (light + dark)
`design/screens/{light,dark}/K03-kid-home.png`. Reviewed `git diff main...HEAD`
**plus the current working tree**, so the verdict reflects the code as it
stands. Per the orchestrator rules, uncommitted work / being behind `main` /
merge order are not findings and are not reported. No simulator was booted
(stage 5 only); all geometry below is pixel measurement of the committed
captures plus arithmetic on the shared components.

## Gates run (in `app/`, this iteration)

| gate | command | result |
|---|---|---|
| format | `dart format --set-exit-if-changed --output=none .` | ✅ `Formatted 401 files (0 changed)` |
| analyze | `flutter analyze` | ✅ `No issues found!` |
| test | `flutter test` (full suite) | ✅ **`+1361: All tests passed!`** |
| skipped proofs | `grep -rn "skip:" app/test/features/kid_home/` | ✅ **zero matches** — the suite has no parked tests |
| geometry | PIL measurement of `ui/app_light_8.png` + `ui/app_dark_8.png` against `design/screens/{light,dark}/K03-kid-home.png`, ÷3 | see tables below |

**Iteration-7's blocker is gone.** The suite is green at `+1361` with no
skips, `flutter analyze` reports no issues (iteration-7 finding 2 closed), and
all six previously-parked proofs (`K03-BUG-13` ×320/390/430, `K03-BUG-14`,
`K03-BUG-15`, and `the pet slot matches the design geometry`) run un-skipped
and pass. `2_build.md`'s claims are now reproducible.

## Shape comparison — measured, light, 390×844 (logical px)

Every landmark the design fixes, measured with the same detector on both PNGs:

| landmark (logical px) | design | `app_light_8.png` | Δ |
|---|---|---|---|
| nest **visible outline** x | 96.0…293.7 (w 197.7, cx **194.8**) | 96.0…293.7 (w 197.7, cx **194.8**) | **0.0** ✅ |
| nest **rim height** at x 102 | 311.3…349.3 (**38.0**) | 343.0…368.0 (**25.0**) | **−13.0** ❌ f1 |
| nest widest row (y) | 327 | 353 | **+26** ❌ f1 |
| speech bubble interior | y 128…165, x 99.0…290.7 | y 128…166, x 99.3…290.3 | ≤0.7 ✅ |
| hearts row | y 442.3…455.0, x 25.0…142.7 | y 442.3…455.0, x 25.0…142.7 | **0.0** ✅ |
| "Today's quests" ink | 483…506 | 483…506 | **0** ✅ |
| section chip (leaf-tint rect) | y 478…509 (h 32), x 266.0…369.7 | y 478…509 (h 32), x 266.0…369.7 | **0** ✅ |
| progress bar ink borders | 527…528 / 541…542 | 527…528 / 541…542 | **0** ✅ |
| progress fill | y 529…540, 50 % of track | y 529…540, 67 % of track | height **0** ✅, width = live 4/6 ✅ |
| card 1 top / bottom border | 559 / 644…646 | 559 / 644…646 | **0** ✅ |
| card 1 internals at y 603 | border 20.0…22.7, pad → 35.0, tile 35.0…83.0 (48) | identical | **0** ✅ |
| card 2 top border | 659 | 665 | **+6** ❌ f2 |
| dock top border | 719…721 | 719…721 | **0** ✅ |
| dock buttons (outer edges) | 20.0…128.7 / 141.0…248.7 / 261.0…369.7 | 20.0…128.3 / 140.7…249.0 / 261.3…369.7 | ≤0.7 ✅ |
| dock button bands | 734…736 / 797…799 | 734…736 / 797…799 | **0** ✅ |
| bottom edge below the dock | *meadow* `(208,238,196)` @ y 843 | dock surface `(255,255,255)` @ y 843 | n/a — **the app is right, see below** |
| meadow tone at x 30, y 530…718 | — | ≤1 level off at every sampled row | ~0 ✅ |

Dark mode (`ui/app_dark_8.png`, fresh) reproduces every full-width ink band
identically to the design PNG — progress 527…528 / 541…542, card 1 559…561 /
644…646, **card 2 665…667 vs the design's 659…661** (the same +6 as light),
dock 719…721, buttons 734…736 / 797…799 — and the nest's loose brown extent is
again `101.7…288.0` in both. The one *intentional* difference is the bottom
strip: the design PNGs paint the meadow hill down to y 843, but the owner's
BOTTOM EDGE rule overrides the designs ("Never show a coloured strip … in light
or dark mode"), so the app correctly runs the dock's own surface to the
physical edge — light `#FFFFFF`, dark `#1F1C2E`, measured at y 725/830/843 with
nothing coloured around the home indicator.

Iteration-7 finding 3 (pet slot 34.7 px off-axis, quest column 56 px low) is
**fixed**: the nest is now pixel-exact horizontally and on the axis, and every
row from the hearts down to the dock lands on the design's y. Iteration-7
finding 4 (meadow flat navy in dark) is **fixed**: the in-flow band now grades
`kidHorizon → kidMeadow` over the design's own 321 px run, which reproduces the
design dark PNG to the level (see finding 4's note).

## Verified clean (no finding)

- **RULES §1 paths** — diff and working tree touch only
  `app/lib/features/kid_home/**`, `app/test/features/kid_home/**`,
  `docs/screens/K03/**`. No `core/`, `app/`, other feature, `tools/screens/`,
  `analysis_options.yaml`.
- **ARCHITECTURE** — feature-first; `domain/` = `kid_child`, `kid_quest`,
  `kid_home_data` + the abstract repository; one bloc for the feature;
  `kid_home_di.dart` (a `registerFactory`, so no shared-bloc-across-routes
  hazard), `kid_home_routes.dart`, `kid_home.dart` untouched. Only finding 6
  contests `domain/`, for a reason already requested in SHARED_REQUEST #14.
- **PIP rule** — every Pip is the active child's own `PipAvatar` fed from the
  DB row (`kid_home_view.dart:281, 289, 732, 917`), `style/skin/accessory/stage`
  via `_pipStyle/_pipSkin/_pipAccessory`. No `pip_stage_*.svg`, no `PipRive`,
  no `riveEnabled` in the feature; the failure, empty and no-child states all
  show the known child's Pip (or the neutral look when no child is known).
- **PERIODS ruling** — `countsForCurrentPeriod` on the read path
  (`kid_home_repository_impl.dart:80-82`) and inside the write transaction
  (`:158-183`) with the family zone (`createdAtTz: Value(zone)`); the
  daily/weekly/once and London day/week proofs run un-skipped.
- **CHILD ORDER** — `watchProfiles()` (`:98-102`) passes the shared
  `watchChildren` (now `createdAt`-ordered) straight through; the six-children
  probe runs un-skipped.
- **COPY** — the HTML's only non-ASCII is in `<title>` (`—`, `·`), never
  rendered; every visible glyph is ASCII, so the screen's straight `'` in
  `Let's do some quests!`, `Today's quests`, `Waiting for Mum` and
  `Mum's thumbs-up` is correct, and `lib/features/kid_home` contains zero
  non-ASCII characters. The design's `&ndash;` renders as U+2013 and the seed
  title carries exactly that (`seed.dart:279`). UK spelling; coins only, never
  `£`. The card 2 content difference (app shows another done quest, design
  shows "Reading – 20 minutes") is DATA OVER MOCKS + title order, recorded in
  SHARED_REQUEST #10.
- **BOTTOM EDGE (owner rule)** — measured on both fresh captures: light
  `#FFFFFF` and dark `#1F1C2E` at x=30 and x=360 from y 722 to 843, no
  meadow/sky strip, nothing coloured around the home indicator. This
  deliberately differs from the design PNGs, which paint the meadow hill to
  y 843 — the owner rule overrides the designs here, and the app is correct.
  The dock's `SafeArea(top: false)` inside the surface box (`:587-676`) is the
  right shape.
- **ALIGNMENT (owner rule)** — 20 px gutters on the header, section row, cards
  and dock; card 1's border at x 20.0 and the tile at 35.0 are identical to the
  design; dock button outer edges exact, internals ≤0.7 px.
- **DESIGN-SYSTEM usage** — no hex colours, no `Colors.*` except
  `Colors.transparent` on the `Scaffold`, no `google_fonts`/`GoogleFonts`, no
  `letterSpacing` override, no `// ignore:`/`ignore_for_file:` anywhere in the
  feature. `.kid-title` renders through `NestBalancedText` (`:506`) per the
  BALANCED HEADINGS rule, `tileBackground` and `wrapLabel: false` are used,
  `KidStatusChip` is a justified feature-private leaf (shared `NestChip` is
  parent-mode Inter 14 with a leaf border; `.kchip` is Nunito 800 15/15 on
  `leaf-tint` with no border). No local forks of the pet stage, bubble or
  hearts remain.
- **Accessibility** — lock 56 px, quest check 28 px ring + 8 px padding = 44 px,
  composed `Semantics` labels on the header, hearts, pet stage and progress,
  dock labels pinned to one line at 1.3×, no raw error string ever shown to a
  child (the failure card and the toast are fixed copy).
- **Children's Code** — no analytics, ads, SDK, network, `print` or
  `subscription_status` in the feature (grep); only the **active** child's
  nickname, coins, happiness and Pip look are read; nothing is written outside
  that child's own completions.
- **Error handling / lifecycle** — `_onLoadRequested` owns one
  `StreamSubscription` and releases it on error and in `close()`
  (`kid_home_bloc.dart:26-53, 119-124`); a mid-session stream error keeps the
  loaded list and only a load with nothing to show becomes the failure card
  (`:89-99`), matching the completion-failure path.

---

## Findings

### 1. [major] The nest is stretched to 66 % of the design's vertical scale and sits ~26 px low

`app/lib/features/kid_home/presentation/views/kid_home_view.dart:77`
(`const double _kNestBoxHeight = 156;`) passed at `:739-741`, combined with
`app/lib/core/design_system/motion/pip_rive.dart:581` (`fit: BoxFit.fill`).

The design renders `.k3-pet .nest` as a 260×236 `<img>` of `nest.svg`
(240-space) with the SVG's default `xMidYMid meet`, so the art keeps its aspect:
236×236 centred, and the visible bowl comes out ≈198 wide × ≈102 tall. K03
passes a 236×**156** box, and `BoxFit.fill` stretches the art vertically to
`156/236 = 0.661`. Measured on `ui/app_light_8.png` with the same detector on
both PNGs:

| | design | app | Δ |
|---|---|---|---|
| nest outline, horizontal | 96.0…293.7 (197.7) | 96.0…293.7 (197.7) | 0 ✅ |
| nest rim height at x 102 | 38.0 | 25.0 | **−13.0** |
| nest rim height at x 290 | 30.7 | 20.4 | **−10.3** |
| bowl widest row (bowl centre) | y 327 | y 353 | **+26** |
| bowl bottom | ≈378 | ≈387 | +9 |

Dark mode shows the same distortion independently: the nest's dark stroke at
x=102 spans y 311…350 (**40**) in `design/screens/dark/K03-kid-home.png` and
y 343…368 (**26**) in `app_dark_8.png` — 26/40 = 0.65, the same `156/236`, so
the cause is theme-independent.

The row scan at the bowl's widest row is byte-identical horizontally
(`ink 96–101 · brown 102–121 · light 122–128 · ink 129–138 · dark brown 139–158 ·
cream 159–230 · …` in both), which proves it is the *same* `nest.svg` at the
*same* width — only the vertical scale differs, and 25.0/38.0 = 0.658 matches
`156/236` to three digits. So the hero bowl renders a third too flat and its
widest point sits 26 px below the design, and this fails the orchestrator's own
stated target in `ORCHESTRATOR_NOTES` UPDATE (08:32) #35 ("Visible nest
outline: … y ≈ 278 → 364").

**Not fixable from K03 — the arithmetic is closed.** `explicitGeometry`
(`pip_rive.dart:519-533`) gives `nestTop = max(6, pipH − (nestRimTopFraction·nestH
+ rimOverlap)) = max(6, 132 − 0.3958·nestH)` and
`stageH = nestTop + nestH + 10`. With `fixedPipHeight: 152` and
`rimOverlap: 20`, forcing `stageH = 236` (the design's `.k3-pet` slot) gives
`nestH = 155.6` — i.e. the current 156 is the *only* value that keeps the
block at 236. Preserving the design's nest aspect needs `nestH ≈ 214`, which
yields `stageH ≈ 271`, i.e. 35 px taller than the slot; absorbing that needs a
stage→hearts gap of `10.75 − 35 ≈ −24`, and `ORCHESTRATOR_NOTES` #35 forbids
negative margins. `BoxFit.contain` alone does not help either: in a 236×156 box
the art would render 156×156 and the bowl would shrink to ≈131×71 — further
from the design.

**Fix (shared — SHARED_REQUEST #16, new).** `PipNestFallback` needs the nest
*art* box to be expressible independently of the *stage* height, because the
design's own geometry does exactly that (`.k3-pet` 260×236 with `.nest`
260×236 filling it, art `meet`-fitted, bowl seated in the lower middle with the
ground shadow at the bottom). Concretely: keep `fit: BoxFit.fill` out of the
way, add an art-box/aspect parameter (e.g. `nestArtHeight:` or
`PipNestFallback.nestAspect`) so the caller can ask for a 198-wide outline with
the art's 260:236 aspect, and derive `nestTop` / `stageH` from the *visible*
rim + bowl + shadow instead of from the full art box. K03's target call then
becomes `nestWidth: 236` (or `visibleNestWidth: 198`), art box 236×236, bowl
widest row on y 327, block still 236 — which keeps the hearts/title/progress/
card landmarks that are now pixel-exact exactly where they are.

Per `ORCHESTRATOR_NOTES` #35 DO 3 K03 did not hack around this; the call it was
told to use verbatim is the one that produces the distortion. The orchestrator
must either land #16 or rule that the bowl's aspect yields to the lower-stack
y targets.

### 2. [minor] Card rhythm is 18 px instead of the design's 12 px, and the drift accumulates

`app/lib/core/design_system/components/nest_quest_card.dart:168`
(`padding: const EdgeInsets.only(bottom: 6)`) sits inside
`kid_home_view.dart:558` (`Column(spacing: NestSpacing.s3)` = 12).

`.k3-quests { gap: 12px }` (`K03-kid-home.html:30`) is what K03 implements, and
that is correct — but the shared card adds its own 6 px bottom padding on top,
so painted cards sit 18 px apart instead of 12:

| | design | app |
|---|---|---|
| card 1 top border | 559 | 559 |
| card 1 bottom border | 644…646 | 644…646 |
| card 2 top border | **659** | **665** |
| gap (border row to border row) | 13 | 19 |

Each card is 6 px lower than the design, accumulating to 30 px by card 6. The
6 px is not a magic number in K03 and must not be compensated with a
`NestSpacing.gap6` column — that would double-correct once `core` is fixed.
Fix (shared): the shadow room the padding creates belongs to the caller's
spacing, not inside the card; either drop the padding and let
`tokens.kidShadow`'s offset be absorbed by `.k3-quests`' gap, or make it a
`shadowPadding` parameter. File as SHARED_REQUEST #16 alongside finding 1 (same
component, same screen, one batch).

### 3. [minor] The geometry pin measures the nest BOX and never the painted outline (iteration-7 finding 7, still open)

`app/test/features/kid_home/kid_home_geometry_test.dart:101-105` asserts
`nest.width closeTo(236, 2)` — the `SvgPicture` box — and puts the intent in a
`reason:` string only. A widget test cannot sample painted alpha, so the pin
stays green if `PipNestFallback.visibleNestRatio` changes and the design's
198 px outline drifts.

Fix (in scope, no shared change needed): the shared API already has the honest
parameter. Pass `visibleNestWidth: 198` instead of `nestWidth: 236`
(`nest_pet_stage.dart:135-140` divides by `visibleNestRatio`, so the outline is
then 198 *by construction*, immune to ratio drift), and update the pin to
`expect(nest.width * PipNestFallback.visibleNestRatio, closeTo(198, 2))`. The
236-wide box this yields (235.3) still satisfies the existing ±2 box assertion,
so nothing else changes.

### 4. [minor] The meadow band is still a feature-local painter although `KidScope` grew the API for it

`kid_home_view.dart:536-540` (`CustomPaint(painter: _MeadowPainter(...))`) and
`:758-797`, still marked `TODO(K03)`.

`KidScope` grew `meadowHeight` / `meadowBottom` / `meadowColor`
(`core/design_system/theme/kid_scope.dart`) and its doc comment names K03, but
K03 paints its own band, so the duplication `ORCHESTRATOR_NOTES` iteration 4
forbade ("rely on `KidScope`'s meadow … instead of painting a second hill") is
still in the tree. The blocker is real and already on record: the design paints
the **screen** background gradient (`components.css:25`, with a flat 62 %
horizon stop and a horizon→meadow grade), and `KidScope`'s background has only
two stops while its hill SVG has a curved crest, so no height parameter
reproduces a straight horizon line.

This is **ownership only, not a visual defect** — the interim band now measures
≤1 level off the design PNG in **both** themes across y 530…718 (worst Δ = 1 in
dark: app (35,61,77) vs design (34,60,77) at y 650, app (37,54,87) vs design
(37,53,87) at y 548). The arithmetic behind it is exact, not approximate:
`gradeSpan = 844 − 0.62·844 = 320.7` over a band that starts on y 523 and is
692 tall gives `lerp(kidHorizon #253359, kidMeadow #1E4A3A, 0.6079)` =
(33, 65, 70) at y 718, which is the design dark PNG's pixel at that row. Keep
the local band, keep the `TODO`, and let SHARED_REQUEST #6 carry the two
missing gradient stops.

### 5. [minor] `844` is hard-coded twice instead of `NestDevice.height`

`kid_home_view.dart:772` (`static const double gradeSpan = 844 - 0.62 * 844;`).
`NestDevice.height` (`tokens/spacing.dart:67`) exists precisely for the design's
390×844 baseline and the rest of the file uses `NestSpacing`/`NestDevice`
throughout. Fix: `static const double gradeSpan = NestDevice.height * (1 - 0.62);`

### 6. [minor] `switchMapStream` still sits in `domain/` (carried)

`app/lib/features/kid_home/domain/kid_home_repository.dart:54-82` — a generic
stream combinator, not a domain abstraction; `ARCHITECTURE.md` keeps `domain/`
to "entities + abstract repository ONLY" and
`core/data/stream_combine.dart` already owns `combineLatest2/3/4`. Requested in
SHARED_REQUEST #14 (unchanged since iteration 6). No action available in K03;
kept on the list so the record is complete.

---

## Note for stage 5 (not a finding)

`ui/app_dark_8.png` and `ui/cmp_{light,dark}_8.png` landed mid-review and are
good — the dark capture agrees with light on every landmark (see above). Two
housekeeping items, neither a code finding:

- `ui/app_dark_8b.png` (untracked) is **not a K03 dark render** — sampled rows
  are bright mint at y 530 (`(163,228,220)`) and a saturated blue dock at y 800
  (`(29,86,162)`), matching neither design nor any earlier capture. Delete it or
  replace it; do not compare against it.
- The nest distortion (finding 1) and the card rhythm (finding 2) will dominate
  the band table's heat map. Both are shared-owned (see finding 1), so stage 5
  should record them rather than re-derive them.

## Verdict

The screen is in genuinely good shape and iteration 8's mandates landed: the
suite is green at `+1361` with zero skipped proofs, `flutter analyze` is clean,
the retry-path subscription leak is fixed, the pet slot is centred and its
outline is pixel-exact, and every row from the hearts down to the dock — chip,
progress bar, card 1, dock, bottom edge — now lands on the design's y in **both
themes**, with the meadow within 1 level of the design PNGs. Every measured
landmark except one is exact.

One major finding remains: the hero nest is stretched to 66 % of the design's
vertical scale and sits ~26 px low (finding 1), confirmed independently on both
the light and the dark device captures. It is caused by the call the
orchestrator mandated verbatim plus `BoxFit.fill` in the shared fallback, it is
arithmetically unreachable from K03, and it is the visible residue of
iteration-7's pet-slot finding — so the screen's centrepiece still does not
match the design. Findings 2–6 are minor and none require code changes before
the next pass; finding 1 needs SHARED_REQUEST #16 and an orchestrator ruling.

Fix is not available inside K03. Escalate finding 1 (and finding 2, same
component) as SHARED_REQUEST #16, take finding 3's `visibleNestWidth: 198`
change in the next build, and re-run the gates and the band table.

VERDICT: FAIL