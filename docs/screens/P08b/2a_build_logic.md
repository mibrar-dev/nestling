# P08b · 2a_build_logic — non-UI layer (iteration 2)

Scope: `today` domain/data/bloc + DI/routes only. No views/widgets edits.
Fixes every FIXES_1.md item in this layer: P08b-T05/B01 (date line),
P08b-T06/B02 (child order). T01–T04, review findings 2/4–8, B03–B05 are
widgets/view-tests — UI builder's, untouched.

## CONTRACT CHANGES

None. Events (`TodayLoadRequested` only), state shape, repository interface,
DI registration and route paths are all unchanged. The UI builder codes
against the existing `TodayState` fields.

## Files changed

- `app/lib/features/today/presentation/bloc/today_bloc.dart` — T05/B01: the
  fresh-nest suffix now uses the same predicate as the shared empty branch
  in `TodayLoadedBody` (`items.isEmpty || summaries.isEmpty`), not
  `summaries.isEmpty` alone. `Seed.newFamily` (children, no quests) now reads
  `Sat 3 Oct · A fresh nest`. P08 unaffected (demo seed always has items).
- `app/lib/features/today/data/today_repository_impl.dart` — T06/B02: dropped
  the eldest-first + nickname re-sort in `watchSummaries()`; summaries keep
  `watchChildren` creation order (CHILD ORDER ruling: Maya, then Leo). Stale
  "Eldest first" comment replaced. Demo/new-family rendering does not move
  (Maya is first and oldest in both seeds).
- `app/test/features/today/today_bloc_test.dart` — new `blocTest`: items
  empty + summaries non-empty (new-family state) → `A fresh nest`, no
  `Happy week`. Iteration-1 empty-summaries assertion kept.
- `app/test/features/today/today_repository_test.dart` — stale "Eldest first"
  comment fixed to creation order; new test: inserting Zara (12) after
  Maya/Leo yields `[maya, leo, zara]`.
- `app/test/features/today/p08b_bugs_test.dart` — un-skipped B01 + B02 only
  (`skip: true` removed on those two proofs). B03–B05 stay skipped for the
  UI builder. No other edits to that file.

## Items done

- [x] T05/B01 + review finding 1: bloc predicate fixed; B01 proof green.
- [x] T06/B02 + review finding 3: sort removed; B02 proof green; stale
  comments at impl + repo test updated.
- [x] No `DateTime.now()`, no `google_fonts` in code or touched tests.
- [x] DI/routes verified unchanged and correct (no edit).

## Verification

- `flutter analyze lib/features/today` + touched test files → No issues found.
- `flutter test --timeout 120s today_bloc_test today_repository_test p08b_bugs_test` → 48 passed, 3 skipped (B03–B05, UI layer).
- P08 regression: `today_view_test today_semantics_tap_test p08_bugs_test` → 77 passed.
- `today_empty_view_test` proofs `P08b-T05` (date line) + `P08b-T06` (older child last) → pass unmodified (turn green on their own).
- `dart format` on all touched files → clean. No simulator used.

## LEFT FOR NEXT ITERATION

Nothing in this layer. Remaining FIXES_1.md items (T01 8 px shift, T02 link
row, T03 tip gap, T04 greeting wrap, B03–B05, underline colour, view-test
coverage) are UI-builder owned.

VERDICT: PASS
