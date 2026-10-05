# K03b Kid home all-done — 4 QA code review (iteration 3)

Scope: `git diff main...HEAD` on branch `screen/K03b` — kid_home feature
files plus this screen's notes, against docs/ARCHITECTURE.md,
docs/screens/RULES.md, docs/DESIGN_SPEC.md §5 K03b,
docs/design/SPACING_SPEC.md, the shared design system, the plan
(`docs/screens/K03b/1_plan.md`), and the mandatory
docs/screens/K03b/ORCHESTRATOR_NOTES.md items (04:03 + 04:52 + 06:44).
No code edited by this stage. No simulator booted, installed on,
screenshotted or driven (stage 5 owns the one allowed UDID).

## Files reviewed (committed diff)

| File | Δ |
|---|---|
| `kid_home/data/kid_home_repository_impl.dart` | drop title re-sort (creation order); surface `needsApproval`; BUG-6 terminal `completeQuest` + `_creditQuestBonus` |
| `kid_home/domain/entities/kid_quest.dart` | +`needsApproval` (default true, in `props`) |
| `kid_home/data/models/kid_quest_model.dart` | round-trip `needsApproval` in fromJson/toJson (true default) |
| `kid_home/kid_home.dart` | drop barrel export of deleted placeholder |
| `kid_home/kid_home_routes.dart` | `/kid-home-done` now builds `KidHomeView` |
| `kid_home/presentation/bloc/kid_home_state.dart` | +`allDone` pure getter (`totalCount > 0 && doneCount == totalCount`) |
| `kid_home/presentation/views/kid_home_view.dart` | all-done branch (`_AllDoneBody`, `_AllDoneBar`); ROW META branch in `_QuestCard`/`_statusText` |
| `kid_home/presentation/views/kid_home_done_view.dart` | deleted placeholder |
| `test/.../k03b_all_done_view_test.dart` | all-done view suite |
| `test/.../k03b_all_done_bloc_test.dart` | `allDone` truth table + live flip paths |
| `test/.../k03b_bugs_test.dart` | probes incl. un-skipped BUG-6 queue test (`skip: false`) |
| `test/.../kid_home_{bloc,repository,view}_test.dart` | creation order + `needsApproval` updates |
| `docs/screens/K03b/**` | plan, notes, FIXES_1/2, prior stage files |

## Evidence gathered (this stage, independently run in `app/`)

- `dart format --output=none --set-exit-if-changed lib/features/kid_home test/features/kid_home` → 53 files, **0 changed**.
- `flutter analyze lib/features/kid_home test/features/kid_home` → **No issues found!**
- `flutter test --timeout 120s test/features/kid_home` → **+798 ~7: All tests passed!** (`~7` are `skip:`-marked parked proofs, incl. shared-owned BUG-2).
- `flutter test --timeout 120s test/features/approvals` → **+144: All tests passed!** (P11 unmoved by the ledger change, per 06:44).
- Edit set is clean against RULES §1: every changed lib path sits under `app/lib/features/kid_home/**` (barrel + routes touched only as the mandated placeholder removal requires, exactly per `1_plan.md` §g checklist); tests under `app/test/features/kid_home/**`; notes under `docs/screens/K03b/**`. No `app/lib/core/**`, `app/lib/app/**`, `tools/**`, or `analysis_options` entry in the diff.
- Orchestrator 06:44 verified in code: `completeQuest` reads the quest row's `needsApproval`; `needsApproval == false` writes `approved` + `decidedAt`/`decidedAtTz` with a `quest_bonus` ledger credit in the SAME transaction on both flip and insert paths; `needsApproval == true` keeps the `done_pending` write with no ledger row. Ledger columns mirror `ApprovalsRepositoryImpl.approve` exactly (`familyId`, `childId`, `quest_bonus`, `amountPence: coins`, `note: title`, `date/dateTz`). Flip path is compare-and-set on still-open rows (BUG-P11-1 shape), so a racing second tap credits nothing. BUG-6 probe is un-skipped in the committed file (`k03b_bugs_test.dart:342`, `skip: false`).
- Orchestrator 04:52 verified: title re-sort removed (creation order, seed order = HTML row order); ROW META `status + needsApproval` branch (`kid_home_view.dart:804-833`: waiting+approval → `Waiting for Mum`; approved+approval → `Mum said yes!`; done+no-approval → `+N` chip); D1 confetti `Positioned` in `Stack(clipBehavior: Clip.none)` with feature-local 226/226 + `pipBottom: 92` — no `core/**` touch.
- Banned-API grep: no live `DateTime.now()` (only a `now` parameter name), no `GoogleFonts`, no `name[0]`, no v1 `pip_stage_*.svg` outside comments, no added `letterSpacing`, no `Color(0x…)` in the view, no `KidHomeDoneView` references left in `app/lib` or committed tests. Clock via `appNowUtc()`; pinned clock file untouched.
- Copy: `Today's quests` (U+2019, same as K03), `All done!`, `You did everything today! Pip is so proud.`, `Visit Pip`, `Hi Maya!` ASCII-exact; no `£` in the all-done branch (coins only). `NestBalancedText` used for the `kidTitle` heading (BALANCED HEADINGS rule); no interactive chip row so CHIP ROWS is N/A.
- Accessibility: Visit Pip / lock / card taps retained (`onTap: _openDetail` at `kid_home_view.dart:837`, done checks display-only); confetti `ExcludeSemantics` + `IgnorePointer`; header `excludeSemantics` groups static text only; pet `semanticLabel` names stage + celebrating. Bottom edge: `_AllDoneBar` surface + `SafeArea(top: false)` + `NestHomeIndicator` inside. Pip is Maya's own `PipAvatar` (row style/skin/accessory, stage clamped, `PipMood.happy` Rive-only).

## Findings

1. **minor** — `docs/ARCHITECTURE.md` route table still maps `/kid-home-done` to `KidHomeDoneView`; this branch renders `KidHomeView` there. The doc is shared (orchestrator owns), so no edit happens on `screen/K03b`. Carryover from iteration 1: needs one line in `SHARED_REQUEST.md` or a note to the loop.
2. **minor** — `app/test/features/kid_home/k03b_bugs_test.dart:370` writes `skip: false` on the un-skipped BUG-6 test. Harmless (equals no skip, suite proves it runs), but the flag is noise; concrete fix: delete the `skip: false,` line.

Observations (not findings): `hide PipMood` on the `design_system.dart` import (`kid_home_view.dart:9`) is a no-op (barrel exports no `PipMood`); the `-7°` conversion inlines pi digits instead of `dart:math` — both zero-effect, no lint. K03 approved demo rows move `Done` → `Mum said yes!` exactly per the 04:52 ROW META ruling, with K03 tests updated to match. Uncommitted working-tree files (`k03b_iteration3_stage_test.dart`, `k03b_bugs_test.dart` mods, `ui/*_3.png`) are process items owned by the loop, not reviewed here.

Everything else passed: tokens only, shared components reused (`NestSpeechBubble`, `NestPetStage`, `NestKidButton`, `KidStatusChip`, `NestProgress`), BLoC contract unchanged (one pure getter, no new events/states), domain holds entities + abstract repo only, no new folders or use-case classes, loading/failure/empty channels shared with K03, dark mode token-driven, Children's Code clean (no analytics/ads/tracking, kind copy).

VERDICT: PASS
