# K04 — Stage 2a build, logic chunk (iteration 4)

Scope: non-UI layer of feature `kid_home` for K04 (`/quest-detail`) —
`domain/**`, `data/**`, `presentation/bloc/**`, DI/route registration.
Views/widgets untouched (UI builder owns them, working in parallel).

## Files changed

- `app/test/features/kid_home/kid_home_repository_test.dart` (+41 lines)
  - New group `K04 ICONS audience guard — data premise` (2 cases), the
    logic-layer half of the guard FIXES_3 owes to iteration 4:
    1. Maya's quest items read from the real seeded DB carry icon keys
       covering the audience-divergent set (`bed`, `dishwasher`, `book`),
       and every stored key resolves through shared `questIconKeys`
       (DATA OVER MOCKS — keys read from the DB, never hard-coded).
    2. `questIconFor` splits kid from parent on exactly the divergent
       keys (`bed`, `dishwasher`, `book`/`reading`) and agrees on the
       shared ones (`bins`, `hoover`, `plate`) — the distinction the
       hard-coded K04-BUG-3 proof cannot assert.
  - The rendered-glyph half (64 px `NestIcon.assetName` per quest) needs
    the view and stays UI-builder owned; deliberately not duplicated here.

No production-code change: the plan-§b `stepsFor` getter stands; no new
events, no repo/DI/route edits needed.

## FIXES_3 triage — remainder not in this layer

- **K04-BUG-5 (Minor, OPEN):** stroke-width of shared asset
  `ic_quest_bed_kid.svg` (`2` vs K04 design `1.8`). Shared asset +
  `test/design_system/audience_glyphs_test.dart:73` are outside `kid_home`
  and off-limits under RULES §1. NOT ACTIONABLE here — orchestrator
  decision (accept 0.5 px vs ship a K04 variant).
- **K04-BUG-4:** fix landed, proof un-skipped, verified passing by stage 3.
- **K04-BUG-1/2/3:** unchanged — shared component / views-owned.
- Skipped proof `k04_bugs_test.dart:383` (K04-BUG-5): filename contains
  none of `bloc`/`cubit`/`repository`/`data` — outside my test ownership;
  not edited, un-skipped, or run with `--run-skipped`.

## Items done

- [x] Added the 2-case data-premise guard above (my layer's share of the
      owed ICONS test).
- [x] Re-verified no `google_fonts`/`GoogleFonts` imports in feature code.
- [x] `dart format` clean on touched files; `flutter analyze
      lib/features/kid_home` → No issues found.
- [x] Ran logic-layer tests with `--timeout 120s`:
      `kid_home_repository_test.dart` + `quest_detail_bloc_test.dart` +
      `kid_home_bloc_test.dart` + `k01_bloc_paths_test.dart` →
      all 89 passed (87 + 2 new).

## CONTRACT CHANGES

None. Event/state shapes unchanged.

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Open: rendered-glyph half of the ICONS guard
(UI builder), K04-BUG-5 shared-asset decision (orchestrator).

VERDICT: PASS
