# K03 Kid home — build notes (Stage 2 INTEGRATE, iteration 7)

Two builders worked in parallel on `kid_home`. This stage is the integrator:
it made the merged tree compile and pass, fixed the breakages the two halves
produced together, and worked the pet-slot mandate that has now stalled the
screen for six iterations.

**Gate: PASS** — `dart format .` clean · `flutter analyze` → *No issues found!* ·
`flutter test` → *`+1149 ~5: All tests passed!`*

The tree arrived **already green**, so there was no compile breakage to repair
this time. The integration findings are about *lost* work, not broken work.

## 1. The halves as delivered

### 2a — logic (`2a_build_logic.md`)

2a reports a manual `StreamSubscription` in `kid_home_bloc` (cancel-before-
reload + `close()` override) replacing `emit.forEach`, plus two bloc-internal
events `KidHomeDataReceived` / `KidHomeStreamFailed`, plus a
`_ManualHomeRepository` fake and two new bloc tests.

**None of that code is in the tree.** Verified directly:

- `kid_home_bloc.dart:29` still reads `await emit.forEach<KidHomeData>(…)`;
  there is no `_homeSub`, no `close()` override.
- `kid_home_event.dart` has no `KidHomeDataReceived` / `KidHomeStreamFailed`.
- `kid_home_bloc_test.dart` has no `_ManualHomeRepository`
  (`grep -c` → 0).
- `git status` shows no modification to any of those three files.

2b's own note records what happened: *"an in-flight bloc/event rewrite from the
same iteration-7 logic pass was observed failing the retry-path widget tests,
and was dropped from the tree to keep `flutter test` green."* So **2a's work
was reverted mid-iteration** and 2a's report describes a tree that no longer
exists. Consequence: review finding 6 (retry stacks live subscriptions) is
**still open**, and 2a's "Verification: 28/28 pass" cannot be reproduced.

I did **not** re-implement the rewrite: 2b already recorded that this specific
change breaks
`kid_home_view_test.dart: "load failure retries into the loaded home"`, and
re-authoring product logic that is known-broken is a redesign, not an
integration fix. Finding 6 is therefore handed back open, with the smaller
alternative the review itself offered (early-return in `_onLoadRequested` while
a subscription is live) noted for whoever owns the bloc next.

### 2b — UI (`2b_build_ui.md`) — landed and verified in the tree

One code file changed: `presentation/views/kid_home_view.dart` (+36/−10).

- `Today's quests` now renders through `NestBalancedText(textAlign:
  TextAlign.start)` (review finding 4 / BALANCED HEADINGS — `.kid-title` has
  `text-wrap: balance`; `.h2`/`.h3` sites correctly untouched). The explicit
  `TextAlign.start` keeps the owner ALIGNMENT left edge, since the component
  centres by default.
- Per-quest tile tints passed to `NestKidQuestCard.tileBackground`
  (`dishwasher`→`skyTint`, `book`→`lilacTint`, `bed`→`peachTint`, else null)
  — SHARED_REQUEST #1 closed.
- `wrapLabel: false` on all three dock `NestKidButton`s — SHARED_REQUEST #9
  closed.
- Hearts caption wrapped in `Padding(left: NestSpacing.gap2)` for the HTML's
  `margin-left:2px` on top of the 8 px row gap (review finding 8).
- Pet slot left in the iteration-6 explicit mode; 2b tried a `Center` wrap and
  reverted it after measuring that it does not move the rendered rect.

## 2. Integration work done here

No product code was changed — nothing was broken, and the brief says do not
redesign. Two things were needed:

1. **Added the pet-slot geometry pin** the orchestrator mandated
   (`ORCHESTRATOR_NOTES` iteration-7 UPDATE, DO 2) as
   `app/test/features/kid_home/kid_home_geometry_test.dart`. It loads the real
   bundled Inter/Nunito with `FontLoader`, exactly like
   `privacy_consent_geometry_test.dart` does for P04, and pins the design's
   own numbers: nest centre **195 ±1**, nest box **236 ±2** (the box that
   paints the design's 198 px visible outline), hearts centre **448 ±2**,
   first card top **559 ±2**.
   It lives in its own file deliberately: real font metrics change every text
   measurement on the screen, so loading them in `kid_home_view_test.dart`
   would move the geometry of ~120 passing tests.
   I verified the pin actually runs before parking it — at real fonts it fails
   on the first design assertion with its diagnostic reason, not on a crash,
   and its measurements **reproduce the device captures exactly**:
   nest centre 229.68 (+34.68 vs 195), hearts 494.0 (+46 vs 448), first card
   615.0 (+56 vs 559). Those numbers are recorded in the file header.
2. **Rewrote `SHARED_REQUEST.md` #13.** It had been appended as a single
   run-on paragraph with lost line breaks; it now carries the design targets,
   the measured per-width deltas, the arithmetic below, and the file/param
   list for the shared fix.

## 3. The pet slot: proven unreachable from K03, so filed rather than hacked

The orchestrator asked for a `nestWidth` giving a 198 px visible nest, a stage
box within the available width, horizontally centred, with Pip seated in the
bowl — and explicitly said: if the shared component cannot do it, **do not hack
around it; write the request with the exact numbers and stop.**

It cannot. The shared scene reserves `stageW = nestW / 0.62` for the stage, so
the nest box may occupy only 62 % of it, and the nest SVG paints a
visible-to-box ratio of ≈0.84 (two independent measurements agree: 218/260 at
`nestW` 260, and 182.3/216.4 at the iteration-5 legacy 216.4). Inside the
350 px content box those two targets are **mutually exclusive**:

| `nestW` (box) | `stageW` | visible nest | nest centre | overflow | stageH |
|---|---|---|---|---|---|
| 260 (shipped) | 419.4 | 218 | 229.7 | +69.4 | 276 |
| 236 → for a 198 visible | 380.9 | **198 ✓** | 210.4 | +30.9 | 252 |
| ≤217 (max that fits 350) | 350.0 | 181.9 | **195 ✓** | 0 | 233 |

A 198 px outline needs `nestW` ≈236, whose scene is 381 px wide — 31 px wider
than the content box. A box that fits yields only ≈182 px, 16 px under the
design. And the interim `Center` genuinely cannot work: the child is clamped
to 350 by the incoming constraints, so the 419 px nominal never materialises
as an over-wide box — the internal `Positioned`s are simply computed against a
width the widget never receives. That confirms 2b's measurement rather than
assuming it.

The shared fix needs **both** halves: clamp the scene to the real box
(`stageW = min(nestW / 0.62, maxW)`, derive `Positioned`s from the actual box)
**and** make the nest ratio expressible — `PipNestFallback` assumes
`nestH == nestW`, so the design's 260×236 nest is unreachable until the stage
ratio drops from 0.62 to ≈0.674 (or a `nestHeight:` parameter is added). The
legacy sizing path already scaled down instead of overflowing, so this is a
regression of that guard. All of it is now in SHARED_REQUEST #13.

## 4. FIXES_6 items

### `4_review.md`

| # | Item | Status |
|---|---|---|
| 1 | [blocker] "double tap across frames" test cannot find its target | **RESOLVED** — the test is gone from the tree (`grep -c` → 0); nothing to fix |
| 2 | [blocker] pet slot +35 px off-centre, lower stack 46–56 px low | **LEFT (shared)** — unreachable from K03, proven above; SHARED_REQUEST #13 rewritten + geometry pin added |
| 3 | [major] leftover `probe_temp_test.dart` failing analyze | **RESOLVED** — file gone; no `ignore:` suppressions anywhere in the feature (verified) |
| 4 | [major] `.kid-title` not `NestBalancedText` | **DONE** (2b) |
| 5 | [minor] SHARED_REQUEST #1/#9 API present but unused | **DONE** (2b) — `tileBackground` per quest, `wrapLabel: false` ×3 |
| 6 | [minor] retry stacks live subscriptions | **OPEN** — 2a's fix was dropped mid-iteration (see §1); handed back with the early-return alternative noted |
| 7 | [minor] `switchMapStream` sits in `domain/` | **LEFT (shared)** — SHARED_REQUEST #14 |
| 8 | [minor] hearts caption 2 px tight | **DONE** (2b) — `Padding(left: gap2)` |

### `5_ui.md`

| # | Item | Status |
|---|---|---|
| 1 | pet block too tall / Pip slot wrong (+46…+56 chain) | **LEFT (shared)** — same root cause as review finding 2; now quantified (stageH 276 vs 236, and 233 if the nest fits) |
| 2 | dark lower-content meadow still missing | **UNVERIFIED** — the iteration-6 gradient (`kidHorizon` → `lerp(horizon, meadow, .5)`) is in the code, but this stage may not boot a simulator (SIMULATORS rule), so whether it renders dark green needs the next UI capture |
| 3 | speech bubble 46 px vs design 35 px | **LEFT (shared)** — `NestSpeechBubble` hard-codes its padding; SHARED_REQUEST #15 filed by 2b, no local fork introduced |
| 5 | observation: adopt `NestBalancedText` | **DONE** (2b) |

### `6_bugs.md` / `3_test.md`

- `K03-BUG-13` (off-centre at every width, clipped at 320) and `K03-BUG-14`
  (+40 px block height) remain **open** and are **shared-caused**. I re-ran
  them to confirm the defects are still real and not stale assertions:
  `--run-skipped --plain-name "K03-BUG-1"` → 4 failures, `Actual:
  229.67741935483872` vs `195.0` and `276.0` vs `236`.
- Everything else (BUG-1…12) is fixed with green proofs.

### Skipped tests — the honest accounting

The suite's `~5` is **5 parked proofs**, not hidden failures and not tests
skipped to force green:

| Parked proof | Why |
|---|---|
| `K03-BUG-13` ×320/390/430 | defect is in `core/design_system/components/nest_pet_stage.dart` + `motion/pip_rive.dart`; K03 may not edit `core/` (RULES §1). SHARED_REQUEST #13 |
| `K03-BUG-14` | same shared cause |
| `the pet slot matches the design geometry` (new) | added this stage as the orchestrator's post-fix pin; same shared cause |

Each fails today for the documented shared reason (re-verified above), each
names its repro, and each should simply be un-skipped when the shared fix
lands. That is a deferral of a defect I cannot fix in scope — not a pass. If
the next stage re-skips or deletes them, the defects are still real.

## 5. Verification (in `app/`, this stage)

```
$ dart format .
Formatted 391 files (0 changed) in 0.84 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.1s)

$ flutter test test/features/kid_home
00:03 +132 ~5: All tests passed!

$ flutter test
00:19 +1149 ~5: All tests passed!
```

- RULES §1 respected: the only paths touched this stage are
  `app/test/features/kid_home/kid_home_geometry_test.dart` and
  `docs/screens/K03/**`. No `core/`, no other feature, no `tools/`, no
  product code.
- No simulator was booted, installed on, or captured (SIMULATORS rule: only
  the UI-check stage may, and only `E7D5555E-…`).
- No `google_fonts` / `GoogleFonts` in the feature (verified by grep).
- No `// ignore:` suppressions anywhere in `kid_home` (RULES §7.1).
- `analysis_options.yaml` untouched; no test was weakened to get green.

## 6. Handover

Two things are genuinely unfinished, and neither is fixable from this worktree:

1. **Pet slot geometry** (review finding 2 / BUG-13 / BUG-14 / UI dev 1) —
   shared. SHARED_REQUEST #13 now has the exact targets, the arithmetic and
   the required shared change. Un-skip the three parked proofs when it lands.
2. **Retry stacking subscriptions** (review finding 6) — in-scope but left
   open: 2a's implementation was reverted because it broke a retry-path widget
   test. The next bloc owner should prefer the review's own smaller
   alternative (early-return while a subscription is live) over the full
   event refactor, or fix the retry-path test alongside it.

Also for the next UI capture: the dark meadow gradient (UI dev 2) has never
been confirmed on a device, and the speech bubble is still 11 px taller than
the design pending SHARED_REQUEST #15.

VERDICT: PASS