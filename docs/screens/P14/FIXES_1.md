# Fix list after iteration 1

## From 3_test.md
# P14 · Rewards manager — Stage 3 tests (iteration 1)

Route `/rewards` · feature `rewards` · parent mode. Test-only stage: nothing in
`app/lib/**` or `tools/**` was touched (`git status --porcelain -- app/lib
tools/` empty). Everything lives in `app/test/features/rewards/`.

## Gates

```
$ dart format .
Formatted 426 files (0 changed) in 1.02 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.4s)

$ flutter test
00:37 +1665 ~7: All tests passed!
```

Per-file (feature dir only):

```
rewards_bloc_test            +13     rewards_states_test      +7
rewards_repository_test       +8     rewards_responsive_test  +9
rewards_view_test             +8     rewards_a11y_test       +12
reward_card_widget_test       +4     rewards_order_test       +2 ~1
p14_bugs_test (stage 6)    +9 ~6
```

72 passed / 0 failed / 7 skipped in the feature dir; 1665 across the app. The
skips are the open-bug proofs (6 from `6_bugs.md`, plus mine below), each
re-provable with `--run-skipped`. No new `google_fonts` import, no
`analysis_options` change, no weakened lint.

## Files

* **`p14_test_support.dart`** (new, harness) — `pumpRewardsApp(tester,
  width/height/textScale/theme/seedDemo/prepare)`, `loadBundledFonts()`,
  `rewardRows/rewardRow/rewardNeedsOk`, `rewardIdsInAppOrder`,
  `tappableSemanticsNodes`, `visibleTrackRect`, and the seeded id + label maps.
* **`rewards_a11y_test.dart`** (new, 12) — the RULES §8 contract.
* **`rewards_states_test.dart`** (new, 7) — loading / failure / empty / copy /
  token surfaces.
* **`rewards_responsive_test.dart`** (new, 9) — 320/390/430 × scale 1.0/1.3 ×
  light/dark.
* **`rewards_order_test.dart`** (new, 2 + 1 skip) — the ORCHESTRATOR_NOTES
  12:27 creation-order ruling.
* **`rewards_bloc_test.dart`**, **`rewards_repository_test.dart`**,
  **`rewards_view_test.dart`** — rewritten order/toggle assertions.

## Coverage against the brief

| requirement | where |
|---|---|
| bloc_test for every event/state path | `rewards_bloc_test.dart` — all five events, `initial/loading/loaded/failure`, four throwing-write paths, stream error + retry |
| light + dark | `rewards_states_test.dart` (tokens per theme), `rewards_responsive_test.dart` (every width × scale in both) |
| widths 320/390/430 | `rewards_responsive_test.dart`; sheets re-checked at all three |
| text scale 1.0 and 1.3 | same, via `platformDispatcher.textScaleFactorTestValue` (the app clamps to 1.0–1.3) |
| empty / loading / error | `rewards_states_test.dart` (loading via a never-emitting stream, failure via a throwing one, empty via `Seed.empty` and via deleting every row) |
| every tap navigates to the right route | `rewards_a11y_test.dart` — Back by tap **and** by `performAction`, asserted with `pushedPath`/`currentPath`, never view text |
| semantics labels on icon buttons | `rewards_a11y_test.dart` — all 14 control labels resolved, each exactly one node with `SemanticsAction.tap` |
| tap targets ≥ 44 (parent) | `rewards_a11y_test.dart` — Back, 6 toggles, 6 edits, New reward, and all seven sheet controls measured |
| in-memory Drift + `Seed.demo`/`empty` | `setUpTestScope` everywhere; `Seed.demo` default, `Seed.empty` / row deletion for the empty cases |

Beyond the list, `performAction(tap)` is asserted to change **real** state, not
just to exist: a switch writes its Drift row, edit opens the prefilled sheet,
`+ New reward` opens a blank one, Back pops the route.

## ORCHESTRATOR_NOTES (12:27 + 12:35) — mandatory items

1. **List in creation order, not price.** Split in two, deliberately:
   * *green* — `rewards_order_test.dart`: the rendered card ids equal
     `repository.watchItems()` ids exactly. That is what the screen owns: it
     must not re-sort. It fails if the view ever adds `.sort()` or reverses.
   * *skipped* — `[P14-ORDER] the rendered list is in Seed.demo creation
     order`. **This one fails today**, which is the point:
     `--run-skipped` gives `at location [1] is 'r-bedtime' instead of
     'r-film'`, i.e. price 60 before price 80. Same finding as stage 6's
     P14-B05; `watchRewardsInCreationOrder` is not in this snapshot (not an
     ancestor). Remove the skip after the next main merge.
2. **Baking's `needsOk` false + "do not hard-code the toggle state".** Every
   order/toggle assertion in the four pre-existing test files was rewritten
   to read the database instead of a literal — the old `'all needsOk isTrue'`
   and `needsOk: false` fixtures would have failed the moment the seed
   correction landed. New pin: `rewards_order_test.dart`'s "the toggle state of
   each row is its database value" (switch state == `rewardNeedsOk(id)`, per
   row) and `rewards_states_test.dart`'s track-colour check.
3. **`watchRewardsInCreationOrder`** — not yet on this branch; nothing to call.
   The green order test is written against the repository interface, so it
   passes unchanged once the repository switches.

## Findings

### Confirmed from this stage (test-side, no screen change needed)

**F1 — widget tests must load the bundled families, or overflow assertions lie.**
`reward_card_widget_test.dart` noted this for card geometry; it bites harder
than that. Without `FontLoader`, the fallback font renders the sheet's
stepper row **19 px too wide** at 320×568 × scale 1.3, and its body **16 px too
tall** — a `RenderFlex` overflow that does not exist on device:

```
no fonts    320×568 ×1.3 → "A RenderFlex overflowed by 19 pixels on the right",
                            "A RenderFlex overflowed by 16 pixels on the bottom"
with fonts  320×568 ×1.3 → 0 exceptions
             390/430×568 ×1.3, 320×844 ×1.0/1.3 → 0 exceptions
```

Every new widget test file calls `setUpAll(loadBundledFonts)`. This also means
the earlier "keyboard robustness of the sheet" open item from `2b`/`2_build`
is **not** reproducible once fonts are loaded: at 320×568 × 1.3 the sheet lays
out cleanly. (The keyboard issue is a different, still-real bug — see B1.)

### Bugs confirmed in the screen (already filed by stage 6, re-proved here)

Measured from the test side; no code changed, per the stage rule.

**B1 / P14-B01 (major) — the keyboard covers the sheet's controls.**
`showNestBottomSheet` never reads `MediaQuery.viewInsets`. With a 300 px inset
at 390×844:

```
Save   y 682 → 734   keyboard top 544   → 190 px behind
Cancel y 742 → 794   keyboard top 544   → 250 px behind
sheet  y 422 → 794   (unchanged by the inset)
```

Shared `nest_bottom_sheet.dart` — `grep -rn viewInsets lib/` returns nothing
app-wide. iOS-only (Android resizes the window). Needs a `SHARED_REQUEST` or a
feature-local `AnimatedPadding` + scrollable body.

**B2 / P14-B02 (minor) — empty and failure surfaces are top-aligned.**
Empty state renders y 107 → 481, centre **294.0** vs the scroll viewport centre
**475.5** — 181.5 px off, pinned under the nav bar. Same `_RewardsScroll`
`ListView` root cause for the failure surface.

**B3 / P14-B05 (major) — price order, not creation order.** See
ORCHESTRATOR_NOTES §1; proven by my skipped `[P14-ORDER]` test.

### Shared-component observation (not a P14 defect)

Every design-system control built as `Semantics(label:, onTap:) > InkWell`
also exposes the inner `InkWell` as a **second, unnamed** semantics node —
measured on `/rewards`: 28 tappable nodes, **14 unnamed** (6 switches at
59×44, 6 edit buttons + Back at 44×44, `+ New reward` at 350×52; `actions`
= `tap`, none carry `isButton`). `/today` shows the same pattern (3 unnamed),
so it is systemic, not P14. Each control is still correctly operable — the
labelled node has the tap action and `performAction` drives the real behaviour,
which my tests assert — so this is a shared `SHARED_REQUEST` candidate, not a
stage-3 blocker. `_EditButton` in `p14_reward_card.dart` follows the same
shared idiom deliberately (its `onTap:` **is** on the `Semantics` node, so
RULES §8 holds).

## Notes for the next iteration

* Two harmless `tap()` "would not hit test" warnings come from
  `p14_bugs_test.dart` (stage 6) at 320-wide + B01/B03 scenarios; every P14
  file I added is warning-free.
* `_RewardsScroll` appends a trailing `SizedBox(s4)` after its single child,
  so the empty/failure surfaces carry 16 px of dead space at the bottom on top
  of the B2 centring problem. Harmless, but fold it in when B2 is fixed.
* A blank sheet's `Save` is disabled until the first frame after typing —
  `enterText` alone does not re-enable it, so tests must `pumpAndSettle()`
  between typing and tapping. Bit me once here; recorded in the harness.
* After a write, `await pumpAndSettle()` is **not** enough to see the new card
  in the tree: the Drift write is real async. `await rewardRows()` first, then
  `pumpAndSettle()`. Without it the empty-state create test read a stale tree
  and looked like a bug.
* `tester.runAsync` is required for `RewardsRepository.watchItems().first`
  inside a widget test — a Drift stream never delivers under the fake clock,
  and a bare await deadlocks to the 10-minute timeout.


## From 4_review.md
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


## From 6_bugs.md
# P14 · Rewards manager — Stage 6 adversarial bug hunt (iteration 1)

Route `/rewards` · feature `rewards` · parent mode · design
`design/html-source/screens/P14-rewards.html` + light/dark PNGs
(1170×2532 ÷3). This stage changed **nothing** in `app/lib/**`; it added
`app/test/features/rewards/p14_bugs_test.dart` and this report.

`ORCHESTRATOR_NOTES.md` (12:27 + 12:35) is mandatory and is covered below:
the creation-order ruling is filed as **P14-B05**, and the "do not hard-code
the toggle state" item is pinned by a verified-clean DB-driven guard (the
seed's `Baking together = false` itself ships with `shared/rewards_seed_order`,
not in this snapshot).

Gates on the snapshot (`flutter test test/features/rewards/p14_bugs_test.dart
test/features/rewards/rewards_bloc_test.dart
test/features/rewards/rewards_repository_test.dart
test/features/rewards/rewards_view_test.dart
test/features/rewards/reward_card_widget_test.dart`):

* **+42 passed, 6 skipped, 0 failed** — the six skips are the open-bug
  proofs below; `--run-skipped` makes every one of them fail on the current
  code, and the 9 verified-clean tests pass in both modes.
* `flutter analyze test/features/rewards/p14_bugs_test.dart` → No issues found;
  `dart format` clean.
* Nothing under `app/lib/**`, `app/lib/core/**` or `tools/**` was touched.

## Bug summary

| id | severity | one-liner | failing test (skip-marked) |
|---|---|---|---|
| P14-B01 | **major** | On iOS the keyboard covers the editor sheet — Save, Cancel and Delete sit behind it once the name field is focused | `[P14-B01] the keyboard must not cover the editor sheet controls` |
| P14-B02 | minor | The empty state and the failure surface are top-aligned under the nav bar, not centred in the scroll (plan §4) | `[P14-B02] the empty state is centred in the scroll area` · `[P14-B02] the failure surface is centred in the scroll area` |
| P14-B03 | minor | A sheet write failure closes the sheet and loses the typed input; no inline error caption (plan §4) | `[P14-B03] a sheet write failure keeps the sheet open with an inline error` |
| P14-B04 | minor, latent | Deleting a reward leaves its pending redemption request orphaned; approving it is a silent no-op | `[P14-B04] deleting a reward with a pending request orphans the request` |
| P14-B05 | **major** | The list is ordered by coin price, not creation order (owner rule / ORCHESTRATOR_NOTES 12:27) | `[P14-B05] rewards are listed in creation order, not price order` |

---

## P14-B01 — major — the iOS keyboard covers the editor sheet

**Repro.** `/rewards` → `+ New reward` → focus the `Name` field (the iOS
keyboard opens and floats over the Flutter view — it does not resize it) →
try to tap `Save`. The sheet does not move.

**Measured** (390×844, keyboard inset 300 px):

| element | app rect (bottom) | keyboard top | result |
|---|---|---|---|
| `Save` | 682 → **734** | 544 | 190 px behind the keyboard |
| `Cancel` | 742 → **794** | 544 | 250 px behind the keyboard |
| `Delete` (edit sheet) | below Cancel | 544 | behind |

**Failing test.**
`[P14-B01] the keyboard must not cover the editor sheet controls`
(`--run-skipped`: `Expected: a value less than or equal to <544.0>
Actual: <734.0>`).

**Root cause.** `showNestBottomSheet`
(`app/lib/core/design_system/components/nest_bottom_sheet.dart`) never reads
`MediaQuery.viewInsets`; Flutter's `_ModalBottomSheetLayout` positions the
sheet at `size.height − childHeight` and ignores insets (verified in the
SDK source), and on iOS the keyboard is reported as insets only. On Android
the window resizes so the sheet moves; **iOS is the broken platform**.

**Suggested fix.** Pad the sheet content by
`MediaQuery.viewInsetsOf(context).bottom` and keep it tappable when the
remaining height is short. This is best done once in the shared
`showNestBottomSheet` (file a `SHARED_REQUEST` — every screen's sheet has the
same hole); feature-local alternative: wrap `RewardEditorSheet`'s body in an
`AnimatedPadding(bottom: viewInsets)` + a height-constrained
`Flexible`/`SingleChildScrollView` so Save/Cancel/Delete stay above the
keyboard and the body scrolls.

---

## P14-B02 — minor — empty and failure surfaces are top-aligned, not centred

**Repro A (empty).** Delete every reward (`Seed.demo`, then
`DELETE FROM rewards`) → open `/rewards`. `NestEmptyState` renders at
y 107 → 481; centre **294.0** vs the scroll viewport centre **475.5**
(181.5 px off). The design surface hugs the nav bar and leaves 363 px of dead
space below.

**Repro B (failure).** A load failure (`watchItems` errors) → the message +
`Try again` column renders at y ≈ 107 → 247; union centre **153.0** vs
**475.5** (322.5 px off).

**Failing tests.**
`[P14-B02] the empty state is centred in the scroll area` ·
`[P14-B02] the failure surface is centred in the scroll area`.

**Root cause.** `_RewardsScroll` is a `ListView`, so the `Center` inside its
child gets an unbounded main axis, shrink-wraps and pins the surface to the
top. Plan §4 says "centred in the scroll" for both states.

**Suggested fix.** Use a `CustomScrollView` with
`SliverFillRemaining(hasScrollBody: false, child: Center(...))` (or a
`LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(minHeight:
constraints.maxHeight)`), keeping the 20 px gutters and the 66 px bottom pad.

---

## P14-B03 — minor — a failed sheet write loses the input with no inline error

**Repro.** Repository `createReward` throws (e.g. disk full / DB closed) →
`+ New reward` → type `Pizza night` → `Save`. The sheet closes
(`find.text('New reward')` = 0), the typed name is gone, and the list is
replaced by the full-screen failure state (`Try again`); no inline caption.

**Failing test.**
`[P14-B03] a sheet write failure keeps the sheet open with an inline error`
(`--run-skipped`: `Expected: exactly one matching candidate … "New reward"`,
`Actual: Found 0`).

**Root cause.** `RewardEditorSheet._submit()` calls `onSave` then `_close()`
synchronously; the write result is only observable on the list's stream state
(plan §4 wants the sheet kept open with a `danger` 13/18 w600 caption above
Save). The 2a build flagged this as a missing per-write result channel.

**Suggested fix.** Give the write events a result channel (`RewardsCreate/
Update/DeleteRequested` returning a `Future`/emitting a per-write result the
sheet awaits) or drive an `errorText` into the sheet from a `BlocListener`;
keep the sheet open and render the caption above Save on failure.

---

## P14-B04 — minor, latent — deleting a reward orphans its pending request

**Repro.** Seed demo → insert the row K08's `requestReward` writes
(`reward_redemptions`: `r-cafe`, `maya`, `requested`) → open `/rewards` →
`Edit Trip to the park cafe` → `Delete` ×2. The reward row is gone but the
redemption row remains `requested` (foreign keys are off). `watchRequests()`
then maps it to title `Reward` / 0 coins, and `approveRedemption` returns
silently — no coins are deducted and the status never leaves `requested`.

**Failing test.**
`[P14-B04] deleting a reward with a pending request orphans the request`
(`Expected: empty`, `Actual: [RewardRedemption(… status: requested …)]`).

**Root cause.** `RewardsRepositoryImpl.deleteReward` deletes only the reward
row; there is no cascade or guard for `reward_redemptions` (and SQLite FK
enforcement is off app-wide).

**Suggested fix.** In the feature-owned repository, delete the reward and its
redemptions in one transaction (or block the delete while a request is
pending) — an orchestrator/product call, since keeping request history may
also be legitimate. Latent today (K08's request UI is not built yet), but
reachable as soon as it is.

---

## P14-B05 — major — the list is ordered by price, not creation order

**Repro.** Seed demo → open `/rewards`. The cards render
`30 min extra screen time, Stay up 15 min later, Pick Friday film, Choose
dinner, Baking together, Trip to the park café` — `coinPrice ASC`, not the
order the rewards were added.

**Measured** (`RewardCard` title order):

| expected (creation order, owner rule) | actual (price order) |
|---|---|
| 30 min extra screen time | 30 min extra screen time |
| Pick Friday film | **Stay up 15 min later** |
| Stay up 15 min later | **Pick Friday film** |
| Baking together | **Choose dinner** |
| Trip to the park café | **Baking together** |
| Choose dinner | Trip to the park café |

**Failing test.**
`[P14-B05] rewards are listed in creation order, not price order`
(`--run-skipped`: `at location [1] is 'Stay up 15 min later' instead of
'Pick Friday film'`).

**Root cause.** `RewardsRepositoryImpl.watchItems()` still calls
`_db.watchRewards(Seed.familyId)`, whose query is
`ORDER BY coinPrice` (`app_database.dart:513`). `ORCHESTRATOR_NOTES.md`
(12:27, 12:35) rules the list must follow the order the rewards were added and
points at `AppDatabase.watchRewardsInCreationOrder` on `main` (branch
`shared/rewards_seed_order`, which also fixes the seed's
`Baking together → needsOk: false`). That shared branch is not in this
snapshot yet (`git merge-base` check: not an ancestor).

**Suggested fix.** With the next main merge, switch `watchItems()` to
`_db.watchRewardsInCreationOrder(Seed.familyId)` and drop the price sort; the
view already renders whatever the stream yields, so no widget change is
needed. Keep the toggle state DB-driven (pinned clean by
`[P14-clean] the toggle state comes from the DB, not the view`).

---

## Verified clean — attacks that were run and held

* **Kid-mode guard**: a kid-mode deep link to `/rewards` lands on
  `/parental-gate` (`selectMode(kid)` + `session.setAppMode('kid')`).
* **Back navigation**: `push('/rewards')` from `/today`, tap `Back` →
  `pushedPath` returns to `/today`.
* **Restart persistence**: a reward created through the sheet is still there
  after `disposeApp` + a fresh app (new bloc/view) over the same Drift DB.
* **Rapid double taps**: two taps on `Save` and two on `+ New reward` in the
  same frame produce exactly one write / one sheet (the pop/push animation
  ignores pointers); a toggle double tap 16 ms apart is two flips and ends
  consistent in UI + DB.
* **Data edges**: 9999 coins and
  `Maximilian-Alexander’s cinema trip` render at 320 px width × 1.3 text
  scale with no overflow and no clipped fixed rects; the empty list renders
  the empty state and `+ New reward` round-trips a create into the list.
* **Accessibility actions**: all 6 toggles, all 6 edit buttons, `Back` and
  `+ New reward` expose `SemanticsAction.tap`; `performAction(tap)` on a
  toggle flips the real `r-screen` DB row. `Save` with an empty name is
  disabled (`enabled: false`, no tap action) — the disabled-control rule.
* **Toggle state is DB-driven** (ORCHESTRATOR_NOTES 12:27): flipping
  `r-baking.needsOk` to `false` in the DB renders that row OFF while the
  other rows stay ON — nothing is hard-coded.
* **Dark mode** at 1.3 scale renders the six seeded rows with no exception.

## Notes, not bugs

* **Same-frame toggle double tap.** Two taps in the same <1 ms frame both
  compute `!true` and write `false` twice; with a 1 ms pump between taps the
  stream has already re-emitted and the second tap restores `true`. A frame is
  16 ms, so a human double tap cannot hit this window — recorded for
  completeness, not filed.
* **Raw exception text.** The failure surface prints `error.toString()`
  (e.g. `Bad state: boom`) rather than a friendly message; cosmetic, matches
  the plan's `errorMessage ?? …` contract.
* **No in-app entry point yet.** `RewardsRoutePaths.rewards` is referenced
  only by the router and smoke tests on this branch; the Family/Money entry
  belongs to other screens. Not a P14 defect.
* **`Reward.detail`** is still carried but unused by P14 (plan §2).

## Verdict rationale

P14-B01 and P14-B05 are major defects: on iOS the primary create/edit flow's
Save, Cancel and Delete controls are covered by the keyboard, and the list is
ordered by coin price against the owner rule / ORCHESTRATOR_NOTES 12:27.
P14-B02–B04 are minor (two plan-§4 layout/copy deviations and one latent
data-integrity gap). Per the stage rule ("PASS only if no major bugs") this
iteration fails.

