# Fix list after iteration 1

## From 3_test.md
# P09 — stage 3 · TEST (iteration 1)

Scope: `app/test/features/quests/**` only. No screen code, no shared code and
no `tools/` was touched; `flutter clean` was never run; no simulator was
booted, installed on, screenshotted or driven; no `skip:`, no `// ignore:`, no
`analysis_options.yaml` change; `google_fonts` appears nowhere.

## 1. Tests added (4 new files, 56 tests)

| File | Tests | What it closes |
|---|---|---|
| `quest_editor_states_test.dart` | 17 | loading / failure / retry / write-failure / navigation / edit-mode data mapping, on the real in-memory Drift DB |
| `quest_editor_a11y_test.dart` | 14 | the full a11y-actions sweep (all six tiles, all seven day cells, the three due rows, the delete flow, every control node) |
| `quest_editor_robustness_test.dart` | 17 | widths 320/390/430 × light/dark, text scale 1.0/1.3, gutters + bottom edge, 44 px tap targets, edge taps, stepper clamp |
| `quest_editor_copy_test.dart` | 8 | character-by-character copy audit + set equality against the design's copy |

### 1.1 States and navigation (`quest_editor_states_test.dart`)

The in-memory scope's real repository always loads and always writes, so the
editor's three unreachable states need a repository that misbehaves. They are
driven by `_FaultyRepository`, a decorator around the **real** one: reads still
come from Drift, so every "the database was/wasn't touched" assertion is real.

- `?id=` fetch pending → centred spinner, no form, no Save pill; the first
  emission replaces it with the sheet (`ConnectionState.waiting` → `done`).
- Route load error → the message + `Try again`, and `Try again` really
  re-subscribes (`watchCalls` 1 → 2) and reaches the loaded form. (The bloc's
  `_closeOnError` is what makes the retry possible.)
- Save/update/delete failure → `NestToast` with the repository's message, the
  screen does **not** navigate, the row in Drift is unchanged, and Save stays
  enabled. `Keep it` never reaches the repository at all.
- Navigation by ROUTE (`pushedPath`), never by copy: `Cancel` on the initial
  route `go`es to `/quests`; `Cancel` on a pushed editor (pushed from P10's
  `+ Add`) **pops** back to `/quests` with the library intact — the branch no
  test covered before; a successful create, a confirmed delete and
  `Back to quests` all land on `/quests`.
- `Seed.empty()`: `Anyone` is preselected, no avatar is drawn, and saving
  stores `assigneeChildId == null`.
- Edit-mode data mapping (quests inserted straight into Drift, so the seed's
  values are not the only ones exercised): `days: '1,3,5'` → cells {0, 2, 4};
  the seed's `icon: 'bins'` still lights the **Bins** tile; a stored
  `assigneeChildId: null` keeps **Anyone** selected (the roster default must
  not overwrite it); `repeatRule: 'daily'` opens with no day row; the saved
  title is trimmed.

### 1.2 Accessibility actions (`quest_editor_a11y_test.dart`)

- All **six** icon tiles: label, `SemanticsAction.tap`, `performAction` flips
  the real tile, exactly one tile stays selected. The earlier suite covered
  only four.
- All **seven** day cells: button flag, tap action, and a toggle on then off
  (the picked set is copied before the tap — the view mutates it in place).
- The due-time sheet, row by row: each row's node exposes tap and
  `performAction` moves the real label *and* the `HH:MM` that lands in Drift
  (`08:30` / `17:00` / `19:30`), plus the sheet re-opening with the newest
  choice marked selected.
- The delete flow driven entirely by semantics: `Delete quest` → modal →
  `Keep it` (row survives) → `Delete` (row gone).
- **Set equality on the control nodes**: the screen publishes exactly the 25
  expected labels and nothing more or less, so a control that loses its label
  or gains a second announcement fails here. A sweep then asserts every
  control node either exposes `tap` or reports `Tristate.isFalse` (disabled).
- Disabled Save reports `enabled: false` **and** has no tap; the header and
  the three group labels are the only four headers; the toggle announces
  `toggled` and flips.

### 1.3 Robustness (`quest_editor_robustness_test.dart`)

- 320 / 390 / 430 × light / dark: no exception, one column (every row starts at
  20 and every full-width row ends at `width - 20`; the icon row is
  `space-between`, so first tile on the gutter and last tile flush right while
  the six fit), the header's own controls on the same edges, the sheet
  full-bleed with paper to the physical bottom edge in every combination.
- 320 wraps the six tiles to two rows instead of clipping (6×44 + 5×8 = 304 >
  280), each still 44×44 and inside the gutters.
- Text scale 1.0 and 1.3 × light / dark: nothing overflows or clips, the
  reward helper stays on one line, a long title keeps the field at 52 and Save
  enabled.
- Tap targets: every control (Cancel, Save, stepper −/+, toggle, due card,
  Delete, 6 tiles, 3 pills, 7 day cells) is ≥ 44 high; the design's own
  minimums are pinned outright (Save 44, tile 44, pill 48, stepper 44,
  segmented 52). Kid-mode 56 does not apply — P09 is a parent screen.
- Edge taps: day cells, person pills, icon tiles, the segmented track's own
  6 px inset and the toggle's 44-high box all respond 5 px (or 2 px) inside
  each edge. Person pills are single-select, so each tap moves the selection
  and clears the others rather than toggling.
- The stepper clamps to 1..100 and the disabled end reports
  `Tristate.isFalse` with no tap action while the other end stays live.

### 1.4 Copy audit (`quest_editor_copy_test.dart`)

Every design string is present, character for character: the straight
apostrophe in `Who's it for?` (U+0027), the plain hyphens in
`Coins land after your thumbs-up` (U+002D — asserted, and `’` / `–` are
asserted **absent**), the U+203A chevron in `Before tea (5pm) ›` (asserted by
code point). Set equality proves the screen invents no copy beyond the design
plus the plan's sanctioned screen-local strings (`Edit quest`,
`Delete quest`, the confirm modal, `Quest not found`, `Pick at least one day`,
the due-sheet rows). The day row is pinned as the design's
`M T W T F S S` with Saturday selected, and the reward helper tracks the
stepper (`= 16p at payout` after one `+`).

This file also pins ORCHESTRATOR_NOTES 17:57 item 1 — the six icon labels in
the design's order (`Icon: Bed, Dishes, Hoover, Book, Bins, Paw`) — and the
stepper's `Decrease reward` / `Increase reward` aria-labels.

## 2. Results

```
$ dart format --set-exit-if-changed .
Formatted 480 files (0 changed) in 1.26 seconds.          (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 5.4s)

$ flutter test
01:00 +2375 ~6: All tests passed!
```

- `test/features/quests/` alone: `00:12 +324 ~5: All tests passed!` — 324 tests
  for the feature, 56 of them new here.
- The `~6` skips are **not** from this stage: 5 are the bug-proof placeholders
  another stage parked in `p09_bugs_test.dart` (its own file header says they
  are `skip:`-marked until each fix lands and `--run-skipped` demonstrates the
  failures), and 1 is the pre-existing repo-wide skip in
  `test/features/pocket_money/p12_bugs_test.dart:320` (P12-BUG-05, identical on
  `main`). Nothing in this stage skips or weakens a test; the note is here only
  so the orchestrator can see where the six come from.

## 3. Bugs found

### P09-TEST-1 — minor — the stepper's minus is U+002D, the design prints U+2212

- File: `app/lib/core/design_system/components/nest_stepper.dart:32`
  (`_StepBtn(label: '-', …)` — shared component, **not** P09's code; P09 only
  places `NestStepper` in the Reward card).
- Repro: open `/quest-editor`; the Reward card's left button is the design's
  `−` (U+2212) in the app it renders `-` (U+002D). Measured in a probe:
  `app stepper minus = U+2D (45) ; design prints U+2212 (8722)`; the design
  bytes are `e2 88 92` in
  `design/html-source/screens/P09-quest-editor.html` (`Decrease reward` row).
- Impact: a visible one-glyph copy deviation inside a 44 px control — the
  hyphen is ~3 px short and sits high against the PNG.
- Precedent: this is the same defect the repo already filed as **P06-BUG-12**
  ("the stepper minus is the design's U+2212, never U+002D"), fixed there with
  a screen-local `P06WeeklyStepper` and pinned by
  `p06_weekly_stepper_widget_test.dart:34`;
  `money_ledger_view_test.dart:352` audits app copy for ASCII hyphens for the
  same reason.
- Not patched here (stage 3 records, the loop fixes). Filed as
  `SHARED_REQUEST.md` §5 with the numbers; `quest_editor_copy_test.dart`'s
  `kGlyphs` excludes the minus until it lands (the file header says so).
- Why this is recorded as a finding and not an observation: the COPY rule is
  character-exact and the repo has already classified this exact class as a
  bug. It does not block P09 landing (shared code, advisory request).

### Observations (not findings)

- **ORCHESTRATOR_NOTES 17:57 item 2** (Quest name value at x ≈ 40 vs the
  design's ≈ 37) is a shared-component inset, not P09 code: the input box is
  exactly the design's `20 / 156 / 350 / 52` while its `EditableText` starts at
  x 40, i.e. 20 px in where `components.css:131` asks for 17 (1 px border + 16 px
  padding). `NestTextField`'s default variant sets
  `contentPadding: horizontal 16` (`nest_text_field.dart:303`) on top of
  Material's built-in ~4 px inset — and the same file's search variant already
  cancels it with `left: -4` (`:199`). Filed as `SHARED_REQUEST.md` §6 with the
  measured numbers, as the note asks; nothing P09 owns can move it.
- 320-wide day cells are ~35 px wide (plan §5 sanctions `Expanded` cells there:
  7×44 + 6×6 does not fit in 280). Height stays 44 and every cell responds, so
  the tap-target test asserts width ≥ 44 only from the design's 390 up.
- `pumpAppRoute` cannot re-navigate inside one test: `NestlingApp` keeps the
  router its `State` built on the first pump, so a second `pumpWidget` shows
  the previous route. Worth knowing for any future multi-route test; it is why
  the due-option tests are one `testWidgets` per option.
- While wiring the a11y suite I hit two Flutter-3.47 API details worth
  recording: `NestToggle` publishes `toggled` + `onTap` but **not** `button`,
  and enabled state is `flagsCollection.isEnabled` (`Tristate`), not
  `SemanticsData.enabled`. A control sweep must test "button **or** toggled",
  or it will miss every switch on every screen.

## 4. Notes for the next stages

- Every widget test here ends with `disposeApp(tester)`, and every semantics
  handle is disposed **inside** the test body (`flutter_test` checks for a live
  `SemanticsHandle` before tear-down callbacks run).
- Tests that pump the app need no simulator, and none was used.
- The suite is now red-proof for the fix cycle: `quest_editor_copy_test.dart`
  can add `−` to `kGlyphs` the moment `SHARED_REQUEST.md` §5 lands, and
  `p09_bugs_test.dart`'s five skipped proofs have their own assertions ready to
  un-skip.


## From 5_ui.md
# P09 — 5_ui · UI check (iteration 1, stage 5)

Route `/quest-editor`, simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots: `docs/screens/P09/ui/app_light_1.png`, `app_dark_1.png` (seed demo,
parent, maya, `DISABLE_ANIMATIONS=1`). Compare sheets: `cmp_light_1.png`,
`cmp_dark_1.png`. Design PNGs are 1170×2532 (@3x); all px below are logical
(design px ÷ 3). Status-bar glyphs excluded per orchestrator STATUS BAR rule
(design mock 9:41 vs OS 17:50). No Pip on this screen; no `NestChip` rows, no
`text-wrap: balance`, no `letter-spacing` (all correctly absent).

Note: `shot.sh` was run with an absolute OUT path
(`$PWD/docs/screens/P09/ui/…`) — the script `cd`s into the app dir before
`cp`, so the brief's relative OUT path fails with `cp: No such file or
directory`. Same screenshots, same flags otherwise.

## Mean diff

- Light: **1.71 %** (bands 0–7: 1.64 / 1.31 / 1.53 / 1.64 / 0.65 / 2.39 /
  2.13 / 2.32). Residual is text-antialias edges + status bar + icon glyphs.
- Dark: **1.60 %** (bands: 1.62 / 1.32 / 1.41 / 1.58 / 0.70 / 2.46 / 2.13 /
  1.56).

## Measured y (design vs app, logical px, top edge)

Best-fit uniform vertical shift over y 60–800 is **dy = 0 px** — no uniform
shift. Scanline edge transitions (thresholded luminance gradient, ±3x
sampling), design → app:

| Element | Design y | App y | Δ |
|---|---|---|---|
| Grabber (40×5) | 58.7–63.7 | 58.7–63.7 | 0 |
| Screen title `New quest` (text peaks) | 100.3 / 106.6 | 100.3 / 106.6 | 0 |
| First control: `Cancel` text box / Save pill | 90 / 80–124 | 90 / 80–124 | 0 |
| `Quest name` label | 136.8 | 136.8 | 0 |
| Name input (52 high) | 156.2 | 156.2 | 0 |
| `Icon` label | 207.2 | 207.2 | 0 |
| Icon tiles (6× 44×44) | 232 | 232 | 0 |
| `Who's it for?` label | 276 | 276 | 0 |
| Person pills (48 high) | 300.8 | 301.0 | 0.2 |
| Reward card (inset, 76) | 363.7 | 363.7 | 0 |
| `Repeats` label | 461.0 | 461.0 | 0 |
| Segmented track (52) | 479.7 | 479.7 | 0 |
| Day row (44) | 540.2 | 540.7 | 0.5 |
| Approval card (72) | 599.7 | 599.7 | 0 |
| Due-by card (88) | 683.7 | 683.7 | 0 |
| Due-card bottom edge | 771.7 | 771.7 | 0 |

Background/border-rect check (shapes, not text): Save pill (296/80/74/44,
Δ ≤ 0.3); name field (20/156/350/52, 0); tiles at x 20/81/142/204/265/326
(0); pills h48 anchored lefts 20/128/222 (right edges ≤ 2 wider from text
shaping, anchored edges 0); segmented track (20/480/350/52, 0) with Weekly
thumb on the third segment; day cells 44.9 wide / 50.86 pitch (≤ 0.9
cumulative, inside rule); stepper block (178/380/176/44, 0); toggle track
(303/620.5 → 354, 0); both cards (20/600/350/72 and 20/684/350/88, 0).
Side gutters exactly 20 (card edges 19.7 → 369.7 in both images, both
themes). Bottom edge: paper `[251,247,240]` at y = 830 at x = 20/195/370 in
both images — paper runs to the physical edge, no strip (OWNER bottom-edge
rule satisfied, light and dark). No overflow, clipping, or ellipsis faults
at 390 px width. Child order Maya → Leo → Anyone (creation order, correct).

Copy (visual, in order): `Cancel` · `New quest` · `Save` · `Quest name` ·
`Hoover the stairs` · `Icon` · `Who's it for?` (curly ’) · `Maya` · `Leo` ·
`Anyone` · `Reward` · `= 15p at payout` · `Repeats` · `Once` · `Daily` ·
`Weekly` · `M T W T F S S` (6th S selected, hero-bg) · `Needs my approval` ·
`Coins land after your thumbs-up` (wraps, per HTML override) · `Due by` ·
`Before tea (5pm) ›` (U+203A, ink-3). All present, all spelled/punctuated as
the HTML source. Dark-mode colours resolve via tokens throughout (cards,
tiles, pills, segmented, day cells, toggle, sheet); no hard-coded colours.

## Deviations

1. (BLOCKER — icon choice) 4 of 6 icon-picker glyphs are visibly different
   line-art from the design, in light AND dark (tile geometry itself is
   correct: 44×44, r14, 1.5 border, selected = leaf border + leaf-tint bg +
   leaf-ink glyph; only the glyph strokes differ).
   - Tile 0 `Bed`: design = flat mattress/bed-frame side view (HTML Bed
     SVG); app (`NestIcons.bed`) = lidded chest/box. Whole-tile MAE 4.5.
   - Tile 1 `Dishes`: design = handled basket (HTML Dishes SVG, reads as a
     padlock silhouette); app (`NestIcons.dishwasher`) = dishwasher/oven
     with racks. Whole-tile MAE 19.9.
   - Tile 2 `Hoover` (selected): design = canister vacuum with hose and
     wheels (HTML Hoover SVG); app (`NestIcons.hoover`) = hook/whistle-like
     loop with spout. Whole-tile MAE 20.5.
   - Tile 4 `Bins`: design = small handled case/clasp (HTML Bins SVG); app
     (`NestIcons.bin`) = rimmed trash bin. Whole-tile MAE 17.3.
   - Tiles 3 `Book` (MAE 4.1) and 5 `Paw` (MAE 1.9) match (stroke-level
     raster residue only).
   - Design value: the HTML inline-SVG glyphs shown in
     `design/screens/light|dark/P09-quest-editor.png`.
   - App value: the shared `NestIcons` glyphs listed above.
   - Fix (shared, `core/` is off-limits to this screen): redraw
     `NestIcons.bed / .dishwasher / .hoover / .bin` to match the design
     line-art (24 px, 2 px stroke, round caps). The screen-side mapping in
     `quest_editor_view.dart:230-240` is already semantically correct
     (bed→bed, dishwasher→dishwasher, hoover→hoover, book→book,
     bins→bin, paw→paw) — there is no better in-DS alternative, so the
     screen needs no code change. Filed as `SHARED_REQUEST.md` §4; blocks
     a PASS verdict until the DS glyphs land on main and are merged back.
   - A designer comparing side-by-side would reject the selected quest
     icon rendering as a different object (vacuum vs whistle-loop), so
     per the UI VERDICT RULE this is a FAIL even though every pixel of
     layout is inside ±2 px.

No other deviations. Items explicitly not findings: status-bar time/glyphs
(orchestrator rule), home-indicator pill tint (OS region), pill widths
+0.5–1.5 px and day-cell 44.9 vs 44 (anchored edges exact, inside ±2 px),
text-edge heat in the diff (antialiasing; measured text block edges ≤ 2 px).


## From 6_bugs.md
# P09 — stage 6 · FIND BUGS (iteration 1)

Tree: `881880a` (“P09: checkpoint after build (iteration 1)”) + the new test
file below. No screen code was changed — the brief forbids fixing here.

Adversarial area sweep: data edge cases (0 / 1 / 6 children, long UK names,
£0.00 / £999.99 / 9999 coins, empty lists), rapid double taps, back
navigation and deep links, Drift restart persistence, the parent/kid guard,
dark-mode contrast, 320 dp × text scale 1.3, async gaps, Europe/London
wall-clock storage, and integer-pence money.

All proofs live in `app/test/features/quests/p09_bugs_test.dart`. Each bug
proof is `skip: true` (bug id in the group name) so the suite stays green;
run them with `--run-skipped` to see them fail. Every probe in the
“attacks that hold” group runs unskipped.

## Summary

| id | severity | one-liner | failing test (group › test) |
|---|---|---|---|
| BUG-P09-1 | **major** | payout helper hard-codes 1p/coin and ignores the family’s `coinValuePencePerCoin` | `BUG-P09-1 — the payout helper ignores the family coin value` › `a 2p-per-coin family still reads "= 15p at payout"` |
| BUG-P09-2 | **major** | double-tap **Save** creates the quest twice (no in-flight guard) | `BUG-P09-2 — double-tap Save creates the quest twice` › `two Save taps before the router frame make two quests` |
| BUG-P09-3 | minor | a quest icon outside the six tiles (`plate`, `shirt`, `sofa`, `bag`, `leaf`) shows no selected tile | `BUG-P09-3 — a quest icon outside the six tiles has no selection` › `editing q-table (icon "plate") selects no tile` |
| BUG-P09-4 | minor | out-of-range stored coins (9999 / 0) cannot be restored once the stepper touches them | `BUG-P09-4 — out-of-range stored coins cannot be restored` › `a 9999-coin quest drops to 9998 with no way back` |
| BUG-P09-5 | minor | a quest assigned to a removed child shows no selected pill; Save keeps the orphan id | `BUG-P09-5 — a removed child leaves an orphaned assignee` › `q-bed assigned to deleted Leo shows no selected pill` |

---

## BUG-P09-1 — major — the payout helper ignores the family coin value

**Where:** `app/lib/features/quests/presentation/views/quest_editor_view.dart`
— `const int _pencePerCoin = 1` (line 249) feeding
`'= ${_coins * _pencePerCoin}p at payout'` (line 652).

**Why it is wrong:** the reward helper is the screen’s only money figure and
the plan (§1-5) says it “derives from `families.coinValuePencePerCoin`”.
The column is real, variable data: the schema carries it, P06’s setup screen
reads it, and P06 pins the exact opposite behaviour for the same column
(“the coin value string follows the database, not the design”,
`pocket_money_setup_view_test.dart:1944`). P09 prints 15p for a family whose
stored rate is 2p/coin — the database value the orchestrator’s DATA-over-mocks
rule says is correct. Reachability note: every shipped seed writes 1, and no
current UI writes a different value, so the wrong figure is latent today; it
becomes wrong the moment any flow (P06/P16, a migration or a seed variant)
stores another rate.

**Repro:**
```dart
final db = await setUpTestScope();
await (db.update(db.families)..where((f) => f.id.equals(Seed.familyId)))
    .write(const FamiliesCompanion(coinValuePencePerCoin: Value(2)));
await pumpAppRoute(tester, QuestsRoutePaths.editor);
// 15 coins × 2p = 30p
expect(find.text('= 30p at payout'), findsOneWidget); // FAILS
```
Expected `= 30p at payout`; actual `= 15p at payout`.

**Suggested fix:** read the rate from the database instead of the constant —
e.g. add a read-only `Stream<int>/Future<int> coinValuePencePerCoin()` to
`QuestsRepository` (feature-local, backed by the `families` row) and render
`coins * rate`; or read it through the existing read-only
`SettingsRepository.watchSettings()` / `FamilyRepository` import the way the
view already imports `family/domain` read-only. Update the widget test that
asserts `= 15p at payout` to keep the demo-seed case (rate 1) and add the 2p
case.

## BUG-P09-2 — major — double-tap Save creates the quest twice

**Where:** `_QuestEditorSheetState._save`
(`quest_editor_view.dart:345`) and the header call site
`QuestSavePill(onPressed: _canSave ? _save : null)` (line 540). `_save`
never consults `state.editorStatus`, and the pill stays enabled while
`QuestEditorStatus.saving`.

**Why it is wrong:** two taps that land before the router frame replaces the
editor both dispatch `QuestsCreateRequested`; `_save` mints the id from
`DateTime.now().millisecondsSinceEpoch` per call, so the two inserts get
different ids and both land — the parent gets two identical quests. (A
same-millisecond pair instead collides on the primary key and surfaces as a
save failure.) This is the same defect class the P10 hunt rated major
(double-tap stacking two editor routes).

**Repro:**
```dart
await pumpAppRoute(tester, QuestsRoutePaths.editor);
await tester.enterText(find.byType(TextField).first, 'Double tap quest');
await tester.tap(find.text('Save'));
await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
await tester.tap(find.text('Save'));
// settle, then read the DB
expect(quests.where((q) => q.title == 'Double tap quest').length, 1); // FAILS: 2
```
Actual: two rows, ids `q-…540` and `q-…548` (proven in a scratch diagnostic).

**Suggested fix:** guard the save in the sheet (`bool _saving = false;`
early-return + set, cleared on the bloc’s failure emission) **and** disable the
pill while `state.editorStatus == QuestEditorStatus.saving`
(`onPressed: null`), so both the visual control and the handler are safe.
Keep the `failure` path re-enabling it.

## BUG-P09-3 — minor — a quest icon outside the six tiles shows no selection

**Where:** `_questIcons` (`quest_editor_view.dart:228`) + the selection test
`selected == option.key || option.aliases.contains(selected)` (line 554).

**Why it is wrong:** the seed stores ten distinct icon keys
(`plate`, `shirt`, `sofa`, `bag`, `leaf`, …) but the picker has six tiles and
only one alias (`bins` → `bin`). Editing `q-table` (`plate`), `q-washing`
(`shirt`), `q-living` (`sofa`), `q-bag` (`bag`) or `q-plants` (`leaf`) renders
the whole `role="radiogroup"` with **no checked tile**, so the parent cannot
see the quest’s current icon (and screen readers announce no selection). The
icon is preserved on save, so this is a visible-state/a11y defect, not data
loss.

**Repro:** `pumpAppRoute('/quest-editor?id=q-table')`; count
`QuestIconTile.selected` → expected 1, actual 0.

**Suggested fix:** extend the alias map so every icon the DB can hold maps to
a tile, or render the stored icon as an extra selected tile when it is not one
of the six; the durable fix is to align the seed’s icon vocabulary with the
six-tile picker (shared/seed change → SHARED_REQUEST, orchestrator-owned).

## BUG-P09-4 — minor — out-of-range stored coins cannot be restored

**Where:** `_coins` initialised straight from the row (line 269) with button
bounds `onDecrease: _coins > 1` / `onIncrease: _coins < 100` (lines 666–667).

**Why it is wrong:** the stepper clamps only its buttons. A stored value
outside the design’s 1–100 range is displayed and can be moved one step, but
never back: a 9999-coin quest drops to 9998 and `+` is dead (9998 is not
< 100); a 0-coin quest can be raised to 1 but never returned to 0. The editor
neither clamps the stored data nor offers a representation for it, so a single
mis-tap permanently rewrites an existing value.

**Repro:** insert a quest with `coins: 9999`, open `?id=q-9999`, tap
`decrease`; `find.text('9998')` passes, then
`NestStepper.onIncrease` is null → the test expects it non-null and fails.

**Suggested fix:** clamp on load (`_coins = quest.coins.clamp(1, 100)`, the
same repair the rest of the app does for out-of-range data) or size the upper
bound to `max(100, storedValue)` so the stored value stays reachable; add a
repo-level range check so such rows cannot be written.

## BUG-P09-5 — minor — a removed child leaves an orphaned assignee

**Where:** `_assignee` seeded from the row (line 300) and
`_effectiveAssignee` (line 287); `FamilyRepository.removeChild` deletes the
child without touching `quests.assigneeChildId`.

**Why it is wrong:** after a child is removed, editing one of their quests
shows the pill row with **nothing selected** (`_assignee` matches no pill and
is not `_anyone`), and Save writes the dead id straight back — the quest stays
assigned to a child who no longer exists, with no visual indication.

**Repro:** `removeChild('leo')`, open `?id=q-bed` (assigned to Leo); count
selected `QuestPersonPill` → expected 1, actual 0.

**Suggested fix:** once the roster is loaded, treat an assignee that matches
no child as `_anyone` (fall back and let Save clear the id), or show a
selected “Anyone” fallback; a cascade/reassign belongs in the family feature
(SHARED_REQUEST, orchestrator-owned).

---

## Attacks that hold (probes, unskipped — 12 tests)

- **Double-tap `Delete quest`** → one confirm modal: the first tap pushes the
  dialog route synchronously, so the modal barrier is the hit-test target for
  the second tap and the framework swallows it.
- **Double-tap `Due by`** → one option sheet (same modal-barrier protection).
- **Restart persistence:** save → dispose the app → new `NestlingApp` over
  the same Drift DB → the quest is on the library’s Active tab.
- **Parent/kid guard:** kid mode + `/quest-editor` lands on
  `/parental-gate`; the editor never builds.
- **320 dp × text scale 1.3**, new and edit mode: no overflow/exception.
- **Six children with long names** (`Maximilian-Alexander`,
  `Annabella-Rose`, `Cassandra-Jane`, `Fitzwilliam`) at 320 × 1.3: pills wrap,
  creation order preserved (Maya, Leo, then the added children, `Anyone`
  last).
- **One-child family:** the new quest defaults to that child.
- **Dark mode:** the Save pill’s `--surface` on `--leaf` pair keeps ≥ 4.5:1
  contrast.
- **Back navigation:** a quest pushed from Today (`?questId=`) → Cancel
  returns to `/today`.
- **Zone/BST:** with the family moved to `Asia/Dubai`, the due time is still
  stored as the wall-clock string `17:00` (`dueLabel` `Before tea (5pm)`).
- **Due-sheet a11y:** all three rows expose `SemanticsAction.tap`, and
  `performAction(tap)` moves the real due label (and the saved `HH:MM`).
- **Delete modal a11y:** `Keep it` and `Delete` expose tap; `Keep it` driven
  through semantics keeps the Drift row.

Existing suites already cover the other listed edges: 0 children / `Seed.empty`
(`quest_editor_view_test.dart` — Anyone only), unknown `?id=` → “Quest not
found”, blank title disables Save, weekly-with-no-days blocks Save.

## Verification

```
$ dart format --set-exit-if-changed test/features/quests/p09_bugs_test.dart
Formatted 1 file (0 changed)
$ flutter analyze test/features/quests/p09_bugs_test.dart
No issues found!
$ flutter test test/features/quests/p09_bugs_test.dart
00:02 +12 ~5: All tests passed!        # 12 probes pass, 5 bug proofs skipped
$ flutter test test/features/quests/p09_bugs_test.dart --run-skipped
+12 -5: Some tests failed              # the five BUG-P09-* proofs fail as documented
```

No simulator was booted, installed on, screenshotted or driven; `flutter
clean` was never run; no `// ignore:` and no shared file was touched.

**Out of scope (process, not findings):** the worktree also carries other
stages’ uncommitted work (`quest_editor_a11y_test.dart`,
`quest_editor_states_test.dart`, `4_review.md`, `5_ui.md`, `ui/`). It was left
untouched. At the time of writing, two of that file’s tests fail for
test-side reasons (it expects `NestToggle`’s node to carry the `isButton`
flag — Flutter’s switch role is `toggled` + `onTap`, which is what the
component publishes — and it compares `Tristate.isSelected` to a `bool`); they
are not P09 screen defects and are that stage’s to resolve.

