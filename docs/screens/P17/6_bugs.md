# P17 Parental gate — bug hunt (Stage 6, iteration 2)

Adversarial pass over the iteration-2 build: data edge cases (0 / 1 / 6
children, long UK names, 0 / 9999 coins, empty lists), rapid double taps
(real and semantics), back navigation and deep links, restart persistence,
parent/kid mode guards, dark-mode contrast, text scale 1.3 + 320 px
overflow, async gaps / emit-after-close, Europe/London time (both BST
changes and GMT) and money rounding. No product code was changed in this
stage. No simulator was used (SIMULATORS rule; `flutter test` only).

- Proof file: `app/test/features/parental_gate/p17_bugs_test.dart` —
  **15 tests: 13 green + 2 skip-marked proofs** (P17-BUG-1 shared major,
  P17-BUG-4 screen-local minor). `flutter analyze` on the file: No issues
  found; `flutter test …p17_bugs_test.dart` → `+13 ~2`.
- Every proof was run unskipped once to confirm it fails, then re-skipped.
- No new major bug in the iteration-2 changes; the two iteration-1 minors
  are fixed and their proofs now run green.

## Result

| ID | Severity | Status |
|---|---|---|
| P17-BUG-1 | Major (shared, router) | open — filed `SHARED_REQUEST.md` #2; proof skip-marked |
| P17-BUG-2 | Minor | **fixed in iteration 2** — proof green (regression test) |
| P17-BUG-3 | Minor | **fixed in iteration 2** — proof green (regression test) |
| P17-BUG-4 | Minor (screen-local) | open — proof skip-marked; also pinned by 5_ui |

No blocker and no major **screen-local** bug. P17-BUG-1 is a shared
`app/lib/app/router.dart` defect the gate route participates in (P17 may not
edit shared code under RULES §1); it is filed for the orchestrator and
carried per the P07-BUG-8/9 and P08 precedent, so it does not block the
screen.

---

## P17-BUG-1 — major (shared): kid mode + expired trial is a redirect loop

**Where:** `app/lib/app/router.dart:120-124` (trial-expired redirect),
reached through `/parental-gate`; also breaks `/kid-home` and every kid
route. Byte-identical to `main` after the iteration-2 merge.

**Repro (proof: `P17-BUG-1: kid mode + expired trial renders the gate`,
skip-marked):** demo DB + aged trial (`subscription_status = 'trial'`,
`trial_start = now − 15 days`) + `AppSession.refresh()`; kid mode; open
`/parental-gate`. Expected: the gate renders (it is exempt from the
onboarding redirect and is the kid's only route to parent mode). Actual:
go_router's error page — `Page Not Found / GoException: redirect loop
detected /paywall => /parental-gate => /paywall / Go to home page`; every
kid route is stuck the same way.

**Suggested fix:** do not apply the paywall redirect in kid mode
(`if (!appMode.isKid && onboarded && session.trialExpired && …)`), or exempt
`ParentalGateRoutePaths.gate` from the trial-expired branch exactly as the
onboarding branch already exempts it. Filed in `SHARED_REQUEST.md` #2
(status updated this iteration: still unfixed).

## P17-BUG-4 — minor (screen-local): the backdrop header top-aligns its items

**Where:** `parental_gate_view.dart:364-367` — the `_GateBackdropBody`
header `Row` passes `crossAxisAlignment: CrossAxisAlignment.start`, where
the CSS is `.kb-top { display:flex; align-items:center; gap:12px;
padding-top:8px }`.

**Repro (proof: `P17-BUG-4: the backdrop header centres its items`,
skip-marked):** pump `/parental-gate` at 390×844, measure the avatar rect
(55…99) and the greeting rect. Expected: greeting and coin pill centred in
the 44 px row (greeting centre 77 ± 1). Actual: greeting centre 72, pill
centre 73 — 5 px / 4 px high. Confirmed independently by the 5_ui geometry
pin `the backdrop row centres its items like .kb-top`
(`parental_gate_geometry_test.dart`, greeting 72 vs 77).

**Suggested fix (one line):** drop the `crossAxisAlignment` argument (the
default is centre). Dimmed scenery — cosmetic, but the header is the only
backdrop strip the card does not cover.

## Iteration-1 fixes verified this iteration

- **P17-BUG-2 (challenge day) — FIXED.** `challengeFor` now reads the
  calendar day via `toFamilyZone(utc, defaultFamilyZoneId)`
  (`parental_gate_repository_impl.dart:43-58`) and `watchItems` uses
  `appNowUtc()`. The old proof runs green; a new BST-boundary probe passes
  both 2026 changes (BST start 29 Mar, end 25 Oct), the London-midnight flip
  and GMT winter.
- **P17-BUG-3 (stale entry) — FIXED.** `onData` resets
  `entered`/`attempts`/`unlocked` when the challenge id changes and keeps
  them on same-challenge re-emits (`parental_gate_bloc.dart:24-45`). Proof
  green.
- **3_test §3.1 (unlock never dismissed a pushed gate) — FIXED.** `_unlock`
  now pops first and flips the mode after (`parental_gate_view.dart:36-58`);
  the green probe asserts `pushedPath == '/kid-home'`, no `NestModal`, parent
  mode, and that re-opening the gate from the lock still works.

## Verified clean (green probes)

| Area | Probe | Result |
|---|---|---|
| rapid double tap | two semantics activations of `Back to Pip` in one frame → one pop | pass |
| rapid double tap | two activations of the final correct digit on a pushed gate → one unlock, gate dismissed, no error | pass |
| back navigation | system back from a pushed gate → `/kid-home`, mode still kid | pass |
| pushed unlock | correct answer → parent mode, gate dismissed (`pushedPath`, no `NestModal`), re-open works | pass |
| disabled gate | pass-through pushed from kid home → parent mode, gate dismissed | pass |
| failure state | `Try again` has a tap action and reloads; `Back to Pip` pops to kid home | pass |
| data edges | no children (`Seed.empty`) → `Hi there!` fallback + usable gate | pass |
| data edges | 1 child (Leo) → his own Pip from the DB (bolt · sky · stage 2 · none), `Hi Leo!` | pass |
| data edges | unknown active-child id → falls back to the first child (Maya, CHILD ORDER) | pass |
| data edges | 6 children, `Maximilian-Alexander`, 9999 coins at 320 px → no overflow | pass |
| timezone | BST start/end, London-midnight flip, GMT winter → one challenge per London day | pass |
| async gap | settings change after the gate closes → no emit-after-close error | pass |
| 320 + 1.3 | failure state at 320 px × textScale 1.3 → no overflow, both buttons present | pass |
| dark contrast | tokens: ink/ink2 on surface ≥ 9:1, lilac on lilacTint ≥ 3.4:1 (decorative icon) | pass |
| money | N/A — no money on P17 (coins only; 0 and 9999 both render) | pass |

## Known shared blocker (not a new finding)

The remaining keypad reds in `parental_gate_geometry_test.dart` —
`the bands below the keypad match the design` (card bottom/height +26,
keypad rows 2–4, cancel, caption) and `the keypad follows the HTML grid gap
(pitch 82)` (row pitch 88 vs 82, column pitch 96 vs 88) — are entirely
inside the shared `NestKeypad` (`app/lib/core/design_system/components/`),
already filed as `SHARED_REQUEST.md` #3 with measurements and a patch. No
call-site change can fix the row pitch (row 2 is already +6 inside the
component) and forking a local keypad is forbidden. ORCHESTRATOR_NOTES
(07:13) confirms the fix is in flight on `shared/keypad_grid` and must match
the CSS `.keypad`; do not re-space keys locally — re-check the key centres
against the design once main has it. Not a P17-local bug.

**Watch item on that request's proposed patch:** the suggestion drops the
CSS `padding: 8px 24px 0` horizontal 24 px ("padding only top 8"). With
Expanded columns, the column pitch then becomes `(W − 20)/3 + 10`, i.e.
~102 at the current 296 slot / ~104 at the card's 302 content — not the
design's 88. Matching the CSS grid (which is what the 07:13 note asks for)
means keeping the 24 px horizontal padding: `(302 − 68)/3 + 10 = 88`. Worth
checking against the geometry pins when the shared fix lands.

## Observations (not defects)

1. **`_announcedAttempts` is not reset when the state's `attempts` resets.**
   The BUG-3 fix sets `attempts: 0` on a challenge change, but the view's
   announcement counter keeps its high-water mark, so the first wrong
   answers on the new challenge are silent. Reachable only if the settings
   row changes while the gate is open (or the gate is open across a settings
   write after midnight). A11y edge; suggest resetting the counter when
   `state.challenge?.id` changes.
2. **Loading has no cancel** (a 56 px slot is reserved but empty); only the
   system back gesture leaves the loading state. Drift's `watchSetting`
   emits promptly and errors land in the failure state, so it is transient.
   Plan-level, already recorded by 3_test §3.3.1.
3. **`Try again` is 44 px on a kid screen** (plan-mandated); DESIGN_SPEC kid
   rules ask for ≥56. Plan/DS question, recorded by 3_test §3.3.2.
4. Dead code: `presentation/widgets/parental_gate_placeholder_card.dart`
   and the unused `ParentalGateChallengeModel` (round-trip tested).
5. Parent-mode deep link + `Back to Pip` lands on `/kid-home` (kid UI in
   parent mode) — product-level question, same as K03's note.

## Verdict basis

No blocker and no major screen-local bug: the two iteration-1 minors are
fixed and proven, the new screen-local finding is minor and proven, and the
one major (P17-BUG-1) is a shared router defect filed and carried per the
P07/P08 precedent (RULES §1 forbids P17 from editing `app/lib/app/router.dart`).
The remaining red geometry pins trace to the shared keypad (request #3).
All other hunt areas are clean.

VERDICT: PASS
