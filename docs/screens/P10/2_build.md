# P10 · Stage 2 — INTEGRATE (iteration 4, last pass)

**Result: `dart format` → 0 changed (exit 0) · `flutter analyze` → No issues
found · `flutter test` → `+1977 All tests passed!`**

**Nothing needed fixing.** There was no integration breakage to reconcile this
iteration and no red test to chase: the shared search-field fix that blocked
iterations 3 (and 2 before it) landed on main and was merged into the branch by
the loop, and both halves verified green against it as-is. No product code
changed; the only diffs are two test files (tightenings + stale-comment
repairs) and `SHARED_REQUEST.md`, all inside `features/quests/**` and this
screen's notes.

## Summary of 2a — logic chunk

**No files changed, no contract change.**
`QuestsState(status, items, ideas, errorMessage)` and `QuestsLoadRequested` are
unchanged since iteration 2, so the UI layer needed no re-plumbing.
`FIXES_3.md` contained **zero** items in this layer, which it triaged against
every FIXES entry, both review findings it owns (`3` watcher leak, still green
with `_closeOnError`) and the test-stage additions (view-layer files it
disclaimed, all passing against the unchanged bloc). 27/27 in
`quests_repository_test.dart` + `quests_bloc_test.dart`, including the
`_closeOnError` leak proof and the creation-order pin.

## Summary of 2b — UI chunk

**No product code changed.** Every remaining item was closed by the shared
merge (`686ce06` → `1db0f8a` "search field 54 tall, text centred"), so 2b used
the pass to re-measure the design straight off
`design/screens/light/P10-quest-library.png`, tighten the proof suite from "±2
ceiling" to "±1 where demanded", repair documentation that had fossilised the
now-fixed defect, and close two gaps in the UI proofs.

Re-measured table (design ÷3 vs app at 390×844, 47/34 insets, real Inter/Nunito
through `FontLoader`) — every Δ is 0 except the two rasteriser notes below:

| Element | Design | App | Δ |
|---|---|---|---|
| title box / ink | 55…89 · ink 61.00…86.33 | 55.0…89.0 | 0 |
| `.segmented` track / thumb | 105…157 · 109…153 | 105.0…157.0 | 0 |
| `.search` ring | 173.0…226.7 (54) | 173.0…227.0 | 0 |
| `.search` hint ink | 194.0…206.0, centre **200.0** | centre **200.0** | 0 |
| card tops (all ten) | 291 / 375 / 459 / 543 / 627 / 711 | identical | 0 |
| card 1 height / step | 68 / 84 | 68.0 / 84.0 | 0 |
| `.trow` title/meta ink x | 85.0 / 85.0 | 84.0 (box; ink ≈85) | 0 |
| `.tab-bar` surface | top 726.0 | 726.0 → 844 | owner edge rule ✓ |

The uniform −2 px shift of the whole lower half is gone: it was entirely the
52-vs-54 field box, so the chip row and all ten cards now land on 227 / 291 /
375 / … exactly and the hint on 200 instead of 189. That was BUG-P10-14, the
sole red test of iteration 3, and `5_ui.md`'s only deviation.

Changes 2b made (all in its scope):
1. **`quest_library_design_geometry_test.dart`** — `_Design.tight = 1` now backs
   the field top/height, chip top/height, card top/height and the 84 px step in
   light *and* dark; the hint-vs-field-centre assertion went ±2 → ±1. Added the
   chip **width** (48 ±2) + flush-to-gutter + the 8 px `.chipscroll` gap, and a
   new `+ Add` pill shape proof (71 × 44, left edge 287, right edge 12 inside
   the card, centred in the row) — the UI CHECK MEASURES SHAPES rule's two
   un-pinned pills. Header table corrected against the PNG (chip … 270.7, card 1
   … 358.7, hint ink, magnifier ink, `+ Add` added) and the "RED on purpose /
   cause is in core/" prose rewritten to what is true after `1db0f8a`.
2. **`quest_library_states_test.dart`** — one stale comment line ("the view
   reads the idea templates from GetIt" contradicted the correct comment four
   lines above). Comment only; 2a disclaimed the file and did not touch it, so
   there is no merge conflict.
3. **`SHARED_REQUEST.md`** — §9 and §10 marked CLOSED with the landing commit;
   §6/§7/§8/§11 left clearly open.

## FIXES

### FIXES-1 — DONE (nothing to fix) · no integration breakage

Verified, not assumed:

- **Contract**: unchanged since iteration 2; view still passes `state.items` /
  `state.ideas` with no service-locator probe; no widget signature moved.
- **File sets**: disjoint. 2a touched **no** file; 2b touched
  `quest_library_design_geometry_test.dart`,
  `quest_library_states_test.dart`, `SHARED_REQUEST.md`. No overlapping edit,
  no import fallout, nothing to re-base.
- **Iteration-3 blocker (FIXES-2)**: CLOSED by shared `1db0f8a` (merged
  `686ce06`) — `NestTextField.search` is now a 54-high border box with 10 px of
  vertical content padding around the 24 px line box, so the hint centres on
  200. No local workaround was taken, per the orchestrator's rule.
- **Iteration-2 items** (states-test mock stub, a11y prefix finder, hidden-anchor
  deletion) still hold; `today_view_test.dart` asserts `pushedPath(tester)` and
  passes with no anchor in the tree.

### FIXES-2 — ORCHESTRATOR_NOTES 13:42, item by item

1. *"Un-skip every proof that waited on these … All must pass."* Done and
   verified: no `skip:` marker exists anywhere in `test/features/quests/` (the
   only grep hit is the comment recording their removal), the four proofs are
   green, and 2b tightened them to ±1 as asked — `quest_library_a11y_test.dart`
   20/20 (one semantics node per segmented option), `…_a11y_actions_test.dart`
   11/11, geometry green in light and dark.
2. *"Delete the hidden `P10 Quest library` anchor if it is still there."* It is
   not: already removed in iteration 2. Independently swept —
   `Offstage` / `Opacity(opacity: 0)` / `excludeFromSemantics` in
   `lib/features/quests/` → 0 hits; the literal `P10 Quest library` appears in
   exactly one place in the whole app, and it is a **negative** assertion
   (`quest_library_a11y_test.dart:444` → `findsNothing`, the placeholder label
   must not be announced).
3. *"Fix the remaining local items in FIXES_3.md. Change nothing else."* Done —
   the only P10-local items left in FIXES_3 were closed; 2b changed no widget,
   no view and no shared file.

### FIXES-3 — nothing P10-local remains; open items are shared/P08-owned

Informational only, no P10 test is red on any of them, and RULES §1 forbids
this screen to touch them:

- `SHARED_REQUEST.md` **§8** — the search field's `aria-label` still lands on an
  inert wrapper node (`nest_text_field.dart:213`) rather than merging into the
  editable node, so that node advertises `isTextField` with no action. Worth
  keeping on the orchestrator's radar under the ACCESSIBILITY ACTIONS rule: the
  suite proves the *behaviour* (the label is in the tree exactly once and typing
  really filters), not an action on that node, because the parameter lives in
  `core/`.
- **§11** — the keyboard's blue **Search** key does nothing; the shared search
  variant exposes no `onSubmitted`. 2b deliberately kept
  `textInputAction: TextInputAction.search` rather than dropping the key to make
  the screen look right while the real fix sits in `core/` — correct call.
- **§6** (promote `QuestPushOnce` to `core/`), **§7** (P08 paints `plate` lilac
  where P10's design says sky).

### Integrator judgement call 2b raised — review finding 4

2b asked integration to rule on the pure `quest_idea_meta.dart` data/filter
module living in `presentation/widgets/`. **Leave it as it is.** `2a` recorded
that `ARCHITECTURE.md:71` reserves `domain/` for entities plus the abstract
repository, and the `quests` table has no category column to model — RULES §1
forbids the schema change that would be required to move it. No action.

## Verification

```
$ dart format --set-exit-if-changed .
Formatted 440 files (0 changed) in 1.10s.      (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.8s)

$ flutter test
00:36 +1977: All tests passed!

$ flutter test test/features/quests
00:05 +191: All tests passed!
```

Independent sweeps: 0 `skip:` markers in the feature; 0 `google_fonts` /
`GoogleFonts.*` in the feature's lib or tests; 0 hidden-anchor constructs. The
only red-free change class in the diff is *tightening* (tolerances down, new
shape proofs added) — no assertion was relaxed, no design constant was rewritten
to match the app, and the one rewritten test (search-field actions, iteration 3)
is documented in `2b_build_ui.md` §"review advisory 1". The
`WARNING (drift): AppDatabase created multiple times` notices in the output are
the repo-wide debug-build notice from `test_scope.dart`, not failures.

No simulator was booted, installed on, screenshotted or driven in this stage.

VERDICT: PASS