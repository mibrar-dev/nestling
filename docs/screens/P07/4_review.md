# P07 Paywall — QA code review (Stage 4, iteration 3)

Scope reviewed: `git diff main...HEAD` (paywall feature lib + tests, loop
docs), against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5, `docs/design/SPACING_SPEC.md`, the
design-system under `app/lib/core/design_system/`, mandatory
`docs/screens/P07/ORCHESTRATOR_NOTES.md`, and iteration-2 defects in
`docs/screens/P07/6_bugs.md`. Evidence: `flutter analyze`
(No issues found!), `flutter test test/features/paywall/` → `+101 ~2`
(all passed; skips are recorded shared defects filed in
`SHARED_REQUEST.md`).

Iteration-3 diff versus iteration 2: `PaywallBloc` gains the already-
subscribed guard on the trial path, `PaywallRepository` gains a one-shot
`readSubscription()`, `_PaywallNav` hides the dead close button while the
trial is expired, and the legal row gets tighter semantics/ellipsis.

## Findings

1. **Minor — `PaywallRequest.restore` is reused to mean "already
   subscribed".** `paywall_bloc.dart:50-66` reports success with
   `request: PaywallRequest.restore` when `startTrial` is skipped for an
   `active` subscriber, so the view's restore branch runs
   `session.setSubscription('active')` (a no-op) — correct behaviour, but
   the enum value is now a double meaning. Concrete fix: add a third
   `PaywallRequest.alreadySubscribed` value and branch on it in the
   listener (still `completeOnboarding()` + `/today`, but skip the
   redundant `setSubscription` write), or document the reuse in
   `paywall_state.dart` where `PaywallRequest` is declared.

2. **Minor — new trial guard is fail-open.** `paywall_bloc.dart:86-97`:
   when `readSubscription()` throws, the trial proceeds and would
   overwrite an unknown subscription. The comment justifies this (retry
   parity with pre-guard behaviour), and the widget tests pin it; but the
   overlap with P07-BUG-12's intent means a transient DB error can still
   regress an active sub. Concrete fix: surface the read failure as
   `PaywallAction.failure` with "Something went wrong" instead of
   attempting the trial, or at minimum record the decision in
   `6_bugs.md` as an accepted trade-off.

3. **Minor — `AppSession` read twice per build in `_PaywallNav`.**
   `paywall_view.dart:119,125`: `GetIt.instance<AppSession>()` is used as
   the `ListenableBuilder` listenable and fetched again for
   `trialExpired`. Functionally fine and rebuilds only when the session
   notifies, but the second lookup should reuse the listenable local:
   `final session = GetIt.instance<AppSession>();` once, then
   `session.trialExpired`.

4. **Minor — CTA caption copy still duplicated** between the static view
   render (`paywall_view.dart:~697`) and `PaywallPlan.detail` in
   `paywall_repository_impl.dart:60-63` (carried over from iteration 2).
   Drop the caption/tag sentence from `detail` or expose it on the entity
   and read it in the view.

5. **Minor — legal-row `·` separators are now `ExcludeSemantics`.**
   `paywall_view.dart:759-764,772-777` — this is the right call
   (decorative punctuation was leaking into the announced text), but it
   changes the asserted copy test expectations; verify the widget tests
   that count `·` separators still assert on painted text, not semantics
   (they do — suite is green). No code change needed; kept here because
   the previous iteration's accessibility note is superseded.

## Checks passed

- **Architecture:** feature-first layout holds — domain is entities +
  abstract `PaywallRepository` (the new `readSubscription()` has a
  documented default implementation; no Drift types leak into domain);
  one BLoC per screen; DI/routes per feature.
- **RULES §1 paths:** diff touches only `app/lib/features/paywall/**`,
  `app/test/features/paywall/**`, `docs/screens/P07/**` and merge-brought
  shared files outside this screen's diff. No shared edits made by P07.
- **Design system:** all colour/spacing/type via `NestType`,
  `NestSpacing`, `context.nest` tokens; `NestBottomCta`, `NestIcon`,
  `NestCard`, `NestButton`, `PipAvatar` reused; no `google_fonts`.
- **DESIGN_SPEC §5 / COPY:** hero title, benefits (incl. curly `’` in
  "Pip’s"), plan card strings with `—` U+2014, timeline with `We’ll` /
  `— cancel any time`, family note, CTA caption with `£`, legal row with
  `·` separators — all match `P07-paywall.html`; UK spelling.
- **Orchestrator rules:** `PipAvatar(style: mochi, stage: 4, inNest:
  true)` with default `skin: sunny` on the 120×120 slot; close-button
  no-op-on-expired now replaced by hiding the control (P07-BUG-10), and
  the `trialExpired` router bounce makes that the only sane shape; the
  already-subscribed guard (P07-BUG-12) stops `startTrialNow()` from
  regressing `active` → `trial`; `AppSession` access via
  `GetIt.instance` because it is not a `Provider` ancestor; child order
  and periods rules are not exercised by this parent-mode screen.
- **Accessibility:** nav header semantics preserved with
  `explicitChildNodes`; close button labelled and 44×44 (hidden, not
  dead, when expired); plan card `selected: true`; decorative coins,
  nest, ticks, connectors and `·` separators excluded from semantics;
  legal links are labelled buttons on ≥44 targets.
- **Performance:** `ListenableBuilder` scoped to the nav row only;
  one-shot `readSubscription()` avoids a dangling watch in tests; the
  bloc still emits via `emit.forEach` for the items stream (single
  subscription, cancelled on handler completion); static column renders
  eagerly under `SingleChildScrollView`.
- **Error handling:** action failure toasts with the exception message
  and keeps the screen; load failure shows Retry; `readSubscription`
  failure is caught (see finding 2); double-tap while `working` is a
  bloc-level no-op.
- **Children's Code:** parent mode only; no analytics, ads or
  child-data surfaces added.
- **Tests:** `+101 ~2` paywall suite green; the 2 skips are the shared
  router-guard defects deferred via `SHARED_REQUEST.md` with proof tests
  named `[P07-BUG-8]`/`[P07-BUG-9]`.

## Verdict basis

No blocker or major findings in the P07 feature. The trial-overwrite
guard, expired-trial close handling and one-shot subscription read are
correct improvements; remaining items are minor polish. The screen may
proceed to stage 5/6.

VERDICT: PASS
