# Fix list after iteration 3

## From 3_test.md
# K03 Kid home — test notes (Stage 3, iteration 3)

Iteration 3 re-tests the fixed screen (period scoping, PipAvatar in the
empty/failure states, SafeArea bottom chrome, K03-BUG-8/9 latches) and
extends the suite for the PERIODS ruling and the new owner rules merged from
main. One real screen bug was found (the dock surface does not cover the OS
inset); the screen was NOT patched.

## Files

- `app/test/features/kid_home/kid_home_view_test.dart` — 36 → 44 tests.
- `app/test/features/kid_home/kid_home_bloc_test.dart` — 20 tests
  (unchanged this iteration; still green).
- `app/test/features/kid_home/k03_bugs_test.dart` — bug-hunt proofs
  (unchanged; all run green, 1 conditional skip = the shared motion flag).
- No `app/lib/**` change in this stage; nothing outside RULES §1 touched.

## New tests (this iteration, +8)

Periods (PERIODS ruling, DB-backed):
- daily: a completion one minute before the London day start reads `to do`
  again (0 done today, coin pill, no chip); moving it inside the day makes it
  count again (`1 done today`, `Done` chip);
- weekly: a completion one minute before the London week start (Mon 00:00)
  reads `to do`; moving it inside the week counts;
- once: a completion 400 days old still counts (`Done` chip);
- a period-expired daily quest starts a fresh completion on tap: the card
  flips to `Waiting for Mum`, K05 opens, and the DB holds exactly two rows —
  the old out-of-period `approved` row untouched plus a new `done_pending`.

Bottom edge / alignment (owner rules merged from main):
- the dock surface must reach the physical screen edge with a 34 px bottom
  inset (**FAILS** — K03-BUG-10);
- the dock top lifts by exactly the 34 px inset (passes);
- no mock home pill is rendered (`NestHomeIndicator` is 0×0, OS draws it);
- gutters align: header avatar, quest cards and dock buttons all start at the
  20 px side gutter.

Pip:
- an accessorised child (storybook/mint/scarf/stage 4) drives the full look
  mapping in the still frame, no v1 art.

## Results

- `dart format --set-exit-if-changed .` — clean.
- `flutter analyze` — `No issues found!`
- `flutter test` — `+467 ~1 -2`: 467 pass, 1 skip (shared motion-flag proof,
  see below), 2 fail — the light + dark proofs of K03-BUG-10.
- K03 alone: bloc 20/20; view 42/44.

## Bug found (screen NOT patched)

### K03-BUG-10 — the dock surface does not cover the OS bottom inset

**Severity: Major (owner rule, "UI checks must FAIL a screen that shows
one").**
Where: `app/lib/features/kid_home/presentation/views/kid_home_view.dart:471`
— `SafeArea(top: false)` wraps the dock `Container` (line 476), so the inset
padding lands *below* the surface container and the KidScope meadow/sky shows
through as a coloured strip under the bar.

Rule: `tools/screens/stages/common.md` BOTTOM EDGE (OWNER RULE, overrides the
designs): the area below any bottom bar down to the physical screen edge MUST
use the same surface colour as that bar; never a coloured strip under a bar
or around the home indicator, light or dark. This supersedes the second half
of `ORCHESTRATOR_NOTES.md` #8 (meadow to the edge), which came from the
design.

Repro:
`flutter test test/features/kid_home/kid_home_view_test.dart --plain-name
"the dock owns the OS bottom inset"` (both themes).
A 34 px system inset (`tester.view.padding = FakeViewPadding(bottom: 34*3)`)
is set; the dock surface's bottom edge is measured at **810** (844 − 34)
instead of 844, i.e. a 34 px meadow strip sits under the bar. Without an
inset the surface does reach the edge, so the bug only appears on a real
device.

Failing tests: `kid_home_view_test.dart:791` "light: the dock owns the OS
bottom inset" and its dark twin — `Expected: a numeric value within <0.5> of
<844>; Actual: <810.0>`.

Fix hint (feature-local): keep the SafeArea/dock geometry but paint the
surface through the inset — move the `SafeArea` inside the surface
`Container` (surface → `SafeArea` → padded content), or add the bottom inset
to the container's bottom padding, so the surface colour runs to the edge
while the buttons stay above the inset. The dock-top-lift assertion must keep
passing.

## Shared item (not a K03 screen bug)

**K03-BUG-7 (`DISABLE_ANIMATIONS=1`) is still open on this branch's main.**
`ORCHESTRATOR_NOTES.md` claims main fixed it; main's tip
(`5eea2ad`/`c83d4bd`) still has
`kDisableAnimations = bool.fromEnvironment('DISABLE_ANIMATIONS')`, which
parses `"1"` as false, and `app.dart` only mirrors the flag into
`MediaQuery.disableAnimations` when it is true. Evidence:
`flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name "K03-BUG-7"
test/features/kid_home/k03_bugs_test.dart` → `Expected: true; Actual:
<false>`. The proof stays conditionally skipped in the plain suite (by
design), so it is not a failing test here; fix belongs to `core/data` +
`app/` (SHARED_REQUEST #5). No K03 screen change can fix it.

## Verified green this iteration

- Pip mandate: pet slot (Maya mochi/sunny/none/stage 3 at 152), Leo
  (bolt/sky/stage 2), accessorised child, empty-quests state (child's own
  PipAvatar, 120), failure state (neutral mochi/sunny/stage 1) — no v1
  `pip_stage_*.svg` anywhere (iteration-2 bugs K03-BUG-7/8 are fixed).
- Periods: daily/weekly/once scoping rendered correctly and the fresh-row
  write path for a new period (K03-BUG-4 ruling holds on screen).
- Iteration-2 fixes still hold: celebration rides the flip, failed write
  never celebrates, retry works, double-tap guards (check + lock).
- Iterations 1–2 coverage still green: 12-cell light/dark × 320/390/430 ×
  scale 1.0/1.3 matrix, empty/loading/error states, every tap destination,
  semantics labels, kid tap targets ≥ 56.

## Notes / observations (not bugs)

1. The dock-top lift and surface-to-edge requirements are independent; only
   the surface coverage fails (K03-BUG-10).
2. `test/flutter_test_config.dart` pins `Seed.anchorOverride` to Sat 3 Oct
   2026 while the repo reads `DateTime.now()`; the period tests compute their
   boundaries from `londonDayStartUtc/londonWeekStartUtc(now)`, so they stay
   deterministic as long as the machine clock is in the same London week as
   the anchor (same coupling the bug suite documents).
3. Harness notes unchanged: direct Drift work inside a `testWidgets` body
   must use `tester.runAsync`; set bottom insets via `tester.view.padding`
   (physical px) before pumping; avoid `pumpAndSettle` while a loading
   spinner can be on screen.


## From 4_review.md

## From 5_ui.md
# K03 Kid home — UI check (Stage 5, iteration 3)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_3.png" <udid> light demo kid maya` -> `docs/screens/K03/ui/app_light_3.png` (1170x2532). Same with `dark` -> `app_dark_3.png`.
- NOTE: absolute OUT paths used (`shot.sh` cds to `$APP_DIR`). Both runs again printed `WARNING — frame never stabilised in 25 s`, exit 1; frames are usable and theme-consistent.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_3.png docs/screens/K03/ui/cmp_light_3.png` (and dark). Read both sheets. Logical px (PNG/3), tolerance ±2px.
- Rules applied: PIP (`PipAvatar` Mochi/sunny/stage 3, slot kept), STATUS BAR (ignore), DATA OVER MOCKS + PERIODS ruling (in-period counts win; seed anchored to today), BOTTOM EDGE owner rule (bar surface must run to the physical edge — FAIL any coloured strip under a bar; overrides the design), ALIGNMENT owner rule (20px gutters, no visible misalignment), ORCHESTRATOR_NOTES (all mandatory items), `1_plan.md`, SPACING_SPEC.

Results:
- light mean diff: 12.97% — bands: 0: 2.97% · 1: 4.85% · 2: 10.86% · 3: 13.18% · 4: 13.20% · 5: 23.28% · 6: 25.80% · 7: 9.64%
- dark mean diff: 11.84% — bands: 0: 3.01% · 1: 4.47% · 2: 8.89% · 3: 9.71% · 4: 12.90% · 5: 23.12% · 6: 23.37% · 7: 9.25%
- Band 7 recovered (26.5% → ~9.5%): dock top back at design height. Bands 2-6 remain elevated for accepted reasons (mandated PipAvatar art, 4-vs-3 counts + fill, Hoover/Done vs Reading/+10 sample order).

Accepted / overridden (NOT defects):
- A1 counts "4 done today" / "4 of 6 done" / ~66.7% fill vs PNG 3/50% — correct per DATA + PERIODS (seed anchored to today; all 4 completions in-period) + ORCHESTRATOR_NOTES #2.
- A2 2nd card "Hoover the stairs" (approved → "Done" chip, partly visible above dock, same presentation as PNG's partly-visible "Reading") vs PNG sample order — repo alphabetical order wins per `1_plan.md` §(a).
- A3 Pip drawing differs from v1 SVG — MANDATED `PipAvatar`; slot position kept (pet band aligns with design).
- A4 status bar (real OS 03:44/03:45 only, no mock duplication) — IGNORED per rule; band 0 is this only.
- A5 quest icon tiles `surface2` vs per-quest tints — SHARED_REQUEST #1, non-blocking. A6 card title ≈17/22 vs 18/24 — pre-declared shared token.
- A7 no home-indicator pill visible in captures — expected: `NestHomeIndicator` reserves nothing now (OS draws it; `simctl screenshot` does not capture the OS indicator). Not verifiable here, not a defect.

Deviations (design value → app value + fix):
1. Coloured strip under the dock to the screen edge (MUST-FAIL per BOTTOM EDGE rule, both themes). App light: GREEN (191,232,176) from y≈805 to y842 under the white dock; app dark: GREEN (30,74,58) under the navy dock. Rule: meadow must END at the dock's top edge; dock surface (light: white surface; dark: the dock's dark surface) must fill from the dock's top border to the physical edge, home-indicator area included. (The PNG shows green here too — the owner rule explicitly overrides the design on this point.) Fix: clip/end the meadow at the dock top; extend the dock container background through the bottom safe area to the screen edge. Do not edit code in this stage — for the iteration-4 builder.
2. Dock top ≈6px high (minor, ALIGNMENT). Dock top border: design y≈719-721 vs app y≈713-715 (light). Fix: keep the ORCHESTRATOR_NOTES y≈720 target exactly (SafeArea/inset accounting) while applying fix #1.
3. Upper-stack residuals (minor, knock-on of the same layout): hearts +12 (design y443-452 vs app y455-464, unchanged from iter2); progress bar +8 (541 vs 549-550); card-1 top +4 (559-561 vs 563-564); green band starts +38 (design y524 behind progress vs app y562 just below it). Fix: trim ≈8-12px from the pet-stage bottom/speech gaps per the mandated Pip slot (nest top ≈y300, Pip ≈152) so hearts/progress/cards/green-start land on design rows.

Otherwise correct: header row, bubble, hearts 4/5 stroked + caption, section title + chip, kid progress geometry, card geometry/chips/checks per status, dock buttons (glyphs, labels, colours both themes), 20px gutters with cards/bars edge-aligned, no overflow/ellipsis issues, coins-only, dark token flips correct.

Iteration-4 fixes (local): #1 bottom-edge fill (both themes), #2 dock top to y≈720, #3 upper-stack trim. Shared/pre-declared: tile tint, title size.


## From 6_bugs.md
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

