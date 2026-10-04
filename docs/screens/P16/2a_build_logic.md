# P16 Settings — 2a build, logic chunk (iteration 5)

Scope: non-UI layer only — `domain/**`, `data/**`, `presentation/bloc/**`,
`settings_di.dart`, plus unit/bloc tests. No view/widget file touched.

## CONTRACT CHANGES

None. No state/event/entity/DI shape changed this iteration.

## FIXES_4 triage (logic layer)

Every open item was audited for a logic-layer hook; none has one:

- **P16-T03** (switch wrapper clips 4 px horizontal slop): the fix
  (`SizedBox(width: 59, … Align centerRight)`) applies in
  `settings_view.dart`. The bloc only supplies toggle state — no hook. The
  owner rule (≥ 44 px target) already holds via the 51 × 44 box.
- **P16-B09** (IANA link ids): shared `family_time.dart`
  (`isKnownZoneId`), SHARED_REQUEST §5. The raw id never reaches the bloc.
- **Review 1** (un-fork `_P16Sect`/subcard/`SettingsRow`): views/build
  decision with sequencing consequences (§4 table) — orchestrator call.
- **Review 2/3** (stale "open" comments on live proofs): the comments live
  in `p16_bugs_test.dart` / `settings_responsive_test.dart`, which are not
  my files (names contain no bloc/cubit/repository/data). Untouched.
- **Review 3 (legacy `SettingsItem`/`watchItems()`/`getItems()`):
  re-verified NOT safely removable — the shared
  `test/core/data/repositories_test.dart` settings group still calls
  `repo.watchItems()`, and `settings_states_test.dart`'s fake still
  delegates both. Deleting them would break files outside my editable
  paths. Kept + documented (same conclusion as iteration 2).
- **Review 4** (B09 skip): shared — escalate §5, then un-skip.
- **Review 5** (owner e-mail literal): views/schema (`members.email`,
  SHARED_REQUEST §4). The bloc already surfaces the live name/role/invite
  row; no e-mail column exists to surface.
- **Review 6** (guard static lifetime): views/widgets layer, tracked for a
  future shared variant — no logic action.
- CLOCK re-verified: `grep DateTime.now()` over domain/data/bloc → 0 hits.

Accordingly no skipped proof in my layer needed un-skipping: T03's proof is
in `settings_a11y_test.dart` (views), B09's in `p16_bugs_test.dart`
(shared). Both stay skipped.

## Files changed

None in `app/`. Owned paths are byte-identical to the iteration-4
checkpoint.

## Verification (this iteration)

- `flutter analyze lib/features/settings` → No issues found.
- `flutter test --timeout 120s` on my files (`settings_bloc_test.dart`,
  `settings_repository_test.dart`) → 39/39 pass.
- No simulator booted, screenshotted or driven.

## LEFT FOR NEXT ITERATION

- Nothing outstanding in the logic layer. Open FIXES_4 items (T03, B09,
  review 1–6) are views/shared/test-stage-owned as triaged above.

VERDICT: PASS
