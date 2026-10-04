# K04 — Stage 2 build, integration (iteration 3)

Scope: make the combined 2a (logic) + 2b (UI) result compile, analyze clean and
pass the full suite. One small corrective edit was needed (a stale test name and
its failure reason, see FIXES-4); everything else merged without conflict.

Inputs: `2a_build_logic.md` (iter 3), `2b_build_ui.md` (iter 3 section),
`1_plan.md`, `FIXES_2.md`, `3_test.md`, `5_ui.md`, `6_bugs.md`,
`ORCHESTRATOR_NOTES.md` (14:28 + 15:08), `SHARED_REQUEST.md`, `RULES.md`.

Iteration 2 closed `test=FAIL ui=FAIL`: one open Minor bug (K04-BUG-4) parked
behind `skip: true`, and one open Major UI deviation (hero glyph) that `3_test.md`
explicitly refused to hand a green tick over.

## What landed

### From 2a (logic) — no files changed

Re-verified plan §b and FIXES_2: no new events, no repository/DI/route change, no
icon logic in `domain/`/`data/`/`bloc` to migrate. **No CONTRACT CHANGES**, so 2b
coded against a contract that landed intact — again no merge adaptation.

2a's FIXES_2 triage, all confirmed correct from my side:
- K04-BUG-4 is a one-argument fix at the view call site (UI-owned), or a shared
  default in `core/` (forbidden). Correctly triaged out of this layer.
- The hero glyph's root cause is the shared batch-5 asset. Correctly triaged out.
- The new ICONS rule needs nothing from this layer — icon mapping lives in views
  + shared core.

### From 2b (UI) — `quest_detail_view.dart` + `k04_bugs_test.dart`

- **K04-BUG-4 (Minor, fixed).** `NestBalancedText(quest.title, maxLines: 3)`
  passes `overflow: TextOverflow.ellipsis`, so an over-cap title cuts with an
  ellipsis instead of mid-word clip. The skipped proof is un-skipped and passes.
  This was the skip `3_test.md`'s FAIL verdict turned on — the suite is no
  longer green over a hidden failure.
- **ICONS ruling (`ORCHESTRATOR_NOTES` 15:08, now mandatory).** The iteration-2
  local mirror of P09's table is gone; `_iconFor` now delegates to the shared
  single source `questIconFor(raw, audience: NestAudience.kid)`, byte-identical
  in behaviour to K03's `_iconFor`. No `core/**` edit was needed — the shared
  helper and its kid assets landed on main before this iteration.

## FIXES — every item, done or left

### DONE

- **K04-BUG-1 (Major, iter 2) —** invisible over-cap title. Fixed in the shared
  `NestBalancedText`; both proofs live.
- **K04-BUG-2 (Minor, iter 2) —** mismatched `extra` swapped in a different
  quest. Fixed in `_resolveQuest`; proof live.
- **K04-BUG-3 (Major, mandated, iter 2) —** wrong hero glyph. Fixed, then
  re-pointed this iteration at the kid assets per the 15:08 ruling; proof live.
- **K04-BUG-4 (Minor, iter 3) —** over-cap title clipped instead of ellipsised.
  Fixed at the call site; proof un-skipped and live.
- **The hero Major from `5_ui.md` deviation 1 is resolved at code level.**
  `5_ui.md` reported `ic_quest_bed.svg` rendering as "a plain hollow rounded
  rectangle with no bed cues — unrecognizable as a bed". `questIconFor('bed',
  audience: kid)` returns `NestIcons.questBedKid`, and I verified
  `assets/icons/ic_quest_bed_kid.svg` path data against the K04 HTML:
  - HTML `.k4-tile` (`K04-quest-detail.html:40`): `M2 18v-7` / `M2 14h20v4` /
    `M22 18v-4a3 3 0 0 0-3-3h-9v3` / `M6 11V8h4v3`
  - asset: **identical**, all four paths.
  So the hero is now the design's own drawing, with the headboard post, pillow
  bump, base and legs `5_ui.md` asked for. **Needs a stage-5 re-shot to confirm
  the FAIL clears** — I cannot verify pixels from here (stage 2 must not boot a
  simulator).
- **K04 has zero skipped tests.** All five proofs (BUG-1 unit + widget, BUG-2,
  BUG-3, BUG-4) run in the default suite: `k04_bugs_test.dart` → 14/14 passing,
  no `~`. The 4 repo-wide skips are K01 ×1, K03 ×2, P12 ×1 — other screens.
- **Format.** `dart format .` → 579 files, **0 changed**.

### FIXES-4 (mine, this stage)

- **K04-BUG-3's proof still named the P09 glyphs it no longer asserts.** After
  iteration 3 re-pointed the expected assets to `questBedKid` /
  `questDishesKid`, the test name, its section comment and its `reason:` string
  all still said "P09 design glyphs" / "must use the batch-5 P09 design glyph".
  The assertions are correct but the documentation contradicts them, which is a
  trap for the next agent: someone reading "must use the P09 glyph" would
  reasonably revert `questBedKid` back to `questBed` and re-break the hero.
  Renamed the test to `K04-BUG-3: the hero tile uses the kid design glyphs`,
  rewrote the section comment to cite 14:28 superseded-by-15:08, and corrected
  the `reason:` string to name both rejected sets (pre-batch-5 parent **and**
  P09-only) and the 64 px arch symptom. **No assertion touched.**

### LEFT — outstanding, needs the orchestrator

- **`SHARED_REQUEST.md` is still unresolved.** `git diff main` confirms
  `nest_balanced_text.dart` still differs from `main` by 22 insertions: the
  K04-BUG-1 fix is committed on this branch but **not yet upstreamed**. This is
  the same item I flagged in iteration 2. Two parts are still shared work:
  the component fix itself, and — per `6_bugs.md` — the permanent regression
  test belonging **next to the component** rather than in a screen test file.
- **Stage-5 re-shot** of `/quest-detail` in light + dark to confirm the hero
  Major clears and no new drift appears.

### LEFT — accepted deviation, unchanged

- **Steps render unticked on arrival** while the design PNG shows two ticked.
  `1_plan.md` §d approved this (v1 keeps no per-quest step storage); `5_ui.md`
  deviation 2 ACCEPTed it. Only the dot fill differs.
- **Bottom edge** — the dark design PNG shows a meadow strip under the bar; the
  app does not. Owner rule overrides the designs; `5_ui.md` deviation 4 ACCEPTed
  it and the matrix test pins `bottom == 844` structurally (bar is the body
  `Column`'s last child).
- **Pip art** — `PipAvatar` from Maya's DB row instead of the v1
  `pip-stage-3.svg`; PIP rule override, ACCEPTed as deviation 3.
- **The cheer Pip + speech bubble merge into one semantics node**
  (`"Pip cheering you on\nPip is doing a happy dance!"`). Both strings are the
  HTML's verbatim copy and the announcement is correct. Splitting them needs a
  shared-component change.

### NOT FINDINGS (per orchestrator rule)

- Uncommitted work, branch position, merge order — loop/orchestrator state. Note
  main *was* merged before this build (`aaf3c32`), which is why the suite moved
  3626 → 3707; every new test passes, so K04 and merged main agree.
- `3_test.md`'s "no `SHARED_REQUEST.md` needed" line is now stale — one exists
  and is live; recorded above.

## Orchestrator-rule audit (re-verified on the merged tree)

| rule | result |
|---|---|
| **ICONS (new, this iteration)** | K04 `_iconFor` → `questIconFor(raw, audience: NestAudience.kid)`, identical to K03. No local icon table remains. Remaining `NestIcons.*` uses are UI chrome (back chevron, check glyph in the done ring and the primary button), not quest/reward glyphs; the coin pill owns its own glyph, so `rewardIconFor` is correctly not used here. |
| no `google_fonts` / `GoogleFonts.*` | clean |
| no `DateTime.now()` in feature | clean |
| no `subscription_status` write | clean |
| no hard-coded `Color(0x…)` | clean — tokens only |
| PIP rule | `PipAvatar` from the child's DB row; no `pip_stage_*.svg` |
| BALANCED HEADINGS | title is `NestBalancedText`, `maxLines: 3`, now with `overflow: ellipsis` |
| bottom edge / alignment | in-flow bar over `SafeArea(top:false)`; matrix test pins gutters at 320/390/430 in both themes |
| accessibility | every control exposes `SemanticsAction.tap`; step rows pass `onTap:` on the wrapper because they also `excludeSemantics` |
| copy | unchanged this iteration; char-by-char vs HTML verified in iteration 1 |
| RULES §1 scope | `kid_home/presentation/**`, `kid_home` tests, `docs/screens/K04/**`. No `core/**` edit this iteration. |
| `analysis_options.yaml` | untouched, no ignores |
| simulators | none booted |

## Tails

```
$ dart format .
Formatted 579 files (0 changed) in 1.88 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.0s)

$ flutter test --timeout 120s
01:29 +3707 ~4: All tests passed!

$ flutter test --timeout 120s test/features/kid_home
00:13 +545 ~3: All tests passed!

$ flutter test --timeout 120s test/features/kid_home/k04_bugs_test.dart
00:01 +14: All tests passed!        # 0 skips — all five bug proofs live
```

The 4 whole-suite skips are K01/K03/P12 parked proofs (other screens). The Drift
"AppDatabase multiple times" warning is pre-existing harness noise. Full-suite
wall clock 1 min 29 s.

## Verdict

`dart format` changed nothing, `flutter analyze` printed **No issues found!**
with no ignores, and the **full 3707-test suite passed**. All five K04 bug proofs
now run un-skipped, so the green suite no longer hides a failure — which was
the specific reason `3_test.md` returned FAIL last iteration. The one edit I made
was a stale-name correction in a passing test; no assertion changed.

Two items remain open for the orchestrator: the `SHARED_REQUEST.md` upstream of
the `NestBalancedText` fix (plus its component-level regression test), and a
stage-5 re-shot to confirm the hero-glyph Major clears in pixels.

VERDICT: PASS
