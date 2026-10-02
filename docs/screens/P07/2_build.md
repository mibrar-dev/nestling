# P07 Paywall — build report (Stage 2, iteration 1)

## Files changed

None. No tracked file was modified and no new file was created in this
iteration (`git status --porcelain` shows only the loop's own untracked
`.brief_build*` / `.start_build` marker files). In particular these were
left untouched:

- `app/lib/features/paywall/presentation/views/paywall_view.dart` — still the
  placeholder scaffold (`P07 Paywall` app bar + raw `ListTile` list).
- `app/lib/features/paywall/presentation/bloc/paywall_{event,state,bloc}.dart`
  — still load-only (`PaywallLoadRequested`, no `PaywallTrialStarted` /
  `PaywallRestoreRequested`, no `action` state).
- `app/lib/features/paywall/presentation/widgets/paywall_placeholder_card.dart`
  — still present.
- `app/test/features/paywall/**` — still does not exist.
- `docs/screens/P07/SHARED_REQUEST.md` — not filed (nothing to request yet).

## Fix items (per docs/screens/P07/1_plan.md §a–g)

Iteration 1 is the first build, so there are no prior-stage fix items to
close; the plan items themselves are the work, and none was implemented:

1. Widget tree (nav / hero / title / benefits / plan / timeline / family
   note / `NestBottomCta` + legal row) — NOT BUILT. Only investigation
   reads were done (plan, HTML source, SPACING_SPEC, design-system tokens,
   `welcome_view.dart` hero-scale precedent, `PipAvatar` API,
   `AppSession`, routes, `test_scope.dart`).
2. BLoC action events + `PaywallAction` state + repository wiring — NOT BUILT.
3. Navigation (close → `/pocket-money-setup`, trial/restore → session
   writes → `/today`, Terms/Privacy toast placeholders) — NOT WIRED.
4. Empty / loading / error states — NOT BUILT.
5. Accessibility contract — NOT BUILT.
6. Feature tests (`paywall_bloc_test.dart`, `paywall_view_test.dart`) —
   NOT WRITTEN.
7. `SHARED_REQUEST.md` — nothing filed.

Two findings from investigation are recorded here so iteration 2 does not
re-derive them:

- `AppSession` is registered in GetIt (`app/lib/app/di.dart`) but is NOT
  provided as an ancestor `Provider` in `app/lib/app/app.dart`, so the
  plan's `context.read<AppSession>()` would throw at runtime. Iteration 2
  must use `GetIt.instance<AppSession>()` (read-only) in the
  `BlocListener` success path and document the deviation.
- Trial vs restore need different session writes (`startTrialNow()` must NOT
  run on the restore path — it would regress an `active` subscription), so
  the `success` state must carry which request succeeded (e.g. a
  `PaywallRequest{trial, restore}` field alongside the plan's
  `PaywallAction{idle, working, success, failure}`).

## Analyze / test tails

`dart format .`, `flutter analyze`, and `flutter test` were NOT run in this
iteration — there was no code change to format, analyze, or test, so there
are no tails to paste. The placeholder view, load-only bloc, and missing
feature tests from the foundation remain exactly as found.

## Verdict basis

Stage 2 requires: placeholder replaced, BLoC + navigation wired, light +
dark with no overflow at 320 dp / text scale 1.3, `flutter analyze` printing
`No issues found!`, and `flutter test` all passing. None of these holds —
no implementation exists to verify. The next iteration must implement
1_plan.md §§a–g in full, then format/analyze/test.

VERDICT: FAIL
