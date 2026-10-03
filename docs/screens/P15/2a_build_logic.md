# P15 · Child profile — Stage 2a BUILD (logic chunk, iteration 1)

Scope: non-UI layer of feature `family` only — `domain/**`, `data/**`,
`presentation/bloc/**`, plus unit/bloc tests. No edits to
`presentation/views/**` or `presentation/widgets/**` (UI builder owns those;
they were mid-edit in this worktree and were not touched).
No DI/route changes (plan §b: "DI: unchanged" — `family_di.dart` and
`family_routes.dart` already wire `FamilyBloc` + `/child-profile`).

## CONTRACT CHANGES

None. Public names match the plan exactly: `ChildProfile`,
`FamilyRepository.watchProfile()`, `FamilyState.profile`,
`FamilyRemoveChildRequested(childId)`.

## Implementation notes (deviation from plan, same public shape)

- Plan §b prescribes `asyncExpand` from the combined base streams onto
  `watchLedger(childId)`. `Stream.asyncExpand` has concat semantics: it
  waits for each inner stream to CLOSE before processing the next outer
  event — and Drift `watch()` streams never close. Verified with a failing
  test (since removed): after `removeChild('maya')` the base re-emits but
  the profile never switches to Leo. `watchProfile()` therefore uses a
  feature-local `StreamController` with *switch* semantics: the ledger
  subscription follows the current selection, and a profile only emits
  once the ledger rows match the current selection (no cross-child owed
  flash). The four base streams still combine via the shared
  `combineLatest4`; no core helpers added, no shared files touched.
- `owedPence` replicates the pure algorithm from
  `PocketMoneyRepositoryImpl.summarise`
  (`pocket_money/.../pocket_money_repository_impl.dart:259-284`), cited in
  a comment; no cross-feature import.
- Period counting uses the 3-arg `countsForCurrentPeriod` from
  `core/data/london_time.dart` (per the PERIODS ruling); `family_time.dart`
  is imported with that name hidden (it exports a 4-arg overload).
- `FamilyState.copyWith` uses a `_keepProfile` sentinel (same pattern as
  `nicknameError`): draft edits omit it (stays put), the load stream passes
  an explicit value — including null when the last child is removed.

## Files changed

- `app/lib/features/family/domain/entities/child_profile.dart` (new):
  `ChildProfile` (Equatable, const) — `child`, `questsThisWeek`,
  `dailyActive`/`weeklyActive`/`onceActive`, `owedPence`.
- `app/lib/features/family/domain/family_repository.dart`:
  `Stream<ChildProfile?> watchProfile()`.
- `app/lib/features/family/data/family_repository_impl.dart`: `watchProfile`
  (selection `activeChildId` ?? first-created ?? null; breakdown by
  `repeatRule` with unknown → `once`; `questsThisWeek` =
  done_pending/approved completions in the current London period via the
  completion quest's rule; owed via the replicated summarise algorithm).
- `app/lib/features/family/presentation/bloc/family_event.dart`:
  `FamilyRemoveChildRequested(childId)`.
- `app/lib/features/family/presentation/bloc/family_state.dart`:
  `ChildProfile? profile` (+ sentinel copyWith, props).
- `app/lib/features/family/presentation/bloc/family_bloc.dart`: single
  `emit.forEach` nests `combineLatest2(watchItems, watchChildren)` with
  `watchProfile`; remove handler awaits `removeChild` (streams re-emit),
  failures emit `errorMessage` with status staying `loaded`.
- `app/test/features/family/child_profile_bloc_test.dart` (new, 14 tests):
  entity equality; real-DB profile for demo Maya (6 active, 4/2/0
  breakdown, `questsThisWeek == 4`, `owedPence == 420`); fallback to
  first-created when unset/unknown; Leo selection (`owedPence == 210`);
  null on fresh seed; mock load emits members+children+profile; later
  profile emission replaces (incl. clearing to null); remove calls
  `removeChild('maya')`; remove failure keeps `loaded` + message; real-DB
  remove maya → Leo re-emit + DB row gone; remove last child → null
  profile; copyWith sentinel behaviour.
- Stub-only upkeep in `app/test/features/family/add_children_test.dart` and
  `p05_bugs_test.dart`: every mock setup that dispatches
  `FamilyLoadRequested` now also stubs `watchProfile` to
  `Stream<ChildProfile?>.value(null)` (+ `child_profile.dart` import).
  Required by plan §f ("keep green"): mocktail returns null for unstubbed
  methods, so the new bloc subscription threw
  `type 'Null' is not a subtype of Stream<ChildProfile?>`. No assertions
  changed; P05 screens never read `profile`.

## Verification

- `flutter analyze lib/features/family test/features/family/` → No issues.
- `flutter test test/features/family/child_profile_bloc_test.dart` → 14/14 pass.
- `flutter test .../p05_bugs_test.dart .../p05_view_metrics_test.dart` → all pass.
- `flutter test .../add_children_test.dart` → 116 pass, 3 fail — all three
  assert `find.text('P15 Child profile')` (the placeholder title) after
  navigating to `/child-profile`; the UI builder's in-progress
  `ChildProfileView` replacement removed that text. Navigation itself
  (`currentPath == '/child-profile'`) still passes. View-owned assertions,
  left for the UI builder/integrator.
- Whole-app `flutter test` and any simulator use deliberately not run
  (integrator's stage).

## LEFT FOR NEXT ITERATION

- The 3 `add_children_test.dart` placeholder-text assertions above (UI
  builder's view now renders the real P15 screen; update or relocate those
  assertions alongside `child_profile_view_test.dart`).
- `child_profile_view_test.dart` (widget/copy coverage) belongs to the UI
  builder — not written here per the parallel-split rule.

VERDICT: PASS
