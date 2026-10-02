ORCHESTRATOR REVIEW of shared/family_time_zone (eed280d): tests are excellent (550 pass, DST + Dubai move + migration). ONE blocker before merge:
`flutter analyze` reports 2 infos (deprecated_member_use: toLondon, formatLondonDay). Every screen branch still calls london_time.dart; each screen loop's build gate requires "No issues found!", so @Deprecated would break ALL in-flight screens on merge.
Do:
1. Remove every `@Deprecated(...)` annotation in app/lib/core/data/london_time.dart. Keep the shims, add a top-of-file doc comment: "Legacy London-only helpers kept for in-flight screens; new code uses family_time.dart. Will be removed after all screens migrate." 
2. Migrate the call sites on THIS branch (app/lib/core/**, app/lib/app/**, and the feature data repositories you already touched) to family_time.dart so main itself uses the new helpers.
3. `dart format .`, `flutter analyze` → "No issues found!", `flutter test` all pass. Also commit docs/research/DATETIME_STORAGE.md is now on main (merge main into your branch first: `git merge main`), re-check your implementation against its §2 table and note any differences in the report.
4. Rewrite docs/screens/_shared/family_time_zone_REPORT.md with an item-by-item DONE/NOT DONE list for the brief (docs/screens/_shared/family_time_zone.md), then commit.
