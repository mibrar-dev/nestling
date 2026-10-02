# K03 Kid home — bug hunt (Stage 6, iteration 3)

Adversarial pass over `kid_home` K03 after the iteration-3 fixes, the owner
bottom-edge/alignment rules and the main `DISABLE_ANIMATIONS` / PipAvatar
fallback merges: data edges, rapid double taps, back navigation, deep links,
restart persistence, mode guards, dark contrast, 320px + 1.3 scale, async
gaps, Europe/London periods (daily/weekly/once, BST edges), integer money,
and the owner rules (bar surface to the screen edge, 20px alignment).
No screen code was changed in this stage.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 37 tests:
  35 run green, 2 skipped (`K03-BUG-7` needs its flag-specific run,
  `K03-BUG-10` is open).
- Run the open proofs:
  `cd app && flutter test --run-skipped --plain-name "K03-BUG-10"` and
  `flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name "K03-BUG-7"`.
- Independent confirmation: the loop's stage-3 `kid_home_view_test.dart`
  also added two **un-skipped failing** bottom-edge tests ("light/dark: the
  dock owns the OS bottom inset", Expected within 0.5 of 844, Actual 810) —
  the whole `flutter test` run is red on those until iteration 4 fixes them.

## Status of earlier bugs

| ID | Severity | Status |
|---|---|---|
| K03-BUG-1 | Major | fixed (idempotent transaction + per-card latch); proof green |
| K03-BUG-2 | Moderate | fixed (success-driven celebration); proof green |
| K03-BUG-3 | Minor | fixed (actionNonce); proof green |
| K03-BUG-4 | Moderate | fixed (PERIODS ruling); proof green |
| K03-BUG-5 | Moderate | fixed on main (router guard); proofs green |
| K03-BUG-6 | Minor | fixed (per-card latch); proofs green |
| K03-BUG-7 | Major | **open** — see below (shared parse still broken) |
| K03-BUG-8 | Minor | fixed mid-loop; proof green |
| K03-BUG-9 | Minor | fixed mid-loop (`_GateLockButton`); proof green |

## New bugs (iteration 3)

### K03-BUG-10 — The dock surface does not reach the physical bottom edge

**Severity: Major (owner BOTTOM EDGE rule; UI MUST-FAIL).**
Where: `kid_home_view.dart` bottom chrome — `SafeArea(top: false)` wraps the
dock `Container(surface)` and the (now zero-sized) `NestHomeIndicator`. The
SafeArea inset area and the strip below the dock keep the `KidScope`
sky/meadow background, so a coloured strip shows under the dock and around
the home-indicator area in both themes. The owner rule: the area below the
bar down to the physical edge must use the **same surface colour** as the
bar; never a coloured strip.

Repro (device, UI iteration 3): light capture shows meadow green
(191,232,176) from y≈805 to y842 under the white dock; dark shows green
(30,74,58) under the navy dock. The design PNG shows green there too — the
owner rule explicitly overrides the design.

Repro (widget, deterministic): simulate the 34px home inset
(`tester.view.padding/viewPadding = FakeViewPadding(bottom: 34)`), pump
`/kid-home`, and assert some surface-filled box spans the full width and
reaches the screen bottom (844). The dock container ends at 832.7 and no
surface box reaches the edge, so the proof fails; with the same setup the
stage-3 test measures the dock bottom at 810.0 on both themes.

Failing test (skipped so the suite stays green):
- `K03-BUG-10: the dock surface must run to the physical bottom edge`
  (also independently failed by the stage-3 view tests for light and dark).

Suggested fix (feature-local, iteration 4): paint the dock's own surface
across the whole bottom chrome, e.g.
`ColoredBox(color: tokens.surface, child: SafeArea(top: false, child: …))`
with the dock's 3px ink top border as the first row inside it, so:
- the meadow/panel ends at the dock's top border,
- the surface fills the dock, the inset padding and the indicator area to
  the screen edge,
- no coloured strip remains in either theme.
Keep the dock top border ink line visible (it must not be covered by the
background), and re-check the dock top target (≈y720) after the change.

### K03-BUG-7 — `DISABLE_ANIMATIONS=1` still parses as false (updated status)

**Severity: Major (shared; motion rule + screenshot determinism).**
The main commit `5eea2ad` wired `kDisableAnimations` into
`MediaQuery.disableAnimations` at the app root (`app.dart`), but
`kDisableAnimations` itself is still
`bool.fromEnvironment('DISABLE_ANIMATIONS')`
(`app/lib/core/data/env_flags.dart:9`), which only understands the literal
`"true"`. With the documented `=1` the flag stays false, the new MediaQuery
wiring never fires, the Rive `PipAvatar` keeps animating and `shot.sh`
still reports `WARNING — frame never stabilised in 25 s` (all iteration-1/2/3
captures). The orchestrator note ("K03-BUG-7 is shared and fixed") is not
yet true for the documented value.

Repro:
- `cd app && flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name "K03-BUG-7" test/features/kid_home/k03_bugs_test.dart`
  → `Expected: true, Actual: <false>` (asserts both `kDisableAnimations` and
  `MediaQuery.disableAnimationsOf` inside the pumped home).
- Control: the same proof passes with `--dart-define=DISABLE_ANIMATIONS=true`,
  which proves the app-root wiring itself is correct.

Failing test (skipped in the plain suite):
- `K03-BUG-7: the documented DISABLE_ANIMATIONS=1 flag must disable motion`

Suggested fix (shared): parse `"1"` as true in
`app/lib/core/data/env_flags.dart`, e.g.
`const kDisableAnimations = bool.fromEnvironment('DISABLE_ANIMATIONS') || String.fromEnvironment('DISABLE_ANIMATIONS') == '1';`
(and mirror in `app/lib/app/launch_flags.dart`), or change `shot.sh` and
RULES §5/§6 to pass `=true`. Filed as SHARED_REQUEST #5.

## Verified clean (probes in the same file)

| Category | Probe | Result |
|---|---|---|
| owner alignment | 20 px gutters: progress bar, first card, dock buttons all share x=20 / x=370 at 390px | pass |
| owner bottom (pre-fix) | surface reaches the edge — covered by K03-BUG-10 (failing) | open |
| state art | failure state renders `PipAvatar`, no `pip_stage_*.svg` | pass |
| state art | empty-quests state renders the child's own `PipAvatar`, no v1 art | pass |
| mandated Pip | Maya = mochi/sunny/none/stage 3; Leo link = bolt/sky/stage 2; pipStage 0/9 clamped | pass |
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

1. **Dock top ≈6px high (UI iteration 3 #2).** On the simulator the dock top
   measured y≈713-715 vs the ORCHESTRATOR_NOTES target y≈720. A widget-test
   assertion is unreliable (GoogleFonts metrics differ in tests), so this
   stays a UI-stage deviation; re-check with stable frames after the
   bottom-edge fix.
2. **Upper-stack residuals (UI iteration 3 #3).** Hearts +12, progress +8,
   card-1 top +4, green start +38 vs the PNG. The build notes argue the
   specified inter-block gaps are exact and the residual is live-Rive
   variance; re-measure once `DISABLE_ANIMATIONS=1` actually freezes frames
   (K03-BUG-7).
3. **Period rollover without a DB change.** Status is computed at stream-map
   time; at London midnight a daily completion stops counting only on the
   next stream emission or reload. No injectable clock, so not provable here.
4. **Test-suite wall-clock coupling.** `flutter_test_config.dart` pins
   `Seed.anchorOverride` but not `DateTime.now()`, which the period filter
   uses; the demo "4 of 6" and period proofs stay deterministic only while
   the machine clock is in the pinned anchor's day/week.
5. **`inNest` note vs composition.** The screen composes the child's
   `PipAvatar` over the `nest` art instead of `inNest: true`; the measurable
   slot requirements are met and stage 5 accepted it.
6. **Parent mode → `/kid-home`** still reachable by deep link (spec guard is
   one-way); **`/kid-home` does not require the K02 PIN** (K01/K02 are
   placeholders); debug gallery routes are not in the guard list.
7. **Accessories in the still frame.** The static `PipAvatar` fallback takes
   no accessory; no seed child equips one today.
8. **Process note (not a finding).** The iteration-3 stage-3 tests leave two
   un-skipped bottom-edge failures in `kid_home_view_test.dart`; they confirm
   K03-BUG-10 and are expected to be made green by the iteration-4 fix.

## Summary

| ID | Severity | Area | Status |
|---|---|---|---|
| K03-BUG-7 | **Major** | `DISABLE_ANIMATIONS=1` parses false → Rive never still, screenshots never stabilise | **open (shared, SHARED_REQUEST #5)** |
| K03-BUG-10 | **Major** | dock surface does not reach the screen edge → coloured strip under the dock (owner MUST-FAIL) | **open (feature-local)** |
| K03-BUG-1..6 | — | iteration-1 defects | fixed, proofs green |
| K03-BUG-8/9 | Minor | celebration swallow, lock route stacking | fixed mid-loop, proofs green |

The iteration-3 screen code genuinely improved (PipAvatar states, period
semantics, retry, tap guards, alignment all verified green), but two major
issues remain: the owner bottom-edge rule is visibly violated on device
(green strip under the dock in both themes — independently failing the
stage-3 suite), and the documented `DISABLE_ANIMATIONS=1` still does not
disable motion, which also keeps every screenshot a random animation frame.

VERDICT: FAIL
