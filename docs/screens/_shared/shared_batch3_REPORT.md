# Shared batch 3 — REPORT (branch `shared/shared_batch3`)

Scope: trial expiry (P07-BUG-8), router guard order (P07-BUG-9), shared
balanced headings (`NestBalancedText` + P07 title), paywall co-parent name
from the database. All changes are backward-compatible: new optional
constructor params with defaults, one new nullable state field, one new
repository method with a null default, no public API renames, no route
changes. Screen branches merge and compile without edits.

Evidence read first: `docs/screens/P07/SHARED_REQUEST.md` §§1–2,
`docs/screens/P07/6_bugs.md` (carried items + verification baselines),
`docs/research/DATETIME_STORAGE.md` (elapsed-time trial rule),
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/design/SPACING_SPEC.md`, `tools/screens/stages/common.md` (owner
rules), `design/html-source/components.css` + `screens/P07-paywall.html`.

## Files changed

- `app/lib/core/data/app_session.dart` — injectable `AppSessionClock`
  (`AppSession(db, {clock})`, default `DateTime.now`); `trialLength = 14
  days`; `isTrialStartExpired(trialStart, nowUtc)` (elapsed
  `trialStart + 14d <= now`, null start never expires); `trialExpired` is
  computed (persisted `'expired'` OR still-`'trial'` but aged out; anything
  else — notably `'active'` — never expires); `startTrialNow` stamps the
  clock; `refresh()` persists an aged-out trial as `'expired'`;
  `checkTrialExpiry()` launch/resume entry point (true iff this call
  flipped `'trial'` → `'expired'`).
- `app/lib/app/launch.dart` — explicit `await
  session.checkTrialExpiry()` after the final `refresh()` (`refresh`
  already enforces; the call keeps the launch contract visible).
- `app/lib/app/app.dart` — `_NestlingAppState` is now a
  `WidgetsBindingObserver`: on resume it fire-and-forgets
  `checkTrialExpiry()`, whose session notification re-evaluates the router
  guard. (Between resumes the computed `trialExpired` getter already fires
  on the next navigation even before the persist.)
- `app/lib/app/router.dart` — guard order fix (P07-BUG-9): the kid-mode
  parent-only → gate redirect now runs BEFORE the onboarding redirect, and
  `/parental-gate` is exempt from the onboarding → `/welcome` rule, so the
  gate redirect sticks for a not-yet-onboarded kid app. Side effect of the
  exemption (no test covers it): a parent fresh-install deep link to
  `/parental-gate` now stays instead of bouncing to `/welcome`.
- `app/lib/core/design_system/components/nest_balanced_text.dart` (new) +
  export in `design_system.dart` — `NestBalancedText` (see item 3).
- `app/lib/features/paywall/domain/paywall_repository.dart` +
  `data/paywall_repository_impl.dart` — new `readCoParentName()` (default
  null; Drift impl selects `members.role = 'co-parent'` in insertion
  (`rowid`) order). Task-allowed exception to the "no feature edits" rule:
  item 4 requires it ("through the paywall bloc/repository").
- `app/lib/features/paywall/presentation/bloc/paywall_state.dart` — new
  nullable `coParentName` (+ `clearCoParent`, mirroring `clearError` so a
  reload replaces instead of keeping a stale name).
- `app/lib/features/paywall/presentation/bloc/paywall_bloc.dart` —
  `_onLoadRequested` one-shot-reads `readCoParentName()` (fail-closed to
  null) into the loading emit; loaded/error states inherit it. One-shot, not
  a second `emit.forEach`, so no new live stream: the suite's teardown
  timers are untouched (a `StreamBuilder` on a Drift watch was prototyped
  first and broke four paywall view tests that dispose without a drain).
- `app/lib/features/paywall/presentation/views/paywall_view.dart` —
  `_PaywallTitle` uses `NestBalancedText` (same copy/style/maxLines, single
  `Text` node: `find.text`, semantics, ellipsis unchanged); `_BenefitList`
  split into three static rows + `_CoParentBenefitRow` reading
  `bloc.state.coParentName` via `context.select` ("… so `Name` sees the
  same" / fallback "… so everyone sees the same").
- Tests: un-skipped `[P07-BUG-8]`/`[P07-BUG-9]`
  (`app/test/features/paywall/p07_bugs_test.dart`, + BUG-1 now expects the
  fresh-seed fallback for benefit 4); reworked the "identical paywall under
  every seed" test (`paywall_view_test.dart`: identical after normalising
  the one database-driven line); new `app/test/core/
  app_session_trial_expiry_test.dart`,
  `app/test/design_system/nest_balanced_text_test.dart`,
  `app/test/features/paywall/paywall_coparent_test.dart`; two additions in
  `paywall_bloc_test.dart` (see below).

## Item 1 — trial expiry (P07-BUG-8, major) → DONE

Was: nothing ever wrote `subscription_status = 'expired'`; the router
guard was dead code. Now: elapsed 14 days from `trialStart` (UTC instant +
`Duration(days: 14)` — DST-immune by construction, which settles
SHARED_REQUEST §1's BST question in favour of the task's elapsed rule over
the calendar-day suggestion), computed in the getter and persisted at
launch/resume. `active` is never touched (pinned by test). `[P07-BUG-8]`
un-skipped and green; the other router tests are untouched and green.

## Item 2 — router guard order (P07-BUG-9, minor) → DONE

Was: kid + onboarding-incomplete deep link to `/paywall` → gate → gate
re-evaluated by the onboarding rule → `/welcome`. Now: kid branch first +
gate exempt → `/parental-gate`, and it sticks. `[P07-BUG-9]` un-skipped and
green; `router_redirect_test.dart`, `router_push_test.dart`,
`routes_smoke_test.dart` all green. Bonus correctness: kid + expired now
gates (paywall is parent-only) instead of paywalling a kid.

## Item 3 — balanced headings → DONE

`components.css` sets `text-wrap: balance` on `.display`, `.h1`,
`.kid-title`, `.kid-hero` (plus the `.balance` utility and P08's
screen-local `.banner p` / `.quest-title`). `NestBalancedText` keeps the
full width's minimum line count and binary-searches (`TextPainter`, 12
halvings) the narrowest width that still fits it, then centres/aligns the
narrowed box per `textAlign`. Single `Text` node, no `\n` (the old
"no inserted hard break" pin still passes). P07 title now breaks "Try
Nestling" / "free for 14 days" (was "…free for 14" / "days"), centred
(the "title is centred" pin still passes at dx 195). Measurement mirrors
`Text` exactly — including the framework rule that an ellipsis without
`maxLines` is single-line (found by probe; unit tests pin `maxLines` like
every call site).

## Item 4 — paywall co-parent name → DONE

Was: hard-coded "… so James sees the same". Now: `PaywallRepository.
readCoParentName()` (Drift, insertion-ordered) → bloc state → benefit 4.
Demo names James; fresh/empty render the fallback. No mocks: repository,
bloc and widget proofs all read a real in-memory database. The old
"identical copy under every seed" pin now normalises the one
database-driven line (everything else still byte-identical; Maya/Leo never
leak).

## Tests added (all pass; full suite +1000, 0 skips)

- `app_session_trial_expiry_test.dart`: static boundary group
  (`a null start never expires`, `13 days 23:59 is still a live trial`,
  `exactly 14 days counts as expired`, `15 days is expired`); pinned-clock
  group (`startTrialNow stamps the clock instant`, `a 15-day-old trial
  reads expired and persists on check` — asserts the getter fires while the
  row is still `'trial'`, then the persist, `a 13-day-old trial stays live
  and writes nothing`, `a trial with no start never expires`, `an
  already-expired row stays expired`); `an active subscriber never expires
  / demo is live 100 days later`.
- `nest_balanced_text_test.dart`: search group (`the title needs more than
  one line at the full width`, `the balanced width keeps the minimum line
  count`, `one step narrower needs more lines`, `a single-line heading lays
  out on one line`); real-font P07 group (`the title keeps two lines of
  near-equal width` — line widths differ by less than "Nestling",
  `the title breaks after "Nestling"`).
- `paywall_coparent_test.dart`: repository group (`demo reads James`,
  `fresh reads null`, `empty reads null`, `an invited co-parent surfaces by
  name`, `with two co-parents the first added wins`); widget group
  (`demo paywall names the seeded co-parent`, `fresh paywall shows the
  fallback` — both also assert `currentPath`, not just copy).
- `paywall_bloc_test.dart`: `copyWith replaces the co-parent name, clearing
  it on a fresh load`, `the load carries the co-parent name from the
  database` (real Drift demo seed → James).
- Un-skipped, not new: `[P07-BUG-8]`, `[P07-BUG-9]`.

## Follow-up for screens (no action needed to merge)

1. Adopt `NestBalancedText` wherever the design balances (drop-in: same
   copy/style/`maxLines`, centred by default). Inventory from
   `components.css` + screen HTML:
   - `.display` → P01 welcome (onboarding).
   - `.h1` → P02 `pg-title` ("Set quests in seconds", also carries
     `.balance`), P03, P04, P05, P06 headings. P07 done here.
   - `.kid-title` → K01, K03, K04, K06, K07 (`k7-hero`), K09 (`k9-head`),
     K10 (`k10-hero`).
   - `.kid-hero` → K05 (`k5-hero`).
   - Screen-local balance (not shared classes): P08 `.banner p` and
     `.quest-title` — P08 owners decide (soft-wrap already allowed per
     SPACING_SPEC §9.2; use the widget if the orphan shows).
   - `.h2`/`.h3`/`.body`/`.caption` and friends have NO balance in CSS —
     do not use the widget there.
2. P07 copy is no longer seed-identical: benefit 4 follows the members
   table. Do not re-pin James for non-demo seeds.
3. Do not write `subscription_status` directly — expiry flows through
   `AppSession` (computed getter + launch/resume persist). An expired
   paywall still omits the close control (P07-BUG-10 stands).
4. The gate exemption is global: a parent deep link to `/parental-gate`
   during onboarding now stays instead of redirecting to `/welcome`. Flag
   it in review if any screen depended on the bounce.

VERDICT: PASS
