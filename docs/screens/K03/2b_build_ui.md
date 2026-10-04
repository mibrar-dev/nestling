# K03 Kid home — Stage 2b UI chunk (iteration 13)

Scope: `app/lib/features/kid_home/presentation/views/**` (one file changed:
`kid_home_view.dart`), plus the view/widget tests
`test/features/kid_home/kid_home_geometry_test.dart`,
`kid_home_view_test.dart` and the one bug proof in `k03_bugs_test.dart` that
FIXES_12 hands me. No domain/data/bloc/route/DI file touched.
`2a_build_logic.md` (iteration 13) re-read before finishing: **no CONTRACT
CHANGES**. No simulator was booted, installed on, driven or screenshotted
(SIMULATORS rule — stage 5 only).

## The two mandated changes, both landed and measured

`shared/pet_bubble_gap` and `shared/kid_meadow` are on main
(`ORCHESTRATOR_NOTES` 15:02 and 02:45), so this iteration spends the design's
own values instead of the iteration-12 workaround:

1. **`NestPetStage(bubbleGap: NestSpacing.gap14)`** — the design's own
   `.k3-pet { margin: 14px auto 0 }` — and **`_kStageToHearts` 21 →
   `NestSpacing.s4`**. The 30-line workaround comment is deleted; what is left
   is the HTML's arithmetic and nothing else.

   Measured at the design's real fonts (`kid_home_geometry_test.dart`, ±0.5,
   all passing):

   | row | design | app |
   |---|---|---|
   | `.speech` border box | 125…169 | 125.0…169.0 |
   | `.k3-pet` box | 183…419 | 183.0…419.0 |
   | hearts centre | 448 | 448.0 |
   | "Today's quests" row (32 px chip) | 494 | 494 |
   | progress bar | 527…542 | 527…542 |
   | first card top | 559 | 559 |
   | card rhythm / dock top | 12 / 720 | 12 / 720 |

   So the bubble, the pet box and **every** row below it now sit on the design's
   rows — the 15:02 targets are exact, not approximate.

2. **K03's own meadow band is gone** (`ORCHESTRATOR_NOTES` 02:45 /
   `docs/screens/_shared/kid_meadow_REPORT.md`): `_MeadowPainter`, the
   `_kCrest*` constants, the `CustomPaint` wrapper and its `TODO(K03)` are
   deleted. The lower content area is now the shared `KidScope` background, so
   the screen paints exactly what `components.css` l.25 describes (four-stop
   gradient, hard stop at 62 %) with the shared 390×136 hills pinned at the
   screen bottom, and K03 paints no hill or meadow of its own (KID BACKGROUND
   rule). The `12 + 4 px` that positioned the old band becomes the single
   `.scroll > * + *` gap the HTML has (`NestSpacing.s4`), so no row moves.

   Verified, not assumed: the painted grades at (10, 600) and (10, 700) in
   **both** themes still match the design RGBs (`kid_home_geometry_test.dart`,
   4/4) with no local painter in the tree, and `kid_home_view_test.dart`'s
   meadow group now pins the shared gradient's colours/stops and the hills'
   geometry (390 × 136, bottom 0) plus `expect(localBand, findsNothing)`.

## FIXES_12 — K03-BUG-16: 9–10 px → 4 px, and the last 4 px is one private constant

`bubbleGap: 14` removed the half of the deviation K03 could reach: the hero art
went from rim 269 → **274.0**, feet 292 → **297.0**, head 190 → **194.4**
against the design's 278 / 301 / 199. The remainder is *not* reachable from
this feature:

- `PipNestFallback.explicitGeometry` seats the nest box at
  `nestTop = _explicitSlotH - nestH - _explicitBleed` = 236 − 188 − 31.4 =
  **16.6**, so the rim lands 91.0 px below the block top where the design's box
  paints it 95 px down. `_explicitBleed` is `private` in
  `core/design_system/motion/pip_rive.dart`, and RULES §1 forbids editing
  `core/`.
- So the parked proof stays parked, with the **design's** value (rim 278) and
  the new numbers in its doc comment — `ORCHESTRATOR_NOTES` 07:40 item 3 is
  explicit: if the shared component cannot produce it without editing core, do
  not hack around it; write the request with the numbers and stop. SHARED_REQUEST
  **#18** is updated to exactly that: option (b) `_explicitBleed` 31.4 → 27.4
  (one line, puts every hero row inside ±2 px, and the four geometry pins move
  to 278 / 364 / 301 / 198 by changing four constants).
- The geometry pins hold the design's targets **minus** that 4 px at **±0.5**
  (274.0 / 360.2 / 297.0 / 194.4), with the design's number and the shared
  constant named in each `reason`, so the residual can only shrink — the
  iteration-12 complaint about a loose pin cannot recur.

### New finding for the shared owner: the bowl is squashed (22 px)

Measured off `design/screens/light/K03-kid-home.png` ÷3 while checking the
residual: at x 195 the bowl's ink runs **275.3…384.7** (≈109 tall) and the
outline's widest row is y 330, x 95.7…294 (198.3 wide). Same asset, but with
its 202/240 *width* ratio **and** its 110/240 *height* ratio both at full size —
i.e. a ~236×236 box bottom-pinned in the pet box, which is exactly what the
HTML's `.k3-pet .nest` (260×236, `bottom: 0`) draws. The app's 236×188 box
(which `ORCHESTRATOR_NOTES` 10:14 mandates) squashes the bowl by 22 px.

`nestHeight: 236` alone is *not* the fix: with today's 31.4 bleed the rim would
land at 183 + 61.9 = **245**, 30 px high. Option **(c)** — `_explicitBleed` → 0
together with `nestHeight: 236` — restores the position *and* the design's bowl
height (rim 276.4, bowl bottom 384.7). Both are written up in SHARED_REQUEST
#18 with the pixel evidence; the decision is the shared owner's.

## Test changes

- `kid_home_geometry_test.dart` — hero pins re-expressed (above) at ±0.5;
  **new** pins for the 15:02 targets the bubble gap bought (`125…169`,
  `183…419`, ±0.5); header note rewritten for this iteration.
- `kid_home_view_test.dart` — the whole `K03 meadow band` group (which drove
  the deleted painter through `dynamic` reflection) is replaced by
  `K03 shared kid background (no local meadow)`: the four gradient stops and
  `[0, 0.62, 0.62, 1]`, the hills' rect, and the absence of any local band, in
  both themes. The now-unused `_meadowBandFinder` and its `dart:ui` import are
  deleted.
- `k03_bugs_test.dart` — K03-BUG-16's doc comment and the file header updated
  with the new measurements. **Still skipped, deliberately** (see above); it is
  the design-value proof that cannot silently re-base. It is the suite's only
  parked proof, as before (`grep skip:` → K03-BUG-16 + K01's, which is another
  loop's screen).

## Owner / orchestrator rules re-checked

- **PIP** — unchanged: the child's own `PipAvatar` (Maya: Mochi · sunny ·
  stage 3) through `NestPetStage(pip:)`, in the failure and empty states too.
- **KID BACKGROUND / BOTTOM EDGE** — the shared kid scope now paints every
  meadow pixel; the dock's own `Container(color: tokens.surface)` still wraps
  its `SafeArea(top: false)`, so the bar runs from y 720 to the physical edge in
  both themes with no hill or sky strip under it (the hills sit *above* the
  dock's top edge, exactly as the HTML puts them, and the pin at
  (10, 600)/(10, 700) confirms the grade above it).
- **ALIGNMENT** — 20 px gutters unchanged; the removed band's 4 px inset was
  absorbed into the section→progress gap, so no card, bar or edge moved.
- **COPY / FONTS / LETTER SPACING / CHIP ROWS / BALANCED HEADINGS / SHAPES /
  TRIAL / ACCESSIBILITY ACTIONS / PERIODS / CLOCK / CHILD ORDER / DATA OVER
  MOCKS** — no copy, font, chip, semantics or data path touched. This iteration
  changed two numbers and deleted a painter.
- No `analysis_options.yaml` change, no `flutter clean`, no simulator, no
  whole-app `flutter test` (the integrator's).

## Verification (in `app/`, this worktree)

- `dart format lib/features/kid_home test/features/kid_home` → 0 changed.
- `flutter analyze lib/features/kid_home test/features/kid_home` →
  **No issues found!**
- `flutter test --timeout 120s test/features/kid_home/` → **+342 ~2, all
  passed** (the whole feature folder, so nothing in the bloc/repository suite
  broke; 2 skipped = K03-BUG-16 and K01's parked proof).

## LEFT FOR NEXT ITERATION

- **SHARED_REQUEST #18(b)** — `_explicitBleed` 31.4 → 27.4 (one line) closes
  the last 4 px; option **(c)** (`_explicitBleed` → 0 + `nestHeight: 236`)
  additionally restores the design's ~108 px bowl height. K03's four pins move
  to the design's numbers by changing four constants.
- **SHARED_REQUEST #17b(b)** — the tail's 3 px padding-box offset (no layout
  impact) and **#16(b)** — `_kQuestCardShadowRoom` (`.k3-quests` gap 12 vs the
  card's 6 px shadow reserve) are unchanged and still open.
- A device UI check (stage 5) to re-measure the band table now that the bubble,
  the pet box and every row below are exact and the meadow is the shared
  background: bands 3–5 should drop, and the hero band should shrink to the
  4 px + the bowl's height.

VERDICT: PASS