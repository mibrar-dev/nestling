# P14 · Rewards manager — Stage 4 QA code review (iteration 1)

Reviewer scope: `git diff main...HEAD` (23 files) against `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P14, `docs/design/SPACING_SPEC.md`,
`1_plan.md`, the design PNGs/HTML, and the orchestrator's owner rules. **No code was
edited.** One major finding → FAIL.

Commands run (no simulator booted, installed on, driven or screenshotted):

```
flutter analyze                                    → No issues found! (ran in 2.7s)
flutter test test/features/rewards/{rewards_view_test,reward_card_widget_test,
                 rewards_bloc_test,rewards_repository_test}.dart   → 00:01 +33: All tests passed!
dart format (checked by 2_build, tree unchanged since)
git diff main...HEAD --name-only                   → only features/rewards/**, test/features/rewards/**, docs/screens/P14/**
```

---

## 1. Findings

### 1. MAJOR — a failed write throws away the editor's input and replaces the whole list with a raw exception string

`app/lib/features/rewards/presentation/widgets/p14_reward_editor_sheet.dart:58-70`
· `app/lib/features/rewards/presentation/bloc/rewards_bloc.dart:38-113`
· `app/lib/features/rewards/presentation/views/rewards_view.dart:50-53`, `:180`

`_submit()` calls `widget.onSave(...)` (which only `bloc.add`s the event) and then
`_close()` unconditionally — the sheet is gone before the write resolves. The four
write handlers report failure by emitting `RewardsStatus.failure` with
`error.toString()`. The view's `failure` branch ignores `state.items` and renders
`_RewardsFailure(message: state.errorMessage)`, so one failed row write produces:

1. the typed name/price/needsOk are lost with no warning (nothing is written);
2. the entire reward list is replaced by a 16 px body paragraph containing the raw
   Dart/Drift exception (`Exception: …`, `SqliteException(1): no such table: …`);
3. the screen stays stuck there until the user taps `Try again`, because a failed
   write produces no new stream emission.

`1_plan.md` §4 specifies the opposite behaviour: *"Sheet write failure: keep sheet
open, show inline error caption (`danger`, 13/18 w600) above Save."* That is not
implemented, and both stage notes (`2b_build_ui.md`, `2_build.md`) park it as an
"orchestrator call". It is not: RULES §1 puts `presentation/bloc/**` in this
screen's editable set, so the fix does not need shared code or a plan-contract
change.

**Concrete fix (all inside `features/rewards/**`):**

1. Give each write event an optional result channel, e.g. add
   `final Completer<void>? result;` to `RewardsNeedsOkChanged`,
   `RewardsCreateRequested`, `RewardsUpdateRequested`, `RewardsDeleteRequested`
   (`rewards_event.dart`).
2. In the four handlers, on error: complete the error path —
   `event.result?.completeError(error)` after the existing `emit.isDone` guard —
   and **stop emitting `failure`** for action writes. A failed toggle must not
   replace the list. Keep the stream's own error (`_onLoadRequested`) as the only
   source of the full-screen `failure` state, which is what `Try again` is for.
3. `_submit()` becomes async: `await` the completer inside `try/catch`; on error
   `setState(() => _errorText = RewardCopy.saveError)` and **do not pop**; render
   the caption above Save with `NestType.fieldLabel(color: tokens.danger)` (13/18
   w600 — the plan's spec) or hand it to `NestTextField(errorText:)`, which already
   paints a danger caption + 2 px danger border (`nest_text_field.dart:13-17`).
   Disable Save while the write is in flight so a double tap cannot create two rows.
4. Test: failing repo → open the edit sheet → Save → sheet still open, danger
   caption visible, DB row unchanged, and the list behind is still the loaded list.

The same fix removes finding 2.

### 2. MINOR — the failure screen shows a raw exception as user copy

`app/lib/features/rewards/presentation/views/rewards_view.dart:179-185`

`message ?? RewardCopy.loadError` puts `error.toString()` in body copy. The
reviewed precedent in this repo is the opposite: `paywall_view.dart:200-207` shows
static copy only and comments *"The technical message stays in `state.errorMessage`
for action-failure toasts."* (`add_children_view.dart:171` still does the raw thing,
so this is not a house-wide rule — but P07 is the newer decision and it is the
correct one.) Fix: render `RewardCopy.loadError` and keep the technical string for
the toast/log introduced in finding 1.

### 3. MINOR — a trailing 16 px spacer the design does not have

`app/lib/features/rewards/presentation/views/rewards_view.dart:86-89`

`.scroll` in `P14-rewards.html:10` is `padding-bottom:66px` with
`.scroll > * + * { margin-top:16px }` (`components.css:65-66`) — no gap after the
last child. `_RewardsScroll` appends `SizedBox(height: NestSpacing.s4)`, so with the
list scrolled to the end the `+ New reward` button's bottom edge lands 82 px above
the physical bottom edge, while the design puts it 100 px above (66 + the 34 px
`.home-indicator` band that the app draws from the OS). The 34 px home-reserve
difference is app-wide (P03/P05/P06 share it) and not P14's to fix; the extra 16 px
is. Fix: delete the spacer (the padding already carries the space), or if it is
meant to stand in for the home reserve, make it explicit and documented
(`66 + NestDevice.homeH`). Stage 5 must measure this with the button in view.

### 4. MINOR — `Center` cannot centre inside the scroll, so empty/failure sit at the top

`app/lib/features/rewards/presentation/views/rewards_view.dart:150`, `:174`

`ListView` children get an unbounded main-axis constraint, so `Center` shrink-wraps
and the empty state / failure state render directly under the nav bar with only
`NestEmptyState`'s own 24 px padding — not "centred in the scroll" as plan §4
describes. Fix: `LayoutBuilder(builder: (_, c) => ConstrainedBox(constraints:
BoxConstraints(minHeight: c.maxHeight), child: Center(...)))`, or drop the `Center`
and let it sit at the top deliberately.

### 5. MINOR — sheet copy and two literals that have tokens

`app/lib/features/rewards/presentation/widgets/p14_reward_editor_sheet.dart:92`,
`:98`, `:99`, `:102-103`, `:109`, `:111` · `p14_reward_card.dart:160`

`'Name'`, `'Price in coins'`, `'Decrease price'`, `'Increase price'`,
`'= $_price p at payout'` are inline in the sheet while every other screen string
lives in `RewardCopy` (`p14_reward_meta.dart:70-99`) — copy is now split across two
files and cannot be diffed against the HTML in one place. `const SizedBox(height: 6)`
twice (`:99`, `:109`) should be `NestSpacing.gap6`, and `const size = 44.0`
(`p14_reward_card.dart:160`) should be `NestDevice.tapParent`, the token the same
file already uses for the 44 tap box 20 lines above.

### 6. MINOR — `onDelete` force-unwraps a nullable

`app/lib/features/rewards/presentation/views/rewards_view.dart:229`

`onDelete: () => bloc.add(RewardsDeleteRequested(id: reward!))` on a *required*
callback: unreachable today (the sheet only renders Delete when `reward != null`),
but a `reward == null` call throws. Fix:
`onDelete: reward == null ? () {} : () => bloc.add(RewardsDeleteRequested(id: reward.id))`.

### 7. MINOR — a11y coverage stops at `hasAction`; no `performAction`, no sheet controls

`app/test/features/rewards/rewards_view_test.dart:134-157`

The committed test asserts `hasAction(SemanticsAction.tap)` for four labels (Back,
one toggle, one edit, `+ New reward`) and proves the DB write with `tester.tap`,
never with `tester.semantics.performAction(finder, SemanticsAction.tap)`. The
orchestrator rule asks for both halves, and P06 sets the precedent
(`pocket_money_setup_view_test.dart:3113-3160`, "performAction(tap) … writes the DB").
Untested for semantics: every sheet control (name field, stepper ±, sheet toggle,
Save/Cancel/Delete), the empty-state button and `Try again`. Fix: add one test that
`performAction(tap)` on a toggle and on an edit button writes through to the DB, and
one that walks the open sheet's controls asserting `hasAction` (Save must pass no tap
and report `enabled: false` while the name is empty).

### 8. MINOR — test hygiene: no `disposeApp`, shared mock

`app/test/features/rewards/rewards_view_test.dart:22`, `:315-345`

The last test never calls `disposeApp(tester)` (RULES §7 asks every pumped test to
drain the Drift close timer) and leaves its `RewardsBloc` open on a mocktail stream
that never completes; `_failRepo` is a module-level `final` mock, so stubs leak
between tests if the file grows. Fix: build the failing mock inside the test (or
`addTearDown` a fresh one) and either call `disposeApp` or comment precisely why the
stream cannot be closed here.

### 9. MINOR — the sheet does not inset for the keyboard

`app/lib/features/rewards/presentation/widgets/p14_reward_editor_sheet.dart:86-88`
· `app/lib/features/rewards/presentation/views/rewards_view.dart:216-218`

The body is a plain `Column(mainAxisSize: min)` (~560 px, ~667 px with
`NestBottomSheet`'s chrome) inside `showNestBottomSheet(isScrollControlled: true)`,
which does not apply `MediaQuery.viewInsets`. With a ~300 px keyboard the
toggle/Save/Cancel/Delete fall behind it and there is no scroll escape. Both stage
notes flag this; it is unproven in the committed tests. Fix: wrap the body in
`Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom))`
plus a scroll view (note `NestBottomSheet` hands its child an unbounded height, so a
bare `SingleChildScrollView` is not the fix), and add a
`tester.view.viewInsets = FakeViewPadding(bottom: 300*3)` test.

### 10. MINOR — scratch probe files sit untracked in the feature test directory

`app/test/features/rewards/_p14_probe_test.dart`, `_p14_probe2_test.dart`,
`_p14_probe3_test.dart` (untracked, `// ignore: avoid_print` × 9)

Created at 12:22–12:29 by a concurrently running stage in this worktree, so this is
a hygiene note rather than a branch defect: RULES §7.1 requires `flutter analyze` to
report no issues **with no ignores**, and the loop commits each iteration — if these
are still present at the final commit they will land on `main`. Delete them (and
`p14_test_support.dart`, `rewards_a11y_test.dart` if they are scratch) before the
commit.

---

## 2. Verified clean — do not re-litigate these

**Scope / rules.** Every changed path is inside RULES §1's allow-list
(`features/rewards/**`, `test/features/rewards/**`, `docs/screens/P14/**`); no
`core/**`, `app/**`, `tools/**` or other-feature file appears in the diff, and
`analysis_options.yaml` is untouched. The deleted
`rewards_placeholder_card.dart` has zero remaining references. No
`google_fonts`/`GoogleFonts`, no `letterSpacing`, no chips (so `NestChipWrap` is
N/A), no `text-wrap: balance` on any P14 element (checked `components.css:28-41`
against `P14-rewards.html` — the nav title is `.nav-bar.compact .nav-title`, not
`.h1`), so `NestBalancedText` is correctly absent. No Pip, no children, no quests
(so PIP / CHILD ORDER / PERIODS are N/A), no `subscription_status` write.

**Architecture.** Feature-first with the domain untouched (entities + abstract
repository only; no Drift import in `presentation/`); one BLoC per feature with
`BlocProvider(create: …)` at the route level (so the `emit.forEach` subscription is
cancelled with the route); `registerRewards` unchanged (repository lazy singleton,
bloc factory); `/rewards` top-level as the route table requires. Presentation talks
to the bloc only — the sheet reports intent through callbacks and never touches the
repository.

**Geometry — independently re-measured from `design/screens/light/P14-rewards.png`
(÷3), not taken on trust.** Card 1 x 20→370, y 167→289 (122, pitch 138 = 122+16);
tile x 32→72 / y 208→248 (40×40); coin pill x 84→139 / y 200→225 (25 high, icon 15,
pad 5/9); toggle track x 179→230 / y 240→271 (51×31) inside a 44-high `.okrow`;
"Needs my OK" advance ≈85 px from x 84, so track x = 84+85+10 = 179; edit button
x 314→358 / y 206→250 (44×44, centred in the card); nav title centred at x 195.2;
intro line 1 x 20.7→339.3 starting at y ≈110, i.e. immediately after the 60-high
compact nav bar with **no** top scroll padding. Every number in
`2b_build_ui.md`'s table and in `reward_card_widget_test.dart` reproduces. The three
non-obvious calls are justified in code and correct:
`IntrinsicWidth` + loose `Flexible` reproduces CSS `flex:0 1 auto` (label intrinsic
width, switch after the 10 px gap, ellipsis when capped at 320 px / 1.3 scale);
`Transform.translate(−4)` reproduces `.toggle::before{left:-4;right:-4}` (Flutter
centres the 51 track in a 59 hit box, so without it the visible track would land at
x 183, 4 px off); and the 25-high pill falls out of `line-height:1` in
`NestCoinPill(xSmall)`. `.editbtn` is hand-built because `NestIconButton` is
circular and would paint the wrong background rect — the right call, and the widget
test asserts the rect, the `surface` fill, the 1 px `line` border and radius 12
rather than a text position (UI-CHECK-MEASURES-SHAPES).

**Copy — character-for-character against `P14-rewards.html:13-21`.** `Reward shop`;
`Things coins can buy — you decide. Children spend coins, never pounds.` (em dash
U+2014); `+ New reward` (ASCII `+`); `Needs my OK`; the two deliberately shortened
`aria-label`s (`Edit Stay up later`, `Edit Trip to the park cafe`, ASCII "cafe")
copied verbatim rather than composed from the accented title; `Trip to the park
café` comes from `Seed.demo()` with `é` U+00E9; coin-pill labels are `{n} coins`.
UK spelling in the comments (`recognises`). No design copy invented for the list
screen; the editor sheet has no design reference at all, so its labels are the
builder's own and carry no spec conflict.

**Tokens / design system.** `grep` finds no `Colors.*`, no `Color(0x…)`, no hex
outside the token barrel in the whole feature. Everything resolves through
`context.nest`, `NestType`, `NestSpacing`, `NestRadii`, `NestDevice`, and the
components (`NestStatusBar`, `NestNavBar(compact:)`, `NestCoinPill(xSmall)`,
`NestToggle`, `NestButton.secondary`, `NestTextField`, `NestStepper`,
`showNestBottomSheet`/`NestBottomSheet`, `NestEmptyState`, `NestIcon`/`NestIcons`)
— no re-implemented components. The icon→glyph map is right and is grounded in
`nestling_assets.dart:190-228`: `clock` is annotated "Reward: stay up 15 min later
(P14)", `chefHat` "baking together (P14 + K08)", `cafe` "trip to the park cafe"
(the catalog deliberately redraws the HTML's arch as a cup; shared code, correct to
follow), `pizza` "choose dinner" for the DB-only row; unknown strings fall back to
the neutral gift tile. Tints match the PNG row by row (sky, lilac, peach, coin,
leaf). The 40×40 tile with radius 12 follows the documented `NestListRow` owner-QA
precedent.

**DATA OVER MOCKS.** The list is the `watchItems` stream (`coinPrice ASC`), so the
screen renders six rows 50/60/80/90/100/150 including `Choose dinner` (90), which
the HTML/PNGs omit, and all six switches ON because every seeded `needsOk` is true
(the PNGs draw "Baking together" off). Nothing is hard-coded from the designs.

**BOTTOM EDGE / ALIGNMENT.** No bottom bar, tab bar or CTA on this screen; the
`Scaffold` paints `paper` to the physical edge and the editor sheet is a
`NestBottomSheet` in `paper`, so no strip can appear under the last child or around
the home indicator in either theme. Gutter geometry is single-sourced
(`NestSpacing.padSide`), the card's tile/column/edit share the card's 12 px padding
edges, and the x positions are asserted numerically rather than eyeballed.

**Accessibility.** Every interactive node exposes `SemanticsAction.tap`: the nav back
(`NestNavBar`), each row toggle (`label` + `toggled:` + `enabled:` + `onTap`), each
edit button (`Semantics(button:, enabled:, label:, onTap:)` **with** `onTap` on the
Semantics node, per RULES §8, with the inner `Ink` icon `ExcludeSemantics` — not a
bare `excludeSemantics: true` wrapper), `+ New reward`, the empty-state button,
`Try again`, and every sheet control. Tap targets: back 44, toggle 44 (51×31 track),
edit 44×44, buttons 52, stepper 44. `_pumpCard` covers 320 px at 1.3 text scale
with no overflow and intact toggle/edit rects; the toggle test taps 5 px above the
track and the write still lands.

**Performance.** Stateless view; `const` where it matters; per-row `ValueKey` so
state/identity survive stream re-emissions; no `setState` in the list path; the
sheet's `TextEditingController` is disposed; `Transform.translate` is a paint-only
transform (no save layer); `IntrinsicWidth` costs one extra intrinsics pass per row
on a list of ≤ a few dozen rows. No rebuild storm: writes arrive as one stream
emission and the bloc emits nothing on success.

**Children's Code.** Parent-mode screen with no analytics, no ads, no network calls,
no child data read or written (rewards are family-wide; `Reward` carries no child
fields), and no coins/£ conversion on a kid surface. Nothing in this diff can leak
child data.

## 3. Handoff notes for stage 5 (5_ui)

- Expect the card order to differ from the PNG below the fifth visible card: the DB
  order is 50/60/80/90/100/150, so `Choose dinner` (90) is card 4 and `Trip to the
  park café` (150) is card 6 (below the fold). Mandated by DATA OVER MOCKS — not
  drift.
- Every switch renders ON, including "Baking together", which the PNG draws off.
- Measure and report: screen title y, first control (intro/card 1) y, each card top
  (pitch 138), the `+ New reward` button bottom when scrolled to the end (see
  finding 3), and the toggle track x (179) — a uniform vertical shift of the whole
  screen is a FAIL.
- The intro must break after "Children" (design line 1 x 20.7→339.3); `maxLines: 4`
  lets it wrap naturally, so confirm the break lands where the design does.

VERDICT: FAIL
