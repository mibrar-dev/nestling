# Shared request — K03 Kid home

1. DONE on main (Stage 2b iteration 7 verified): `NestKidQuestCard` now
   accepts `tileBackground`; K03 passes per-quest tint (see view). Preferred
   semantics: the K03 HTML
   tinted tiles per quest (`sky-tint` dishwasher, `lilac-tint` reading,
   `peach-tint` tidy). An optional tile background parameter would close
   the drift. Files: `app/lib/core/design_system/components/nest_quest_card.dart`.
   Blocks: no — shipping with `surface2` tiles, drift noted for compare.
2. Need: stale design copy only — PNG/HTML say "3 of 6 done" but the demo DB
   yields 4 of 6 (dishwasher + table pending, bins + hoover approved). No
   seed change wanted (RULES §4); either accept live "4 of 6 done" or update
   the PNG copy. Blocks: no.
3. DONE on main (Stage 2 iteration 2 verified): commit `ded8eb9` gates
   `/today-empty`, `/quest-editor` (plus all `_onboardingLocations`) from
   kid mode, with a router test enumerating parent paths. K03-BUG-5 proofs
   un-skipped and passing. No action needed.
4. DONE on main (Stage 6 iteration 2 re-verified): the PERIODS ruling added
   `countsForCurrentPeriod` / `londonDayStartUtc` / `londonWeekStartUtc` and
   K03's `watchItems` now scopes status to the quest's current London period.
   The day-boundary proof runs un-skipped and passes (daily/weekly/once
   probes added; BST switch days covered). No action needed.
5. DONE on main (Stage 6 iteration 5 re-verified): shared batch `4751c52`
   (`7eaa1f7`) makes `env_flags.dart` parse the documented
   `DISABLE_ANIMATIONS=1` as true
   (`bool.fromEnvironment(...) || String.fromEnvironment(...) == '1'`).
   The `K03-BUG-7` proof passes under `=1` and the still-frame path is
   taken; `shot.sh` frames are deterministic again. No action needed.
6. PARTLY LANDED (review finding 1c, iteration 5; revisited iteration 8):
   `KidScope` grew `meadowHeight` / `meadowBottom` / `meadowColor`
   (`core/design_system/theme/kid_scope.dart`, shared batch `7eaa1f7`), so
   the *parameter* half is done — but K03 still paints its own in-flow band
   (`_MeadowPainter`, still `TODO(K03)`) because what the design draws is
   the SCREEN background gradient (`components.css` l.25
   `linear-gradient(180deg, kid-sky-top 0%, kid-sky-bottom 62%,
   kid-horizon 62%, kid-meadow 100%)`), and two pieces of it are still
   missing in `core/`: (a) the flat horizontal 62 % horizon stop —
   `KidScope`'s hill SVG has a curved crest, so no height parameter
   reproduces a straight horizon line; (b) the horizon→meadow grade, since
   `KidScope`'s background has only two stops (`kidSkyTop` →
   `kidSkyBottom`). Iteration 8's interim fix grades K03's local band to
   `tokens.kidMeadow` over the design's own 321 px run, so both themes now
   match the PNGs; request re-scoped to the two missing gradient stops.
   Files: `app/lib/core/design_system/theme/kid_scope.dart`,
   `app/lib/core/design_system/components/nest_pet_stage.dart`'s hill asset
   owner (`meadowHill`).
   Blocks: no (local panel stays until the flat stop lands).
7. DONE on main (Stage 2b iteration 6 verified): `NestType.kidName`,
   `NestType.kidCaption` and `NestType.kidChipLabel` exist
   (`app/lib/core/design_system/tokens/typography.dart:128,134,138`) with the
   exact values requested. K03's four call sites (view ×3, `kid_status_chip`
   ×1) now use them and `google_fonts` is gone from the whole feature —
   `grep -rn "google_fonts\|GoogleFonts" app/{lib,test}/features/kid_home`
   returns nothing. Exemption on record for the sub-17 px kid copy is
   unchanged: the K03 HTML uses 15 px, below DESIGN_SPEC §0.9's 17 px kid
   minimum; the shared styles encode the design per `1_plan.md` §(a)/(e).
   Original need below for the trail. Blocks: no.
   Need (review finding 3, iteration 5): kid type styles missing from
   `NestType` — `kidName` (Nunito 22/26 w900 ink), `kidCaption` (Nunito
   15/20 w700 ink2), `kidChipLabel` (Nunito 15/15 w800 leafInk) — so K03
   can stop calling `GoogleFonts.nunito` directly. Exemption on record:
   the K03 HTML uses 15 px kid copy, below DESIGN_SPEC §0.9's 17 px kid
   minimum; the screen follows the design per `1_plan.md` §(a)/(e).
   Files: `app/lib/core/design_system/tokens/typography.dart`.
   Blocks: no.
8. Record (review finding 4, iteration 5 — waiver, no shared change
   needed): K03 composes `nest.svg` + `PipAvatar(inNest: false)` via the
   shared `NestPetStage(pip:)` slot instead of the Rive `PipStage`
   artboard, so the front-rim-bites-feet z-order comes from the shared
   fallback scene, not the artboard. `inNest:` is omitted (it defaults
   to false; lint forbids the redundant argument) and is in any case
   unused on the custom-`pip:` path. Slot measurements met; UI stage
   accepted twice.
9. DONE on main (Stage 2b iteration 7 verified): `NestKidButton.wrapLabel`
   landed and K03 passes `wrapLabel: false` on all three dock buttons. Was a
   Need (`softWrap: false` + `FittedBox(scaleDown)` or equivalent) for
   narrow screens / large text scales — "My jar" wraps to two lines
   under fallback fonts today (cosmetic; real Nunito fits). Files:
   `app/lib/core/design_system/components/nest_kid_button.dart`.
   Blocks: no.
10. Extend #2 above (review finding 14): the design shows three sample
    cards but the screen correctly renders every active quest (6 under
    the demo seed, repo alphabetical order per DATA OVER MOCKS) — not a
    defect, recorded so future compares don't flag the extra cards.
11. DONE on main (Stage 2 integrator, iteration 6 verified): `NestPetStage`
    grew the target-size API requested here — `nestWidth:` +
    `fixedPipHeight:` (explicit mode at
    `app/lib/core/design_system/components/nest_pet_stage.dart:29-30,92-96`),
    which sets `nestW = nestWidth ?? fixedPipHeight/split` and
    `pipH = fixedPipHeight ?? nestW*pipPerNestWidth` instead of deriving
    from `maxW`. K03 now calls
    `NestPetStage(pip: PipAvatar(...), speech:, pipSize: 152, nestWidth: 260,
    fixedPipHeight: 152, semanticLabel:)`, which lands the design slot
    (260 px nest, 152 px Pip) through the shared component — the
    feature-local `Stack` + `SvgPicture` scene fork the UI chunk had
    provisionally added was reverted at integration, so the design-system
    "never re-implement components" rule holds again. `pipSize` stays as the
    design cap for the legacy sizing path. Needs a UI-stage capture to
    confirm the rendered slot against the design PNG. Original need below
    for the trail. Blocks: no.
12. DONE on main (Stage 2a iteration 6 verified): shared `watchChildren`
    now orders by `createdAt` (+ `rowid` tiebreak, schema v3) and the seed
    staggers Maya/Leo one minute apart, so `watchProfiles()` returns
    `['Maya', 'Leo']`. K03-BUG-12 un-skipped and passing. Original need below
    for the trail. Blocks: no.
    Need (orchestrator CHILD ORDER ruling, iteration 5; proof added by
    Stage 6 iter-5 — K03-BUG-12): children must be listed in insertion order
    (Maya, then Leo), never alphabetically. `KidHomeRepository.watchProfiles`
    passes through shared `watchChildren`, which orders by nickname in
    `app/lib/core/data/app_database.dart` (shared — not editable here), so
    `watchProfiles()` currently returns `['Leo', 'Maya']`; the failing proof
    is `K03-BUG-12: profiles come in added order (Maya then Leo), never
    alphabetical` (skipped, run with `--run-skipped`). The children table
    exposes no insertion-order key (no createdAt / sequence column), so the
    repository cannot reconstruct insertion order locally. Either add the
    key to the shared schema / order `watchChildren` by `rowid`, or fix it
    in the K01 picker loop (sole profile consumer today). Quest order stays
    title-alphabetical per `1_plan.md` §(a), accepted deviation A2.
    Blocks: no.

No schema/DI/token changes needed. No new assets needed (all icons +
`nest`/`coin`/`meadowHill` exist in `nestling_assets.dart`; Pip renders via
`PipAvatar` + `pip_v2/mochi` fallbacks).

13. DONE on main (shared batch `pet_stage_explicit`, merged into the branch
    before the iteration-8 build — Stage 2b iteration 8 verified): explicit
    mode now composes the scene inside the REAL parent box (centred there,
    scaled down instead of overflowing) and `PipNestFallback` grew
    `nestHeight` / `visibleNestWidth`, so the design's slot is expressible.
    K03 calls `NestPetStage(pip: PipAvatar(<child's own>), speech: "Let's do
    some quests!", nestWidth: 236, nestHeight: 156, fixedPipHeight: 152)` —
    the box that paints the design's 198 px visible outline (236 ×
    `visibleNestRatio` 202/240 = 197.9) in the design's 236 px block. All
    five parked proofs are un-skipped and green: `K03-BUG-13` at 320/390/430,
    `K03-BUG-14`, and `the pet slot matches the design geometry`
    (`kid_home_geometry_test.dart`, real fonts: nest centre 195±1, nest box
    236±2 → 198 visible, Pip centre 195±1, hearts centre 448±2, first card
    top 559±2). The request is closed; the original analysis is kept below for
    the trail.
    Need (Stage 6 iteration 6, K03-BUG-13/14 — follow-up to #11): the new
    explicit size mode does not respect the parent width, and cannot express
    the design's pet slot at all. K03 calls
    `NestPetStage(nestWidth: 260, fixedPipHeight: 152)`; the shared component
    derives `stageW = nestW / 0.62 = 419.35` and positions the scene against
    that nominal width regardless of `LayoutBuilder.maxWidth`, so the nest sits
    at a fixed centre x ≈ 229.68 at every screen width, and `nestH = nestW`
    makes the nest square (stage height `6 + nestH + 10`).

    **Measured (widget proofs, current tree):**
    - 390 px: slot centre 195.0 vs nest/Pip centre 229.68 → **+34.68 px
      off-centre**;
    - 320 px: slot centre 160.0 vs 229.68 → **+69.68 px off-centre**, nest
      right edge 359.7 vs slot right 300 → **+59.68 px overflow** (clipped);
    - 430 px: +14.68 px off-centre;
    - pet block height 276 vs the design's 236 (K03-BUG-14).

    **Design targets at 390×844 (logical px, `design/screens/light/
    K03-kid-home.png` ÷3 — the app shot uses the same coordinates):** visible
    nest outline x 96 → 294 (198 wide, centre x 195), y ≈ 278 → 364; Pip
    centred at x 195, head top ≈ y 201, Pip's bottom ≈ y 301 overlapping the
    nest's top rim by ≈ 20 px (no gap, no separate shadow under Pip's feet);
    ground shadow ends ≈ y 388; hearts row centre ≈ y 448; `Today's quests`
    ≈ y 494; progress bar ≈ y 527–542; first card top ≈ y 559; card 2 visible,
    peeking above the dock.

    **Why this cannot be fixed from K03 (arithmetic, integration-verified
    iteration 7).** The nest SVG paints a visible-to-box ratio of ≈0.84
    (two independent measurements agree: 218/260 at `nestW` 260, and
    182.3/216.4 at the iteration-5 legacy `nestW` 216.4). The scene reserves
    only 62 % of the stage width for the nest, so inside the 350 px content
    box (390 − 2×20 gutters) the two targets are mutually exclusive:

    | nestW (box) | stageW | visible nest | nest centre | overflow | stageH |
    |---|---|---|---|---|---|
    | 260 (shipped) | 419.4 | 218 | 229.7 | +69.4 | 276 |
    | 236 → for a 198 visible | 380.9 | **198 ✓** | 210.4 | +30.9 | 252 |
    | ≤217 (max that fits 350) | 350.0 | 181.9 | **195 ✓** | 0 | 233 |

    A 198 px outline needs `nestW` ≈236, whose scene is 381 px wide — 31 px
    wider than the content box. A box that fits (≤217) yields only a ≈182 px
    outline, 16 px under the design. So no K03-side `nestWidth` value reaches
    both, and an interim `Center` wrap cannot help (the child is clamped to
    350 by the incoming constraints, so the 419 px nominal never materialises
    as an over-wide box — the internal `Positioned`s are simply computed
    against a width the widget never gets). Per `ORCHESTRATOR_NOTES`
    iteration-7 UPDATE DO 3, K03 did not hack around this.

    **Fix (shared).** In explicit mode, clamp the scene to the available width
    — `stageW = min(nestW / 0.62, maxW)` and derive every `Positioned` from
    the *actual* box — **and** make the nest box ratio a parameter so the
    design's 260×236 nest is expressible (`PipNestFallback` assumes
    `nestH == nestW`; it needs a `nestHeight:`, or the stage ratio must drop
    from 0.62 to ≈0.674 so 236 fits in 350). The legacy sizing path already
    scaled down instead of overflowing, so this is a regression of that guard.

    **Proofs** (all parked with `skip: true`, all fail today):
    `K03-BUG-13` at 320/390/430, `K03-BUG-14`, and
    `the pet slot matches the design geometry` in the new
    `kid_home_geometry_test.dart` — a real-font (`FontLoader` Inter/Nunito)
    pin of nest centre 195±1, nest box 236±2 (→ the 198 px visible outline),
    hearts centre 448±2 and first card top 559±2. Measured at real fonts it
    reproduces the device captures exactly: nest centre 229.68 (+34.68),
    hearts 494.0 (+46), first card 615.0 (+56) — so the pin is trustworthy
    and should simply be un-skipped once the shared fix lands.
    Files: `app/lib/core/design_system/components/nest_pet_stage.dart`,
    `app/lib/core/design_system/motion/pip_rive.dart`.
    Blocks: K03's owner ALIGNMENT rule at narrow widths, and the iteration-7
    QA row targets.
14. Need (review finding 7, iteration 6): `switchMapStream` — the
    `switchMap`-for-never-closing-watch-streams helper backing
    `KidHomeRepository.watchHome()` — currently lives in
    `app/lib/features/kid_home/domain/kid_home_repository.dart` because K03
    may not edit `core/`. It is generic plumbing, not a domain abstraction
    (`ARCHITECTURE.md` keeps `domain/` to entities + abstract repository
    only), and `app/lib/core/data/stream_combine.dart` already owns
    `combineLatest2/3/4` for every feature. Request: move it next to them
    (same semantics, feature re-imports it) or bless the current spot.
    Stage 6 iteration 7 addendum (K03-BUG-15 proof): the helper also does
    not release its source/inner subscriptions when the consumer cancels
    after an error — three failed loads leave 3 live subscriptions
    (`K03-BUG-15: retry does not stack live stream subscriptions`,
    `Expected ≤ 2, Actual 3`). Whichever file it lives in, the shared fix
    should cancel on consumer cancel; the feature-local alternative is an
    early-return in `_onLoadRequested` while a load is live.
    Files: `app/lib/core/data/stream_combine.dart`,
    `app/lib/features/kid_home/domain/kid_home_repository.dart`,
    `app/lib/features/kid_home/data/kid_home_repository_impl.dart`.
    Blocks: no (helper is tested in place: `switchMapStream` group in
    `kid_home_bloc_test.dart`).

15. CLOSED — no change wanted (iteration 7 finding; settled in iteration 8):
    the shared bubble already matches `.speech`, and the "≈35 px" target was
    a misread of the inner white area of the design PNG. `ORCHESTRATOR_NOTES`
    UPDATE (08:32) rules that 44 px is the design's FULL height: `.speech`
    sets no `line-height`, so the browser renders `normal` (≈22 px in Nunito)
    and the fix belongs in the shared component, which now omits `height`
    instead of hard-coding 24/16 (a fixed 24/16 rendered it 46 px tall).
    K03's typography proof records the browser-default line height instead of
    pinning 24/16. No API change requested.
    Original need (5_ui finding 3, closed as above): the shared speech bubble
    rendered `NestSpeechBubble` 3 px border + `NestSpacing.s2` (8) padding +
    16/24 text + 8 padding + 3 px → ≈46 logical px tall, against a reported
    ≈35 in the design. Files:
    `app/lib/core/design_system/components/nest_pet_stage.dart`.
    Blocks: no.
16. Need (review findings 1+2, iteration 8 — one batch, same component):
    (a) Nest art-box independence. `PipNestFallback` renders `nest.svg`
    with `fit: BoxFit.fill` into the full stage box, so K03's mandated call
    (`nestWidth: 236, nestHeight: 156`) stretches the bowl to 156/236 =
    0.661 vertically: rim 38→25 px at x102, bowl widest row y327→353 (+26),
    bowl bottom ≈378→387 (+9), identical in dark (26/40 = 0.65). Measured
    with the same detector on design vs `ui/app_light_8.png` /
    `ui/app_dark_8.png`. The arithmetic is closed from K03: forcing
    `stageH = 236` (design `.k3-pet`) with `fixedPipHeight: 152`,
    `rimOverlap: 20` gives `nestH = 155.6` — the current 156 is the only
    value that keeps the block at 236 — while preserving the art aspect
    needs `nestH ≈ 214` → `stageH ≈ 271`, and `ORCHESTRATOR_NOTES` #35
    forbids the negative stage→hearts gap that would absorb it; `BoxFit`
    change alone renders 156×156 art (bowl ≈131×71, further off). Request:
    an art-box/aspect parameter (e.g. `nestArtHeight:`) so the caller can
    ask for the 198-wide outline at the art's 260:236 aspect, deriving
    `nestTop`/`stageH` from the visible rim + bowl + shadow; K03's target
    call then keeps block 236 with the widest row on y327. Files:
    `app/lib/core/design_system/motion/pip_rive.dart` (`explicitGeometry`,
    `nestTop`/`stageH`, `BoxFit.fill`), optionally
    `.../components/nest_pet_stage.dart`. Blocks: the hero centrepiece
    (major; `shared/pet_stage_seat` branch is reportedly fixing it — K03
    makes no local change per `ORCHESTRATOR_NOTES` 09:52).
    (b) Card rhythm. The shared `NestKidQuestCard` carries 6 px bottom
    padding (`nest_quest_card.dart:168`) inside K03's `.k3-quests` 12 px
    column, so painted cards sit 18–19 px apart vs the design's 12
    (card-2 top 665 vs 659, accumulating 6 px per card). Request: drop the
    in-card padding with the shadow offset absorbed by the caller's gap, or
    add a `shadowPadding` parameter. Files:
    `app/lib/core/design_system/components/nest_quest_card.dart`.
    Blocks: no (6 px, minor).
    **K03 now compensates (iteration 9, 5_ui deviation 1).** The review
    preferred no local compensation, but the owner ALIGNMENT rule makes a
    visible 6 px drift a UI failure and the UI stage measured it as one, so
    the quest column reads
    `spacing: NestSpacing.s3 - _kQuestCardShadowRoom`
    (`kid_home_view.dart`, `_kQuestCardShadowRoom = 6`), which puts painted
    card 2's top border back on the design's y 659 and its 60 px peek above
    the dock back on the design's 719. **Reverting rule: when (b) lands,
    delete `_kQuestCardShadowRoom` and put `NestSpacing.s3` straight back in
    the column** — one constant, one call site, nothing else moves. A
    `shadowPadding:` parameter is the cleanest shape for it (K03 would then
    pass `shadowPadding: EdgeInsets.zero`).
17. OPEN (iteration 10, `5_ui` deviation 2): the speech-bubble tail's white
    interior is ~10 px shorter than the design's. Measured on
    `design/screens/light/K03-kid-home.png` vs `ui/app_light_9.png` at the
    tail's centre column x 195: design white y 152→174 (23 px), app white
    y 152→164 (13 px). Body is identical (44 tall, same x/w, 36 vs 37 by
    rounding), so nothing downstream moves — it is purely the painted tail.
    Cause: `NestSpeechBubble`'s `_TailPainter` fills an inner triangle only
    6.5 px deep inside an 18×10 tail box
    (`app/lib/core/design_system/components/nest_pet_stage.dart`, the
    `Size(18, 10)` CustomPaint and its inner path), while `.speech::after`
    in `design/html-source/components.css` l.192 is a 9 px ink wedge whose
    interior reads white for its full drop. Request: make the tail's inner
    fill reach the tail's tip (or size the tail to the design's 9 px drop)
    so the centre column matches; keep `NestSpeechBubble`'s public API —
    K03 only passes `text`. Blocks: no (cosmetic, 10 px, no layout impact).
