# P17 Parental gate — QA code review (stage 4, iteration 2)

Scope reviewed: `git diff main...HEAD` — parentals_gate feature, its
tests, `docs/screens/P17/**` (+ the pre-existing `docs/screens/_shared`
report carried on this branch). Branch state: merge of main included;
orchestrator iteration-2 targets recorded in
`docs/screens/P17/ORCHESTRATOR_NOTES.md`.

Verified this iteration: `flutter analyze` → No issues found;
`dart format --output=none --set-exit-if-changed lib test` → only
`app/test/design_system/list_row_trailing_test.dart` differs, which is
traced to main's history (commit 79fe455, present at the branch's
merge-base, NOT in P17's diff) — observation only, not a P17 edit.
`flutter test test/features/parental_gate` → +90 ~1 -2: the two reds are
the ORCHESTRATOR_NOTES geometry pins that fail solely because shared
`NestKeypad` drifts from the CSS grid — already filed as
`SHARED_REQUEST.md` #3 with `TODO(P17)` at the call site. All 90 other
tests pass, including the new repository/London-day and bloc
reset-on-challenge-change tests.

## Iteration-1 findings — disposition

1. `app/test/core/family_time_test.dart` + `docs/screens/_shared/…` outside
   RULES §1 — still only covered by the `_shared` report; not cross-linked
   from `SHARED_REQUEST.md`. **Still open (minor).**
2. Backdrop reads `AppDatabase`/`AppSession` via GetIt
   (`parental_gate_view.dart:316-317`) — **still open (minor)**; line
   refs shifted after the iteration-2 edit.
3. `AppDatabase.memory()` per `challengeFor` test — **FIXED**: one
   `setUpAll` instance now serves the whole group (file lines 10-17).
4. Caret on the first empty digit box only — **FIXED**: every empty box
   now renders the leaf caret, matching the HTML `.digit.empty::after`.
5. Loading placeholder drift — **FIXED**: placeholders now 22/24 px for
   the instruction/one-line question instead of 20/34.
6. Challenge keyed to the UTC day — **FIXED** (`P17-BUG-2`):
   `challengeFor` reads `toFamilyZone(utc, defaultFamilyZoneId)` and the
   id strings use the London date; repository doc comment updated.

## Iteration-2 code changes — review

- `parental_gate_bloc.dart:20-44` — clearing the stale `errorMessage`
  on every load emit, and resetting `entered/attempts/unlocked` only when
  the challenge id actually changes (`P17-BUG-3`) is correct; a
  same-challenge re-emit (e.g. unrelated settings write) preserves the
  in-progress entry. Equatable/copyWith shape updated consistently.
- `parental_gate_state.dart` `clearError` — `copyWith` now clears the
  error when asked; permanent fields can't resurrect it. Fine.
- `parental_gate_view.dart:39-56` — `_unlock` pops the route BEFORE
  flipping app mode in the `canPop` branch (avoids the router's
  refreshListenable restoring `/parental-gate` mid-pop), and pops to
  parent mode FIRST in the `/today` redirect branch. The rationale
  comment is accurate; behaviour is unchanged outwardly.
- `parental_gate_view.dart:108-131` — the modal is now anchored at the
  design's y 66 (`Padding.fromLTRB(s6, 66, s6, 0)` +
  `ConstrainedBox(minHeight: maxHeight - 66)` +
  `Align(topCenter)`), replacing the centred layout that produced the
  uniform vertical shift. Overflow still handled by the scroll view.
- `parental_gate_view.dart:359-362` — `NestStatusBar` now reserves the
  status-bar height behind the backdrop header (resolves the iteration-1
  "Hi Maya!" under the clock). Padding is `fromLTRB(28, NestSpacing.s2,
  28, 0)`.
- `_GateLoading` placeholder heights updated (22/24).
- `_DigitsRow` caret on every empty box (see above).
- `NestKeypad` call site carries `TODO(P17)` + SHARED_REQUEST #3: keys
  are 72×72 with a 16 px shared row gap where the CSS grid is 72 + 10,
  so the card is 26 px too tall — pinned red in the geometry test until
  the shared component lands (RULES §2: no local fork).
- P17-BUG-1 (kid mode + expired trial ⇒ `/paywall` ↔ `/parental-gate`
  redirect loop) is a shared `router.dart` defect; reproduced, filed in
  SHARED_REQUEST with a skip-marked proof (`P17-BUG-1` in
  `p17_bugs_test.dart`), P17 correctly did not patch shared code.

## Findings

1. **minor** (process) — Same as iteration-1 #1: the
   `family_time_test.dart` edit + `_shared` report sit on this branch
   outside RULES §1 without a line in `SHARED_REQUEST.md`. Fix: cite the
   `_shared` report from `SHARED_REQUEST.md` (or have the orchestrator
   absorb it on `main`).

2. **minor** — `parental_gate_view.dart:316-317`: `_GateBackdrop` still
   reads `AppDatabase`/`AppSession` via GetIt instead of receiving the
   child stream through `ParentalGateRepository`/bloc. Fix: move the
   active-child watch behind the feature repository (or the bloc) and
   bind the backdrop to bloc state, matching the rest of the app.

3. **note (not actionable by P17)** — Two geometry tests stay red until
   shared `NestKeypad` adopts the CSS grid (72×72 keys, 10 px row gap,
   `padding: 8px 24px 0`); already tracked in `SHARED_REQUEST.md` #3 and
   `TODO(P17)` at `parental_gate_view.dart` keypad slot. No screen-local
   fix remains.

4. **note (not actionable by P17)** — `app/test/design_system/list_row_trailing_test.dart`
   fails `dart format` check; it is inherited from main's merge-base
   (79fe455), not part of P17's diff. The orchestrator should re-run
   format on main.

Children's Code re-check: no analytics/ads/trackers; gate copy and
url-free; no child data leaves the device. Confirmed.

No blocker or major screen-local findings.

VERDICT: PASS
