# K01 · Stage 2a — BUILD, LOGIC CHUNK (iteration 3)

Scope: ONLY the non-UI layer of feature `kid_home` for K01
(`domain/**`, `data/**`, `presentation/bloc/**`, plus owned tests:
files matching `bloc`/`cubit`/`repository`/`data`).
Views/widgets belong to the UI builder — untouched by this stage.

## CONTRACT CHANGES

Additive only — no existing name changed shape; two items need the
view half-lines below (BUG-3 dispatch was already specified in
iteration 2 and is now MANDATORY for BUG-6 safety):

1. **BUG-6 single-flight (bloc done):** `_onProfileSelected` now
   returns early — without writing — when `selectedProfileId` is
   still unconsumed (same burst). Sequential handlers make a
   transient `_selecting` flag useless (event 2 starts only after
   event 1 completes), so the pending one-shot IS the guard. The
   pending clears via `KidHomeSelectionHandled` or the next home
   emission, so genuinely later taps are never dropped.
   VIEW HALF (mandatory pairing): dispatch
   `context.read<KidHomeBloc>().add(const KidHomeSelectionHandled());`
   right after `unawaited(context.push(...))` in the picker's
   selection listener (review finding 1, demanded by stages 4+6).
   Without it, a cross-tile retap after a stuck pending selection
   would now be ignored (previously it navigated) — the flag can
   only be unwedged by the dispatch or a home re-emit.
2. **Review finding 2 (bloc done):** new state field
   `profilesFailed` (default `false`, in `props`, carried by every
   constructor; set on the profiles error path, cleared by any
   healthy roster). VIEW HALF: gate the failure-card heal on it —
   e.g. render `_PickerLoaded` on `failure` only when
   `!state.profilesFailed` (profiles-caused outage, roster back),
   never on a home-stream failure with a stale roster. Current
   `profiles.isNotEmpty` check masks exactly that card.
3. No other shape changes (`KidHomeSelectionHandled`,
   `copyWithSelectionHandled`, `copyWithProfilesRecovered` all
   iteration-2, unchanged).

## FIXES_2.md — item-by-item (logic layer only)

- **K01-BUG-6 (major, NEW — FIXED + un-skipped in owned file).**
  Burst selections now persist only the first child: the second
  `KidHomeProfileSelected` finds the one-shot pending and returns
  before its `setActiveChild`, so `app_state` always names the
  pushed route's child. Parked reproducer
  (`k01_bloc_paths_test.dart`, plain `test` per the blocTest-skip
  note) un-skipped and green, plus a follow-up test proving a
  dropped burst selection leaves no trace and the next tap works.
  The `k01_bugs_test.dart` widget probe stays skipped (not my file;
  needs the view half-line above — with it, single route + agreeing
  DB; test stage to un-skip).
- **K01-BUG-3 (re-classified — logic half complete, still needs the
  view dispatch).** The `KidHomeSelectionHandled` event, handler and
  consume path exist and are proven (re-selection after handled
  emits distinctly and writes again; no-op when nothing pending).
  Nothing in `lib/` dispatches it yet — that one line is the UI
  builder's (review finding 1). The harness debate (artifact vs
  race) changes nothing logic-side: the dispatch removes the
  ordering dependence either way. Skipped widget probe untouched
  (not my file; still red without the dispatch).
- **Review finding 2 (minor — logic half done).** `profilesFailed`
  exposed from state with full transition tests (set on error,
  carried everywhere, cleared by any healthy roster, in equality).
  View gating is UI builder's (CONTRACT CHANGES §2).
- **Review finding 4 (minor — done).** `1_plan.md` §0 corrected to
  the shipped ASCII apostrophe with the BUG-A history note, so the
  plan no longer contradicts `k01_copy_parity_test.dart` (13/13).
  No orchestrator ruling exists; the record now matches reality.
- **Review finding 5 (list_row_trailing, another feature) — NOT
  MINE.** Explicitly out of the K01 surface; left for main.
- **BUG-A / BUG-1 / BUG-2 / BUG-4 / D1–D4 / KID BACKGROUND — NOT
  MINE.** All view or shared; verified fixed per FIXES_2 §4 except
  as noted. BUG-2's bloc alternative deliberately NOT implemented
  (superseded by the BUG-6 guard + view latch pairing above).
- **CLOCK rule:** no clock calls added; the two pre-existing
  `DateTime.now().toUtc()` in the K03 period math are untouched
  (not a FIXES item; changing the time source is orchestrator
  territory). No `google_fonts`, no `letterSpacing` anywhere new.

## Files changed (logic layer)

- `app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart`
  — pending-selection early return in `_onProfileSelected` (+ docs).
- `app/lib/features/kid_home/presentation/bloc/kid_home_state.dart`
  — `profilesFailed` field + `copyWith` param + carry-through in all
  eight constructors + `props`. `copyWithProfiles` /
  `copyWithProfilesRecovered` clear it via the constructor default.
- `app/test/features/kid_home/k01_bloc_paths_test.dart` (owned) —
  un-skipped the BUG-6 reproducer (now passing); new tests:
  dropped-burst-leaves-no-trace, outage-flag stream-health
  tracking, outage-flag constructor/equality unit test; header
  covered-list updated. (`domain/**`, `data/**` needed nothing.)
- `docs/screens/K01/1_plan.md` — §0 apostrophe correction only.
- Did NOT touch: `presentation/views/**`,
  `presentation/widgets/**`, `k01_bugs_test.dart` (all skips
  intact), any other feature, shared code.

## Verification (this stage only — no simulator, no full-app run)

- `flutter analyze` on domain + data + bloc + the three owned test
  files → No issues found. `dart format` clean.
- `flutter test k01_bloc_paths + kid_home_bloc + kid_home_repository`
  → 63/63 pass (59 + un-skipped BUG-6 + 3 new).
- Feature-wide analyze shows only the UI builder's in-flight view
  error (`_OverflowTileRow`, BUG-1 work) — verified theirs via
  `git diff`, untouched.
- No `flutter clean`, no simulator use.

## LEFT FOR NEXT ITERATION

- UI builder: Handled dispatch (mandatory, §1) + failure-heal gate
  on `state.profilesFailed` (§2) + finish BUG-1 row.
- Test stage: un-skip BUG-6 widget probe (logic proven; needs the
  dispatch) and BUG-3 probe (needs the dispatch), once green.
- Nothing unfinished in the logic layer itself.

VERDICT: PASS
