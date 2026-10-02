# router_push_test_fix — path-based shared push/pop tests

Fixes the one shared test that asserted placeholder view titles. `test/app/router_push_test.dart`
(added in shared batch 1) asserted `find.text('P02 Value tour')` and friends; those strings exist
only on the foundation's placeholder views, so the test broke on every screen branch that
replaced its placeholder — P02 first (`docs/screens/P02/2_build.md`, SHARED_REQUEST item 4,
`00:11 +609 -1`).

## Files changed

| File | Change |
|---|---|
| `app/test/app/router_push_test.dart` | Rewritten: every `find.text(<placeholder title>)` assertion replaced by a router-location assertion. `expectPushPop(tester, from, to)` lost its `showsFrom`/`showsTo` text parameters and asserts locations only. All 4 original scenarios kept verbatim by name; 3 added. |
| `app/test/test_scope.dart` | Added `pushedPath(tester)` next to `currentPath(tester)` (additive only — `currentPath` semantics untouched, so no shared/feature test can change behaviour). |
| `docs/screens/_shared/router_push_test_fix_REPORT.md` | This report. |

Nothing under `app/lib/**` was touched; no screen code, no lint, no `analysis_options.yaml`.

## What and why

**Why the old assertions were fatal.** Screen agents replace placeholder views with real screens.
The only stable, shared contract for "which screen is showing" is the route path, so the shared
tests assert paths.

**Why one helper was not enough.** `currentPath` reads
`routerDelegate.currentConfiguration.uri`, and go_router 18's `RouteMatchList.uri` *deliberately
excludes `ImperativeRouteMatch`s* (`match.dart`: "This uri only reflects [RouteMatch]s that are
not [ImperativeRouteMatch]"). So after `context.push(...)`, `currentPath` still reports the
declarative location it pushed from — the original file's own header note. `GoRouter.state` is
built from the full match list and is what the `Navigator` actually renders, so the pushed state is
asserted with `pushedPath` (`GoRouter.of(context).state.uri.path`). The quirk is documented once,
on the helper, so the next agent does not re-derive it.

**Per scenario the contract now asserted** (unchanged navigation, changed evidence):

1. `pumpAppRoute(from)` → `currentPath == from` (the screen mounted at its own path).
2. `push(to)` → `pushedPath == to` (the pushed route is on top and rendered).
3. `pop()` → `pushedPath == from` **and** `currentPath == from` (pop returns to the previous path;
   both accessors agree once nothing is pushed).

No `find.text`, no view content, no keys tied to placeholder markup — screen-independent by
construction.

## Tests added (`test/app/router_push_test.dart`, group `push/pop contract`)

Kept unchanged (4): `push P09 quest editor from /today, pop returns` ·
`push P11 approvals from /today, pop returns` · `push /value-tour from /welcome, pop returns` ·
`push between top-level onboarding routes, pop returns`.

Added (3):

- `push from a shell-branch route to a sibling branch` — `/today` → `/quests`: push between two
  `StatefulShellRoute.indexedStack` branches, the case a screen agent is most likely to break with
  a `goBranch`-style tab bar.
- `nested pushes pop back one level at a time` — `/today` → push `/quest-editor` → push
  `/approvals`, then two pops unwind one level each and land back on `/today`. Pins the "P08 reaches
  P09/P11 with `push`, they must `pop()`" contract stated in the file header.
- `the two location helpers agree when nothing is pushed` — pins the helper invariant
  (`pushedPath == currentPath` at rest), so a future go_router bump that changes push bookkeeping
  fails here with a clear message instead of as a mystery in a scenario.

## Verification

In this worktree (`app/`):

- `dart format .` → `Formatted 357 files (0 changed)` (final pass clean).
- `flutter analyze` → `No issues found!` (ran 3.8s). No new `// ignore:`; the two
  `unawaited_futures` ignores each carry a documented reason (`document_ignores` satisfied).
- `flutter test` (full) → `00:26 +530: All tests passed!` (was 527 tests, all passing; +3 added,
  0 removed).

Grep sweep for the same fragility elsewhere (`find.text('P0…')` / `find.text('K0…')` /
`showsTo:` / `showsFrom:` outside `test/features/**`): **only `router_push_test.dart` matched**,
and it is now clean. The remaining shared `find.text` assertions are on dev-only surfaces no screen
agent owns — `test/motion_lab_test.dart`, `test/pip_lab_test.dart`, `test/widget_test.dart`
(design-system gallery) — plus one *negative* assertion in `routes_smoke_test.dart`
(`find.text('Something went wrong')` must be absent), which a real screen cannot satisfy.
`test/app/router_redirect_test.dart` was already purely path-based. Feature tests under
`test/features/**` are out of scope (screen agents own them) and were left untouched.

### Cross-branch proof on the P02 branch

P02's worktree was **not** touched (it had uncommitted work in progress). Instead `screen/P02` was
exported read-only with `git archive` into a scratch dir
(`/private/var/folders/…/T/opencode/p02_verify`, since deleted), `flutter pub get --offline`, then:

| Run | Result |
|---|---|
| P02 HEAD + the **old** committed `router_push_test.dart` | `+3 -1: Some tests failed` — `push /value-tour from /welcome, pop returns`, `Expected: true Actual: <false>` at the `find.text('P02 Value tour')` line. Same failure as `docs/screens/P02/2_build.md`. |
| P02 HEAD + this branch's new `router_push_test.dart` | `00:03 +7: All tests passed!` |
| P02 HEAD full suite + new file | `00:17 +613: All tests passed!` (P02 branch alone: 609 pass + 1 fail) |

Merge safety for the same reason: `screen/P02`'s copies of both changed files are byte-identical to
this branch's pre-change copies, so the `test_scope.dart` append and the `router_push_test.dart`
whole-file replacement apply without conflict on any screen branch that has not touched them.

## What follow-up screens must do

1. **Nothing.** Replaces the placeholder with the real screen and the shared tests still pass.
2. Do not change route paths or `GoRouter` wiring to satisfy a shared test — paths are the contract
   now. If a screen genuinely needs a new route, that is a shared change
   (`docs/screens/RULES.md` §2, `SHARED_REQUEST.md`), and `docs/ARCHITECTURE.md` §Route table plus
   `test/app/routes_smoke_test.dart` must be updated in the same batch.
3. Screen that is *pushed* to (P09, P11, …) must return with `context.pop()`, not `go()` — pinned
   by `nested pushes pop back one level at a time`.
4. If a shared test ever needs a widget on screen, assert a `ValueKey` on shared chrome, or assert a
   path. Never a placeholder view title.
5. `pushedPath` is exported from `app/test/test_scope.dart` and may be used by feature tests that
   assert a location after a `push` (several `test/features/today/**` tests still read
   `find.text('P09 Quest editor')` to get at a pushed route — they are feature-owned and out of
   scope here, but the same cleanup applies when their screens land).

## Follow-ups for the orchestrator

- `docs/screens/P02/SHARED_REQUEST.md` item 4 (the `showsTo: 'P02 Value tour'` one-line fix) can be
  closed by this branch: the placeholder literal is gone from shared tests entirely.
- Other screen branches reporting shared-test failures on placeholder literals (`P09`, `P11`,
  `P03`, …) should get the same all-clear once this branch merges.
- Optional, not blocking: `test/features/today/{today_view_test,p08_bugs_test}.dart` still locate
  pushed screens via `find.text('P09 Quest editor')` / `find.text('P11 Approvals')`. Those files
  belong to P08 and K-family screen agents; they are equally fragile and would be fixed by the same
  swap to `pushedPath`/`currentPath`. P02 already follows this pattern for its own screen.

VERDICT: PASS