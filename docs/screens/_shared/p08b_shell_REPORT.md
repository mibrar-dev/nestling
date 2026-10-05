# P08b support — Today-empty inside the Today tab shell + `new_family` seed

Branch: `shared/p08b_shell` (from main). Shared-only change; no feature
`presentation/**` code touched.

## Files changed

- `app/lib/app/router.dart` — moved `todayEmptyRoute` out of the top-level
  route list into the Today `StatefulShellBranch` (`[todayRoute,
  todayEmptyRoute]`), so `/today-empty` renders inside `ParentShell` with
  the tab bar and Today active, exactly like `/today`. Path, name and the
  parent-only redirect entry unchanged (no redirect logic edited).
- `app/lib/core/data/seed.dart` — added `Seed.newFamily(db)`: family +
  parent Sarah (same row as `empty`) + both children via `_childrenDemo`
  (Maya then Leo, creation order) + `_settingsDemo`; NO quests,
  completions, ledger, goals, rewards, badges or wardrobe;
  `onboarding_complete = true`, subscription `trial` with
  `trialStart = clock.now()` (same as `empty`), appMode parent. Header
  comment updated (Four → Five variants, `empty` marked legacy for P08b).
- `app/lib/app/launch.dart` — launch seed switch handles `SEED=new_family`
  (`case 'new_family': await Seed.newFamily(db)`); header comment updated.
- `app/lib/app/launch_flags.dart` — header comment updated;
  `isSupportedSeed` accepts `new_family`.
- `docs/screens/SCREENS.tsv` — P08b seed column `empty` → `new_family`.
- `app/test/app/today_empty_shell_test.dart` (new) — tab-shell router tests
  (route assertions + `NestTabBar.currentIndex` only, no view copy).
- `app/test/core/data/seed_test.dart` — new `Seed.newFamily` group.
- `app/test/app/launch_flags_test.dart` — supported-seed test now includes
  `new_family`.

## What / why

P08b (Today empty) is a parent-tab screen: the tab bar must stay visible
with Today selected. Previously `/today-empty` was a top-level route, so
it rendered without the shell. The P08b screen agent shoots
`/today-empty` with the `new_family` seed — a family fresh out of
onboarding (children exist, but nothing earned yet) — so the empty-state
card renders against realistic roster data instead of a childless family.

## Tests added

- `today-empty tab shell /today-empty shows the tab bar with Today selected`
  (`currentPath == '/today-empty'`, `NestTabBar.currentIndex == 0`).
- `today-empty tab shell /today still shows the tab bar with Today selected`
  (regression guard, same assertions for `/today`).
- `Seed.newFamily Maya then Leo exactly as demo, onboarding complete`
  (both children field-for-field as demo, roster order `['maya','leo']`,
  Sarah present, `onboardingComplete`, `trial`, parent mode).
- `Seed.newFamily no quests, ledger, goals, rewards, badges or wardrobe`
  (all eight tables empty).
- Extended `LaunchFlags.isSupportedSeed supports … new_family …`.

## Verification

- `cd app && dart format .` — clean (7 files formatted, 1 changed).
- `flutter analyze` — `No issues found!` (no new ignores).
- Targeted: `today_empty_shell_test`, `seed_test`, `launch_flags_test`,
  `router_redirect_test` — all passed.
- Full suite `flutter test --timeout 120s` — `All tests passed!`
  (+4387, ~12 skipped), exit 0.

## Follow-up for screens

- P08b screen agent: shoot `/today-empty` with `SEED=new_family`
  (per updated `SCREENS.tsv`); the tab bar is now part of the frame, so
  keep the 84 px bar + 24 px home reserve in layout comparisons.
- Other screens: no action. `Seed.empty()` is untouched and still
  supported; only the P08b manifest row moved to `new_family`.

VERDICT: PASS
