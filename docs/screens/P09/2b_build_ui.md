# P09 — 2b build, UI chunk (FIXES_3 iteration, iteration 4)

Scope: `app/lib/features/quests/presentation/views/**`,
`…/presentation/widgets/**`, and the view/widget tests named `*view*` /
`*widget*` in `app/test/features/quests/`. Plus the mechanical test updates
my own code changes forced (listed under *Files*), plus `p09_bugs_test.dart`
(un-skipping, explicitly in this stage's brief). No domain/data/bloc/cubit
file, no `app/lib/core/**`, no `app/lib/app/**`, no `tools/`. `flutter clean`
never run; no simulator booted, installed on, screenshotted or driven; no
`analysis_options` change; no `skip:` left in the P09 bug proofs; no
`google_fonts`.

Re-read first: `2a_build_logic.md` (its only behavioural change is the
`QuestsBloc.saveFailedMessage` parent-safe copy — a bloc-side edit, nothing
for the view; the states suite's assertions are unchanged by it) and
`ORCHESTRATOR_NOTES` 20:09 (switch picker to the `quest*` icons, delete
`toggleTrackOffset` — both done below).

## What I changed in the UI layer

| FIXES_3 item | Where | What |
|---|---|---|
| BUG-P09-9 (major) + review finding 2 | `quest_editor_view.dart` `_approvalCard`, `quest_editor_widgets.dart` | The two stale batch-5 compensations are deleted: the approval card's bottom padding returns to `NestSpacing.s4` (16) and the `Transform.translate(toggleTrackOffset)` is gone (the metrics constant itself is deleted). The card renders 72 again and the 51×31 track lands at the design rect 303/620.5/51/31 (hard-verified with the PNG's own centre scanline). |
| BUG-P09-10 (minor) | `_approvalCard` | The toggle is no longer a child of the 40-high approval Row. The card's padding is applied in a `Stack` (edgeInsets.zero on the card), and the `NestToggle` is a `Positioned(top: 20.5, right: s4)` sibling of the padded `Row`. Now every ancestor render box around it is at least as tall as its 59×44 hit slop (the Stack spans the full 350×72 card), so taps 5 px above / 5 px below the track and 2 px right of it hit it (the failing tap coordinates the proof pins). |
| BUG-P09-11 (minor) | `NestStepper` in `_rewardCard` | The first step in the direction of the valid band jumps to the boundary: `−` when `_coins > _maxCoins` sets `_coins = _maxCoins`; `+` when `_coins < _minCoins` sets `_minCoins`. In-range values decrement by one as before. The stored value is still shown as stored (BUG-P09-4), and Save stays blocked (BUG-P09-6) until a repair step lands it in 1..100. |
| BUG-P09-12 (major) + review finding 3 | `_questIcons` | The four legacy glyphs are switched to the design paths `NestIcons.questBed / questDishes / questHoover / questBins` (design order unchanged; `book`/`paw` byte-identical, unchanged). Stored `quests.icon` keys are untouched — artwork-only swap. The six tiles now run on the exact P09 paths. |
| Review finding 1 (blocker) | 4 test files | `quest_editor_copy_test.dart` / `quest_editor_a11y_test.dart` / `quest_editor_view_test.dart` / `quest_editor_robustness_test.dart` fixes from iteration 3's test stage stood (`kGlyphs` `−` U+2212, node-by-label, drop toggle box ≥44 sweep, pin 51×31) and still pass. This stage's additional forced updates: the toggle-position pins in `quest_editor_view_geometry_test.dart` (track-rect assertions replace the 59×44 box assertions), `quest_editor_data_integrity_test.dart` (expected glyph list matches the batch-5 names), `p09_bugs_test.dart` (the old BUG-P09-4 artefact test is rewritten around the jump brace; BUG-P09-9..12 unskipped), and `quest_editor_view_test.dart` (the approval card now measures 72; the toggle rect is asserted at 303/620.5/51/31; the out-of-range reward assertions expect the jump to 100). |
| Iteration-3 | `p09_bugs_test.dart`, three test-file fixes | Un-skip BUG-P09-9 ×2, BUG-P09-10 ×3, BUG-P09-11, BUG-P09-12 — the seven proofs now run green against the fixed tree. Their assertions were not weakened; only BUG-P09-4's stale stepper test was rewritten around the jump brace the BUG-P09-11 repair requires. |

### Contract note
`QuestEditorMetrics.approvalTrackTopInCard = 20.5` documents the card-local
offset of the toggle track (card content starts at 616; the track is centred
in the 40-high row ⇒ 620.5). No token edits; no core files touched.

## Files

- `lib/features/quests/presentation/views/quest_editor_view.dart`
  (`_approvalCard` restructure, stepper jump-to-boundary, `quest*` icon list)
- `lib/features/quests/presentation/widgets/quest_editor_widgets.dart`
  (`toggleTrackOffset` deleted; `approvalTrackTopInCard` added)
- Forced mechanical test updates (no assertion weakened, none deleted):
  `quest_editor_view_geometry_test.dart`, `quest_editor_view_test.dart`,
  `quest_editor_data_integrity_test.dart`,
  `quest_editor_coin_rules_test.dart` (the one stepper test for a 9999 row
  now pins the boundary-jump), `p09_bugs_test.dart`.

Not mine, deliberately: `quests_bloc.dart` / review finding 4 (logic builder —
already landed with `saveFailedMessage`), `quests_repository.dart`'s
`ArgumentError`→`AssertionError` doc line (finding 8 — the logic builder had
already patched it), `DESIGN_SPEC.md`'s 48 px stale number (finding 7 —
shared `docs/`, for the orchestrator), GetIt-degradation (finding 9 —
optional, left).

## Verification (UI layer only)

```
$ dart format --set-exit-if-changed lib/features/quests test/features/quests
Formatted 43 files (2 changed) in 0.24 seconds.
$ flutter analyze lib/features/quests test/features/quests
No issues found! (ran in 6.6s)
$ flutter test test/features/quests/
00:22 +394: All tests passed!          # 394, includes unskipped BUG-P09-9..12
```

Whole-app `flutter test` and the simulator were NOT run (integrator / stage 5
own them). No simulator was booted.

## LEFT FOR NEXT ITERATION

1. **Review finding 9** (`GetIt.instance` with no graceful degradation) —
   optional, cheap, not done; the sibling P10 screen's BUG-P10-8 pattern is
   the precedent.
2. **Review finding 7** (`DESIGN_SPEC.md:168` says 48 px tiles; the design is
   44) — shared `docs/`, needs the orchestrator.
3. **Spatial focus order** from the wrapped toggle: the toggle moved from a
   row child to a Stack sibling, but its semantic index in the card is the
   same (it follows the "Needs my approval" text column in the tree), so
   focus order is preserved.

VERDICT: PASS
