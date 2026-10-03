# P09 — 2b build, UI chunk (FIXES_2 iteration, iteration 3)

Scope: `app/lib/features/quests/presentation/views/**`,
`…/presentation/widgets/**`, and the view/widget tests named `*view*` /
`*widget*` in `app/test/features/quests/`. Plus the mechanical test updates
my own code changes forced (listed under *Files*), plus
`p09_bugs_test.dart` (un-skipping, explicitly in this stage's brief). No
domain/data/bloc/cubit file, no `app/lib/core/**`, no `app/lib/app/**`, no
`tools/`. `flutter clean` never run; no simulator booted, installed on,
screenshotted or driven; no `analysis_options` change; no `skip:` left in the
P09 bug proofs; no `google_fonts`.

Re-read first: `2a_build_logic.md` (its only contract change is
`QuestsEditorQuery.ideaId`, already on disk — the logic builder wrote
`quests_routes.dart` while I worked; I did not touch it) and
`ORCHESTRATOR_NOTES.md` 19:19 (icons / toggle / stepper minus / field inset
are SHARED on `shared/shared_batch5`; fix only the P09-local items; do not
substitute icons).

## What I changed in the UI layer

| FIXES_2 item | Where | What |
|---|---|---|
| Review **1** (major) | `quest_editor_view.dart` `_questIcons` | Dishes tile reverted from the look-alike `NestIcons.basket` to `NestIcons.dishwasher`, and the justifying comment deleted. The previous stage's claim that "main redrew `ic_hoover.svg` / `ic_dishwasher.svg`" was false (review finding 1 disproved it by git + asset bytes); that claim is struck below and is not re-litigated. |
| Review **2** (major) | `quest_editor_view.dart`, `quest_library_body.dart`, `quest_editor_view_test.dart` | `?idea=<templateId>` is read next to `?id=` (`?id=` wins) and seeds a NEW draft from `QuestsRepository.ideas()` — title, icon, coins, repeatRule, needsApproval. The sheet grew an explicit `isEdit` flag, because a template seed is still a create: the title stays `New quest`, no `Delete quest`, a **fresh id** on save (never `idea-bed`), and `active: true` (templates carry `active: false`). Unknown idea ids fall back to the default template. The stale `TODO(P10)` in the library row is gone and names `QuestsEditorQuery.ideaId`. Three tests. |
| Review **3** (minor) | `quest_editor_view.dart` + 4 P10 test files | The `Tooltip(message: 'Back')` is DELETED (product code was serving `WidgetTester.pageBack()`), and all 8 `pageBack()` sites in `quest_library_view_test`, `quest_library_a11y_actions_test`, `quest_library_states_test`, `p10_bugs_test` became `tester.binding.handlePopRoute()` — the idiom `today_view_test` / `p08_bugs_test` already use. New P09 test pins the consequence: no `Back` tooltip, no `BackButton`, and `Cancel` is the way back (from a root-mounted editor it falls back to `/quests`). I took the review's *primary* fix, not its cheaper alternative, because `ORCHESTRATOR_NOTES` 19:19 lists "Cancel tooltip coupling" as a P09-local item. |
| Review **4** (minor, perf) | `_header` | `QuestSavePill` is wrapped in `ValueListenableBuilder<TextEditingValue>` over `_title`; the per-keystroke `setState(() {})` on the `NestTextField` is deleted. Typing a quest name no longer rebuilds the six tiles, three pills, two `LayoutBuilder`s, three cards, the segmented control and the seven day cells. |
| Review **5** (minor, perf/robustness) | `initState` | The roster subscription rebuilds only on a real change (`_rosterLoaded && listEquals(...)`; the first emission always applies so `_rosterLoaded` is still set for an empty roster), and **both** subscriptions now carry `onError: (_) {}` instead of turning a stream error into an unhandled async error. |
| Review **6** (minor, a11y) | `_dueCard` | `semanticLabel: 'Due by, $_dueLabel'`. `NestCard` sets `excludeSemantics: semanticLabel != null`, so the old bare label dropped the row's own text: VoiceOver heard "Change due time, button" and never the current choice. |
| Review **8** (docs) | `5_ui.md`, `SHARED_REQUEST.md`, this file | The "curly ’ in `Who's`" sentence corrected (the HTML prints U+0027 — hexdump in `5_ui.md`); the Dishes substitution paragraphs in `5_ui.md` / `SHARED_REQUEST.md` §4 rewritten to the reverted state; the false "main redrew the glyphs" claim struck here. |
| **BUG-P09-8** (major, `3_test.md` P09-TEST-2) | `_initial` | `nickname.substring(0, 1)` → `nickname.characters.first` (same accessor P06 uses at `pocket_money_setup_view.dart:684`). An emoji-leading nickname (`😀 Sam`, which P05 accepts) used to hand Flutter's paragraph builder a lone surrogate and fail the whole paint. |
| **BUG-P09-6** (minor) | `_canSave`, `_rewardCard` area | The mismatch is now impossible instead of silent: the value is still shown as stored (BUG-P09-4), the widened stepper bounds still make the repair reachable, but Save is **blocked** while `_coins` is outside 1..100 and a live-region caption `Coins must be 1–100` (the `Pick at least one day` pattern) says why. Two tests in `quest_editor_view_test.dart`. |
| **BUG-P09-7** (minor) | `_iconRow` | `isSelected` is computed first and an already-highlighted tile's tap is inert, so tapping Dishes for a `plate` quest no longer silently rewrites the stored key. Tapping a *different* tile still rewrites it (proven by `quest_editor_data_integrity_test.dart`). |
| Un-skipped proofs | `p09_bugs_test.dart` | BUG-P09-6 ×2, BUG-P09-7, BUG-P09-8 ×2 now run on every `flutter test` (was 5 skips). Their assertions were not touched — only the `skip: true` flags and the header's status paragraph. |

### Design frame untouched
No change moves anything in the design state: the caption is reachable only
from a corrupt stored value, the icon tiles/segments/cards keep their metrics,
and the pill swap is the same `QuestSavePill` widget inside a listenable.
`quest_editor_view_geometry_test.dart` (the ±2 px rects) is green unchanged.

### New copy
`Coins must be 1–100` is the only string this stage adds — screen-local
validation copy in the pattern of the sanctioned `Pick at least one day`
(`1–100` uses an en dash). The copy audit pumps the design frame only, where
the caption cannot appear, so `kOwnedCopy` is unaffected.

## Files

- `lib/features/quests/presentation/views/quest_editor_view.dart`
- `lib/features/quests/presentation/widgets/quest_library_body.dart` (comment)
- `test/features/quests/quest_editor_view_test.dart` (+6 tests)
- `test/features/quests/p09_bugs_test.dart` (un-skip only)
- Forced mechanical updates, because MY change altered a rendered string or a
  harness contract (no assertion weakened, none deleted):
  - `quest_editor_a11y_test.dart` — 3 references to the due-row label
    (`'Change due time'` → `'Due by, Before tea (5pm)'`), and the sheet's
    `pick()` helper now looks the row up by the value it is showing.
  - `quest_editor_data_integrity_test.dart` — the Dishes tile's expected
    glyph (`basket` → `dishwasher`) and its comment.
  - `quest_library_view_test.dart`, `quest_library_a11y_actions_test.dart`,
    `quest_library_states_test.dart`, `p10_bugs_test.dart` — 8 `pageBack()`
    → `handlePopRoute()` after the `Tooltip` deletion. Four of these files are
    outside this stage's `view`/`widget` name scope; the review asked for the
    conversion and left no alternative that keeps them green.
- Docs: `2b_build_ui.md` (this file), `5_ui.md`, `SHARED_REQUEST.md` §4.

Not mine, deliberately: `quests_routes.dart` (the logic builder added
`ideaId`), `quests_bloc.dart` (review finding 10's parent-safe toast copy —
the logic builder documents why it was not applied), `quest_editor_copy_test.dart`
(review finding 7: keep the `'-'` entry until the shared `NestStepper` flips to
U+2212, in the same commit), `nest_stepper.dart` / the icon and field-inset
assets (core/, `shared/shared_batch5`).

## Verification (UI layer only)

```
$ dart format --set-exit-if-changed lib/features/quests test/features/quests
Formatted 43 files (0 changed)
$ flutter analyze lib/features/quests test/features/quests
No issues found! (ran in 5.3s)
$ flutter test test/features/quests/
00:23 +378: All tests passed!          # 367 → 378: +5 un-skipped proofs, +6 new
$ flutter test test/features/today/    # P08 pushes /quest-editor?questId=
00:07 +110: All tests passed!
```

Whole-app `flutter test` and the simulator were NOT run (integrator / stage 5
own them). No simulator was booted.

## LEFT FOR NEXT ITERATION

1. **Icon glyphs / toggle offset / field inset (shared).** When
   `shared/shared_batch5` merges back, switch the picker to the names in
   `docs/screens/_shared/shared_batch5_REPORT.md` and delete
   `QuestEditorMetrics.toggleTrackOffset` (plus its `Transform`) and the
   approval card's comment. Until then the shared-baseline glyphs stay and
   stage 5 keeps reporting the tile-MAE blocker.
2. **Review finding 10** (Dart error string in a parent-facing toast) —
   bloc-layer, and the logic builder records that applying it turns green
   `quest_editor_states_test.dart` assertions red in the same commit.
3. **Step 5 (`±2 px`) re-check** after the batch5 merge: the icon tiles and
   the toggle track move, so the geometry test's toggle rect will need the
   numbers re-measured.
4. Nothing else outstanding in the UI layer; every P09-local item in
   FIXES_2 and `ORCHESTRATOR_NOTES` 19:19 is either done here or owned by a
   shared/core batch.

VERDICT: PASS