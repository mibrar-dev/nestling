# K01 · Stage 2a — BUILD, LOGIC CHUNK (iteration 1)

Scope: ONLY the non-UI layer of feature `kid_home` for K01
(`domain/**`, `data/**`, `presentation/bloc/**`, plus owned tests).
Views/widgets belong to the UI builder — untouched by this stage.

## CONTRACT CHANGES

None — implemented exactly per `docs/screens/K01/1_plan.md` §2.
Public names the UI builder codes against (stable):

- Events: `KidHomeProfilesRequested`, `KidHomeProfileSelected(childId,
  pinSet)`, `KidHomeProfilesReceived(profiles)`,
  `KidHomeProfilesFailed(error)` (existing `KidHomeLoadRequested` /
  `KidHomeQuestCompleted` / `KidHomeDataReceived` / `KidHomeStreamFailed`
  untouched).
- State: `profiles` (default `const <KidChild>[]`, creation order),
  `selectedProfileId` (nullable one-shot; view pushes `pinSet ?
  KidHomeRoutePaths.pin : KidHomeRoutePaths.home` with
  `extra: {'childId': id}`), `copyWithSelection(childId)`,
  `copyWithProfiles(next)`.
- Repo: `Future<void> setActiveChild(String childId)` (writes
  `app_state.activeChildId`, owns its write like `completeQuest`).
- Entity: `KidChild.ageBand` (`required`, DB stores `7-9`, view renders
  `7–9` U+2013).

## Files changed (logic layer)

- `app/lib/features/kid_home/domain/entities/kid_child.dart` — added
  `required ageBand` (+ docs, + props).
- `app/lib/features/kid_home/domain/kid_home_repository.dart` — added
  `setActiveChild` with K01 contract docs.
- `app/lib/features/kid_home/data/kid_home_repository_impl.dart` —
  `_toChild` maps `ageBand: row.ageBand`; added `setActiveChild`
  (`UPDATE app_state WHERE id = 1`). No `AppSession` dependency.
- `app/lib/features/kid_home/presentation/bloc/kid_home_event.dart` —
  4 new events per plan (list above). No navigation in bloc.
- `app/lib/features/kid_home/presentation/bloc/kid_home_state.dart` —
  `profiles` + `selectedProfileId` fields + props; every
  `copyWith`/`withCompletion*` constructor carries both (a dropped
  `profiles` would blank the picker after any quest emit);
  `copyWithLoaded` carries `profiles` and consumes `selectedProfileId`
  one-shot (same pattern as `justCompletedQuestId`); new
  `copyWithSelection` / `copyWithProfiles`.
- `app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart` —
  guarded `_profilesSub` beside the existing `_homeSub` (same K03-BUG-15
  pattern: ignore reload while live, release on error and on `close()`,
  so Try again via `KidHomeLoadRequested` really reloads);
  `KidHomeProfilesRequested` restarts just the profiles stream;
  `KidHomeProfileSelected` awaits `setActiveChild` then emits
  `copyWithSelection`, on error emits `withCompletionFailed`
  (`actionError`/`actionNonce`, view toasts
  `Hmm, that did not work. Try again.`); profiles mid-session error
  keeps the shown roster, failure card only when nothing to show.
- DI/routes: no change needed (`registerKidHome` already provides the
  bloc factory; picker/pin/home routes already dispatch
  `KidHomeLoadRequested`, which now starts both subscriptions).

## Tests

- `app/test/features/kid_home/kid_home_bloc_test.dart` (owned) —
  `_maya`/`_leo` gain `ageBand`; fake roster is `[maya, leo]`
  (creation order) with `failProfiles`/`failSelect` flags,
  `selected` record, pushable profiles; new `_loadingWithProfiles`
  matcher documents the fresh-load sequence
  (`loading` → `loading`+roster → `loaded`: profiles emit before home);
  12 existing sequences extended with it (behaviour-preserving, the
  picker roster arriving while still loading); new `K01 profiles` group
  (7 tests: roster Maya-first + ageBands, profiles-only retry keeps one
  home subscription, selection writes + emits, failed selection keeps
  roster + `actionError`, mid-session profiles error keeps roster,
  carry-through unit test, event equality).
- `app/test/features/kid_home/kid_home_repository_test.dart` (new,
  owned) — DB-backed over `Seed.demo`: `watchProfiles` returns
  `[maya, leo]` with K01 fields (Maya `pinSet: true`, Leo
  `pinSet: false`); `setActiveChild` persists to `app_state` and
  `watchHome` follows without reload.
- Minimal compile-keeping edits outside the owned set (per plan §2
  "update ALL existing constructors", no behaviour change):
  `k03_bugs_test.dart` + `kid_home_view_test.dart` — `ageBand` on the
  `_maya` fixture and a no-op `setActiveChild` stub on each K03-era
  fake (8 in `k03_bugs`, 1 in view test). K01 selection is covered in
  the bloc + repository tests above.
- Did NOT touch: `presentation/views/**`, `presentation/widgets/**`
  (UI builder's: `profile_picker_view.dart`, `kid_home_view.dart`,
  `profile_tile.dart`, `kid_style_helpers.dart` all theirs).

## Verification (this stage only — no simulator, no full-app test run)

- `flutter analyze lib/features/kid_home test/features/kid_home` →
  No issues found. `dart format` applied (4 files).
- `flutter test test/features/kid_home/kid_home_bloc_test.dart
  test/features/kid_home/kid_home_repository_test.dart` → 40/40 pass.
- `k03_bugs_test.dart` shows 8 failures, `kid_home_view_test.dart`
  fails on counts/chips — verified IDENTICAL at clean HEAD
  (scratch worktree of `6653e2e`, since removed): pre-existing KNOWN
  RED date-skew (real clock = 4 Oct, seed pinned to 3 Oct; daily
  completions expired → fewer done/chips), not this screen's
  findings. No new failures introduced.
- No `google_fonts`, no `letterSpacing`, no `DateTime.now()` added;
  no `flutter clean`, no simulator use.

## LEFT FOR NEXT ITERATION

- Nothing unfinished in the logic layer. UI builder owns the picker
  view/tiles, navigation pushes, semantics wiring, geometry tests and
  the `k01_profile_picker_test.dart` widget suite per plan §6.
- Integrator owns: full `flutter test`, `shot.sh` light+dark,
  `compare.py` UI check (±2 px rule).

VERDICT: PASS
