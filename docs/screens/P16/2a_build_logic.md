# P16 Settings — 2a build, logic chunk (iteration 1)

Scope: non-UI layer only — `domain/**`, `data/**`, `presentation/bloc/**`,
`settings_di.dart`, and `bloc`/`repository` unit tests. No view/widget file
touched.

## Files changed

- `app/lib/features/settings/domain/entities/settings_child_entry.dart` (new):
  `SettingsChildEntry` (`id`, `nickname`, `ageBand` raw e.g. `7-9`,
  `pipStageName`, `coins`, `avatarColour`) + `settingsPipStageName(stage)`
  (`1 Egg`, `2 Hatchling`, `3 Fledgling`, `4 Songbird`, unknown → `Fledgling`).
- `app/lib/features/settings/domain/entities/settings_member_entry.dart` (new):
  `SettingsMemberEntry` (`id`, `name`, `role`, `inviteStatus`).
- `app/lib/features/settings/domain/entities/settings_item.dart` (extended):
  added pure `settingsItemsFor(AppSettings)`; the legacy `_rows` body moved
  here unchanged so repo and bloc share it (old view keeps compiling).
- `app/lib/features/settings/domain/settings_repository.dart` (extended):
  added `watchRoster()` + `watchMembers()`. All existing members untouched.
- `app/lib/features/settings/data/settings_repository_impl.dart` (extended):
  `watchRoster()` via `_db.watchChildren` (creation order, Maya→Leo);
  `watchMembers()` via `members` ordered by `rowid` (Sarah→James);
  `watchItems()` now maps `settingsItemsFor` (identical output).
- `app/lib/features/settings/presentation/bloc/settings_event.dart`
  (extended): kept `SettingsLoadRequested`; added
  `SettingsNotificationsChanged({approvals?, payout?, summary?})`,
  `SettingsTimeZonePicked(zoneId)` (positional),
  `SettingsMoveConfirmed()`, `SettingsMoveDismissed(zone)` (positional).
- `app/lib/features/settings/presentation/bloc/settings_state.dart`
  (extended): kept `status`/`items`/`errorMessage`; added
  `settings: AppSettings?`, `familyRoster`, `memberRows`,
  `familyZoneId` (default `Europe/London`), `pendingZone: String?`,
  `dismissedZones: Set<String>` (default `{}`). `copyWith` gains
  `clearPendingZone` so the banner can clear to null explicitly.
- `app/lib/features/settings/presentation/bloc/settings_bloc.dart`
  (rewritten): `SettingsBloc({repository, zoneService})`; one `emit.forEach`
  over `combineLatest3(watchSettings+watchFamilyTimeZone,
  watchRoster+watchMembers, _watchPendingMove)` with the house
  `_closeOnError`. Write handlers never emit (streams re-emit); only
  `SettingsMoveDismissed` emits (no stream backs it). `_watchPendingMove`
  is a one-shot device-zone read re-evaluated per family-zone emission.
  Also exports `gmtOffsetLabel(zoneId, nowUtc)` (`GMT+4`, `GMT+0`, BST→`GMT+1`).
- `app/lib/features/settings/settings_di.dart` (extended): injects shared
  `FamilyZoneService` (registered in `app/di.dart` before this runs).
- `app/test/features/settings/settings_repository_test.dart` (new, 9 tests).
- `app/test/features/settings/settings_bloc_test.dart` (new, 14 tests).

## Items done (plan §b + §f logic half)

- Roster/members streams with child order (Maya→Leo) and member order
  (Sarah→James); Pip stage names `Fledgling`/`Hatchling` from seed stages.
- Zone pick/confirm/dismiss event plumbing; unknown ids ignored (no emit);
  `confirmPendingMove` stores the device zone; dismiss is bloc-local only.
- `gmtOffsetLabel` + `shortZoneLabel` reuse (no new shared helper).
- Failure path: stream error → `failure` + `Retry` (`SettingsLoadRequested`)
  resubscribes to recovery.
- Verified: `flutter analyze` on my layer → No issues found; `dart format`
  applied; `flutter test test/features/settings` → 23/23 pass; shared
  `repositories_test` settings group + `family_time_test` zone test still
  pass. No `google_fonts` anywhere. No simulator used.

## CONTRACT CHANGES

None. Event/state/entity names and shapes match `1_plan.md` exactly; the UI
builder can code against the plan. One placement note: the plan put the
GMT-offset formatter in "feature widgets", which is the UI builder's layer —
it lives in `settings_bloc.dart` as `gmtOffsetLabel` instead (pure,
tested here); feel free to re-export or relocate it when the view lands.

## LEFT FOR NEXT ITERATION

- Nothing in the logic layer. UI builder owns views/widgets, widget tests,
  copy audit and the stage-5 UI check.
- Observed (not mine, not a finding): parallel UI-builder files
  `presentation/widgets/settings_rows.dart` / `zone_picker_sheet.dart`
  exist untracked in this worktree; `settings_rows.dart:47` carries a
  `use_null_aware_elements` info — left for the UI builder.

VERDICT: PASS
