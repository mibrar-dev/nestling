# P07 Paywall — bug hunt (Stage 6, iteration 2)

Adversarial pass over the now-built P07 feature: `app/lib/features/paywall/**`
(808-line view, action bloc, Drift repository, route), the router guard and
session handoff, and the design sources
(`design/html-source/screens/P07-paywall.html`,
`design/screens/{light,dark}/P07-paywall.png`, `docs/screens/P07/1_plan.md`,
`docs/screens/P07/ORCHESTRATOR_NOTES.md`, `SHARED_REQUEST.md`).

**Headline: the screen is built and iteration-1 bugs 1–7 are fixed with green
proofs.** Iteration 2 found one **major latent** defect — the close button
cannot leave the expired-trial paywall (P07-BUG-10, found by stage 3 and
independently reproduced here) — plus two new **minor** bugs (P07-BUG-11,
P07-BUG-12). The two shared items from iteration 1 (P07-BUG-8 major,
P07-BUG-9 minor) remain open, filed in `docs/screens/P07/SHARED_REQUEST.md`,
and cannot be fixed under RULES §1. Because P07-BUG-10 is major (it becomes a
blocking trap the moment P07-BUG-8’s expiry fix lands), this iteration cannot
pass.

Proof file: `app/test/features/paywall/p07_bugs_test.dart` — 14 tests
unskipped and green (bugs 1–7 + 4 verified-clean baselines), 5 skipped
(BUG-8/9 shared, BUG-10/11/12 open). `--run-skipped` fails each skipped proof
for the documented reason.

## Iteration-1 ledger

| ID | Iteration-1 finding | Iteration-2 outcome |
|---|---|---|
| P07-BUG-1 | blocker: screen not implemented | **fixed** — full `1_plan.md` §a surface; proof green |
| P07-BUG-2 | blocker: no trial/restore path, onboarding dead end | **fixed** — events + `PaywallAction`/`PaywallRequest`, session writes, `/today`; proofs green |
| P07-BUG-3 | major: `NestBottomCta` cannot render CTA → caption → legal row | **fixed** — local column with `caption: null`; proof green |
| P07-BUG-4 | minor: caption dropped “the” | **fixed** — `detail` now `after the 14-day trial`; proof green |
| P07-BUG-5 | minor: stray full stop, tag missing from data | **fixed** — `detail` carries sub + caption + tag, em-dash joined; proofs green |
| P07-BUG-6 | minor: stale `errorMessage` survived a retry | **fixed** — `copyWith(clearError:)`; proof green |
| P07-BUG-7 | minor (latent): UPDATE-only writes | **fixed** — `_upsert` mirrors `AppSession._write`; proof green |
| P07-BUG-8 | major (shared): the 14-day trial never expires | **open** — nothing writes `'expired'`; `SHARED_REQUEST.md` §1; proof skipped |
| P07-BUG-9 | minor (shared): kid-mode guard order during onboarding | **open** — `router.dart` unchanged; `SHARED_REQUEST.md` §2; proof skipped |

Evidence for the fixes: all ten iteration-1 proofs are unskipped and pass
(`flutter test test/features/paywall/p07_bugs_test.dart` → `+14 ~5`), plus the
feature suites. The four stage-3 test defects the build repaired (impossible
`tops[1] ≈ tops[2]`, CTA height measured on the label text, bool matcher on a
`Tristate`, decorative-label regex that matched the title/Pip) were each
re-verified as legitimate test bugs; intent was preserved, not weakened.

## Iteration-2 findings

### P07-BUG-10 — Major (latent today; blocking trap once P07-BUG-8 lands) — the close button cannot leave the expired-trial paywall

**Found by:** stage 3 (`3_test.md`, proof in `paywall_view_test.dart:1102`);
independently reproduced here with a second proof in `p07_bugs_test.dart`.

**Where:** `paywall_view.dart:27-34` (`_onBack`: `canPop() ? pop() : go(P06)`)
combined with the router’s expired-trial rule (`router.dart:90-93`): when the
trial is expired, **every** location except `/paywall` is redirected back to
`/paywall`. `pop()` lands on `/today` and is bounced; `go(P06)` is bounced
too. The design’s close X (`Close and go back`) is therefore a dead control
for an expired user — they can only subscribe or restore.

**Repro:** `cd app && flutter test
test/features/paywall/p07_bugs_test.dart --run-skipped --plain-name
'[P07-BUG-10] close leaves'` → set `subscription_status='expired'`,
onboarded, pump `/today` (redirects to `/paywall`), tap X →
`Expected: not '/paywall' / Actual: '/paywall'`.

**Failing tests:** `[P07-BUG-10] close leaves the expired-trial paywall (no
bounce)` (`p07_bugs_test.dart`, `skip: true`) and stage 3’s
`[P07-BUG-10] close escapes the expired-trial paywall (no /today bounce)`
(`paywall_view_test.dart`, `skip: true`).

**Why latent:** nothing in `app/lib` writes `'expired'` (P07-BUG-8), so the
state is unreachable in today’s product — but the moment the shared expiry
fix lands, every expired parent hits this trap. The two must be fixed
together.

**Suggested fix (screen-local option):** for `session.trialExpired` the
paywall is a hard gate, so the onboarding close affordance must not pretend
to work — omit the close tile (and its 44px balance spacer) when
`GetIt.instance<AppSession>().trialExpired`, or render it disabled with a
correct label. **Orchestrator option:** relax the router guard to allow a
specific escape (e.g. `/settings`) so X can `go` there. A test asserting
*where* an expired parent should land is a product decision; the proofs only
require “X leaves `/paywall`”.

### P07-BUG-11 — Minor — the legal separators are announced

**Where:** `paywall_view.dart:747` and `:753` render the two `·` separators
as plain `Text('·', …)`. The design marks them `aria-hidden="true"`
(`P07-paywall.html:108,110`), and the two links carry their own labels — the
dots must not become separate semantics nodes.

**Repro:** `--run-skipped --plain-name '[P07-BUG-11]'` → `Expected: no
matching candidates / Actual: Found 2 widgets with a semantics label named
"·"`. A screen reader announces “middle dot” between `Restore purchases`,
`Terms` and `Privacy`.

**Failing test:** `[P07-BUG-11] the · separators stay out of semantics`
(`skip: true`).

**Suggested fix:** wrap both separator `Text` widgets in `ExcludeSemantics`
(or `Semantics(excludeSemantics: true, …)`) — one line each, screen-local.

### P07-BUG-12 — Minor — Start free trial downgrades an active subscriber

**Where:** `paywall_view.dart:41-55` (`_onActionSuccess` trial branch always
calls `session.startTrialNow()`), after the bloc already ran
`repository.startTrial()` (`paywall_bloc.dart:50` →
`paywall_repository_impl.dart:30-39`). `/paywall` stays reachable for an
onboarded app (`router.dart` `parentOnly` list), and `Seed.demo` is an
`active` family, so the screen can be shown to a paying subscriber. Tapping
`Start free trial` overwrites `subscription_status: 'active'` with `'trial'`
and moves `trial_start`. The restore path deliberately refuses this
(“Restore purchases never starts a trial”); the trial path has no equivalent
guard.

**Repro:** `--run-skipped --plain-name '[P07-BUG-12]'` on `Seed.demo` →
`Expected: 'active' / Actual: 'trial'` (and the seeded `trial_start` is
replaced by now).

**Failing test:** `[P07-BUG-12] an active subscription is not replaced by a
trial` (`skip: true`).

**Suggested fix:** guard the trial action on the current subscription — e.g.
the bloc watches `repository.watchSubscription()` and treats an `active`
subscription as “already subscribed” (skip `startTrial()`, emit success), or
the view skips `startTrialNow()` when `session.subscriptionStatus == 'active'`
— then complete onboarding and go to `/today` as today. Note:
`paywall_bloc_test.dart` pins repository-level “trial wins by design”; the
guard belongs at the action layer, so that pin can stay as the raw repository
contract. The orchestrator may also rule that a deep-linked paid user should
be redirected off `/paywall` entirely — either way the CTA must not regress a
paid subscription.

## Carried open items (shared, filed — not fixable under RULES §1)

1. **P07-BUG-8 — major (shared):** the 14-day trial never expires; nothing in
   `app/lib` writes `subscription_status = 'expired'`, so the router’s
   `trialExpired → /paywall` redirect is dead code. Filed in
   `SHARED_REQUEST.md` §1 (owner: `core/data/app_session.dart` +
   `app/launch.dart`; suggested fix computes expiry from `trialStart + 14`
   London calendar days). Proof `[P07-BUG-8]` stays `skip: true`. **Fix
   together with P07-BUG-10** — landing expiry without the close fix traps
   every expired parent.
2. **P07-BUG-9 — minor (shared):** kid-mode + onboarding-incomplete deep link
   to `/paywall` ends on `/welcome` instead of `/parental-gate` (guard
   ordering in `app/lib/app/router.dart`). Filed in `SHARED_REQUEST.md` §2.
   Proof `[P07-BUG-9]` stays `skip: true`.

## Verified clean this iteration

- **Bugs 1–7 proofs:** unskipped and green (see ledger).
- **Rapid double taps:** trial same-frame double tap → one `startTrial` call,
  one navigation; restore same-frame double tap → one `activate` call; close
  double tap → one pop. (Bloc `working` guard + disabled CTA; probes run and
  deleted.)
- **Close during an in-flight trial:** pops to `/pocket-money-setup`, no
  exception, and the completed request never navigates to `/today` (the
  listener is gone; bloc 9 cancels the emitter, so no emit-after-close throw).
- **Load error + trial:** error body with `Retry` and the CTA both render; a
  trial tapped from the failure state still completes and lands on `/today`.
- **Deep links / back (non-expired):** `/paywall` reachable with `Seed.fresh`
  and stays open for an onboarded app; close → `/pocket-money-setup`; kid
  mode (onboarded) → `/parental-gate`.
- **Restart persistence:** trial handoff survives a fresh `AppSession` over
  the same DB (onboarded, `trial`, `trial_start`, `Europe/London`); restore
  survives as onboarded + `active`.
- **Text scale 1.3 × width 320 × dark:** no overflow/exception (CTA present);
  the stage-3 12-combination matrix covers the rest.
- **Dark-mode contrast (tokens, computed):** sky on surface 7.14:1 dark /
  5.48:1 light, leafInk on leafTint 8.47:1 / 7.12:1, ink2 on surface
  9.82:1 — all ≥ 4.5:1 for the 13 px links.
- **FONTS rule:** no `google_fonts`/`GoogleFonts` anywhere in the feature or
  its tests (grep clean; nothing to delete).
- **Money rounding / integer pence and child-data edge cases:** not applicable
  — P07 does no arithmetic and renders no child or money data (static plan,
  fixed `James` copy; demo/empty/fresh render identically per the stage-3
  seed test).
- **Owner rules:** bottom edge and 20 px gutters are pinned by the stage-3
  pixel/geometry tests and the stage-5 compare (separate stage).

## Verification (run this stage, `app/`)

- `flutter test test/features/paywall/p07_bugs_test.dart` → **+14 ~5**.
- `flutter test test/features/paywall/` → **+92 ~6** (stage-3’s own skip
  included; only the shared/open proofs skipped).
- `flutter analyze` → `No issues found!`; `dart format` → 0 changed.
- Full `flutter test` → **+742 ~6, all pass** (6 skips: the 5 open proofs in
  this file + stage 3’s P07-BUG-10 proof).
- The three new proofs (BUG-10/11/12) fail exactly as documented with
  `--run-skipped`; the scratch probe files used for the hunt were deleted.
- No screen code touched; only `app/test/features/paywall/p07_bugs_test.dart`
  and this file.

## Verdict basis

Iteration-1 blockers/majors are fixed with green proofs and the two new minor
findings have failing skip-marked proofs, but P07-BUG-10 is a real defect in
the screen’s back navigation: on the expired-trial paywall the close control
can never work while the router forces every location back to `/paywall`. It
is latent only because P07-BUG-8 is unfixed; the two must be fixed together,
and the screen should not ship a dead X into the expiry release. Per the
stage rule — PASS only if no major bugs — this iteration fails.

VERDICT: FAIL
