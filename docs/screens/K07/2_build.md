# K07 · 2 BUILD (integrate, iteration 3) — 2a logic + 2b UI combined

Job: make the two parallel halves compile and pass together. No simulator was
booted (only `5_ui` may touch `BC440E48-B3A3-43BC-971B-0EF5DB621874`), no
design was redesigned, no shared file was touched (RULES §1: `features/pip/**` +
`test/features/pip/**` + this folder only), no `pkill`.

**This iteration needed no integration repair.** The two halves already agreed
on the contract, so the work below is verification (the gates, plus reading
every seam the merge could have broken) and one stale cross-half comment.

## What landed

### 2a — non-UI layer (`2a_build_logic.md`, iteration 3)

CONTRACT CHANGES: **none** — the public surface is byte-identical to iteration
2. The single edit to an existing member is additive and defaulted:
`PipState.toLoading({bool restartingNest = true, bool restartingEvolution =
true})`, so every existing fixture and `pip_buy_result_test.dart:480`'s no-arg
call still compiles and behaves exactly as before.

- Fixed `4_review.md` finding 1 (carried from `FIXES_2`): `toLoading()` dropped
  **both** streams' arrival flags while a retry re-subscribed only the one that
  died, so the surviving stream reported `loading` and its screen sat on a
  spinner with **no retry affordance** (the retry button only exists on the
  `failure` branch). The reset is now explicit about what is restarting:
  `_onLoadRequested` passes `restartingNest: _nestSub == null,
  restartingEvolution: _evolutionSub == null` — the one null subscription is
  exactly the stream `??=` is about to re-listen. A restarting stream drops its
  flag and error slot; a surviving stream keeps flag, slot, status and data.
- `status` inside `toLoading` is now derived through the existing `_combine`
  instead of being hard-coded `loading`, so the aggregate can never disagree
  with the two per-stream statuses it is defined from (the same lesson as
  iteration 2's `copyWithLoaded` sibling-slot defect).
- +3 proofs in `pip_evolution_bloc_test.dart`: the state-level reset in both
  directions (including that a restart clears only its own error slot), and two
  bloc-level proofs that the surviving stream never dips back to `loading`.
  2a verified they bite: reverting only the call site to `emit(state.toLoading())`
  fails exactly those two and nothing else.

### 2b — presentation layer (`2b_build_ui.md`, iteration 3)

Layout, copy, spacing and the bottom-edge rule are **unchanged** from iteration
2 (which passed build + test + review + UI) — correctly, this iteration's brief
was a bug list.

- **K07-BUG-5 fixed (MAJOR, orchestrator-mandatory)** —
  `pip_evolution_sparks.dart` only: the design's `svg.sparks` is an inline SVG
  with **literal** hexes, so the layer is theme-invariant by construction;
  resolving from `context.nest` gave every sparkle and dot a `#F3F0FA` white
  ring on the night sky (`5_ui.md` D4 / `cmp_dark_2.png`). Stroke and all five
  fills now resolve from `NestColors.light` in both themes, `shouldRepaint` is
  `false`, the widget tree is `const` end to end.
- `k07_bugs_test.dart`: the K07-BUG-5 proof un-skipped (the file's only
  `skip:`, now removed).
- `pip_evolution_sparks_test.dart`: palette assertions read the light palette,
  plus a dark-only proof that no dark ink reaches the canvas, `shouldRepaint`
  pinned false, and `4_review.md` finding 3's wrong filename in the header
  corrected.
- `pip_nest_states_test.dart`: applied 2a's cross-half fixture change (below).

## FIXES

### Done — 1. The mandatory orchestrator item (D4 / K07-BUG-5) verified as ruled

`ORCHESTRATOR_NOTES.md` 23:55 is mandatory, so I checked the landed code against
it rather than trusting the note:

- `_SparksPainter.paint` strokes with `NestColors.light.ink` and every fill goes
  through `_Spark.color`, which reads `NestColors.light` — no `context.nest`
  left in the file, `shouldRepaint` returns `false`, and the change is confined
  to `pip_evolution_sparks.dart` as ruled.
- "Verify each fill hex equals the HTML's literal": `tokens/colors.dart` holds
  `ink 0xFF1E1B3A`, `lilac 0xFF7C6CF2`, `success 0xFF1F9D63`, `coin
  0xFFF4B400`, `peach 0xFFFF8A5B` — the HTML's `<g stroke="#1E1B3A">` and its
  four sparkle fills, exactly. Tokens-only and PNG parity agree, as 2b claimed.
  The sixth sample, the sky dot's `#3D7FF0`, is not a token in either scheme
  (`--sky` is `#2563D6`), so it paints the light sky token — 2b's disclosed
  loose end, filed as `SHARED_REQUEST.md` item 4 and pinned by an assertion that
  the literal is NOT painted. Leaving it is right: the alternative is a literal
  hex (forbidden) or a new shared token (not this screen's call).
- "Add a widget/painter test under dark theme asserting the stroke colour is
  0xFF1E1B3A": `k07_bugs_test.dart`'s K07-BUG-5 does exactly that, and it is a
  real probe — it pumps the **app shell** at `ThemeMode.dark`, pulls the
  painter off the live `CustomPaint`, rasterises it with a `PictureRecorder`
  and samples pixels at the design's own `viewBox` coordinates (stroke at
  sparkle 1's left point `(13, 49)`, each fill at its sparkle's waist), then
  compares the whole dark map against the light one so a future accent cannot
  slip past the per-entry list. No skip, no `--run-skipped` needed now.

### Done — 2. 2a's cross-half fixture change, applied by 2b, verified

2a flagged (mid-flight) that `pip_nest_states_test.dart` referenced a
`closeEvolutionGate` that no longer existed, and prescribed one line:
`_NestOnlyRepository.watchEvolution` answers a healthy `Stream.value(null)`
instead of hanging on a silent controller. 2b landed it: no orphan reference
remains, the fake is one 5-line class, and the file is `+20: All tests passed!`.
This is the iteration-1 fixture I originally added for K06 — it now matches the
production shape (a stream that settles with no child) instead of diverging
from it.

### Done — 3. Stale cross-half comment in that same file

2b corrected the fixture's own docstring but left the **file header** still
describing iteration 1's behaviour ("keeps K07's second stream silent"), which is
now false — the very file a future iteration would edit from. Fixed the header
(4 lines) and moved the trailing comment off the over-long `watchEvolution`
line. Comments only; no behaviour, no assertion touched.

### Verified, no change needed

- **Contract**: 2a says "none in iteration 3", and the tree matches — every
  `PipState` member, `props` and `PipEvent` keeps its iteration-2 shape, the
  two views still switch on `state.evolutionStatus` / `state.nestStatus`, and
  `questsFinishedCount` still feeds the `quests done` card.
- **The iteration-2 defect class cannot recur in `toLoading`**: every one of the
  five `status:` sites in `pip_state.dart` now passes `_combine` exactly the
  flags and slots the state it builds carries, so `status`, `nestStatus` and
  `evolutionStatus` cannot disagree. The only two remaining `status: status`
  passes are `withActionStarted` / `withActionFailed`, which touch no load
  field.
- **Retry semantics on a real failure**: both subs dead ⇒ both restart ⇒ both
  flags and slots drop ⇒ spinner; one dead ⇒ only that one restarts; both live
  ⇒ the early guard returns and nothing is emitted, so no reload flicker.
- **No skipped gate**: zero `skip: true` in `test/features/pip/`; the whole
  directory runs `+419` with no `~` marker.
- Nothing outside RULES §1 was edited by me; no `analysis_options` change, no
  `google_fonts`, no `DateTime.now()`, no `flutter clean`.

### Left

- **`5_ui`: re-measure the dark sparkles** (`5_ui.md` **D4** / the 23:55 note's
  second bullet): no light outline, stroke `#1E1B3A`, fills `#7C6CF2` /
  `#1F9D63` / `#F4B400` / `#FF8A5B`. Everything else on screen is byte-identical
  to iteration 2's accepted shots, so the band table should not move. The 6 px
  sky dot will read `#2563D6` where the PNG says `#3D7FF0` — filed item 4, not a
  regression.
- **`4_review.md` finding 2 — `evolutionSub(0)`** = "Because you helped 0 times"
  under "Pip grew into a Hatchling!". The branch is missing, not the wording,
  and no design source has a zero case, so it needs the orchestrator's sign-off
  (filed as `SHARED_REQUEST.md` item 5). No copy invented here; 2b's
  `k07_bugs_test.dart` control pins today's wording.
- **`SHARED_REQUEST.md`** items 1-4, all non-blocking notes/rulings for the
  orchestrator: the K07 background deviation (no `KidScope`, no `.meadow`), the
  screen-scoped load event (item 2, the reason `PipLoadRequested` still opens
  K06's stream on K07), and the non-token `#3D7FF0` sky dot (item 4).
- **No in-app entry point for `/pip-evolution`** (`6_bugs.md` observation 1) —
  the CTA leaves to `/pip`; whether K06 should open K07 on a stage-up is the
  K06/flow owner's call.
- **Stale note, closed here so it is not re-reported**: 2b's LEFT item 2
  (`toLoading()` clearing both arrival flags, `4_review.md` finding 1) was
  written before 2a's fix landed in the same iteration — 2a fixed exactly that
  finding and it is proven by the two new bloc-level tests. Nothing is owed.

## Gates

```
$ dart format .
Formatted 642 files (0 changed) in 2.05 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.8s)

$ flutter test --timeout 120s test/features/pip
00:10 +419: All tests passed!      (no `~`: zero skips in the feature)

$ flutter test --timeout 120s
01:35 +4474 ~10: All tests passed!
```

`~10` are the suite's own skips and **none is K07's**: `k01_bugs` (1),
`k03_bugs` (2), `k09_bugs` (6), `p12_bugs` (1).

Files changed by this stage only:
`app/test/features/pip/pip_nest_states_test.dart` (the stale file header + the
over-long line's comment) and `docs/screens/K07/2_build.md`. No production file
needed a change this iteration.

VERDICT: PASS