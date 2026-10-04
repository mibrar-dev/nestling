# P09 — stage 4 · QA code review (iteration 6)

Scope reviewed: `git diff main...HEAD` on branch `screen/P09` against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P09
(line 168), `docs/design/SPACING_SPEC.md`, the design system in
`app/lib/core/design_system/`, the HTML source
`design/html-source/screens/P09-quest-editor.html`, and the mandatory item in
`docs/screens/P09/ORCHESTRATOR_NOTES.md` (09:27, BUG-P09-14).

`git merge-base main HEAD` = `bbdfdbe`; `git rev-list --count HEAD..main` = 4
(the shared `unique_ids` and `kid_trial_gate` batches are merged in and the
loop merges `main` before the next build — process, not a finding).
`HEAD` was `dfc7011` ("P09: checkpoint after build (iteration 6)") for the
whole review. The iteration-5→6 code delta is exactly three hunks in two lib
files plus five test files.

No code was edited. Only this file was written. No simulator was booted,
installed on, screenshotted or driven; `flutter clean` was never run.

Because a sibling stage is writing in this worktree (the uncommitted
`.brief_*.md` files in `git status`), every gate ran against an isolated
`git archive HEAD` export (`…/opencode/p09-i6`).

```
$ cd …/opencode/p09-i6/app && dart format --set-exit-if-changed --output=none .
Formatted 538 files (0 changed) in 4.53 seconds.          (exit 0)
$ flutter analyze
No issues found! (ran in 9.8s)                            (exit 0)
$ flutter test test/features/quests/
00:25 +414: All tests passed!                              (exit 0)
$ flutter test
03:11 +3125 ~2: All tests passed!                          (exit 0)
```

414 in the feature suite is iteration 5's 403 **plus exactly the eleven tests
this iteration added** — `p09_bugs_test` +1, `quest_editor_robustness_test` +5,
`quest_editor_view_geometry_test` +4, `quest_editor_states_test` +1 — so
nothing was weakened or skipped to reach green. `grep 'skip:'` over
`test/features/quests/` returns one comment line and no active skip. The 2
skips in the whole suite are other features'
(`kid_home/k01_bugs_test.dart:566`, `pocket_money/p12_bugs_test.dart:321`).

## Verdict summary

**The mandatory item is fixed and its proof is a real regression test — I
verified that independently by reverting the fix and re-running it. The
iteration-6 toggle re-centring is correct and does not move the design frame.
No blocker, no major. Seven minors, four carried. VERDICT: PASS.**

---

## The mandatory item — BUG-P09-14 / ORCHESTRATOR_NOTES 09:27: **fixed, and the proof is real**

The note: *"never derive ids from the clock … Once main has it, use
`newId('q')` for new quests. Un-skip the BUG-14 proof: create two quests in a
row under the pinned clock and both must exist. Raw SQL/exception text must
never reach the toast."*

**Fix.** `app/lib/features/quests/presentation/views/quest_editor_view.dart:546`

```dart
id: _isEdit ? widget.initialQuest!.id : newId('q'),
```

`appNowUtc` is gone from the feature — `grep 'DateTime.now()\|appNowUtc\|clock.now'`
over `lib/features/quests/` returns nothing. The import moved from
`core/data/app_clock.dart` to `core/data/ids.dart` (line 8), i.e. no clock
import survives in the feature at all.

**Proof, independently re-verified by me (not taken on trust).** I copied the
isolated export, restored the old line
(`'q-${appNowUtc().millisecondsSinceEpoch}'` + the old import) and ran only
the new proof:

```
$ flutter test test/features/quests/p09_bugs_test.dart \
    --plain-name "two creates in one session both persist"
00:01 +0 -1: Some tests failed.
  Expected: no matching candidates
    Actual: Found 1 widget with text "New quest"
  file: p09_bugs_test.dart line 675
```

So on the old code the second save strands the editor on `New quest` — exactly
the reported symptom — and the test fails. `appNowUtc()` returns the pinned
story instant whenever `Seed.anchorOverride` is set
(`app/lib/core/data/app_clock.dart:26-33`), so *every* create in a test mints
the same id: the collision is guaranteed, not flaky. The scratch copy has been
deleted.

The proof itself (`app/test/features/quests/p09_bugs_test.dart:644-701`) is
written well: it uses the **real** `QuestsRepositoryImpl`, drives the full flow
(plain editor create → `/quests` → P10 `+ Add` → second create), and asserts
three separate things — the editor closed, no `UNIQUE constraint failed` text
is on screen, and both rows exist with **two distinct ids**
(`created.toSet(), hasLength(2)`), so it cannot pass with one quest twice.
`quest_editor_states_test.dart:555-604` adds an independent shape pin: the id
must match `^q-<uuid v4>$` and must not equal either clock stamp.

**The third sentence of the mandate — "raw SQL/exception text must never reach
the toast" — is met for this screen.** With the id fixed, the only writer-side
exception reachable from the editor is `ArgumentError` from the coins guard,
which maps to `QuestsBloc.saveFailedMessage`. I checked the schema to be sure
nothing else can throw: `quests.assigneeChildId` has **no** foreign key
(`app_database.dart:122`), `title` has no length constraint, and `createdAt` is
a `currentDateAndTime` default that never appears in the insert companion — so
there is no constraint-violation route left. Finding 2 below records the
remaining *latent* hole, not a live one.

---

## Iteration 6's other change — the approval toggle re-centring (P09-TEST-9): **correct, no design drift**

`quest_editor_view.dart:1054-1075` replaces `Positioned(top: 20.5, right: s4)`
with `Positioned.fill → LayoutBuilder → Stack → Positioned(top: (H−31)/2, right: s4)`.
I checked this against the shared widget and Flutter's hit-test rules:

* `.switchrow { align-items: center }` with the card's symmetric 16/16 padding
  means centring on the **card** and centring on the **content box** are the
  same thing, and doing it from the card's own height makes it correct at every
  metric instead of only the measured one. On the design frame the result is
  numerically identical — `(72−31)/2 = 20.5` card-local → `620.5` global,
  `303→354` horizontally — which is what `5_ui.md` measured and what the
  geometry test pins. **No UI re-shoot should find drift**; `5_ui` must still
  re-shoot to confirm.
* The `Positioned.fill` + `LayoutBuilder` + `Stack` shape is *necessary*, not
  cargo-cult: `RenderPadding` deflates its hit region, so a `Padding` inset
  anywhere between the track and the card edge would reject the slop taps, and
  `RenderPositionedBox`/`RenderStack` do not bounds-check their children — which
  is exactly how `_RenderToggleHitSlop`'s 4 px / 6.5 px overhang survives
  (`core/design_system/components/nest_toggle.dart:151-168`). The inline
  comment records the measured dead ends, which is the right way to stop the
  next person "simplifying" it back into a broken tree.
* The hit area is intact: the slop spans `cardCentre ± 22` vertically and
  reaches `cardRight − 12` horizontally, both inside the 72-high / 16-padded
  card. `quest_editor_toggle_hit_area_test.dart` proves taps 5 px above, 5 px
  below and 2 px right all flip the switch, and it passes.
* Layout cost: one extra `LayoutBuilder` over a single-child `Stack`. Negligible.
* **Confirmed against pixels.** The sibling UI stage re-shot this iteration
  while the review ran: light 1.29 %, dark 1.19 %, dy = 0, and the toggle track
  rect is *bit-identical in position* to iteration 5 (app `303→353.7` /
  `620.7→651` vs design `303→353.7` / `621→651.7`, ≤0.3 px). The re-centring
  has no surface on the design frame, exactly as predicted.

---

## Findings (iteration 6) — all minor

### 1. MINOR (carried, iteration-5 finding 1, still open) — `_save()` sends `Quest.active: false` for every new quest, contradicting the comment directly above it

`app/lib/features/quests/presentation/views/quest_editor_view.dart:567-570`:

```dart
// A new quest is always stored active — including a `?idea=` create,
// whose template carries `active: false` (templates are not rows).
active: _isEdit && widget.initialQuest!.active,
```

`&&` short-circuits, so for every new quest (plain and `?idea=`) the dispatched
entity carries `active: false`. Nothing is visible today only because
`QuestsRepositoryImpl.createQuest` hard-codes `active: const Value(true)`
(`quests_repository_impl.dart:63`) and ignores the field — the obvious DRY
cleanup there (`Value(quest.active)`) would silently archive every quest a
parent creates. No test catches it: the four existing assertions read the row
back from Drift, which is `true` because of the repository's hard-coding.

**Fix.** `active: _isEdit ? widget.initialQuest!.active : true,` plus a test
that asserts the *dispatched* entity (`_FaultyRepository.written.single.active`
in `quest_editor_states_test.dart` is the right hook), not the row read back.
The plan file also has to agree — see finding 5.

### 2. MINOR (carried, iteration-5 finding 2, still open) — `_editorError` forwards raw `error.toString()` for anything that is not an `ArgumentError`

`app/lib/features/quests/presentation/bloc/quests_bloc.dart:123-129`.
Explicitly considered and **downgraded-kept at MINOR**, not raised, for two
reasons I checked rather than assumed: (a) there is no reachable non-`ArgumentError`
path from this screen's three write handlers (see the mandate section above —
no FK, no length constraint, server-defaulted `createdAt`); (b) `error.toString()`
is the **codebase-wide convention** — `approvals_bloc`, `auth_bloc`, `family_bloc`,
`kid_home_bloc`, `kid_jar_bloc`, `badges_bloc` all do it — so P09 is already
stricter than the norm, and the underlying hole is shared, not P09's.

**Fix** (same as iteration 5; the orchestrator can take it as a shared item):

```dart
String _editorError(Object error) {
  log('quest save failed: $error', name: 'quests');
  return QuestsBloc.saveFailedMessage;
}
```

If the design ever wants distinct copy per cause, map each cause explicitly.

### 3. MINOR (carried, iteration-5 finding 4, still open) — `QuestEditorMetrics.cancelPadding` hard-codes a value the shared scale already carries

`app/lib/features/quests/presentation/widgets/quest_editor_widgets.dart:29`
(`static const double cancelPadding = 6;`, used at `:113`) duplicates
`NestSpacing.gap6 = 6` (`core/design_system/tokens/spacing.dart:28`), and the
same file already imports and uses `NestSpacing` throughout. The other
constants in `QuestEditorMetrics` (`14`, `1.5`, `18`, `64`, `56`) are genuinely
off-scale and correctly screen-local; this is the odd case out.

**Fix.** Delete `cancelPadding` and use `NestSpacing.gap6` at the call site,
keeping the CSS-provenance comment.

### 4. MINOR (new, iteration 6) — `approvalTrackHeight`/`approvalTrackWidth` duplicate `NestToggle`'s private 51×31, and a stale height silently breaks the centring

`app/lib/features/quests/presentation/widgets/quest_editor_widgets.dart:47-48`,
consumed at `quest_editor_view.dart:1031` and `:1060-1063`. Unlike finding 3
this is a real drift hazard rather than cosmetic: `NestToggle`'s box is a
private `width: 51, height: 31` inside the shared component
(`core/design_system/components/nest_toggle.dart:52-53`), and the new centring
formula *subtracts* the height. If a shared batch ever resizes the track, P09's
`Positioned` top is computed from a stale number and the switch silently rides
off-centre with every geometry test still green (they all assert symmetry
against the card, not against the toggle).

**Fix.** Export the size from the shared component
(`NestToggle.trackWidth = 51`, `NestToggle.trackHeight = 31`) and reference it
here; that is a one-line core addition, so file it in `SHARED_REQUEST.md`
rather than editing `core/`. Failing that, note in the doc comment that the
pair must move with `NestToggle`'s box.

### 5. MINOR (new, iteration 6) — `1_plan.md:126` is now wrong on two counts

`docs/screens/P09/1_plan.md:126` still reads
`` `assigneeChildId` (null = Anyone), `active: true`. New id: `q-<ms epoch>`. ``
The id rule was superseded by ORCHESTRATOR_NOTES 09:27 / the IDS rule
(`newId('q')`), and `active: true` is what the code *says* it does but not what
it *does* (finding 1). `docs/screens/P09/**` is inside RULES §1, so this is
P09's to fix. Left stale, it is the doc a future agent reads first.

**Fix.** `active: true for a new quest, the stored flag for an edit` and
`new id: newId('q')` (uuid), with a line pointing at ORCHESTRATOR_NOTES 09:27.

### 6. MINOR (carried, iteration-5 finding 6, still open) — the BUG-P09-13 proof's inline comment describes the pre-fix behaviour in the present tense

`app/test/features/quests/p09_bugs_test.dart:632-636` reads *"In debug the
assert fires first (AssertionError), the mapping misses, and the raw
`Failed assertion: …` text is what the toast would show"* — inside a test that
has been green since iteration 5 because that is no longer true. Harmless, but
it reads as a live bug description next to a passing assertion.
**Fix.** Re-word to past tense.

### 7. MINOR (shared doc — **not** P09's to edit) — `DESIGN_SPEC.md:168` still says "48px tiles"

The HTML is unambiguous: `.ic{width:44px;height:44px;min-width:44px;min-height:44px}`
and `.icons{display:grid;grid-template-columns:repeat(6,44px);gap:8px}`, and both
PNGs are 44 px. The code (`NestDevice.tapParent`) and the geometry test are
right. Carried from iteration-3 finding 7 for the orchestrator's doc pass —
RULES §1 puts `docs/DESIGN_SPEC.md` out of this screen's reach.

**Iteration-5 finding 3 is now CLOSED**: the garbled `` (uta:hex)-verified ``
slug was inside the comment block iteration 6 rewrote (`quest_editor_view.dart:1035-1053`);
no truncated tool slug remains in the feature.

---

## What was checked and found correct

* **RULES §1 file scope.** `git diff --stat main...HEAD` touches
  `lib/features/quests/{data,domain,presentation}/**`,
  `lib/features/quests/quests_routes.dart`, `test/features/quests/**`, the two
  `test/features/today/` files, and `docs/screens/P09/**`.
  `app/lib/core/**`, `app/lib/app/**`, `app/test/core/**`, `tools/**`,
  `analysis_options.yaml` and `pubspec.yaml` are untouched
  (`git diff main...HEAD` lists no path under them). The `today/` files are
  pre-authorised by `docs/screens/_shared/shared_batch4.md:15` and
  `router_push_test_fix.md` and only swap placeholder-title assertions for the
  durable `pushedPath` contract. The iteration-6 delta adds no path at all
  outside the feature.
* **Architecture.** Feature-first intact: `domain/` is entities plus the
  abstract repository only; one bloc for the feature; the route file and the
  query contract (`QuestsEditorQuery.questId / legacyQuestId / ideaId`) live in
  `quests_routes.dart`; `/quest-editor` → `QuestEditorView` + `QuestsBloc`
  exactly as `ARCHITECTURE.md:134` says. `QuestsBloc` is a `registerFactory`
  (`quests_di.dart:16-17`), so each push builds and closes its own bloc. The one
  cross-feature read (`FamilyRepository.watchChildren()`) is read-only and has an
  in-feature precedent.
* **Design system.** `grep` over the feature's `lib/` finds **no** `Colors.`
  literal except `Colors.transparent`, no `letterSpacing` (P09's CSS sets none,
  so the `NestType` default 0 is correct), no hard-coded colour and no
  `GoogleFonts`/`google_fonts`. Every gap runs through
  `NestSpacing`/`NestDevice`/`NestRadii`, every style through `NestType`.
  `NestBalancedText` is correctly absent (no `text-wrap: balance` anywhere in
  P09's HTML — re-verified) and `NestChipWrap` is correctly absent (there are
  no `NestChip` rows: `.ic` and `.person` are custom per the plan and are
  already ≥44 at 44 and 48). Shared components reused, none re-implemented:
  `NestStatusBar`, `NestTextField`, `NestCard`, `NestStepper`,
  `NestSegmented`, `NestDayPicker`, `NestToggle`, `NestAvatar`, `NestIcon`,
  `NestButton`, `NestModal`, `NestBottomSheet`, `NestToast`. Each screen-local
  widget carries the CSS that justifies it, and `QuestEditorLabel` documents
  why `NestSectionLabel` does not fit (sentence case, not uppercase).
* **Copy.** Verified against the HTML source, character for character:
  `Who's it for?` with a **straight** U+0027 apostrophe, `Coins land after your
  thumbs-up` with U+002D (not an en dash), `Before tea (5pm) ›` with U+203A,
  `= 15p at payout`, the U+2212 `−` stepper glyph, the seven day letters. The
  screen-local strings are enumerated in `kScreenLocalCopy` with a plan section
  each, and the audit is a set equality over everything the tree paints, so an
  invented string fails the suite. Iteration 6 introduced **no** new copy.
  UK spelling throughout.
* **Accessibility.** Every interactive element carries `onTap:` on its own
  `Semantics` node: `QuestCancelButton`, `QuestSavePill` (null when disabled, so
  it reports `enabled: false` and exposes no tap), `QuestIconTile`,
  `QuestPersonPill`, `QuestDueOptionRow`, plus the shared `NestStepper`,
  `NestToggle`, `NestSegmented`, `NestDayPicker`, `NestButton` and the due
  `NestCard` — whose label carries the *current value*
  (`Due by, $_dueLabel`), because `NestCard`'s `excludeSemantics` would
  otherwise drop it. The four group labels are `semanticHeader`, the icon row is
  one `container` labelled `Quest icon`, and both validation captions are
  `liveRegion: true`. The iteration-6 toggle restructure touches no semantics
  node. Every widget test ends with `disposeApp(tester)`.
* **Children's Code.** `/quest-editor` is in the router's `parentOnly` list
  (`app/lib/router.dart:88`) and kid mode is redirected to `/parental-gate`,
  proven by a test. No analytics, no ads, no network: `grep 'http\|analytics\|
  Firebase\|Socket'` over `lib/features/quests/` returns nothing. The screen
  reads the family's own children and writes only to `quests`. No
  `subscription_status` is written anywhere in the diff. No Pip on this screen,
  so the PIP rule does not apply (correctly recorded in `1_plan.md`).
* **Error handling.** Save/update/delete failures keep the editor open, leave
  the Drift row untouched, re-enable the pill via `clearSaveGuard()` (called
  from the `BlocConsumer` listener before the toast) and surface mapped copy. A
  failed route-level load offers `Try again`, and `_closeOnError` terminates the
  watcher so each retry starts exactly one subscription. Coins are validated in
  the repository before Drift is touched; an out-of-range stored value blocks the
  save with a visible reason instead of being silently clamped, and the
  one-tap boundary jump gives a corrupt value a real repair path.
* **Performance / lifecycle.** `buildWhen` keeps `watchItems()` emissions from
  rebuilding the form; both subscriptions are fields cancelled in `dispose`
  (`unawaited`), as is `_title`; the roster listener ignores an equal list so a
  `children` write elsewhere cannot rebuild the form; the per-keystroke rebuild
  is scoped to the save pill with `ValueListenableBuilder`; the icon row's
  `LayoutBuilder` is cheap and its `tiles` list is built once per build; `const`
  is used everywhere it compiles. The new `LayoutBuilder` adds one subtree
  layout of a single-child `Stack` per approval-card build — not a rebuild storm.
* **Clock / ids.** `DateTime.now()` and `appNowUtc` are both absent from the
  feature. `newId('q')` is the only id source, matching the IDS rule
  (`core/data/ids.dart`, a shared addition, not a P09 edit). The
  `quest_editor_states_test.dart` addition uses `appNowUtc()` deliberately and
  only to assert the id is *not* that value.
* **Bottom edge, alignment, child order.** The paper sheet runs to the physical
  bottom edge (`quest-editor-sheet` key + `minHeight: constraints.maxHeight`,
  asserted by a geometry test that samples the last row). Gutters are
  `NestSpacing.padSide` (20) on every row and the icon row is
  `space-between`. Children arrive in creation order from the shared repository
  and a new quest defaults to the first of them — never alphabetical.
* **Test hygiene.** No `skip:`, no `// ignore:`, no `google_fonts` in the
  feature's tests. The four `tester.pageBack()` → `handlePopRoute()` swaps are
  *stronger*, not weaker: the old call could only resolve a `Back` tooltip,
  which this screen deliberately does not have, and each swapped call still
  asserts the resulting route.

## LEFT FOR THE LOOP

1. Finding 1 — one-line fix at `quest_editor_view.dart:567` plus a test that
   asserts the *dispatched* entity's `active`.
2. Findings 2 and 3 — the two one-liners in `quests_bloc.dart` and
   `quest_editor_widgets.dart`.
3. Finding 4 — export `NestToggle`'s track size from the shared component
   (needs a `SHARED_REQUEST.md` line; `core/` is off-limits to this screen) and
   reference it from `QuestEditorMetrics`.
4. Finding 5 — `1_plan.md:126`, two lines, P09's own file.
5. Finding 6 — test prose only.
6. Finding 7 — shared `docs/DESIGN_SPEC.md:168`; route to the orchestrator's
   doc pass.
7. **Already done by the sibling UI stage while this review was being written**
   (process note, not a finding): `5_ui.md` and `ui/cmp_{light,dark}_6.png` are
   uncommitted in this worktree and report iteration 6 at **1.29 % light /
   1.19 % dark** (was 1.38 / 1.21), dy = 0, gutters exactly 20, and the toggle
   track rect **unchanged** at x 303→353.7, app y 620.7→651 vs design
   621→651.7 (≤0.3 px) — which is the independent confirmation of this
   review's prediction that the re-centring is numerically identical on the
   design frame. The uncommitted work is the loop's own in-flight stages and is
   not reported as a finding.

No simulator was used in this stage.

VERDICT: PASS
