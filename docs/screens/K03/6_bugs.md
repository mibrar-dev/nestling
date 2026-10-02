# K03 Kid home — bug hunt (Stage 6, iteration 4)

Adversarial pass over `kid_home` K03 after the iteration-4 bottom-chrome fix:
data edges, rapid double taps, back navigation, deep links, restart
persistence, mode guards, dark contrast, 320px + 1.3 scale, async gaps,
Europe/London periods (daily/weekly/once, BST edges), integer money, and the
owner rules (bar surface to the screen edge, 20px alignment).
No screen code was changed in this stage.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 39 tests:
  37 run green, 2 skipped (`K03-BUG-7` needs its flag-specific run,
  `K03-BUG-11` is open).
- Run the open proofs:
  `cd app && flutter test --run-skipped --plain-name "K03-BUG-11"` and
  `flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name "K03-BUG-7"`.
- Full-suite state: `flutter test` → `+477 ~2, All tests passed!` (the two
  skips are the proofs above).

## Iteration-4 result: K03-BUG-10 is fixed

The dock's surface `Container` now wraps `SafeArea(top: false)`
(`kid_home_view.dart` bottom chrome), so the inset is painted with the bar's
own colour. Both proofs run un-skipped and pass:
- `K03-BUG-10: the dock surface must run to the physical bottom edge` (light)
- `K03-BUG-10 dark: the dock surface must also reach the edge in dark mode`
- Independently: the two stage-3 view tests ("light/dark: the dock owns the
  OS bottom inset") now pass, and UI iteration 4 measures dock surface from
  y≈810 to the physical edge, no green strip.

## Open bugs

### K03-BUG-7 — `DISABLE_ANIMATIONS=1` still parses as false

**Severity: Major (shared; motion rule + screenshot determinism).**
`5eea2ad` wired `kDisableAnimations` into `MediaQuery.disableAnimations` at
the app root, but `kDisableAnimations` itself is still
`bool.fromEnvironment('DISABLE_ANIMATIONS')`
(`app/lib/core/data/env_flags.dart:9`), which only understands `"true"`.
With the documented `=1` the flag stays false, the MediaQuery wiring never
fires, the Rive `PipAvatar` keeps animating and `shot.sh` still warns
"frame never stabilised in 25 s" (iterations 1–4 captures).

Repro:
- `cd app && flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name "K03-BUG-7" test/features/kid_home/k03_bugs_test.dart`
  → `Expected: true, Actual: <false>` (asserts both `kDisableAnimations` and
  `MediaQuery.disableAnimationsOf` at the home).
- Control: passes with `--dart-define=DISABLE_ANIMATIONS=true`, proving the
  app-root wiring itself is correct.

Failing test (skipped in the plain suite):
- `K03-BUG-7: the documented DISABLE_ANIMATIONS=1 flag must disable motion`

Suggested fix (shared, SHARED_REQUEST #5): parse `"1"` as true in
`env_flags.dart`, e.g.
`bool.fromEnvironment('DISABLE_ANIMATIONS') || String.fromEnvironment('DISABLE_ANIMATIONS') == '1'`,
mirror in `launch_flags.dart`, or pass `=true` from `shot.sh` / RULES.

### K03-BUG-11 — A silent no-op completion leaves the check latched

**Severity: Minor (feature-local).**
Where: `kid_home_repository_impl.dart` `completeQuest` returns **silently**
when the quest row has vanished (`if (quest == null) return;`), while
`kid_home_view.dart` `_QuestCardState._busy` only resets on a status flip or
a `completionToken` (failure) change. A silent no-op produces neither, so
the check stays dead and the bloc's `_awaitingCelebration` entry lingers
(a later stream flip of that quest id would then celebrate a write this tap
did not make). Also recorded as review finding #6.

Repro: fake repository whose `completeQuest` records the call and returns
without error and without flipping anything; tap the "Mark done" check
twice. The second tap must reach the repository (retry), but the latch
swallows it.

Failing test (skipped so the suite stays green):
- `K03-BUG-11: a silent no-op completion leaves the check latched`
  (expected 2 recorded calls, actual 1).

Suggested fix: treat "write returned without a flip" as a terminal outcome —
e.g. after `await _repository.completeQuest(...)`, verify the quest is done
in the next emission and otherwise evict the pending entry plus bump
`actionNonce` (so the card's latch resets and the SnackBar shows); or throw
a not-found error from the repository so the existing failure path handles
it. The card could also reset `_busy` when the bloc clears that quest's
pending celebration.

## Carried open items (owned by other stages, not re-proven here)

| Source | Severity | Item | Owner |
|---|---|---|---|
| 4_review finding 1 | Major | local forks (`_KidPetStage`, `_SpeechBubble`, `_HeartIcon`, `_MeadowPainter`) must be replaced by the new shared `NestPetStage(pip:)` / `NestSpeechBubble` / `NestHeart` / `KidScope` meadow (mandatory in ORCHESTRATOR_NOTES) | iteration-5 build |
| 4_review finding 10 | Major | K03-BUG-7 above | shared |
| 5_ui iteration 4 dev 1 | Moderate (dark only) | dark lower-content meadow band missing behind progress/cards (flat navy; light renders green) | iteration-5 build |
| 5_ui iteration 4 dev 2/3 | Minor | upper-stack residuals (hearts +12, progress +8, card-1 +4, green start +38) and dock top −6px vs target y≈720 | iteration-5 build |

## Verified clean (probes in the same file)

| Category | Probe | Result |
|---|---|---|
| bottom edge | light + dark: a surface-filled box spans full width to the physical edge under the 34px inset | pass |
| alignment | 20px gutters: progress bar, first card, dock buttons share x=20 / x=370 | pass |
| state art | failure and empty-quests states render `PipAvatar`, no `pip_stage_*.svg` | pass |
| mandated Pip | Maya = mochi/sunny/none/stage 3; Leo = bolt/sky/stage 2, `2 done today` / `2 of 4 done` (seed `e972b46`); pipStage 0/9 clamped | pass |
| periods | day/week starts inclusive; daily/weekly/once; BST/GMT switch days | pass |
| period + repo | daily just before the start → to_do, at the start → approved; weekly outside → to_do; once 400 days → approved | pass |
| retry | failed completion → SnackBar, no K05; retry → K05 | pass |
| data edges | 0 / 1 / 6 children; "Maximilian-Alexander" + 9999 coins at 320/1.3; `+0` coins, no `£` | pass |
| back nav | check → K05 → back → home, card flipped to "Waiting for Mum" | pass |
| deep links | `/kid-home` kid mode with/without active child | pass |
| restart | Drift file DB closed/reopened: completion still `done_pending` | pass |
| guard | `/today`, `/today-empty`, `/quest-editor`, `/add-children`, `/pocket-money-setup` → gate in kid mode | pass |
| dark contrast | 16 K03 token pairs ≥ 4.5:1 in both themes | pass |
| async gap | late `completeQuest` failure after `bloc.close()` does not throw | pass |
| money | integer coins only on this screen | pass |

## Observations (checked, not raised as bugs)

1. **Period rollover without a DB change.** Status computes at stream-map
   time; at London midnight a daily completion stops counting only on the
   next stream emission or reload. No injectable clock, so not provable here.
2. **Test-suite wall-clock coupling.** The seed anchor is pinned
   (`flutter_test_config.dart`) but `DateTime.now()` (the period filter) is
   not; the demo counts stay deterministic only while the machine clock is
   in the pinned anchor's day/week.
3. **`inNest` note vs composition** — review finding 4; slot measurements
   met, stage 5 accepted twice; needs a waiver on record or the shared
   `NestPetStage(pip:)` migration (finding 1).
4. **Parent mode → `/kid-home`** reachable by deep link; PIN not enforced
   (K01/K02 placeholders); debug gallery routes unguarded.
5. **Accessories in the static `PipAvatar` fallback** are not drawn (no seed
   child equips one today).

## Summary

| ID | Severity | Area | Status |
|---|---|---|---|
| K03-BUG-7 | **Major** | `DISABLE_ANIMATIONS=1` parses false → Rive never still, screenshots never stabilise | **open (shared, SHARED_REQUEST #5)** |
| K03-BUG-10 | Major (owner) | dock surface to the screen edge | **fixed iteration 4, light+dark proofs green** |
| K03-BUG-11 | Minor | silent no-op write leaves the check latched | **open (feature-local)** |
| K03-BUG-1..6, 8, 9 | — | earlier defects | fixed, proofs green |

The iteration-4 bottom-edge fix is real and verified in both themes, and the
whole verified-clean table still passes. The iteration can still not close
PASS: the documented `DISABLE_ANIMATIONS=1` major (K03-BUG-7) remains open,
the review's major component-fork mandate is not yet applied, and the dark
meadow deviation is still on the UI side.

VERDICT: FAIL
