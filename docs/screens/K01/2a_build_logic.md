# K01 · Stage 2a — BUILD, LOGIC CHUNK (iteration 2)

Scope: ONLY the non-UI layer of feature `kid_home` for K01
(`domain/**`, `data/**`, `presentation/bloc/**`, plus owned tests:
files matching `bloc`/`cubit`/`repository`/`data`).
Views/widgets belong to the UI builder — untouched by this stage
(their `profile_picker_view.dart` is mid-write for BUG-1 as this is
written and does not compile yet; that breakage is theirs, not mine).

## CONTRACT CHANGES

Additive only — every existing name keeps its shape; the UI builder
codes the two view half-lines below against these:

1. **New event `KidHomeSelectionHandled`** (clears a pending
   `selectedProfileId`, no-op when none; navigation stays out of the
   bloc). VIEW HALF-LINE (fixes K01-BUG-3 end to end): in the picker's
   `BlocListener(selectedProfileId)`, right after
   `unawaited(context.push(...))`, dispatch
   `context.read<KidHomeBloc>().add(const KidHomeSelectionHandled());`.
   Until then behaviour is byte-identical to iteration 1 (no
   regression: the event is simply never sent).
2. **New state constructors `copyWithSelectionHandled()` and
   `copyWithProfilesRecovered(next)`** (both additive; `props`
   unchanged — no new fields, so no existing equality changes).
3. **BUG-5 behaviour change** (bloc-side only, no view change needed):
   a healthy roster after a profiles-caused outage restores `loaded`
   and clears the stale load error while the home stream is live; Try
   again shows `loading` while only the roster restarts.
4. Deliberately NOT in the bloc (would regress with the current view):
   no ignore-while-pending for bursts — K01-BUG-2 stays a view-side
   screen-level latch (same `_busy` pattern as `_GateLockButton`: set
   before `push`, clear on pop return).

## FIXES_1.md — item-by-item (logic layer only)

- **BUG-B / review finding 1 / K01-BUG-5 (major) — FIXED (logic).**
  `_onProfilesReceived` now restores `loaded` via the new
  `copyWithProfilesRecovered` when the recovery follows a
  profiles-caused error (`_profilesFailed` flag) while the home
  subscription is still live; a roster arriving over a dead home
  stream does NOT mask the failure card. Try again
  (`KidHomeLoadRequested`) emits `loading` when it restarts only the
  roster (review finding 3). Regression test added (profiles-failure
  → Try again → recovery asserts `loaded` with `homeSubscriptions ==
  1`, exactly as the review asked).
- **Review finding 2 (minor) — FIXED.** Recovery clears the stale
  `errorMessage`; any healthy roster after a profiles error clears it.
- **K01-BUG-3 (major) — LOGIC HALF DONE, view half-line pending.**
  `KidHomeSelectionHandled` + `copyWithSelectionHandled` implemented
  and proven (re-selection after handled emits distinctly and writes
  again; no-op when nothing pending). The skipped widget test also
  needs the view dispatch above, so its `skip:` stays until the UI
  builder lands that line — flagged for the test stage, not forced.
- **BUG-A (apostrophe) — NOT MINE.** One-character view change
  (`profile_picker_view.dart:210`) plus test-file updates outside my
  owned set. No orchestrator ruling found in `ORCHESTRATOR_NOTES.md`;
  left for the UI builder. My layer ships no copy.
- **K01-BUG-1 (3+ children) — NOT MINE.** Tiles-band layout, view
  only (UI builder is writing `_OverflowTileRow` now).
- **K01-BUG-2 (burst double nav) — NOT MINE (bloc side deliberately
  untouched).** A bloc ignore-while-pending would silently drop
  legitimate cross-tile retaps against the current view; the
  suggested screen-level latch is view-only. No logic change.
- **K01-BUG-4 (empty nickname) — NOT MINE.** Label fallback lives in
  `ProfileTile` (view); core DB is off-limits for validation.
- **5_ui D1/D2, ORCHESTRATOR_NOTES D1/D2 — NOT MINE** (view layout);
  **D3/D4 meadow — shared** (`shared/kid_meadow`), untouched.
- **CLOCK rule:** my code adds no clock calls. The two pre-existing
  `DateTime.now().toUtc()` in `kid_home_repository_impl.dart`
  (K03 period math) are untouched: not a FIXES_1 item, and changing
  the time source under 200 green tests is integrator/orchestrator
  territory. Disclosed, not deferred.
- **Skipped bug tests:** none un-skipped by this stage. BUG-5's
  widget probe cannot run while the view is mid-write (compile
  error, verified); BUG-3's needs the view dispatch. Both are proven
  at bloc level in owned files; un-skip belongs to the test stage
  once the view compiles. `k01_bugs_test.dart` not touched.

## Files changed (logic layer)

- `app/lib/features/kid_home/presentation/bloc/kid_home_event.dart`
  — added `KidHomeSelectionHandled` (+ contract docs).
- `app/lib/features/kid_home/presentation/bloc/kid_home_state.dart`
  — added `copyWithSelectionHandled()` /
  `copyWithProfilesRecovered(next)`; `selectedProfileId` docs now
  name both consume paths. No field/prop changes.
- `app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart`
  — registered the handler; `_profilesFailed` release flag;
  recovery restore in `_onProfilesReceived`; Try-again `loading`
  when only the roster restarts (gated on home-live so the
  home-failure retry sequence is unchanged).
- `app/test/features/kid_home/k01_bloc_paths_test.dart` (owned) —
  `_RosterFake` gains additive `homeChildNull` / `failHome` flags;
  header list extended; new groups (7 tests): BUG-5 Try-again
  recovery without a home re-emit, Try-again spinner capture,
  home-caused failure never masked, handled clears pending,
  re-selection emits distinctly (BUG-3 mechanism), handled no-op,
  constructor/equality unit test.
- Did NOT touch: `domain/**`, `data/**` (nothing needed),
  `presentation/views/**`, `presentation/widgets/**`,
  `k01_bugs_test.dart` (skips intact), any other feature.

## Verification (this stage only — no simulator, no full-app run)

- `flutter analyze` on domain + data + bloc + DI/routes + the three
  owned test files → No issues found. `dart format` clean.
- `flutter test k01_bloc_paths + kid_home_bloc + kid_home_repository`
  → 59/59 pass (52 existing + 7 new).
- Whole-feature `analyze` shows exactly one error, in
  `profile_picker_view.dart:253` (`_OverflowTileRow` undefined) —
  the UI builder's in-flight BUG-1 edit, confirmed not mine
  (`git diff` shows their view/widgets changes vs my bloc+tests).
- No `google_fonts`, no `letterSpacing`, no new `DateTime.now`;
  no `flutter clean`, no simulator use.

## LEFT FOR NEXT ITERATION

- UI builder: `KidHomeSelectionHandled` dispatch (1 line, CONTRACT
  CHANGES §1) + BUG-2 screen latch + BUG-1 overflow row (in
  progress) + BUG-A one-character ruling/fix + BUG-4 label fallback.
- Test stage: un-skip BUG-5 widget probe once the view compiles
  (logic proven), then BUG-3 probe once the dispatch lands.
- Nothing unfinished in the logic layer itself.

VERDICT: PASS
