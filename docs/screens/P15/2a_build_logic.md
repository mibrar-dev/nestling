# P15 · Child profile — Stage 2a BUILD, LOGIC CHUNK (iteration 2)

Scope: non-UI layer of feature `family` only — `domain/**`, `data/**`,
`presentation/bloc/**`, the feature's DI/route registration files, and
unit/bloc tests (plus the explicitly-instructed un-skip of the six
`p15_bugs_test.dart` proofs). No edits to `presentation/views/**` or
`presentation/widgets/**` (the UI builder is concurrently editing those in
this worktree and owns them). Implements `1_plan.md` §b plus every
`FIXES_1.md` item in the logic layer.

## CONTRACT CHANGES

Additive only (existing constructions, events and tests compile unchanged):

- New event `FamilyChildSelected({required childId})` — the route
  dispatches it before the first `FamilyLoadRequested`; events run in
  order, so the first emission already follows the requested child.
- New repository method `Future<void> selectChild(String childId)` —
  validates the id against `children` and persists it to
  `app_state.activeChildId`; unknown ids are ignored (fallback covers).
- `FamilyState.copyWith` gains `bool clearErrorMessage = false` (P12
  `P06-BUG-06` precedent) — the only way to express a null `errorMessage`.
- `FamilyRepositoryImpl` constructor gains optional
  `DateTime Function()? clock` (Today precedent) — all existing
  `FamilyRepositoryImpl(db: …)` call sites compile unchanged.

## Fixes landed (all in the logic layer)

- **P15-BUG-1 (major)** — `?childId=` ignored. `childProfileRoute`
  (`family_routes.dart`, owned by this chunk) reads
  `state.uri.queryParameters['childId']` and dispatches
  `FamilyChildSelected` before the load; the bloc persists valid ids via
  `selectChild`, so `watchProfile` — and every sibling screen — follows.
  No P05/P08 change. Timing subtlety found while proving it: the persist
  costs DB roundtrips the tight view proofs don't allow, so `selectChild`
  also records the request synchronously in `_pendingSelection`, which the
  mapper honours when it names a loaded child (membership-gated, so stale
  or unknown values can never render; async validation converges the
  persisted row). Superseded requests never clobber newer ones.
- **P15-BUG-6 (major)** — orphaned rows. `removeChild` now deletes the
  child's `quest_completions`, `ledger_entries`, `savings_goals`,
  `reward_redemptions`, `earned_badges`, `pip_wardrobe` rows, its assigned
  `quests` (family-wide "Anyone" quests survive), then the `children` row —
  all in one `transaction`.
- **P15-BUG-7 (major)** — stale `activeChildId`. Same transaction: when the
  removed child was the persisted selection, repoints it at the first
  remaining child in creation order (the P15 fallback), or NULL when the
  family is empty.
- **P15-BUG-8 (major)** — wall-clock period math. Injectable clock
  defaulting to `Seed.anchorOverride?.toUtc() ?? DateTime.now().toUtc()`
  (Today shape verbatim); production behaviour unchanged
  (`anchorOverride` is null outside tests).
- **P15-BUG-3 (minor, both variants)** — stale/suppressed errors. Load
  `onData` passes `clearErrorMessage: true` on every emission (recovered
  loads drop the dead message); remove failures first clear then raise when
  the message is unchanged, so a repeated identical failure emits twice
  and toasts again — no state-shape change, no view change needed.

## Files changed

- `app/lib/features/family/data/family_repository_impl.dart`: clock,
  `_pendingSelection` + `_effectiveSelection`, `selectChild`, cascading
  transactional `removeChild` with repoint.
- `app/lib/features/family/domain/family_repository.dart`: `selectChild`.
- `app/lib/features/family/presentation/bloc/family_event.dart`:
  `FamilyChildSelected`.
- `app/lib/features/family/presentation/bloc/family_bloc.dart`:
  `_onChildSelected`, `clearErrorMessage` on load, clear-then-raise on
  repeated remove failures.
- `app/lib/features/family/presentation/bloc/family_state.dart`:
  `clearErrorMessage` flag.
- `app/lib/features/family/family_routes.dart`: `?childId=` → selection
  event before load. DI unchanged.
- `app/test/features/family/child_profile_bloc_test.dart`: +2 tests
  (`selectChild` persist/ignore; synchronous first-emission honour).
- `app/test/features/family/p15_bugs_test.dart`: all six `skip:` markers
  removed (brief explicitly instructs un-skipping); header updated. No
  proof logic touched.
- `docs/screens/P15/SHARED_REQUEST.md`: §3 records the landed
  `today_view_test.dart` anchor swap (review finding 9, record-only).

## Not mine (left for their owners)

- Test-stage P15-BUG-2 (failure toasted twice) and review finding 4: the
  fix is view-listener scoping in `child_profile_view.dart` (UI builder).
- Test-stage P15-BUG-4 ("an Egg"): `child_profile_copy.dart` (UI builder).
- Test-stage P15-BUG-5 + ORCHESTRATOR items 1–2: shared `NestListRow` /
  icons — already in `SHARED_REQUEST.md` §§1–2 (orchestrator).
- Review findings 5, 6, 7 (header semantics, hero wrap, `size: 84` token),
  8 (pronoun — no fix), 10 (view-state tests): UI builder / none.
- `child_profile_theme_size_test.dart` icon-label proofs (light+dark) are
  red because the UI builder's in-flight edit swaps row `leadingAsset:`
  for custom `leading:` stacks whose `NestIcon` nodes carry no label —
  view-layer, not this chunk.

## Verification (in `app/`, no simulator)

- `flutter analyze` on the logic scope → No issues found.
- `flutter test test/features/family/` → 228 pass; the only red is the 2
  icon-label proofs above (UI builder's in-flight views).
- Six un-skipped `p15_bugs_test.dart` proofs → all green; the test-stage
  BUG-1 (view) and BUG-3 (bloc) red proofs → green.
- `add_children` + `p05_*` → 135/135 green. `test/core/data/
  repositories_test.dart` → 22/22 green (covers `removeChild`).
- `dart format` clean. No `google_fonts`. No whole-suite run, no
  simulator (integrator's stage).

## LEFT FOR NEXT ITERATION

- Nothing in the logic layer is unfinished. The remaining red (2
  icon-label proofs, BUG-2/BUG-4 view proofs, BUG-5 shared) all belong to
  the UI builder or the orchestrator.

VERDICT: PASS
