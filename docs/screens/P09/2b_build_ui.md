# P09 — 2b build, UI chunk (iteration 1)

## Files written (UI layer only)

- `app/lib/features/quests/presentation/views/quest_editor_view.dart` —
  the screen (rewrite of the placeholder): `Scaffold` + `NestStatusBar` +
  full-height sheet over the surface-2 backdrop, the edit-mode
  `FutureBuilder`, the load-failure state, and the private
  `_QuestEditorSheet` state that owns the form draft (title, icon,
  assignee, coins, repeat, days, approval, due) + save/delete.
- `app/lib/features/quests/presentation/widgets/quest_editor_widgets.dart`
  (new) — screen-local `QuestEditorLabel` (`.lbl`), `QuestCancelButton`,
  `QuestSavePill`, `QuestIconTile` (`.ic`), `QuestPersonPill` (`.person`),
  `QuestDueOptionRow`, plus `QuestEditorMetrics` (the four P09-only sizes
  with their CSS source) and `questCardTitle()` (`.switchrow .tt` 16/22 w600).
- `app/test/features/quests/quest_editor_view_test.dart` (new, 27 tests).

No files outside `presentation/views/**`, `presentation/widgets/**` and
`app/test/features/quests/*view*.dart` were touched. No
`google_fonts`/`GoogleFonts.*` anywhere; every colour and size resolves
through `context.nest` / `NestType` / `NestSpacing` / `NestDevice` /
`NestRadii`.

## Coded against the logic layer's contract (`2a_build_logic.md`)

`QuestEditorStatus` (`initial/saving/saved/failure`) + `state.editorError`,
`QuestsCreateRequested` / `QuestsUpdateRequested` / `QuestsDeleteRequested`,
and `QuestsEditorQuery.questId` (`'id'`) read through
`GoRouterState.of(context).uri.queryParameters`. No contract changes needed.

## Design geometry used (measured off `design/screens/light/P09-quest-editor.png`, ÷3)

| Element | Measured (logical px) | Built as |
|---|---|---|
| sheet | y 47 → 844, radius 32, paper to the physical edge | `Container(paper, NestRadii.topXl)` inside `ConstrainedBox(minHeight: viewport)` over a `surface2` `ColoredBox` |
| grabber `.sheet::before` | 40×5, y 59–64 (4 above / 12 below) | `s1` + 40×5 line pill + `s3` |
| header row | y 80–124 (`padding 4 0 8`) | `Padding(4,0,8)` + `Row` |
| Cancel `.cancel` | 16 w600 ink-2, glyphs x 27–78 | `NestType.bodyStrong(ink2).copyWith(w600)` + 6px side padding (the browser `<button>` padding, so the centred title lands where the design has it) |
| Save `.save` | x 296–370, 74×44, leaf bg / `--surface` text, radius pill | `QuestSavePill` (min 64×44, `padding 0 18`, `buttonLabel(surface)`, disabled opacity .45) |
| field `.field` | label 132–150, input x 20 w 350 y 156 h 52 r 16 | `NestTextField(label: 'Quest name')` |
| `Icon` `.lbl` | 208–226 (flush under the field — the design stacks them with no margin) | `QuestEditorLabel` + `SizedBox(6)` |
| icon tiles `.ic` | 44×44 r 14, x 20/81/142/204/265/326, y 232–276, border 1.5 line | `Row(spaceBetween)` (falls back to `Wrap` below 304px) + `QuestIconTile` |
| `Who's it for?` `.lbl` | 276–294; pills y 300–348 (48) at x 20 w 100 / 128 w 86 / 222 w 76, gap 8 | `QuestEditorLabel` + `Wrap(8)` + `QuestPersonPill` (`4 14 4 4`, `s32` avatar) |
| Reward `.card.inset` | x 20 w 350 y 364 h 76 | `NestCard(inset)` + `Row` + `Expanded(Column)` + `NestStepper` |
| `Repeats` `.lbl` | 456–474; segmented y 480 h 52; day row y 540–584 | `QuestEditorLabel` + `NestSegmented` + `SizedBox(8)` + `NestDayPicker` |
| approval `.card` | x 20 w 350 y 600 h 72; toggle 51×31 | `NestCard` + `Expanded(Column)` + `NestToggle` |
| due `.card` | x 20 w 350 y 684 h 88 (`.due` min-height 56) | `NestCard(onTap:)` + `ConstrainedBox(minHeight: 56)` + `Text.rich` (label + `' ›'` in ink-3) |
| sheet bottom | padding 50 (`home-h 34 + 16`), paper to the edge | `EdgeInsets.fromLTRB(20, 8, 20, homeH + s4)` |

Owner rules applied: the sheet is `paper` down to the physical bottom edge
(no surface-2 strip under anything, light or dark); every block sits on the
same 20px gutters (20 → 370, confirmed against the measured card rects);
children come from `FamilyRepository.watchChildren()` in creation order
(never sorted) with `Anyone` appended last; copy is character-exact
(`Who's it for?` with the curly apostrophe, `= {n}p at payout`,
`Coins land after your thumbs-up`, `Before tea (5pm) ›`).

## Deliberate deviations (recorded, not silent)

1. **Loading state.** Plan §4 asks for a spinner while
   `QuestsLoadRequested` is `initial`/`loading`. The editor never reads
   `QuestsState.items`, so the form renders immediately and only a `failure`
   swaps in the error row (`Try again`). A spinner here would blank a form
   whose data is already local, and would flash on the Drift stream's first
   frame. Edit mode still shows its own spinner while `getQuest` resolves.
2. **`NestSegmented` is 8px shorter than the design** (component: 44
   container / 36 thumb; design + SPACING_SPEC: 52 / 44). The component is
   reused as required — filed as `docs/screens/P09/SHARED_REQUEST.md`. Until
   it lands, the Repeats section and everything below it sits 8px higher
   than the design PNG. Nothing else in the screen is affected above it.
3. **`NestTextField` is 54 tall** (24 line + 2×14 padding + 2 borders) where
   `.field input` is 52. Same shared component, so 2px of drift under the
   field; not filed separately because it affects every screen that uses
   `NestTextField` and the fix belongs to the design-system owner.

## Accessibility

Semantics: `Cancel`/`Save` buttons, `header: true` on the title and the
three group labels, `Icon: <name>` radio buttons with `selected`, person
pills as single-select buttons, `Repeats`/`Repeat days` groups, stepper
`Increase/Decrease reward`, `Needs my approval` toggle, `Change due time`
button on the due row, and `Pick at least one day` in a live region. Tap
targets: icon tiles 44, person pills 48, day cells 44 (via
`NestDayPicker`), stepper 44, toggle 44 (`NestToggle` wrapper), Cancel
44×44, Save 64×44, due row 56. Text scale 1.3 and a 320-wide surface are
covered by tests.

## Verification (UI layer only)

- `dart format` clean.
- `flutter analyze lib/features/quests test/features/quests` → No issues
  found.
- `flutter test test/features/quests/quest_editor_view_test.dart` →
  **27 tests, all passing**: new-quest defaults, hoover/Maya selection,
  Saturday-only, child order, stepper both ways, repeat switching, Save gating
  on a blank title and on an empty weekly selection, `Pick at least one day`,
  day-cell edges, icon/person single-select, toggle, due sheet, Cancel, Save →
  persisted row + `/quests`, edit pre-fill from `q-hoover`, update in place,
  unknown id → `Quest not found`, delete keep/confirm, empty family, dark
  mode, 320 wide, text scale 1.3, and a **design-geometry** group asserting
  the rects measured off the PNG — 44×44 icon tile, 48-tall person pill,
  44-tall Save flush to 370, cards at x 20 / w 350 / h 76 and 88.
- No simulator used (stage 5 owns that).

### Two real bugs the suite caught (both fixed in the view)

1. **Infinite rebuild loop.** `StreamBuilder(stream: …watchChildren())` built
   a *new* Drift stream on every build, so every `setState` resubscribed and
   re-emitted — the sheet rebuilt forever and `pumpAndSettle` never settled.
   The stream is now one `late final` field for the editor's lifetime, and
   the "first child by default" choice is derived (`_effectiveAssignee`)
   rather than assigned during build.
2. **Border drawn outside the box.** `Ink(decoration: BoxDecoration(border:))`
   insets its child by the border width, so the icon tile measured 47×47 and
   the person pill 51 tall. Both now paint the hairline with `Material.shape`
   (no inset) and carry the extra 1.5 in their padding — CSS border-box
   behaviour: exactly 44×44 and 48.

## Notes for the UI check (stage 5)

- The measured y-coordinates assume the 47px status bar, which is what
  `NestStatusBar` reserves with no system inset. On a simulator with a taller
  system status bar the whole sheet shifts down by the same amount — compare
  bands, not absolutes.
- **In edit mode the Delete button sits below the fold** at 844px (the sheet
  grows by the 16 gap + 52 button) and the sheet scrolls; the widget test
  uses `scrollUntilVisible`. Expected, not a defect.
- The 6px side padding on `QuestCancelButton` is deliberate: the design's
  `.cancel` is a bare `<button>`, so its glyphs start 6px inside the button
  box (x 26) — that is what centres `New quest` where the design has it
  (x 146→236).
- `QuestEditorMetrics` holds the only P09 sizes with no token —
  `iconTileRadius` 14, `hairline` 1.5, `savePadding` 18, `dueRowMinHeight` 56,
  `cancelPadding` 6 — each with its CSS source.
- Widget tests use a fixed-width box per glyph, so any horizontal position
  assertion there is meaningless; the geometry test therefore asserts sizes,
  gutters and heights only.

## LEFT FOR NEXT ITERATION

- Re-check the Repeats block against the screenshot once the
  `NestSegmented` fix lands (or re-file if the orchestrator declines).
- If the UI check measures the day cells at 44.86 rather than 44, that is
  `NestDayPicker`'s `Expanded` + 6px gaps versus `.dayrow`'s
  `space-between` (7px effective gaps) — a design-system call, not a
  screen fix.
- The due-time sheet and the delete-confirm modal have no P09 design frame;
  their copy comes from the plan. A design pass could add them.
- `families.coinValuePencePerCoin` is not exposed to the view layer (it is a
  column on `families`, not part of `FamilyRepository`), so the reward helper
  uses the documented constant `1` — the value every seed sets. If that
  becomes configurable, expose it and replace `_pencePerCoin`.
VERDICT: PASS
