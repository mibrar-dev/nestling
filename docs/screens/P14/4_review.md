# P14 · Rewards manager — Stage 4 QA code review (iteration 2)

Scope: `git diff main...HEAD` (50 files: 8 `app/lib/features/rewards/**`,
10 `app/test/features/rewards/**`, 32 `docs/screens/P14/**`) against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P14,
`docs/design/SPACING_SPEC.md`, `1_plan.md`, `ORCHESTRATOR_NOTES.md`, the design
HTML + light/dark PNGs, and the owner rules. **No code was edited.**

Iteration 1's MAJOR (finding 1: a failed write destroyed the editor's input and
replaced the list with a raw exception) is **closed** — the optional
`Completer<void>? result` channel, the removal of the write-failure `failure`
emit, the async `_submit`/`_delete` with a danger caption and a `_saving` guard,
the centred empty/failure surfaces, the removal of the trailing 16 px spacer,
the `performAction` a11y proofs, the `disposeApp` drains, the keyboard inset and
the creation-order query are all present in the committed code. Seven MINORs
remain open; all new findings below are minor. **No blocker or major →
PASS.**

## 0. Commands run (no simulator booted, installed on, driven or screenshotted)

```
dart format --output=none --set-exit-if-changed .   → Formatted 435 files (0 changed)
flutter analyze                                      → No issues found! (ran in 9.3s)
flutter test test/features/rewards/                  → 00:12 +84: All tests passed!
flutter test                                         → 00:52 +1879 ~3: All tests passed!
git diff main...HEAD --name-only                     → features/rewards/**, test/features/rewards/**,
                                                        docs/screens/P14/** only
```

The `~3` skips are **not** in the branch: `git show HEAD:…/p14_bugs_test.dart |
grep skip:` is empty. They are in the *working tree* copy of that file
(`skip: true` at lines 421/488/528), written minutes ago by the stage-6 bugs
loop running concurrently in this worktree — see §3 Process notes. The full
suite is green on the committed state.

---

## 1. Findings

### 1. MINOR — the sheet's inline error caption still interpolates the raw exception

`app/lib/features/rewards/presentation/widgets/p14_reward_meta.dart:117`, `:120`
· used at `p14_reward_editor_sheet.dart:95`, `:118`

```dart
static String saveError(Object error) => 'Could not save the reward: $error';
```

Iteration 1 finding 2 (raw exception as user copy) was fixed on the full-screen
surface — `_RewardsFailure` renders static `RewardCopy.loadError` and keeps
`error.toString()` technical, with the paywall precedent cited in the comment
(`rewards_view.dart:214-217`). The inline caption kept the same rule-breaking
string, so the one surface a parent is most likely to read after a failed write
shows `Could not save the reward: SqliteException(1): no such column: …` or
`Exception: …`. The doc comment claims "the friendly sentence first, then the
technical detail", but the technical detail is exactly what should not be in
parent-facing copy.

**Fix:** drop the `$error` interpolation from both helpers —
`'Could not save the reward. Please try again.'` / `'Could not delete the
reward. Please try again.'` — and, if the detail must be kept, log it or park it
on `state.errorMessage`. Or route it through `NestTextField(errorText:)`, which
already paints a danger caption from a friendly string.

### 2. MINOR — the editor sheet's `Needs my OK` row announces itself twice

`app/lib/features/rewards/presentation/widgets/p14_reward_editor_sheet.dart:215`
and `:223`

```dart
Text(RewardCopy.needsOkLabel, style: NestType.fieldLabel(color: tokens.ink), …)
…
NestToggle(value: _needsOk, semanticLabel: RewardCopy.needsOkLabel, …)
```

Both siblings of the same `Row` carry the identical string, so VoiceOver reads
the switch as *"Needs my OK"* and then *"Needs my OK, switch, on"* — two nodes,
one label. The list cards get this right (`p14_reward_card.dart:113-130`:
visible `Needs my OK`, semantic `Needs approval for …`), which is why the
committed a11y test can assert one labelled node per row but has to fall back to
`find.byType(NestToggle)` inside the sheet (`rewards_a11y_test.dart:372-373`,
"the switch is addressed by type here" — the test works around the symptom
instead of the cause).

**Fix:** `MergeSemantics` around the sheet's `Row` so the label and the switch
announce as one node (`"Needs my OK, switch, on"`, tap still acts on the switch),
or give the switch a distinct label the way the card does.

### 3. MINOR — a stream failure *after* data has loaded freezes the list with no way out

`app/lib/features/rewards/presentation/views/rewards_view.dart:53-59`

```dart
case RewardsStatus.failure:
  if (state.items.isNotEmpty) {
    return _RewardsLoaded(items: state.items);
  }
```

`emit.forEach` terminates its subscription when the stream errors, so this
branch can render a list that will never update again — and because
`items.isNotEmpty`, `Try again` (the only recovery affordance in the bloc's
design) is deliberately hidden. A parent can still tap a switch, the write
lands, and nothing moves on screen. This is the correct trade-off for *write*
failures (fixed in iteration 1), but the *stream* case deserves a recovery path.

**Fix:** keep a `bool streamFailed` (or re-add `RewardsLoadRequested` on the next
write / on pull-to-refresh), or show a one-line inline retry strip above the
list; at minimum document the dead-subscription assumption in the branch
comment. `rewards_states_test.dart` covers the empty-items failure only.

### 4. MINOR — the sheet re-derives `NestBottomSheet`'s chrome by hand

`app/lib/features/rewards/presentation/widgets/p14_reward_editor_sheet.dart:141-157`

```dart
final chrome = NestSpacing.s2 + NestSpacing.gap5 + NestSpacing.s3 +
    (titleStyle.fontSize ?? 0) * (titleStyle.height ?? 1) +
    NestSpacing.s2 + NestDevice.homeH + NestSpacing.s4;
```

That sum reproduces `NestBottomSheet`'s internal padding (top pad, grabber,
grabber gap, h3 title, title gap, home reserve, bottom pad) outside the
component that owns it. It is arithmetically right today (8+5+12+24+8+34+16 =
107), and it drives the max height that keeps the form out of RenderFlex
overflow, so a future tweak to the shared sheet — a taller grabber, a different
title style, a changed bottom pad — silently under-estimates the cap and brings
the overflow back. The estimate also ignores `textScaleFactor` (at 1.3 the title
is ~7 px taller), so the cap is loose exactly where it should be tight.

**Fix:** add this to `SHARED_REQUEST.md` (it belongs with the keyboard-inset
request: the fix is one keyboard-aware `constraints` inside the shared helper,
after which both the local opener and this constant disappear), or expose the
sheet chrome as a public constant from `nest_bottom_sheet.dart`. Until then keep
a test that pins it: the sheet at 320×568 × 1.3 with a 300 px inset must raise
no `RenderFlex` overflow (`p14_bugs_test.dart` [P14-B01] covers 390×844).

### 5. MINOR — `.editbtn` is a hand-rolled control because the shared one is circular

`app/lib/features/rewards/presentation/widgets/p14_reward_card.dart:151-189`

`NestIconButton` paints `CircleBorder`/`CircleBorder` InkWell/`BoxShape.circle`
(`core/design_system/components/nest_icon_button.dart:39-70`), so it cannot draw
the design's 44×44 **radius-12** square; `_EditButton` reproduces `.editbtn`
(44×44, r12, 1 px `--line`, `--surface`, 24 px `--ink-2`) and the widget test
asserts the rect, fill, border and radius rather than a text position. The
decision is correct and the deviation is documented, but it is a shape
re-implementation of a design-system control inside a feature.

**Fix (not blocking):** append a line to `SHARED_REQUEST.md` asking for
`NestIconButton.shape` (or a `NestSquareIconButton`) so P14 — and any later
screen with an `.editbtn` — stops owning the shape.

### 6. MINOR — two comments in the committed tests are now false

`app/test/features/rewards/p14_test_support.dart:126-136` says the canonical
query and the `needsOk` seed correction "arrive with the next main merge" and
calls `[P14-ORDER]` "skip-marked"; `rewards_order_test.dart:14-17` repeats the
skip wording. Both landed: `watchRewardsInCreationOrder` is wired
(`rewards_repository_impl.dart:21-28`) and the proof is live with no `skip:`
anywhere in the feature. A stale "this is blocked on main" comment is how the
next agent re-litigates a settled decision.

**Fix:** reword both to state the current fact (creation order is live; the
proof is not skipped).

### 7. MINOR — iteration-1 test hygiene (carried, demonstrably harmless)

`app/test/features/rewards/rewards_view_test.dart:23` (module-level `_failRepo`
mock, stubs shared if the file grows), `:333-364` and
`rewards_states_test.dart:79-155` (pumped tests with no `disposeApp`). Both use
mock repositories, so no Drift `QueryStream` is cancelled and no
"A Timer is still pending" can fire — the green suite proves it. RULES §7 asks
for the drain on tests that pump the app, and the file should say why it is
skipped rather than leave the next reader guessing.

**Fix:** build the failing mock inside its test (or `addTearDown` a fresh one)
and put a one-line comment on the three tests explaining that no Drift stream
is open, or add the drain.

---

## 2. Verified clean — do not re-litigate

**Scope / RULES §1.** Every changed path is inside the allow-list:
`lib/features/rewards/{data,presentation}/**`,
`test/features/rewards/**`, `docs/screens/P14/**`. No `core/**`, no `app/**`, no
`tools/**`, no other feature, `analysis_options.yaml` untouched. The deleted
`rewards_placeholder_card.dart` has zero remaining references (`grep` clean).
No `google_fonts`/`GoogleFonts`, no `letterSpacing`, no `skip:`/`ignore:`,
no `TODO(P14)`.

**Orchestrator rules.** `ORCHESTRATOR_NOTES.md` (12:27 + 12:35) is fully
applied and verified in code: `watchItems()` serves
`watchRewardsInCreationOrder` and no price sort survives anywhere in the feature
(only `coinPrice` *column writes*); toggle state is read from `reward.needsOk`
and never a literal, so the seeded `needsOk: false` for "Baking together"
renders OFF without a code change; the child order ruling is N/A (no children on
this screen); PIP is N/A (no Pip on P14); PERIODS, TRIAL, `NestChipWrap` and
`NestBalancedText` are N/A (`P14-rewards.html`'s CSS has no `text-wrap: balance`
on `.intro` or `.nav-bar.compact .nav-title` — checked against
`components.css:28-41`).

**Architecture.** Feature-first, domain untouched (entities + abstract
repository only; no Drift import in `presentation/`), one `RewardsBloc` provided
at the route level in `rewards_routes.dart` so the `emit.forEach` subscription
dies with the route, `registerRewards` unchanged (lazy singleton repo, bloc
factory), `/rewards` top-level per the route table. The editor sheet reports
intent through callbacks and never touches the repository or the bloc's state;
all four writes go through events. `Colors.transparent` at
`rewards_view.dart:274` is copied from the shared helper's own call
(`nest_bottom_sheet.dart:122`), not a colour invention.

**Tokens / design system.** No `Colors.*`, no `Color(0x…)`, no hex, no literal
`fontSize:` anywhere in the feature; every value resolves through `context.nest`,
`NestType`, `NestSpacing`, `NestRadii`, `NestDevice` and shared components
(`NestStatusBar`, `NestNavBar(compact:)`, `NestCoinPill(xSmall)`, `NestToggle`,
`NestButton`, `NestTextField`, `NestStepper`, `NestBottomSheet`, `NestEmptyState`,
`NestIcon`/`NestIcons`, `showNestToast`). The only hand-built widgets are the
two in finding 5 and the sheet's opener, both justified and filed.

**Copy — character-for-character against `P14-rewards.html:13-21`.**
`Reward shop`; `Things coins can buy — you decide. Children spend coins, never
pounds.` (em dash U+2014); `+ New reward` (ASCII `+`); `Needs my OK`; the five
names with `é` U+00E9 from `Seed.demo()`; the two deliberately shortened
`aria-label`s (`Edit Stay up later`, `Edit Trip to the park cafe`, ASCII "cafe")
copied verbatim rather than composed from the accented title; coin pills
`{n} coins`. UK spelling in the comments. The sheet's strings are marked in
`p14_reward_meta.dart:102-109` as having no design reference — correct, the HTML
and both PNGs are the list screen only.

**Error handling.** Write failures no longer touch the bloc's state
(`rewards_bloc.dart:36-44`), so a failed toggle cannot replace the list; the
sheet keeps the typed name, shows a danger caption and stays open; Save is
disabled while a write is in flight (`_saving`) so a double tap cannot create
two rows; delete is armed by a second tap whose label change (`Delete` →
`Confirm delete`) is asserted in `rewards_view_test.dart:236-246`; `_completeError`
leaves a settled channel alone, so no unhandled async error can reach the zone.
The remaining exception-in-copy leak is finding 1.

**Accessibility.** Every interactive node carries `SemanticsAction.tap`: nav
back, all six switches (label + `toggled:` + `enabled:` + `onTap` passthrough),
all six edit buttons (`Semantics(button:, enabled:, label:, onTap:)` **with**
`onTap` on the Semantics node per RULES §8, inner icon `ExcludeSemantics`),
`+ New reward`, the empty-state action, `Try again`, and all seven sheet
controls; a disabled Save advertises no tap and reports `enabled: false`.
`performAction(tap)` is asserted to change **real** state, not just to exist: a
switch writes its Drift row, edit opens the prefilled sheet, `+ New reward`
opens a blank one, Back returns to `/today` (`pushedPath`, never view text).
Tap targets ≥44 measured for all of them, and the switch is live 5 px above,
on, and 5 px below the drawn track. Finding 2 is the only gap.

**Performance.** Stateless view; `const` where it matters; per-row
`ValueKey` so identity survives stream re-emissions; no `setState` in the list
path and no optimistic local toggle state (the card follows the stream);
`Transform.translate` is paint-only; `IntrinsicWidth` costs one intrinsics pass
per row on a short list; the sheet's `TextEditingController` is disposed and
both async paths are `mounted`-guarded; writes emit nothing on success, so a
single tap produces a single rebuild. No rebuild storm.

**Geometry / UI-CHECK-MEASURES-SHAPES.** The card measurements in
`p14_reward_card.dart:8-22` reproduce what the light render shows ÷3 (card
20→370 × 122 high, pitch 138; tile 40×40; pill 25 high; toggle track x 179;
edit 44×44) and are asserted numerically by `reward_card_widget_test.dart`,
`rewards_responsive_test.dart` (20 px gutter, 16 px pitch, `edit.size == 44×44`,
`edit.right == width − 20 − 12`, button sharing the card edges at 52 high) and
`rewards_view_test.dart`. `IntrinsicWidth` + loose `Flexible` correctly
reproduces CSS `flex:0 1 auto`; `Transform.translate(−4)` reproduces
`.toggle::before{left:-4;right:-4}`.

**BOTTOM EDGE / ALIGNMENT.** No bottom bar, tab bar or CTA on this screen, so
the `Scaffold` paints `paper` to the physical edge in both themes and the
editor sheet is a `NestBottomSheet` in `paper` — no strip is possible. Gutters
are single-sourced from `NestSpacing.padSide` and asserted at 320/390/430 ×
1.0/1.3 in both themes.

**Children's Code.** Parent-mode screen: no analytics, no ads, no network, no
child data read or written by P14's own path (`watchItems` touches only the
`rewards` table), no coins/£ conversion on a kid surface, no `subscription_status`
write.

---

## 3. Process notes — not findings (orchestrator PROCESS ITEMS rule)

* A stage-6 bugs loop is running concurrently in this worktree right now: it has
  deleted the iteration-1 probe files, created untracked
  `app/test/features/rewards/_p14_it2_probe_test.dart`, and has uncommitted
  changes to the tracked `p14_bugs_test.dart` (3 new `skip: true` at lines
  421/488/528) plus `5_ui.md`/`6_bugs.md`. Untracked scratch files and
  uncommitted work are the loop's to resolve — but before this branch merges,
  the probe file must be deleted and those three skips resolved, or main will
  inherit a skipped test suite. (Iteration 1's finding 10 is the same note.)
* `git status` also shows modified `docs/screens/P14/.brief_*.md` — loop
  bookkeeping.
* Merge order / being behind main: not reviewed, by rule.

## 4. Handoff

* **Stage 5 (UI, simulator 604697A9 only):** the committed layout is unchanged
  from `5_ui.md`, whose measured title/intro/card tops all read Δ0. Re-measure
  anyway because the *data* is new: the visible sequence is 50 → 80 → 60 → 100 →
  150 with "Baking together" **off**, and `Choose dinner` (90) sits below the
  fold. Report title y, intro y, each card top, the ±2 px verdict, the toggle
  track x (179) and the bottom edge.
* **Stage 6 (bugs):** findings 1 and 2 are cheap, in-feature and testable
  (assert the caption contains no `Exception`/`SqliteException`; assert the
  sheet's `Needs my OK` row is one merged node). Finding 3 needs a decision
  about the dead subscription. Findings 4-7 are housekeeping.

VERDICT: PASS