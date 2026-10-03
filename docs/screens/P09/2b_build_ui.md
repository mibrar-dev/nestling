# P09 — 2b build, UI chunk (iteration 1 of this run)

The screen was already implemented (iteration-1/2 of the earlier loop run), so
this stage re-verified the whole UI layer against the design PNGs **with the
real bundled fonts loaded**, fixed the one shape that missed the ±2 px rule,
and turned the throwaway probe into a permanent geometry proof.

## Files changed (UI layer only)

- `app/lib/features/quests/presentation/widgets/quest_editor_widgets.dart` —
  new `QuestEditorMetrics.toggleTrackOffset` = `Offset(4, -2)` with its CSS
  derivation (`.toggle::before { left/right: -4px; top/bottom: -7px }`).
- `app/lib/features/quests/presentation/views/quest_editor_view.dart` —
  the approval toggle is wrapped in `Transform.translate(...toggleTrackOffset)`
  so the painted 51×31 track lands on the design rect; the grabber gets
  `ValueKey('quest-editor-grabber')`; the icon row gets the plan §1-3
  `Semantics(container: true, label: 'Quest icon')` radiogroup wrapper.
- `app/test/features/quests/quest_editor_view_geometry_test.dart` (new, 5
  tests) — real-font, absolute design-rect proof.
- `app/test/features/quests/quest_editor_view_test.dart` — the toggle
  assertion now encodes the design truth (hit box overhangs to 358, painted
  track flush at 354) instead of the old, wrong "box right == 354".
- `app/test/features/quests/quest_editor_view_probe_test.dart` — **deleted**
  (its numbers are now assertions).
- `docs/screens/P09/SHARED_REQUEST.md` — the `NestSegmented` request is marked
  **resolved** (it landed on main in `8ad0cdc`); a non-blocking advisory was
  added for `NestToggle`'s track/hit-area asymmetry.

No files outside `presentation/views/**`, `presentation/widgets/**`,
`app/test/features/quests/*view*.dart` and `docs/screens/P09/**` were touched.
No `google_fonts`/`GoogleFonts.*`; every colour/size resolves through
`context.nest` / `NestType` / `NestSpacing` / `NestDevice` / `NestRadii`.

## Contract (re-read `2a_build_logic.md`, iteration 3)

`QuestEditorStatus.initial/saving/saved/failure` + `state.editorError`,
`QuestsCreateRequested` / `QuestsUpdateRequested` / `QuestsDeleteRequested`,
edit id via `GoRouterState.of(context).uri.queryParameters['id']`
(`QuestsEditorQuery.questId`), plus P10's additive `ideas` (ignored here).
**No contract changes** — the view needed none.

## Design geometry — measured off `design/screens/light/P09-quest-editor.png` (÷3) vs the app, both at 390×844 with the bundled faces

`x / y / w / h`, logical px. Design values are pixel measurements (plus the
CSS cross-check in parentheses). **Every row is inside ±2 px.**

| Element | Design | App | Δ |
|---|---|---|---|
| sheet (paper, to the physical edge) | 0 / 47 / 390 / 797 | 0 / 47 / 390 / 797 | 0 |
| grabber `.sheet::before` | 175 / 59 / 40 / 5 | 175 / 59 / 40 / 5 | 0 |
| `.cancel` text box (ink 27→78.7) | 26 / 90 / – / 24 | 26 / 90 / 53.7 / 24 | 0 |
| title `New quest` box (ink 146.3→236.3) | 145 / 90 / 91 / 24 | 145 / 90 / 91.3 / 24 | ≤0.3 |
| `.save` pill | 296 / 80 / 74 / 44 | 295.7 / 80 / 74.3 / 44 | ≤0.3 |
| `Quest name` label | 20 / 132 / – / 18 | 20 / 132 / 75.5 / 18 | 0 |
| name input `.field input` | 20 / 156 / 350 / 52 | 20 / 156 / 350 / 52 | 0 |
| `Icon` label (flush under the field) | 20 / 208 / – / 18 | 20 / 208 / 350 / 18 | 0 |
| 6 × `.ic` (space-between, 61.2 pitch) | 20 / 81.2 / 142.4 / 203.6 / 264.8 / 326, y 232, 44×44 | identical | 0 |
| `Who's it for?` label | 20 / 276 / – / 18 | 20 / 276 / 350 / 18 | 0 |
| `.person` ×3 (48 tall, 8 gaps) | 20/128/222, y 300, 100/86/76 | 20/128.5/224, y 300, 100.5/87.5/76.6 | ≤2 (see note) |
| `.card.inset` Reward | 20 / 364 / 350 / 76 | 20 / 364 / 350 / 76 | 0 |
| `Reward` title / helper | 36 / 382 / 58×22 · 36 / 404 / 94×18 | same | 0 |
| `.stepper` (44 + 12 + 64 + 12 + 44) | 178 / 380 / 176 / 44 | 178 / 380 / 176 / 44 | 0 |
| `Repeats` label | 20 / 456 / – / 18 | 20 / 456 / 350 / 18 | 0 |
| `.segmented` track | 20 / 480 / 350 / 52 | 20 / 480 / 350 / 52 | 0 |
| tab label centres Once/Daily/Weekly | 79.7 / 195 / 310.3 | 79.7 / 195.1 / 310.4 | ≤0.1 |
| `.dayrow` (7 × 44) | 20 + i·51, y 540, 44×44 | 20 + i·50.86, y 540, 44.9×44 | ≤0.9 |
| `.card` Needs my approval | 20 / 600 / 350 / 72 | 20 / 600 / 350 / 72 | 0 |
| approval title / sub | 36 / 618 / 148.7×22 · 36 / 640 / 198.9×18 | same | 0 |
| `.toggle` **track** (51×31) | 303 / 620.5 · right 354 | 303 / 620.5 · right 354 | 0 (**fixed**) |
| `.card` Due by | 20 / 684 / 350 / 88 | 20 / 684 / 350 / 88 | 0 |
| `Due by` / value row | 36 / 717 · value ink ends 353 | 36 / 717 · box right 354 | ≤1 |
| bottom edge | paper at y=843 | paper at y=843 | 0 |

Owner rules re-checked on the geometry: 20 px side gutters everywhere
(20 → 370, nothing a few px off); the segmented thumb occupies the design's
third segment (254.7 → 366, y 484 → 528); the sheet's paper runs to the
physical bottom edge in light **and** dark (no `--surface-2` strip, nothing
around the home indicator); no `NestChip` rows and no `text-wrap: balance`
heading on this screen, so `NestChipWrap` / `NestBalancedText` are correctly
absent; no `letter-spacing` anywhere (the P09 CSS sets none), so every
`NestType` style is used untouched; no Pip on this screen.

## The one real defect this iteration found and fixed

`NestToggle` is a 59×44 box (the CSS `::before` hit area, 51+8 / 31+13) that
**centres** the 51×31 track inside it. The design hangs its hit area around a
track that is **flush with the row's content edge**: measured on the PNG the
track is x 303 → 354, y 620.5 → 651.5 and only the invisible hit area reaches
358. The screen rendered the visible switch at x 299 → 350, y 622.5 → 653.5 —
**4 px short of the content edge and 2 px low**, i.e. an alignment failure
under the owner's rule and 4 px outside the ±2 px verdict.

Fix without touching `core/` or re-implementing the component: the view
wraps `NestToggle` in `Transform.translate(Offset(4, -2))`
(`QuestEditorMetrics.toggleTrackOffset`). The painted track is now exactly
x 303 → 354, y 620.5 → 651.5; the 44 px tap target only moves into the card's
own 16 px padding, which is where the CSS `::before` overhang sits anyway. A
cleaner component-side fix is filed as a non-blocking advisory in
`SHARED_REQUEST.md`.

## Deliberate deviations (recorded, not silent)

1. **No spinner for `QuestsLoadRequested`** (plan §4 asks for one). The editor
   never reads `QuestsState.items`, so the form's data is local; a spinner
   would blank a fully populated form and flash on the Drift stream's first
   frame. Only a `failure` swaps in the error row + `Try again`. Edit mode
   still shows its own spinner while `getQuest` resolves.
2. **Person-pill labels are the nicknames, not `For Maya`** (plan §1-4 wrote
   `label: 'For Maya'`). The design HTML puts no `aria-label` on `.person`, so
   its accessible name is the visible text; the view excludes the subtree (so
   the avatar initial does not merge into "M\nMaya") and labels the node with
   the design-truth name.
3. **Day cells are 44.9 wide, 50.86 apart** (design: 44 wide, 51 apart).
   `.dayrow` is `justify-content: space-between` (7 px effective gaps);
   `NestDayPicker` is the shared component and shares the width over
   `Expanded` cells with 6 px gaps. Worst-case edge error 0.86 px, inside the
   rule; fixing it means changing a component P10/K03 also use.
4. **`QuestEditorMetrics` still holds the four P09 sizes with no token**
   (`iconTileRadius` 14, `hairline` 1.5, `savePadding` 18,
   `dueRowMinHeight` 56, `cancelPadding` 6) plus `toggleTrackOffset`, each
   with its CSS source in the doc comment.
5. **The due-time sheet and the delete-confirm modal have no P09 design
   frame**; their copy comes from plan §§1-8 (`Before school (8:30am)`,
   `Before tea (5pm)`, `Before bed (7:30pm)`; `Delete this quest?` / `Keep it`
   / `Delete`). A design pass could add them.
6. **`quest.detail` is written as `Weekly · 15 coins` on save.** P10 renders
   that column as the active-quest meta line and the seed leaves it empty, so
   a saved quest gains a meta line. It is derived from the form (repeat +
   coins), so it follows the DATA-over-mocks rule; noted here because it is
   the one place the editor writes a denormalised string.

## Verification (UI layer only)

- `dart format --set-exit-if-changed lib/features/quests/presentation
  test/features/quests` → clean.
- `flutter analyze lib/features/quests test/features/quests` → **No issues
  found** (no ignores added).
- `flutter test test/features/quests` → **255 tests, all pass** (35 view +
  5 new real-font geometry + the feature's bloc/repository/P10 suites).
  No simulator was booted (stage 5 owns that); no whole-app `flutter test`.

### What the geometry test adds over the existing view suite

`quest_editor_view_test.dart` measures with the widget-test font, where every
glyph is one em wide: the assignee pills wrap to a second row and every
text-bearing rect below them drifts ~56 px, so that file can only assert
sizes, gutters and block-to-block deltas. The new file loads the bundled
Inter/Nunito through `FontLoader` (the same technique as `p10_bugs_test.dart`)
and asserts **absolute** design coordinates for all 30 visible elements, in
light and dark, plus the bottom-edge rule and the icon radiogroup.

## Notes for the UI check (stage 5)

- The numbers above assume the 47 px `NestStatusBar` reserve. On a simulator
  with a taller system status bar the whole sheet shifts down by the same
  amount — compare bands, not absolutes.
- In edit mode the `Delete quest` button sits below the fold at 844 px (the
  sheet grows by the 16 gap + the 52-high button) and the sheet scrolls.
  Expected, not a defect; the widget test uses `scrollUntilVisible`.
- Expect two text-metric residues that are not layout bugs: the pill widths
  run 0.5–1.5 px wider than the browser render (`Anyone` right edge 300.6 vs
  the design's 298), and `.day` cells are 0.86 px narrower per step. Both come
  from the shared components/text shaping, both are inside ±2 px on every
  anchored edge (pill lefts, row start, row end), and neither can be corrected
  without editing `core/`.
- Copy to compare character-by-character: `Cancel`, `New quest` / `Edit quest`,
  `Save`, `Quest name`, `Hoover the stairs`, `Icon`, `Who’s it for?` (curly
  apostrophe), `Maya`, `Leo`, `Anyone`, `Reward`, `= 15p at payout`,
  `Repeats`, `Once`, `Daily`, `Weekly`, `M T W T F S S`,
  `Needs my approval`, `Coins land after your thumbs-up`, `Due by`,
  `Before tea (5pm) ›` (U+203A, ink-3), and in edit mode `Delete quest`.

## LEFT FOR NEXT ITERATION

- Nothing outstanding in the UI layer: every design element is inside ±2 px
  and the shape proofs run with real fonts.
- Optional, needs a shared change (`core/`, out of bounds here): make
  `NestToggle` expose its 51×31 track as the layout box with the hit area as
  an overhang, so call sites align the visible switch by ordinary layout and
  `toggleTrackOffset` can be deleted (filed in `SHARED_REQUEST.md` §2).
- Optional, needs a design frame: the due-time sheet and the delete-confirm
  modal.

VERDICT: PASS
