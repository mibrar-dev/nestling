# K03b Kid home all-done — 4 QA code review (iteration 2)

Scope: `git diff main...HEAD` on branch `screen/K03b` — kid_home feature
files plus this screen's notes, against docs/ARCHITECTURE.md,
docs/screens/RULES.md, docs/DESIGN_SPEC.md §5 K03b,
docs/design/SPACING_SPEC.md, the shared design system, and the mandatory
docs/screens/K03b/ORCHESTRATOR_NOTES.md items (04:03 + 04:52). No code
edited by this stage. No simulator booted, installed on, screenshotted
or driven (stage 5 owns the one allowed UDID).

## Files reviewed

| File | Δ |
|---|---|
| `app/lib/features/kid_home/data/kid_home_repository_impl.dart` | drop title re-sort (creation order); surface `needsApproval` |
| `app/lib/features/kid_home/domain/entities/kid_quest.dart` | +`needsApproval` (default true, in `props`) |
| `app/lib/features/kid_home/data/models/kid_quest_model.dart` | round-trip `needsApproval` in fromJson/toJson |
| `app/lib/features/kid_home/kid_home.dart` | drop barrel export of deleted placeholder |
| `app/lib/features/kid_home/kid_home_routes.dart` | `/kid-home-done` now builds `KidHomeView` |
| `app/lib/features/kid_home/presentation/bloc/kid_home_state.dart` | +`allDone` pure getter |
| `app/lib/features/kid_home/presentation/views/kid_home_view.dart` | all-done branch (`_AllDoneBody`, `_AllDoneBar`), ROW META branch in `_QuestCard`/`_statusText` |
| `app/lib/features/kid_home/presentation/views/kid_home_done_view.dart` | deleted placeholder |
| `app/test/features/kid_home/k03b_all_done_view_test.dart` | all-done view suite (creation order + new meta pins) |
| `app/test/features/kid_home/k03b_all_done_bloc_test.dart` | `allDone` truth table + live flip paths |
| `app/test/features/kid_home/k03b_bugs_test.dart` | 24 probes + 7 parked proofs (bugs-stage owned) |
| `app/test/features/kid_home/kid_home_{bloc,repository,view}_test.dart` | updated to creation order + `needsApproval` |
| `docs/screens/K03b/**` | plan, build/integration notes, FIXES_1, prior review/ui/bugs |

## Evidence gathered (this stage, independently run in `app/`)

- `dart format --output=none --set-exit-if-changed lib/features/kid_home test/features/kid_home` → 52 files, **0 changed**.
- `flutter analyze lib/features/kid_home test/features/kid_home` → **No issues found!**
- `flutter test --timeout 120s test/features/kid_home` → **+755 ~12: All tests passed!** (`~12` are pre-existing `skip:`-marked parked proofs, not failures).
- Edit set is clean against RULES §1: every changed path sits under `app/lib/features/kid_home/**`, `app/test/features/kid_home/**`, `docs/screens/K03b/**`. No `app/lib/core/**`, `app/lib/app/**`, `tools/**`, or `analysis_options` entry in the diff.
- Iteration-1 review finding 1 (major, bubble→pet gap 14 vs 30): FIXED — code is now `SizedBox(s4=16)` + `NestPetStage` in `Padding(top: gap14)` inside `Stack(clipBehavior: Clip.none)` with `Positioned(top: 4)` confetti (`kid_home_view.dart:902-968`); 2_build records both K03B-BUG-1 parked proofs green on demand.
- Orchestrator 04:52 items verified in code: D1 confetti absolute (Positioned, never sizes the Stack) with feature-local 226/226 nest constants (`kid_home_view.dart:55-65`) and `pipBottom: 92` taking the shared early return — no `core/**` touch; ROW ORDER sort removed (`kid_home_repository_impl.dart:76-79`); ROW META `status + needsApproval` branch (`kid_home_view.dart:804-833`) matching the K03b HTML rows (`Mum said yes!` / `+N` chip / `Waiting for Mum`).
- Copy byte-checked: `Today's quests` U+0027 in HTML l.76 and view l.500/l.979 identical; `All done!`, `You did everything today! Pip is so proud.`, `Visit Pip`, `Hi Maya!` ASCII-exact. No `£` in the all-done branch (coins only). No `google_fonts`, no live `DateTime.now()`, no `name[0]`, no v1 `pip_stage_*.svg` outside comments, no `letterSpacing`, no `Color(0x…)` in the view. Clock pinned via `test/flutter_test_config.dart` (Sat 3 Oct 2026 09:41 London).
- Accessibility: Visit Pip tap assertions present (view test 5 hits, bugs test 3 hits); confetti `ExcludeSemantics` + `IgnorePointer`; header `excludeSemantics` groups static text only; done checks display-only. Bottom edge: `_AllDoneBar` surface + `SafeArea(top: false)` + `NestHomeIndicator` inside (bugs probes confirm surface to the edge, light + dark). Pip is Maya's own `PipAvatar` (style/skin/accessory from the row, stage clamped, `PipMood.happy` Rive-only). K03 not-done branch behaviourally unchanged (full K03 suites green, card 1 still dishwasher in both orders).

## Findings

1. **minor** — `app/test/features/kid_home/k03b_bugs_test.dart:269` parked proof `K03B-BUG-4 … says "Mum said yes!"` asserts `findsOneWidget`, but the ROW META implementation is correct and renders three such chips (seeded q-bins + q-hoover are `approved` in the same London week, plus the flipped q-reading — all need approval). Concrete fix (bugs-stage owned, do not touch from other stages): assert the reading card specifically (e.g. scope the finder to the q-reading card) or expect `findsNWidgets(3)`, then un-skip. Tracked in `2_build.md` §FIXES_1; test is `skip: true` so the suite stays green.

2. **minor** — `docs/ARCHITECTURE.md` route table still maps `/kid-home-done` to `KidHomeDoneView`; this branch renders `KidHomeView` there. The doc is shared (orchestrator owns), so no edit happens on `screen/K03b` — carryover from iteration 1, needs one line in `SHARED_REQUEST.md` or a note to the loop.

Observations (not findings): `hide PipMood` on the `design_system.dart` import (`kid_home_view.dart:9`) is a no-op barrel already exports neither `PipMood` nor `pip_avatar`; the `-7°` conversion (`kid_home_view.dart:949`) inlines pi digits instead of `dart:math` — both zero-effect, no lint, geometry proofs pass.

Everything else passed: tokens only, shared components reused, BLoC contract unchanged (one pure getter, no new events/states), domain holds entities + abstract repo only, no new folders or use-case classes, loading/failure/empty channels shared with K03, dark mode token-driven, Children's Code clean (no analytics/ads/tracking, kind copy, no £ in kid view).

VERDICT: PASS
