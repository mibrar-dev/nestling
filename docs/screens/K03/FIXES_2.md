# Fix list after iteration 2

## From 3_test.md
# K03 Kid home — test notes (Stage 3, iteration 2)

Iteration 1 left K03 green (44 tests). Iteration 2 re-tests the fixed screen
(K03-BUG-1/2/3/5/6 fixes, the new completion/celebration state machine) and
extends the suite for the mandatory orchestrator PipAvatar rules. Two real
requirement violations were found and are recorded below; the screen was NOT
patched.

## Files

- `app/test/features/kid_home/kid_home_bloc_test.dart` — 14 → 20 tests.
- `app/test/features/kid_home/kid_home_view_test.dart` — 30 → 36 tests.
- `app/test/features/kid_home/k03_bugs_test.dart` — bug-hunt proofs
  (unchanged this stage; K03-BUG-1/2/3/5/6 un-skipped and green, K03-BUG-4
  skipped pending the foundation ruling).
- No `app/lib/**` change in this stage; nothing outside RULES §1 touched.

## New / extended tests (this iteration)

Bloc + state (7):
- state: completion outcomes are explicit and nonce-bumped
  (`withCompletionSucceeded` carries questId/coins; `withCompletionFailed`
  bumps `actionNonce`; `withCompletionStarted` clears the outcome);
- state: `copyWithLoaded` clears transient completion outcomes;
- bloc: the celebration signal rides the flip emission itself
  (`justCompletedQuestId`/`Coins` on the 5/6 state — extended existing test);
- bloc: the celebration signal clears on the next stream emission (one-shot,
  cannot celebrate twice);
- bloc: a completion that does not flip the card never celebrates;
- bloc: two identical failures both surface (reset between attempts);
- bloc: retry after a failure clears the error and celebrates on success.

View (6 new + 3 extended):
- Pip: the pet slot renders the child's own `PipAvatar` (Maya =
  mochi/sunny/none/stage 3, size 152) with no v1 art;
- Pip: the active child's database look drives `PipAvatar` (Leo =
  bolt/sky/none/stage 2);
- Pip: the empty-quests state shows the child's own Pip (**FAILS**);
- Pip: no product state renders the v1 `pip_stage_*.svg` art (**FAILS**);
- navigation: double-tapping the check completes once (one event, one
  celebration);
- navigation: a failed check tap can be retried and then celebrates;
- extended: a failed completion asserts no `/quest-complete` opens;
- extended: the child-with-no-quests test uses the shared quest-less-child
  helper.

The view fake repository now models the real one: a successful
`completeQuest` flips the quest to `done_pending` and re-emits, so the
celebration rides the flip in fake-backed tests exactly as it does on Drift.

## Results

- `dart format --set-exit-if-changed .` — 343 files, 0 changed.
- `flutter analyze` — `No issues found!`
- `flutter test` — `+380 ~1 -2`: 380 pass, 1 skip (K03-BUG-4, filed as
  SHARED_REQUEST #4), 2 fail — the two bug proofs below.
- K03 alone: bloc 20/20; view 34/36.

## Bugs found (screen NOT patched)

### K03-BUG-7 — empty-quests state renders the v1 Pip SVG

**Severity: Moderate (mandatory orchestrator rule).**
Where: `app/lib/features/kid_home/presentation/views/kid_home_view.dart:877`
(`_KidEmptyQuests` → `NestEmptyState(art: SvgPicture.asset(pipStage1))`).

Rule: the stage brief says every Pip on a product screen must be the child's
OWN `PipAvatar`, and v1 `pip_stage_*.svg` art is never allowed in product
screens. This state has the active child loaded, so the child's look is
available.

Repro: insert a quest-less child (`Nina`, DB defaults mochi/sunny/stage 1),
set `app_state.active_child_id`, open `/kid-home` → "No quests today" shows
`assets/illustrations/pip_stage_1.svg` and zero `PipAvatar` widgets.

Failing test: `kid_home_view_test.dart:470` "the empty-quests state shows the
child's own Pip" — Expected exactly one `PipAvatar`; found 0.

Fix hint: keep the 160 px art slot, render
`PipAvatar(style/skin/accessory/stage from the child)` instead of the v1 SVG.

### K03-BUG-8 — failure state renders the v1 Pip SVG

**Severity: Moderate (mandatory orchestrator rule).**
Where: `app/lib/features/kid_home/presentation/views/kid_home_view.dart:200`
(`_KidFailure` → `SvgPicture.asset(pipStage1)`).

Repro: register a repository whose streams error (or stop the DB), open
`/kid-home` → "Oh no! Pip got lost." renders
`assets/illustrations/pip_stage_1.svg`.

Failing test: `kid_home_view_test.dart:485` "no product state renders the v1
`pip_stage_*.svg` art" — Expected empty; actual
`['assets/illustrations/pip_stage_1.svg']`.

Fix hint: this state has no child data, so the brief's no-child fallback
applies: a neutral `PipAvatar(style: mochi, skin: sunny, stage: 1)` (or no
art at all) — never the v1 illustration.

## Verified green this iteration

- K03-BUG-1/2/3/6 fixes hold under the stage-3 suite: double-tap check →
  exactly one completion and one celebration; failed write → no K05, list
  kept, SnackBar; retry after failure → celebration; two identical failures
  both announce; the celebration signal is one-shot (cleared by the next
  stream emission).
- PipAvatar mandate in the loaded state: Maya mochi/sunny/none/stage 3 at
  size 152; Leo bolt/sky/none/stage 2; no v1 art while loaded.
- All iteration-1 coverage still green: 12-cell light/dark × 320/390/430 ×
  scale 1.0/1.3 matrix, empty/loading/error states, every tap destination,
  semantics labels, kid tap targets ≥ 56.

## Notes / observations (not bugs)

1. The pet slot composes the nest SVG with a standalone `PipAvatar`
   (`inNest` left at its default `false`) instead of the `PipStage` artboard.
   The note's slot intent — Pip ≈152 px on the 260×236 nest, feet at the rim
   — is met; checked visually against the design crop and the iteration-2
   capture, so this is not raised as a bug.
2. K03-BUG-4 ("done today" day-boundary semantics) stays skipped: needs the
   foundation ruling in `SHARED_REQUEST.md` #4.
3. Harness notes from iteration 1 still apply: direct Drift work inside a
   `testWidgets` body must go through `tester.runAsync`; avoid
   `pumpAndSettle` while a loading spinner can be on screen; use
   `tester.getSemantics` for merged card labels.


## From 4_review.md

## From 5_ui.md
# K03 Kid home — UI check (Stage 5, iteration 2)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_2.png" <udid> light demo kid maya` -> `docs/screens/K03/ui/app_light_2.png` (1170x2532). Same with `dark` -> `app_dark_2.png`.
- NOTE: absolute OUT paths used (`shot.sh` does `cd "$APP_DIR"`, so a relative OUT resolves under `app/`). Both runs again printed `WARNING — frame never stabilised in 25 s` and exited 1; saved last-capture frames are usable and mutually consistent (light/dark differ only in theme).
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_2.png docs/screens/K03/ui/cmp_light_2.png` (and dark).
- Read: `cmp_light_2.png`, `cmp_dark_2.png`. All numbers logical px (PNG/3), tolerance ±2px.
- Overrides applied: ORCHESTRATOR PIP rule (`PipAvatar`, Maya Mochi/sunny/stage 3 — never v1 SVGs), STATUS BAR rule (ignore status-bar diffs), DATA OVER MOCKS (DB numbers win), `ORCHESTRATOR_NOTES.md` #1 (Pip slot: Pip ≈152 on 260x236 nest, nest top ≈y300) and #2 (4/4-of-6 correct).

Results:
- light mean diff: 15.14% — bands: 0 (0-105) 2.99% · 1 (105-211) 4.84% · 2 (211-316) 10.86% · 3 (316-422) 13.18% · 4 (422-527) 13.20% · 5 (527-633) 24.82% · 6 (633-738) 24.67% · 7 (738-844) 26.52%
- dark mean diff: 13.94% — bands: 0: 3.02% · 1: 4.47% · 2: 8.89% · 3: 9.71% · 4: 12.90% · 5: 23.72% · 6: 21.76% · 7: 26.95%
- Diff rose vs iter1 (11.74%/10.89%) for explained reasons: mandated PipAvatar art swap (bands 2-4), now-fully-visible card-2 content mismatch vs the PNG sample (Hoover/Done vs Reading/+10 — data order, bands 5-6), and the dock/home-strip offset below (band 7).
- Fixed since iter1: green band now present behind progress/cards; hearts stroked + closer (+12, was +30); dock icons correct glyphs + fg both themes; dark glow circle gone (matches PNG); card-1 top within +3px.

Accepted / overridden (NOT defects, excluded from verdict):
- A1 counts: design "3 done today"/"3 of 6 done"/50% vs app "4 done today"/"4 of 6 done"/~66.7% — database is correct (ORCHESTRATOR_NOTES #2, DATA rule).
- A2 card order/content: app 2nd card "Hoover the stairs"/"Done" (approved) vs PNG "Reading – 20 minutes"/"+10" — repo alphabetical order wins per `1_plan.md` §(a) (do NOT re-sort); "Done" chip + green check is the correct approved rendering.
- A3 Pip artwork: v1 SVG chick (hair spikes, green wing tips) vs `PipAvatar` Mochi/sunny/stage-3 (cheek discs, top curl) — MANDATED by the PIP rule; slot size/position kept close.
- A4 status bar: mock "9:41" vs real OS "02:30"/"02:32" — IGNORED per STATUS BAR rule (band 0 ≈3% is this only).
- A5 quest icon tiles `surface2` beige vs per-quest tints (measured light tile design (230,239,254) vs app beige) — SHARED_REQUEST #1, non-blocking.
- A6 card title ≈17/22 vs 18/24 — pre-declared shared token (noted iter1), not locally fixable.

Deviations (design value → app value + fix):
1. Home-indicator strip background wrong (major, both themes). Design: meadow green continues under dock + home area to y843 (light green; dark (30,65,56)) with a 134x5 pill (dark rows 825-829). App: light strip is WHITE (255,255,255 at y835/840) with only a thin mark; dark strip is NAVY ((31,28,46) at y838/842). Fix: extend the meadow/background layer under the bottom chrome — check `KidScope` layering vs Scaffold/dock/`NestHomeIndicator` backgrounds in both themes.
2. Dock sits ~28px too low (major). Dock top border: design y≈719-721 vs app y≈747-749 (light, measured). Card-1 top matches (+3: 560-561 vs 563-564), so ≈25px of excess height sits between card-1 top and dock top. Fix: audit progress→card-1 gap, card-1→card-2 gap (spec `.k3-quests` gap 12 vs base 16), and card internal heights until the dock + home pill land back on design rows.
3. Green band starts ~39px too low (moderate). Left-edge green: design y≈524 (behind the progress bar) vs app y≈563 (just below it). Same fix family as #2 — upper stack still slightly tall (hearts +12 accounts for part of it).
4. Hearts row +12px low (minor; was +30 in iter1). Yellow-heart rows: design y443-452 vs app y455-464. Outside ±2px but much improved. Fix: trim pet-stage bottom padding toward the orchestrator slot (nest top ≈y300, Pip ≈152).
5. Iteration-1 items #4 (dark glow) and #7 (dock icon fg) are FIXED — verified in both themes (dark dock icons: dark-on-lavender/amber/mint; light: white/dark/white as designed). Iter1 #5 hearts stroke FIXED. Iter1 #2 gap and #3 Pip scale substantially improved (slot now close; residual is the mandated art swap).

Otherwise correct: header (`k3-top`, s64 lilac M, 22/26 w900 name, 15/20 sub, 120 pill, 56 r18 lock), speech bubble, "Today's quests" 28/34 + `kchip`, kid progress (h16, 2px border, leaf fill + gloss), card geometry (min-h 72, pad 12, r24, 3px border, kid shadow, 56 checks, correct chips per status), dock layout/colours both themes, no overflow/ellipsis issues, coins-only (no £), dark token flips correct.

Iteration-3 fixes (local): #1 home-strip background both themes, #2 dock height audit (≈25px between card-1 and dock), #3/#4 upper-stack trim. Shared/pre-declared: tile tint, title size.


## From 6_bugs.md
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

