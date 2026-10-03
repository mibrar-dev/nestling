# Shared request — K03 Kid home

1. Need: `NestKidQuestCard` icon tile is fixed `surface2`, but the K03 HTML
   tints tiles per quest (`sky-tint` dishwasher, `lilac-tint` reading,
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
6. Need (review finding 1c, iteration 5): a `KidScope` meadow-band
   height/inset parameter so screens stop painting their own hill. K03
   paints one in-flow full-bleed band (`_MeadowPainter`, marked
   `TODO(K03)`) because the shared 136 px bottom hill cannot cover the
   band the design shows behind progress/cards; same need will hit K06+.
   Files: `app/lib/core/design_system/theme/kid_scope.dart`.
   Blocks: no (local panel kept until the API exists).
7. Need (review finding 3, iteration 5): kid type styles missing from
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
9. Need (review finding 13, iteration 5): a `NestKidButton` label-wrap
   option (`softWrap: false` + `FittedBox(scaleDown)` or equivalent) for
   narrow screens / large text scales — "My jar" wraps to two lines
   under fallback fonts today (cosmetic; real Nunito fits). Files:
   `app/lib/core/design_system/components/nest_kid_button.dart`.
   Blocks: no.
10. Extend #2 above (review finding 14): the design shows three sample
    cards but the screen correctly renders every active quest (6 under
    the demo seed, repo alphabetical order per DATA OVER MOCKS) — not a
    defect, recorded so future compares don't flag the extra cards.
11. Need (review finding 1, iteration 6): `NestPetStage` accepts only a
    `pipSize` cap (`pipH = min(maxW*0.62*0.55, pipSize)`), so on a 390 px
    screen the slot is fixed at a ~119 px Pip on a ~217 px nest with no
    API path to the design's 260×236 slot (would need maxW ≈ 446).
    Measured: nest 182 vs 198 wide, Pip band 25 px shorter than design
    (positions met: Pip top y=197, rim ≈286-292). Request: a target-size
    API — `nestWidth:` / `pipHeight:` / `stageWidth:` that the scene
    honors instead of deriving from `maxW`. Until it lands, K03 keeps
    the shared `NestPetStage(pip:, speech:, pipSize: 152)` composition
    per the mandatory migration note (positions carry over; art swap is
    accepted). Files: `app/lib/core/design_system/components/nest_pet_stage.dart`.
    Blocks: no.
12. Need (orchestrator CHILD ORDER ruling, iteration 5; proof added by
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
