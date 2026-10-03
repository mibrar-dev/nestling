# P15 · Child profile — Stage 2b BUILD (UI chunk, iteration 4)

Scope owned: `app/lib/features/family/presentation/views/**`,
`presentation/widgets/**`, `app/test/features/family/child_profile_view_test.dart`.
No domain/, data/, bloc/ or core/ edits this stage. No simulator, no
whole-app `flutter test` (integrator's stages).

## FIXES_3.md items closed

### P15-BUG-10 — the view no longer required a GoRouter ancestor

The P15-BUG-9 fix in iteration 3 read
`GoRouterState.of(context)` in `didChangeDependencies`, which asserts when
there is no router above the context — so `ChildProfileView` threw `GoError`
in any bare `MaterialApp` pump (widget test, preview harness, design gallery).

Fix in `ChildProfileView`:

```dart
if (GoRouter.maybeOf(context) == null) return;
final requested = GoRouterState.of(context).uri.queryParameters['childId'];
```

`GoRouter.maybeOf` returns `null` when no GoRouter is present, so the view
builds unharmed off-router. `GoRouterState.of` — the dependency that fires
`didChangeDependencies` on a live location change — only runs when a router
is present, so the P15-BUG-9 live-reselection keeps working. The first
navigation is still selection-before-load through the route's own dispatch.

The BUG-10 proof in `child_profile_view_test.dart` also wraps the bare
`MaterialApp` with `NestTheme.light()`: with the GoError gone, the pump
exercises `build`, and `context.nest` reads its `NestTokens` extension from
the theme — which is the one thing a route-less mount legitimately still
needs (a design-system theme, not a router).

No other FIXES_3.md item is in my ownership: findings 3/4/5 in 4_review
(bloc, data, `debugPrint`) are the logic builder's; the
`family_time_test.dart` red lives under `app/core/**` / `app/test/core/**`
(RULES §1 — recorded in `SHARED_REQUEST.md` §6); the selection test's stale
expectation is the test stage's (the review's corrected assertion
`4 → 2 at +1 day, 0 at +2 days` and the integration stage's re-verification
both confirm the test as it stands is correct — verified by running it:
green, no change needed).

## Gates (in `app/`)

```
$ dart format lib/features/family test/features/family
Formatted 32 files (0 changed) in 0.12 seconds.

$ flutter analyze lib/features/family test/features/family
No issues found! (ran in 3.7s)

$ flutter test --no-pub test/features/family/
00:08 +281: All tests passed!
```

The single iteration-3 red proof (BUG P15-BUG-10) is now green, with the
repro kept as the proof: route-less mount shows the screen's Maya without
exception and without needing any router ancestor.

## LEFT FOR NEXT ITERATION

* Stage 5 re-shoot (light + dark) — expect identical band geometry
  (hero 47/164, stats 227/82, Pip 325/116, list 457/180, danger 653/80); the
  change surface here was router-less mount robustness only, no visual delta.
* `child_profile_row.dart` stays until `SHARED_REQUEST.md` §1 lands on `main`;
  delete it and return to `NestListRow` (plus §2b's `leadingWidget` for the
  coin).
* Open shared asks: §1 row flex, §2b `leadingWidget`, §3 `NestPip.rowSlot = 84`,
  §5 roster-order query, §6 the blocking core test fix.

VERDICT: PASS