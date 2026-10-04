# K07 · 2 BUILD (integrate, iteration 1) — 2a logic + 2b UI combined

Job: make the two parallel halves compile and pass together. No simulator was
booted (only `5_ui` may), no design was redesigned, no shared file was touched
(RULES §1: only `features/pip/**` + `test/features/pip/**` + this folder).

## What landed

### 2a — non-UI layer (`2a_build_logic.md`, verbatim summary)

- `domain/entities/pip_evolution.dart` (new): `PipEvolution { profile,
  questsDone }`, Equatable.
- `pip_repository.dart` / `pip_repository_impl.dart`:
  `Stream<PipEvolution?> watchEvolution()` — feature-local `_switchMap` over
  `watchAppState()` × `combineLatest2(watchProfile(id),
  watchCompletionsForChild(id))`; null with no active child or a gone child
  row; `questsDone` counts `done_pending` + `approved`, **all time** (a
  lifetime milestone, so the PERIODS ruling does not apply and no clock is
  read).
- bloc: `PipState.evolution` + `copyWithEvolution` + `withStreamError`,
  `PipEvolutionReceived` / `PipEvolutionFailed`, and `PipLoadRequested`
  opening BOTH subscriptions under separate null-guards with a per-stream
  error release; mid-session errors keep the loaded screen; `close()` cancels
  both. `items` (K06 wardrobe) untouched.
- Tests: `pip_evolution_repository_test.dart` (8) + `pip_evolution_bloc_test.dart`
  (13) new; `pip_bloc_test.dart`'s exact-sequence K06 tests repointed at a
  silent-evolution fake.

### 2b — presentation layer (`2b_build_ui.md`, verbatim summary)

- `pip_evolution_view.dart` (placeholder replaced) + widgets
  `pip_evolution_background.dart` (screen-local lilac glow + the SHARED
  `NestKidStarsPainter`, dark only), `pip_evolution_sparks.dart`,
  `pip_evolution_stage.dart` (old Pip → arrow → new Pip, both
  `PipAvatar` with the child's own style/skin/accessory),
  `pip_evolution_stats.dart`, `pip_evolution_copy.dart` (every string with
  its HTML line).
- Geometry pinned at ±2 px in `pip_evolution_widget_test.dart` (13) against a
  pixel scan of the light PNG: stage slot 20/105/350/250, old Pip 22/287/68/68,
  arrow left +76/bottom 24, new Pip 124/115/240/240, hero line box 371/34, sub
  421/26, speech 463/66 for 2 lines, stat cards 20/140/260 × 110 × 84, bar top
  border 721, CTA top 736, `bar.bottom == 844`.
- Two measured deviations: no `KidScope` (K07's CSS overrides the kid
  background and has no `.meadow`), and `.kid-bar` bottom padding 4 px so the
  shared `NestKidButton`'s 6 px shadow room lands the bar's top border on 721
  and the bar's bottom on the physical edge (owner bottom-edge rule).
- `pip_evolution_view_test.dart` (16) + `pip_evolution_widget_test.dart` (13).

### Contract between the halves

`2a_build_logic.md` says **CONTRACT CHANGES: None**; the landed code matches
`1_plan.md` §(b) exactly, and 2b coded against it unchanged. No member was
renamed, no import disagreed, no BLoC state/event had to be reconciled — the
two halves only had to be brought to green together.

## FIXES

### Done — 1. The 11 K06 failures 2b handed over (integration-only breakage)

2a made `PipLoadRequested` open a SECOND stream (`watchEvolution`) and either
healthy emission now promotes `PipState.status` to `loaded`. 11 pre-existing
K06 tests drove a repository that only ever failed or gated `watchNest()`, so
the healthy evolution emission carried `/pip` out of the states under test:
the loading spinner and the failure card never appeared (0 ×
`CircularProgressIndicator`, 0 × `Oh no! Pip got lost.`), and one exact
sequence grew an extra emission.

Fixed in the test fakes only — same pattern 2a already used in
`pip_bloc_test.dart` (`_EvolutionSilentRepository`), no production change:

- `test/features/pip/pip_nest_states_test.dart` — new abstract
  `_NestOnlyRepository` keeps `watchEvolution()` silent (closed via
  `closeEvolutionGate()` in the teardown); `_ControlledNestRepository` and
  `_FlakyNestRepository` now extend it. Every loading / failure / no-child
  assertion is byte-identical to before, and the file header documents why.
  10 failures fixed.
- `test/features/pip/pip_buy_result_test.dart` — `two refusals in a row …`
  nonce sequence `[0, 0, 1, 0, 1]` → `[0, 0, 0, 1, 0, 1]`: one load now
  emits one healthy state per stream, both at nonce 0. The assertion's point
  (one bump per failure, one reset between) is unchanged. 1 failure fixed.

### Done — 2. Merge-induced lie on both screens (2 lines each, mirrored)

Before the merge a screen's `loaded` + "no data" state could only mean "no
active child". With two streams it can also mean *this* screen's stream failed
while the sibling's is healthy — and both screens then said `Who's playing?`,
sending a real child to the picker with a Choose button instead of a retry:

- `pip_nest_view.dart`: `loaded` + `nest == null` + `evolution != null` → the
  failure card (with its working retry), `_NoActiveChild()` only when both are
  null.
- `pip_evolution_view.dart`: `loaded` + `evolution == null` + `nest != null` →
  `_EvolutionFailure(profile: nest.profile)` (the nest's last-known Pip +
  retry), `_EvolutionNoChild()` only when both are null.
- Proof, one test each (no production behaviour changed for the paths K06/K07
  already covered): `pip_nest_states_test.dart` "the K07 stream healthy and
  this one failing: the failure card, not the who-is-playing card" (new
  `_FailingNestOnlyRepository`) and `pip_evolution_view_test.dart` "the nest
  stream healthy and this one failing: the failure card, not the who-is-playing
  card" (new `_FailingEvolutionOnlyRepository`). Both assert the failure copy,
  the real tap action and that the who-is-playing card is absent.

### Left

- Nothing from 2a: its layer was complete and its 41 tests still pass.
- 2b's own item 2 — the `shot.sh` + `compare.py` run against
  `design/screens/{light,dark}/K07-evolution.png` — is owed by `5_ui` (that is
  the only stage allowed to boot simulator
  `604697A9-11DA-462F-9837-396E9CA2493A`). Its geometry table in
  `2b_build_ui.md` is the app-side expectation to compare against.
- 2b's item 3 — optional polish (a K07-specific failure card instead of K03's
  shapes) — stays optional; copy/layout decision, not a defect.
- Note for `5_ui`: the design PNG is a **stage-4** screen
  (`Pip grew into a Songbird!`, one 34 px hero line). The seeded child is stage
  3, so `Pip grew into a Fledgling!` measures 351.7 px in the 350 px content
  box and wraps to **two lines** — exactly as the browser would — which puts the
  sub/stats/caption 34 px lower than the PNG while the stage slot and the bar
  stay put. DB-driven content is exempt from ±2 px (UI VERDICT RULE) and both
  readings are pinned in `pip_evolution_widget_test.dart`. Do not "fix" it by
  shrinking the heading, adding tracking or breaking the 20 px gutter.

## Gates (tails)

```
$ dart format .
Formatted 605 files (0 changed) in 2.01 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.9s)

$ flutter test --timeout 120s test/features/pip
00:24 +288: All tests passed!

$ flutter test --timeout 120s
04:19 +3917 ~4: All tests passed!
```

(`~4` = the suite's own skipped tests; 0 failures.)

Files changed by this stage only:
`app/lib/features/pip/presentation/views/pip_nest_view.dart`,
`app/lib/features/pip/presentation/views/pip_evolution_view.dart`,
`app/test/features/pip/pip_nest_states_test.dart`,
`app/test/features/pip/pip_buy_result_test.dart`,
`docs/screens/K07/2_build.md`. Nothing outside RULES §1; no
`analysis_options` change, no `google_fonts`, no `flutter clean`, no simulator.

VERDICT: PASS