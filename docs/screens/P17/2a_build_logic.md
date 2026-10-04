# P17 Parental gate — 2a build logic (iteration 3)

Scope: non-UI layer only — `domain/**`, `data/**`,
`presentation/bloc/**`, plus unit/bloc tests whose names contain
`bloc`/`repository`/`data`. No view/widget edits; no DI/route edits;
no simulator use.

## CONTRACT CHANGES

None — not even additive this iteration. Events, state fields,
helpers, `copyWith(clearError)` and the London-day `challengeFor`
are exactly what iteration 2 shipped and what the UI builder codes
against.

## Files changed

None in `app/lib/**` or `app/test/**` this iteration
(`git status` shows only the loop's own `.brief_build_*` files).
Deliberately so — see below.

## FIXES_2 triage — no item in my layer

- §3.1 backdrop row `crossAxisAlignment` (incl. P17-BUG-4 proof) and §3.3
  FittedBox/`NestKeypadFit` merge blocker: both are the view call site
  (`parental_gate_view.dart`) — UI builder's.
- §3.2 keypad pitch: shared `NestKeypad`, now landed on `main`
  (`9cac0c6`; the only `app/lib/core` change in this worktree since
  iteration 2). Nothing P17-local was ever possible; request #3 stands.
- 6_bugs obs 1 (`_announcedAttempts` not reset): the counter is view
  state in `parental_gate_view.dart` — only the view can reset it.
  Recorded as an observation, unpinned; UI builder's if taken up.
- 6_bugs obs 4 dead code: `ParentalGateChallengeModel` stays (per-feature
  ARCHITECTURE shape, round-trip tested); the placeholder card is view's.
- 4_review finding 2 (backdrop reads `AppDatabase` via GetIt): view
  code, and the fix it suggests (new repository method) contradicts
  `1_plan.md` §(b), which deliberately chose "no new repo" for the
  backdrop. Churning the repository interface mid-parallel-work for a
  carried-over minor would break the UI builder's contract for no
  product gain — left as the plan specifies.
- P17-BUG-1 (shared router) and the 7 K03 scaffold-title reds: out of
  layer (requests #2 / #1).
- Midnight re-key limitation (my iteration-2 note, 3_test obs 5): still
  open by design — the plan's Drift-only repository contract provides
  no timer, and a gate is a seconds-long interaction. No test pins it.

## Verification after the main merge (regression only)

The `main` merge touched nothing in my dependency surface
(`family_time`, `app_clock`, `seed`, repository, bloc all byte-identical
to the iteration-2 checkpoint), but re-ran everything anyway:

- `flutter analyze lib/features/parental_gate
  test/features/parental_gate/parental_gate_bloc_test.dart
  test/features/parental_gate/parental_gate_repository_test.dart`
  → No issues found!
- `flutter test` bloc + repository files → +38, all pass (25 + 13).
- `p17_bugs_test.dart` P17-BUG-2 and P17-BUG-3 proofs by `--plain-name`
  → +1 / +1, all pass (widget tests in that file not run — the view is
  mid-fix by the parallel UI builder for the §3.3 FittedBox crash).
- No `google_fonts`, no letterSpacing, no `DateTime.now()` in lib, no
  simulator.

## LEFT FOR NEXT ITERATION

- Nothing in this layer. If the orchestrator ever mandates 4_review
  finding 2 (backdrop behind the repository), that is a contract change
  needing a joint iteration with the UI builder — not a solo logic edit.

VERDICT: PASS
