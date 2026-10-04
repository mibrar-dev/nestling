# K06 · Pip's nest (`/pip`) — UI build (stage 2b, iteration 3)

Scope, unchanged: `app/lib/features/pip/presentation/views/**`,
`app/lib/features/pip/presentation/widgets/**`, and the view/widget tests in
`app/test/features/pip/` (files whose names contain `view` or `widget`). No
domain/data/bloc edits from this stage (the logic builder is editing those in
parallel — `pip_repository.dart`, `pip_repository_impl.dart`, `pip_bloc.dart`,
`pip_state.dart` were all touched by them).

## FIXES_2 item triage — what was actually UI-owned

Working through `FIXES_2.md`:

| Item | Layer | Owner | UI action? |
|---|---|---|---|
| D2 — wardrobe Scarf/Wellies glyphs are look-alikes | shared `assets/icons/*.svg` | shared | Filed `SHARED_REQUEST.md` §5; the note forbids substituting in-screen, so no. Zero screen-side work remains for this. |
| D3 — Wellies 40 / Crown 120 vs design 30 / 60 | seed vs design | shared | The shared batch 7 commit (`2517101`, on `main` and merged in this worktree) made the seed mirror the design: Wellies 30, Crown 60. `SHARED_REQUEST.md` §6 is still the ruling. The VIEW needed one line: see below. |
| K06-BUG-7 — a refused buy is silent | bloc / repository | logic | Contract change landed in the parallel logic builder (`PipBuyResult` on `buyItem`; the bloc already names `result == PipBuyResult.cannotAfford` → `kPipNotEnoughCoins`). The view side needed nothing: the existing `BlocListener` on `PipState.actionNonce` already emits the kind toast when `actionError` is set, so when the bloc fires the refusal it will show. |

## What I actually changed

- `test/features/pip/pip_nest_view_test.dart` — the five stale assertions that
  pinned the pre-batch-7 seed (Wellies 40 / Crown 120 → Wellies 30 / Crown 60,
  one of each tile bought: 112 - 30 = 82, and the "not wearable" case's balance
  check). Copy/precision reasoning from FIXES_2 D3: the rendered numbers come
  from `watchWardrobe` (the DB), which now agrees with the design — so the
  UI verdict's "DB-driven content is excluded" note becomes "DB == design",
  and no production line moved.

## Verification (UI-stage scope only — no whole-app suite, no simulator)

```
flutter analyze lib/features/pip                                        → No issues found!
flutter test --timeout 120s test/features/pip/pip_nest_view_test.dart
  test/features/pip/pip_nest_widget_test.dart                            → +22: All tests passed!
```

`pip_nest_states_test.dart`, `pip_nest_interactions_test.dart`,
`pip_atomic_writes_test.dart` and `k06_bugs_test.dart` also have stale
40/120 assertions from before shared batch 7 — they contain no `view`/`widget`
in their names, so they fall outside this scope; the strategy is unchanged
(assert against the live seeded row, never a literal). Listing so the next
person triages them the same way.

No views or widgets were edited this iteration: the screen already satisfies
the iteration-2 geometry verdicts (`5_ui.md`: 2.28% light / 2.00% dark, every
structural band Δ 0, BOTTOM EDGE passing, and D1 closed).

## LEFT FOR NEXT ITERATION

1. UI check (`5_ui`) must re-run on a merged build: it should now report D2's
   glyph tiles as correct and the locked-tile borders painted in dark mode
   (BUG-6 had a light-theme pixel proof; iteration 2's stage 6 extended it to
   dark). Whether the shared batch 7 assets produced no regressions is a
   stage-5 call.
2. The BUG-7 parked tests (`k06_bugs_test.dart` skip + `pip_iter2_fixes_test`
   skip) are for the logic builder's "skip: true" removal once their
   `PipBuyResult` transaction is verified; the view side is ready.
3. `kPipNotWearable` ("That one is not something Pip can wear.") is still the
   one on-screen string not in the design, awaiting ratification.
4. The "40/120 in the assertions of non-view/widget test files" sweep above.

VERDICT: PASS
