# P14 · Rewards manager — Stage 4 QA code review (iteration 3)

Scope: `git diff main...HEAD` (56 files: 7 changed + 1 deleted
`app/lib/features/rewards/**`, 11 `app/test/features/rewards/**`,
`docs/screens/P14/**`) against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P14, `docs/design/SPACING_SPEC.md` §§0/2/3/8–11,
`1_plan.md`, `ORCHESTRATOR_NOTES.md`, the design HTML + light/dark PNGs, and the
owner rules. **No code was edited.**

**Iteration 2's seven MINORs:** 2, 3 and 4 are **closed** (the sheet's
`Flexible` body replaces the hand-derived chrome sum; the sheet's duplicate
`Needs my OK` announcement is gone; every `failure` now renders the surface
with `Try again`, backed by `_closeOnError` so the retry cannot stack a
subscription). 1, 5, 6 and 7 are **still open** — 1 is now provably wrong
rather than merely arguable (finding 1), and 5/6 gained a documentation
inconsistency (finding 3). Findings 5–10 below are new; **all ten are MINOR, so
there is no blocker and no major → PASS.**

---

## 0. Commands run (no simulator booted, installed on, driven or screenshotted)

```
dart format --output=none --set-exit-if-changed <all tracked lib+test>
   → Formatted 379 files (0 changed)          FORMAT_EXIT=0
flutter analyze                                → 10 issues, ALL in the untracked
                                                _p14_it3_probe_test.dart (see §3)
flutter test test/features/rewards/<10 committed files>
   → 00:03 +103: All tests passed!
flutter test                                   → 00:58 +2244 ~1 -3; the 3 failures
                                                are all in the untracked probe (see §3)
```

The feature's committed suite is green: **103 passed, 0 failed, 0 skipped**
(`git grep "skip: true" HEAD -- app/test/features/rewards/` → no hits, so
iteration 2's "three skips" note is resolved). No `google_fonts`/`GoogleFonts`,
no `letterSpacing`, no `skip:`, no `// ignore` in any committed file. No
simulator was touched at any point in this stage.

---

## 1. Findings

### 1. MINOR (carried — iteration-2 finding 1) — a raw exception in parent-facing copy, and the feature's own test suite says that is wrong

`app/lib/features/rewards/presentation/widgets/p14_reward_meta.dart:114-121`

```dart
/// Inline caption above Save when the write fails (plan §4): the friendly
/// sentence first, then the technical detail. …
static String saveError(Object error) => 'Could not save the reward: $error';
static String deleteError(Object error) => 'Could not delete the reward: $error';
```

· rendered at `p14_reward_editor_sheet.dart:93` and `:116`

Iteration 2 raised this as "friendly sentence first, then the technical
detail". Reading the feature's own tests settles it: the full-screen surface has
a **dedicated test asserting the opposite rule** —
`test/features/rewards/rewards_states_test.dart:137-140`:

```dart
// Static copy only — the raw `Bad state: boom` exception never reaches
// user-facing text (stage 4, finding 2; `paywall_view.dart` precedent).
expect(find.textContaining('boom'), findsNothing);
```

So the feature already forbids a raw exception in parent-facing copy on one
surface and permits it on the other. A parent whose `Save` fails reads
`Could not save the reward: SqliteException(1): no such column: created_at` in
the one place the message is guaranteed to be read.

Two proofs currently **depend on the violation**:
`p14_bugs_test.dart:287` and `:489` both locate the caption with
`find.textContaining('disk full')`. `rewards_a11y_test.dart:504` and
`rewards_write_failures_test.dart:282/329/366` use prefix-style locators
(`Could not save the reward`) and keep working unchanged. `2_build.md:87-94`
correctly escalated this as needing an orchestrator ruling.

**Ruling requested → drop the tail.** Fix:

```dart
static const String saveError = 'Could not save the reward. Please try again.';
static const String deleteError =
    'Could not delete the reward. Please try again.';
```

then re-point `p14_bugs_test.dart:287` and `:489` to
`find.text('Could not save the reward. Please try again.')` (the `:489` one
needs a semantics handle for `getSemantics` — use
`find.bySemanticsLabel(RegExp('Could not save the reward'))`), add
`expect(find.textContaining('disk full'), findsNothing)` beside line 140 so the
rule is pinned for both surfaces, and log `error` (or park it on
`state.errorMessage`) instead of printing it. Two locators change; nothing else
does.

### 2. MINOR (carried — iteration-2 finding 5) — `.editbtn` is still a hand-rolled shape inside a feature

`app/lib/features/rewards/presentation/widgets/p14_reward_card.dart:148-189`

`NestIconButton` paints `CircleBorder` (`core/design_system/components/nest_icon_button.dart`),
so `_EditButton` re-creates the design's 44×44 **radius-12** square (44 target,
r12, 1 px `--line`, `--surface`, 24 px `--ink-2`) to get the shape right. The
deviation is documented and `reward_card_widget_test.dart:126` asserts the rect,
fill, border and radius rather than a text position — which is exactly what
UI-CHECK-MEASURES-SHAPES asks for. The decision is right; the duplication is
still waiting on the shared component.

**Fix (unchanged from iteration 2, still not done):** add a `NestIconButton.shape`
/ `NestSquareIconButton` request to `SHARED_REQUEST.md` (see finding 3 — the file
does not currently contain it).

### 3. MINOR (new) — `SHARED_REQUEST.md` describes a mechanism P14 has abandoned, and omits an item `2_build.md` says it has

`docs/screens/P14/SHARED_REQUEST.md:22-25` vs `docs/screens/P14/2_build.md:98-100`

```
SHARED_REQUEST.md:   `RewardEditorSheet` applies the resting 92 % cap and the keyboard padding itself.
2_build.md:100:      SHARED_REQUEST.md still open — … and `NestIconButton.shape` (the 44×44 radius-12 `.editbtn`).
```

Both statements are now false. The iteration-3 build **deleted** the 92 % cap
(`p14_reward_editor_sheet.dart:146-151` replaced the
`math.max(0, (keyboard > 0 ? screen : screen * 0.92) - chrome - keyboard)` sum),
and `SHARED_REQUEST.md` contains no `NestIconButton` line at all — its only
heading is the keyboard inset.

This matters more than ordinary doc drift: this file is the orchestrator's
specification for a change it will apply to **every** screen with a form sheet.
It currently asks for option (b) "drop the fixed cap and let callers cap
themselves, plus make the sheet body scrollable" — the exact approach P14 has
just proved wrong (the caller-side cap was the source of P14-B08's 13–20 px
overflow). Following it as written would reproduce the bug on six other
screens.

**Fix:** rewrite the `Blocks:` paragraph to name the mechanism that shipped —
`NestBottomSheet` should itself hand its `child` a loose `Flexible` and let the
caller pad by `viewInsets`, after which `showRewardEditorSheet` and the local
cap both disappear — and append the `NestIconButton.shape` item that
`2_build.md:100` already claims is there.

### 4. MINOR (new) — `RewardEditorSheet` is now a `ParentDataWidget` inside a shared component's private `Column`

`p14_reward_editor_sheet.dart:146-151` → `core/design_system/components/nest_bottom_sheet.dart:30-77`

The B08 fix is the right idea — let the layout engine hand the form exactly
what is left instead of re-deriving the chrome — but it is implemented by
returning `Flexible` from `RewardEditorSheet.build`, and `Flexible` is only
legal as a direct child of a `Flex`. That is true today because
`NestBottomSheet`'s `child` is a direct child of its `Column`
(`nest_bottom_sheet.dart:75`), and `Flexible` is currently used by no other
caller in the app. If that shared component's `Column` is ever replaced by a
`Stack`, or `child` gains a wrapper, every `/rewards` sheet open throws
`Incorrect use of ParentDataWidget` — a runtime crash on a screen whose lib
code was not touched.

**Fix:** make the shared component own it, which is finding 3's request
anyway: have `NestBottomSheet` build
`Flexible(fit: FlexFit.loose, child: child)` internally and document the
contract, or add a `NestBottomSheet.scrollable` variant. Then
`RewardEditorSheet` goes back to returning a plain `Padding` +
`SingleChildScrollView`. Until it lands, add one line to the `Flexible`'s doc
comment naming `nest_bottom_sheet.dart:30` as the required parent.

### 5. MINOR (new) — `Try again` has no in-flight guard, so a double tap stacks a second subscription

`app/lib/features/rewards/presentation/views/rewards_view.dart:238-244`
· `app/lib/features/rewards/presentation/bloc/rewards_bloc.dart:20-34`

`_closeOnError` was added precisely so a retry could not stack a live
subscription on a dead one, and `rewards_bloc_test.dart` proves the single-retry
case (`attempt == 2`, `watches == 2`). The button, though, dispatches
unconditionally:

```dart
onPressed: () =>
    context.read<RewardsBloc>().add(const RewardsLoadRequested()),
```

Two taps inside one frame add the event twice. bloc's default transformer is
concurrent, so `_onLoadRequested` runs twice and each opens its own
`emit.forEach` — reopening exactly the hole `_closeOnError` closes. Impact is
bounded (the two `onData` callbacks produce `Equatable`-equal states, and
`BlocBase.emit` dedupes them, so nothing repaints), but it is two live Drift
`QueryStream` listeners where one is intended, and the guard that would prevent
it is already visible to the view: the surface is only rendered on
`failure`.

**Fix (no new dependency — `bloc_concurrency` is not in `pubspec.yaml` and a
screen agent may not add it):** ignore a duplicate in the bloc, right where the
status is already published:

```dart
Future<void> _onLoadRequested(RewardsLoadRequested event, Emitter<RewardsState> emit) async {
  if (state.status == RewardsStatus.loading) return; // a retry is already in flight
  emit(state.copyWith(status: RewardsStatus.loading));
  …
}
```

and pin it in `rewards_view_test.dart`: tap `p14_try_again` twice, assert
`attempt == 2`, not 3.

### 6. MINOR (new) — the `.scroll` bottom override `66` is written three times, and one copy must track the others

`rewards_view.dart:103`, `:133`, `:136`

`_RewardsScroll` pads with `66` (the SPACING_SPEC §8 P14 override — correct and
cited in the class doc), `_RewardsCenteredScroll` pads with `66`, and its
`ConstrainedBox(minHeight: constraints.maxHeight - 66)` subtracts the same
number so the empty/failure surfaces centre in the viewport. Changing the
padding without the `minHeight` (or vice-versa) silently shifts the centring by
the difference — the exact class of bug P14-B02 was, and no test would fail.

**Fix:** one `static const double scrollPadBottom = 66;` on
`_RewardsScroll` (with the `SPACING_SPEC.md:93` citation) used at all three
sites, and read `NestSpacing.padSide`/`homeH` style rather than a literal.

### 7. MINOR (carried — iteration-2 finding 6, half open) — `p14_test_support.dart` still describes a settled change as pending

`app/test/features/rewards/p14_test_support.dart:36` and `:126-136`

> "the canonical query and the `needsOk` seed correction **arrive with the next
> main merge** … The order itself is proved separately by the **skip-marked**
> `[P14-ORDER]` test"

Both landed: `rewards_repository_impl.dart:25-27` serves
`watchRewardsInCreationOrder`, the seed ships `needsOk: false` for
`r-baking`, and `rewards_order_test.dart:14-17` was already reworded to say so
and is **not** skipped (`git grep "skip: true"` → none). A stale
"blocked on main" comment in the harness is how the next agent re-opens a
decided question.

**Fix:** reword both to the current fact — creation order is live, `seedInsertionOrder`
is only used by the live `[P14-ORDER]` proof.

### 8. MINOR (new) — an unused a11y helper marks the one real gap in the semantics contract

`app/test/features/rewards/p14_test_support.dart:153-187` (`tappableSemanticsNodes`)

`grep -rn tappableSemanticsNodes test/features/rewards/` → **only its own
definition.** It walks the whole semantics tree and returns every node carrying
`SemanticsAction.tap`, which is precisely the check the owner
ACCESSIBILITY rule asks for ("every interactive element must be operable") and
precisely the check `rewards_a11y_test.dart:42-73` does *not* make: that test
walks a hard-coded label list (`Back`, six approval labels, six edit labels,
`+ New reward`) and asserts each is announced once. A new, unlabelled or
unlisted control would pass the whole file silently.

Everything that *is* listed is covered well — one labelled node per control,
`toggled`/`enabled` states read from the DB, ≥44 px targets, `performAction`
driving the real Drift row / real route pop / real sheet open, a disabled Save
with no tap, and the switch live 5 px above, on and 5 px below the drawn track.
The gap is exhaustiveness, not correctness of the covered set.

**Fix:** use the helper where it was written for —
`expect(tappableSemanticsNodes(tester).map((n) => n.getSemanticsData().label),
containsAll(<String>[...labels, 'Try again']))` and assert the node count
equals the expected list length, so an extra tappable node fails. If exhaustiveness
is not wanted, delete the 35 lines rather than leave dead harness code.

### 9. MINOR (new) — stale test comment: the ambiguity finding 2 removed is still documented as present

`app/test/features/rewards/rewards_a11y_test.dart:372-373`

```dart
// `'Needs my OK'` is both the visible row label and the switch's
// semantic label, so the switch is addressed by type here.
…
'Needs my OK switch': tester.getRect(find.byType(NestToggle).last),
```

The visible label is now `ExcludeSemantics`'d
(`p14_reward_editor_sheet.dart:198`), so `Needs my OK` is announced by exactly
one node — the switch — which is why the sibling test at `:345-359` can assert
`actionableNodes(tester, 'Needs my OK') hasLength(1)` and pass. The comment
describes the pre-fix state and justifies a workaround that is no longer
needed.

**Fix:** address it as `tester.getRect(find.bySemanticsLabel('Needs my OK'))`
and delete the comment, so the two tests use one addressing scheme.

### 10. MINOR (carried — iteration-2 finding 7) — shared module-level mock; two pumped tests without `disposeApp`

`app/test/features/rewards/rewards_view_test.dart:23`, `:333`, `:371`

`final _failRepo = _FailRepository();` is created once at library scope and
re-stubbed in both failure tests, so stub state accumulates across them (each
`when` overwrites its predecessor, so it works — but the tests are order-coupled
through a mutable singleton). Both tests call `setUpTestScope()`, which registers
`AppSession` and its live Drift watch (`test_scope.dart:22-31`), and neither
ends with `disposeApp(tester)`, so RULES §7's drain is skipped. The suite is
green, which proves no `QueryStream` cancellation timer fires today — the gap
is that the file does not say why it is safe, and the next person to change the
stubs inherits the risk.

**Fix:** build the mock inside each of the two tests (or
`addTearDown(() => _FailRepository())`), and add the drain — or a one-line
comment saying which of the two it is and why.

---

## 2. Verified clean — do not re-litigate

**Scope / RULES §1.** Every changed path is inside the allow-list:
`lib/features/rewards/{data,presentation}/**`,
`test/features/rewards/**`, `docs/screens/P14/**`. No `core/**`, no `app/**`, no
`tools/**`, no other feature, `analysis_options.yaml` untouched, no pubspec
change. The deleted `rewards_placeholder_card.dart` has zero remaining
references (`grep -rn rewards_placeholder_card app/` → empty).

**Orchestrator rules.** `ORCHESTRATOR_NOTES.md` (12:27 + 12:35) fully applied
and verified in code: `watchItems()` serves
`watchRewardsInCreationOrder(Seed.familyId)`
(`rewards_repository_impl.dart:25-27`) and no price sort survives in the
feature (only `coinPrice` *column writes*); the toggle renders `reward.needsOk`
and never a literal, so the seeded `needsOk: false` for "Baking together"
renders OFF with no code change (`rewards_order_test.dart:73-95` pins it from
the DB); creation order is asserted live and unskipped (`rewards_order_test.dart:51-71`).
PIP, CHILD ORDER, PERIODS, TRIAL, `NestChipWrap` and `NestBalancedText` are N/A
— no Pip, no children, no quest periods, no subscription write, no chips, and
`P14-rewards.html`'s CSS sets no `text-wrap: balance` on `.intro` or
`.nav-bar.compact .nav-title`.

**Architecture.** Feature-first; `domain/` holds entities + the abstract
repository only, with no Drift import anywhere in `presentation/`; one
`RewardsBloc`, provided at the route level in `rewards_routes.dart:20-25` so
the `emit.forEach` subscription dies with the route; `registerRewards` untouched
(lazy-singleton repo, bloc factory); `/rewards` top-level per the route table.
The editor sheet reports intent through callbacks and never touches the
repository or the bloc's state — all four writes go through events. Entity
`Reward` is an Equatable value object; `Reward.detail` is carried and unused by
P14 (plan §2 — correct, `updateReward`/`createReward` write no such column).

**Error handling.** Write failures never reach the bloc's state
(`rewards_bloc.dart:45-100`), so a failed toggle cannot replace the list — the
iteration-1 blocker stays closed. The sheet keeps the typed name, shows a danger
caption and stays open; Save is disabled while a write is in flight
(`_saving`) so a double tap cannot create two rows; Delete is armed by a second
tap whose label change is asserted; `_completeError` leaves a settled channel
alone. `_closeOnError` forwards the first stream error **and closes**, so the
handler completes and the retry resubscribes from scratch with one live
subscription — the `TodayBloc`/`PocketMoneyBloc` house pattern, cited in place.
The remaining exception-in-copy leak is finding 1.

**Accessibility.** Every interactive node carries `SemanticsAction.tap`: nav
back, all six switches (label + `toggled:` + `enabled:` + `onTap`), all six
edit buttons (`Semantics(button:, enabled:, label:, onTap:)` — **`onTap` on the
Semantics node** per RULES §8, inner icon `ExcludeSemantics`), `+ New reward`,
the empty-state action, `Try again`, the sheet's Close/±/Save/Cancel/Delete. A
disabled Save advertises no tap and reports `enabled: false`. `performAction(tap)`
is asserted to change **real** state: a switch writes its Drift row, edit opens
the prefilled sheet, `+ New reward` opens a blank one, Back returns to `/today`
via `pushedPath`. Tap targets ≥44 measured for every control, and the switch is
live 5 px above, on and 5 px below the drawn track. Finding 2's duplicate
announcement is closed. Exhaustiveness is the only gap — finding 8.

**Performance.** Stateless view; `const` where it matters; a per-row
`ValueKey('p14_reward_${reward.id}')` so identity survives stream re-emissions;
no `setState` in the list path and no optimistic local toggle state (the card
follows the stream, so a failed flip snaps back honestly). `Transform.translate`
is paint-only. `IntrinsicWidth` costs one intrinsics pass per row on a 6-row
list. The sheet's `TextEditingController` is disposed and both async paths are
`mounted`-guarded. Writes emit nothing on success, so one tap is one rebuild. No
rebuild storm. (Finding 5 is the one subscription leak, not a rebuild storm.)

**Geometry / UI-CHECK-MEASURES-SHAPES.** The card's documented measurements
(`p14_reward_card.dart:8-22`) reproduce the light render ÷3 (card 20→370 × 122
high, pitch 138; tile 40×40; pill 25 high; toggle track x 179; edit 44×44) and
are asserted numerically — not by text position — by
`reward_card_widget_test.dart` (rects, the exact 44×44 radius-12 edit rect, the
fallback tile), `rewards_responsive_test.dart:52` (20 px gutter, 16 px pitch,
`edit.size == 44×44`, the button sharing the card edges at 52 high, across
320/390/430 × 1.0/1.3) and `rewards_view_test.dart`. `IntrinsicWidth` + loose
`Flexible` correctly reproduces CSS `flex:0 1 auto`; `Transform.translate(−4)`
reproduces `.toggle::before{left:-4;right:-4}` while keeping the 59 px hit box.
`NestCoinPill(xSmall)` is exactly the HTML's inline override (13 px, `5px 9px`,
15 px coin, gap 6). The 40 px tile's radius-12 deviation from `.icon-tile`'s
`--r-m` follows the merged `NestListRow` owner-QA precedent
(`core/design_system/components/nest_list_row.dart:63-65`), not a local
invention.

**Tokens / design system.** No `Colors.*` except `Colors.transparent` at
`rewards_view.dart:280`, which is copied verbatim from the shared helper's own
call (`nest_bottom_sheet.dart:122`). No `Color(0x…)`, no hex, no literal
`fontSize:` anywhere in the feature. Every value resolves through `context.nest`,
`NestType`, `NestSpacing`, `NestRadii`, `NestDevice` and shared components
(`NestStatusBar`, `NestNavBar(compact:)`, `NestCoinPill(xSmall)`, `NestToggle`,
`NestButton`, `NestTextField`, `NestStepper`, `NestBottomSheet`,
`NestEmptyState`, `NestIcon`/`NestIcons`, `showNestToast`). The only
hand-built widgets are `_EditButton` (finding 2) and the sheet's opener — both
justified, both filed.

**Copy — character-for-character against `P14-rewards.html:13-21`.** `Reward shop`;
`Things coins can buy — you decide. Children spend coins, never pounds.` (em
dash U+2014); `+ New reward` (ASCII `+`); `Needs my OK`; the five names with
`é` U+00E9 from `Seed.demo()` (`seed.dart:521-526`); the two deliberately
shortened `aria-label`s (`Edit Stay up later`, `Edit Trip to the park cafe` —
ASCII "cafe", copied verbatim rather than composed from the accented title,
`p14_reward_meta.dart:65-75`); coin pills `{n} coins`; the six approval labels
from the HTML's own `aria-label` attributes, keyed by reward **id** so they are
never re-derived from the title. `rewards_states_test.dart:236` +
`p14_test_support.dart:55-72` pin the HTML strings; UK spelling throughout the
feature and its comments (no `grep` hits for the usual US spellings).

**BOTTOM EDGE / ALIGNMENT.** No bottom bar, tab bar or CTA panel on this
screen, so `Scaffold(paper)` reaches the physical edge in both themes and the
editor sheet is a `NestBottomSheet` in `paper` — a coloured strip is not
reachable. Gutters are single-sourced from `NestSpacing.padSide` and asserted at
320/390/430 × 1.0/1.3 in both themes (`rewards_responsive_test.dart:52`,
`:338`). `5_ui.md` measured title/intro/every card top and the card edges at
Δ0 with no uniform shift.

**Children's Code.** Parent-mode screen. No analytics, no ads, no network, no
child data read or written by P14's own path (`watchItems` touches only the
`rewards` table; `watchRequests`/`approve`/`deny` are the K08 path and are not
reachable from this view), no coins/£ conversion, no `subscription_status`
write.

---

## 3. Process notes — not findings (orchestrator PROCESS ITEMS rule)

* A stage-6 bugs loop is running **concurrently in this worktree** right now. It
  has created and is actively editing untracked
  `app/test/features/rewards/_p14_it3_probe_test.dart` (and briefly
  `_p14_it3b_probe_test.dart`), which is why `flutter analyze` reports 10 infos
  (all `library_private_types_in_public_api` / `document_ignores` /
  `eol_at_end_of_file` inside it), `dart format .` reports 1 changed file, and
  `flutter test` reports `-3` ("probe double try again", "probe retry after
  stream error recovers", "probe sheet semantics"). Every one of those is the
  loop's own in-flight probe, not the committed branch — the committed suite is
  **+103, 0 failed, 0 skipped**. The probe files must be deleted before this
  branch merges. Finding 5 overlaps the "double try again" probe; it is filed
  here on its own evidence so it is not lost if the probe is dropped.
* `git status --porcelain` also shows modified `docs/screens/P14/.brief_*.md`
  (loop bookkeeping) and untracked `docs/screens/P14/ui/app_light_3.png`.
* Merge order / being behind `main`: not reviewed, by rule.

## 4. Handoff

* **Stage 5 (UI, simulator 604697A9 only):** the committed layout did not move
  in iteration 3 (the view diff is the `failure` branch and comments only) and
  the data did — the visible sequence is 50 → 80 → 60 → 100 → 150 with
  "Baking together" **off** and `Choose dinner` (90) below the fold. Re-measure
  anyway; report the title y, intro y and each card top design vs app, the ±2 px
  verdict, the toggle track x (179), the gutters and the bottom edge.
* **Stage 6 (bugs):** finding 1 is the one worth doing next — it is cheap
  (two test locators), it makes the inline caption obey the rule
  `rewards_states_test.dart:140` already asserts for the full-screen surface,
  and `2_build.md` correctly refused to rule on it unilaterally. Finding 5
  overlaps your "double try again" probe — if it is real, the bloc-side
  `if (state.status == RewardsStatus.loading) return;` guard needs no new
  dependency. Findings 3, 4, 6, 8 and 9 are housekeeping; 2, 7 and 10 are
  iteration-2 carry-overs.

VERDICT: PASS