# P15 · Child profile — Stage 2b (build, UI chunk) — iteration 1

Route `/child-profile` · parent mode · feature `family` · owner: UI layer only
(`presentation/views/**`, `presentation/widgets/**`, and the P15 view tests).

## What landed

| File | Change |
|---|---|
| `app/lib/features/family/presentation/views/child_profile_view.dart` | Replaced the placeholder scaffold. Status switch (spinner / failure + `Try again` / no-children / loaded), `BlocListener` that surfaces `errorMessage` as a `NestToast`, `Scaffold(backgroundColor: tokens.paper)`. No nav bar, no back button, no bottom CTA (the design is a tab-branch root; the tab bar and bottom edge stay with the shared `ParentShell`). |
| `app/lib/features/family/presentation/widgets/child_profile_body.dart` | The scrolled body: pinned `NestStatusBar` + `ListView(padSide 20 / bottom 32, 16 px gaps)` holding the hero card, the 3-up stats row, the Pip card, the `NestList` of three rows and the danger card — plus the remove-confirmation modal. |
| `app/lib/features/family/presentation/widgets/child_profile_copy.dart` | Every P15 string, composed from the HTML source's characters (U+00B7, U+2013 via `displayAgeBand`, U+203A, U+00A3) and the stage-name / percentage helpers. |
| `app/test/features/family/child_profile_view_test.dart` | 12 widget tests: design band geometry, exact copy, the Pip slot, navigation, `SemanticsAction.tap`, the remove flow, 320 px and text scale 1.3. All green; every pump ends with `disposeApp(tester)`. |

No domain / data / bloc / route file was touched.

## Geometry (measured from the design PNG ÷ 3, pinned by tests)

```
47      NestStatusBar (reserves 47; OS draws the glyphs)
47…211  hero card       164  20 + 64 avatar + 10 + 30 (24/30 h1) + 20 + 20
227…309 stat tiles       82  12 + 26 (22/26 value) + 2×16 label + 12
325…441 Pip card        116  16 + 84 slot + 16
457…637 list of 3 rows  180  3 × 60 (tile 40 + padding 10/10 + 40 text column)
653…733 danger card      80  16 + 48 + 16  (the design frame clips it at 727)
```

Stat tiles: 110 wide, 10 gap (fractional, never fixed), all three equal height
via `IntrinsicHeight` + a stretching row — a CSS grid item stretches to the
tallest sibling, which is the tile whose "Quests this week" label wraps.
Gutters: every band starts at 20 and ends at 370 (ALIGNMENT rule asserted).

## Owner-rule checks

- **PIP** — the Pip card renders `PipAvatar(style/skin/accessory from the row,
  stage 3, size 84)` in the design's 84 px slot at x 36; the v1
  `pip_stage_3.svg` is never used. Removing Maya falls through to Leo and the
  slot switches to bolt · sky · stage 2 (asserted). No-children uses
  `PipAvatar(mochi, stage 1)` at 140.
- **DATA OVER MOCKS** — the design's "18 quests this week" and "3 daily,
  3 weekly" are mocks. The screen renders the bloc's numbers: Maya shows
  `4` (completions in the current period), `120` coins, `4` happy days and
  `6 active · 4 daily, 2 weekly`; the test asserts those exact strings.
- **STATUS BAR** — `NestStatusBar` only reserves height.
- **BOTTOM EDGE** — nothing of this screen's paints below the tab bar:
  `NestTabBar` already runs its `surface` to the physical edge
  (`nest_tab_bar.dart:29-51`, outer `Container(color: tokens.surface)` around
  the `SafeArea`). No strip, light or dark. Nothing to file.
- **ALIGNMENT** — asserted above.
- **CHILD ORDER** — the roster order comes from the repository (creation
  order); the profile's fall-through after a removal is asserted (Maya → Leo).
- **COPY** — `Age 7–9 · Pip is a Fledgling`, `Pip · Fledgling`,
  `175 of 250 · 70%`, `On · Maya knows their code`, `Change ›`, `›`,
  `£3.00 a week · Owed £4.20`, `Remove Maya from family`,
  `Remove Maya?`, `They will lose their quests, coins and Pip. This cannot be
  undone.` — asserted character-for-character in the test (U+2013, U+00B7,
  U+203A, U+00A3).
- **FONTS / LETTER SPACING** — no `google_fonts`; every style is a
  `NestType` base with an explicit `copyWith` for the screen-local sizes.
  No tracking added anywhere (the P15 CSS sets none).
- **BALANCED HEADINGS** — the P15 CSS block styles `.hero h1` locally and, as
  shown, sets NO `text-wrap: balance` (only the `.h1` class does, and P15 does
  not use that class). The name is one short line, so it renders as a plain
  `Text` — `NestBalancedText` is deliberately not used here.
- **CHIP ROWS** — P15 has no chips.
- **ACCESSIBILITY ACTIONS** — the three rows (`NestListRow.onTap`), the danger
  button (`NestButton`), the modal's two buttons and the empty-state CTA all
  expose `SemanticsAction.tap`; the test asserts the action on each and that
  `performAction(tap)` on the Money row really navigates to `/money`. The only
  `Semantics` wrapper with `image:` (the Pip) is not interactive and needs no
  action. No `Semantics(excludeSemantics: true)` is used on a control.
- **TRIAL / SUBSCRIPTION** — not touched by this screen.

## Deltas from `1_plan.md` (all deliberate, all in the UI layer)

1. **PIN subtitle pronoun** — `knows their code`, as the plan already
   recorded: the schema stores no gender. The HTML says "her".
2. **Pip semantics label** — `"Maya's Pip, a fledgling"` (P08's wording)
   instead of the plan's `"Maya's Pip, a Fledgling"`: the capitalised stage
   name is right for the visible copy but the article would mis-announce
   stage 1 ("a Egg"). `child_profile_copy.dart` keeps the two spellings apart
   (`pipStageName` for copy, `pipStagePhrase` for the label).
3. **Hero avatar has no semantic label** — the initial is the first letter of
   the name printed directly beneath it, so a label would announce "Maya, M".
   P05's kid cards already omit it.
4. **Confirm dialog lives in the body widget**, not the view — it needs the
   `FamilyChild`, which the body already holds. The bloc is read *before*
   `showNestModal`: the dialog is a sibling route on the app Navigator, so its
   own context sits above this route's `BlocProvider`.
5. **Stat value uses `NestType.kidName` + tabular figures** — that style is
   exactly Nunito 900 at 22/26, the design's `.stat .v` (with `.num`).

## Contract used

Coded against `1_plan.md` §(b)/(c) and the bloc contract the logic builder
landed while this stage ran: `FamilyState.profile` (`ChildProfile`:
`child`, `questsThisWeek`, `dailyActive`, `weeklyActive`, `onceActive`,
`owedPence`) and `FamilyRemoveChildRequested(childId)`. No view-side change is
needed for the logic builder's `watchProfile` switch-semantics fix (its note
in `family_repository_impl.dart:63-71` is data-layer only). `2a_build_logic.md`
was re-read at the end of this stage: **CONTRACT CHANGES: None** — every
public name this layer uses (`ChildProfile`, `FamilyState.profile`,
`FamilyRemoveChildRequested(childId)`) matches what shipped, so no view-side
follow-up is needed.

## Verification run in this stage

```
flutter analyze lib/features/family test/features/family → No issues found
dart format lib/features/family test/features/family → clean
flutter test test/features/family → 161/161 pass
```

No simulator was booted, installed on or screenshotted (stage 2b must not).
`shot.sh` + `compare.py` are the UI stage's job; the bands above give it the
expected numbers.

## Cross-builder hand-back (see `2a_build_logic.md`)

The logic builder listed three `add_children_test.dart` tests as failing
"because the P15 placeholder is gone" and handed the fix to the UI side
("view-owned assertions"). They located the destination screen by the
placeholder title `'P15 Child profile'`; this stage replaced all four
occurrences (lines 652, 655, 1299, 1638) with
`find.byKey(const Key('p15-hero'))`, the real screen's hero card. No other
assertion, expectation or test name in that file changed, and the whole
`test/features/family` suite is green (161 tests).

## LEFT FOR NEXT ITERATION

1. **UI-stage comparison** — verify the render against
   `design/screens/{light,dark}/P15-child-profile.png` with
   `tools/screens/compare.py`; the expected y positions are in the table
   above. Watch the danger card: the design frame clips it at 727 while the
   scroll viewport shows all 80 px once scrolled.
3. **Bottom-edge / alignment pass in both themes** (owner rules) — the tab bar
   is shared code, so if a strip appears it is a SHARED_REQUEST, not a fix
   here.
4. Text-scale 1.3 and 320 px are proven overflow-free, but no screenshot was
   taken at either; the UI stage may want to eyeball them.

VERDICT: PASS
