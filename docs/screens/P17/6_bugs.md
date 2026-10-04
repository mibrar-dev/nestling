# P17 Parental gate — bug hunt (Stage 6, iteration 4)

Adversarial pass over the iteration-4 build: data edge cases (0 / 1 / 6
children, long UK names, 0 / 9999 coins, empty lists), rapid double taps
(real and semantics), back navigation and deep links, restart persistence,
parent/kid mode guards, dark-mode contrast, text scale 1.3 + 320 px and
intermediate widths, async gaps / emit-after-close, Europe/London time (both
BST changes and GMT), the new IDS rule and money rounding. No product code
was changed in this stage. No simulator was used (SIMULATORS rule;
`flutter test` only).

- Proof file: `app/test/features/parental_gate/p17_bugs_test.dart` —
  **19 tests, all green, 0 skips** (P17-BUG-1/2/3/4/5 all fixed).
- Feature verification: my file + `bloc` + `repository` + `geometry` +
  `states` → `+94: All tests passed!` (0 skip, 0 red).
- Process note (not a finding): the full feature-directory run currently
  hangs in the parallel test stage's brand-new
  `parental_gate_view_test.dart` test `persistence (IDS + TRIAL rules) …`
  (`did not complete`) — a FakeAsync/`runAsync` deadlock in a file being
  written right now, not a product issue; that file was green at the build
  stage (115 pass).

## Result

| ID | Severity | Status |
|---|---|---|
| P17-BUG-1 | Major (shared, router) | **fixed on `main`** (`shared/kid_trial_gate`, `0d7aa52`) — proof green and now non-vacuous |
| P17-BUG-2 | Minor | fixed (iteration 2) — proof green |
| P17-BUG-3 | Minor | fixed (iteration 2) — proof green |
| P17-BUG-4 | Minor (screen-local) | fixed (iteration 3) — proof green |
| P17-BUG-5 | Major (test integrity) | **found and fixed this stage** — proof green |

No open bug. The whole app suite is green (`+3036 ~2` at the build stage);
`SHARED_REQUEST.md` #1, #2 and #3 are all RESOLVED on `main`.

---

## P17-BUG-5 — major (test integrity, fixed this stage): the un-skipped P17-BUG-1 proof was vacuous

**Where:** `app/test/features/parental_gate/p17_bugs_test.dart` →
`_expireTrial` (the trial-age helper used by the P17-BUG-1 proof the
iteration-4 builders un-skipped).

**What happened:** the helper wrote
`trialStart = DateTime.now().toUtc() − 15 days` — the **real wall clock**.
But `AppSession` now defaults to `appNowUtc` (`app_session.dart:28`), which
`flutter_test_config.dart` + `app_clock.dart` pin to **Sat 3 Oct 2026
08:41Z**. At run time (4 Oct 09:17Z real) the write stored 19 Sep 09:17Z;
+14 days = 3 Oct 09:17Z, which is *after* the pinned now — so
`session.trialExpired` stayed **false**. The proof then opened
`/parental-gate` in kid mode with a live trial and passed on the plain
kid-reachable gate: `Grown-ups only`, no `redirect loop` text and
`currentPath == '/parental-gate'` all hold **without ever exercising the
expired-trial path**. A green proof that cannot fail is worse than a skip —
it would hide a regression of the shared fix.

**Evidence (probe, before the fix):**
`session: status=trial expired=false` while
`isTrialStartExpired(row.trialStart, DateTime.now().toUtc()) == true` and
`session.nowUtc == 2026-10-03 08:41:00.000Z` — the row aged against the
wall clock, the session against the pinned clock.

**Fix (test file only):** `_expireTrial` now ages from `session.nowUtc` and
asserts `session.trialExpired` is true, so the proof cannot go vacuous
again. A new end-to-end proof pins the shared flow:
`expired kid trial: kid home funnels to the gate, unlock pays`.

**Proofs:** `P17-BUG-1: kid mode + expired trial renders the gate` and
`expired kid trial: kid home funnels to the gate, unlock pays` — both green
with a genuinely expired trial.

## Shared fix (`shared/kid_trial_gate`) verified end-to-end

With the trial genuinely expired (`trialStart = session.nowUtc − 15d`,
`session.refresh()` flips `trial` → `expired`):

| Flow | Result |
|---|---|
| kid + expired + `/kid-home` | redirects to `/parental-gate`, gate renders |
| kid + expired + `/parental-gate` | gate renders, no error page, no loop |
| kid + expired + `/settings` (parent-only) | gate (kid guard) |
| unlock from the gate | parent mode, then `/paywall` (the orchestrator's "parent sees the paywall after the gate") |
| session | `subscription_status` flips `trial` → `expired` on refresh; the gate never writes the trial row |

## Iteration-4 view changes verified

- **Card centring** (`Column(mainAxisAlignment: center)` +
  `ConstrainedBox(minHeight: viewport)`, no `66` literal): 11
  ORCHESTRATOR_NOTES geometry pins still Δ0; 320/390/430 × 1.0/1.3 states
  suite green (no overflow).
- **Caption single owner** (failure state renders the note once, gap
  `s2 + gap2`); `Try again` now 56 (kid rule); failure state at 320 × 1.3
  still overflow-free.
- **Loading escape:** during `initial`/`loading` the card shows a real
  `Back to Pip` (56 px ghost) with `SemanticsAction.tap`; tapping it pops to
  `/kid-home` (probe).
- **Announcement re-base** regression (iteration 3) still green.
- **IDS rule:** P17 creates no rows — the only writes are the settings
  switch (update) and the app-mode flip through `AppSession`; the challenge
  id is a London-day-derived entity key, not a row id and not a clock
  timestamp. The rule does not apply (also confirmed by 2a).

## Verified clean (green probes)

| Area | Probe | Result |
|---|---|---|
| rapid double tap | two semantics activations of `Back to Pip` in one frame → one pop | pass |
| rapid double tap | two activations of the final correct digit on a pushed gate → one unlock, gate dismissed | pass |
| back navigation | system back from a pushed gate → `/kid-home`, mode still kid | pass |
| pushed unlock | correct answer → parent mode, gate dismissed (`pushedPath`, no `NestModal`), re-open works | pass |
| expired trial | kid home → gate → unlock → `/paywall` (BUG-5 end-to-end) | pass |
| disabled gate | pass-through pushed from kid home → parent mode, gate dismissed | pass |
| loading state | real `Back to Pip` escape with a tap action, pops to kid home | pass |
| failure state | `Try again` reloads; `Back to Pip` pops; 320 × 1.3 no overflow | pass |
| data edges | no children → `Hi there!` fallback; 1 child (Leo) → his own Pip (bolt · sky · stage 2) | pass |
| data edges | 6 children, `Maximilian-Alexander`, 9999 coins at 320 px → no overflow | pass |
| restart persistence | gate switch persists across repository instances | pass |
| keypad widths | 360 px shrink-wrap → 11 painted keys 69 px, no overlap | pass |
| timezone | BST start/end, London-midnight flip, GMT winter → one challenge per London day | pass |
| a11y | announcement re-bases on a challenge change | pass |
| async gap | settings change after the gate closes → no emit-after-close error | pass |
| dark contrast | ink/ink2 on surface ≥ 9:1, lilac on lilacTint ≥ 3.4:1 (decorative) | pass |
| money | N/A — no money on P17 (coins only; 0 and 9999 both render) | pass |

## Observations (not defects)

1. `4_review` findings 2 (backdrop reads `AppDatabase` via GetIt) and 5
   (each `Try again` opens a second `emit.forEach`) are carried: repository
   /bloc contract changes that contradict `1_plan.md` §(b).
2. Midnight re-key of an open gate — `watchItems()` is a Drift-only stream
   with no timer, by design; a gate is a seconds-long interaction.
3. Dead code: `parental_gate_placeholder_card.dart` (repo-wide v1 scaffold,
   unreferenced) and `ParentalGateChallengeModel`.
4. Parent-mode deep link + `Back to Pip` lands on `/kid-home` (kid UI in
   parent mode) — product-level question, same as K03's note.

## Verdict basis

No open bug. The one shared major (P17-BUG-1) is fixed on `main` and its
proof is now meaningful; the test-integrity defect that made it vacuous
(P17-BUG-5) was found and fixed in this stage, and the shared flow is
verified end-to-end. All other hunt areas are proven clean.

VERDICT: PASS
