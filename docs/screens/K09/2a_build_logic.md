# K09 · 2a BUILD (logic chunk, iteration 1)

Scope: non-UI layer of `kid_jar` only — `domain/**`, `data/**`,
`presentation/bloc/**`, plus unit/bloc tests. Views/widgets untouched (UI
builder owns them). Plan: `docs/screens/K09/1_plan.md` §b.

## Files changed

- `app/lib/features/kid_jar/domain/entities/jar_snapshot.dart` (new):
  `JarSnapshot {childId, items, summary}` + `formatJarAmount(pence)`
  (`+£3.80` at/above £1, `+12p` below; U+2212 `−£2.00` safety branch).
- `app/lib/features/kid_jar/domain/kid_jar_repository.dart`: added
  `Stream<JarSnapshot> watchJar()`; everything else unchanged.
- `app/lib/features/kid_jar/data/kid_jar_repository_impl.dart`:
  `watchJar()` fans `watchAppState` (`activeChildId ?? 'maya'`) out to one
  atomic `_jarFor(child)` snapshot; money-in filter
  `{weekly_base, quest_bonus, gift}` newest-first; row mapping
  (weekly_base → `Pocket money` / `This|Last {Weekday}` via
  `londonWeekStartUtc`+`toLondon`; quest_bonus → note / `Quest bonus`;
  gift → note-before-` (` / `From {name}` from `(added by …)`, else `Gift`);
  `watchSummary` math byte-identical, now derived from the same emission;
  `watchItems()` = snapshot items; `moveToSavings` untouched.
- `app/lib/features/kid_jar/presentation/bloc/kid_jar_state.dart`: added
  `childId, owedPence, goalTitle, goalSavedPence, goalTargetPence,
  nextPayoutDay` (defaults `''/0/'…'/0/0/'Saturday'`); new `copyWithLoaded`
  (replaces all jar fields, clears stale error); `copyWith` extended.
- `app/lib/features/kid_jar/presentation/bloc/kid_jar_bloc.dart`:
  `KidJarLoadRequested` → `loading` + `emit.forEach(watchJar())`
  (retry re-adds the event; prior subscription cancelled); no new events.
- `app/test/features/kid_jar/kid_jar_repository_test.dart` (new, 13 tests)
  and `kid_jar_bloc_test.dart` (new, 7 tests). DI/routes need no change.

## Implementation notes (not contract changes)

- Plan §b says `asyncExpand`; used a feature-local `_switchMap` instead
  (copy of the `kid_shop` helper). `asyncExpand` pauses the outer
  subscription until the inner closes and Drift watch streams never close,
  so an active-child switch after the first emission would stall forever.
- One ledger subscription feeds both list and summary per emission, so a
  snapshot can never pair new rows with a stale owed figure (caught live:
  the first green run showed transient 10-rows/420p pairing).
- No `DateTime.now()` (clock/`appNowUtc` only), no `google_fonts`, ids
  untouched, tokens n/a to this layer.

## Verification

- `dart format` clean; `flutter analyze lib/features/kid_jar
  test/features/kid_jar` → No issues found.
- `flutter test --timeout 120s` on both new files → 20/20 pass
  (Maya 420/Lego 1550/2499/Saturday/9 rows head weekly_base 300;
  Leo 210/no-goal; empty-seed empty/0; live child-switch + inserts;
  failure→retry; state semantics).
- Shared `test/core/data/repositories_test.dart` → 22/22 pass
  (summary + moveToSavings unaffected). No simulator used.

## LEFT FOR NEXT ITERATION

Nothing in this layer. UI builder owns views/widgets + view/geometry/copy
tests (plan §f items 3–5).

VERDICT: PASS
