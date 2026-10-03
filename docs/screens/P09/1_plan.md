# P09 — New / edit quest · plan (stage 1)

Route: `/quest-editor` (parent mode, top-level route — no tab bar).
Sources: `design/html-source/screens/P09-quest-editor.html`,
`design/screens/light|dark/P09-quest-editor.png` (÷3 → logical px),
DESIGN_SPEC §5 P09, SPACING_SPEC §§2,3,6,8,9.
No `docs/screens/P09/ORCHESTRATOR_NOTES.md` exists (checked) — only the
global orchestrator rules apply. No Pip appears on this screen (PIP rule n/a).
No `text-wrap: balance` in P09 CSS → no `NestBalancedText`.
No `letter-spacing` in P09 CSS → keep `NestType` default 0 everywhere.
No `NestChip` rows (person pills and day cells are custom, not chips).

## 0. Copy (byte-for-byte from the HTML source — builder: do not retype)

`Cancel` · `New quest` / `Edit quest` (edit title, see §3) · `Save` ·
`Quest name` · `Hoover the stairs` · `Icon` ·
`Who's it for?` (copy the ’ exactly as in the HTML file) ·
`Maya` · `Leo` · `Anyone` · `Reward` · `= 15p at payout`
(dynamic: `= {coins}p at payout`) · `Repeats` · `Once` · `Daily` · `Weekly` ·
day cells `M T W T F S S` · `Needs my approval` ·
`Coins land after your thumbs-up` · `Due by` · `Before tea (5pm)` + `›`
(ink-3 chevron) · due-sheet options (§2 item 9) · edit-only `Delete quest`,
confirm modal `Delete this quest?` / `Delete` / `Keep it`.
UK spelling throughout. Never import `google_fonts`.

## 1. Widget tree, top → bottom (tokens only, never hard-code colours/sizes)

- `Scaffold(backgroundColor: tokens.paper)` — the sheet runs to the physical
  bottom edge (OWNER bottom-edge rule: paper-to-edge, never a surface-2 strip
  under the sheet). `NestStatusBar.new()` (height reserve only).
- Body: `Container(color: tokens.surface2)` full-bleed → sheet `Container`
  (`color: tokens.paper`, `borderRadius: NestRadii.topXl` = 32 top, 0 bottom,
  `constraints: minHeight = viewport height`, so surface-2 never shows below).
  Sheet padding `8,20,50` (top 8, sides 20 = `padSide`, bottom = homeH 34 + 16 —
  mirror `NestBottomSheet` padding, but build the column locally because the
  header is a custom 3-part row, not title+close; do NOT reuse
  `NestBottomSheet(title:)`).
- Scroll: `SingleChildScrollView` (content can exceed 844 with keyboard open;
  `resizeToAvoidBottomInset: true`). Column, `crossAxisAlignment: stretch`.
- 1. Header row (`sheet-top`: `padding 4,0,8`, row space-between, center):
  `Cancel` text button (min 44×44, `NestType.bodyStrong(ink2)` 16 w600 —
  HTML `.cancel`) · title `New quest` (`NestType.h3`, 18/24 w800, Flexible +
  ellipsis) · `_SavePill` (screen-local: min 64×44, radius pill, bg leaf /
  fg surface, 16 w700, horizontal padding 18; disabled → `opacity .45`,
  `onTap: null`). Semantics: buttons `Cancel`, `Save`.
- 2. `NestTextField(label: 'Quest name', controller: titleController)`
  (52 high, radius 16, focus ring per DS). Initial text `Hoover the stairs`
  for new; edit mode pre-fills from the quest (see §3).
- 3. `SizedBox(16)`. Label `Icon` (`.lbl`: 13/18 w600 ink2) + `SizedBox(6)` +
  icon grid: `Row(mainAxisAlignment: spaceBetween)` of 6 × 44×44 tiles
  (radius 14, border 1.5; unselected: border line, bg surface, icon ink2;
  selected: border leaf, bg leaf-tint, icon leaf-ink), icon 24 via `NestIcon`.
  Icons in order with `NestIcons`: `bed` (Bed), `dishwasher` (Dishes),
  `hoover` (Hoover, selected by default), `book` (Book), `bin` (Bins),
  `paw` (Paw). `Semantics(container: true, label: 'Quest icon')`, each tile
  `button: true, selected: …, label: 'Icon: Hoover'` etc. Narrow-width rule
  (320): tiles wrap — use `Wrap(spacing: 8, runSpacing: 8)` instead of `Row`
  so 6×44+5×8=304 overflow cannot happen on 280 content width (wrap to two
  rows; design order preserved).
- 4. `SizedBox(16)`. Label `Who's it for?` + `SizedBox(6)` + `Wrap(spacing 8,
  runSpacing 8)` of person pills (screen-local `_PersonPill`, NOT `NestChip`):
  height 48, `padding 4,14,4,4`, radius pill, border 1.5 line / bg surface,
  text 15 w600 ink; selected: border leaf, bg leaf-tint, text leaf-ink.
  Maya pill leading `NestAvatar(M, s32, lilac)`, Leo `NestAvatar(L, s32,
  peach)`, `Anyone` no avatar. Single-select, default = first child (Maya).
  Source: `StreamBuilder` on `sl<FamilyRepository>().watchChildren()`
  (creation order = Maya, Leo — never sort); `Anyone` appended last.
  `assigneeChildId`: child id or null. Semantics button + selected.
- 5. `SizedBox(16)`. `NestCard(variant: inset)`: row space-between center —
  left `Column`: `Reward` (16 w600 ink) + `= {n}p at payout` (13/18 ink2,
  `softWrap: false`, ellipsis); right `NestStepper(valueText: '$coins',
  decreaseSemanticLabel: 'Decrease reward',
  increaseSemanticLabel: 'Increase reward')`. Coins range 1–100, default 15;
  minus disabled at 1 (stepper handles opacity). Helper derives from
  `families.coinValuePencePerCoin` (=1): `= {coins}p at payout`.
- 6. `SizedBox(16)`. Label `Repeats` + `SizedBox(6)` +
  `NestSegmented<String>(options: Once/Daily/Weekly, value: repeat,
  semanticLabel: 'Repeats')`, default `weekly`. If `repeat == 'weekly'`:
  `SizedBox(8)` + `NestDayPicker(days: [M,T,W,T,F,S,S], selected: {5},
  semanticLabel: 'Repeat days')` (Saturday index 5 selected by default;
  index i ↔ CSV value i+1, Mon..Sun). Hidden for Once/Daily.
- 7. `SizedBox(16)`. `NestCard(variant: standard)`: row space-between —
  left Flexible `Column`: `Needs my approval` (16 w600) + sub
  `Coins land after your thumbs-up` (13/18 ink2, wraps, NOT nowrap —
  HTML overrides `.ss` with `white-space:normal` here) + right
  `NestToggle(value: needsApproval, semanticLabel: 'Needs my approval')`,
  default true.
- 8. `SizedBox(12)`. `NestCard(variant: standard)`: `InkWell` due row
  (min-height 56, semantics button `Change due time`): left `Due by`
  (16 w600) + right row: value `Before tea (5pm)` (15 w600) + ` ›` chevron
  (ink-3). Toggles a local option; tap opens `showNestBottomSheet` with 3
  fixed rows (`Before school (8:30am)` → dueTimeLocal `08:30`;
  `Before tea (5pm)` → `17:00`, default; `Before bed (7:30pm)` →
  `19:30`); `dueLabel` + `dueTimeLocal` stored verbatim on the quest.
- 9. Edit mode only: `SizedBox(16)` + `NestButton.dangerGhost('Delete quest')`
  full width (52 high). Tap → `NestModal` confirm (`Delete this quest?`,
  buttons `Keep it` ghost + `Delete` danger) → `QuestsDeleteRequested` →
  `context.go(QuestsRoutePaths.library)`. (DESIGN_SPEC: “Delete not shown
  for new” ⇒ edit shows it; this is an assumption, recorded here.)
- Dark mode: everything resolves via `context.nest` tokens; day-cell selected
  uses heroBg/onHero (both themes); Save pill leaf/surface per tokens.

## 2. BLoC + repository (local Drift via existing repo — no new tables)

- `QuestsBloc` (same file, new handlers; `emit.forEach` load unchanged):
  - `QuestsLoadRequested` (existing).
  - `QuestsCreateRequested(Quest quest)` → `repository.createQuest` →
    `editorStatus: saving`, then `saved`.
  - `QuestsUpdateRequested(Quest quest)` → `repository.updateQuest` → saved.
  - `QuestsDeleteRequested(String id)` → `repository.deleteQuest` → saved.
- `QuestsState` adds `editorStatus: initial/saving/saved/failure` +
  `editorError` (copyWith-extended; existing `items` stream untouched).
- Form draft state (title, icon, assignee, coins, repeat, days, approval, due)
  lives in the `StatefulWidget` form, NOT the bloc. `Quest` entity fields map
  1:1: `title`, `icon` key, `coins`, `repeatRule` (once/daily/weekly),
  `days` CSV (`''` unless weekly), `dueLabel`, `dueTimeLocal`, `needsApproval`,
  `assigneeChildId` (null = Anyone), `active: true`. New id: `q-<ms epoch>`.
- Validation: Save enabled iff `title.trim().isNotEmpty &&
  (repeat != 'weekly' || days.isNotEmpty)`. No inline errors except: if
  weekly && days empty, show caption `Pick at least one day` (danger, w600)
  under the day row.
- Family data: read-only `FamilyRepository.watchChildren()` via GetIt in the
  view (`StreamBuilder`); NEVER edit `family/` files.

## 3. Interactions + navigation (route constants)

- Entry: `QuestsRoutePaths.editor` = `/quest-editor`. Add optional query
  `?id=<questId>` in `quests_routes.dart` (feature-local, allowed):
  `state.uri.queryParameters['id']`. No id → new mode (defaults above).
  With id → edit mode: title `Edit quest`, pre-fill via
  `repository.getQuest(id)` (`FutureBuilder`; id unknown → `Quest not found`
  + `Back to quests` ghost → `/quests`). Pass the loaded quest into the form
  as `initialQuest`.
- `Cancel` → `context.canPop() ? context.pop() :
  context.go(QuestsRoutePaths.library)`.
- `Save` (valid) → create/update → `context.go(QuestsRoutePaths.library)`
  (`/quests`). Route file change: parse `id` query only; no `app/` edits.
- Icon tile / person pill / segmented / day cell / stepper / toggle / due row:
  local `setState` only.
- P10/P08b entry points (other screens' plans) use `/quest-editor` and
  `/quest-editor?id=<id>` — this plan defines that contract.

## 4. Empty / loading / failure states

- Route-level `QuestsLoadRequested`: initial/loading →
  `Center(CircularProgressIndicator)`; failure → centered
  `state.errorMessage ?? 'Something went wrong'` + `NestButton.ghost(
  'Try again')` re-adding `QuestsLoadRequested`.
- Edit-id fetch: loading spinner; unknown id → `Quest not found` + back
  button (above). No other empty state (a form always renders).
- Save failure (`editorStatus.failure`) → `NestToast` with `editorError`.
- `Seed.empty()` (no children): assignee row shows `Anyone` only.

## 5. Accessibility

- Semantics: header title `header: true`; every control labelled (§1);
  icon radiogroup pattern; save/cancel buttons; due row button;
  day cells via `NestDayPicker`; error caption in a live region.
- Tap targets ≥ 44 everywhere: icon tiles 44, pills 48, day cells 44
  (NestDayPicker), stepper 44, toggle 44 wrapper, Save 64×44, Cancel 44×44,
  due row 56.
- Text scale 1.3 (app clamps 1.0–1.3): person-pill text `Flexible` +
  ellipsis; day cells `FittedBox scaleDown` (built-in); Save/Cancel +
  title in Flexible header; reward helper ellipsis; approval sub wraps.
- Width 320: icon tiles `Wrap` (no 304-px overflow); `NestDayPicker`
  Expanded cells; pills wrap; sheet keeps 20 px gutters; long quest titles
  ellipsis in the field (single line).
- Contrast: ink-2 labels, leaf-ink on leaf-tint selections — token pairs,
  both themes.

## 6. Test plan (`app/test/features/quests/`, no `google_fonts` anywhere)

- `quest_editor_bloc_test.dart`: create/update/delete call the repo and move
  `editorStatus` initial→saving→saved; repo error → failure + message.
- `quest_editor_view_test.dart` (via `setUpTestScope(seedDemo: true)` +
  `pumpAppRoute(tester, '/quest-editor')`, end with `disposeApp(tester)`):
  defaults — field `Hoover the stairs`, hoover tile selected, Maya pill
  selected, `15` + `= 15p at payout`, Weekly + Saturday selected, approval
  ON, `Before tea (5pm)`; light + dark pump without error.
- Interactions: stepper + → `16`/`= 16p at payout`; repeat Once hides day
  row; blank title disables Save; weekly + deselect-all disables Save and
  shows `Pick at least one day`; Save persists via repo and lands on
  `/quests`; Cancel returns; `/quest-editor?id=q-hoover` pre-fills edit mode
  (`Edit quest` + `Delete quest` present); delete → confirm → gone from repo.
- A11y/robustness: 320-wide surface pumps with no overflow; textScaler 1.3
  pumps with no overflow; tap 5 px above/below day cells still toggles
  (hit area); child order Maya-then-Leo.
- `dart format .`, `flutter analyze` (no issues), `flutter test` all pass.

## 7. SHARED_REQUEST

None. Icons (`bed`, `dishwasher`, `hoover`, `book`, `bin`, `paw`), avatars,
stepper, segmented, day picker, toggle, cards, bottom sheet, modal, toast all
exist in `app/lib/core/design_system/`. Children come from the existing
`FamilyRepository.watchChildren()` (read-only import, no edits outside
`quests/` + this doc dir). Route query param is feature-local
(`quests_routes.dart`). No schema, seed, DI, or router-shell change needed.

VERDICT: PASS
