# P07 Paywall — bug hunt (Stage 6, iteration 1)

Adversarial test pass over the P07 feature as it exists on this branch:
`app/lib/features/paywall/**` (placeholder view, load-only bloc, Drift
repository, route), the router guard and session handoff, and the design
sources (`design/html-source/screens/P07-paywall.html`,
`design/screens/{light,dark}/P07-paywall.png`, `docs/DESIGN_SPEC.md:158`,
`docs/screens/P07/1_plan.md`, `docs/screens/P07/ORCHESTRATOR_NOTES.md`).

**Headline: the screen is still the foundation placeholder.** Every designed
element is absent, the trial/restore path does not exist, and the trial the
screen is supposed to start can never expire. The bug-proof tests live in
`app/test/features/paywall/p07_bugs_test.dart`, one group per bug id, all
`skip: true` with the bug id in the test name so the suite stays green while
the defects are open (this SDK's `testWidgets`/`test` `skip` parameter is
`bool?`, so the id lives in the test name rather than the skip string;
`flutter test test/features/paywall/` → `+24 ~12 −43`, the −43 being stage 3's
pre-existing red contract suite).
`flutter test test/features/paywall/p07_bugs_test.dart --run-skipped` fails
all 12 bug tests for exactly the reasons below; the four “verified clean”
baselines in the same file pass.

## Bug summary

| # | Severity | One line | Failing test(s) |
|---|---|---|---|
| 1 | Blocker | The paywall screen does not exist (placeholder only) | `[P07-BUG-1] the design surface renders at /paywall` |
| 2 | Blocker | No trial/restore path; P07 dead-ends onboarding (ORCHESTRATOR_NOTES 1 unmet) | three `[P07-BUG-2]` tests |
| 3 | Major | `NestBottomCta` cannot render the design order (CTA → caption → legal row) | `[P07-BUG-3] CTA, then caption, then legal row — all inside the bottom bar` |
| 4 | Minor | Plan caption drops “the” (`after 14-day trial`) | `[P07-BUG-4] the repository caption is the design’s wording` |
| 5 | Minor | Plan detail is not the design copy (stray full stop, sub+caption merged, tag dropped) | two `[P07-BUG-5]` tests |
| 6 | Minor | `PaywallState.copyWith` cannot clear `errorMessage`; stale error survives a retry | `[P07-BUG-6] errorMessage is cleared when the reload succeeds` |
| 7 | Minor (latent) | Repository trial/restore writes are UPDATE-only, not upserts | `[P07-BUG-7] startTrial records the trial even if the row is missing` |
| 8 | Major (shared) | The 14-day trial never expires — router guard unreachable | `[P07-BUG-8] a trial started 15 days ago must not keep giving access` |
| 9 | Minor (shared) | Kid mode + onboarding-incomplete deep link ends on /welcome, not the gate | `[P07-BUG-9] a kid-mode deep link to /paywall lands on the parental gate` |

---

### P07-BUG-1 — Blocker — the paywall screen is not implemented

**Where:** `app/lib/features/paywall/presentation/views/paywall_view.dart:9-42`
(`AppBar('P07 Paywall')` at :12, `Text('No items yet')` at :25, `ListTile` at
:31).

**Repro:** `cd app && flutter test test/features/paywall/p07_bugs_test.dart
--run-skipped --plain-name '[P07-BUG-1]'` → `Expected: no matching candidates /
Actual: Found 1 widget with text "P07 Paywall"`. Pump `/paywall` at 390×844 and
the screen shows a Material app bar and one `ListTile` whose subtitle is the
repository plan string. The design has: compact nav with the 44×44 close
button, hero (`PipAvatar` mochi/sunny stage 4 in the nest, 3 coins), the h1
`Try Nestling free for 14 days`, the 4 benefit rows, the leaf-bordered annual
plan card (radio, title, sub, tag), the `What happens next` timeline, the
family note, `NestBottomCta` with `Start free trial`, the caption, and the
`Restore purchases · Terms · Privacy` row.

**Rule impact:** orchestrator PIP (no `PipAvatar` anywhere), COPY, ALIGNMENT
and BOTTOM EDGE are all unimplemented; the stage 5 comparison already showed
the whole surface missing in light and dark.

**Suggested fix:** implement `docs/screens/P07/1_plan.md` §a in full
(feature-private widgets; tokens only). The stage 3 widget contract
(`paywall_view_test.dart`) is the checklist.

### P07-BUG-2 — Blocker — no trial/restore path; onboarding cannot complete

**Where:** `presentation/bloc/paywall_event.dart:10` (only
`PaywallLoadRequested`), `paywall_bloc.dart:9` (only `_onLoadRequested`),
`paywall_state.dart:4,13` (no action field). The mandatory orchestrator note
(`docs/screens/P07/ORCHESTRATOR_NOTES.md:1`) requires
`AppSession.startTrialNow()` + `AppSession.completeOnboarding()` before
navigating to Today.

**Repro:** `--run-skipped --plain-name '[P07-BUG-2] Start'` → `tap()` finds 0
widgets with text `Start free trial`. Tapping the (missing) CTA can therefore
never write `app_state`, never call the session, and never reach `/today`; P07
is a dead end and a restart would land back at `/welcome` (the P01 BUG-4
class).

**Tests:** `[P07-BUG-2] Start free trial completes onboarding and lands on
/today` (expects `onboarding_complete=true`, `subscription_status='trial'`,
`trial_start` set with `Europe/London`, path `/today`),
`[P07-BUG-2] Restore purchases activates (never downgrades) and lands on
/today`, and `[P07-BUG-2] a rapid double tap starts one trial and navigates
once` (two taps with no frame between must not double-navigate or throw from a
disposed context).

**Suggested fix:** per `1_plan.md` §b–c: add `PaywallTrialStarted` /
`PaywallRestoreRequested` and a `PaywallAction` discriminator; trial =
`repository.startTrial()` + `session.startTrialNow()` + `completeOnboarding()`;
restore = `repository.activate()` + `session.setSubscription('active')` +
`completeOnboarding()`; then `context.go(TodayRoutePaths.today)`. Use
`GetIt.instance<AppSession>()` (it is **not** a Provider ancestor —
`app/lib/app/app.dart:45-53`), guard the listener with `context.mounted`, and
ignore success while `action == working` so a double tap is a no-op.
Build note: the constant is `PocketMoneyRoutePaths.setup`, not
`.pocketMoneySetup` (`app/lib/features/pocket_money/pocket_money_routes.dart:13`).

### P07-BUG-3 — Major — the bottom bar cannot render the design's order

**Where:** `app/lib/core/design_system/components/nest_bottom_cta.dart:19-48`
renders `child` first and its optional `caption` last; there is no slot after
the caption. `1_plan.md` §a.4 (and `P07-paywall.html:103-113`) require
`Start free trial` → caption → `Restore purchases · Terms · Privacy`, all
inside the bar. A build that follows the plan literally cannot place the legal
row after the caption; a build that passes `child: Column(button, legalRow)`
renders the legal row **above** the caption.

**Repro:** `--run-skipped --plain-name '[P07-BUG-3]'` → fails finding the
elements (nothing built), and the order assertions pin the requirement:
`cta.bottom ≤ caption.top ≤ legal-row.top`, with the links inside
`NestBottomCta`.

**Suggested fix:** build the bar content locally as
`NestBottomCta(child: Column(button, caption, _LegalRow), caption: null)`
using `NestType.caption` for the caption text (screen-private, no core edit),
which keeps the component's `DecoratedBox` + `SafeArea` bottom-edge guarantee.
If a shared footer slot is preferred instead, file a SHARED_REQUEST for
`nest_bottom_cta.dart` — do not re-implement the bar's surface in the feature.

### P07-BUG-4 — Minor — the plan caption drops the article “the”

**Where:** `app/lib/features/paywall/data/paywall_repository_impl.dart:52-54`
→ `'£29.99/year after 14-day trial.'`. The design's `.caption`
(`P07-paywall.html:105`) is `£29.99/year after the 14-day trial. Cancel
anytime in Settings.` — the HTML is the copy source of truth (orchestrator
COPY rule; `DESIGN_SPEC.md:158` paraphrases without “the”, the HTML wins).

**Repro:** `--run-skipped --plain-name '[P07-BUG-4]'` →
`Actual: 'Just £2.50 a month, billed yearly. £29.99/year after 14-day trial.
Cancel anytime in Settings.'` (does not contain `after the 14-day trial`).

**Suggested fix:** insert `the ` at `paywall_repository_impl.dart:54`.

### P07-BUG-5 — Minor — the plan detail is not the design copy

**Where:** `paywall_repository_impl.dart:48-56`. Three defects in one string:

1. the sub gains a full stop the design does not have — HTML `:86` is
   `Just £2.50 a month, billed yearly` (no `.`); the repository writes
   `billed yearly. `;
2. the sub and the CTA caption are concatenated into `detail`, so a consumer
   rendering `detail` as the sub prints the caption too;
3. the card's third line `One price, the whole family` (`P07-paywall.html:87`)
   has no data source at all — `detail` drops it, so the plan card would have
   to hard-code it.

**Repro:** `--run-skipped --plain-name '[P07-BUG-5]'` → both tests fail:
`Expected: not contains 'billed yearly.'` and `Expected: contains 'One price,
the whole family'`.

**Suggested fix:** give `PaywallPlan` a `tag` field (feature-local entity) and
store the sub exactly as the design writes it; keep the caption out of
`detail` or expose it as its own field. If the view renders the three strings
statically per `1_plan.md` §d, still fix `detail` so the data layer cannot
leak wrong copy to a future consumer.

### P07-BUG-6 — Minor — a stale error survives a successful retry

**Where:** `paywall_state.dart:17-27` — `copyWith` can set `errorMessage` but
never reset it to `null`. Sequence: load fails (`errorMessage='Exception:
offline'`) → retry succeeds (`status: loaded`) → the failure message is still
in the state, so any future action-failure toast/UI can surface a stale error.

**Repro:** `--run-skipped --plain-name '[P07-BUG-6]'` →
`Expected: null / Actual: 'Exception: offline'`.

**Suggested fix:** add an explicit clear path — e.g.
`copyWith({bool clearError = false})` or a dedicated
`PaywallState.loaded(...)` constructor used by `_onLoadRequested`'s `onData`
that starts from a clean state.

### P07-BUG-7 — Minor (latent) — repository writes are UPDATE-only

**Where:** `paywall_repository_impl.dart:30-39` (`startTrial`) and `:41-46`
(`activate`) do `update(appState)..where(id = 1)` with no insert fallback.
`AppSession._write` (`core/data/app_session.dart:67-76`) upserts because a
real first install has no seeded row (P01 BUG-4). Today
`AppDatabase.migration.beforeOpen` (`app_database.dart:341-367`) guarantees the
row, so this is not reachable through normal seeding — but the repository is
one schema/launch path away from the same silent no-op: 0 rows written, yet
the user is navigated to `/today` with no subscription recorded.

**Repro:** `--run-skipped --plain-name '[P07-BUG-7]'` — delete the row, call
`startTrial()` → `Expected: not null / Actual: <null>` (no row written).

**Suggested fix:** mirror `AppSession._write`: after `write(companion)` returns
0, insert `companion.copyWith(id: Value(1))`.

### P07-BUG-8 — Major (shared) — the 14-day trial never expires

**Where:** nothing in `app/lib` ever writes `subscription_status = 'expired'`
(`grep -rn "'expired'" app/lib` → only the readers
`core/data/app_session.dart:27` and
`features/paywall/domain/entities/subscription_status.dart:10`). The router's
guard `router.dart:90-93` (`onboarded && session.trialExpired → /paywall`) is
therefore dead code: a trial started by P07 (or seeded `trial` with a
`trial_start`) keeps full access forever, and the paywall never returns. The
design is explicit: `Day 14 — £29.99 billed — cancel any time`.

**Repro:** `--run-skipped --plain-name '[P07-BUG-8]'` — start a trial, backdate
`trial_start` 15 days, pump `/today` → `Expected: '/paywall' / Actual:
'/today'`.

**Suggested fix (shared, needs SHARED_REQUEST):** make expiry real — compute
`trialExpired` from `trialStart + 14 calendar days` in the family zone using
`london_time.dart` (a UTC `+ Duration(days: 14)` is wrong across the October
BST→GMT change and is the timezone trap for this screen), or persist
`'expired'` at launch; then the existing router redirect works. Owner:
`core/data/app_session.dart` + `app/launch.dart`.

### P07-BUG-9 — Minor (shared) — kid-mode guard order during onboarding

**Where:** `app/lib/app/router.dart:83-118`. For a kid-mode app that is **not
yet onboarded**, `/paywall` redirects to the parental gate, but the gate
location is then re-evaluated by the onboarding rule (`!onboarded && !in
_onboardingLocations` → `/welcome`), and `/welcome` is itself parent-only, so
the chain terminates on `/welcome` (P01's parent marketing screen) instead of
the gate. Onboarded kid mode is correct (`/paywall` → `/parental-gate`).

**Repro:** `--run-skipped --plain-name '[P07-BUG-9]'` → `Expected:
'/parental-gate' / Actual: '/welcome'`.

**Suggested fix (shared):** evaluate the kid-mode branch before the onboarding
branch, or exempt `ParentalGateRoutePaths.gate` from the onboarding redirect.
Low reachability (APP_MODE=kid during onboarding), hence minor.

---

## Verified clean (not bugs)

- **Deep links, parent mode:** `/paywall` is reachable with `Seed.fresh`
  (onboarding incomplete) and stays open for an onboarded demo app; the close
  target `/pocket-money-setup` is an onboarding location, so both entry paths
  are consistent. Baselines in `p07_bugs_test.dart`.
- **Kid-mode guard (onboarded):** `/paywall` → `/parental-gate`; no parent-only
  bypass in the realistic combination.
- **Restart persistence:** after `startTrialNow()` + `completeOnboarding()`, a
  fresh `AppSession` over the same database reads onboarding complete, status
  `trial`, `trial_start` set, zone `Europe/London` — the data layer would
  survive a restart once BUG-2 writes through it.
- **Dark-mode contrast (tokens, computed):** dark sky `#7FA9FF` on surface
  `#1F1C2E` = 7.14:1, dark leafInk `#8EE6BC` on leafTint `#173A2B` = 8.47:1,
  ink2 on surface = 9.82:1, separators 6.19:1; light sky `#2563D6` on surface
  `#FFFFFF` = 5.48:1, leafInk on leafTint = 7.12:1 — all ≥ 4.5:1 for the 13px
  links.
- **Money rounding / integer pence:** P07 does no arithmetic — the £29.99 and
  £2.50 strings are static copy and the screen reads no ledger rows, so
  pence-rounding and BST money bugs are not applicable here.
- **Data edge cases (0/1/6 children, long names, £0.00, 9999 coins):** not
  applicable — P07 renders no child or money data (plan list is static, one
  entry); the stage 3 suite pins demo/empty/fresh to an identical screen and
  forbids `Maya`/`Leo` leaking in.
- **Rapid double tap:** no implementation exists to double-fire (BUG-2); the
  contract test in BUG-2's group pins single navigation + no disposed-context
  throw for when it lands.
- **Status bar, `NestStatusBar` height-only, text-scale 1.3 / width 320,
  bottom-edge pixels, 20px gutters:** all are stage 3/5 contracts and cannot
  be independently re-verified while the surface is absent (BUG-1).

## Verdict basis

P07-BUG-1 and P07-BUG-2 are blockers: the screen does not exist and its only
purpose — starting the trial and finishing onboarding — is unimplemented.
P07-BUG-3 is a major build trap in the design-system API, and P07-BUG-8 is a
major product hole (a trial that never ends). The minor findings (4–7, 9) are
real and each has a failing proof test. “No major bugs” does not hold.

VERDICT: FAIL
