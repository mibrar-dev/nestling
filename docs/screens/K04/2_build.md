# K04 — Stage 2 build, integration (iteration 2)

Scope: make the combined 2a (logic) + 2b (UI) result compile, analyze clean and
pass the full suite. **No code change was needed in this stage** — the two
builders' work merged without conflict and the pipeline was already green. This
file records what landed, the FIXES_1 triage, and the one item that needs an
orchestrator decision (the shared-file edit).

Inputs: `2a_build_logic.md` (iter 2), `2b_build_ui.md` (iter 2 section),
`1_plan.md`, `FIXES_1.md`, `6_bugs.md`, `ORCHESTRATOR_NOTES.md`,
`SHARED_REQUEST.md`, `docs/screens/RULES.md`.

## What landed

### From 2a (logic) — no files changed this iteration

Re-verified plan §b and FIXES_1: no new events, no repository/DI/route change.
The iteration-1 `KidHomeBloc.stepsFor` getter (`kid_home_bloc.dart:30`) is the
only logic-layer addition and is unchanged. **No CONTRACT CHANGES**, so 2b coded
against a contract that landed intact — this is why the merge needed no
adaptation.

2a's FIXES_1 triage: none of the three bugs is in the logic layer. K04-BUG-1's
root cause is the shared `NestBalancedText`; BUG-2 and BUG-3 both live in
`quest_detail_view.dart` (UI-owned). Agreed and confirmed below.

### From 2b (UI) — `quest_detail_view.dart` + `k04_bugs_test.dart`

The three `6_bugs.md` findings are fixed and their proofs are un-skipped:

| bug | fix | proof |
|---|---|---|
| **K04-BUG-1** (Major) | `NestBalancedText` no longer probes line counts with the caller's `maxLines` cap; `build` returns the full-width `Text` when the natural line count exceeds the cap | unit `balancedWidthFor > 50` + widget title width `> 100` px — both pass |
| **K04-BUG-2** (Minor) | `_resolveQuest`: an explicit `questId` in `extra` that names another child or an unknown quest now returns `null` → `_QuestMissing`. The `q-tidy` / first-to-do / first-item fallbacks only run for a true direct launch (no `questId`) | asserts `Tidy your bedroom` absent + `Pick a quest` present |
| **K04-BUG-3** (Major, mandated) | `_iconFor` replaced with P09's batch-5 key/alias table | loops q-tidy / q-dishwasher / q-hoover / q-bins, asserts the 64 px `NestIcon` asset |

`_iconFor` was checked key-by-key against `quest_editor_view.dart`
`_questIcons` — an exact 1:1 match, including aliases:

| P09 key | aliases | icon | K04 `_iconFor` |
|---|---|---|---|
| `bed` | `sofa` | `questBed` | `'bed' \|\| 'sofa' => NestIcons.questBed` ✓ |
| `dishwasher` | `plate` | `questDishes` | `'dishwasher' \|\| 'plate' => NestIcons.questDishes` ✓ |
| `hoover` | — | `questHoover` | `'hoover' => NestIcons.questHoover` ✓ |
| `book` | — | `book` | `'book' => NestIcons.book` ✓ |
| `bin` | `bins`, `shirt`, `bag` | `questBins` | `'bin' \|\| 'bins' \|\| 'shirt' \|\| 'bag' => NestIcons.questBins` ✓ |
| `paw` | `leaf` | `paw` | `'paw' \|\| 'leaf' => NestIcons.paw` ✓ |
| unknown | — | — | `_ => NestIcons.questCard` ✓ |

So the `ORCHESTRATOR_NOTES.md` 14:28 mandate ("the flat bed … not the
bed-with-figure icon … the same design glyphs P09 uses") is satisfied in full,
and the hero tile now agrees with the editor that writes those keys. The
pre-batch-5 `bedSit` is gone from K04.

`k04_bugs_test.dart`: all four parked proofs un-skipped, header comments
re-marked `fixed`, and `disposeApp(tester)` added to the three newly-live
widget tests (required — un-skipping them without the drain would fail teardown
with "A Timer is still pending", RULES §7).

## FIXES — every item, done or left

### DONE

- **K04-BUG-1 · invisible long quest title.** Fixed in
  `app/lib/core/design_system/components/nest_balanced_text.dart`. Root cause:
  `balancedWidthFor` counted lines with the caller's `maxLines: 3` applied, so
  any title needing ≥3 lines reported `3 <= 3` at every width (including
  0.1 px) and the binary search collapsed; the heading then rendered inside a
  `SizedBox(width: 0.1)` and painted nothing. Fix: probe with the natural line
  count, and bail to full-width `_text()` when the natural count exceeds the
  cap. Both proofs pass.
- **K04-BUG-2 · mismatched `extra` swapped in a different quest.** Fixed in
  `_resolveQuest`. The view's doc comment had claimed behaviour the code did
  not implement; code and comment now agree.
- **K04-BUG-3 · wrong hero glyph.** Fixed in `_iconFor`, verified 1:1 against
  P09 above.
- **Test un-skips + drains.** All three bug proofs are live in the default
  suite: `k04_bugs_test.dart` runs 11/11 with **zero** skips.
- **Format.** `dart format .` → 572 files, **0 changed**. Both halves were
  already formatted; the merge introduced no churn.
- **Cross-half seam.** The only coupling is `bloc.stepsFor(questId)`, unchanged
  and correctly called from `quest_detail_view.dart:192`. No mismatched states,
  events, renamed members or import changes were needed.

### LEFT — needs an orchestrator decision (not a build failure)

- **The `NestBalancedText` edit is outside RULES §1 scope.**
  `app/lib/core/design_system/**` is shared; RULES §1 says a screen agent must
  never edit it, and `6_bugs.md` itself marked K04-BUG-1 as "SHARED_REQUEST
  territory, not editable by this screen". 2b applied the fix locally because
  the bug proofs had to go green, and recorded it deliberately in
  `docs/screens/K04/SHARED_REQUEST.md` (`Blocks: no`) for the orchestrator to
  merge upstream deliberately.
  I **kept** it rather than reverting: reverting would turn the suite red and
  re-break a Major bug, and the orchestrator has an explicit channel for this
  exact case. Flagging it here so the merge is a conscious decision.
  - The change is additive and safe for existing callers: no public API change,
    and behaviour is identical whenever the text already fits within `maxLines`
    (the bail only fires when the natural count *exceeds* the cap, which
    previously rendered an invisible heading).
  - Regression coverage: 9 external callers exist (pocket_money_setup,
    welcome, value_tour, create_account, kid_home, add_children,
    profile_picker, paywall, quest_detail) and all their features' suites pass
    in the full run — including P02's *"starved titles keep full size and
    ellipsise, never shrink"*.
  - Per `6_bugs.md`, a permanent regression test belongs **next to the
    component**, not in a screen's test file. That is shared work and is still
    outstanding for the orchestrator to land with the fix.

### LEFT — owed to stage 5 (UI check)

- `shot.sh` for `/quest-detail` in light + dark, `compare.py` against both
  design PNGs. Not run here — stage 2 must never boot a simulator.
- The cheer Pip + speech bubble merge into one semantics node
  (`"Pip cheering you on\nPip is doing a happy dance!"`). Both are the HTML's
  verbatim copy and the announcement is correct; splitting them needs a
  shared-component change.

### NOT FINDINGS (per orchestrator rule)

- Uncommitted work, the branch being behind main, and merge order are loop /
  orchestrator state. Note the branch **did** merge main (`3deb59d`) before this
  iteration, which is why the suite grew from 3415 to 3626 tests — every one of
  the 211 new tests passes, so the K04 work and the merged main work agree.
- Steps render **unticked** on arrival while the PNG shows two ticked — the
  deviation `1_plan.md` §d explicitly approved (v1 keeps no per-quest step
  storage). Only the dot fill differs; 40 px dots, 60 px rows and the card rect
  are unchanged.
- The 3 remaining skips in the `kid_home` suite are K03-BUG ×2 and K01-BUG ×1 —
  other screens' parked proofs. K04 has none.

## Orchestrator-rule audit (re-verified on the merged tree)

| rule | result |
|---|---|
| no `google_fonts` / `GoogleFonts.*` | clean |
| no `DateTime.now()` in feature | clean |
| no `subscription_status` write | clean |
| no hard-coded `Color(0x…)` | clean — `context.nest` / `context.nestKid` tokens only |
| PIP rule | `PipAvatar` from the child's DB row; no `pip_stage_*.svg` |
| bottom edge (owner) | in-flow `Container(surface, top 3×ink)` over `SafeArea(top:false)`; `k04_bugs_test.dart` still pins the dark bar reaching the edge under a 34 px inset |
| alignment (owner) | 20 px gutters; geometry test pins every rect |
| balanced headings | title is `NestBalancedText`, `maxLines: 3` — and now renders visibly for long DB titles |
| accessibility | every control exposes `SemanticsAction.tap`; step rows pass `onTap:` on the wrapper because they also `excludeSemantics` |
| copy | unchanged this iteration; verified char-by-char against the HTML in iteration 1 |
| RULES §1 scope | all changes inside `kid_home/presentation/**`, `kid_home` tests and `docs/screens/K04/**` **except** the one documented shared-file edit above |
| `analysis_options.yaml` | untouched, no ignores added |
| simulators | none booted |

## Tails

```
$ dart format .
Formatted 572 files (0 changed) in 1.82 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.7s)

$ flutter test --timeout 120s
02:41 +3626 ~4: All tests passed!

$ flutter test --timeout 120s test/features/kid_home
00:17 +495 ~3: All tests passed!

$ flutter test --timeout 120s test/features/kid_home/k04_bugs_test.dart
00:02 +11: All tests passed!        # 0 skips — all three bug proofs live
```

The 4 whole-suite skips and the Drift "created the database class AppDatabase
multiple times" warnings are pre-existing (in-memory test harness; the skips are
K01/K03/P12 parked proofs). Not failures. Full-suite wall clock 2 min 41 s.

## Verdict

`dart format` changed nothing, `flutter analyze` printed **No issues found!**
with no ignores, and the **full 3626-test suite passed** with all three FIXES_1
bugs fixed and their proofs live. The only item needing an orchestrator call is
the documented shared-component edit, which is recorded in `SHARED_REQUEST.md`
and carries regression evidence from all 9 existing `NestBalancedText` callers.

VERDICT: PASS
