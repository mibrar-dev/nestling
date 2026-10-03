# P05 · Add children — logic build (STAGE 2a, iteration 7)

Scope: non-UI layer of feature `family` only —
`domain/**`, `data/**`, `presentation/bloc/**`, DI/route registration.
No file under `presentation/views/**` or `presentation/widgets/**` touched.

## CONTRACT CHANGES

None. Public names stable per `1_plan.md` §b (`FamilyLoadRequested`,
`FamilyDraftChanged`, `FamilyAddChildRequested({onSaved})`, all
`FamilyState` fields and draft defaults). No UI-builder rework required.

## Files changed

None in this iteration — verify-only. The iteration-6 logic change
(`FamilyRepositoryImpl.watchChildren` delegates to the shared
`AppDatabase.watchChildren`, `createdAt, rowid` ordering; interim
`rowid`-only query retired) is present in the worktree (committed in
iteration 6, survived the `fc68854` main merge) and re-verified below.
`family_di.dart` / `family_routes.dart` need no changes (bloc registered as
factory, routes dispatch `FamilyLoadRequested`).

## Items done

- `FIXES_6.md` triaged for this layer: its only bug, **P05-BUG-11** (chip
  tap-area clipped by the `Wrap`), sits in
  `presentation/widgets/add_child_form_card.dart` + shared `nest_chip.dart`
  — explicitly "no P05-local fix exists" and therefore not this layer.
  No logic items, no logic-layer skipped tests to un-skip.
- `ORCHESTRATOR_NOTES.md` 04:31 decision checked: the shared `NestChipWrap`
  has **not** landed (no `*chip_wrap*` under `core/design_system`; main
  merged via `fc68854`), so per the ruling the correct logic-layer action
  is nothing — P05-BUG-11 stays skipped, which it is
  (`p05_bugs_test.dart:498`, `skip: true`). The Wrap swap + `atLeast44`
  restore + un-skip all belong to the UI builder / shared fix when
  `NestChipWrap` arrives.
- Verification (this worktree, unchanged code):
  `flutter analyze lib/features/family` → No issues found;
  `flutter test test/features/family` → **122 passed, 1 skipped, 0 failed**
  (the skip is the mandated P05-BUG-11 proof). FONTS rule re-grepped:
  no `google_fonts`/`GoogleFonts` in `lib/features/family` or its tests.

## LEFT FOR NEXT ITERATION

- UI builder (when main contains `NestChipWrap`): replace the age-chip
  `Wrap` with `NestChipWrap`, restore the tap-target test to
  `atLeast44(chip)` in height and width, un-skip P05-BUG-11.
- Test/UI side nit (not this layer's file to edit in parallel): the
  P05-BUG-11 `skip: true` carries no reason string yet — the 04:31 note
  asks for a reason referencing `shared/chip_wrap_hit_area`.

VERDICT: PASS
