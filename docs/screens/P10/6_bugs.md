# P10 · Quest library — bug hunt (Stage 6, iteration 2)

Route `/quests` · feature `quests` · parent mode · seeds `Seed.demo()` (12
active quests) and `Seed.empty()` (0) · tests pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`. Tree tested: iteration-2 build checkpoint
`caeefe1` with shared batch4 on `main` (`c1be080`: `NestSegmented` 52/44,
`NestTextField.search`, `NestTabBar` content position, `watchActiveQuests`
creation order). `ORCHESTRATOR_NOTES.md` items 1–6 re-verified.

**Iteration-1 proofs:** all nine `p10_bugs_test.dart` proofs (BUG-P10-1…8)
are now un-skipped and **green** — they guard the fixes. **One new P10-local
major was found this iteration** (BUG-P10-12, proof added behind
`skip: 'BUG-P10-12'`). **One major shared bug remains open** (BUG-P10-10,
the only stable red in the feature). No screen code was changed.

| Id | Iter-1 | Iter-2 status |
|---|---|---|
| BUG-P10-1 | major | **FIXED** — `QuestPushOnce`; same-frame double tap → 1 editor; re-arm after pop verified |
| BUG-P10-2 | major | **FIXED** — `CrossAxisAlignment.start`; proofs green |
| BUG-P10-3 | minor | **FIXED** — search + chips rendered on Ideas only; proof green |
| BUG-P10-4 | minor | **FIXED** — 16 px separators between rows; end gap 32 |
| BUG-P10-5 | major | **FIXED** — shared `NestTextField.search`; icon 24 at x+16 |
| BUG-P10-6 | major | **FIXED** — shared `NestSegmented` 52/44; proof green |
| BUG-P10-7 | major | **FIXED** — shared tab bar; Today icon centre 749 (design 748) |
| BUG-P10-8 | major | **FIXED** — `ideas` in `QuestsState`; view no longer imports GetIt |
| BUG-P10-9 | major | **FIXED** — every P10 `Semantics(excludeSemantics: true)` carries `onTap` + `container`; a11y proofs green |
| **BUG-P10-10** | major | **OPEN (shared)** — `NestSegmented` announces each option twice; 3 red tests |
| BUG-P10-11 | minor | **FIXED** — `plate`/`sofa` tints |
| **BUG-P10-12** | — | **OPEN — new major** (P10-local) — applied search filter invisible after a tab round-trip |

---

## BUG-P10-12 — major — the applied search filter goes invisible after a tab trip

`quest_library_body.dart:38` keeps `_query` in `_QuestLibraryBodyState`, while
the search field exists only while `filtersOn` (`:118-131`, the BUG-P10-3
fix). Switching to Active removes the `NestTextField` from the tree and
disposes its internal text state; `_query` survives. Returning to Ideas
rebuilds an **empty** field while `filterQuestIdeas` still applies the old
query.

**Repro.** `/quests` → type `pet` (1 row: “Feed the pet”) → tap `Active (12)`
→ tap `Ideas`. The field is blank, but only “Feed the pet” is listed. With a
no-match query (`zzz`) the screen shows “No ideas found” under an empty search
field, with nothing on screen explaining why (measured: field text `""`,
empty state `true`).

**Proof (skipped with the bug id):** `returning to Ideas can show a query that
hides rows` in `p10_bugs_test.dart` — fails today with `Found 0 widgets with
text "Make your bed"` under the empty field. Fix-agnostic: it passes if the
app either keeps the query **visible** or clears it.

**Fix.** Hoist a `TextEditingController` in `_QuestLibraryBodyState` and pass
it to `NestTextField.search` (the field keeps showing the applied query across
tab switches; `_query` stays derived from it), or clear `_query` when
`filtersOn` goes false. Either way, un-skip BUG-P10-12.

## BUG-P10-10 — major — `NestSegmented` announces every option twice (shared)

`nest_segmented.dart:53-58` wraps each option in `Semantics(button, selected,
label, onTap)` without `excludeSemantics: true`, so the option's own `Text`
and the `InkWell` node merge into a second “Ideas” node. `find.bySemanticsLabel
('Active (12)')` matches **2** and a screen reader reads every label twice.
Proofs (red, owned by stage 3): `each option is one labelled, tappable
button`, `every interactive node announces what it does`, `the same semantics
contract holds in dark` in `quest_library_a11y_test.dart`.

**Fix (one line, shared):** add `excludeSemantics: true` to that per-option
`Semantics`; keep the `onTap` batch4 added. Filed in `SHARED_REQUEST.md` §1.
Not fixable under RULES §1 (core).

---

## Adversarial probes this iteration (no additional bugs)

| Area | Result |
|---|---|
| Push guard same-frame / cross-frame | Double tap before a frame → 1 `/quest-editor`; 50 ms-later tap absorbed → 1; back → `/quests`; fresh tap pushes again (re-arm) ✓ |
| Push guard via assistive tech | `performAction(tap)` on `+ Add` and on an Active row pushes the editor ✓ |
| A11y actions (new rule) | Chip `performAction(tap)` filters the list; `+ Add`/row push; segmented switches tab; search field is a labelled text field. Only the shared duplicate label (BUG-P10-10) is red |
| Absolute geometry, 390×844 with 47/34 insets (real fonts) | title top **55**; segmented top **105**, height **52**; `.search` row 173–225 (inner input 177–221, 44); chips top 225, chip centre 247; first card top **289**; Today icon centre **749** — every value within ±2 px of the design (notes items 1–5) |
| Regression suite | Iteration-1 proofs 9/9 green; responsive matrix 320/390/430 × 1.0/1.3 × light/dark green |
| Back / deep links | Editor back → `/quests`; `/quests` and `/quests/` match; kid mode → `/parental-gate` ✓ |
| Restart / Drift persistence | Re-pump and file-DB reopen keep `Active (12)`; a live insert updates to `Active (13)` ✓ |
| Dark mode | Tokens unchanged; tinted tiles stay tinted; contrast pairs ≥ 4.5:1 ✓ |
| 320 px + 1.3 scale, long UK names, 9999 coins, empty lists, async mid-push | All green (matrix + proofs) |
| Europe/London + BST, money pence, 0/1/6 children | N/A — no dates, no `£`, no child data on P10 |

Process note: the concurrent TEST stage (iteration 2) was writing
`quest_library_a11y_actions_test.dart` and editing `quest_idea_meta_test.dart`
while this stage ran; loader failures/analyze infos from those two files at
capture belong to that stage, not to this report. The 3 stable red tests are
BUG-P10-10 above.

## Gates at hand-off

- `flutter analyze test/features/quests/p10_bugs_test.dart lib/features/quests` → **No issues found**.
- `dart format --set-exit-if-changed` on the bug file → clean.
- `flutter test test/features/quests/p10_bugs_test.dart` → **9 passed, 1 skipped, 0 failed** (the skip is BUG-P10-12).
- BUG-P10-12 un-skipped → fails with the expected assertion; the other nine proofs pass on `caeefe1`.

VERDICT: FAIL
