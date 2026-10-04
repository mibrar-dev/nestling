# P16 Settings — 2a build, logic chunk (iteration 6)

Scope: non-UI layer only — `domain/**`, `data/**`, `presentation/bloc/**`,
`settings_di.dart`, plus unit/bloc tests. No view/widget file touched.

## CONTRACT CHANGES

Additive only: `SettingsRepositoryImpl` takes an optional
`FamilyZoneService? zoneService` (defaults to a local instance, so all
existing `SettingsRepositoryImpl(db: …)` constructions compile unchanged).
No state/event/entity/interface shape changed.

## FIXES_5 triage (logic layer)

- **Review 5 (done)** — `watchMembers` now delegates to the shared
  `AppDatabase.watchMembers()` (batch 6) instead of feature-local raw SQL;
  order (Sarah → James) and mapping unchanged.
- **Review 6 (done)** — the repository no longer builds its own
  `FamilyZoneService` inline; it holds an injected one, wired to the DI
  singleton in `settings_di.dart`.
- **Review 7 (kept, re-verified)** — `SettingsItem` / `watchItems()` /
  `getItems()` still have live consumers: the shared
  `test/core/data/repositories_test.dart` settings group calls
  `repo.watchItems()`, and `settings_states_test.dart`'s fake delegates
  both. Deleting them would break files outside my editable paths.
- **P16-T04** (avatar initials): views-only fix (`nestAvatarInitial`
  swaps in `settings_view.dart`). Not mine.
- **P16-B09** (IANA links): shared `family_time.dart`. Not mine.
- **Review 1/3/4** (un-fork sequencing, ripple, chip-label token):
  views/SHARED_REQUEST-owned. **Review 2/3** (stale comments): test files
  I don't own. **Review 5 e-mail part**: already live via `members.email`.
  **Review 6 guard part / finding 2** (fenced switches): views.
- CLOCK re-verified: `grep DateTime.now()` over domain/data/bloc → 0 hits.

No skipped proof in my layer needed un-skipping: T04's proof is in
`settings_a11y_test.dart` (views), B09's in `p16_bugs_test.dart` (shared).

## Files changed

- `app/lib/features/settings/data/settings_repository_impl.dart`:
  shared `watchMembers`, injected zone service.
- `app/lib/features/settings/settings_di.dart`: wires the zone-service
  singleton into the repository.
- `app/test/features/settings/settings_repository_test.dart`: owner/co-parent
  e-mail assertions (DB-driven), explicit-service zone-write test.

## Verification (this iteration)

- `flutter analyze` on my layer + my test files → No issues found.
- `flutter test --timeout 120s` on my files → 40/40 pass.
- No simulator booted, screenshotted or driven.

## LEFT FOR NEXT ITERATION

- Nothing outstanding in the logic layer. Open FIXES_5 items (T04, B09,
  review 1–4/6/8) are views/shared/test-stage-owned as triaged above.

VERDICT: PASS
