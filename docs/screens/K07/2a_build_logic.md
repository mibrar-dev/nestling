# CONTRACT CHANGES — read this before coding against the bloc

**None in iteration 3.** The public surface the UI builder codes against is
byte-identical to what iteration 2 shipped:

- `PipState`'s constructor, `props`, `nestSettled` / `evolutionSettled`,
  `nestError` / `evolutionError`, `errorMessage`, `nestStatus` /
  `evolutionStatus`, `items`, `copyWithLoaded`, `copyWithEvolution`,
  `withNestError`, `withEvolutionError`, `withActionStarted`,
  `withActionFailed` — all unchanged in shape and name.
- Every `PipEvent` is unchanged.
- The only edit to an existing member is **additive and defaulted**:
  `PipState.toLoading({bool restartingNest = true, bool restartingEvolution =
  true})`. A caller with no arguments (every existing fixture, and
  `pip_buy_result_test.dart:480`) gets exactly iteration 2's behaviour — a full
  reload — so nothing outside the bloc had to be touched. No view reads
  `toLoading()`.

Iteration 2's CONTRACT CHANGES §1 and §2 stand as written (2b has since applied
both: `pip_evolution_view.dart` switches on `state.evolutionStatus`, and the
"quests done" card reads `evolution.questsFinishedCount`).

---

# K07 · Stage 2a — build, logic chunk (iteration 3)

Scope owned: `app/lib/features/pip/domain/**`, `data/**`,
`presentation/bloc/**`, the feature's DI/route files, and the
`bloc` / `repository` / `data` tests in `app/test/features/pip/`. **No file
under `presentation/views/**` or `presentation/widgets/**` was touched by this
stage** (2b owns those), and no simulator was booted, installed on, driven or
screenshotted (RULES §1, loop brief). 2b was working in the same worktree
concurrently; their in-flight edits appear in `git status` but are not mine.

## Files changed

| file | change |
|---|---|
| `lib/features/pip/presentation/bloc/pip_state.dart` | `toLoading()` now takes `restartingNest` / `restartingEvolution` (both default `true`) and resets only the streams that are actually restarting; `status` is derived via the existing `_combine` instead of being hard-coded `loading` |
| `lib/features/pip/presentation/bloc/pip_bloc.dart` | `_onLoadRequested` passes `restartingNest: _nestSub == null, restartingEvolution: _evolutionSub == null` — the one null subscription is exactly the stream that died and is about to be re-listened by `??=` |
| `test/features/pip/pip_evolution_bloc_test.dart` | **+3 tests**: the state-level reset (both directions + the error-slot rule + the unchanged defaults) and two bloc-level proofs that the *surviving* stream never dips back to `loading` while the sibling retries |

Nothing else in the layer needed changing: `domain/entities/pip_evolution.dart`
(`questsDone` rows + `questsFinished` distinct), `data/pip_repository_impl.dart`
(`watchEvolution`, lifetime, no clock), `domain/pip_repository.dart`,
`pip_routes.dart` and `pip_di.dart` are as iteration 2 left them and were
re-verified by reading and by the gates below.

## Items done (from `docs/screens/K07/FIXES_2.md`)

### FIXES_2 "Carried from stage 4" item 1 (`4_review.md` finding 1, MINOR) — **fixed in this layer**

`toLoading()` dropped **both** streams' arrival flags (and both error slots)
while `_onLoadRequested` re-subscribes with `??=`, so a retry after a
single-stream failure kept the healthy subscription alive and reported its own
status as `loading` until some unrelated table write re-emitted it — a screen on
a spinner with no retry affordance, since the retry button only exists on the
`failure` branch.

The reset is now explicit about what is being restarted:

```dart
emit(state.toLoading(
  restartingNest: _nestSub == null,
  restartingEvolution: _evolutionSub == null,
));
```

- a **restarting** stream drops its arrival flag and its error slot and returns
  to `loading` until the new subscription answers (unchanged behaviour, and the
  only behaviour on a cold open, where both subscriptions are null);
- a **surviving** stream keeps its flag, its error slot and therefore its own
  `nestStatus` / `evolutionStatus` — it is still streaming, and its data stays
  on screen.

`status` is now `_combine(...)`d from the same inputs instead of being
hard-coded `PipStatus.loading`, so the aggregate can never disagree with the two
per-stream statuses it is defined from (the same lesson as
`copyWithLoaded`'s sibling-slot comment).

**Proofs, all green, and they bite** — with the old `emit(state.toLoading())`
restored, exactly the two new bloc-level tests fail; with the fix, all pass:

| test | asserts |
|---|---|
| `a retry resets only the stream it actually restarts (4_review.md finding 1)` | nest retry ⇒ `nestStatus == loading` **and** `evolutionStatus == loaded`; the mirror; a restart clears only its own error slot (the sibling's recorded error survives, so its status stays honest); the no-argument defaults still mean "full reload" |
| `a retry keeps the SURVIVING stream loaded (4_review.md finding 1)` | the review's requested proof: nest fails before answering, evolution is healthy and loaded, "Try again" is dispatched, the nest stream is re-subscribed and the evolution stream **never emits again** — every published `evolutionStatus` is `loaded`, the celebration is never blanked, and the nest recovers to `loaded` when it answers |
| `the mirror: a retried evolution leaves the NEST stream loaded` | the same in the other direction (K06's data survives K07's retry) |

### FIXES_2's own table — all four already closed before this stage, re-verified

`PipEvolution` still carries rows + distinct quests (`K07-BUG-3`), the state
still has per-stream arrival and error slots (`K07-BUG-1`), and the whole
iteration-2 gate suite for this layer is green (below). Nothing in this layer
was reopened by iteration 3's bug hunt.

### K07-BUG-5 (MAJOR, the only open item in FIXES_2) — **2b's file, 2b in flight**

The fix is `presentation/widgets/pip_evolution_sparks.dart` only, which this
stage may not edit (`ORCHESTRATOR_NOTES.md` 23:55: "Fix in
`pip_evolution_sparks.dart` only"). Observed landing in the shared worktree
while this stage ran: `_Spark.colorOf` now resolves through `NestColors.light`
(`:92-96`) and the stroke paints with `NestColors.light.ink` (`:167`), and the
parked proof's `skip: true` has been dropped from `k07_bugs_test.dart`
(`git diff` → 1 deletion, that line only). 2b also owns
`pip_evolution_sparks_test.dart` (`4_review.md` finding 3) and the
`pip_nest_states_test.dart` fixture from CONTRACT CHANGES §1. **Nothing owed to
this layer**; the note is here so the integrator knows those three files belong
to the other builder, not to an uncommitted half-finished state.

## Deliberately not actioned

- **`4_review.md` finding 2** — the `evolutionSub(0)` zero branch is in
  `presentation/widgets/pip_evolution_copy.dart` (2b's), and the review itself
  says the wording needs the orchestrator's sign-off. `ORCHESTRATOR_NOTES.md`
  has no ruling, so no copy was invented here. 2b's
  `k07_bugs_test.dart` control (`0 and 999999999 coins…`) pins today's wording,
  so the copy fix will have to move that assertion on purpose.
- **`SHARED_REQUEST.md` §2 — the screen-scoped load event.** No orchestrator
  ruling, and `docs/ARCHITECTURE.md:85` mandates one
  `<Feature>LoadRequested` per feature, so `PipLoadRequested` still opens both
  streams. Iteration 2's cost measurement stands (three extra Drift watches per
  `/pip-evolution` entry, no data or state impact). Unchanged on purpose.
- **`SHARED_REQUEST.md` §1 / §3** — notes for the orchestrator, no code.
- No simulator, no `flutter clean`, no `analysis_options` change, no skipped
  test, no `google_fonts`, no `DateTime.now()`, no `pkill`.

## Gates (this layer only, every run with `--timeout`)

```
$ dart format --output=none --set-exit-if-changed \
      lib/features/pip/presentation/bloc lib/features/pip/domain \
      lib/features/pip/data lib/features/pip/pip_routes.dart \
      lib/features/pip/pip_di.dart test/features/pip/pip_evolution_bloc_test.dart
    Formatted 13 files (0 changed)

$ flutter analyze lib/features/pip/presentation/bloc lib/features/pip/domain \
      lib/features/pip/data test/features/pip/pip_evolution_bloc_test.dart
    No issues found!

$ flutter test --timeout 120s test/features/pip/pip_evolution_bloc_test.dart
    → +30: All tests passed!   (3 new proofs, no skips)

$ flutter test --timeout 120s test/features/pip/pip_evolution_bloc_test.dart \
      test/features/pip/pip_bloc_test.dart test/features/pip/pip_bloc_actions_test.dart
    → +71: All tests passed!

$ flutter test --timeout 120s test/features/pip/pip_evolution_repository_test.dart \
      test/features/pip/pip_repository_test.dart test/features/pip/pip_evolution_data_test.dart \
      test/features/pip/pip_atomic_writes_test.dart
    → +52: All tests passed!

# backwards compatibility of the defaulted signature (not this stage's file):
$ flutter test --timeout 120s test/features/pip/pip_buy_result_test.dart
    → +21: All tests passed!   (its `failed.toLoading()` no-arg call still compiles)
```

Negative control for the new proofs: reverting only the bloc's call site to
`emit(state.toLoading())` makes **exactly** the two new bloc-level tests fail
(`+28 -2`) and nothing else — so they pin the fix, not the fixtures.

### In-flight files seen mid-stage (not this layer's, not a finding)

`flutter analyze lib/features/pip` reported 2 errors in
`presentation/widgets/pip_evolution_sparks.dart` (`missing_required_argument`,
`undefined_method 'colorOf'`) and 1 in
`test/features/pip/pip_nest_states_test.dart`
(`closeEvolutionGate` undefined at `:209`) while 2b was mid-edit on both. Every
run above happened with this layer's files at rest; the integrator should
re-run the directory once 2b has landed, per the PROCESS rule this is the
loop's and the orchestrator's to sequence, not a blocker here.

## LEFT FOR NEXT ITERATION

- Nothing in this layer. `watchEvolution`, `PipEvolution`, the dual-stream
  `PipLoadRequested` state machine and its retry semantics are complete and
  proven; the only remaining K07 work sits in `presentation/views/**`,
  `presentation/widgets/**` and their tests (2b's), plus the UI check's
  re-measure of the dark sparkles.

VERDICT: PASS