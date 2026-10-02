# P07 Paywall — QA code review (Stage 4, iteration 1)

Scope reviewed: `git diff main...HEAD` (docs/screens/P07/plan files only), the
current state of `app/lib/features/paywall/**`, the new tests in
`app/test/features/paywall/**`, and the stage reports `1_plan.md`,
`2_build.md`, `3_test.md`, plus mandatory `ORCHESTRATOR_NOTES.md`.

**Headline: the screen was not built in this iteration.** Stage 2 returned
`VERDICT: FAIL` with no implementation; Stage 3 added a 63-test suite of which
43 fail. There is effectively no P07 code to approve.

## Findings

1. **Blocker — P07 paywall screen is not implemented.**
   `app/lib/features/paywall/presentation/views/paywall_view.dart:9-42` is still
   the foundation placeholder (`AppBar('P07 Paywall')` at :12,
   `Text('No items yet')` at :25, `ListTile` list at :31). `git diff main...HEAD`
   contains zero changes under `app/lib/`. None of the required surface exists:
   `NestStatusBar`, hero Pip, title "Try Nestling free for 14 days", 4 benefit
   rows, plan card, trial timeline, family note, `NestBottomCta`, "Start free
   trial" CTA + caption, Restore/Terms/Privacy row, close X.
   *Fix:* implement `docs/screens/P07/1_plan.md` §§a–g in full; rerun
   `flutter test test/features/paywall/` as proof.

2. **Blocker — P07 is a dead end; ORCHESTRATOR_NOTES item 1 is violated.**
   `presentation/bloc/paywall_event.dart:10` has only `PaywallLoadRequested`;
   `paywall_bloc.dart:9` has only `_onLoadRequested`; `paywall_state.dart:4,13`
   has no `action` field. There is no trial or restore path, so
   `AppSession.startTrialNow()` / `AppSession.completeOnboarding()` are never
   called and the user cannot reach `/today` — onboarding cannot complete.
   *Fix:* add `PaywallTrialStarted` / `PaywallRestoreRequested` events, an
   action state discriminating trial vs restore (trial must NOT downgrade an
   `active` subscription; restore must NOT call `startTrialNow()`), wire
   `GetIt.instance<AppSession>()`, then navigate to `/today`.

3. **Blocker — feature test suite is red (43 of 63 failing).**
   `app/test/features/paywall/paywall_view_test.dart`: 42 widget tests fail
   against the placeholder view; `paywall_bloc_test.dart`: 1 fails. Per the
   stage brief the *tests themselves* are not patched — they are the contract
   for the build. *Fix:* satisfy them in the build stage; do not weaken them.

4. **Major — plan caption copy drops "the" (COPY rule, HTML wins).**
   `app/lib/features/paywall/data/paywall_repository_impl.dart:52-54` renders
   `£29.99/year after 14-day trial.` The HTML source
   `design/html-source/screens/P07-paywall.html:105` is
   `£29.99/year after the 14-day trial.` (`docs/DESIGN_SPEC.md:158` paraphrases
   without "the" — HTML source wins; do not "fix" the test). *Fix:* insert
   `the ` in the repository string.

5. **Major — plan card's design tag has no data source.**
   `paywall_repository_impl.dart:49-56` concatenates sub + caption into `detail`
   and drops the tag `One price, the whole family`
   (`P07-paywall.html:87`). The copy group in the widget test requires it on
   screen. *Fix:* carry the tag on `PaywallPlan` (or render it statically and
   say so in `1_plan.md` so there is a single source of truth).

6. **Minor — repository writes are UPDATE-only, not upserts.**
   `paywall_repository_impl.dart:36-45` (`startTrial`) and `:47-56`
   (`activate`) use `update(appState)..where(id = 1)` with no insert fallback;
   `AppSession._write` (`core/data/app_session.dart:70-79`) upserts. If
   `app_state` is ever empty the write silently touches 0 rows and the user is
   routed to `/today` with no subscription recorded — the P01 BUG-4 defect
   class. *Fix:* use the same upsert pattern.

7. **Minor (latent) — accessibility/bottom-edge/alignment contracts unmet.**
   The placeholder has no semantic labels (nav label `Subscription`, close
   button label/action, `selected: true` plan card, decorative nest/coins
   unlabelled), and once the real body lands it must verify the OWNER rules:
   painted pixel on the last row equals the `NestBottomCta` surface colour
   (no page-tint/meadow strip under the home indicator), consistent 20 px
   gutters, and `PipAvatar(style: mochi, skin: sunny, stage 4, inNest: true)`
   on the 120×120 hero slot — never `pip_stage_*.svg`.

## Architecture / rules check

- Feature-first layout (`domain` entities + abstract repo, Drift-backed
  `data`, BLoC per screen, routes + DI per feature) matches
  `docs/ARCHITECTURE.md`; the placeholder is scaffolding only.
- Edited paths stay inside RULES §1 (`app/lib/features/paywall/**`,
  `app/test/features/paywall/**`, `docs/screens/P07/**`). No shared files
  touched; no `SHARED_REQUEST.md` filed, and none of the failures requires
  one.
- `2_build.md` correctly records that `AppSession` is provided via GetIt only
  (`app/lib/app/app.dart:46-52` lacks it as a `Provider` ancestor), so the
  plan's `context.read<AppSession>()` would throw — use
  `GetIt.instance<AppSession>()`.
- `flutter analyze` reports no issues and `dart format` is clean per
  `3_test.md`; no hard-coded colours/sizes introduced by this iteration (no
  UI code added).
- Children's Code: no analytics, ads, tracking, or child-data surfaces
  introduced; parent mode only.
- Data-over-mocks / periods / child-order rules: not exercised by current
  code; must hold in the build (annual plan from repository, no hard-coded
  design numbers).

## Verdict basis

Blockers 1–3 stand: the required surface, navigation path, and green test
suite are all absent. This iteration cannot pass; the build stage must
implement `1_plan.md` §§a–g against the existing failing tests, fix findings
4–7, and then stages 3–4 rerun.

VERDICT: FAIL
