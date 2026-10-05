# Shared report — family_session (last backlog items)

## Files changed
- `app/lib/core/data/current_family.dart` (new): `CurrentFamily` holder — `fallbackId='fam1'`, `resolve` (one families row or fallback), `refresh` (first row wins, keep id when empty), `ensureFamily` (insert-or-ignore families+settings OFF).
- `app/lib/app/di.dart`: registers `CurrentFamily` (resolved from DB) before `AppSession`; passes it to `AppSession` and every repository.
- `app/lib/core/data/app_session.dart`: optional `currentFamily` param + `familyId` getter (fallback for direct test constructions).
- `app/lib/core/data/family_zone_service.dart`: defaults `Seed.familyId` → `CurrentFamily.fallbackId`; drops seed import.
- 15 repository impls + DIs (approvals, auth, badges, family, kid_home, kid_jar, kid_shop, parental_gate, paywall, pocket_money, privacy_consent, quests, rewards, settings, today): optional `currentFamily` ctor param, `_familyId` getter, all `Seed.familyId` → `_familyId`; DIs pass `sl<CurrentFamily>()`. Auth `_ensureOwner` calls `ensureFamily` so post-deletion onboarding recreates the row.
- `app/lib/features/settings/data/family_data_export.dart`: default `Seed.familyId` → `CurrentFamily.fallbackId`.
- `app/lib/features/settings/data/settings_repository_impl.dart`: `watchMembers`/`exportFamilyData` pass `_familyId` explicitly.
- `app/lib/features/parental_gate/presentation/views/parental_gate_view.dart`: backdrop `db.watchChildren` uses `CurrentFamily` from get_it (task-allowed presentation edit for Seed removal).
- `app/lib/core/design_system/components/nest_list_row.dart`: new `leading`, `titleColor`, `titleWeight` per P16 SHARED_REQUEST §6.
- `app/lib/features/settings/presentation/views/settings_view.dart`: delete/member/child rows now `NestListRow`.
- `app/lib/features/settings/presentation/widgets/settings_rows.dart`: `SettingsRow` fork deleted; chevron/hint/avatar helpers kept.
- `app/test/test_scope.dart`: refreshes `CurrentFamily` after `Seed.demo`.
- `app/test/core/data/current_family_test.dart` (new): isolation + fresh-install proofs.
- `app/test/features/kid_home/k03b_bugs_test.dart`: K03B-BUG-7 skipped proof replaced.
- `app/test/features/settings/settings_{a11y,view,final_fixes}_test.dart`: `SettingsRow` predicates → `NestListRow`; unused imports dropped.

## What / why
1. Current family: product no longer reads `Seed.familyId` (grep: zero hits in `app/lib/features`; `Seed` keeps the constant for seeding only). One family per device, same `'fam1'` value — no behaviour change. After P16 delete, `refresh` keeps the id and Auth `ensureFamily` recreates `families`+`settings` on the next onboarding write; `refresh` re-points without restart.
2. K03B-BUG-7: pending completions stay queued with no silent credit; only new completions are terminal (orchestrator decision, one-line comment in test).
3. SettingsRow: `NestListRow` covers avatar leading + danger title; fork deleted. Same padding/min-height/gaps/typography — Settings does not move (P16 diff 0.95% unchanged).
4. Kid headers: K01/K03/K04/K05 views contain no local 28/26 spacing literals (verified by grep; `gap28`/`gap26` already exist for P17 and are used there). No change needed — already compliant.

## Test names added
- `repositories never read a second family's rows` (`current_family_test.dart`): inserts `fam2`+Zoe+quest, asserts Family/Today/Quests/KidHome return only `fam1`.
- `fresh install after deletion resolves again via ensureFamily` (`current_family_test.dart`): `clearAll` → `refresh` keeps id → `ensureFamily` recreates → `addChild` lands in `fam1`.
- `K03B-BUG-7: approval OFF keeps already-pending completions in the queue` (`k03b_bugs_test.dart`): pending `q-dishwasher` stays queued with no ledger growth; new `q-reading` completion is terminal (approved+credited, never queued).

## Verification
- `cd app && dart format . && flutter analyze` → No issues found.
- `flutter test --timeout 120s` → 5324 tests, all passed.
- Shots (simulator 604697A9-11DA-462F-9837-396E9CA2493A, light, seeds per SCREENS.tsv):
  - P16 `/settings` (demo/parent): mean diff 0.95% vs expected 0.95% (Δ 0.00, within ±0.2).
  - K03 `/kid-home` (demo/kid): mean diff 2.86% vs expected 2.80% (Δ +0.06, within ±0.2).

## Follow-up screens must do
- Screen agents: nothing required. Repositories now take optional `currentFamily` — direct `Repo(db: db)` constructions keep working via fallback. If a screen constructs a repository directly with a second family in tests, pass `currentFamily:` explicitly. `SettingsRow` is gone — use `NestListRow(leading:, titleColor:, titleWeight:)`. `Seed.familyId` must not reappear in `app/lib/features` (grep must stay empty).

VERDICT: PASS
