# K07 · Pip evolves (`/pip-evolution`) — Stage 6 bug hunt (iteration 2)

Adversarial pass over K07 as it stands after stage 2 (`2_build.md`), the
iteration-2 `1_plan.md`, and the stage-3/4 test + review work. **This stage
changed no product code** — RULES §1 lets a bug hunt add only
`app/test/features/pip/**` and `docs/screens/K07/**`, and `git status app/lib`
is empty at the end of the stage. No simulator was booted, installed on or
driven (only `5_ui` may touch `BC440E48-B3A3-43BC-971B-0EF5DB621874`; the
screenshots quoted below are the ones `5_ui.md` already captured). No
`flutter clean`, no `analysis_options` change, no skipped gate.

Deliverable: `app/test/features/pip/k07_bugs_test.dart` — **6 skipped failing
proofs** (K07-BUG-1 ×2, K07-BUG-2, K07-BUG-3 ×2, K07-BUG-4) plus **8 tests that
PASS** and pin what the hunt cleared.

Iteration 1's `6_bugs.md` found K07-BUG-1 and K07-BUG-2. Both are **still open**
— the tree's product code is byte-identical to iteration 1's build
(`7a649a7`), so their ids, proofs and severities carry forward unchanged, and
this stage re-measured rather than assumed them. K07-BUG-3 and K07-BUG-4 are
new.

## Verdict summary

| # | Severity | Summary | Proof |
|---|---|---|---|
| K07-BUG-4 | **MAJOR** | Every confetti sparkle silently loses its `M` tip vertex: `Path.moveTo` draws nothing and `addPolygon(close: true)` closes to the polygon's *own* first point, so the design's 4-point sparkle paints as a flat-topped blob. This is the exact cause of `5_ui.md` **D2** — and the plan/template were already correct, which is why the review missed it. | `k07_bugs_test.dart` → `K07-BUG-4: every confetti sparkle loses its \`M\` tip vertex…` (rasterised painter) |
| K07-BUG-1 | **MAJOR** | A *pending* evolution stream is rendered as the load-failure card "Oh no! Pip got lost.", and that card's only recovery control ("Try again") is a no-op while the stream is in flight. Systematic on this route. | `…k07_bugs_test.dart` → `K07-BUG-1: a still-pending evolution stream…` (widget, fake repo) + `K07-BUG-1 (real repository, no fakes)…` (state level, `PipRepositoryImpl`) |
| K07-BUG-3 | minor | The `quests done` stat counts completion **rows**, not quests, so a re-completable daily/weekly quest inflates the milestone (and contradicts the sub-line, which counts the same rows). | `…k07_bugs_test.dart` → `K07-BUG-3: the "quests done" card counts completion ROWS…` (widget) + `K07-BUG-3 (repository, no widget tree)…` |
| K07-BUG-2 | minor | At 320 px the grown 240 px Pip covers the 68 px "before" Pip and the 30 px arrow, so the before → after story is unreadable. | `…k07_bugs_test.dart` → `K07-BUG-2: at 320 px the grown 240 px Pip covers…` |

**VERDICT: FAIL** — two major bugs (K07-BUG-4, K07-BUG-1).

---

## K07-BUG-4 — MAJOR — every sparkle loses its tip vertex (the real cause of `5_ui.md` D2)

**Where** `app/lib/features/pip/presentation/widgets/pip_evolution_sparks.dart:168-179`
(`_sparkPath`).

**Repro (deterministic, ~1 s)**

1. Pump `PipEvolutionSparks` in light, take its `CustomPaint.painter`, and
   rasterise it at `EvolutionSparksGeometry.artSize` (350×220).
2. Scan the lilac fill in the art's left 100 px — sparkle 1 alone.
3. The painted box is **art rows 46..60 (14 px tall)**, widest at row 48, i.e.
   a shape whose flat top sits at y 46 and whose single point drops to y 60.

The design's `M32 30 37 44 51 49 37 54 32 68 27 54 13 49 27 44Z` is a
symmetric 4-point sparkle: tip (32,30) and base (32,68) are equidistant from the
side points at y = 49. It must paint symmetric about y 49, ~23 px tall after the
3 px ink stroke eats both tips. Measured: **14 px tall, 5 px off-centre**.

`Path.getBounds()` names the cause exactly:

```
SCRATCH buggy bounds: Rect.fromLTRB(13.0, 44.0, 51.0, 68.0)   ← y starts at 44
SCRATCH fixed bounds: Rect.fromLTRB(13.0, 30.0, 51.0, 68.0)   ← y starts at 30
```

`moveTo(numbers[0], numbers[1])` only sets the current point; it **draws
nothing**. `addPolygon(offsets, close: true)` then closes the polygon back to
`offsets.first` — the *second* pair, `(37,44)` — never to the `moveTo` point. So
the tip vertex `(32,30)` is never filled and never stroked, and the top arm of
every sparkle collapses into the flat edge `(27,44) → (37,44)`.

**Why this survived two review rounds.** The `d` strings in `_sparks` are
**byte-exact against `design/html-source/screens/K07-evolution.html` lines
35–46**, `1_plan.md` pins the same template, and `4_review.md` checked the
strings. The defect is in the *parser*, not the data, so every string-level
assertion passed. It was visible in `5_ui.md` D2 as "asymmetric rounded blob
(flat wide top, single downward point)", but that stage concluded the path
template was wrong — which is why `ORCHESTRATOR_NOTES.md` D2 says "fix as the
UI check says" and the path data is in fact already right.

**Affected: all four sparkles, both themes** (the painter is shared), so this is
the screen's confetti, i.e. the thing that makes the celebration read as a
celebration.

**Failing test** — `flutter test --timeout 120s --run-skipped test/features/pip/k07_bugs_test.dart`

```
K07-BUG-4: every confetti sparkle loses its `M` tip vertex, so the design's
4-point sparkle is painted as a flat-topped blob
  Expected: a value greater than or equal to <20>
    Actual: <14>
```

**Suggested fix** (feature-local, RULES §1-legal, 2 lines in
`pip_evolution_sparks.dart`) — drop the `moveTo` and let the polygon own every
vertex, including the tip:

```dart
return Path()
  ..addPolygon(<Offset>[
    for (var i = 0; i + 1 < numbers.length; i += 2)
      Offset(numbers[i], numbers[i + 1]),
  ], true);
```

**Fix verified, then reverted** (this stage may not fix the screen): with the
loop above applied to a scratch copy, the K07-BUG-4 proof goes green
(`00:00 +1: All tests passed!`) and the painted box becomes rows 37..60 with the
widest row on the centre line (asymmetry 5.0 → 0.5). The working tree was then
restored byte-for-byte (`git status app/lib` empty, confirmed after restore), so
the shipped code still fails the proof.

---

## K07-BUG-1 — MAJOR — a still-pending evolution stream is shown as "Oh no! Pip got lost.", and its "Try again" does nothing

*(Unchanged from iteration 1; re-measured against the current tree.)*

**Where**

- `app/lib/features/pip/presentation/views/pip_evolution_view.dart:86-97` —
  `case PipStatus.loaded:` reads `state.evolution`, and when it is null it
  falls through to the sibling stream: `if (nest != null) return
  _EvolutionFailure(...)` (line 95) before `_EvolutionNoChild()` (line 96).
- `app/lib/features/pip/presentation/bloc/pip_bloc.dart:51-68` — the load
  subscribes to the NEST stream first (line 51) and the evolution stream second
  (line 60); line 49's guard `if (_nestSub != null && _evolutionSub != null)
  return;` is what makes the card's retry a no-op.
- `app/lib/features/pip/presentation/bloc/pip_state.dart:60-68` —
  `copyWithLoaded` publishes `PipStatus.loaded` with `evolution == null`.

**Repro (deterministic, 2 s)**

1. Register a repository whose `watchNest()` is the real one and whose
   `watchEvolution()` is an open, silent stream (no value, no error).
2. Pump `/pip-evolution`.
3. The screen shows **"Oh no! Pip got lost." / "Let's try again." /
   `Try again`** with no Pip, no title, no CTA — while the only thing true of
   the screen is that its data is still in flight.
4. Tap `Try again`: `evolutionCalls` stays at 1. The bloc guard sees both
   subscriptions as live and drops the event, so the kid's only way out of the
   card does nothing.

**Failing tests** (two, so the fake cannot be blamed for the timing)

```
K07-BUG-1: a still-pending evolution stream renders the load-failure card…
  Actual: _TextWidgetFinder:<Found 1 widget with text "Oh no! Pip got lost.": […

K07-BUG-1 (real repository, no fakes): the bloc publishes a "loaded" state with
a nest but no evolution, which /pip-evolution renders as "Oh no! Pip got lost."
  5 of 5 cold opens published `loaded` before the evolution arrived
```

The second proof runs five cold opens against the shipped `PipRepositoryImpl`
with the demo seed and no widget tree: **5 of 5**, not a race. `PipLoadRequested`
subscribes nest-first by construction (`pip_bloc.dart:51` then `:60`) and both
streams start from the same `watchAppState()` emission, so the ordering is
structural.

**Visible impact.** In the shipped timing the two emissions are fractions of a
millisecond apart, so they usually coalesce into one painted frame. But the false
state is real on *every* cold open, and it becomes visible whenever the second
query is slower than a frame: a cold database, a big `quest_completions` table,
a busy isolate. The persisted form is worse — if `watchEvolution()` is slow or
hung, the child sits on an alarming error card with a **dead** "Try again" and
no way out except the parental gate.

**Suggested fix** (feature-local, RULES §1-legal; identical to iteration 1's
and to `4_review.md` finding 1). Give each stream its own arrival flag in
`PipState` (e.g. `nestSettled` / `evolutionSettled`, set in `copyWithLoaded` /
`copyWithEvolution` and both `…Failed` handlers, carried through the other
`copyWith*` helpers and `props`), and let each view gate on **its own** stream:

```dart
case PipStatus.loaded:
  final evolution = state.evolution;
  if (evolution != null) return _EvolutionBody(evolution: evolution);
  // nest != null only proves K06's stream spoke; it says nothing about ours.
  return const _EvolutionNoChild();          // ← delete the line-95 branch
```

with the loading branch keyed on `!evolutionSettled && errorMessage == null`, so
a pending screen shows the spinner and a failed one shows the card. Second,
independent hardening: `_onLoadRequested`'s guard should ignore a repeat load
while the *pending* card is showing, or the retry button should not be offered
until its own stream has settled.

---

## K07-BUG-3 — minor — "quests done" counts completion rows, not quests

**New this iteration.**

**Where**

- `app/lib/features/pip/data/pip_repository_impl.dart:96-99` —
  `questsDone = completions.where((c) => c.status == 'done_pending' ||
  c.status == 'approved').length` — a row count, with no `distinct` on
  `questId`.
- `app/lib/features/pip/presentation/widgets/pip_evolution_copy.dart:39-41` —
  `evolutionSub` renders the same number as "Because you helped N times".

**Repro (deterministic, 2 s)** — the demo seed has Maya with 4 **distinct**
quests done (`q-dishwasher` + `q-table` pending, `q-bins` + `q-hoover`
approved). Insert one more `approved` completion for `q-bins` — legal, and
routine: a `daily`/`weekly` quest is re-completable, and nothing in the schema
forbids a second row for the same `(questId, childId)`.

```
K07-BUG-3 (repository, no widget tree): watchEvolution reports 5 for 4 distinct
quests after one quest is completed twice
  Expected: <4>
    Actual: <5>
  5 completion rows cover only 4 distinct quests (q-dishwasher, q-table,
  q-bins, q-hoover), so "quests done" counted rows, not quests
```

The widget proof reads the painted card: the number under `k07-stat-quests` is
`'5'` where `'4'` is correct, while the sub-line correctly reads "Because you
helped 5 times".

**Why it matters on this screen specifically.** K07 is a *milestone* screen: the
stat card is the number that goes with Pip's stage, and the card's own label is
`quests done`. A child who completes one daily quest for a month reads
"30 quests done" for one quest. Worse, the two numbers on the screen then
disagree — the card says 30 quests, the sub-line says 30 times, and the child can
see that they are not the same claim.

**Suggested fix** (feature-local): count distinct quests for the card, keeping
the row count for the sub-line, since "helped N times" is honestly per
completion:

```dart
final counted = completions
    .where((c) => c.status == 'done_pending' || c.status == 'approved');
final questsDone = counted.length;                 // the sub-line ("times")
final questsFinished = counted.map((c) => c.questId).toSet().length;  // the card
```

which needs one more field on `PipEvolution` (or the card fed a second value).
If the product really wants the row count everywhere, then the card's label is
what must change — but that label is the design's (`K07-evolution.html:61`), so
the count is the cheaper side to fix. `1_plan.md` §(b) chose rows deliberately
("a lifetime milestone"), so this needs the plan's author to confirm which of the
two sentences the number is meant to be; either way the two must not contradict
each other.

---

## K07-BUG-2 — minor — at 320 px the grown Pip covers the "before" Pip and the arrow

*(Unchanged from iteration 1; re-measured.)*

**Where** `app/lib/features/pip/presentation/widgets/pip_evolution_stage.dart:97-142`
(`.k7-stage` slot) with `EvolutionStageGeometry`: `oldSize 68` at `left: 2`,
`arrowSize 30` at `left: 76`, `newSize 240` at `right: 6`.

**Repro** pump `/pip-evolution` on a 320×844 surface (a supported width —
`docs/design/SPACING_SPEC.md:369` plans 320 layouts) and measure the three boxes:

```
arrow 96.0..126.0     grown Pip 54.0..294.0     old Pip 22.0..90.0
newRect.left - arrowRect.right = -72   (the design allows -2)
```

The slot needs `2 + 68 + 6 + 30 + 6 + 240 = 352` px and only has 280, so the
fixed-size grown Pip slides 72 px left over the arrow and 36 px over the old
Pip. The arrow and the faded "before" silhouette are painted underneath the
grown Pip — the one thing the screen exists to show (before → after) is
illegible at that width.

**Failing test** — `k07_bugs_test.dart` → `K07-BUG-2: at 320 px the grown 240 px
Pip covers the 68 px old Pip and the 30 px arrow…`

```
Expected: a value greater than or equal to <-2.0>
  Actual: <-72.0>
   at 320 the arrow sits entirely inside the grown Pip's box
   (arrow 96.0..126.0, Pip 54.0..294.0)
```

**Suggested fix** (feature-local, no shared change): make the slot's three
pieces scale with the available width instead of being fixed — e.g. wrap the
slot content in a `FittedBox(fit: BoxFit.scaleDown, alignment: bottomRight)` or
size the grown Pip as `min(240, slotWidth - oldSize - arrowSize - gaps)` while
keeping the 390 px geometry byte-identical (the UI check measured 240/68/30 and
the ±2 px budget must survive). A cheaper acceptable alternative: below ~352 px
of slot width drop the old-Pip silhouette and centre the grown Pip, the way the
stage-1 branch already does.

---

## Investigated and cleared (no bug — recorded so it is not re-reported)

1. **A synchronously failing stream leaves the failure card's retry dead.**
   Hypothesis: `_evolutionSub ??= …listen(onError: …)` runs the handler *before*
   the assignment, so a stream that errors inside `listen()` leaves a dead
   subscription and `pip_bloc.dart:49` blocks every later retry.
   **Disproved by measurement**: Dart delivers `Stream.error` in a microtask,
   *after* `listen()` returns, so the handler sees the real subscription and
   clears the field. Both failure-delivery shapes Dart offers (`Stream.error` and
   `addError` on a controller) are pinned by a PASSING test, `cleared: after a
   REAL stream failure "Try again" really re-subscribes (both Dart
   failure-delivery shapes)`. (Only a `StreamController.sync` whose `onListen`
   pushes the error could break the guard; no repository in the app builds one.)
2. **Data edge cases — all clean.** 0 children / `activeChildId = null`
   ("Who's playing?" + `Choose` → `/who-is-playing`, no retry button), a ghost
   `activeChildId` (same card), 1 child, **6 children** (the screen follows the
   ACTIVE child only — with four extra rows inserted, Maya still renders
   `stage 3, quests 4`), `pip_stage` 0 and 5 (clamped to 1..4, no `PipAvatar`
   assert), 0 and 1 completions (`Because you helped 0 times` / `… 1 time`
   singular), 9999 coins, and a 19-character name (`Maximilian-Alexander`) at
   320 px / text scale 1.3 / dark — no overflow, no exception, `9999` intact in
   the merged stat sentence.
3. **A child picked AFTER the no-child card live-updates into the celebration.**
   New this iteration and worth pinning: `active_child_id` going null → `'leo'`
   must take the screen from "Who's playing?" to `Pip grew into a Hatchling!` /
   `Because you helped 2 times` / `Meet Hatchling Pip` with **no reload and no
   dead end**. PASSING (`control: the no-child card live-updates…`), so the
   `_switchMap` + `combineLatest2` chain in `watchEvolution` is correct in both
   directions.
4. **Switching the active child Maya → Leo retitles the whole screen.**
   Also new this iteration. A live switch must move the hero, the sub-line, the
   coins, the CTA and the Pip's VoiceOver image label together
   (`Maya's Pip, a fledgling` → `Leo's Pip, a hatchling`), with no stale frame
   and no exception. PASSING (`control: switching the active child Maya -> Leo…`).
5. **Rapid taps — clean.** Double-tap CTA navigates to `/pip` once; double-tap
   lock opens `/parental-gate` once and popping it returns to `/pip-evolution`
   with the CTA still working; double-tap retry re-subscribes once.
6. **Restart / Drift persistence — clean.** Writing a new `pip_stage` and
   `pip_total_coins` and re-reading yields `{questsDone 4, stage 4, coins 260}`
   — nothing on this screen is cached in memory, so nothing is lost across a
   restart. (Iteration 1 additionally proved the file-backed reopen path.)
7. **Kid-mode guard — correct, including the trial path.** A cold deep link to
   `/pip-evolution` in kid mode with an aged `trial` row lands on
   `/parental-gate` (`router.dart:127-132`); measured
   `trialExpired=true → path=/parental-gate`. `/pip-evolution` is not on the
   `parentOnly` list, so a parent may inspect it (intended). No bypass found.
8. **Dark-mode contrast — clean.** Every text pair on the screen clears 4.5:1
   (measured iteration 1: light — title/sub/number `ink` on `surface` 16.50,
   caption + stat label `ink2` 8.87, CTA `onAccent` on `lilacStrong` **5.03**,
   the worst pair on the screen; dark — ink 14.76, `ink2` 9.82, CTA 7.74).
9. **Async gaps — clean.** A bloc closed while both streams are live tolerates a
   late `addError` on both subscriptions with no `StateError`. New this
   iteration: a DB write committed while the whole app is torn down mid-load
   throws nothing (`control: a late stream emission after the app is torn down
   throws nothing`) — no add-after-close, no emit-after-close.
10. **Timezone / money rounding — not applicable.** K07 reads no clock at all
    (`watchEvolution` counts rows; `pip_evolution_copy.dart` says so
    explicitly) and shows no `£` (the jar screens own money). Its only numbers
    are lifetime integer counts, so there is nothing to round. The PERIODS
    ruling (`countsForCurrentPeriod`) does not apply to a lifetime milestone;
    the seed's Maya completions (2 `done_pending` + 2 `approved`, all inside the
    current London week) give 4 either way, so the screen's demo numbers are
    period-independent and the BST change cannot move them.

## Test-harness note (not a product bug, but it cost this stage time)

A Drift **write issued while the app is pumped** inside `tester.runAsync`
deadlocks this harness when the written table is one a live watch is sitting on:
measured on an `INSERT` into `quest_completions` with `watchCompletionsForChild`
live, hanging at the `await`, with `--timeout` unable to fire because the await
is inside the fake-async zone. Iteration 1 hit the same wall on `db.delete`
inside a pumped test. K07-BUG-3's widget proof therefore writes **before** the
first pump, and its second proof is a plain real-async `test` with no widget
tree. This is a harness constraint, recorded here so the next stage does not
re-derive it — it is not a K07 defect.

## Observations (not findings)

1. **Nothing in the app links to `/pip-evolution`.** `PipRoutePaths.evolution`
   has no call site outside `pip_routes.dart`; the only ways in are a deep link
   or `--dart-define=INITIAL_ROUTE`. `1_plan.md` §(c) does not require an
   inbound link (K07 is a "moment" screen and the CTA *leaves* to `/pip`), so
   this is not a screen defect — but if the intended flow is "K06 celebrates a
   stage-up by opening K07", that entry point does not exist yet and belongs to
   the K06/flow owner.
2. **The three non-design states still paint an empty bottom bar** (review
   finding 8, accepted): `_EvolutionBar()` with `stage: null` renders the band
   with its 3 px ink rule and no CTA. K07-BUG-1's false-failure frame is one of
   the frames that shows it.
3. **The two apostrophe styles in the announcements** (review finding 5) still
   hold: `'Loading Pip’s big moment'` uses a curly ’ where every other string in
   the screen uses the ASCII `'` that the HTML source writes.
4. **The design's `#3D7FF0` sparkle dot is not a token** (`3_test.md`
   observation 1) — unchanged; still the screen painting `tokens.sky`.
5. **`flutter test test/features/pip/` can stall.** Iteration 1 recorded 7
   minutes of no progress inside `pip_buy_result_test.dart` while running the
   whole directory (alone that file is green in 3 s); `--timeout` cannot fire on
   a test awaiting inside the fake-async zone. This stage therefore ran the ten
   K07-related files explicitly (138 pass, 10 skipped) rather than the
   directory. Not caused by, and not fixable from, K07's screen.

## Gates

```
cd app
dart format test/features/pip/k07_bugs_test.dart            → 1 file, no change
flutter analyze test/features/pip/k07_bugs_test.dart          → No issues found!
flutter analyze test/features/pip/                           → No issues found!

flutter test --timeout 90s test/features/pip/k07_bugs_test.dart
  → +8 ~6: All tests passed!        (8 controls green, 6 proofs parked)

flutter test --timeout 90s --run-skipped test/features/pip/k07_bugs_test.dart
  → +8 -6:  exactly the six proofs fail, none hangs:
      K07-BUG-1 (widget)                      → "Oh no! Pip got lost." found
      K07-BUG-1 (real repository, no fakes)   → 5 of 5 cold opens
      K07-BUG-2 (320 px)                      → Expected >= -2.0, Actual -72.0
      K07-BUG-3 (widget)                      → Expected '4', Actual '5'
      K07-BUG-3 (repository, no widget tree)   → Expected <4>, Actual <5>
      K07-BUG-4 (rasterised sparkle)           → Expected >= 20, Actual 14

# the ten K07-related files together, stage-3/4 suites included:
flutter test --timeout 120s test/features/pip/pip_evolution_*.dart \
  test/features/pip/k07_*.dart
  → +138 ~10: All tests passed!
```

Every gate ran with a per-test timeout (`--timeout 90s` / `120s`); no run was
waited on for more than ten minutes and none hung. The stage-3/4 K07 suites
(`pip_evolution_*_test.dart`, `k07_sparkles_bug_test.dart`) were read and run
but **not edited** by this stage.

Scratch probes (`zz_scratch_sparks_probe_test.dart`, `zz_probe_more_test.dart`)
were exploratory and are **deleted**; every number they produced is either quoted
above or pinned by a permanent test in `k07_bugs_test.dart`.

`SHARED_REQUEST.md` stays as filed (iteration 1). All four fixes are in-feature
(`pip_evolution_view.dart`, `pip_bloc.dart`, `pip_state.dart`,
`pip_evolution_stage.dart`, `pip_evolution_sparks.dart`,
`pip_repository_impl.dart`, `pip_evolution.dart`), which RULES §1 puts in this
branch's scope.

## Verdict

Two major bugs. **K07-BUG-4** is the screen's confetti: all four sparkles paint
as flat-topped blobs in both themes because `_sparkPath` drops each path's `M`
tip vertex — the path *data* was already correct, which is exactly why the
review passed it and `5_ui.md` D2 could only report the symptom; the fix is two
lines and is verified green. **K07-BUG-1** puts a false "Oh no! Pip got lost."
card with a dead "Try again" on the celebration screen's systematic cold-open
path (5/5 cold opens with the shipped repository). K07-BUG-3 (rows counted as
quests) and K07-BUG-2 (320 px overlap) are minor and independent.

VERDICT: FAIL
