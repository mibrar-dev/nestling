# P09 — stage 2 · INTEGRATE (iteration 3)

This iteration is a **FIXES_2** round: 2a (logic) and 2b (UI) split the
loop's `test=FAIL / review=FAIL / ui=FAIL / bugs=FAIL` findings and fixed them
in parallel. They met on the same contract — 2a added one route query key,
2b consumed it — so **no integration repair was needed** (details in §4). No
redesign, no refactor, no shared-file edit.

## 1. What 2a handed over (logic half)

One additive route-contract key, nothing else:

- **`QuestsEditorQuery.ideaId` (`'idea'`)** in `quests_routes.dart` — P10's
  Ideas tab already pushes `/quest-editor?idea=<templateId>`; 2a defined what
  the editor does with it (seed a **new** draft from
  `QuestsRepository.ideas()`, `?id=` wins over `?idea=`, unknown ids fall back
  to the new-quest defaults) and left the view half to 2b.
- **Deliberately not changed, with reasons recorded rather than silently
  dropped:**
  - *Review finding 10* (parent-safe toast copy) would rewrite the bloc's
    `editorError` contract and turn green `quest_editor_states_test.dart`
    assertions red — another stage's file, and a path no parent can reach
    (the view clamps before dispatching).
  - *BUG-P09-6/7/8* need no repository/bloc/route change; the repo's coins
    validation stays as the unreachable last line of defence. Their five
    proofs stayed skipped until 2b's halves landed.
- No `domain/`, `data/`, `bloc/`, DI or DI-adjacent file needed work; the
  FIXES_1 additions (`watchCoinValuePencePerCoin`, the 1..100 write guard,
  `_FaultyRepository` delegation) stand.

## 2. What 2b handed over (UI half)

Everything `ORCHESTRATOR_NOTES.md` 19:19 listed as P09-local, plus the local
test/bugs findings:

| Item | Fix |
|---|---|
| Review **1** (major) | Dishes tile **reverted** from the look-alike `NestIcons.basket` to `NestIcons.dishwasher`; 19:19 says icons are shared, so the screen keeps the baseline glyph and substitutes nothing. |
| Review **2** (major) | `?idea=<templateId>` read next to `?id=`, seeding a **new** draft. The sheet grew an explicit `isEdit` flag, because a template seed is still a create: title stays `New quest`, no `Delete quest`, **fresh id** on save (never `idea-bed`), `active: true`. The stale `TODO(P10)` is gone. |
| Review **3** (minor) | `Tooltip(message: 'Back')` deleted (product code was serving `tester.pageBack()`); all 8 `pageBack()` sites across 4 P10 test files became `tester.binding.handlePopRoute()`. New P09 test pins the consequence. |
| Review **4** (minor, perf) | `QuestSavePill` inside a `ValueListenableBuilder<TextEditingValue>`; the per-keystroke `setState(() {})` is gone, so typing no longer rebuilds ~50 widgets. |
| Review **5** (minor) | Roster subscription rebuilds only on a real change (`listEquals`), and **both** subscriptions carry `onError: (_) {}`. |
| Review **6** (minor, a11y) | Due row's `semanticLabel: 'Due by, $_dueLabel'` — the old bare label made `NestCard` drop the row's own text, so VoiceOver never heard the current choice. |
| Review **8** (docs) | The false "main redrew the glyphs" claim struck; the `Who's` apostrophe sentence corrected to U+0027 (I re-verified: the HTML has zero U+2019 and the code matches). |
| **BUG-P09-8** (major) | `nickname.substring(0, 1)` → `nickname.characters.first` (same accessor P06 uses) — an emoji-leading nickname handed the paragraph builder a lone surrogate. |
| **BUG-P09-6** | Out-of-range stored coins: still *shown* as stored, but Save is blocked with a live-region `Coins must be 1–100`, so no silent clamp. |
| **BUG-P09-7** | An already-highlighted icon tile's tap is inert, so tapping Dishes for a `plate` quest no longer rewrites the stored key. |
| Un-skips | BUG-P09-6 ×2, -7, -8 ×2 now run every `flutter test` (5 skips → 0). Assertions untouched. |

Forced mechanical test updates (my check: none weakened or deleted — each was
forced by a rendered string or harness contract changing): the due-row label
in `quest_editor_a11y_test.dart` (3 refs + the `pick()` helper), the Dishes
glyph in `quest_editor_data_integrity_test.dart`, and the 8 `pageBack()`
conversions. `quest_editor_view_test.dart` gained 6 tests.

Feature scope: **367 + ~5 → 378 pass, 0 skipped**.

## 3. Mandatory orchestrator items

**19:19 — "icons, toggle, stepper minus, field inset are SHARED … do not
substitute icons"** — honoured: the picker uses the baseline `NestIcons.*`
set in the design's order (Bed, Dishes, Hoover, Book, Bins, Paw, verified
against the HTML), `SHARED_REQUEST.md` §4 no longer argues for a substitute,
and the only string this stage adds to the screen is the local validation
copy `Coins must be 1–100` (en dash, matching the sanctioned
`Pick at least one day` pattern).

**19:19 — "when main has batch5 … switch the picker to the icon names in
`shared_batch5_REPORT.md` and remove `toggleTrackOffset`" — NOT yet
actionable in this tree.** `shared/shared_batch5` **is** on `main`
(`87cf5d4`/`9bbf65a`, "P09 exact quest icons, NestToggle 51x31 + hit slop,
stepper U+2212, textfield 17px inset"), but it landed at **19:19:39**, two
minutes *after* this branch's merge of `main` (`6072d8a`, 19:17:51), so it is
not in this worktree: `git merge-base --is-ancestor 9bbf65a HEAD` fails and
`app/assets/icons/ic_quest_*.svg` are absent here. Per the orchestrator's
PROCESS ITEMS rule ("the branch being behind main, and merge order are handled
by the loop and the orchestrator"), merging `main` is the loop's step, not a
P09 finding — so I did not merge, and did not pre-empt the batch with a local
hack. **Next build, immediately after the loop's merge, this becomes
mandatory** and is the only P09 work left that touches product code:

1. read `docs/screens/_shared/shared_batch5_REPORT.md`, switch the six tiles to
   the exact icon names it lists;
2. delete `QuestEditorMetrics.toggleTrackOffset`, its `Transform.translate`
   wrapper and the approval card's comment (the fixed `NestToggle` now paints
   its 51×31 track as the layout box with the hit area as slop);
3. flip `quest_editor_copy_test.dart`'s `kGlyphs` minus entry from `'-'` to
   `'−'` **in the same commit** as the shared `NestStepper` flip;
4. re-measure the toggle rect in `quest_editor_view_geometry_test.dart` and the
   six tile MAEs for stage 5.

**17:57 item 2** (field text inset, app x ≈ 40 vs design x ≈ 37) is the shared
`NestTextField` 17 px inset that batch5 also carries; nothing local to do.

## 4. FIXES in this stage

**None needed.** The halves met on the merged bloc/state surface
(`QuestEditorStatus`, `editorStatus`, `editorError` — 2a touched none of them),
on the same event names, and 2b consumed `QuestsEditorQuery.ideaId` as it was
written. `dart format .` reported **0 changed** — not even a merge residue
this time. Checks I ran beyond the gate:

- `skip: true` count in `test/features/quests` = **0**; the repo's only skip is
  `p12_bugs_test.dart:320` (P12's, identical on `main`) — that is the `~1`.
- no `google_fonts` / `GoogleFonts` in the feature's lib or tests;
- `git status --short -- lib/core lib/app ../tools` → **empty** (no shared
  code, no `tools/`, no `analysis_options.yaml` change);
- icon order and the `Who's it for?` apostrophe re-verified against
  `design/html-source/screens/P09-quest-editor.html`;
- `_save()` re-read end-to-end: a `?idea=` seed writes a fresh id and
  `active: true`, an edit keeps its id and `active` flag, and the create/update
  event follows `isEdit` — the template row can never be updated or written.

## 5. FIXES deliberately left open

- **Review finding 10** (parent-safe toast copy) — bloc layer; 2a's note is
  right that applying it turns green `quest_editor_states_test.dart`
  assertions red, so it needs one commit across the bloc and that file.
- **Review findings 7/8/9** — docs/process items for the loop.
- **`?idea=` unknown-id fallback** and the template → draft mapping are
  covered by tests; nothing further queued.
- **The four batch-5 follow-ups in §3** — the next build's mandatory list.

## 6. Verification (tails)

```
$ dart format .
Formatted 494 files (0 changed) in 2.15 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.7s)

$ flutter test
02:06 +2573 ~1: All tests passed!
```

`~1` is the single pre-existing skip in the repo
(`test/features/pocket_money/p12_bugs_test.dart:320`, P12-BUG-05, unchanged
from `main`). The `WARNING (drift): AppDatabase created multiple times`
notices are the repo-wide debug-build notice from `test_scope.dart`, not
failures. Suite grew 2530 → 2573 (+11 new P09 tests, +5 un-skipped BUG-P09
proofs, +27 elsewhere in the repo's other features).

No simulator was booted, installed on, screenshotted or driven in this stage.
`flutter clean` was never run; no `// ignore:` was added and no test was
skipped or weakened to reach green.

## 7. Handover

Stage 3 (test) has a green 2573-test suite with **zero** skipped proofs in the
feature. Stage 5 (UI check): nothing moved in the design state this iteration
(the caption is reachable only from a corrupt stored value, the pill swap is
the same widget inside a listenable, `quest_editor_view_geometry_test.dart` is
green unchanged), so the ±2 px table still holds — **but** after the loop's
batch-5 merge the icon tiles and the toggle track will move, so the tile-MAE
and toggle-rect re-measure is the first job of that stage.

VERDICT: PASS