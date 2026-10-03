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

VERDICT: FAIL