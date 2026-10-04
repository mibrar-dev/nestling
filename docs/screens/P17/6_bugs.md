# P17 Parental gate — bug hunt (Stage 6, iteration 1)

Adversarial pass over `parental_gate` P17 as built in iteration 1: data edge
cases (0 / 1 / 6 children, long UK names, 0 / 9999 coins, empty lists), rapid
double taps (real and semantics), back navigation and deep links, restart
persistence, parent/kid mode guards, dark-mode contrast, text scale 1.3 +
320 px overflow, async gaps / emit-after-close, Europe/London time (BST),
and money rounding. No screen code was changed in this stage. No simulator
was used (SIMULATORS rule; `flutter test` only).

- Proof file: `app/test/features/parental_gate/p17_bugs_test.dart` —
  11 tests: 8 green probes + **3 skip-marked proofs** (one per open bug).
  `flutter analyze` on the file: No issues found.
- Reproduced with the app's own repository/DB/router; the only fakes are the
  loading/failure stream stubs (feature-local, fixed 3×9 challenge).
- Verified this stage: `flutter test test/features/parental_gate/p17_bugs_test.dart`
  → `+8 ~3: All tests passed!`.
- Note: the whole `test/features/parental_gate/` directory was red while this
  stage ran because parallel stages were mid-edit (the iteration-2 geometry
  pins that await the UI fix, and a `SemanticsHandle` leak in the rewritten
  view test). Those are other stages' in-flight work, not findings here; this
  file alone is green.

## Result

| ID | Severity | Status |
|---|---|---|
| P17-BUG-1 | Major (shared, router) | open — filed in `SHARED_REQUEST.md`; proof skip-marked |
| P17-BUG-2 | Minor | open — proof skip-marked (also `4_review.md` finding 6) |
| P17-BUG-3 | Minor | open — proof skip-marked |

No blocker and no major **screen-local** bug. P17-BUG-1 is a shared
`app/lib/app/router.dart` defect that the gate route participates in (P17 may
not edit shared code under RULES §1); it is filed for the orchestrator and
carried per the P07-BUG-8/9 and P08 precedent, so it does not block the
screen.

---

## P17-BUG-1 — major (shared): kid mode + expired trial is a redirect loop

**Where:** `app/lib/app/router.dart` (redirect), reached through
`/parental-gate`; also breaks `/kid-home` and every kid route.

**Repro (proof: `P17-BUG-1: kid mode + expired trial renders the gate`,
skip-marked):**
1. Demo DB, then persist an aged trial (`subscription_status = 'trial'`,
   `trial_start = now − 15 days`) and `AppSession.refresh()` — expiry is
   enforced (shared_batch3), so `session.trialExpired == true`.
2. Kid mode (`AppModeController.selectMode(kid)`), open `/parental-gate`.
3. Expected: the gate renders (the router already exempts the gate from the
   onboarding redirect; the gate is the kid's only route to parent mode,
   where the paywall then fires).
4. Actual: go_router never settles — the screen is its error page:
   `Page Not Found / GoException: redirect loop detected /paywall =>
   /parental-gate => /paywall / Go to home page`. `/kid-home` ends on the
   same error page.

**Why:** in kid mode the trial-expired branch returns `/paywall`;
`/paywall` is parent-only in kid mode, so the kid-mode branch returns
`/parental-gate`; the gate hits the trial-expired branch again — a two-state
loop. `router.dart` is identical on `main`, so this is live for any kid-mode
user whose 14-day trial has aged out.

**Suggested fix:** do not apply the paywall redirect in kid mode, e.g.
`if (!appMode.isKid && onboarded && session.trialExpired && location !=
PaywallRoutePaths.paywall) return PaywallRoutePaths.paywall;` — or exempt
`ParentalGateRoutePaths.gate` from the trial-expired branch exactly as the
onboarding branch already exempts it. Filed in `SHARED_REQUEST.md`.

## P17-BUG-2 — minor: the daily challenge ignores the Europe/London day

**Where:** `app/lib/features/parental_gate/data/parental_gate_repository_impl.dart`
(`challengeFor`, `watchItems`).

**Repro (proof: `P17-BUG-2: the challenge follows the Europe/London day
(BST)`, skip-marked):** the challenge must be stable across one London day.
London 00:30 BST on 4 Oct 2026 is `2026-10-03T23:30Z`; London 12:00 BST is
`2026-10-04T11:00Z`. Expected: same challenge (same `id`, same question).
Actual: `id` `2026-10-3` vs `2026-10-4` — different questions on the same
London day.

**Why:** the day key is the UTC calendar date (`utc.day + utc.month * 31`,
id from UTC y/m/d) while every other period in the app is Europe/London
(PERIODS ruling; `Seed.anchorDay` is London). During BST the question flips
at 01:00 London, not at the London midnight, and a gate left open never
re-keys at all (the settings stream does not re-emit at midnight). Same
issue flagged as a note in `4_review.md` finding 6.

**Suggested fix:** derive the day from `toFamilyZone(now,
defaultFamilyZoneId)` (as `Seed.anchorDay` does) and keep `now` from the
app clock (`appNowUtc()` once the shared clock pin merges).

## P17-BUG-3 — minor: a challenge change keeps the stale typed entry

**Where:** `app/lib/features/parental_gate/presentation/bloc/parental_gate_bloc.dart`
(`_onLoadRequested` `onData`).

**Repro (proof: `P17-BUG-3: a challenge change resets the typed entry`,
skip-marked):** load 7×6, type `4`, then have `watchItems()` emit a new
challenge (3×9). Expected: the boxes reset (the digits belonged to the old
question). Actual: `entered` is still `'4'` (and `attempts` is kept) against
the new challenge, so the boxes show a digit that is not part of the new
answer and the next digit verifies a mixed entry. Reachable whenever the
settings row changes while the gate is open (any P16 settings write
re-emits `watchSetting`).

**Suggested fix:** in the `onData` handler, when `items.first.id` differs
from `state.challenge?.id`, reset `entered: ''` (and `attempts: 0`).

---

## Verified clean (green probes, same hunt)

| Area | Probe | Result |
|---|---|---|
| rapid double tap | two semantics activations of `Back to Pip` in one frame → one pop, mode unchanged | pass |
| back navigation | system back from a pushed gate → `/kid-home`, mode still kid | pass |
| pushed unlock | correct answer on a gate pushed from K03 → parent mode + `/kid-home`, no error | pass |
| failure state | `Try again` has a tap action and reloads; `Back to Pip` pops to kid home | pass |
| data edges | no children (`Seed.empty`) → `Hi there!` fallback + usable gate | pass |
| data edges | 6 children, `Maximilian-Alexander`, 9999 coins at 320 px → no overflow | pass |
| async gap | settings change after the gate closes → no emit-after-close error | pass |
| 320 + 1.3 | failure state at 320 px × textScale 1.3 → no overflow, both buttons present | pass |
| dark contrast | tokens: ink/ink2 on surface ≥ 9:1, lilac on lilacTint ≥ 3.4:1 (decorative icon) | pass |
| money | N/A — no money on P17 (coins only; 0 and 9999 both render) | pass |

## Observations (not defects)

1. After a pushed-gate unlock the app pops back to `/kid-home` **in parent
   mode**; kid home is not guarded against parent mode. The P17 plan
   specifies this pop and K03's notes already carry "parent-mode /kid-home"
   as a product-level question — recorded, not raised.
2. The loading state has no `Back to Pip` (only system back). Drift's
   `watchSetting` emits promptly and errors land in the failure state, so
   this is a transient-only gap; the plan's loading design does not include
   a cancel.
3. `ParentalGateState.copyWith` cannot clear `errorMessage` to null (it
   persists after a retry, but is never displayed once loaded) — harmless.
4. `presentation/widgets/parental_gate_placeholder_card.dart` and
   `ParentalGateChallengeModel` are unused leftovers; dead code, not a bug.
5. Parent-mode deep link + `Back to Pip` lands on `/kid-home` (kid UI in
   parent mode) — product-level question, same family as observation 1.

## Verdict basis

No blocker, no crash and no data-loss bug; the two screen-local findings are
minor and skip-proven. The one major (P17-BUG-1) is a shared router defect
filed in `SHARED_REQUEST.md` and carried per the P07/P08 precedent, since
RULES §1 forbids P17 from editing `app/lib/app/router.dart`. All other hunt
areas are proven clean by the green probes above.

VERDICT: PASS
