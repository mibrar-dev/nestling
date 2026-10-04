# P16 Settings — 2a build, logic chunk (iteration 2)

Scope: non-UI layer only — `domain/**`, `data/**`, `presentation/bloc/**`,
`settings_di.dart`, plus unit/bloc tests and un-skipping the logic-layer bug
proofs in `FIXES_1.md`. No view/widget file touched (one comment-only edit to
`p16_bugs_test.dart` to un-skip the fixed B02 proof).

Iteration 1 is superseded except where noted; the contract below is current.

## CONTRACT CHANGES ( additive, one removal)

1. **Added `SettingsState.deviceZoneId: String?`** — the raw device zone from
   the bloc's one-shot read, kept regardless of dismissal. The zone picker
   must order by this field (device row first when non-null and ≠
   `familyZoneId`), not by `pendingZone` (review finding 1 / P16-B01 logic
   half). `pendingZone` semantics are unchanged (banner-only).
2. **Added `SettingsSessionStore`** (`presentation/bloc/
   settings_session_store.dart`, DI lazy singleton): holds session
   `dismissedZones`. `SettingsBloc` takes an optional `sessionStore` (defaults
   to the DI singleton when registered, else a fresh store, so direct unit
   constructions stay hermetic). Load merges the store into state; dismiss
   writes the store and emits (P16-B02).
3. **Removed `SettingsState.items`** (review finding 5): no consumer — the
   replaced view never read it and no settings test referenced it. Kept:
   `SettingsItem`, `settingsItemsFor` (still serve repository `watchItems()`,
   pinned by the shared `repositories_test` settings group), and
   `getItems`/`watchItems` signatures (unchanged behaviour).

## Files changed

- `presentation/bloc/settings_session_store.dart` (new).
- `presentation/bloc/settings_state.dart`: +`deviceZoneId`, −`items`
  (ctor/copyWith/props/docs).
- `presentation/bloc/settings_bloc.dart`: `_watchMoveInput()` yields
  `(device, pending)`; load merges the session store; dismiss writes it;
  `settingsItemsFor` import dropped.
- `settings_di.dart`: registers/passes `SettingsSessionStore`.
- `domain/entities/settings_item.dart`: doc refresh (repo-owned helper now).
- `test/.../settings_bloc_test.dart`: device assertions (banner + surviving
  dismissal), new `session dismissals` group (shared-store rebuild + DI
  fallback), initial-state `deviceZoneId` check.
- `test/.../settings_repository_test.dart`: new CLOCK test — writes stamp
  `updatedAt` with `appNowUtc()` (pinned `2026-10-03 08:41Z`).
- `test/.../p16_bugs_test.dart`: un-skipped `[P16-B02]` only (comment swap).

## FIXES_1 triage (logic layer only)

- **P16-B01 (logic half done)**: `deviceZoneId` populated and tested; proof
  still fails (`--run-skipped` re-checked) because the picker still reads
  `pendingZone` — UI builder's half, in their layer. Left skipped.
- **P16-B02 (done)**: session store; proof passes `--run-skipped` and in-suite;
  un-skipped. My bloc tests cover the rebuild + fallback paths.
- **P16-B04 (repo part already clean)**: no `DateTime.now()` in
  domain/data/bloc (the two `_write` stamps already use `appNowUtc()` from a
  main merge); remaining offender is `zone_picker_sheet.dart:85` (UI layer).
  Left skipped.
- **Review 1 (logic half done)**: same as B01. **Review 4 (repo part done)**:
  same as B04. **Review 5 (done)**: `state.items` deleted as above.
- **Not mine (views/shared, untouched)**: P16-T01/B07, P16-T02, B03, B05,
  B06, review 2/3/6/7/8, navigation/a11y skips, email/schema items.
- Verified: `flutter analyze lib/features/settings test/features/settings`
  → No issues found; `dart format` applied; my files 37/37 pass;
  `p16_bugs_test.dart` +14 ~6 green. Full `test/features/settings` reads
  +94 ~10 −2 — both failures are in `settings_a11y_test` and reproduce with
  my changes stashed (parallel UI-builder view edits in flight), not this
  layer. No simulator used.

## LEFT FOR NEXT ITERATION

- UI builder: picker orders by `state.deviceZoneId` (un-skips B01);
  `zone_picker_sheet.dart:85` → `appNowUtc()` (un-skips B04); all views-layer
  FIXES items (T01/T02/B03/B05/B06/B07, review 2/3/6/7/8).

VERDICT: PASS
