# P10 · Quest library — bug hunt (Stage 6, iteration 3)

Route `/quests` · feature `quests` · parent mode · seeds `Seed.demo()` (12
active quests) and `Seed.empty()` (0) · tests pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`. Tree tested: iteration-3 build checkpoint
`325e93e`, with shared `segmented_semantics` (`ab1ba06`, merged `0cdb53c`) and
batch4 on `main`. `ORCHESTRATOR_NOTES.md` items 1–6 plus the 12:17 update
re-verified.

**Result: no new P10-local bug.** Every finding from iterations 1–2 is fixed
and guarded by un-skipped green proofs; the whole feature is green except the
**one mandatory pin for a shared defect** — `NestTextField.search` floats the
hint 11 px too high (BUG-P10-14). No screen code was changed by this stage;
`p10_bugs_test.dart` needed no edit (its only skip, BUG-P10-12, is now a
green proof).

| Id | Iter-2 | Iter-3 status |
|---|---|---|
| BUG-P10-1 | fixed | green proof (push guard) |
| BUG-P10-2 | fixed | green proof (row text x+64) |
| BUG-P10-3 | fixed | green proof (filters Ideas-only) |
| BUG-P10-4 | fixed | green proof (end gap 32) |
| BUG-P10-5 | fixed | green proof (search icon 24 at x+16) |
| BUG-P10-6 | fixed | green proof (segmented 52/44) |
| BUG-P10-7 | fixed | green proof (tab content y) |
| BUG-P10-8 | fixed | green proof (ideas in state) |
| BUG-P10-9 | fixed | green proofs (semantics actions) |
| BUG-P10-10 | open (shared) | **FIXED** on main `ab1ba06` (`excludeSemantics`); a11y suite 20/20 |
| BUG-P10-11 | fixed | green proof (tile tints) |
| BUG-P10-12 | open (local) | **FIXED** — `TextEditingController` owned by the body; round-trip probe below; proof green |
| BUG-P10-13 | open (shared) | **no red** — assertion rewritten to what P10 owns; underlying node-merge defect informational, `SHARED_REQUEST.md` §8 |
| **BUG-P10-14** | — | **OPEN (shared, major)** — search hint centre 189 vs design 200; the sole red test |

---

## OPEN — BUG-P10-14 — major — `NestTextField.search` floats the hint to the top

`app/lib/core/design_system/components/nest_text_field.dart` (`_buildSearch`):
the editable gets a tight 44 px `SizedBox` with `isDense` + negative left
padding, and `TextAlignVertical.center` only centres the ~24 px line box inside
itself, so the hint paints at the **top** of the slot.

Measured on `/quests` at 390×844 with the device insets (the geometry suite,
real fonts): field box 173…225, magnifier centre **199** (correct), hint box
177…201 → hint centre **189**; the design's field is 173…227 and its hint sits
level with the magnifier at **200** (ORCHESTRATOR_NOTES 12:17 item 1, ±1
mandate). Everything below the field is consequently the uniform **−2 px**
shift: chip pill 227→225, cards 291→289, 375→373, … (12:17 item 2). A 11 px
error and a whole-lower-half shift both violate the UI VERDICT RULE.

**Proof (the only red in the feature, mandatory per note 3):**
`quest_library_design_geometry_test.dart` →
`the hint is centred in the field, not floated to the top` (`hint.center.dy`
189 vs 200±1, and vs `field.center.dy` 199).

**Fix (shared — `SHARED_REQUEST.md` §10, RULES §1 forbids editing `core/`):**
give the editable the full 44 px box rather than a line box (vertical
`contentPadding` of `(44 − 24) / 2 = 10` beside the existing `left: -4`, or a
`strutStyle`/`textHeightBehavior`), and settle `§9` at the same time (row 52 →
the design's 54). The pin already uses the design value 200, so it goes green
when either shared fix lands. Related shared minors with no red: §8 (the
`aria-label` lands on an inert wrapper node; the editable announces the hint).

## Fixed this iteration (verified)

- **BUG-P10-12** — `_QuestLibraryBodyState` now owns and disposes a
  `TextEditingController`, passed to `NestTextField.search`. Probe: type `pet`
  → Active → Ideas keeps the field text `pet` and the 1-row filter; clearing
  restores the list. Proof green (no skip left).
- **Review finding 3 / watcher leak** — `QuestsBloc` streams through
  `_closeOnError` before `emit.forEach`; proof
  `a failed load releases its watcher so retry subscribes exactly once` green
  (`quests_bloc_test.dart:202`, 17/17).
- **Review 6/7/8** — `NestType.bodyStrong` reuse, both empty states on the
  20 px gutter (probe: both rects x 20…370), `NestSpacing.s10` for the tile.

## Adversarial probes this iteration

| Area | Result |
|---|---|
| Search round-trip (the BUG-P10-12 fix) | text preserved and applied; clear → full list ✓ |
| Filter semantics sanity | `the` → 7 ideas (all titles containing “the”), `pet` → 1 ✓ |
| Empty states | Active `(0)` and Ideas no-match both x 20…370 ✓ |
| Watcher retry | 1 subscription after a failed load; retry reaches `loaded` ✓ |
| Suites | a11y 20/20, a11y-actions 11/11, view 27/27, widget 16/16, states 19/19, filter 20/20, meta 16/16, repo 10/10, bloc 17/17, geometry 8/9 (hint pin) |
| Rapid double taps / push guard / performAction | Still green (10/10 in `p10_bugs_test.dart`) |
| UI VERDICT RULE measurements (design → app) | title 55…89 → 55…89 (0); segmented 105…157 → 105…157, thumb 109…153 → 109…153 (0); field 173…227 → 173…225 (−2); chip 227…271 → 225…269 (−2); cards 291/375/459/543/627/711 → 289/373/457/541/625/709 (−2 each); tab surface top 726 → 726, bottom design 810 → app 844 (owner edge rule ✓); tab icon 736…760 → 737…761 (+1); label 764…778 → 765…779 (+1); **hint centre 200 → 189 (−11, open)** |
| Back/deep links, kid gate, restart persistence, dark mode, 320 × 1.3, long names, 9999 coins, async mid-push | Unchanged code paths, still green |
| Europe/London + BST, money pence, 0/1/6 children | N/A on P10 |

Process note: the concurrent UI stage left `zz_probe_empty_test.dart` and a
whole-app analyze run picked up its 3 infos; P10-owned files are clean. The
2026-10-03 UI screenshots (`app_*_3.png`) are that stage's.

## Gates at hand-off

- `flutter analyze` → clean for every P10-owned file (3 infos from the other
  stage's temp probe only).
- `dart format --set-exit-if-changed` on the P10 test files → 0 changed.
- `flutter test test/features/quests` → **176 passed, 1 failed** — the failed
  test is the shared BUG-P10-14 pin above.
- `flutter test test/features/quests/p10_bugs_test.dart` → **10/10, no skips**.

VERDICT: FAIL
