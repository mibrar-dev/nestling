# P17 Parental gate — bug hunt (Stage 6, iteration 3)

Adversarial pass over the iteration-3 build: data edge cases (0 / 1 / 6
children, long UK names, 0 / 9999 coins, empty lists), rapid double taps
(real and semantics), back navigation and deep links, restart persistence,
parent/kid mode guards, dark-mode contrast, text scale 1.3 + 320 px and
intermediate widths, async gaps / emit-after-close, Europe/London time (both
BST changes and GMT) and money rounding. No product code was changed in this
stage. No simulator was used (SIMULATORS rule; `flutter test` only).

- Proof file: `app/test/features/parental_gate/p17_bugs_test.dart` —
  **18 tests: 17 green + 1 skip-marked proof** (P17-BUG-1, the shared router
  loop). `flutter analyze` on the file: No issues found;
  `flutter test …p17_bugs_test.dart` → `+17 ~1`.
- Feature suite: `flutter test test/features/parental_gate` →
  `+119 ~1: All tests passed!` — **0 red** (iteration 2 ended 2 red on the
  shared keypad; `main`'s `shared/keypad_grid` merge closed them). The count
  grew from the build stage's 106 as parallel stages added their own tests
  while this stage ran; the skip is P17-BUG-1.
- No new bug found in the iteration-3 changes; all three earlier bugs are
  fixed and their proofs run green as regression tests.

## Result

| ID | Severity | Status |
|---|---|---|
| P17-BUG-1 | Major (shared, router) | open — filed `SHARED_REQUEST.md` #2; proof skip-marked |
| P17-BUG-2 | Minor | **fixed (iteration 2)** — proof green |
| P17-BUG-3 | Minor | **fixed (iteration 2)** — proof green |
| P17-BUG-4 | Minor (screen-local) | **fixed (iteration 3)** — proof green |

No blocker and no major **screen-local** bug. P17-BUG-1 is a shared
`app/lib/app/router.dart` defect the gate route participates in (P17 may not
edit shared code under RULES §1); it is filed for the orchestrator and
carried per the P07-BUG-8/9 and P08 precedent, so it does not block the
screen.

---

## P17-BUG-1 — major (shared): kid mode + expired trial is a redirect loop

**Where:** `app/lib/app/router.dart:120-124` (trial-expired redirect),
reached through `/parental-gate`; also breaks `/kid-home` and every kid
route. Still byte-identical to `main` after the iteration-3 merge.

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
onboarding branch already exempts it. Filed in `SHARED_REQUEST.md` #2.

## Iteration-3 changes verified

- **Shared keypad grid (`shared/keypad_grid` via `main`) — request #3
  resolved.** `NestKeypad` now reproduces CSS `.keypad` (1fr columns, 10 px
  gaps, `8 24 0` padding, 72 px keys); the P17 call site chooses stretch at
  card content ≥ `NestKeypad.contentWidth` (284) and shrink-wrap + FittedBox
  below it. The 11 ORCHESTRATOR_NOTES geometry pins are green at Δ0; my
  independent probe at 360 px (shrink-wrap path) measures 11 painted keys of
  69.0 px with no overlap — ≥56 as required.
- **P17-BUG-4 fixed:** the backdrop header Row no longer passes
  `crossAxisAlignment: start`, so `.kb-top { align-items: center }` holds;
  the proof runs green (greeting centre now equals the avatar centre).
- **6_bugs observation 1 fixed:** `_announcedChallengeId` re-bases the
  wrong-answer announcement counter when the live challenge changes. New
  regression proof: wrong answer on 7×6 (announce 1) → challenge switches to
  3×9 → wrong answer on 3×9 announces again (2 total).
- **Loading card height:** `_GateLoading` now reserves the CSS-grid keypad
  height (326) and no longer double-counts the caption gap; the
  "loading placeholders keep the loaded card height" pin is green.

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
| data edges | 1 child (Leo) → his own Pip from the DB (bolt · sky · stage 2 · none) | pass |
| data edges | 6 children, `Maximilian-Alexander`, 9999 coins at 320 px → no overflow | pass |
| restart persistence | gate switch persists across repository instances | pass |
| keypad widths | 360 px (shrink-wrap) → 11 painted keys 69 px, no overlap, no exception | pass |
| timezone | BST start/end, London-midnight flip, GMT winter → one challenge per London day | pass |
| a11y | announcement re-bases on a challenge change (obs 1 regression) | pass |
| async gap | settings change after the gate closes → no emit-after-close error | pass |
| 320 + 1.3 | failure state at 320 px × textScale 1.3 → no overflow, both buttons | pass |
| dark contrast | tokens: ink/ink2 on surface ≥ 9:1, lilac on lilacTint ≥ 3.4:1 (decorative icon) | pass |
| money | N/A — no money on P17 (coins only; 0 and 9999 both render) | pass |

## Out of scope (not P17 findings)

The whole-app suite still has 8 reds, all in `app/test/features/kid_home/**`
(P17 may not edit other features' tests): 7 assert the v1 scaffold title
`P17 Parental gate` and 1 calls `tester.pageBack()` expecting an AppBar back
button — both were supplied by the scaffold P17 replaced. One-line fixes per
site are written up in `SHARED_REQUEST.md` #1 with line numbers.

## Observations (not defects)

1. Loading has no cancel (a 56 px slot is reserved but empty); only the
   system back gesture leaves the loading state. Drift's `watchSetting`
   emits promptly and errors land in the failure state, so it is transient.
   Plan-level, recorded by 3_test §3.3.1.
2. `Try again` is 44 px on a kid screen (plan-mandated); DESIGN_SPEC kid
   rules ask for ≥56. Plan/DS question, recorded by 3_test §3.3.2.
3. Dead code: `presentation/widgets/parental_gate_placeholder_card.dart`
   (the repo-wide v1 scaffold, unreferenced in 11 features).
4. Parent-mode deep link + `Back to Pip` lands on `/kid-home` (kid UI in
   parent mode) — product-level question, same as K03's note.

## Verdict basis

No blocker and no major screen-local bug: all three earlier findings are
fixed and proven, iteration-3's changes are verified by green probes, and the
feature suite is fully green (106 pass / 1 honest skip). The one major
(P17-BUG-1) is a shared router defect filed and carried per the P07/P08
precedent (RULES §1 forbids P17 from editing `app/lib/app/router.dart`).

VERDICT: PASS
