# K03 Kid home — test notes (Stage 3, iteration 1)

Scope: `kid_home` feature, route `/kid-home` (`KidHomeRoutePaths.home`), kid
mode. Screen code is Stage 2's; this stage adds tests only (plus this note).

## Files

- `app/test/features/kid_home/kid_home_bloc_test.dart` — extended (4 → 14
  tests): every `KidHomeEvent` path, every `KidHomeStatus`, live stream
  re-emission, retry, action-error, plus `KidHomeState` value semantics.
- `app/test/features/kid_home/kid_home_view_test.dart` — extended (10 → 30
  tests): 12-cell layout matrix, empty/loading/error states, all tap
  destinations, semantics labels and kid tap sizes.
- No `app/lib/**` change in this stage; no files outside RULES §1.

## Bloc + state coverage (14 tests)

`KidHomeState` (5):
- defaults idle/empty (status, child, items, counts, fraction, errors);
- `doneCount` counts `approved` + `done_pending` only (4 items → 2, 0.5);
- `copyWith` keeps the child; `copyWithLoaded` can clear it;
- equal states compare equal; `KidHomeQuestCompleted` equality covers
  childId/questId/coins.

`KidHomeBloc` (9 `blocTest`s) over a stream fake that hands out fresh streams
per call (like the Drift repo):
- load → `loading` → `loaded` (Maya, 6 items, 4/6, fraction ≈ 0.667);
- load mirrors live item and child stream updates (4/6 → 5/6 → child null);
- loaded child with no quests → zero counts;
- silent streams stay `loading`;
- load failure → `failure` with `errorMessage`;
- failure then retry → `loading` → `loaded`;
- check tap: `completeQuest('maya','q-reading')`, flip streams back in as
  5/6;
- completion failure: list kept, `actionError` set, item still `to_do`;
- completion before any load still reaches the repository.

## Widget coverage (30 tests, all over the in-memory Drift DB)

Layout matrix — light + dark × 320/390/430 × text scale 1.0/1.3 (12):
header ('Hi Maya!', '120', '4 of 6 done'), all 6 quest cards, dock
Pip/Shop/My jar, no `£` anywhere, `takeException()` null (no overflow).
The card list is scrolled into view first (see notes).

States:
- `Seed.empty` (no active child) light + dark: 'Who's playing?' + 'Choose';
  Choose navigates to `/who-is-playing`;
- child with no quests (extra child row, no quests): 'Hi Nina!',
  '0 done today', 'No quests today', 'Enjoy playing with Pip!', dock kept;
- loading light + dark (silent fake repo): spinner + semantics
  'Loading your quests';
- load failure light + dark (erroring fake repo): 'Oh no! Pip got lost.' +
  'Try again' → recovers to the loaded home;
- failed completion (fake repo): SnackBar 'Hmm, that did not work. Try
  again.', list kept, `completeQuest` attempted.

Navigation (every tap):
- quest card body → `/quest-detail` with `extra {questId: q-reading,
  childId: maya}`;
- to-do check → `/quest-complete` with `extra {questId, childId, coins:10}`
  and the DB row flips to `done_pending` (read back through the repository);
- done check (done_pending card) → no completion action (pending approvals
  still 3); the tap falls through to the card and opens `/quest-detail`;
- lock → `/parental-gate`;
- dock → `/pip`, `/reward-shop`, `/my-jar`;
- 'Choose' → `/who-is-playing` (state group);
- 'Try again' re-fires the load (state group).

Accessibility:
- semantics: lock 'Grown-ups', coin '120 coins', header 'Hi Maya, 4 done
  today', progress '4 of 6 of today's quests done', hearts 'Pip is happy
  today, 4 of 5 hearts', checks 'Mark done' ×2 / 'Done' ×4, card nodes
  'Empty the dishwasher, Waiting for Mum's thumbs-up' and 'Put the bins out,
  Done' (merged node, read via `tester.getSemantics`);
- tap targets ≥ 56 (`NestDevice.tapKid`): lock 56×56, to-do check, all 3 dock
  buttons, all 6 quest card rows;
- 320 px at scale 1.3 keeps lock + progress semantics, no overflow.

## Results

- `dart format --set-exit-if-changed .` — 341 files, 0 changed.
- `flutter analyze` — `No issues found!`
- `flutter test` — `00:06 +331: All tests passed!` (kid_home: 44 = 14 bloc +
  30 view; suite was 301 before).

## Bugs found

None. Every test passes; no screen defect was exposed. The items below were
investigated and are behaviour, not defects.

## Notes / observations (not bugs)

1. Lazy list: `ListView` at `kid_home_view.dart:317` builds the trailing card
   column only when it enters the viewport + cache extent. At 390/430 px and
   text scale 1.3 the column starts below that line, so the cards are absent
   from the tree until the list scrolls (standard Flutter). The tests scroll
   explicitly before counting cards; nothing is unreachable at runtime.
2. Two Drift sources can each forward an error (`kid_home_bloc.dart:28`), so a
   double failure emits two equal-looking `failure` states. The view renders
   the same failure screen; the view tests drive this path with both fake
   streams erroring.
3. `copyWithLoaded` keeps the previous `errorMessage`
   (`kid_home_state.dart:61`), so after a successful retry the loaded state
   still carries the stale message. Not rendered while `status == loaded`;
   no user-visible effect on K03.
4. `NestKidQuestCard` labels both approved and `done_pending` checks 'Done'
   (`nest_quest_card.dart:318`, shared component); the card node carries the
   'Waiting for Mum's thumbs-up' status, which is what screen readers announce
   for the row. A per-check pending label would need a shared-component change
   (not requested; non-blocking).

## Harness notes (for other screen agents)

- Direct Drift work in a `testWidgets` body (e.g. `Seed.empty`, raw inserts,
  repository reads) deadlocks under the fake-async zone; wrap it in
  `tester.runAsync(...)`. Streams driven through `tester.pump` are fine.
- Avoid `pumpAndSettle` on screens that can be loading: the
  `CircularProgressIndicator` never settles; bounded
  `pump()`/`pump(Duration)` steps are deterministic.
- `find.bySemanticsLabel` matches explicit `Semantics` widgets and cannot see
  merged nodes; use `tester.getSemantics(finder).label` for merged card nodes.

VERDICT: PASS
