# P09 — 2b build, UI chunk (iteration 2)

## CONTRACT CHANGES read before finishing

Re-read `docs/screens/P09/2a_build_logic.md`: iteration 3 made **no** logic
edits and the contract stands — `QuestsCreateRequested` / `QuestsUpdateRequested`
/ `QuestsDeleteRequested`, `QuestsState.editorStatus`
(`QuestEditorStatus.initial/saving/saved/failure`) + `editorError`, edit id
from `GoRouterState.of(context).uri.queryParameters[QuestsEditorQuery.questId]`.

The logic builder's **uncommitted** work in this worktree is what this stage
builds on (no renames):

- `QuestsRepository.watchCoinValuePencePerCoin()` — `Stream<int>` over the
  `families` row (the `settings` mirror deliberately not subscribed).
- `QuestsRepositoryImpl.minCoins = 1` / `maxCoins = 100` + `_checkCoins` on
  create/update.

Both are consumed here; nothing in `2a`'s surface was renamed.

## Files changed (UI layer only)

| File | Change |
|---|---|
| `app/lib/features/quests/presentation/views/quest_editor_view.dart` | the five bug fixes + review findings 4/5/6/7/9/11 |
| `app/lib/features/quests/presentation/widgets/quest_editor_widgets.dart` | one comment (finding 2 evidence); no behavioural change |
| `app/test/features/quests/p09_bugs_test.dart` | `skip: true` removed from the five `BUG-P09-*` proofs (5 flags), header rewritten |
| `docs/screens/P09/SHARED_REQUEST.md` | §4 glyph update, §5 correction for whoever lands the minus |

No `core/`, `family/`, router, seed, schema or `pubspec` edit. No new test
file was needed: every fix is proven by an existing, previously-skipped proof.

## FIXES_1 — every UI/layout/copy item closed

### BUG-P09-1 (major) — the payout helper ignored the family's coin value → **fixed**

`const int _pencePerCoin = 1` is gone. The sheet subscribes once to
`QuestsRepository.watchCoinValuePencePerCoin()` and renders
`'= ${_coins * _pencePerCoin}p at payout'`. The helper is now DB-driven, so a
2p-per-coin family reads `= 30p at payout` (DATA-over-mocks: the demo seed's
rate of 1 still prints `= 15p at payout`, unchanged). Also review finding 4.

### BUG-P09-2 (major) — a double tap on Save created the quest twice → **fixed**

Two layers: the sheet holds a `_saving` flag that `_save()` checks and sets
(and that `QuestSavePill` reads, so the pill renders disabled while the write
is out), and the route releases it via
`_sheetKey.currentState?.clearSaveGuard()` in the `BlocConsumer` listener the
moment `editorStatus` is `failure`, so a failed write never leaves the parent
with a dead pill. Review finding 6. `_sheetKey` is a plain
`GlobalKey<_QuestEditorSheetState>` passed as the sheet's `key` — no setter
hack, no shared file.

### BUG-P09-3 (minor) — an icon outside the six tiles showed no selection → **fixed**

`_questIcons.aliases` now covers every key the seed stores: `sofa`→Bed,
`plate`→Dishes, `bins`/`shirt`/`bag`→Bins, `leaf`→Paw. Editing `q-table`,
`q-washing`, `q-living`, `q-bag` or `q-plants` therefore highlights exactly one
tile, so the radiogroup is never silent for a screen reader. The alias only
decides which tile is *highlighted* — `_icon` still holds the stored key, so an
untouched save preserves `plate` etc. Also review finding 10. **Geometry is
unchanged**: still exactly six 44×44 tiles in the same order (the a11y set
equality of 25 labels and the geometry suite both still pass).

### BUG-P09-4 (minor) — out-of-range stored coins were unreachable → **fixed**

`_coins` is initialised from the row as stored (no silent rewrite on open), and
the stepper's own bounds widen to include it
(`_coinFloor = min(1, stored)`, `_coinCeiling = max(100, stored)`), so a 9999
quest steps down to 9998 with `+` still live and every value between stays
reachable. What `_save` writes is clamped to the repository's 1..100 contract
(`_checkCoins` would otherwise throw), so the DB never receives an out-of-range
count. A new quest keeps the design's bounds: minus dead at 1, plus dead at 100.

### BUG-P09-5 (minor) — a removed child left an orphaned assignee → **fixed**

The roster now lives in a field updated from one subscription in `initState`
(review finding 11 — it was being written during a `StreamBuilder` build). Once
the roster has loaded, `_effectiveAssignee` treats an id it no longer lists as
`Anyone`, and `_assigneeRow` paints from that same value — so exactly one pill
is selected and Save writes `assigneeChildId: null` instead of a dangling FK.

### Review findings folded in

- **5** — `Quest.detail` is not a column (the repository recomputes it on every
  read), so the view no longer carries its own copy; `_repeatLabel` deleted.
- **7** — `buildWhen: previous.status != current.status`: the editor never reads
  `items`, so `watchItems()` re-emissions no longer rebuild ~50 widgets.
- **9** — `active: widget.initialQuest?.active ?? true`; editing no longer
  resurrects an archived row.
- **11** — the roster is no longer mutated during build (see BUG-P09-5).
- **13** — the copy list in this file now names the ASCII apostrophe, matching
  the HTML source and the code.

### Review finding 2 — investigated, deliberately NOT changed

`tokens.surface` on the Save pill stays. Measured in the pill's own rect
(logical 296–370 × 80–124) of `design/screens/dark/P09-quest-editor.png`: the
label's core colour is **rgb(21,19,31)** ≈ `--surface` #1F1C2E, whereas
`--onLeaf` dark is **rgb(14,26,20)** — a greenish tone the design does not
print (in light mode `--surface` == `--onLeaf` == #FFFFFF, so the two are
indistinguishable). The design's own CSS says `color: var(--surface)`. The
evidence is recorded at the call site so the question is not re-opened.

### 5_ui deviation 1 (BLOCKER, icon glyphs) — status changed by the merge

The loop merged `main` after stage 5 filed `SHARED_REQUEST.md` §4, and two of
the four glyphs have since been redrawn in the DS: `ic_hoover.svg` is now a
canister body + hose + wheels (the "hook/whistle loop" is gone) and
`ic_bed.svg` is a bed frame + headboard; `ic_book.svg` / `ic_paw.svg` are
byte-identical to the design's SVGs. `ic_dishwasher.svg` and `ic_bin.svg` are
unchanged and still differ from the design.

For Dishes the screen now draws `NestIcons.basket` — the design's Dishes SVG
(`M4 11h16v9…` + `M8 11V7a4 4 0 0 1 8 0v4`) is a handled basket, and the DS
already ships a basket glyph (tapered body + handle arc) while the dishwasher
appliance is a different object at whole-tile MAE 19.9. This is a glyph swap
inside `quests/`, not a redraw; §4 still asks the DS for the exact path, and
`ic_dishwasher.svg` remains correct for the P10 library rows
(`quest_idea_meta.dart`'s `questIconAsset`). **Stage 5 must re-measure the six
tiles**; `bin` (17.3) is the only one expected to stay clearly off.

Nothing else moved: no padding, tile, pill, card or label changed size or
order, so stage 5's pixel-perfect geometry table (uniform shift 0, every edge
≤ ±2 px, gutters 20, paper to the physical edge) still describes this build.

## Accessibility (unchanged contract, re-verified)

Every interactive element still passes `onTap:` on its own `Semantics` node
alongside the `InkWell`, with `excludeSemantics: true` on the same node — icon
tiles, person pills, Cancel, Save, the due row and the three due-sheet rows.
The disabled Save pill still reports `enabled: false` with no tap action, and
now also during an in-flight write. No new control was introduced, and the
25-label set equality in `quest_editor_a11y_test.dart` is untouched and green.

## Verification

```
$ dart format --set-exit-if-changed lib/features/quests test/features/quests
Formatted 41 files (0 changed)

$ flutter analyze lib/features/quests test/features/quests
No issues found!

$ flutter test test/features/quests/
00:15 +335: All tests passed!        # was 330 + ~5 skipped; the 5 BUG-P09-* proofs now run

$ flutter test test/features/today/
00:04 +110: All tests passed!        # P08 consumes this route (cancel → /today)
```

Whole-app `flutter test` and any simulator were deliberately **not** run
(the integrator / stage 5 own them). No simulator was booted, installed on,
screenshotted or driven. `flutter clean` was never run; no `// ignore:` and no
`analysis_options.yaml` change; `google_fonts` appears nowhere.

## LEFT FOR NEXT ITERATION

- **`Tooltip(message: 'Back')` on Cancel (review finding 3).** Kept on purpose:
  seven P10 tests push `/quest-editor` and then call `pageBack()`, which
  resolves `find.byTooltip('Back')`. Deleting it needs those files
  (`quest_library_states_test.dart`, `quest_library_a11y_actions_test.dart`,
  `p10_bugs_test.dart` — none of them `view`/`widget`-named, i.e. not this
  stage's files) converted to `tester.binding.handlePopRoute()` in one
  commit. Worth doing for VoiceOver, not in a 25-minute chunk.
- **Review finding 8 (per-keystroke rebuild).** `onChanged: (_) =>
  setState(() {})` still rebuilds the sheet per character. The fix
  (`ValueListenableBuilder<TextEditingValue>` around `QuestSavePill` only) is
  cheap but was left alone to keep this iteration's diff to the FIXES_1 list.
- **Shared, still open (cannot be fixed from a screen agent):**
  `NestStepper`'s U+002D minus (SHARED_REQUEST §5 — §5 now records that
  `quest_editor_copy_test.dart`'s `kGlyphs` currently *requires* the hyphen and
  must be flipped to `'−'` in the same commit that fixes the component), the
  `NestTextField` ~4 px text inset (§6), and the remaining `ic_dishwasher` /
  `ic_bin` paths (§4).
- **Stage 5 owns:** the ±2 px re-check and the tile MAE re-measure after the
  merged glyphs and the Dishes swap.

VERDICT: PASS