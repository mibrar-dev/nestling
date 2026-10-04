# K09 · 2 BUILD (integrate, iteration 2)

Two builders worked this worktree in parallel: `2a_build_logic.md` (the
non-UI layer — `domain/**`, `data/**`, `presentation/bloc/**` + the
bloc/repository tests) and `2b_build_ui.md` (the views/widgets + the
view/bug tests). This stage's only job was to make the combined result
compile and pass.

**No integration breakage was found.** The two halves were written against
the same contract and it holds exactly:

- 2b calls `jarEntryGlyph(entry.type, entry.iconKey)`; 2a's `JarEntry`
  carries `iconKey` (`String`, default `''`) and the repository resolves it
  by quest title — signatures match, no renamed members.
- 2b dispatches **only** `KidJarLoadRequested`; 2a's two new events
  (`KidJarSnapshotReceived` / `KidJarStreamFailed`) are bloc-internal and no
  view or test references them (`grep` over `app/lib` shows them only in the
  bloc/bloc-event files).
- `KidJarState` surface 2b reads (`childId, items, owedPence, goalTitle,
  goalSavedPence, goalTargetPence, nextPayoutDay` via `copyWithLoaded`) is
  exactly what 2a emits; `questIconFor('')` falls back to
  `NestIcons.questCard`, so 2b's unmatched-note path is safe.
- No conflict markers, no duplicate definitions, no import cycles.

**No source edit was made in this stage.** `dart format` found nothing to
change, `flutter analyze` is clean and the full suite passes; the merge of
the two halves is already consistent. The only files in the tree are the
builders' own (below).

## Summary of 2a (logic) — as landed

- `domain/entities/jar_entry.dart`: `iconKey = ''` (+ props).
- `data/models/jar_entry_model.dart`: `iconKey` round-trips, missing key → `''`.
- `presentation/bloc/kid_jar_event.dart`: internal `KidJarSnapshotReceived`
  / `KidJarStreamFailed`.
- `presentation/bloc/kid_jar_bloc.dart`: K09-BUG-1 — guarded
  `StreamSubscription<JarSnapshot> _jarSub`, cancel-before-reload, released
  on error and in `close()`; stream output re-enters as internal events
  (no more unguarded `emit.forEach`); the false comment is corrected.
- `data/kid_jar_repository_impl.dart`: K09-BUG-3 — 4th stream (all family
  quests, creation order) feeds a title → icon join, quest rows carry
  `iconKey`, others `''`; K09-BUG-5 — `_summarize` floors owed at 0;
  K09-BUG-4 — `moveToSavings` caps the credit + ledger row at the goal
  remainder, no-op into a full goal; review finding 4 — `watchJar` doc now
  describes the single `watchLedger` emission both list and summary derive
  from.
- Tests: `kid_jar_repository_test.dart` +7 (icon keys incl. fallback, owed
  floor, 3 savings-cap cases), `kid_jar_bloc_test.dart` +2 (`close()`
  releases the sub, `iconKey` passthrough). No existing test edited.
- `docs/screens/K09/SHARED_REQUEST.md` (new): review finding 1, the shared
  `NestProgress` kid gloss (below).

## Summary of 2b (UI) — as landed

- `presentation/views/my_jar_view.dart`: K09-BUG-2 — `coming on …` painted
  `tokens.ink` (was `ink2`); K09-BUG-6 — scroll tail is `--s8` only
  (`SafeArea` already carries the home inset); review finding 6 — loading
  label is a `liveRegion`.
- `presentation/widgets/jar_goal_card.dart`: K09-BUG-4 —
  `remainingPence` clamped at 0.
- `presentation/widgets/jar_history_card.dart`: K09-BUG-3 + 5_ui dev. 1—
  `jarEntryGlyph(type, iconKey)` → `questIconFor(iconKey, audience: kid)` /
  `NestIcons.jarPocketMoney` / `NestIcons.gift`; the empty-row disc follows
  to `jarPocketMoney`. No `NestIcons.poundCoin` left in `kid_jar`.
- Tests: `my_jar_view_test.dart` + the K09-BUG-3b proof and the over-saved
  `JarGoalCard` widget proof; `my_jar_view_states_test.dart` asserts the
  loading `liveRegion`; `k09_bugs_test.dart` — `K09-BUG-4/5/6` un-skipped,
  header updated, **no `skip:` remains anywhere in the feature**.

## FIXES_1 disposition — every item

| id / source | item | status |
|---|---|---|
| K09-BUG-1 (3_test §3.1) | retry stacks live subscriptions; stale stream can overwrite the reloaded state | **FIXED** (2a, cancel-before-reload + `close()`). Both red proofs in `kid_jar_bloc_test.dart` green, no test edit |
| K09-BUG-2 (3_test §3.2, notes 18:47) | `coming on Saturday` painted `--ink-2`; HTML inherits `--ink` | **FIXED** (2b `tokens.ink`). Both theme proofs green |
| K09-BUG-3 (3_test §3.3, notes 18:47) | every quest-bonus row shows one fixed glyph instead of `questIconFor(key, kid)` | **FIXED** (2a `iconKey` join + 2b render). DB-driven proof green |
| K09-BUG-4 (6_bugs, major) | reached goal still asks for money | **FIXED** (2a repo cap + 2b card clamp). Live proof green |
| K09-BUG-5 (6_bugs, latent) | negative owed rendered as positive hero money | **FIXED** (2a floor). Live proof green |
| K09-BUG-6 (6_bugs, minor) | scroll tail double-counts the home inset | **FIXED** (2b: tail `--s8`). Live proof green (footer bottom 778) |
| 5_ui dev. 1 | row-1 glyph is a coin-slot mark, not a `£` | **FIXED** (2b → `NestIcons.jarPocketMoney`) |
| 5_ui dev. 2 | row-2 glyph must be the quest's own kid glyph | **FIXED** (2b → kid `questIconFor`) |
| 5_ui dev. 3 | row-1 sub/amount differ from the mock | **NOT A FINDING** — DB over mocks (`This Sunday` / `+£3.00` is the seeded value; the seed is anchored to today) |
| 5_ui dev. 4 | gift glyph unverified below the fold | **VERIFIED** (2b: `NestIcons.gift` draws HTML:95 exactly; K09-BUG-3b proof green) |
| 4_review 1 | `NestProgress` kid gloss spans the whole track | **OPEN SHARED** — `SHARED_REQUEST.md` filed; outside `kid_jar`, must not be attributed to K09 |
| 4_review 2 | over-saved “to go” | **= K09-BUG-4, FIXED** |
| 4_review 3 | money formatter split across layers (`formatJarAmount` in domain, `jarPounds` in a widget-less `jar_amounts.dart`) | **LEFT** — pure refactor, no visual change; cross-layer (see LEFT FOR NEXT ITERATION) |
| 4_review 4 | `watchJar()` doc contradicts the code | **FIXED** (2a) |
| 4_review 5 | `watchItems()` silently changed meaning for K10 | **DONE as docs** — handover line preserved below (K10 section) |
| 4_review 6 | loading label not a live region | **FIXED** (2b) |
| notes 18:47 | `jarPocketMoney` / `jarGift` swap once on main | **DONE** — main landed the assets (`NestIcons.jarPocketMoney`, `nest_icon.dart:59`); 2b swapped the branches (`NestIcons.gift` draws the design's `:95` SVG exactly, no `jarGift` file) |
| 3_test obs. 1 | scroll tail counts the home inset twice | **= K09-BUG-6, FIXED** |
| 3_test obs. 2–3 | `NestLockButton` `enabled` flag / semantics-label lookup | **NOT FINDINGS** — shared component + test technique; unchanged |
| 2_build (iter 1) LEFT | failure-state art (`NestIcons.jar` vs `JarIllustration`) | **LEFT** — cosmetic; a stage-5 call |

## K10 handover (closes 4_review 5)

`KidJarRepository.watchItems()` (and `KidJarBloc.state.items`) now serves
**money-in rows only** with `This/Last {weekday}` details, and each item
carries `iconKey`; `owedPence` is floored at 0 and `moveToSavings` is capped
at the goal remainder. K10 (`PayoutDayView`, sharing `KidJarBloc`) must not
assume the old every-row/`formatDay` contract.

## Verification (this stage)

Order run in `app/`; exact tails:

```
$ dart format .
Formatted 625 files (0 changed) in 1.93 seconds.
```

```
$ flutter analyze
Analyzing app...
No issues found! (ran in 3.0s)
```

```
$ flutter test --timeout 120s
02:19 +4266 ~4: All tests passed!
```

- `test/features/kid_jar` run explicitly → **`00:03 +105: All tests passed!`**
  — includes the five formerly red K09-BUG-1/2/3 proofs, the three formerly
  skipped K09-BUG-4/5/6 proofs and the K09-BUG-3b/over-saved widget proofs.
- The `~4` skips are pre-existing and belong to other features
  (`kid_home/k01_bugs_test.dart`, `kid_home/k03_bugs_test.dart` ×2,
  `pocket_money/p12_bugs_test.dart`). **No `kid_jar` test is skipped.**
- Only debug-build noise: Drift's “opened a second time” advice from the
  per-test in-memory databases — not an error, not merge-related.
- Scope: the changed/added paths are exactly `app/lib/features/kid_jar/**`,
  `app/test/features/kid_jar/**` and `docs/screens/K09/**` (2a/2b diffs).
  No core, no app, no other feature, no `tools/**`; no weakened analysis, no
  `DateTime.now()`, no `google_fonts` (comments only), no `flutter clean`,
  no interactive `flutter run`, no simulator booted/installed/driven, no
  image attached.

## LEFT FOR NEXT ITERATION

1. **4_review 3 — formatter split** (`formatJarAmount` in
   `domain/entities/jar_snapshot.dart`, `jarPounds` in the widget-less
   `presentation/widgets/jar_amounts.dart`). Pure refactor with no visual
   change; left by both builders as cross-layer. Needs a coordinated
   iteration or an explicit ruling that it may stay.
2. **Failure-state art** — `NestIcons.jar` at 96 px vs `JarIllustration`
   (cosmetic; the design has no error frame). Stage-5 call.
3. **4_review 1 — `NestProgress` dark gloss** — tracked in
   `SHARED_REQUEST.md`; the UI check must not attribute the dark-mode band
   to K09.
4. **5_ui re-check** — the only visually changed pixels are the two history
   row glyphs and the `coming on …` ink; geometry is otherwise unchanged
   (title 107, jar 151, goal 465, progress 557, heading 634, list 676,
   footer bottom 778).

VERDICT: PASS
