# P09 — stage 2 · INTEGRATE (iteration 2)

This iteration is a **FIXES_1** round: 2a (logic) and 2b (UI) each took half
of the loop's `test=FAIL / ui=FAIL / bugs=FAIL` findings and fixed them in
parallel. Both halves needed **no** integration repair from me — see §4 for
the one formatting normalisation the merge forced. No redesign, no refactor.

## 1. What 2a handed over (logic half)

Two additive interface changes on `QuestsRepository` — **no renames, no
event/state changes**, so 2b could consume them as they landed:

1. **`Stream<int> watchCoinValuePencePerCoin()`** (BUG-P09-1) — reads the
   `families` row (the same source of truth as pocket_money's setup; the
   `settings` mirror deliberately *not* subscribed, because the bug repro
   writes `families` directly). Emits `1` until the row exists.
2. **`minCoins = 1` / `maxCoins = 100` + `_checkCoins`** on `createQuest` /
   `updateQuest` (BUG-P09-4) — assert in debug, `ArgumentError` in release,
   same shape as pocket_money's `setMode`/`setPayoutDay`. Bodies became
   `async` so the throw surfaces as a failed future the bloc already maps to
   `editorStatus.failure` + `editorError`.

Files: `domain/quests_repository.dart`, `data/quests_repository_impl.dart`,
`quests_repository_test.dart` (new `BUG-P09-1` and `BUG-P09-4` groups), plus
**one** forced knock-on line in `quest_editor_states_test.dart` — the
hand-written `_FaultyRepository implements QuestsRepository` would not compile
after the interface addition, so the new method is pure delegation (no fault
injected, none of that stage's assertions changed). Flagged in 2a, not hidden.
Bloc/events/state, entity, DI and routes untouched.

## 2. What 2b handed over (UI half)

Five bug fixes plus review findings 4/5/6/7/9/11/13 in `quest_editor_view.dart`
(one comment in `quest_editor_widgets.dart`, no behavioural change), and the
five `BUG-P09-*` proofs in `p09_bugs_test.dart` **un-skipped** (330 + ~5 →
335, all running):

- **BUG-P09-1** — `const _pencePerCoin = 1` deleted; the sheet subscribes once
  to `watchCoinValuePencePerCoin()` and prints `= ${coins × rate}p at payout`.
  The demo seed's rate of 1 still prints `= 15p at payout`, unchanged
  (DATA-over-mocks).
- **BUG-P09-2** — `_saving` flag guards `_save()` and drives the pill's
  disabled state; the route releases it through
  `_sheetKey.currentState?.clearSaveGuard()` when `editorStatus` turns
  `failure`, so a failed write never leaves a dead pill. No logic-layer guard
  was added on purpose (bloc handlers already run sequentially — 2a's
  analysis, which I checked against the code and agree with).
- **BUG-P09-3** — `_questIcons.aliases` now covers every seeded key
  (`sofa`→Bed, `plate`→Dishes, `bins`/`shirt`/`bag`→Bins, `leaf`→Paw), so the
  radiogroup is never silent. The alias only picks the highlighted tile; the
  stored key is preserved on save. Six tiles, same order, same geometry.
- **BUG-P09-4** — the stored value is shown as stored (opening the editor never
  silently rewrites it) and the stepper's bounds widen to include it
  (`_coinFloor`/`_coinCeiling`), while `_save` hands the repository an in-range
  value.
- **BUG-P09-5** — the roster moved from a `StreamBuilder` build-time write to
  one `initState` subscription; an assignee the roster no longer lists falls
  back to `Anyone`, so exactly one pill is selected and Save clears the
  dangling FK.
- Review findings 5 (`Quest.detail` is not a column — the view keeps no copy
  of its own), 7 (`buildWhen: previous.status != current.status`),
  9 (`active: initialQuest?.active ?? true` — editing never resurrects an
  archived row), 11 (roster), 13 (copy list names the ASCII apostrophe, which
  I re-verified byte-for-byte against the HTML: the source has zero U+2019 and
  the code matches).

## 3. Mandatory ORCHESTRATOR_NOTES items (17:57) — both handled

1. **Icon glyphs and order.** Order verified against
   `design/html-source/screens/P09-quest-editor.html` lines 30–35: Bed,
   Dishes, Hoover (selected), Book, Bins, Paw — exactly what
   `_questIcons` renders, labels included. On glyph *shape*: `ic_hoover.svg`
   and `ic_bed.svg` were redrawn in the DS by the `main` merge (canister +
   hose + wheels; bed frame + headboard), and `ic_book.svg` / `ic_paw.svg` are
   byte-identical to the design's. `ic_dishwasher.svg` and `ic_bin.svg` still
   differ, and those files are `core/` (off-limits), so 2b took the sanctioned
   route: SHARED_REQUEST §4 keeps asking for the exact paths, and Dishes draws
   the DS `basket` glyph — a swap inside `quests/`, not a redraw. **Stage 5
   owns the re-measure**; `bin` (tile MAE 17.3) is the one still expected to
   read clearly off.
2. **`Quest name` field text inset (app x ≈ 40, design x ≈ 37).** The cause is
   shared: `NestTextField`'s default variant leaves ~3 px more inset than the
   design's `1 px border + 16 px padding`. 2b filed it as SHARED_REQUEST §6
   with the numbers instead of hard-coding a call-site padding. Nothing in the
   screen moved (orchestrator instruction 3: do not move other elements).

## 4. FIXES in this stage

**No integration breakage was found.** The halves met on the same merged
bloc/state (`QuestEditorStatus`, `editorStatus`, `editorError` untouched by
2a), the same event names, and `QuestEditorView` needed no rename or import
fix. The one thing the merge left behind was cosmetic:

- `app/test/features/today/p08_bugs_test.dart` — the `main`-side conflict
  resolution (`fcdd5ed`, P11 approvals) left
  `GoRouter.of(tester.element(find.byType(Navigator).first)).go('/today')`
  split across five lines. `dart format .` joined it back to one line — no
  behaviour change, and `dart format --set-exit-if-changed .` is clean
  afterwards. The file is P08's; this is the formatting-only residue of the
  merge, not an edit of P08's assertions.

Coherence checks I ran beyond the gate: no `skip: true` anywhere in
`test/features/quests` (the repo's only skip is `p12_bugs_test.dart:320`,
P12's, unchanged from `main`); no `google_fonts` / `GoogleFonts` in the
feature; child order still comes from `watchChildren()` (creation order —
Maya, Leo), never sorted; icon order and copy verified against the HTML; and
`git status --short -- lib/core lib/app ../tools` is empty (no shared code, no
`tools/`, no `analysis_options.yaml`).

## 5. FIXES deliberately left open

- **Review finding 3** — `Tooltip(message: 'Back')` on Cancel stays: seven P10
  tests push `/quest-editor` and call `pageBack()`, which needs
  `find.byTooltip('Back')`. Converting those three files to
  `tester.binding.handlePopRoute()` is a separate commit (worth doing for
  VoiceOver, out of this stage's scope).
- **Review finding 8** — the per-keystroke `setState` still rebuilds the sheet
  (the `ValueListenableBuilder` split is cheap but out of the FIXES_1 list).
- **Review finding 2** — `tokens.surface` on the Save pill stays: measured in
  the dark PNG the label's core is rgb(21,19,31) ≈ `--surface`, and the design's
  own CSS says `color: var(--surface)`. Evidence recorded at the call site.
- **Shared, cannot be fixed from a screen agent:** `NestStepper`'s U+002D minus
  (§5), `NestTextField`'s ~3 px inset (§6), and the remaining
  `ic_dishwasher` / `ic_bin` paths (§4).
- **`?idea=` prefill** (P10's `+ Add` on an idea row) is still not implemented —
  new behaviour, not a merge breakage; `TODO(P10)` stands in
  `quest_library_body.dart`.

## 6. Verification (tails)

```
$ dart format .                              # 1 change: the merged p08_bugs_test line
Formatted 492 files (1 changed) in 1.91 seconds.

$ dart format --set-exit-if-changed .        # re-run, proves the tree is clean
Formatted 492 files (0 changed) in 1.95 seconds.   (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.4s)

$ flutter test
01:48 +2530 ~1: All tests passed!
```

`~1` is the single pre-existing skip in the repo
(`test/features/pocket_money/p12_bugs_test.dart:320`, P12-BUG-05 — identical on
`main`). The `WARNING (drift): AppDatabase created multiple times` notices are
the repo-wide debug-build notice from `test_scope.dart`, not failures.

No simulator was booted, installed on, screenshotted or driven in this stage.
`flutter clean` was never run; no `// ignore:` and no test was skipped or
weakened to reach green.

## 7. Handover

Stage 3 (test) has a green 2530-test suite and five newly-unskipped BUG-P09
proofs. Stage 5 (UI check) must re-measure the six icon tiles after the merged
glyphs + the Dishes→basket swap (2b's geometry table otherwise still holds:
uniform shift 0, every edge ≤ ±2 px, gutters 20, paper to the physical edge),
and can close ORCHESTRATOR_NOTES 17:57 item 2 only if the shared
`NestTextField` inset (§6) lands.

VERDICT: PASS