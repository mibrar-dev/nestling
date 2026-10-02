# K03 Kid home — bug hunt (Stage 6, iteration 2)

Adversarial pass over `kid_home` K03 after the iteration-2 fixes and the
main-branch PERIODS ruling: data edges, rapid double taps, back navigation,
deep links, restart persistence, mode guards, dark contrast, 320px + 1.3
scale, async gaps, Europe/London periods (daily/weekly/once, BST edges) and
integer money. No screen code was changed in this stage.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 33 tests:
  32 run green, 1 skipped (`K03-BUG-7` needs its flag-specific run).
- Iteration-1 proofs K03-BUG-1..6 all run un-skipped and pass.
- K03-BUG-8 and K03-BUG-9 were fixed mid-loop by the concurrent iteration
  and their proofs now run un-skipped.
- Re-verified after the main merge `f6b02d8` (PipAvatar fallback art for
  every style, recoloured to the child's skin): K03's still path uses
  `mochi/s3_idle_1.svg`; new probes assert the mandated Pip attributes for
  Maya and Leo and the pipStage 0/9 clamp.
- Run the motion-flag proof:
  `flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name "K03-BUG-7"`.

## Iteration-1 bugs — fixed and re-verified

| ID | Severity | Fix landed | Proof (green) |
|---|---|---|---|
| K03-BUG-1 | Major | `completeQuest` is idempotent inside a Drift transaction; per-card `_busy` latch blocks the second event in the same frame | repo + widget double-tap proofs |
| K03-BUG-2 | Moderate | celebration navigation rides `justCompletedQuestId` (success only); failed write keeps the list + SnackBar | failed-completion proof |
| K03-BUG-3 | Minor | `actionNonce` makes every failure a distinct state; reset on completion start / healthy stream | double-failure proof |
| K03-BUG-4 | Moderate | main PERIODS ruling: `watchItems` scopes status via `countsForCurrentPeriod` (daily/weekly/once); day-boundary proof now un-skipped | day-boundary proof + new period probes |
| K03-BUG-5 | Moderate | main router gates `/today-empty`, `/quest-editor`, `/add-children`, `/pocket-money-setup` from kid mode | both deep-link proofs |
| K03-BUG-6 | Minor | per-card `_busy` latch covers card body + check; one route per gesture burst | both route-stacking proofs |

## New bugs (iteration 2)

### K03-BUG-7 — `DISABLE_ANIMATIONS=1` does not disable animations

**Severity: Major (shared; motion rule + screenshot determinism).**
Where: `app/lib/core/data/env_flags.dart` (`kDisableAnimations`),
`app/lib/app/launch_flags.dart` (`disableAnimations`). RULES §6 and
`tools/screens/shot.sh` both document/pass `--dart-define=DISABLE_ANIMATIONS=1`,
but `bool.fromEnvironment` only treats the literal `"true"` as true — `"1"`
parses as **false**. Nothing else sets `MediaQueryData.disableAnimations`, so
on device every motion path that checks the compile-time flag believes
animations are enabled.

Repro:
1. `cd app && flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name "K03-BUG-7" test/features/kid_home/k03_bugs_test.dart`
   → `Expected: true, Actual: false`.
2. On the simulator, `tools/screens/shot.sh` (which always passes `=1`)
   captures K03 with the live Rive `PipAvatar` running; the harness prints
   `WARNING — frame never stabilised in 25 s` in **both** iteration-1 and
   iteration-2 UI runs. With Rive idle motion there is never a stable frame.
3. Control: `--dart-define=DISABLE_ANIMATIONS=true` makes the proof pass and
   the `PipAvatar` build takes the static SVG fallback
   (`reduceMotion || !riveEnabled` → `_PipAvatarSvgFallback`).

Failing test:
- `K03-BUG-7: the documented DISABLE_ANIMATIONS=1 flag must disable motion`
  (skipped in the plain suite; runs and fails under the documented flag).

Suggested fix (shared): treat `"1"` as true, e.g.
`String.fromEnvironment('DISABLE_ANIMATIONS') == '1' || bool.fromEnvironment('DISABLE_ANIMATIONS')`
in `env_flags.dart` (and `launch_flags.dart`), and ideally set
`MediaQueryData.disableAnimations` from it once at the app root so every
motion path obeys the same switch. Passing `=true` in `shot.sh` is a one-line
workaround. Filed as SHARED_REQUEST #5.

### K03-BUG-8 — A failed later tap swallowed an earlier success (fixed mid-loop)

**Severity: Minor (UX; no data loss).**
Where: `kid_home_bloc.dart` `_awaitingCelebration` was a single record; two
quick completions of different quests overwrote each other, and if the second
write failed the first quest's flip was never celebrated.

Repro (proof): gate the first `completeQuest`; tap quest A, tap quest B;
release A (card flips while the pending slot already holds B); fail B.
Actual before the fix: `state.justCompletedQuestId == null` (A never
celebrated). Fixed during this stage by keying the pending map per quest
(`Map<String,int>` + first-flip-wins loop); the proof now runs un-skipped.

Failing test (now green):
- `K03-BUG-8: a failed second completion swallows the first success (no celebration)`

### K03-BUG-9 — Double-tapping the lock stacked two gate routes (fixed mid-loop)

**Severity: Minor (back-stack UX).**
Where: `kid_home_view.dart` — the lock pushed `/parental-gate` with no
per-tap latch (unlike `_QuestCard`); the lock is a 56px kid target, so a
fast double tap is realistic.

Repro: open `/kid-home`, tap "Grown-ups" twice inside one frame.
Actual before the fix: two `/parental-gate` routes were pushed; one system
back press left the user on the second gate instead of returning home.
Fixed during this stage with a `_GateLockButton` stateful wrapper whose
`_busy` latch wraps `context.push(gate)` in `try/finally`; the proof now
runs un-skipped.

Failing test (now green):
- `K03-BUG-9: double-tapping the lock stacks two gate routes`

## Verified clean (probes in the same file)

| Category | Probe | Result |
|---|---|---|
| periods | day/week starts inclusive, older excluded; daily/weekly/once; explicit BST→GMT (25 Oct) and GMT→BST (29 Mar) switch days | pass |
| mandated Pip | home renders `PipAvatar` with Maya = mochi/sunny/none/stage 3; Leo deep-link = bolt/sky/stage 2; pipStage 0 → 1 and 9 → 4 (clamped, no assert) | pass |
| period + repo | daily completion 1s before the London day start → to_do, at the start → approved; weekly outside the week → to_do; once 400 days old → approved | pass |
| retry | failed completion → SnackBar, no celebration; retry after the failure → K05 opens | pass |
| 0 children | `Seed.empty` → "Who's playing?" + Choose | pass |
| 1 child / 6 children | Leo removed / four extra children: Maya's home unchanged | pass |
| long UK name | "Maximilian-Alexander" + 9999 coins at 320px / scale 1.3 | pass |
| £0.00 / £999.99 | coins only; `+0` for a zero-coin quest, no `£` anywhere | pass |
| back navigation | check → K05 → back → home with the card flipped to "Waiting for Mum" | pass |
| deep links | `/kid-home` kid mode with/without active child; `/kid-home` in parent mode still deliberate (see observations) | pass |
| restart | Drift file DB closed/reopened: completion still `done_pending` | pass |
| guard | `/today`, `/today-empty`, `/quest-editor`, `/add-children`, `/pocket-money-setup` all redirect to the gate in kid mode | pass |
| dark contrast | 16 K03 token pairs ≥ 4.5:1 in both themes | pass |
| async gap | late `completeQuest` failure after `bloc.close()` does not throw | pass |
| money rounding | integer coins only; pence arithmetic lives in the parent money screens | pass |

## Observations (checked, not raised as bugs)

1. **Period rollover without a DB change.** `watchItems` computes status at
   stream-map time; at London midnight a daily completion stops counting only
   when the stream re-emits (any DB write) or the screen reloads. There is no
   day-tick timer and no injectable clock, so this cannot be proven in-suite;
   worth a foundation tick if kids keep the app open overnight.
2. **Test-suite wall-clock coupling.** `test/flutter_test_config.dart` pins
   `Seed.anchorOverride` to Sat 3 Oct 2026 but nothing pins `DateTime.now()`,
   which both `watchItems` and `completeQuest` use. The demo "4 of 6" and the
   period proofs stay deterministic only while the machine clock is in the
   same London day/week as the pinned anchor; a clock seam
   (`DateTime Function() now` or `package:clock`) would make it robust.
3. **`inNest` note vs composition.** ORCHESTRATOR_NOTES #1 asks for
   `PipAvatar(..., inNest true)`; the screen renders the child's `PipAvatar`
   (Mochi/sunny/stage 3, attributes from the DB) at 152px over the `nest`
   art instead, which matches the measurable slot requirements (Pip 152 on a
   260×236 nest) and avoids double-nesting with the Rive `PipStage` artboard.
   Stage 5 accepted the result (A3); flagged here only for traceability.
4. **Parent mode → `/kid-home`.** Still reachable by deep link; the spec
   guard is one-way (kid → parent/gate) and there is no in-app parent entry.
5. **PIN bypass.** `/kid-home` in kid mode does not require the K02 PIN;
   K01/K02 are placeholders owned by other K screens, so no PIN state exists
   to enforce yet.
6. **Debug routes in kid mode.** `/design-system`, `/motion-lab`, `/pip-lab`
   are not in the guard list (debug-only entry points).
7. **Leo's icon fallback.** `paw`/`bag`/`leaf` icons still fall back to the
   generic quest-card glyph (`_iconFor`); per plan, design shows Maya only.
8. **Accessories in the still frame.** The merged `f6b02d8` fallback
   (`_PipAvatarSvgFallback`) recolours by skin but takes no accessory, so
   under `DISABLE_ANIMATIONS`/reduced motion a child wearing a bow/cap/
   scarf/glasses shows the bare idle art. Neither seed child equips one
   today, so no design impact; a golden/screenshot check with an accessorised
   child would be needed to raise it as a defect (shared component).

## Summary

| ID | Severity | Area | Status |
|---|---|---|---|
| K03-BUG-1 | Major | duplicate pending completions / double payout | fixed, proof green |
| K03-BUG-2 | Moderate | celebration before successful save | fixed, proof green |
| K03-BUG-3 | Minor | swallowed repeat failure feedback | fixed, proof green |
| K03-BUG-4 | Moderate | "done today" period semantics | fixed (main ruling), proof green |
| K03-BUG-5 | Moderate | kid-mode guard misses parent routes | fixed on main, proofs green |
| K03-BUG-6 | Minor | stacked duplicate routes on double tap | fixed, proofs green |
| K03-BUG-7 | **Major** | `DISABLE_ANIMATIONS=1` parses false → Rive Pip never still, screenshots never stabilise | **open (shared)** |
| K03-BUG-8 | Minor | in-flight failure swallowed an earlier celebration | fixed mid-loop, proof green |
| K03-BUG-9 | Minor | double-tap on the lock stacked gate routes | fixed mid-loop, proof green |

The screen itself is in good shape: every iteration-1 bug is fixed and
re-verified, period semantics now match the ruling, and the new edge probes
pass. The one major finding is shared infrastructure (K03-BUG-7): the
documented still-frame flag silently parses as false, so K03's Rive Pip
keeps animating on device and the UI stage's screenshots cannot stabilise.
Until that flag (or `shot.sh`) is fixed, the screenshot evidence is a random
animation frame and RULES §6 is not actually satisfied on device.

VERDICT: FAIL
