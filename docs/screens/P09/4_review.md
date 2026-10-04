# P09 — stage 4 · QA code review (iteration 5)

Scope reviewed: `git diff main...HEAD` on branch `screen/P09` against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P09
(line 168), `docs/design/SPACING_SPEC.md`, the design system in
`app/lib/core/design_system/`, the HTML source
`design/html-source/screens/P09-quest-editor.html`, both design PNGs, and the
mandatory item in `docs/screens/P09/ORCHESTRATOR_NOTES.md` (00:25, iteration 5).

`git merge-base main HEAD` = `9e9d617` = `main`; `git rev-list --count
HEAD..main` = `0`, so the branch is not behind `main`. `HEAD` was `5f7def6`
("P09: checkpoint after build (iteration 5)") for the whole review.

No code was edited. Only this file was written. No simulator was booted,
installed on, screenshotted or driven; `flutter clean` was never run.

Because a sibling stage is writing in this worktree (the uncommitted
`.brief_*.md` files in `git status`), every gate was run against an isolated
`git archive HEAD` export (`/…/opencode/p09-i5`).

```
$ cd …/opencode/p09-i5/app && flutter analyze
No issues found! (ran in 10.2s)

$ dart format --set-exit-if-changed --output=none .
Formatted 534 files (0 changed) in 2.69 seconds.      (exit 0)

$ flutter test test/features/quests/
00:18 +403: All tests passed!          # 0 skipped — iteration 4's one parked
                                       # proof (BUG-P09-13) is now un-skipped
$ flutter test
01:45 +3092 ~2: All tests passed!
```

The whole tree is green for the first time: the `test/core/family_time_test.dart`
failure that ORCHESTRATOR_NOTES 23:55 flagged as pre-existing on `main` is fixed
and merged. The 2 skips are other features' (`kid_home/k01_bugs_test.dart:566`,
`pocket_money/p12_bugs_test.dart:321`); `grep skip: test/features/quests/`
returns one comment line and no active skip.

## Verdict summary

**The single mandated item is fixed and proven with an assertion that would
have failed on the old code. No blocker, no major. Four minors, one of them new
(latent, no user-visible effect). VERDICT: PASS.**

The 403-test feature suite is exactly the iteration-4 count (394) plus the nine
tests this iteration added, so nothing was weakened to reach green.

---

## The mandatory item — P09-TEST-6 / BUG-P09-13: **fixed**

ORCHESTRATOR_NOTES 00:25: *"in debug builds the coin guard's assert text leaks
into the toast. The toast must show the product copy only, in debug and release,
with a test."*

**Fix.** `app/lib/features/quests/data/quests_repository_impl.dart:92-104` —
`_checkCoins` no longer asserts:

```dart
void _checkCoins(int coins) {
  if (coins < minCoins || coins > maxCoins) {
    throw ArgumentError.value(coins, 'coins', 'Quest coins must be 1..100');
  }
}
```

One code path for every build mode. In release the `if` throws
`ArgumentError`, as before; in debug/test there is no longer an `assert` to fire
first, so the same `ArgumentError` reaches
`QuestsBloc._editorError`'s `if (error is ArgumentError)` branch
(`quests_bloc.dart:124`), which returns `QuestsBloc.saveFailedMessage` and logs
the detail under `name: 'quests'`. The raw
`Failed assertion: … Quest coins must be 1..100, got 9999` string — source path,
line number and internal range — can no longer reach a parent's toast in any
build mode.

**Proof, and it is a real proof.** `app/test/features/quests/quests_repository_test.dart:413`
and `:431` changed from `throwsA(isA<AssertionError>())` to `throwsArgumentError`.
That assertion **cannot pass on the old code**: under `flutter test` the assert
fired first and threw `_AssertionError`, which is not an `ArgumentError`. The
stronger matcher is therefore the regression test for the debug path.

On top of that, `app/test/features/quests/p09_bugs_test.dart:603-629` adds the
end-to-end proof iteration 6 parked as `skip: true`. It is now **un-skipped and
green**, uses the **real** `QuestsRepositoryImpl` (no mock), dispatches
`QuestsCreateRequested` with a 9999-coin `Quest` and asserts
`state.editorError == QuestsBloc.saveFailedMessage`. Because `flutter test`
runs with asserts enabled, this test *is* the debug-build case the bug report
asked for. The toast itself is pinned separately by the reworked
`quest_editor_states_test.dart:352-390`, whose `_FaultyRepository` grew a
`writeError` parameter so a test can inject a specific error type and assert both
that `find.text(QuestsBloc.saveFailedMessage)` is on screen and that neither
`Invalid argument` nor `1..100` appears.

**Contract docs corrected.** `quests_repository.dart:22-26` no longer promises
"`AssertionError` in debug / `ArgumentError` in release"; it now states
`ArgumentError` in all builds and cites P09-TEST-6. The `_checkCoins` doc
comment explains *why* there is no assert, so the next person does not
"restore" it.

Reachability is unchanged (the clamped editor never dispatches an out-of-range
value — `_canSave` blocks the write and shows `Coins must be 1–100`), so this was
and remains a defensive-path fix. It is now correct in both modes.

---

## Findings (iteration 5)

### 1. MINOR — `_save()` dispatches `Quest.active: false` for every new quest, contradicting the comment directly above it

`app/lib/features/quests/presentation/views/quest_editor_view.dart:564-567`:

```dart
// Editing a quest must not resurrect an archived one (review finding 9).
// A new quest is always stored active — including a `?idea=` create,
// whose template carries `active: false` (templates are not rows).
active: _isEdit && widget.initialQuest!.active,
```

The comment says a new quest is always stored active. The expression evaluates
to **`false`** whenever `_isEdit` is false, i.e. for every new quest (plain and
`?idea=`). Measured first-hand on this tree with a spy repository that captures
the dispatched entity before the real write:

```
PROBE new quest: dispatched active = false
PROBE edit quest: dispatched active = true
```

Nothing is visible today only because `QuestsRepositoryImpl.createQuest`
(`quests_repository_impl.dart:63`) hard-codes `active: const Value(true)` on
insert, ignoring `quest.active`. So the domain object lies, and the screen is one
line away from archiving every quest a parent creates: if anyone "cleans up"
`createQuest` to write `Value(quest.active)` — the obvious DRY change — every
new quest silently disappears from the library's Active tab. No test catches it:
`quest_editor_view_test.dart:303` and `:925`, `quest_editor_states_test.dart:748`
and `quest_editor_data_integrity_test.dart:463,480` all read the **row back from
Drift**, which is `true` because of the repository's hard-coding.

**Fix.**

```dart
active: _isEdit ? widget.initialQuest!.active : true,
```

and add a test that asserts the object the **bloc received** carries
`active == true` for a new quest (the existing `_FaultyRepository.written` list
in `quest_editor_states_test.dart` is already the right hook — assert on
`written.single.active`, not on the row read back).

### 2. MINOR (carried, iteration-4 finding 1) — `_editorError` still forwards raw `error.toString()` for anything that is not an `ArgumentError`

`app/lib/features/quests/presentation/bloc/quests_bloc.dart:123-129`. A Drift
`SqliteException` (disk full, a constraint on a column P09 does not clamp) would
still reach `showNestToast` verbatim. The editor does not produce those paths
today and this iteration's mandate was explicitly "fix ONLY P09-TEST-6, change
nothing else", so it is correctly left alone — but it stays open.

**Fix.**

```dart
String _editorError(Object error) {
  log('quest save failed: $error', name: 'quests');
  return QuestsBloc.saveFailedMessage;
}
```

If the design ever wants distinct copy per cause, map each cause explicitly
rather than forwarding the runtime's text.

### 3. MINOR (carried, iteration-4 finding 2) — garbled token in a comment

`app/lib/features/quests/presentation/views/quest_editor_view.dart:1037`:
`` the design rect (`uta:hex`-verified) `` — a truncated tool slug, left as-is by
the same "change nothing else" instruction.

**Fix.** `the design rect (verified against the P09 PNG, ÷3).`

### 4. MINOR (new) — `QuestEditorMetrics.cancelPadding` hard-codes a value the shared scale already carries

`app/lib/features/quests/presentation/widgets/quest_editor_widgets.dart:29`
(`static const double cancelPadding = 6;`, used at `:107`) duplicates
`NestSpacing.gap6 = 6` (`app/lib/core/design_system/tokens/spacing.dart:28`) —
and the same file already imports and uses `NestSpacing` throughout. The
"tokens only, never hard-code sizes" rule prefers the shared token; the other
five constants in `QuestEditorMetrics` (`14`, `1.5`, `18`, `64`, `56`) are
genuinely off-scale and correctly screen-local, so this one is the odd case out.

**Fix.** Delete `cancelPadding` and use `NestSpacing.gap6` at the call site,
keeping the CSS-provenance comment.

### 5. MINOR (new, shared doc — not P09's to edit) — `DESIGN_SPEC.md:168` still says "48px tiles"

The HTML (`.ic{width:44px;height:44px}`, `.icons{grid-template-columns:repeat(6,44px)}`)
and both PNGs are 44 px; the code and the geometry test are right. Carried from
iteration-3 finding 7 for the orchestrator's doc pass — `docs/DESIGN_SPEC.md` is
shared, so RULES §1 puts it out of this screen's reach.

### 6. MINOR (new, test prose) — the BUG-P09-13 proof's inline comment still describes the pre-fix behaviour as current

`app/test/features/quests/p09_bugs_test.dart:620-626` reads *"In debug the assert
fires first (AssertionError), the mapping misses, and the raw
`Failed assertion: …` text is what the toast would show"* — inside a test that is
now green because that is no longer true. Harmless, but it reads as a live bug
description next to a passing assertion. **Fix.** Re-word to past tense
("the assert used to fire first …").

---

## What was checked and found correct

* **RULES §1 file scope.** `git diff --stat main...HEAD` touches
  `lib/features/quests/{data,domain,presentation}/**`,
  `lib/features/quests/quests_routes.dart`, `test/features/quests/**`, the two
  `test/features/today/` files, and `docs/screens/P09/**`.
  `app/lib/core/**`, `app/lib/app/**`, `app/test/core/**`, `tools/**`,
  `analysis_options.yaml`, `pubspec.yaml` are all untouched
  (`git diff main...HEAD -- app/analysis_options.yaml app/pubspec.yaml` is
  empty). The two `today/` files are outside RULES §1's list but are explicitly
  pre-authorised by `docs/screens/_shared/shared_batch4.md:15` and
  `docs/screens/_shared/router_push_test_fix.md`; they only swap
  placeholder-title assertions for the durable `pushedPath` contract.
* **Architecture.** Feature-first intact: `domain/` is still entities plus the
  abstract repository only; one bloc for the feature; routes and the query
  contract (`QuestsEditorQuery.questId / legacyQuestId / ideaId`) live in
  `quests_routes.dart`; `/quest-editor` → `QuestEditorView` + `QuestsBloc`
  exactly as `ARCHITECTURE.md`'s table says. `editorStatus` stays orthogonal to
  `status`, so `watchItems()` emissions do not rebuild the form (`buildWhen` on
  `status` only) and no reload event was reintroduced. `QuestsBloc` is a
  `registerFactory` (`quests_di.dart:16-17`), so each route push builds and
  closes its own bloc — no singleton-subscriber accumulation. The one
  cross-feature read (`FamilyRepository.watchChildren()`) is read-only and has an
  in-feature precedent.
* **Design system.** `grep` over the diff's `lib/` files finds **no**
  `Colors.` literal (`Colors.transparent` only), no `letterSpacing` anywhere
  (P09's CSS sets none, so the `NestType` default 0 is correct), no hard-coded
  colour, and no `GoogleFonts`/`google_fonts`. Every gap through
  `NestSpacing`/`NestDevice`/`NestRadii`; every style through `NestType`.
  `NestBalancedText` is correctly absent (no `text-wrap: balance` in P09's CSS)
  and `NestChipWrap` is correctly absent (no `NestChip` rows — `.ic`/`.person`
  are custom per the plan and are already ≥44 tap targets at 44 and 48).
  Shared components reused, none re-implemented: `NestStatusBar`, `NestTextField`,
  `NestCard`, `NestStepper`, `NestSegmented`, `NestDayPicker`, `NestToggle`,
  `NestAvatar`, `NestIcon`, `NestButton`, `NestModal`, `NestBottomSheet`,
  `NestToast`. The screen-local widgets (`QuestEditorLabel`, `QuestCancelButton`,
  `QuestSavePill`, `QuestIconTile`, `QuestPersonPill`, `QuestDueOptionRow`) each
  carry the CSS that justifies them, and `QuestEditorLabel` documents why
  `NestSectionLabel` does not fit (sentence case, not uppercase).
* **Copy.** Every design string matches the HTML character for character,
  verified by extracting the HTML's text nodes and comparing:
  `Who's it for?` with a **straight** U+0027 apostrophe, `Coins land after your
  thumbs-up` with U+002D (not an en dash), `Before tea (5pm) ›` with U+203A,
  `= 15p at payout`, the U+2212 `−` stepper glyph, the seven day letters. The
  screen-local strings are enumerated in `kScreenLocalCopy` with a plan section
  each, and the copy audit is a *set equality* over everything the tree paints,
  so an invented string fails the suite. UK spelling throughout.
* **Accessibility.** Every interactive element carries `onTap:` on its own
  `Semantics` node: `QuestCancelButton`, `QuestSavePill` (null when disabled, so
  it reports `enabled: false` and exposes no tap), `QuestIconTile`,
  `QuestPersonPill`, `QuestDueOptionRow`, plus the shared `NestStepper`,
  `NestToggle`, `NestSegmented`, `NestDayPicker`, `NestButton` and the due
  `NestCard` — whose label carries the *current value* (`Due by, $_dueLabel`),
  because `NestCard`'s `excludeSemantics` would otherwise drop it. The four group
  labels are `semanticHeader`, the icon row is one `container` labelled
  `Quest icon`, and both live-region captions are `liveRegion: true`.
  `quest_editor_toggle_hit_area_test.dart` (new in iteration 4) loads the bundled
  faces, asserts its own premise (the card really is 72 and the sub-line really
  is one 18 px line) and then proves the toggle's full CSS `::before` 59×44 hit
  box at the offsets the bug report used — so it cannot pass vacuously.
* **Children's Code.** `/quest-editor` is in the router's `parentOnly` list
  (`lib/app/router.dart:88`) and kid mode is redirected to `/parental-gate`,
  proven by a test. No analytics, no ads, no network, no child data leaves the
  device: the screen reads the family's own children and writes only to `quests`.
  No `subscription_status` is written anywhere in the diff. No `Pip` on this
  screen, so the PIP rule does not apply (correctly noted in `1_plan.md`).
* **Error handling.** Save/update/delete failures keep the editor open, leave the
  Drift row untouched, re-enable the pill via `clearSaveGuard()` (called from the
  `BlocConsumer` listener before the toast), and surface mapped copy. A failed
  route-level load offers `Try again`, and `_closeOnError` terminates the watcher
  so each retry starts exactly one subscription. Coins are validated in the
  repository before Drift is touched, and an out-of-range stored value blocks the
  save with a visible reason instead of being silently clamped; the one-tap
  boundary jump gives a corrupt value a real repair path.
* **Performance / lifecycle.** `buildWhen` keeps `watchItems()` emissions from
  rebuilding the form; both subscriptions are fields cancelled in `dispose`
  (`unawaited`), as is `_title`; the roster listener ignores an equal list so a
  `children` write elsewhere cannot rebuild the form; the per-keystroke rebuild
  is scoped to the save pill with `ValueListenableBuilder`; the icon row's
  `LayoutBuilder` is cheap and its `tiles` list is built once per build; `const`
  is used everywhere it compiles.
* **Clock.** `DateTime.now()` is gone from the feature — the new-quest id uses
  `appNowUtc().millisecondsSinceEpoch` (`quest_editor_view.dart:543`), the
  CLOCK-rule accessor, which is test-pinnable.
* **Bottom edge, alignment, child order.** The paper sheet runs to the physical
  bottom edge (`quest-editor-sheet` key + `minHeight: constraints.maxHeight`,
  asserted by a geometry test that samples the last row). Gutters are
  `NestSpacing.padSide` (20) on every row and the icon row is `space-between`.
  Children arrive in creation order from the shared repository and a new quest
  defaults to the first of them — never alphabetical.
* **Test hygiene.** No `skip:`, no `// ignore:`, no `google_fonts` in the
  feature's tests, and the four `tester.pageBack()` → `handlePopRoute()`
  swaps (in `p10_bugs_test`, `quest_library_*`) are *stronger*, not weaker: the
  old call could only resolve a `Back` tooltip, which this screen deliberately
  does not have (review finding 3), and each swapped call still asserts the
  resulting route. Every widget test ends with `disposeApp(tester)`.

## LEFT FOR THE LOOP

1. Finding 1 — one-line fix in `quest_editor_view.dart:567` plus a test that
   asserts the *dispatched* entity's `active`.
2. Findings 2 and 3 — the two iteration-4 leftovers, both one-liners in
   `quests_bloc.dart` and a comment.
3. Finding 4 — `cancelPadding` → `NestSpacing.gap6`.
4. Finding 5 — shared `docs/DESIGN_SPEC.md:168`; route to the orchestrator's doc
   pass (still not P09's to edit).
5. Finding 6 — test prose only.
6. `5_ui` can now re-shoot freely: this iteration changed no layout, no copy and
   no colour, and the whole tree is green.

No simulator was used in this stage.

VERDICT: PASS