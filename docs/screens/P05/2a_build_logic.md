# P05 · Add children — logic build (STAGE 2a, iteration 6)

Scope: non-UI layer of feature `family` only —
`domain/**`, `data/**`, `presentation/bloc/**`, DI/route registration.
No file under `presentation/views/**` or `presentation/widgets/**` touched.

## CONTRACT CHANGES

None. Public names stable per `1_plan.md` §b: `FamilyLoadRequested`,
`FamilyDraftChanged({nickname, ageBand, avatarColour})`,
`FamilyAddChildRequested({onSaved})`, and all `FamilyState` fields
(`children`, `draftNickname`/`draftAgeBand`/`draftAvatarColour` defaults
`''`/`'7-9'`/`'peach'`, `nicknameError`, `saveInProgress`,
`lastSavedNickname`) are exactly what `add_children_view.dart` consumes
(verified read-only: view dispatches `FamilyLoadRequested`,
`FamilyDraftChanged`, `FamilyAddChildRequested` and reads
`saveInProgress`, `nicknameError`, `lastSavedNickname`, `draftAgeBand`,
`draftAvatarColour`, `status`). No UI-builder rework required.

## Files changed

1. `app/lib/features/family/data/family_repository_impl.dart`
   - Retired the interim `rowid`-only `_watchChildrenInAddedOrder()` query.
     Schema v3 (shared batch 2, on main) gave `children` a real `createdAt`
     column and `AppDatabase.watchChildren` now orders by
     `createdAt, rowid` (CHILD ORDER ruling, durable form), so the feature
     delegates to the shared helper instead of maintaining a private query.
     Behaviour is identical on all existing data (seed `createdAt` order ==
     insertion order; `addChild` writes an explicit `now()` instant), and the
     stale "table has no creation marker" comment is gone.
   - `dart format` clean, `flutter analyze lib/features/family` → No issues.
2. `docs/screens/P05/SHARED_REQUEST.md`
   - Top entry updated: durable child-order fix recorded as LANDED, P05
     consumption of the shared helper noted, close-out condition stated
     (UI gate confirms Maya-first). No new shared requests (none needed:
     routes, `addChild`/`watchChildren`, and every DS component exist).

## Items done

- `1_plan.md` §b fully implemented in this layer (bloc/state/events/draft
  defaults/validation messages `Give them a nickname` /
  `Keep it under 24 characters` / `Something went wrong — try again`
  with em-dash, double-tap guard P05-BUG-2, mid-save typing guard P05-BUG-5,
  `ageYears` band mapping P05-BUG-6, explicit `createdAt` on insert).
- `FIXES_5.md`: single deviation is the shared `NestChip` 44 px flow box —
  not this layer (shared `core/`, read-only). No logic items, no skipped bug
  tests referenced. Nothing to fix here.
- `ORCHESTRATOR_NOTES.md` logic items: CHILD ORDER enforced in this
  repository (creation order, Maya then Leo) with order-locking tests green;
  no `google_fonts`/`GoogleFonts` anywhere in `lib/features/family` or its
  tests; no `TODO(P05)` in this layer.
- Verification: `flutter test test/features/family` → **116 passed**,
  including all bloc/order/repository proofs (`p05_bugs_test.dart` 11/11,
  child-order groups, rename-survives-order, bloc-never-reorders).

## NOT this layer (verified pre-existing, left for UI builder / integrator)

`flutter test test/features/family` has 3 red widget-geometry tests, all in
`add_children_test.dart`, all caused by shared batch 2 (`NestChip` now lays
out 32 px with the 44 px hit area overlaid — orchestrator 23:48 note), and
all proven independent of this stage's edit (fail identically with the
`family_repository_impl.dart` change stashed):

- `the chip row height is the design value plus the 44-px tap box`:
  expects the old +12 px delta, measures 0.0 — the shared fix landed, so the
  expectation flips to 0 (the test's own comment predicts this).
- `every interactive control is at least 44px` (age chip measures 32.0) and
  `the failure panel Try again button is a 44+ target`: layout-size
  assertions that need re-measuring against the overlay hit area.
- Fixing them means deciding how the new overlay hit area is asserted and
  editing widget-test expectations in a file the UI builder owns — out of
  this stage's layer, so deliberately untouched to avoid a parallel-edit
  conflict.

## LEFT FOR NEXT ITERATION

- UI builder: flip/pin the 3 chip-geometry expectations above to the new
  32 px-layout + overlay-hit-area behaviour (and drop any local chip
  workaround per the 23:48 note); `kid_card_grid.dart:15` comment still says
  "rowid-ordered watch" — one-line comment refresh to "creation-ordered".
- Integrator: close the child-order `SHARED_REQUEST.md` entry once the UI
  gate confirms Maya-first on the merged build.

VERDICT: PASS
