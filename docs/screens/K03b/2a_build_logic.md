# 2a BUILD LOGIC — K03b Kid home all done (iteration 2)

## CONTRACT CHANGES

1. `KidQuest` gains `needsApproval` (bool, default `true`):
   `app/lib/features/kid_home/domain/entities/kid_quest.dart`. Optional
   named param, so every existing `KidQuest(...)` construction (bloc/view/
   geometry/bugs tests) compiles unchanged. Default `true` mirrors the
   `quests.needs_approval` DB default and the P09 "Needs my approval" ON
   default, preserving prior meaning everywhere the flag is not passed.
   Added to `props` (equality distinguishes it). UI builder: branch the
   done-row meta on `item.status` + `item.needsApproval` per ROW META —
   `done_pending` → `Waiting for Mum` (unchanged); `approved` +
   needs approval → `Mum said yes!`; done + no approval → `+N` coin chip.
2. `KidQuestModel` threads the flag through `fromJson` (absent → `true`)
   / `toJson` (`app/lib/features/kid_home/data/models/kid_quest_model.dart`).
3. Item order contract: `_watchItemsFor` no longer re-sorts; `state.items`
   is `watchActiveQuests` creation order (created_at, then id) — dishwasher,
   reading, bins, tidy, hoover, table for Maya. The view already renders
   `state.items` in order (no re-sort in `kid_home_view.dart`), so this is
   the card order. K03 card 1 stays `Empty the dishwasher` (first in both
   orders); cards 2–6 reorder per the ROW ORDER owner rule.

## Files changed (logic layer only)

- `app/lib/features/kid_home/domain/entities/kid_quest.dart` — +`needsApproval`.
- `app/lib/features/kid_home/data/models/kid_quest_model.dart` — flag round-trip.
- `app/lib/features/kid_home/data/kid_home_repository_impl.dart` — dropped the
  title sort (ROW ORDER), surfaces `needsApproval: q.needsApproval` (ROW META).
- `app/test/features/kid_home/kid_home_repository_test.dart` — new group `K03b
  row order + approval flag` (3 tests) + `drift` import.
- `app/test/features/kid_home/kid_home_bloc_test.dart` — `_withStatus` carries
  the flag; new `needsApproval defaults true and shapes equality` test;
  stale "(alphabetical)" fake-order comment corrected.
- Did NOT touch: `presentation/views/**`, `presentation/widgets/**`,
  `k03b_bugs_test.dart`, `k03b_all_done_view_test.dart` (UI builder /
  integrator owned), `app/lib/core/**`, `app/lib/app/**`, seed, analysis options.

## Items done

- `allDone` getter: already on main from iteration 1 (verified present,
  `kid_home_state.dart:94`) — no change needed.
- K03B-BUG-5 (logic half): title sort removed; repository test proves Maya's
  6 items arrive dishwasher → reading → bins → tidy → hoover → table.
- K03B-BUG-4 (logic half): `needsApproval` flows DB row → entity; repository
  tests prove default-true seeding and that clearing `needs_approval` on
  `q-tidy` surfaces `false` on exactly that entity.
- `dart format` clean, `flutter analyze lib/features/kid_home` → No issues.
- Owned suites green: `kid_home_repository_test` 13/13, `kid_home_bloc_test`
  53/53 (incl. 1 new), `quest_detail_bloc_test` green (62/62 combined run).
  No `google_fonts`, no `DateTime.now()`, `disposeApp` pattern untouched.

## FIXES_1 disposition (only logic-layer items acted on)

- Review finding 1 (bubble→pet 16 px gap) → view-side, UI builder owns.
- Review finding 2 (`ARCHITECTURE.md` route table) → shared doc, orchestrator owns.
- 5_ui deviation 1 (+15.3 px block): root cause per 04:52 D1 is the confetti
  layer taking part in layout — fix is feature-side absolute positioning in
  the view (D1 forbids touching `nest_pet_stage.dart`/`pip_rive.dart`), so
  K03B-BUG-2's suggested shared-code fix is SUPERSEDED; no SHARED_REQUEST
  from this layer. UI builder owns the D1 targets (title 469.3 / progress
  513.0 / card1 545.0).
- 5_ui deviation 2 (bubble `textAlign`): fixed on main via `shared/speech_align`
  (04:52 D2) — not this branch.
- K03B-BUG-1/2/3 (parked geometry proofs): view/shared-side, still skipped.
- K03B-BUG-4 parked widget tests: still skipped ON PURPOSE — they assert
  rendered copy (`Mum said yes!`, `+15`) and need the view's meta branch
  (UI builder). Un-skipping now would redden the suite. Integrator: run them
  with `--run-skipped --plain-name K03B-BUG-4` after the view branch lands;
  the entity half they depend on is proven in `kid_home_repository_test`.
- K03B-BUG-5 parked widget test: data half now satisfies it (view renders in
  items order, verified no re-sort); left skipped for the integrator to
  un-skip with `--run-skipped --plain-name K03B-BUG-5` to avoid a same-file
  parallel-edit clash with the UI builder in `k03b_bugs_test.dart`.

## LEFT FOR NEXT ITERATION

- None in the logic layer. Integrator: un-skip + run the K03B-BUG-4/5 proofs
  above, then the full `kid_home` suite (K03 regression: only card order 2–6
  changes by mandate; no non-owned test asserts the old full order — verified
  by grep; single-title finds are order-insensitive).

VERDICT: PASS
