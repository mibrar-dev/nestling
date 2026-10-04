# 2 BUILD (INTEGRATE) — K02 Kid PIN (`kid_home`, iteration 1)

Merge of the two halves built in parallel. This stage changed no design, no
copy, no geometry — only what the merge of 2a + 2b broke.

## Summary of 2a (logic)

`app/lib/features/kid_home/presentation/bloc/`:

- `kid_home_event.dart`: `KidHomePinSubmitted({childId, pin})`.
- `kid_home_state.dart`: `pinChecking=false`, `pinWrongNonce=0`,
  `pinPassed=false` threaded through every constructor; `copyWithLoaded`
  preserves checking/nonce and resets `pinPassed` (one-shot, mirrors
  `justCompletedQuestId`).
- `kid_home_bloc.dart`: `_onPinSubmitted` — re-entry guard while
  `pinChecking`, `await repo.verifyPin`, outcome built from the state at
  completion time, repository throw reads as the wrong path.
- Tests: 9 bloc tests (`K02 PIN` group) + DB-backed `K02 PIN verification`
  repository tests. No DI/route/schema/seed change.

## Summary of 2b (UI)

`app/lib/features/kid_home/presentation/views/kid_pin_view.dart`: `KidScope` →
transparent `Scaffold` → status bar + top bar (back `NestIconButton`
`Back`, `NestLockButton` `Grown-ups`) + `ListView` body (128 lilac avatar
disc, `NESTLING` mark pill ls 1.28, `Hi {nickname}! Enter your secret
code`, `NestPinDots`, `NestKeypad(kid: true)`, `Forgot it? Just ask a
grown-up.`, transparent home-indicator reserve so the shared meadow runs
to the physical edge). Local `_entered`/`_awaiting` entry state, 4th digit
dispatches, `BlocListener`s for pass (`go(home)`) / wrong (clear + toast),
no-PIN child auto-advance, `_KidLoading` / `_KidFailure` / `_NoActiveChild`
per plan §(d). 22 widget tests in `kid_pin_view_test.dart`.

## FIXES

### Done

1. **Analyzer nits in `kid_home_bloc_test.dart` (2b's handover item).**
   `flutter analyze` printed 5 `info` issues: `omit_local_variable_types` ×2
   and `no_leading_underscores_for_local_identifiers` ×3 on the K02
   matchers. Renamed `_checking`/`_passed`/`_wrong` → `checking`/`passed`/
   `wrong` and dropped the two redundant `Matcher` annotations
   (`kid_home_bloc_test.dart:1260,1268,1276` + their 11 use sites). No
   behaviour change — same predicates, same expectations.
2. **Two K01 tests broke on the real K02 view (`k01_bugs_test.dart`).**
   `K01-BUG-3 regression: the same tile navigates again` and
   `rapid same-tile double tap pushes exactly one route` used
   `tester.pageBack()`, which resolves only `find.byTooltip('Back')` or
   `CupertinoNavigationBarBackButton` — i.e. the Material `AppBar` back
   button of the old placeholder `KidPinView`. K02's real top bar is the
   design-system `NestIconButton`, whose accessible name is a `Semantics`
   label, not a `Tooltip` (`nest_icon_button.dart` has no tooltip, and
   `core/design_system/**` is off-limits per RULES §1). Smallest fix that
   keeps each proof's intent: tap the real control the way the rest of the
   file already does (`find.bySemanticsLabel('Grown-ups')` at line 701) —
   `await tester.tap(find.bySemanticsLabel('Back'))`.
3. **`rapid same-tile double tap` also needed the harness drain.** Without
   it the pushed `/kid-pin` route was still on its loading UI (no back
   control — by design: K02's `_KidLoading` is byte-for-byte K03's pattern,
   status bar + lock + spinner). Added the sibling test's documented
   `tester.runAsync` drain of the real Drift `setActiveChild` write, an
   explicit `expect(pushedPath, '/kid-pin')` (this is now what proves
   "exactly one route" — the original `pageBack()`+picker assertion could
   not distinguish no-push from one-push), then the back tap and the
   unchanged `'/who-is-playing'` landing.

No imports, renames, BLoC states/events or contract mismatches were found
between the halves: 2b coded against exactly the names 2a shipped, and the
whole `kid_home` feature suite (K01 + K02 + repo + bloc + shared state
consumers) passes together.

### Left / for the next iteration

- **`NestKeypad` fit opt-in (ORCHESTRATOR_NOTES 07:13, mandatory).** The
  shared `shared/keypad_grid` fix (main `b1bfb4e`, "10px gaps, 8-24-0
  padding, 1fr columns + shrinkWrap fit for K02") has **not** reached this
  worktree: `screen/K02` was last merged from main at `e01420a`, before
  `9cac0c6`/`7d37756`. This tree's `nest_keypad.dart` still has the old
  24px column / 16px row gaps and no `NestKeypadFit`, so the K02 call site
  stays `NestKeypad(onKey:, onDelete:, kid: true)` and carries the
  `NOTE(K02)` TODO. Once the loop merges main, the UI stage must (a) pass
  `fit: NestKeypadFit.shrinkWrap` at the K02 call site (the shared doc
  comment names K02 as the shrink-wrap consumer) and (b) re-measure the key
  centres against the design (77/195/277 px x, rows 393/475/557/639).
  Not written here on purpose: the enum does not exist in this worktree, so
  the call would not compile and this stage's gate is analyze-clean.
  `kid_pin_view_test.dart` pins no keypad y/pitch values, so the merge
  cannot break it — verified.
- `SHARED_REQUEST #1` (`NestType.kidSay`, `NestType.kidMark`) still
  TODOed at the call sites with metric-matched local styles; unchanged by
  this stage.

## Rule spot-checks on the merged result

- PIP: K02's failure card shows `PipAvatar(style: mochi, stage: 1)` —
  correct, because the bloc only enters `failure` when `state.child == null`
  (`kid_home_bloc.dart:225`), so the child's own Pip is unknowable there;
  identical to K03's fallback branch. K02 has no `pip_stage_*.svg` usage.
- Bottom edge: no bar on K02; the trailing `SizedBox(viewPadding.bottom)`
  paints nothing, so the shared meadow reaches the physical edge.
- Alignment/gutters: 20 px everywhere, avatar/dots/keypad centred on x 195.
- Copy: ASCII exactly as the HTML source — `Hi Maya! Enter your secret
  code`, `NESTLING`, `Forgot it? Just ask a grown-up.`,
  `That didn't work. Try again.`
- No `GoogleFonts`, no `DateTime.now()`, no `subscription_status` write,
  no hard-coded colours/sizes in the merged files.
- Scope: only `app/lib/features/kid_home/**`, `app/test/features/kid_home/**`
  and `docs/screens/K02/**` touched.

## Gates

`cd app && dart format .`

```
Formatted 522 files (0 changed) in 2.15 seconds.
```

`cd app && flutter analyze`

```
Analyzing app...
No issues found! (ran in 10.9s)
```

`cd app && flutter test`

```
01:41 +2916 ~2 -2: .../test/features/onboarding/value_tour_view_test.dart: P02 value tour — owner rule: alignment dark 430dp: 20px gutters on every edge
01:41 +2917 ~2 -2: ... P02 value tour — owner rule: alignment card content shares one inner left edge
01:41 +2918 ~2 -2: Some tests failed.
Failing tests:
  .../test/features/kid_home/k01_bugs_test.dart: K01-BUG-3 regression: the same tile navigates again
  .../test/features/kid_home/k01_bugs_test.dart: edge-case probes rapid same-tile double tap pushes exactly one route
```

(after FIXES 1–3)

```
01:45 +2914 ~2: .../test/pip_avatar_test.dart: PipAvatar falls back to the static SVG under reduced motion
01:46 +2920 ~2: All tests passed!
```

2920 pass, 2 skipped (pre-existing skips), 0 failures.

VERDICT: PASS