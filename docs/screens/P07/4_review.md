# P07 Paywall — QA code review (Stage 4, iteration 2)

Scope reviewed: `git diff main...HEAD` (paywall feature lib + tests, loop
docs), against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5, `docs/design/SPACING_SPEC.md`, the design-system
under `app/lib/core/design_system/`, and mandatory
`docs/screens/P07/ORCHESTRATOR_NOTES.md`. Evidence: `flutter analyze`
(No issues found!), `flutter test test/features/paywall/` → `+84 ~2` (all
passed; 2 skips are the shared-router defects filed in
`SHARED_REQUEST.md`), iteration-1 defects tracked in `6_bugs.md` are all
closed in code.

## Findings

1. **Minor — CTA caption copy duplicated.** The string
   `£29.99/year after the 14-day trial. Cancel anytime in Settings.` appears
   twice: rendered statically in
   `app/lib/features/paywall/presentation/views/paywall_view.dart:691` and
   again inside the repository's `PaywallPlan.detail`
   (`app/lib/features/paywall/data/paywall_repository_impl.dart:60-63`).
   The view's static render is intentional per `1_plan.md` §d, but the
   repository must not be a second source of truth for it. Concrete fix:
   drop the caption/tag sentence from `PaywallPlan.detail` (leave sub +
   title), or expose a caption accessor on the entity and have the view
   read it.

2. **Minor — hero geometry uses raw pixel literals.**
   `paywall_view.dart:283-376` hard-codes the hero stack (170×170 circle at
   (90,−5), 150 nest at (100,41), 120 Pip at (115,20), coin offsets), and
   the body uses raw gaps `SizedBox(height: 26)` (:250), `18` (:253),
   `48` (:260), and `Padding(left: 36)` (:615). This reproduces the design
   exactly and matches the P01 hero-scene precedent, but the gaps should
   either come from `NestSpacing` tokens or a short comment stating they
   are design-absolute px (the `24/15` / `20/15` line-box `copyWith` at
   :435,:502,:592,:631 has exactly that justification). Concrete fix:
   replace the three body gaps with the nearest tokens only if the pixel
   diff stays within tolerance; otherwise annotate each with
   `// design-absolute`.

3. **Minor — `_PaywallCta` composes its own bar instead of using
   `NestBottomCta.caption`.** `paywall_view.dart:675-700` passes
   `caption: null` (per `1_plan.md` §f, P07-BUG-3) and inlines the caption
   text so `Restore purchases · Terms · Privacy` can sit after it. This
   preserves the owner rule (the `NestBottomCta` `DecoratedBox` surface
   still runs to the screen edge, `nest_bottom_cta.dart:19-30`), but the
   duplication of the bar's caption styling (`NestType.caption`,
   `ink2`, centred, maxLines 3) will drift if the component changes.
   Concrete fix: the `SHARED_REQUEST.md` already asks for a
   `caption/legal` slot on `NestBottomCta`; once that lands, delete the
   local composition.

4. **Minor (latent) — terms/privacy toast placeholders.** The legal links
   answer in place with a toast (`paywall_view.dart:744-752`) pending real
   routes. Acceptable for P07, but the TODO must be actioned before
   release; it already is tracked in `SHARED_REQUEST.md`-adjacent planning
   and carries no child-data exposure.

## Checks passed

- **Architecture:** feature-first layout holds — domain is entities
  (`paywall_plan.dart`, `subscription_status.dart`) + abstract
  `paywall_repository.dart` only; one BLoC for the screen; DI
  (`paywall_di.dart`) and routes (`paywall_routes.dart`) per feature.
- **RULES §1 paths:** the diff touches only
  `app/lib/features/paywall/**`, `app/test/features/paywall/**` and
  `docs/screens/P07/**` — nothing shared, nothing outside the allow-list.
- **Design system:** no hard-coded colours/fonts; all text goes through
  `NestType.*`, spacing through `NestSpacing.*`, icons through
  `NestIcon`/`NestIcons`, the bottom bar through `NestBottomCta`, status
  bar via `NestStatusBar`. No `google_fonts`/`GoogleFonts` anywhere in the
  feature or its tests.
- **DESIGN_SPEC §5 / COPY:** title, 4 benefits, plan title/sub/tag,
  timeline (`Today` / `Day 12` / `Day 14` with curly apostrophe and em
  dash), family note, CTA, caption and legal row all match
  `P07-paywall.html` character-for-character (verified `—` U+2014, `’`
  U+2019, `·` U+00B7, `£`). UK spelling throughout.
- **Orchestrator rules:** `PipAvatar(style: mochi, skin: sunny [default],
  stage: 4, inNest: true)` on the 120×120 hero slot (P01–P07 rule, no
  `pip_stage_*.svg`); trial/restore writes go through
  `AppSession.startTrialNow()` / `setSubscription('active')` /
  `completeOnboarding()` before `/today` (ORCHESTRATOR_NOTES 1,
  `paywall_view.dart:47-60`); restore never downgrades an `active`
  subscription; `AppSession` read via `GetIt.instance` because it is not a
  `Provider` ancestor.
- **Iteration-1 regressions closed:** caption now contains "the"
  (:691, repository :61); `_upsert` fallback in
  `paywall_repository_impl.dart:65-75`; `copyWith(clearError:)` in
  `paywall_state.dart:33-40`; trial vs restore discriminator
  `PaywallRequest` prevents the startTrial-on-restore bug.
- **Accessibility:** nav has `Semantics(label: 'Subscription', header:
  true)` with `explicitChildNodes`; close is a 44×44 labelled button with
  tap action; benefits rows labelled; plan card announces
  `selected: true`; decorative nest/coins/ticks/connector carry no label;
  legal links are `button: true` with labels on ≥44×44 targets.
- **Performance:** screen is short static content under
  `SingleChildScrollView` (eager layout, no sliver semantics issues);
  bloc-scoped rebuilds only via `BlocBuilder`/`BlocListener` with
  `listenWhen`; the repository stream is a single-value stream; hero uses
  the scale-down `LayoutBuilder` pattern; heavy SVGs are `ExcludeSemantics`
  wrapped. No rebuild storms observed.
- **Error handling:** `initial`/`loading` progress, `failure` shows
  "Something went wrong" + Retry that re-adds `PaywallLoadRequested`;
  action failure surfaces `showNestToast` with the exception message;
  second-tap while `working` is a bloc-level no-op.
- **Children's Code:** parent mode only; no analytics, ads, tracking,
  or child-data surfaces added.
- **Tests:** 84 passed, 2 skipped (the shared router-guard trial-expiry
  and kid-mode gate defects, correctly deferred via `SHARED_REQUEST.md`
  rather than faked green here). Analyzer and format clean.

## Verdict basis

No blocker or major findings remain in the P07 feature code. The
remaining shared-side defects (trial expiry guard, kid-mode deep-link
gate, `NestBottomCta` legal slot) are documented in
`docs/screens/P07/SHARED_REQUEST.md` and skipped in the suite with the
defect id in each test name.

VERDICT: PASS
