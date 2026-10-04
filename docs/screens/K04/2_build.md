# K04 — Stage 2 build, integration (iteration 1)

Scope: make the combined 2a (logic) + 2b (UI) result compile, analyze clean and
pass the full suite. Nothing was redesigned; the only edits in this stage were
repointing K03 test anchors onto real K04 content (see FIXES-1), which 2b had
already prepared and which the merge made necessary.

Inputs: `docs/screens/K04/2a_build_logic.md`, `docs/screens/K04/2b_build_ui.md`,
`docs/screens/K04/1_plan.md`, `docs/screens/RULES.md`, orchestrator rules.
`docs/screens/K04/ORCHESTRATOR_NOTES.md` does not exist — no extra mandates.

## What landed

### From 2a (logic) — `presentation/bloc/kid_home_bloc.dart`

Exactly one addition, as planned in 1_plan §b:

```dart
List<String> stepsFor(String questId) => _repository.stepsFor(questId);
```

A pure delegate to `KidHomeRepository.stepsFor`. No new event, no state change,
no repository change, no DI/route change. It exists because views may not touch
GetIt directly and the bloc owns the only repository reference. Public event and
state shapes are untouched, so the 78 existing bloc/repository unit tests pass
unmodified.

### From 2b (UI) — `presentation/views/quest_detail_view.dart`

The `Scaffold(appBar: AppBar('K04 Quest detail'))` placeholder is replaced by
the design's screen. Structure: `KidScope` (shared sky + 136 px meadow only, no
local hills) > `Scaffold(transparent)` > `Column`:

| region | widget |
|---|---|
| status bar | `NestStatusBar` (height only; OS draws glyphs) |
| `.k4-top` | `NestIconButton` (56, back, 26 px icon, transparent) + `Spacer` + `_GateLockButton` → `NestLockButton` large, `'Grown-ups'` |
| `.scroll` | `ListView(20, 0, 20, 32)`: 120×120 tile (r24, `peachTint`, 3×`ink`, `kidShadow`, 64 px glyph) → 4 px → `NestBalancedText` title (maxLines 3, centred) → 16 → `NestCoinPill('+15', large, 'Plus 15 coins')` → 16 → `.kcap` hint → 16 → `_StepsCard` → 22 → cheer row (`PipAvatar` 64 + `NestSpeechBubble`) |
| `.kid-bar` | `Container(surface, top 3×ink)` > `SafeArea(top:false)` > `Padding(20,12,20,4)` > `Column(spacing:4)` > `NestKidButton('I did it!', leaf, check 26)` + `NestKidButton('Back', white)` > `NestHomeIndicator` |

Non-loaded states keep the same chrome so nothing jumps: `_KidLoading`
(`'Loading quest'`), `_KidFailure` (`'Oh no! Pip got lost.'` / `"Let's try
again."` / `'Try again'`), `_NoActiveChild` (`"Who's playing?"` / `'Choose'`),
`_QuestMissing` (`NestEmptyState` `'Pick a quest'` / `'Choose a quest to see its
steps.'` / `'Back home'`).

Quest resolution follows 1_plan §b: route `extra` `{'questId','childId'}` →
design quest `q-tidy` (direct-launch fallback for `shot.sh`) → first
`to_do`/`not_yet` → first item. An `extra` id that no longer resolves goes to
`_QuestMissing`; it never silently shows a different quest.

Tests added: `quest_detail_view_test.dart` (19 cases) and
`quest_detail_geometry_test.dart` (3 cases), 19 + 3 `disposeApp(tester)` calls
matching the 19 + 3 cases, no missing drains.

## FIXES — every item, done or left

### DONE

- **FIXES-1 · cross-screen test anchors (6 sites, 2 files).** 2b had already
  repointed these in its worktree; the merge kept them and they are the only
  reason the suite needed touching at all. `kid_home_view_test.dart` (4 sites
  via the new `_k04DetailAnchor()` helper) and `k03_bugs_test.dart` (2 sites):
  `find.text('K04 Quest detail')` → `find.text('Tick each bit off, then press
  the big button.')`, the detail screen's own copy. The old anchor was the
  placeholder AppBar title, which no longer exists.
  - `kid_home_view_test.dart:1855` and `:2095` still resolve
    `GoRouter.of(tester.element(_k04DetailAnchor())).state` and assert
    `/quest-detail` + the pushed `extra` — unchanged strength.
  - `k03_bugs_test.dart` K03-BUG-6 dropped `tester.pageBack()` (it needs an
    AppBar back button; K04 has none by design) for
    `tester.tap(find.byType(NestIconButton))` — K04's own Back. This is
    **stronger** than before: it now additionally asserts
    `findsNothing` on the detail copy after the back press, which is what
    actually proves "a double tap must not stack a second detail route" — a
    stacked route would render the hint twice.
  - No K03 behaviour assertion was weakened. `extra['questId'] == 'q-reading'`
    and the pending-approval-unchanged assertion at `:1918` are intact.
- **Cross-half contract seam.** The only coupling between 2a and 2b is
  `bloc.stepsFor(questId)`. 2a shipped it with the exact signature 2b coded
  against, so no rename, import or signature adaptation was needed — the two
  halves joined without conflict. `quest_detail_view.dart:192` calls it through
  `context.read<KidHomeBloc>()`; `dart:async` and `flutter_bloc` imports are
  present and `PipMood` is hidden from the barrel import (v1/v2 collision),
  exactly as the file header documents.
- **No Mismatched BLoC states/events.** The view consumes only existing
  `KidHomeStatus`, `justCompletedQuestId`, `justCompletedCoins`, `actionError`,
  `actionNonce` and dispatches only `KidHomeLoadRequested` and
  `KidHomeQuestCompleted`. Nothing had to be renamed.
- **Format.** `dart format .` → 551 files, **0 changed** — both halves were
  already formatted, so the merge introduced no reformatting churn.

### LEFT (owed to the UI-check stage 5, not this stage)

- `shot.sh` for `/quest-detail` in light + dark and `compare.py` against both
  design PNGs. Not run here — stage 2 must never boot a simulator.
- The cheer Pip + speech bubble currently merge into one semantics node
  reading `"Pip cheering you on\nPip is doing a happy dance!"`. Both strings are
  the HTML's verbatim copy (`alt` on the img, text on `.speech`) and the merged
  announcement is correct. Splitting them needs a `MergeSemantics`-free boundary
  — a shared-component change, out of scope for a screen agent. Flagged for the
  reviewer, not fixed here.
- Dark mode needs the device capture to confirm the meadow/sky colours behind
  the bar; the tokens and layout are theme-agnostic.

### NOT FINDINGS (per orchestrator rule)

- The untracked `docs/screens/K04/.start_build*` / `.brief_build*.md` files, the
  branch being behind main and merge order are loop/orchestrator state.
- Steps render **unticked** on arrival while the design PNG shows two ticked.
  This is the deviation 1_plan §d explicitly approved ("Do NOT pre-tick to match
  the mock") and the reason is documented in code: v1 has no per-quest step
  storage. Only the dot fill differs — 40 px dots, 60 px rows and the card rect
  are identical, so geometry is unaffected.

## Orchestrator-rule audit (grep-verified on the merged tree)

| rule | result |
|---|---|
| no `google_fonts` / `GoogleFonts.*` in `kid_home` lib or tests | clean (2 hits are assertion/comment strings in `kid_pin_view_test.dart`, `k03_bugs_test.dart`) |
| no `DateTime.now()` in feature | clean |
| no `subscription_status` write | clean |
| no hard-coded `Color(0x…)` in the view | clean — `context.nest` / `context.nestKid` tokens only |
| no `pip_stage_*.svg` (PIP rule) | clean — `PipAvatar` fed from the child row via `pipStyleOf`/`pipSkinOf`/`pipAccessoryOf`; the one `pip_stage_` hit is a comment saying it is *not* used |
| no `name[0]` / clock-derived ids | clean — no `newId` needed on this screen |
| shared kid background | `KidScope` only, default 390×136 meadow; no local hills |
| bottom edge (owner) | bar is in-flow `Container(surface, top 3×ink)` wrapping `SafeArea(top:false)`, so the surface box reaches the physical edge; geometry test pins `bar.bottom == 844` |
| balanced headings | title is `NestBalancedText` (`.kid-title` is a balance class) |
| chip rows | n/a — no `NestChip` rows on this screen |
| letter spacing | n/a — the design sets no tracking on K04 |
| copy parity | verified character-by-character against `design/html-source/screens/K04-quest-detail.html`: `Tick each bit off, then press the big button.`, `I did it!`, `Back`, `Grown-ups`, `Pip cheering you on`, `Pip is doing a happy dance!`, and the three step strings all appear verbatim; `.kcap` (15/20 w700 ink-2) → `NestType.kidCaption`, `.k4-step-t` (18/24 w800 ink) → `NestType.h3`, `+15` → DB coins |
| accessibility | every control exposes `SemanticsAction.tap`; the step rows pass `onTap:` on the `Semantics` wrapper because they also `excludeSemantics` (the wrapper would otherwise drop the action) |
| scope (RULES §1) | only `app/lib/features/kid_home/presentation/**`, `app/test/features/kid_home/**`, `docs/screens/K04/**` — `git status --porcelain -uall` lists nothing else; `analysis_options.yaml` untouched (no ignores added) |
| no simulator | stage 2 booted nothing |

## Tails

```
$ dart format .
Formatted 551 files (0 changed) in 1.73 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.0s)

$ flutter test --timeout 120s
01:10 +3415 ~4: All tests passed!

$ flutter test --timeout 120s test/features/kid_home
00:11 +484 ~3: All tests passed!
```

The 4 skips and the Drift "created the database class AppDatabase multiple
times" warnings are pre-existing on this branch (in-memory test harness) and are
not failures. Wall clock 70 s for 3415 tests.

## Verdict

`dart format` changed nothing, `flutter analyze` printed **No issues found!**
with no ignores, and the **full 3415-test suite passed**. The two halves
integrated with exactly one FIXES item (cross-screen test anchors), which
strictly strengthened a K03 assertion. No redesign, no shared file touched.

VERDICT: PASS
