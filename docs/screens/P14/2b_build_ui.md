# P14 · Rewards manager — Stage 2b build UI (iteration 1)

Owner: UI builder. Layer: `app/lib/features/rewards/presentation/views/**` +
`presentation/widgets/**`, plus the view/widget tests in
`app/test/features/rewards/`. No `domain/`, `data/` or `bloc/` file was touched,
and no shared code outside the feature.

## CONTRACT USED

Re-read `docs/screens/P14/2a_build_logic.md` before finishing: **CONTRACT CHANGES
— None.** The view is coded against the plan §2 events exactly
(`RewardsNeedsOkChanged(id, needsOk)`, `RewardsCreateRequested(title, coinPrice,
needsOk, icon)`, `RewardsUpdateRequested(reward)`, `RewardsDeleteRequested(id)`,
`RewardsLoadRequested`) and the unchanged `RewardsStatus{initial,loading,loaded,
failure}` / `RewardsState(items, errorMessage)`.

## Files

- `app/lib/features/rewards/presentation/views/rewards_view.dart` — replaced the
  placeholder AppBar/ListTile scaffold with the real screen (nav + intro + card
  list + `+ New reward`, plus loading / empty / failure states) and the
  `openRewardEditor()` sheet entry point.
- `app/lib/features/rewards/presentation/widgets/p14_reward_meta.dart` (new) —
  icon→asset/tint map, the two verbatim `aria-label` maps (approval subject,
  shortened edit labels) and every screen string in `RewardCopy`.
- `app/lib/features/rewards/presentation/widgets/p14_reward_card.dart` (new) —
  the `.rw` card and the `.editbtn`.
- `app/lib/features/rewards/presentation/widgets/p14_reward_editor_sheet.dart`
  (new) — create/edit form body for the in-feature bottom sheet.
- `app/lib/features/rewards/presentation/widgets/rewards_placeholder_card.dart`
  **deleted** — unreferenced foundation placeholder.
- `app/test/features/rewards/rewards_view_test.dart` (new, 8 tests) and
  `app/test/features/rewards/reward_card_widget_test.dart` (new, 4 tests).

## Geometry — measured, not assumed

All rects measured off `design/screens/light/P14-rewards.png` (÷3) and then
asserted in `reward_card_widget_test.dart`; the implementation lands on them:

| element | design | implementation |
|---|---|---|
| card | x 20→370 (350), y 167→289 (**122**) | 350 × 122 at x 20 |
| tile | 40×40 at x 32→72, y 208→248 (centred) | 40×40, radius 12, icon 24 |
| name | x 84, 15/21 w700, 1 line ellipsis | `bodySmallStrong.copyWith(w700, 21/15)` |
| coin pill | x 84, **y 200→225 (25)**, icon 15, pad 5/9, gap 6 | `NestCoinPill(xSmall)` |
| `.okrow` | x 84, y 233→277 (44), label 84→169, gap 10 | `ConstrainedBox(minHeight 44)` + row |
| toggle track | **x 179→230** (51×31) in a 59-wide hit box | x 179.3→230.3 |
| edit button | **x 314→358, 44×44**, radius 12, 1 px line | 44×44, radius 12, surface fill |
| card pitch | 138 (122 + 16) | 16 between `.scroll` children |
| `+ New reward` | full width, 52 high | `NestButton.secondary` |

Three layout decisions that needed measurement rather than the plan's sketch:

1. **No 2 px gap between the name and the coin pill.** The plan §1 sketches
   `padding-top: 2`, but the render puts the pill's top edge at exactly
   `card.top + 12 + 21` and the card's total height is exactly 122 = 12 + 21 +
   **25** + 8 + 44 + 12. A 2 px gap would make it 124. The pill is 25, not 23,
   because `.coin-pill` has `line-height: 1`, so the 15 px coin icon is the
   tallest child of the 5 px-padded row — `NestCoinPill(xSmall)` reproduces that
   for free.
2. **`IntrinsicWidth` around `.okrow`.** CSS `.okrow` is a shrink-to-fit flex row
   (`flex: 0 1 auto`), so the switch must sit right after the label at x 179. A
   plain `Flexible` in a max-size `Row` hands the paragraph its whole share as a
   max width and the label expands, pushing the track to x 237. `IntrinsicWidth`
   + `Flexible` (loose by default) reproduces `0 1 auto`: shrink-to-fit normally,
   capped at the column width at 320 px / 1.3 scale where the label ellipsizes.
   This is the ALIGNMENT rule in code.
3. **`Transform.translate(-4)` on `NestToggle`.** `NestToggle` centres the 51×31
   track inside a 59 px hit box — the Flutter equivalent of
   `.toggle::before { left:-4; right:-4 }`. Shifting the widget back that 4 px
   puts the visible track on the design's `gap: 10` edge while the hit area
   still covers it (measured 179.3 vs the design's 179).

## Owner / orchestrator rules applied

- **BOTTOM EDGE** — no bottom bar, tab bar or CTA panel on this screen, and the
  `Scaffold` paints `tokens.paper` to the physical edge, so no strip can appear
  below the last child. The editor sheet is a `NestBottomSheet` (radius 32 top,
  `paper` fill), so it also runs to the edge.
- **ALIGNMENT** — everything hangs off one 20 px `ListView` gutter; card, tile,
  middle column and edit button share the card's 12 px padding edges; the
  rects above are asserted, not eyeballed.
- **DATA OVER MOCKS** — the list is the `watchItems` stream in
  `coinPrice ASC`: **six** rows 50/60/80/90/100/150, including `Choose dinner`
  at 90, which the HTML/PNGs omit. All six toggles render ON because every
  seeded `needsOk` is true (the PNGs draw “Baking together” off). Nothing is
  hard-coded from the designs.
- **COPY** — every string is a constant in `p14_reward_meta.dart` typed from the
  HTML: em dash U+2014 in the intro and the empty state, `é` in
  `Trip to the park café`, ASCII `+` in `+ New reward`, and the two shortened
  `aria-label`s copied verbatim (`Edit Stay up later`, `Edit Trip to the park
  cafe` — no accent, unlike the visible title).
- **FONTS / LETTER SPACING / CHIP ROWS / BALANCED HEADINGS** — N/A or
  untouched: no `google_fonts`, no `letterSpacing` override (this screen's CSS
  sets none, so `NestType` defaults apply), no `NestChip` rows, no
  `text-wrap: balance` on this screen.
- **TRIAL / CHILD ORDER / PIP / PERIODS** — N/A for P14 (no subscription
  writes, no children, no Pip, no quests).
- **ACCESSIBILITY ACTIONS** — every control exposes `SemanticsAction.tap`:
  nav `Back` (from `NestNavBar`), each row's `NestToggle`
  (`label: 'Needs approval for …'`, `toggled:`, `enabled:`, `onTap:`), each
  edit (`Edit {name}` with `onTap:` on the `Semantics` node — the `Ink` is
  `ExcludeSemantics`), `+ New reward`, and every sheet control (field, stepper
  −/+, switch, Save/Cancel/Delete). A test asserts the tap action on Back, a
  toggle, an edit button and `+ New reward`.
- **UI CHECK MEASURES SHAPES** — the widget test asserts the card, tile, coin
  pill, toggle-track and edit-button **background rects**, not text positions,
  and checks the edit button's fill is `surface` (not `paper`) with a 1 px
  `line` border and radius 12.
- **SIMULATORS** — none used at any point in this stage.

## Design-system components only

`NestStatusBar`, `NestNavBar(compact:)`, `NestCard`-style `Container` with
`tokens.cardShadow`, `NestCoinPill(xSmall)`, `NestToggle`, `NestButton`,
`NestTextField`, `NestStepper`, `NestBottomSheet`/`showNestBottomSheet`,
`NestEmptyState`, `NestIcon`, `NestIcons`, and the `NestTokens`/`NestSpacing`/
`NestRadii`/`NestType` tokens. The only hand-built widgets are the two the
design system has no shape for: the `.rw` card (a three-part row with a coin
pill and a switch) and `.editbtn` (a **44×44 radius-12 rectangle** — deliberately
not `NestIconButton`, which is circular and would paint the wrong background
rect).

## Editor sheet

In-feature `showModalBottomSheet` — there is no `/rewards/editor` route in the
route table. Title `New reward` / `Edit reward` (18/24 w800), `Name` field,
`Price in coins` + `NestStepper` (step 5, floor 5, `50 coins` default) +
`= {n} p at payout` helper, a `Needs my OK` switch, Save (primary), Cancel
(ghost) and Delete (dangerGhost, edit only). Delete needs **two taps**: the
first arms it and relabels the button `Confirm delete`, the second deletes, so
no destructive write is one stray tap away. Cancel/`Back` dismisses with no
write. Defaults for a new reward: price 50, `needsOk` true, `gift` icon; Save
sends `RewardsCreateRequested`, and an empty name leaves Save disabled.

## Verification

- `dart format lib/features/rewards test/features/rewards` → clean.
- `flutter analyze lib/features/rewards test/features/rewards` → **No issues
  found** (no ignores left in the tree; the one temporary `// ignore` added
  during development was removed by deleting the redundant argument instead).
- `flutter test test/features/rewards/` → **All tests passed (33/33)** — the 8
  view tests and 4 widget tests below plus the logic builder's 21 bloc and
  repository tests.
  - `rewards_view_test.dart`: nav title + exact intro; six cards in DB order
    with exact names/prices and every toggle ON; exact coin amounts and no
    overflow in **dark**; `SemanticsAction.tap` on Back / toggle / edit /
    `+ New reward`; a toggle tap writes through to the DB **and a tap 5 px above
    the 51×31 track flips it back**; edit → prefilled sheet → Save writes →
    Delete arms then removes; `+ New reward` creates with the sheet defaults
    (`reward-…` id, 50 coins, `needsOk` true) while Cancel writes nothing; an
    empty DB shows `No rewards yet` and still opens the sheet; a stream failure
    shows the message and `Try again`.
  - `reward_card_widget_test.dart`: every rect in the table above at 390 px; the
    edit button's 44×44 background, `surface` fill, 1 px border and radius 12;
    **320 px width at 1.3 text scale** with no overflow and the toggle/edit
    rects intact; unknown icon strings falling back to the neutral gift tile.
- No whole-app `flutter test`, no `shot.sh`, no simulator — the integrator and
  the UI-check stage own those.

### Two test-harness notes worth carrying forward

- **Widget tests do not load the bundled families.** `reward_card_widget_test`
  loads Inter/Nunito through `FontLoader` in `setUpAll` (the pattern in
  `test/core/design_system/nest_chip_test.dart`). Without it the fallback font
  makes “Needs my OK” 143 px wide instead of 85 and every text-derived rect
  assertion is meaningless — worth copying into any future screen test that
  asserts horizontal positions.
- **Do not `await bloc.close()` on a bloc whose `emit.forEach` is fed a
  mocktail stream** in these tests — it never completes and the test hangs for
  the full 10-minute timeout. Likewise prefer bounded `pump()`s over
  `pumpAndSettle()` anywhere a `loading` state can park the indeterminate
  spinner.

## LEFT FOR NEXT ITERATION

1. **Inline error caption in the editor sheet.** Plan §4 asks for a `danger`
   13/18 w600 caption above Save when a sheet *write* fails. The BLoC contract
   (2a: “CONTRACT CHANGES — None”) reports failure on the stream state, but the
   sheet is a separate route, so `BlocBuilder` in the view cannot rebuild it and
   `close()`-time races make a state-watching sheet fragile. The sheet therefore
   dismisses on Save and the failure surfaces on the list. Surfacing it needs a
   per-write result channel (e.g. `RewardsCreateRequested` returning a
   `Future`/emitting an `errorMessage` the sheet can read, or the sheet taking
   an `errorText` parameter driven by a `BlocListener`). **This is a contract
   question for the logic builder / orchestrator, not a view-only change.**
2. **Keyboard robustness of the sheet.** The body is a plain
   `Column(mainAxisSize: min)` (the `showNestBottomSheet` precedent in
   `gallery_overlays.dart`), which measures ~560 px against a 776 px cap. If a
   real device keyboard shrinks the sheet below that, the body will need to
   scroll; `NestBottomSheet`'s `Column(mainAxisSize: min)` passes unbounded
   height to its child, so the fix is not a bare `SingleChildScrollView`.
   Not reproducible in the current widget tests.
3. **Light/dark screenshot comparison** (`shot.sh` + `compare.py`) is the UI
   stage's job; the widget tests cover the geometry numerically but no render
   has been diffed against the PNGs yet.
4. `Reward.detail` is still carried but unused by P14 (price shows in the coin
   pill), per plan §2 — left alone.

VERDICT: PASS