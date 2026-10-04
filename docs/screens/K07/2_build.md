# K07 · 2 BUILD (integrate, iteration 2) — 2a logic + 2b UI combined

Job: make the two parallel halves compile and pass together. No simulator was
booted (only `5_ui` may), no design was redesigned, no shared file was touched
(RULES §1: `features/pip/**` + `test/features/pip/**` + this folder only).

## What landed

### 2a — non-UI layer (`2a_build_logic.md`, iteration 2)

A real contract change this time, published at the top of its note as
CONTRACT CHANGES:

- `PipState` now tracks **each stream on its own**: `nestSettled` /
  `evolutionSettled` (a null emission counts as answered — "no child" is a
  healthy answer), the diagnostic-only slots `nestError` / `evolutionError`,
  and the getters `nestStatus` / `evolutionStatus` that each screen must
  switch on. The aggregate `status` is now the AND of both streams
  (`_combine`), so a sibling stream can neither fake readiness nor fake a
  failure. `withStreamError` / `toFailure` are replaced by `withNestError` /
  `withEvolutionError`; `status`, `nest`, `evolution`, `errorMessage`,
  `actionError`, `actionNonce` and every event keep their shapes.
- `PipEvolution` gained `questsFinished` (DISTINCT quests) beside `questsDone`
  (completion ROWS), with `questsFinishedCount` falling back to the row count —
  K07-BUG-3's data half. `watchEvolution` reports both.
- Fixed `4_review.md` finding 2 / `6_bugs.md` **K07-BUG-1** (MAJOR): "Oh no!
  Pip got lost." on 5/5 cold opens, because `PipLoadRequested` subscribes nest
  first and the nest's arrival used to publish `loaded`. Proofs un-skipped and
  green (`pip_evolution_bloc_test.dart`, `k07_bugs_test.dart` state level).
- Also folded in `4_review.md` finding 10 (error slots written per stream) and
  finding 3 (the `cascade_invocations` analyze info, which gated).

### 2b — presentation layer (`2b_build_ui.md`, iteration 2)

- Both views now switch on **their own** stream (`state.evolutionStatus` /
  `state.nestStatus`) and the sibling-consult branches are gone, exactly as
  CONTRACT CHANGES §1 requires.
- **K07-BUG-4 / `5_ui` D2** (MAJOR, mandatory via `ORCHESTRATOR_NOTES.md`):
  every sparkle lost its `M` tip vertex — `Path.moveTo` draws nothing and
  `addPolygon(close: true)` closes to the polygon's *own* first point, so the
  design's 4-point sparkle painted as a flat-topped 7-gon. `_sparkPath` now
  hands every vertex to one `addPolygon`; measured art band moved from
  `y 449..528` onto the design's own `y 407..528`. The four `Path`s are also
  parsed once and cached (finding 11).
- **K07-BUG-3** widget half: the `quests done` card renders
  `evolution.questsFinishedCount` (distinct quests) while the sub-line keeps
  the row count it honestly calls "times".
- **K07-BUG-2**: the stage slot is wrapped in `FittedBox(scaleDown,
  bottomRight)` only below 350 px of width — at 390 the geometry is
  byte-identical (scale 1.0), at 320 the arrow and the "before" Pip are legible
  again.
- Finding 5 (the `.kid-bar` 3 px rule is drawn only when there is a CTA; the
  surface box, and so the owner BOTTOM EDGE rule, is untouched), finding 6
  (one ASCII-apostrophe convention, spinner label now `"Loading Pip's big
  moment"`), findings 7 + 8 (stage-1 copy no longer contradicts its own hero
  — `Psst… Pip is still an Egg!` with a real `…`; the three stat labels moved
  into the copy table).
- Every proof un-skipped: `k07_sparkles_bug_test.dart` and `k07_bugs_test.dart`
  run with **zero** skips, and K07-BUG-1's widget proof was honestly rewritten
  (a pending screen shows no retry at all) rather than weakened.

## FIXES

### Done — 1. `2b_build_ui.md` §0: the state dropped the sibling error slot it
### computed `status` from (2 lines, the whole integration breakage)

`copyWithLoaded` / `copyWithEvolution` call `_combine(... evolutionError:
evolutionError)` — they READ the sibling's slot to decide `status` — but the
`PipState` they build did not carry that slot, so it defaulted to null. The
result was a state that contradicted itself: `status == failure` while
`evolutionSettled == false` / `evolutionError == null`, i.e.
`evolutionStatus == loading` — so `/pip-evolution` would sit on its spinner
forever instead of showing its failure card, and `/pip` would spin instead of
retrying. It is not theoretical: the evolution stream's `Stream.error` is
delivered in a microtask while the nest's first emission needs real Drift I/O,
so on the real `PipRepositoryImpl` the error lands FIRST and the healthy
sibling emission then wiped it.

Fixed in `app/lib/features/pip/presentation/bloc/pip_state.dart` (2a's file,
which 2b may not edit — the integrator's job): `evolutionError: evolutionError`
in `copyWithLoaded` and `nestError: nestError` in `copyWithEvolution`, each with
a comment saying why the slot must travel with the state that derived from it.
Recovery still works unchanged: the sibling's own healthy emission clears its
slot, and `toLoading()` re-arms both flags with both slots null, so "Try again"
re-subscribes cleanly.

The two tests 2b predicted red were red (`00:10 +389 -2`) and went green with
the patch. Added one state-level pin in
`pip_evolution_bloc_test.dart` so the invariant cannot rot silently next
iteration: *"a healthy emission CARRIES the sibling error slot status came
from"* — both directions, asserting the slot AND the per-stream status.

### Done — 2. Verified, no change needed

- `2a` CONTRACT CHANGES §1's view wiring (§1's `evolutionStatus` /
  `nestStatus` switch, the two deleted sibling branches) — both views are
  correct in the tree (`pip_evolution_view.dart:84`,
  `pip_nest_view.dart:80`); no leftover `switch (state.status)`.
- §2's `questsFinishedCount` on the `quests done` card — landed.
- `2a`'s warning that 3 cases in `pip_nest_states_test.dart` would stay red
  while K07's stream is silent: **stale**, and deliberately NOT actioned. Those
  are view tests and the views now read `nestStatus`, which the silent sibling
  does not touch — the file is `+19 -1` with the only failure being §0. The
  one-line `_NestOnlyRepository` change 2a proposed would have made the fixture
  diverge from the production shape for no gain, so it stays out.
- `errorMessage` is dropped by the same two methods. Left alone: it is the
  aggregate diagnostic, no view reads it (raw DB text must never reach a kid
  screen), and its docstring says it is cleared by the next healthy emission.

### Left

- **`5_ui` must re-measure the sparkle band** (per `4_review.md` note 1 and
  `2b_build_ui.md` §5): the ink boxes now run 14 logical px higher, onto the
  design's coordinates (`407..528` for all four sparkles). `D2` should clear;
  `D1` stays exempt (orchestrator-accepted DB-truth wrap, +34 px below the
  title) and `D3` stays accepted. That is the only stage allowed to boot
  simulator `BC440E48-B3A3-43BC-971B-0EF5DB621874`.
- **`4_review.md` finding 9** — the orchestrator still owes the explicit ruling
  on the dark-mode sparkle accents (the design's inline SVG hard-codes
  `#7C6CF2` / `#1F9D63` / `#FF8A5B`; "tokens only" wins, so the token re-theme
  stands). No code change either way until it rules.
- **`SHARED_REQUEST.md`** — item 1 (record the K07 background deviation: no
  `KidScope`, no `.meadow` element, lilac glow + the shared dark stars) is
  still a note the orchestrator owes; item 2 (a screen-scoped load event, so
  K07 stops opening K06's stream) is deferred, non-blocking.
- **`4_review.md` finding 4** — accepted as-is by both stages, same request.

### Not my call

Nothing in `FIXES_1.md` is left open on the integration path: every bug 2a/2b
owned is fixed and proven, and the remaining items above are UI-verification,
orchestrator rulings or deferred requests.

## Gates

```
$ dart format .
Formatted 641 files (0 changed) in 1.94 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.0s)

$ flutter test --timeout 120s test/features/pip
00:10 +392: All tests passed!

$ flutter test --timeout 120s
01:48 +4447 ~10: All tests passed!
```

`~10` are the suite's own skips and **none of them is K07's**: they are
`k01_bugs` (1), `k03_bugs` (2), `k09_bugs` (6) and `p12_bugs` (1). The whole
`test/features/pip` directory runs with **zero** skips.

Files changed by this stage only:
`app/lib/features/pip/presentation/bloc/pip_state.dart` (the 2 carry lines +
their comments), `app/test/features/pip/pip_evolution_bloc_test.dart` (one
state-level test), `docs/screens/K07/2_build.md`. Nothing outside RULES §1; no
`analysis_options` change, no `google_fonts`, no `DateTime.now()`, no
`flutter clean`, no simulator, no `Wrap`/`Row` chip rows.

VERDICT: PASS