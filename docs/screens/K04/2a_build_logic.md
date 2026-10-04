# K04 — Stage 2a build, logic chunk (iteration 3)

Scope: non-UI layer of feature `kid_home` for K04 (`/quest-detail`) —
`domain/**`, `data/**`, `presentation/bloc/**`, DI/route registration.
Views/widgets untouched (UI builder owns them, working in parallel).

## Files changed

None in iteration 3. The plan-§b getter (`stepsFor` delegate,
`kid_home_bloc.dart:30`) stands; no logic-layer edit is required by the
plan or by FIXES_2 (see triage).

## FIXES_2 triage — no item is in the logic layer

- **K04-BUG-4 (Minor, OPEN):** `NestBalancedText(quest.title, maxLines: 3)`
  at `quest_detail_view.dart:577` passes no `overflow:`, so an over-cap
  title clips instead of ellipsising. The fix is one argument at that
  view call site (or a shared default in `core/`). Both locations are
  outside this layer (views = UI builder; `core/**` forbidden by RULES
  §1). NOT ACTIONABLE here.
- **Hero tile glyph (Major, `5_ui.md` deviation 1):** screen code correctly
  implements the mandated ruling; root cause is the shared batch-5 asset
  `ic_quest_bed.svg`, i.e. `core/**` + orchestrator decision. NOT
  ACTIONABLE here; screen agent must file SHARED_REQUEST (integrator /
  orchestrator call, not a `kid_home` logic edit).
- **New ICONS rule (`questIconFor`/`rewardIconFor` with audience):** the
  shared helper has now landed on main
  (`core/design_system/components/quest_icons.dart:41`) and K03's view
  already consumes it (`kid_home_view.dart:83`). Icon mapping lives in
  views + shared core — there is no icon logic in `kid_home` domain /
  data / bloc to migrate. Nothing for this layer to adopt.
- **K04-BUG-1/2/3 (iteration 1):** unchanged from last iteration's triage —
  shared component / views-owned, not this layer.
- Skipped proofs in `k04_bugs_test.dart`: filename contains none of
  `bloc`/`cubit`/`repository`/`data` — outside my test ownership; not
  edited, un-skipped, or run with `--run-skipped`.

## Items done

- [x] Re-verified plan §b: no new events, no repo/DI/route changes needed.
- [x] Re-verified no `google_fonts`/`GoogleFonts` imports in feature code.
- [x] `flutter analyze lib/features/kid_home` → No issues found.
- [x] Ran logic-layer tests with `--timeout 120s`:
      `quest_detail_bloc_test.dart` (new, 9 cases incl. `stepsFor`
      delegation + real-DB seed order) + `kid_home_bloc_test.dart` +
      `kid_home_repository_test.dart` + `k01_bloc_paths_test.dart` →
      all 87 passed.

## CONTRACT CHANGES

None. Event/state shapes unchanged.

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Open work belongs elsewhere: K04-BUG-4's
one-argument view fix + test un-skip are UI-builder owned; the hero glyph
needs a shared-asset fix via the orchestrator (RULES §1 off-limits to
this screen).

VERDICT: PASS
