# Shared fix — p08b_shell (P08b tab shell + `new_family` seed)

The previous run made all code edits; this run verified the diff against the
task items, ran format/analyze/full tests in the foreground, and fixed
nothing because there were no gaps.

Note: `docs/screens/_shared/task_p08b_shell.md` (the original task file)
does not exist on this branch or anywhere in git history, so items 1–3 were
reconstructed from the branch diff (committed as `bcd2cb0` during this
session by the loop). The diff is self-consistent and maps
to exactly three items: (1) `Seed.newFamily`, (2) launch-flag plumbing,
(3) `/today-empty` tab-shell routing + `SCREENS.tsv` + shell test.

## Files changed

- `app/lib/core/data/seed.dart` — added `Seed.newFamily(db)`: family + parent
  Sarah (same row as `empty`) + both children exactly as in `demo` (Maya 7-9
  lilac mochi/sunny stage 3, Leo 4-6 peach bolt/sky stage 2, Maya created
  first = roster order) + default settings; NO quests/completions/ledger/
  goals/rewards/badges/wardrobe; `onboarding_complete = true`, `trial`
  subscription starting now, parent app mode. Header comment updated
  (four → five variants; `empty` marked legacy).
- `app/lib/app/launch_flags.dart` — `isSupportedSeed` accepts `new_family`;
  doc comment updated.
- `app/lib/app/launch.dart` — `applyLaunchFlags` switch handles
  `SEED=new_family` via `Seed.newFamily(db)`; doc comment updated.
- `app/lib/app/router.dart` — `todayEmptyRoute` moved into the Today
  `StatefulShellBranch` (`[todayRoute, todayEmptyRoute]`) and removed from
  the top-level list, so `/today-empty` renders inside `ParentShell` with
  the tab bar and Today selected (index 0), exactly like `/today`.
- `app/test/core/data/seed_test.dart` — new `Seed.newFamily` group
  (2 tests, see below).
- `app/test/app/launch_flags_test.dart` — existing support test extended
  to `new_family` (renamed `supports demo, empty, fresh, new_family and
  onboarding_kids`).
- `app/test/app/today_empty_shell_test.dart` — NEW: tab-shell contract
  (2 widget tests, route assertions only, no view copy).
- `docs/screens/SCREENS.tsv` — P08b row seed `empty` → `new_family`
  (tabs preserved).

Not committed (left untracked): `docs/screens/_shared/.brief_p08b_shell.md`
— orchestrator scaffolding holding this task's prompt text, not part of the
change; no `.brief*` file under `docs/screens/_shared/` is tracked.

## What / why

P08b (Today empty) is the first-run home screen for a family that just
finished onboarding: children exist (so the roster/Pip slots render) but no
quests exist yet. `Seed.empty` (no children) was the wrong state, so this
change adds the dedicated `new_family` seed, wires it through the launch
flags, points the P08b screenshot/loop row at it, and puts `/today-empty`
under the Today tab so the shell contract holds.

## Tests

New/updated (targeted run `seed_test + launch_flags_test +
today_empty_shell_test`: 21 passed):

- `Seed.newFamily Maya then Leo exactly as demo, onboarding complete`
- `Seed.newFamily no quests, ledger, goals, rewards, badges or wardrobe`
- `LaunchFlags.isSupportedSeed supports demo, empty, fresh, new_family
  and onboarding_kids` (updated)
- `today-empty tab shell /today-empty shows the tab bar with Today
  selected` (asserts `currentPath == '/today-empty'` + `NestTabBar`
  index 0; never asserts view copy)
- `today-empty tab shell /today still shows the tab bar with Today
  selected` (regression guard for `/today`)

Full suite (foreground `flutter test --timeout 120s`): 4387 passed,
12 skipped, 0 failed — `All tests passed!`.
`dart format .`: 0 changed. `flutter analyze`: `No issues found!`
(no new ignores). This run fixed no failures — none were caused by
the change.

## Follow-up for screens (esp. P08b screen agent)

- Shoot/loop P08b with `SEED=new_family` + `INITIAL_ROUTE=/today-empty`
  (already in `SCREENS.tsv`); do not use `empty`.
- `/today-empty` is in the Today tab branch (index 0) — keep its view
  inside the shell; do not re-add it as a top-level route.
- `Seed.empty` is kept for backward compatibility; nothing else reads
  `new_family` yet, so no migration needed.

VERDICT: PASS
