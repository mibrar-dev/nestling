# K04 quest detail — Stage 6 bug hunt (iteration 2)

Scope: `kid_home` · route `/quest-detail` · kid mode. Second adversarial pass
over the iteration-2 build (K04-BUG-1/2/3 fixes + shared merges), against
`docs/screens/RULES.md`, the orchestrator rules, `ORCHESTRATOR_NOTES.md`
(14:28 and 15:08) and the K03 bug history.

**Result: all three iteration-1 findings are fixed and verified; one new
Minor (cosmetic) bug found.** No major bug remains open in K04's code.

| # | Severity | Status (iter 2) | Area |
|---|---|---|---|
| K04-BUG-1 | was Major | **FIXED & verified** | `.kid-title` / `NestBalancedText` + `maxLines: 3` |
| K04-BUG-2 | was Minor | **FIXED & verified** | `_resolveQuest` extra handling |
| K04-BUG-3 | was Major (mandated) | **FIXED & verified** | hero tile icon glyphs (`_iconFor`) |
| K04-BUG-4 | Minor | **OPEN** | over-cap title is clipped, not ellipsised |

Proofs live in `app/test/features/kid_home/k04_bugs_test.dart`. The three
fixed proofs now run **un-skipped** as regression guards; the new K04-BUG-4
proof is skipped by default (`// skip: K04-BUG-4` next to `skip: true`; the
test name carries the id) so the plain suite stays green.

Commands (iteration 2):

```
$ flutter test --timeout 120s test/features/kid_home/k04_bugs_test.dart
00:03 +13 ~1: All tests passed!      # 13 live probes + 1 skipped (BUG-4)

$ flutter test --timeout 120s --run-skipped --plain-name K04-BUG-4 \
    test/features/kid_home/k04_bugs_test.dart
Expected: TextOverflow:<TextOverflow.ellipsis>
  Actual: TextOverflow:<TextOverflow.clip>
1 test failed                        # the bug is real

$ flutter analyze
No issues found! (ran in 5.7s)
```

---

## K04-BUG-4 — a title longer than the 3-line cap is clipped, not ellipsised (Minor, OPEN)

**Where:** `NestBalancedText(quest.title, … maxLines: 3)` in
`quest_detail_view.dart` (no `overflow:` argument) →
`nest_balanced_text.dart` `_text()`.

**What happens.** The K04-BUG-1 fix renders an over-cap title at full width,
but `_text()` defaults to `TextOverflow.clip`, so a title whose natural
layout needs more than 3 lines stops mid-word on the third line with **no
ellipsis** — the child cannot tell the text continues. The component's
full-width path comments “the Text's own maxLines ellipsis keeps it honest”,
but the default is clip; the design CSS (`.kid-title`) has no max-lines at
all and would show every line. Measured at 390×844: the title renders
`Size(350, 102)` (three lines), `maxLines == 3`, `overflow ==
TextOverflow.clip`. A 4-line title also renders at 320 px / 1.3× with no
overflow exception, same clip behaviour.

**Repro.**
1. In P09 create a quest with a long name, e.g. the proof's 150-char title
   (`A very long quest title that should wrap to three lines … and longer
   still until the title is far too long`), assign Maya.
2. Open its K04 detail. The title spans all three lines and is cut off
   without an ellipsis (the design would render the full title and scroll).

**Failing test.** `K04-BUG-4: an over-cap title must ellipsise, not clip`
(asserts `Text.overflow == TextOverflow.ellipsis`; actual `clip`).
Run: `flutter test --timeout 120s --run-skipped --plain-name K04-BUG-4
test/features/kid_home/k04_bugs_test.dart`

**Severity rationale.** Cosmetic and limited to titles longer than the
3-line cap; the title is visible and readable, only the truncation cue is
missing. Minor.

**Suggested fix (screen-local, allowed by RULES §1).** Pass
`overflow: TextOverflow.ellipsis` to the K04 `NestBalancedText` call (or
default the component to ellipsis whenever `maxLines != null`; that is a
shared change and belongs in a SHARED_REQUEST).

---

## Iteration-1 findings — fixed and verified

| bug | fix | proof (now live) |
|---|---|---|
| **K04-BUG-1** (Major) | Shared `NestBalancedText`: the width probe counts **natural** lines (`maxLines: null`); `build` returns the full-width `Text` when the natural count exceeds the cap. Recorded in `SHARED_REQUEST.md` for the orchestrator to merge deliberately. | `K04-BUG-1: balancedWidthFor …` (unit) + `K04-BUG-1: a long quest title measures ~0 px …` (widget) — both pass; the 59-char realistic title now measures a positive balanced width (was 0.085 px) |
| **K04-BUG-2** (Minor) | `_resolveQuest` returns `null` (→ “Pick a quest”) whenever an explicit `questId` in `extra` does not resolve for the playing child; q-tidy/first-item fallbacks only run on a true direct launch. | `K04-BUG-2: an extra naming another child must not show a different quest` — passes |
| **K04-BUG-3** (Major, mandated) | `_iconFor` mirrors P09's batch-5 key/alias table (`bed/sofa→questBed`, `dishwasher/plate→questDishes`, `hoover→questHoover`, `bin/bins/shirt/bag→questBins`, `book→book`, `paw/leaf→paw`, else `questCard`). | `K04-BUG-3: the hero tile uses the P09 design glyphs` (loops q-tidy/q-dishwasher/q-hoover/q-bins) — passes |

`K04-BUG-2`'s fix also corrected a live behaviour: deleting the shown quest
mid-view now falls to “Pick a quest” (green probe retained).

## Context — the hero glyph question (not filed here)

The iteration-2 UI check (`5_ui.md`) fails the screen on the shared
`ic_quest_bed.svg` asset: at the 64 px hero size it renders as a plain
arch/box, unlike the K04 design's richer bed, and unlike iteration 1's
`bedSit`. K04's code follows the 14:28 mandate exactly (verified key by
key), and `ORCHESTRATOR_NOTES.md` **15:08** says kid screens will switch to
the shared `questIconFor/rewardIconFor(audience: kid)` helpers “being added
on main … Not a finding meanwhile; switch once main has it”. As of this
stage that helper is **not yet in this worktree or on main** (grep: no
`questIconFor`), so no K04 change is possible yet. Not counted as a K04 bug
per the orchestrator note; the loop should pick the helper up after the
next main merge.

## Checked clean (iteration-2 additions, running un-skipped)

- **Over-cap title path** (new K04-BUG-1 code): a 150-char title renders at
  full content width with three lines reserved at 390 px and at 320 px /
  1.3× text; no overflow exception (the missing ellipsis is K04-BUG-4).
- **Delete the shown quest mid-view**: the stream emission flips the screen
  to the “Pick a quest” state with no exception (extra id no longer
  resolves).
- All iteration-1 clean probes still pass: Back double-tap pops one route;
  `Seed.empty` deep link offers the picker; completion survives a fresh app
  pump; 9999 coins at 320/1.3; dark bottom bar reaches the edge under a
  34 px inset; a 30 h-old daily completion is “to do” again; every K04
  token pair ≥ 4.5:1 in both themes.

## Not findings

- Completing and pressing Back in the same frame ends on `/quest-complete`
  with the row saved and no exception (celebration wins; acceptable).
- A staggered second tap during a slow write dispatches a second event, but
  `completeQuest`'s transaction is idempotent: one row, one celebration.
- Only `k04_bugs_test.dart` and this file were written; the screen was not
  modified. No simulator used; all proofs run in `flutter test`.

VERDICT: PASS
