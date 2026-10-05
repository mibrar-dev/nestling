# CONTRACT CHANGES — read this before coding against the bloc

**None in iteration 5.** The public surface is byte-identical to what
iteration 3 shipped and iterations 4 re-verified, so 2b's views and the tests
that pin the contract are untouched by this stage:

- `PipState`'s constructor, `props`, `evolution`, `items`, `nestSettled` /
  `evolutionSettled`, `nestError` / `evolutionError`, `errorMessage`,
  `nestStatus` / `evolutionStatus`, `copyWithLoaded`, `copyWithEvolution`,
  `withNestError`, `withEvolutionError`, `withActionStarted`,
  `withActionFailed`, `toLoading({restartingNest, restartingEvolution})` — all
  unchanged in shape and name.
- Every `PipEvent` is unchanged, including `PipLoadRequested` (still opens
  both streams — see "SHARED_REQUEST §2" below, still awaiting a ruling).
- `PipEvolution` unchanged: `profile`, `questsDone`, `questsFinished`,
  `questsFinishedCount`, `props`.
- `PipRepository` / `PipRepositoryImpl` unchanged (no lib edit at all this
  iteration — see "Files changed").

---

# K07 · Stage 2a — build, logic chunk (iteration 5)

Scope owned: `app/lib/features/pip/domain/**`, `data/**`,
`presentation/bloc/**`, `pip_di.dart`, `pip_routes.dart`, and the
`bloc` / `cubit` / `repository` / `data` tests in `app/test/features/pip/`.
**No file under `presentation/views/**` or `presentation/widgets/**` was
touched** (2b owns those), and no simulator was booted, installed on, driven
or screenshotted (RULES §1, loop brief).

## Files changed

| file | change |
|---|---|
| `docs/screens/K07/2a_build_logic.md` | this file only |

No `lib/` and no `test/` file changed. The audit below is why: nothing in
`1_plan.md` §(b) is unimplemented, and **not one item in `FIXES_4.md` or
`4_review.md` sits in this layer** — every finding names a views/widgets file
or a shared file, and the only two skipped proofs both measure painted widget
geometry.

## Items done

### FIXES_4 audit — both items are 2b's, not this layer's

| finding | file the fix needs | whose |
|---|---|---|
| K07-BUG-8 (MAJOR) — each `.k7-stats` cell wraps number+label in its own `FittedBox(scaleDown)`, so the three numbers paint at three type sizes and their tops drift 3.16 px at 390 px / 1.3 (2.40 px at 320 px / 1.0) | `presentation/widgets/pip_evolution_stats.dart` | **2b** |
| K07-BUG-9 (minor) — the app-only `maxLines: 3` + ellipsis survives on the caption (`.kcap` sets no clamp) | `presentation/views/pip_evolution_view.dart` | **2b** |

The CORRECTION section (the app shell clamps the OS text scaler to 1.0–1.3,
so 2×–3.2× reachability arguments are unreachable) needs no code anywhere —
it is a bound on future hunt work, recorded here so iteration 6 does not
re-litigate it. The hunt matrix's "timezone / BST / money rounding: provably
n/a" (`watchEvolution` counts rows, reads no clock, renders coins never `£`)
is this layer's property and still holds: no clock read was added, none
exists.

The two parked proofs (`k07_bugs_test.dart:1793` K07-BUG-8, `:1832`
K07-BUG-9) both pump the real view and assert painted rects / widget caps —
neither file matches this layer's `bloc`/`cubit`/`repository`/`data` test
scope, and neither can go green without its view/widget fix. **So the
un-skipping of both belongs to 2b**, landing together with the two fixes in
one commit. This stage left both `skip: true` lines in place rather than
half-opening a proof it cannot make green. Verified: the **only** skips in
`test/features/pip` are those two (plus `k07_bugs_test.dart`'s own header
convention); every file in this layer's scope has zero skips
(`grep -n skip` over the six owned files returns nothing).

### `4_review.md` findings — none is this layer's either

| finding | file the fix needs | whose / status |
|---|---|---|
| 1 (MINOR) — stat numbers' baseline splay; `Alignment.topCenter` necessary but not sufficient | `pip_evolution_stats.dart` | **2b** (subsumed by K07-BUG-8's fix) |
| 2 (MINOR) — surviving `.kcap` cap + stale 3.16× comment | `pip_evolution_view.dart` | **2b** (now K07-BUG-9 with a permanent proof) |
| 3 (MINOR) — `evolutionSub(0)` renders "Because you helped 0 times" | `presentation/widgets/pip_evolution_copy.dart:48-50` | **2b**, and blocked on orchestrator wording (`SHARED_REQUEST.md` §5) — no copy invented here |
| 4 (MINOR) — spark/stage count `4` transcribed as a literal in three files | `pip_evolution_view.dart`, `pip_evolution_stage.dart`, `pip_evolution_copy.dart` | **2b** (the suggested `pipStageCount` const lives in `pip_look.dart`, a widget file) |
| 5 (MINOR) — `#3D7FF0` sky dot has no token | `app/lib/core/design_system/tokens/colors.dart` (shared) | **orchestrator** (`SHARED_REQUEST.md` §4); the tokens-only rule forbids painting the literal from this branch |

Checked for layer bleed while auditing finding 4: the only `clamp` calls in
this layer are `coinsToGrow.clamp(0, evolveAtCoins)` (`pip_profile.dart:32`)
and the growth fraction `clamp(0.0, 1.0)` (`pip_nest.dart:18`) — domain value
clamps, not stage-count literals. The out-of-range `pip_stage` clamp
(0/5/99 → 1..4) lives in 2b's stage widget. Nothing to consolidate here.

### `1_plan.md` §(b) — complete, re-verified by reading, not by assumption

- `PipEvolution` (profile + `questsDone` + `questsFinished`), the two-number
  split from K07-BUG-3 and its `props` — present.
- `PipRepository.watchEvolution()`, `switchMap` over `watchAppState()` with
  `combineLatest2(watchProfile(id), watchCompletionsForChild(id))`, null on no
  active child / deleted row — present (`data/pip_repository_impl.dart:80`).
- The `done_pending | approved`, all-time count with **no clock read** — the
  PERIODS ruling correctly does not apply; `pip_evolution_data_test.dart`
  proves yesterday / last-week / last-month rows still count, and iteration
  4's five update-path tests pin the K05/P11 status-UPDATE writes
  (`to_do`→`done_pending` counts +1, approval never double-counts, decline
  takes the credit back).
- `PipBloc`: two guarded subscriptions under the one `PipLoadRequested`, an
  error released only in its own slot, `close()` cancelling both, and the
  iteration-3 `toLoading(restartingNest:, restartingEvolution:)` retry
  semantics — present.
- `pip_routes.dart` (`/pip-evolution` → `BlocProvider(create: …
  PipLoadRequested())` → `PipEvolutionView`) and `pip_di.dart` (lazy
  `PipRepositoryImpl`, factory `PipBloc`) — present and correct.
- `ORCHESTRATOR_NOTES.md` unchanged (19:10 + 23:55 only, both satisfied long
  ago); no `TODO(K07)`, no `google_fonts`, no `DateTime.now()` anywhere in the
  layer or its tests (grep-verified).

## Deliberately not actioned

- **SHARED_REQUEST §2 (screen-scoped load)** — still no orchestrator ruling;
  `docs/ARCHITECTURE.md:85` mandates one `<Feature>LoadRequested` per feature,
  so `PipLoadRequested` still opens both streams. Unchanged on purpose.
- **SHARED_REQUEST §1 / §3 / §4 / §5** — notes for the orchestrator. No code.
- **`watchItems()`'s `?? 'maya'` fallback** — flagged in iteration 4, still
  K06's behaviour and unreachable from any K07 view; touching it would move
  K06's screen for no K07 gain. Unchanged on purpose.
- No simulator, no `flutter clean`, no `analysis_options` change, no skipped
  test, no `google_fonts`, no `DateTime.now()`, no `pkill`.

## Gates (this layer only, every run with `--timeout`)

```
$ dart format --output=none --set-exit-if-changed \
      lib/features/pip/domain lib/features/pip/data \
      lib/features/pip/presentation/bloc lib/features/pip/pip_di.dart \
      lib/features/pip/pip_routes.dart <all 7 owned test files>
    Formatted 19 files (0 changed)

$ flutter analyze lib/features/pip <all 7 owned test files>
    No issues found!

$ flutter test --timeout 120s <all 7 owned test files>
    → +129: All tests passed!
    (pip_evolution_repository 14 + data + evolution_bloc + repository +
     bloc + bloc_actions + atomic_writes; no skips)
```

The whole-app `flutter test` and the simulator are the integrator's (loop
brief); the K07 UI suites (`pip_evolution_view` / `a11y` / `widget` / `copy` /
`sparks` / `stream_contract` / `stats_scales`, `k07_bugs`,
`k07_sparkles_bug`, `pip_orchestrator_notes`, `pip_iter2_fixes`,
`pip_buy_result`, the K06 nests) were neither edited nor run by this stage —
they are 2b's, stage 3's and the UI check's.

## LEFT FOR NEXT ITERATION

- Nothing outstanding **in this layer**: `watchEvolution`, `PipEvolution`,
  the dual-stream `PipLoadRequested` state machine, its retry semantics and
  the DI / route wiring are implemented, audited and proven.
- Still owed by others: 2b's K07-BUG-8 (`pip_evolution_stats.dart` — drop the
  per-cell `FittedBox` per FIXES_4 option 1, the only CSS-faithful one, plus
  review finding 1's `topCenter` inset) and K07-BUG-9
  (`pip_evolution_view.dart` — drop `maxLines: 3` + ellipsis, and correct the
  stale 3.16× comment at `:338-347`), plus the un-skip of their two parked
  proofs in `k07_bugs_test.dart`; the orchestrator's rulings on
  SHARED_REQUEST §2 (screen-scoped load), §4 (`#3D7FF0` token) and §5
  (`evolutionSub(0)` wording, unblocking review finding 3).

VERDICT: PASS