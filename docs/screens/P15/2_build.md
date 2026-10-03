# P15 · Child profile — Stage 2 INTEGRATE (iteration 1)

Route `/child-profile` · parent mode · feature `family` · parent light+dark designs.
Inputs re-read: `docs/screens/RULES.md`, `docs/ARCHITECTURE.md`,
`docs/DESIGN_SPEC.md` §5 P15, `docs/design/SPACING_SPEC.md`,
`1_plan.md`, `2a_build_logic.md`, `2b_build_ui.md`.
No `ORCHESTRATOR_NOTES.md` exists (checked) — only the global orchestrator rules
apply. No simulator was booted, installed on or screenshotted (stage 2 must not).

## Summary of 2a (logic) + 2b (UI)

The two builders worked in parallel and the merge needed **no code-level
reconciliation**: `2a` shipped **CONTRACT CHANGES: None**, and `2b` coded
against exactly those public names. Every symbol the UI layer consumes
(`ChildProfile`, `FamilyState.profile`, `FamilyRemoveChildRequested(childId)`,
`FamilyRepository.watchProfile()`) exists with the planned shape, so there was
no mismatched BLoC state, no renamed member and no import to rewire.

**2a — logic** (`domain/**`, `data/**`, `presentation/bloc/**`):

- new `ChildProfile` entity (`child`, `questsThisWeek`,
  `dailyActive`/`weeklyActive`/`onceActive`, `owedPence`);
  `FamilyRepository.watchProfile()`; `FamilyState.profile`;
  `FamilyRemoveChildRequested`.
- `watchProfile()` selection = `activeChildId` ?? first child in creation order
  ?? null. It deliberately uses a feature-local `StreamController` with
  **switch** semantics instead of the plan's `asyncExpand`, because
  `asyncExpand` has concat semantics and would never re-select after a
  removal on Drift's never-closing `watch()` streams. The four base streams
  still combine via the shared `combineLatest4`; no core file touched.
- `questsThisWeek` counts only completions whose quest
  `countsForCurrentPeriod(...)` is true (PERIODS ruling) — demo Maya = 4, not
  the design's mocked 18. `owedPence` replicates
  `PocketMoneyRepositoryImpl.summarise` as a private static, cited in a
  comment; no cross-feature import.
- `add_children_test.dart` / `p05_bugs_test.dart` mock setups got the
  `watchProfile` stub (mocktail returns null for unstubbed methods).
- 14 bloc tests added.

**2b — UI** (`presentation/views/**`, `presentation/widgets/**`):

- `child_profile_view.dart` (status switch + `NestToast` listener),
  `child_profile_body.dart` (the scrolled body + remove-confirm modal),
  `child_profile_copy.dart` (all P15 strings from the HTML source's
  characters), `child_profile_view_test.dart` (12 widget tests).
- 12 view tests added; the P15 placeholder scaffold is gone.

Integration state: **already coherent.** The only breakage was in a test file,
not in the app.

## FIXES

| # | Item | Where | Done |
|---|---|---|---|
| 1 | `add_children_test.dart` — 3 tests asserted the removed placeholder title `'P15 Child profile'` | handed over by 2a, claimed done by 2b (lines 652/655/1299/1638 → `find.byKey(const Key('p15-hero'))`) | already done by 2b, re-verified green |
| 2 | `today_view_test.dart` "P08 Today navigation kid card opens the child profile with its childId" asserted the same removed placeholder at line 541 — **missed by 2b** (it only grepped the family dir) | `app/test/features/today/today_view_test.dart:541-543` | **done** |
| 3 | Contract reconciliation (state/event/member names) | — | none needed |
| 4 | Imports / merged-half compile errors | — | none |

Fix 2 in full — the smallest possible change, byte-identical to the precedent
2b already established in the family tests, with no assertion, expectation or
test name changed:

```diff
-      expect(find.text('P15 Child profile'), findsOneWidget);
-      final uri = _currentUri(tester, find.text('P15 Child profile'));
+      // P15 is a real screen now, so anchor on its hero card instead of the
+      // old placeholder title (same anchor add_children_test.dart uses).
+      expect(find.byKey(const Key('p15-hero')), findsOneWidget);
+      final uri = _currentUri(tester, find.byKey(const Key('p15-hero')));
       expect(uri.path, '/child-profile');
       expect(uri.queryParameters['childId'], 'maya');
```

The `childId == 'maya'` and `path == '/child-profile'` assertions — the actual
subject of that test — are untouched and still pass, and the tap-driven
navigation from Today is unaffected.

**Scope note for the orchestrator.** `test/features/today/**` is outside this
screen's RULES §1 editable set, but the failing assertion was a direct casualty
of the P15 placeholder removal in this very merge, and the stage brief makes
fixing merge-caused test failures the integrator's job. The edit is confined to
an anchor finder; no `today` production code or `today` behaviour is touched.
`grep -rn "P15 Child profile" lib test` now returns nothing, so no further
placeholder anchors survive anywhere in the app or its tests.

## Verification (run in `app/`)

```
$ dart format .
Formatted 488 files (0 changed) in 1.28 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.4s)

$ flutter test
00:48 +2423 ~1: All tests passed!

$ flutter test test/features/family
00:05 +161: All tests passed!
```

Full suite: **2423 pass, 1 skipped (pre-existing), 0 failed.** Family feature:
161 pass. No test was skipped, deleted or weakened to get here; no
`analysis_options.yaml` change; no `google_fonts` import anywhere.

## Left for the next stage

1. **UI-stage comparison (5_ui)** — `shot.sh` `/child-profile` light + dark on
   udid `E7D5555E-378A-49DF-AAEE-16677AF4B9DB`, then `compare.py` against
   `design/screens/{light,dark}/P15-child-profile.png`. Expected bands from 2b:
   hero 47–211, stats 227–309, Pip card 325–441, list of 3 457–637, danger
   653–733. Watch the danger card: the design frame clips it at 727. Per the UI
   VERDICT RULE, report measured y for the title, first control and each card
   top, design vs app.
2. **Owner-rule UI passes in both themes** — bottom edge under the tab bar
   (`NestTabBar` is shared code, so a strip there is a SHARED_REQUEST, not a
   fix here), 20 px gutters on every edge, DATA OVER MOCKS numbers
   (`4` / `120` / `4` happy days / `6 active · 4 daily, 2 weekly` / £4.20),
   Pip = the child's own `PipAvatar` (Maya mochi·sunny·stage 3 at 84 px,
   Leo bolt·sky·stage 2) with no `pip_stage_*.svg`.
3. Nothing else is outstanding from 2a or 2b. `SHARED_REQUEST.md` is not
   needed for this iteration.

VERDICT: PASS
