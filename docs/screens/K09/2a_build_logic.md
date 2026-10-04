# K09 · 2a BUILD (logic chunk, iteration 2)

Scope: non-UI layer of `kid_jar` only — `domain/**`, `data/**`,
`presentation/bloc/**` + the `bloc`/`repository` test files. Views/widgets
and the `my_jar_*`/`k09_bugs_test` files belong to the UI builder — not
touched. Plan: `1_plan.md` §b. Fixes: every `FIXES_1.md` item in this layer
(§2). Iteration 1 (guarded `_switchMap`, atomic snapshot, 20 tests) is
commit history; this file accounts iteration 2.

## CONTRACT CHANGES

Public names are stable (`KidJarLoadRequested` still the only view event;
`watchJar`/`watchItems`/`watchSummary`/`moveToSavings` signatures
unchanged). Two backward-compatible additions the UI builder codes against:

1. `JarEntry.iconKey` (default `''`): the quest's `quests.icon` key for
   `quest_bonus` rows, resolved by title in the repository (K09-BUG-3);
   `''` = unknown → fallback glyph. Existing constructions compile
   unchanged. The view should render
   `questIconFor(entry.iconKey, audience: NestAudience.kid)` for quest rows
   (ORCHESTRATOR_NOTES 18:47; the mandatory proof reads the keys out of the
   database and demands the kid glyph per row: bins/bins, hoover/hoover,
   bed/bed, shirt/shirt).
2. `KidJarSnapshotReceived` / `KidJarStreamFailed` events: bloc-INTERNAL
   re-entry for the guarded subscription (K09-BUG-1, K03-BUG-15 shape).
   Views must never dispatch them.

Behaviour pins: `owedPence` never negative (clamped at 0, K09-BUG-5);
`moveToSavings` never credits past the goal remainder and is a no-op into a
full goal (K09-BUG-4 hardening — the card clamp itself is the UI builder's).

## Files changed

- `domain/entities/jar_entry.dart`: added `iconKey = ''` (+ props).
- `data/models/jar_entry_model.dart`: `iconKey` round-trips through
  `fromJson`/`toJson` (missing key reads `''`).
- `presentation/bloc/kid_jar_event.dart`: added the two internal events.
- `presentation/bloc/kid_jar_bloc.dart`: K09-BUG-1 fix — guarded
  `StreamSubscription<JarSnapshot>? _jarSub`, cancel-before-reload at the
  top of `_onLoadRequested`, released on error and on `close()`; stream
  output re-enters as internal events (no more `emit.forEach`). The false
  "cancels the prior subscription" comment is corrected.
- `data/kid_jar_repository_impl.dart`: (a) K09-BUG-3 — 4th stream (all
  family quests, creation order) feeds a title → icon join; quest rows
  carry `iconKey`, others `''`; unmatched/empty notes → `''`. (b) K09-BUG-5
  — `_summarize` clamps owed at 0 (rows keep their signs). (c) K09-BUG-4 —
  `moveToSavings` caps the credit + ledger row at the remainder, no-op when
  none. (d) review finding 4 — the `watchJar` doc now describes the single
  `watchLedger` emission both list and summary derive from.
- `test/.../kid_jar_repository_test.dart`: +7 (icon keys incl. fallback,
  owed floor with `−£5.00` row, 3 savings-cap cases). No existing test
  edited.
- `test/.../kid_jar_bloc_test.dart`: +2 (`close()` releases the sub,
  iconKey passthrough). The two K09-BUG-1 proofs pass with no test edit.
- `docs/screens/K09/SHARED_REQUEST.md` (new): review finding 1
  (`NestProgress` kid gloss clipped to the fill).

## FIXES_1 disposition (logic layer only)

| id | layer part | status |
|---|---|---|
| K09-BUG-1 (minor) | bloc guard | FIXED — both red proofs green |
| K09-BUG-3 (major, mandated) | `iconKey` through entity + repo lookup | FIXED on this side; widget must render `questIconFor(entry.iconKey, kid)` |
| K09-BUG-5 (minor, latent) | owed floor in `_summarize` | FIXED — skipped view proof's data leg holds (owed 0 → hero `£0.00`, no `£0.80`) |
| K09-BUG-4 (major) | `moveToSavings` cap | HARDENED here; card clamp + proof are UI builder's |
| K09-BUG-2 / K09-BUG-6 / 5_ui dev. 1–2 | views/widgets | NOT MINE — untouched |
| 4_review 3 (formatter) / 6 (live region) | widgets/views | NOT MINE — untouched |
| 4_review 4 (stale comment) | repo doc | FIXED |
| 4_review 5 (`watchItems` meaning) | docs | HANDOVER below (no code change per the review) |
| ORCHESTRATOR_NOTES `jarPocketMoney`/`jarGift` | widgets | NOT MINE — swap is in `jarEntryGlyph`, UI builder's |

## Verification

- `dart format` clean; `flutter analyze lib/features/kid_jar
  test/features/kid_jar` → No issues found (no ignores; no `DateTime.now`,
  no `google_fonts`; clock via `appNowUtc`/`londonWeekStartUtc`).
- `flutter test --timeout 120s` on both layer files → 32/32 pass,
  including the two K09-BUG-1 proofs and all 7+2 new tests.
- Shared `test/core/data/repositories_test.dart` → 22/22 (summary +
  capped `moveToSavings` unaffected). No simulator booted (stage rule).

## HANDOVER (K10 + next loop)

- K10 (`PayoutDayView`) shares `KidJarBloc`/`state.items`: since iteration
  1 `watchItems()` serves money-in rows only with `This/Last {weekday}`
  details (review finding 5) — K10 must not assume the old
  every-row/`formatDay` contract. New this iteration: items also carry
  `iconKey`, and `owedPence`/`moveToSavings` are floored/capped.
- Skipped proofs in `k09_bugs_test.dart` (BUG-4/5/6) were NOT un-skipped
  (not this layer's file); BUG-5's data leg is fixed so it goes green, and
  BUG-4's needs the card clamp.
- UI builder: `jarEntryGlyph` still maps every quest row to one glyph —
  take `entry.iconKey` (K09-BUG-3 proof + 5_ui deviation 2).

## LEFT FOR NEXT ITERATION

Nothing in this layer. Open items live in views/widgets (`jarEntryGlyph`
key rendering incl. the `jarPocketMoney` swap — the shared glyphs are
already on this branch via the `shared/jar_glyphs` merge,
`my_jar_view.dart:231` ink, goal-card clamp, scroll tail).

VERDICT: PASS
