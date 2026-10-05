# K03b Kid home all-done — 4 QA code review (iteration 1)

Scope: `git diff main...HEAD` on branch `screen/K03b` — kid_home feature
files plus this screen's notes. No code edited by this stage. No
simulator booted, installed on, screenshotted or driven (stage 5 owns
the one allowed UDID).

## Files reviewed

| File | Δ |
|---|---|
| `app/lib/features/kid_home/kid_home.dart` | drop barrel export of deleted placeholder |
| `app/lib/features/kid_home/kid_home_routes.dart` | `/kid-home-done` now builds `KidHomeView` |
| `app/lib/features/kid_home/presentation/bloc/kid_home_state.dart` | +`allDone` getter |
| `app/lib/features/kid_home/presentation/views/kid_home_view.dart` | all-done branch (`_AllDoneBody`, `_AllDoneBar`), K03 branch re-indented |
| `app/lib/features/kid_home/presentation/views/kid_home_done_view.dart` | deleted placeholder |
| `app/test/features/kid_home/k03b_all_done_view_test.dart` | new (8 tests) |
| `docs/screens/K03b/**` | plan, build notes, orchestrator notes |

## Evidence gathered

- `dart format --output=none --set-exit-if-changed app/lib/features/kid_home app/test/features/kid_home` → 50 files, **0 changed**.
- `flutter analyze lib/features/kid_home test/features/kid_home/k03b_all_done_view_test.dart` → **No issues found!**
- `flutter test --timeout 120s test/features/kid_home/k03b_all_done_view_test.dart` → **All tests passed!** (+8). Build log records the full suite green (+4395 ~12), including K03's `kid_home_view_test.dart`, `k03_bugs_test.dart`, `kid_home_geometry_test.dart`.
- Edit set is clean against RULES §1: only `app/lib/features/kid_home/**`,
  `app/test/features/kid_home/**`, `docs/screens/K03b/**`. No
  `app/lib/core/**`, `app/lib/app/**`, `tools/**` or `analysis_options`
  entry in the diff. No `SHARED_REQUEST.md` needed — every component the
  screen uses (`NestSpeechBubble`, `NestPetStage` with `slotHeight`,
  `NestKidButton`, `KidStatusChip`, `NestProgress`, confetti asset)
  already exists on main.
- Orchestrator rules re-checked: Pip is the child's own `PipAvatar`
  (`pipStyleOf/pipSkinOf/pipAccessoryOf` from the row, stage clamped
  1..4, `PipMood.happy` — Rive-only, harmless under
  `DISABLE_ANIMATIONS`); no v1 `pip_stage_*.svg`. `NestStatusBar` is the
  shared height-only bar. Counts/copy derive from the DB
  (`doneCount`/`totalCount`/`fraction` off period-scoped items); no
  design numbers hard-coded. Children are added-order (untouched path).
  Klondike: `_AllDoneBar` + `SafeArea(top: false)` keeps the bar's
  `surface` running to the physical edge — no meadow strip under the
  bar in either theme. No `google_fonts`, no `DateTime.now()`, no
  `name[0]`, no v1 assets. Accessibility: Visit Pip exposes
  `SemanticsAction.tap` (tested); confetti is `ExcludeSemantics` +
  `IgnorePointer`; header text group is a non-control
  `excludeSemantics` label; done checks are display-only (same as K03).
  Children's Code: no analytics/ads/tracking; failures/loading/empty
  channels are the shared K03 widgets. K03 not-done branch is
  behaviourally unchanged (all K03 tests pass).

## Findings

1. **major** — `_AllDoneBody` vertical rhythm is off by 16 px versus the
   design CSS. `design/html-source/screens/K03b-kid-home-done.html`
   puts the speech bubble, then `.k3-stage` with
   `.scroll > * + * { margin-top: var(--s4) }` (= **16 px**,
   `components.css:66`), and inside `.k3-stage` the `.k3-pet` carries
   `margin: 14px auto 0`. So the design's bubble→pet gap is **16 + 14 =
   30 px**. The code (`kid_home_view.dart:870`) emits a single
   `SizedBox(height: NestSpacing.gap14)` (**14 px**) between the bubble
   and the stage stack, and the `NestPetStage` slot starts immediately.
   Net effect, measured against the HTML: the Pip/nest slot top sits
   ~16 px higher than the design, and the whole section row → progress
   → quest-card block rides along 16 px high; the confetti plate lands
   at bubble-bottom + 18 instead of the designed +20 (its
   `Positioned(top: 4)` is now relative to the raised stack instead of
   the design's `+16` stage origin). Under the UI-verdict ±2 px rule
   the pet slot, section row, progress and cards all fail. Concrete
   fix: `bubble → const SizedBox(height: NestSpacing.s4) → Stack(…)`,
   and inside the Stack wrap the `NestPetStage` in
   `Padding(top: NestSpacing.gap14)` so the confetti's `top: 4`
   measures from the design's stage origin — the same structure K05
   uses (`.k5-pip { margin: 14px 0 2px }` lives on the Pip, not the
   stage, `quest_complete_view.dart:399-403`). Both the 16 px and the
   14 px then land exactly where the CSS puts them.

2. **minor** — `docs/ARCHITECTURE.md` route table (line ~104) still
   maps `/kid-home-done` to `KidHomeDoneView`; this branch renders
   `KidHomeView` there now. The doc is shared (orchestrator owns), so
   no edit happens on `screen/K03b` — worth one line in
   `SHARED_REQUEST.md` or a note to the loop.

Everything else passed: tokens only, shared components reused, BLoC
contract unchanged (one pure getter), no new events/states, loading/
failure/empty paths shared with K03, all-done bar matches the design's
`.kid-bar` paddings and reuses `NestHomeIndicator` inside the surface
per the BOTTOM EDGE owner rule, dark mode is token-driven.

VERDICT: FAIL
