# P05 · Add children — QA code review (STAGE 4, iteration 8)

Scope: `git diff main...HEAD` on branch `screen/P05`, reviewed against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md` (§1 scope, §4 data contract,
§7 done criteria), `docs/DESIGN_SPEC.md` §5 P05, `docs/design/SPACING_SPEC.md`
§6/§10.6, `design/html-source/screens/P05-add-children.html` +
`components.css`, the design system as used, and
`docs/screens/P05/ORCHESTRATOR_NOTES.md` (all items re-checked as closed).

Iteration 8's delta is small and was reviewed line by line:

* `add_child_form_card.dart` — both interactive rows moved `Wrap` →
  `NestChipWrap`; the design's `role="group"` `Semantics` node moved off the
  row onto the row's own `.lbl` heading (its reason is correct:
  `RenderSemanticsAnnotations` is a `RenderProxyBox`, so its `hitTest` stops at
  `size.contains(position)` and would re-clip the ±6 px reach — see
  `nest_chip_wrap.dart:9-16` for the same reasoning on the shared side).
* `add_children_view.dart` — the `.h1` moved `Text` → `NestBalancedText`
  (`components.css:29` sets `text-wrap: balance` on `.h1`), plus
  `textAlign: TextAlign.left`.
* `p05_bugs_test.dart` — `[P05-BUG-11]` un-skipped and rewritten to tap 5 px
  above/below the block; the header no longer advertises a skip.
* `add_children_test.dart` — BUG-11 proof flipped from "clipped by the Wrap"
  to a live `isTrue` proof, the characterisation test that asserted the bug
  was deleted, a new pill-background/width proof landed, and the gutter proof
  switched to the `NestBalancedText` box.
* `p05_view_metrics_test.dart` — new file, bundled-face production metrics.

## Gates re-run independently on `main...HEAD`

```
dart format --set-exit-if-changed .        → 391 files, 0 changed, exit 0
flutter analyze                            → No issues found!, exit 0
flutter test test/features/family          → 00:05 +130: All tests passed!, exit 0
  ├─ add_children_test.dart @HEAD blob     → 00:04 +114: All tests passed!
  └─ p05_bugs_test.dart + p05_view_metrics_test.dart → 00:01 +16: All tests passed!
grep -rn "skip:" test/features/family/     → no matches (0 skips)
grep -rn "google_fonts\|GoogleFonts"        → no matches (feature + tests)
grep -rn "letterSpacing" lib/features/family/ → no matches
grep -rn "Wrap(\|Row(" lib/features/family/presentation/ → no matches
```

Because a parallel stage was writing `app/test/features/family/add_children_test.dart`
while this review ran, the committed blob was also executed on its own from a
scratch package directory (`test/features/zz_p05_head_check/`, since removed) so
the gate numbers above belong to `main...HEAD` and not to the in-flight file.

**Result: 0 blocker, 0 major, 7 minor + 1 out-of-scope note. VERDICT: PASS.**

---

## Findings

### 1. MINOR — the save path's `catch` is too narrow; a non-`Exception` throw leaves the form permanently disabled

`app/lib/features/family/presentation/bloc/family_bloc.dart:95`

```dart
} on Exception catch (error) {
```

`saveInProgress: true` is cleared **only** inside this handler (line 99). A
throw that is not an `Exception` — `ArgumentError`, `StateError`,
`TypeError`, any `Error` — is not caught here, escapes to
`Bloc.observer.onError`, and leaves `saveInProgress == true` forever: both CTA
buttons stay disabled with no message and no way back. `SqliteException`
implements `Exception`, so the common path is covered; the gap is the
non-SQLite failures a Drift insert can raise (constraint/value errors surface
as `ArgumentError`, which is an `Error`).

Fix: use bloc's documented catch-all —

```dart
} catch (error, stackTrace) {
  debugPrint('P05 addChild failed: $error\n$stackTrace');
```

(keep the existing `debugPrint`, add the stack trace; the rest of the handler
is already correct.)

### 2. MINOR — the design's `role="group"` is no longer in the semantics tree, and the test that documents it still says it is

`app/lib/features/family/presentation/widgets/add_child_form_card.dart:72-82`
and `:104-114`; `app/test/features/family/add_children_test.dart:2921`
(name), `:2934` (reason), `:2945-2946` (comment).

The HTML marks both rows `role="group" aria-label="Age band"` /
`"Avatar colour"` (`P05-add-children.html:70,77`). The iteration-8 fix moved
the labelled `Semantics` node onto the `.lbl` heading — the right call, because
a `Semantics` container around the row is exactly the tight box that re-breaks
P05-BUG-11 — but the consequence is that the chips/switches are no longer
inside a group node at all, and:

* the test is still named `the chip and swatch groups are labelled containers`,
* its `reason` still reads `role=group for the age band (design role="group")`,
* its comment still says the controls stay "reachable inside the groups".

All three now describe a node that is a *sibling* of the row, not the group, so
the proof passes without proving anything about grouping. (The behaviour itself
is acceptable and already recorded as a conscious trade-off in `6_bugs.md`.)

Fix, two parts:
1. Honest test now — rename to `the age-band and avatar-colour headings are
   labelled nodes`, change the reason to `the group's aria-label survives on
   the .lbl heading (a Semantics container on the row would re-clip BUG-11)`,
   and reword `:2945-2946` to "the controls stay reachable *after* the label".
2. Real fix, via the shared path RULES §2 requires: file a `SHARED_REQUEST`
   asking `NestChipWrap` to take a `groupLabel` and emit a genuine group node
   from its render object (override `visitChildrenForSemantics` /
   `describeSemanticsConfiguration` so the widened `hitTest` and the group node
   coexist). `lib/core/**` is off-limits to a screen branch, so P05 cannot do
   this itself.

### 3. MINOR — the ALIGNMENT proof now measures the wrapper, so it no longer pins the painted heading to the gutter

`app/test/features/family/add_children_test.dart:994`;
`app/test/features/family/p05_view_metrics_test.dart:157-166`.

`find.text(…)` was swapped for `find.byType(NestBalancedText)` because the
wrapper's `LayoutBuilder` box is full width while the inner `Text` is narrowed
to the balanced break width — correct reasoning, and the intent (the *band*
fills the 20 px gutters) is preserved. But no remaining assertion pins the
*painted* heading's left edge: switching `textAlign` at
`add_children_view.dart:204` back to the `NestBalancedText` default
(`TextAlign.center`) would leave both the gutter test and the shipped-face test
green while centring the title inside the gutter — an owner-ALIGNMENT
regression that only the pixel comparison would catch.

Fix — one line in `p05_view_metrics_test.dart`, the file that already loads the
bundled faces:

```dart
expect(tester.getRect(find.text('Who\u2019s in your nest?')).left,
    NestSpacing.padSide, reason: '.h1 is left-aligned on the gutter');
```

### 4. MINOR — hard-coded 48 px button height

`app/lib/features/family/presentation/views/add_children_view.dart:118`

```dart
minHeight: 48,
```

Correct value (`.add-another { min-height: 48px }`, `P05-add-children.html:24`),
and `Continue` correctly falls through to `NestButton`'s 52 default
(`.field input`/`.btn` height 52). But 48 has no token: `NestSpacing` tops out
at `s10 = 40` and `NestSpacing` is `lib/core/**`, which RULES §1 forbids a
screen branch from editing.

Fix: file a `SHARED_REQUEST` for a token-level 48 (e.g. `NestSpacing.gap48`,
or expose the design's `.add-another` height on `NestButton`), then use it.
This is the only magic length left in the P05 tree apart from the documented
`.edit { top: 1px; right: 1px }` (`kid_card_grid.dart:115-116`, which has no
token either and carries its own explanatory note).

### 5. MINOR — one assertion in the new BUG-11 proof is tautological

`app/test/features/family/add_children_test.dart:2437-2441`

```dart
expect(
  row.top - label.bottom,
  lessThan(NestChip.hitSlop + NestSpacing.s1),   // 4 < 10 — always true
  reason: 'the widened tap target stops inside the label box',
);
```

`NestChip.hitSlop` is 6 and `NestSpacing.s1` is 4, so the bound is 10 while the
measured value is fixed at 4 by the preceding assertion on line 2434-2436: the
expectation can never fail. The *behavioural* proof that follows (tap at
`label.center.dy` leaves the selection untouched) is the real one and is good;
this numeric line is decoration that reads as a guard.

Fix — tighten the bound to the claim it is making (4 < 6, i.e. the overhang
does cross the 4 px gap into the heading box):

```dart
lessThan(NestChip.hitSlop),
reason: 'the 6 px reach crosses the 4 px gap and lands on the heading',
```

### 6. MINOR — `SHARED_REQUEST.md` still titles P05-BUG-11 "open"

`docs/screens/P05/SHARED_REQUEST.md:317-318`

```
# Shared request — P05 `NestChip`'s overlaid 44-px target is unreachable inside
# the chip `Wrap` (P05-BUG-11, open — effective target is 32×pill)
```

The shared fix landed (`core/design_system/components/nest_chip_wrap.dart` is
on main), P05 adopted it (`add_child_form_card.dart:87` and `:119`) and the
proof is un-skipped and green. A stale "open — effective target is 32×pill"
heading will send the next reader (and the next merge) looking for a defect
that no longer exists.

Fix: retitle to `— LANDED on main` and close with one line: adopted in
`add_child_form_card.dart:87,119` in iteration 8; the `[P05-BUG-11]` proof in
`p05_bugs_test.dart` is un-skipped and passes.

### 7. MINOR — a comment names the wrong typeface

`app/test/features/family/p05_bugs_test.dart:505-506`

```
// Nunito, so the chips wrap to two runs here; a point inside the row
```

The chip label is **Inter** (`NestType.chipLabel` →
`_inter(14, 20, w600)`, `tokens/typography.dart:86-88`), not Nunito — the
comment two blocks up in the same file gets this right ("The test fallback
font is ~30% wider"). The conclusion (two runs in the test font, so the proof
must use the block edges) is correct and I verified the arithmetic: at the
322 px content width the four pills measure ≈332 px in the square test font.

Fix: `// The test fallback font is wider than the bundled Inter metrics, so the
chips wrap to two runs here; …`

### 8. MINOR (not in `main...HEAD` — process item, flagged for stage 6) — in-flight balanced-headings test compares px against a unitless ratio

`app/test/features/family/add_children_test.dart` (uncommitted, added by the
concurrent stage-6 agent after this review started)

```
Expected: a value less than or equal to <4.142857142857142>
  Actual: <68.0>
ThemeMode.light 320.0 @1.0x
```

`NestType.h1(...).height` is the **ratio** 34/28 = 1.2143, so
`lineHeight * 3 + 0.5` = 4.14 is a bound in ratio units compared against a
height in logical pixels. The heading itself is correct: 68.0 = 2 × 34 is the
right two-line box for "Who's in your nest?" at 320 px. The expectation is
what is wrong.

Fix: compare against a pixel line box —

```dart
final style = NestType.h1(color: …);
final lineBox = (style.fontSize ?? 28) * style.height!;
expect(rendered.height, lessThanOrEqualTo(lineBox * 3 + 0.5), …);
```

Recorded as minor and explicitly **not** counted as blocker/major: per the
orchestrator's PROCESS ITEMS rule, uncommitted work belongs to the loop, and
`main...HEAD` is green. It is raised because it will make `flutter test` red
the moment that file is committed.

---

## Out-of-scope observation (performance, no action required now)

`FamilyDraftChanged` is dispatched on every keystroke
(`add_children_view.dart:226-228`) and `draftNickname` is in `FamilyState.props`
(`family_bloc.dart` / `family_state.dart:80-90`), so each character emits a new
state and rebuilds the whole `_Body`: the `ListView`, `KidCardGrid`
(`GridView.builder` + `LayoutBuilder` + `childAspectRatio`) and
`NestBalancedText` (which re-runs its `TextPainter` search,
`nest_balanced_text.dart:61-90`, once the heading wraps). It is bounded — no
loop, no timer, at most two kid cards, and at 390 px the heading is a single
line so only one `TextPainter` layout runs per keystroke — so this is not a
rebuild storm and it is not a finding. If it ever shows up in a profile, the
cheapest correct fix is to wrap `KidCardGrid` in
`BlocSelector<FamilyBloc, FamilyState, List<FamilyChild>>` (roster-only
rebuilds) and leave the draft in the bloc state, which the Continue
validation already reads directly.

## Confirmed clean (no action)

* **RULES §1 scope.** `git diff main...HEAD --name-status` touches only
  `app/lib/features/family/{data,presentation}/**`,
  `app/test/features/family/**` and `docs/screens/P05/**`. Nothing in
  `app/lib/core/**`, `app/lib/app/**`, another feature, `app/test/app/**` or
  `tools/screens/**`. `analysis_options.yaml` untouched.
* **ARCHITECTURE.md.** One bloc per feature (`FamilyBloc`, events/state in the
  feature); one view per route; the two new widgets and
  `child_display.dart` are feature-private; `domain/` is untouched (entities +
  abstract repo only); the repository interface is unchanged (only the impl
  gained `_ageYearsForBand`); DI and routes untouched, so `/add-children` keeps
  its `FamilyBloc` at the route level.
* **State layer / RULES §4.** `watchItems()` + `watchChildren()` are combined
  **once** and subscribed with a single `emit.forEach` — no re-added load
  events. `_closeOnError` forwards the first error and closes, so a failed load
  does not leak a watcher set per "Try again". `FamilyRepositoryImpl` delegates
  ordering to the shared `createdAt, rowid` watch, so the CHILD ORDER ruling
  holds app-wide with no local sort anywhere in P05.
* **Design-system usage.** No re-implemented component. The only colour literals
  in the feature are `Colors.transparent` on the two transparent `Material`s
  (a Material primitive, not a brand token). Every size is `NestSpacing` /
  `NestDevice` / `NestAvatarSize` / `NestRadii` except finding 4. Type is
  `NestType` only, no `google_fonts`, no `GoogleFonts.*`, no `letterSpacing`
  reintroduced (so the P12/K02 tracking call sites stay the only ones).
* **CHIP ROWS rule.** Zero `Wrap(`/`Row(` left in the feature; both
  interactive rows use `NestChipWrap` (age chips `:87`, swatches `:119`).
* **BALANCED HEADINGS rule.** `.h1` is the only balanced class on this screen
  (`components.css:29`); it renders through `NestBalancedText` with the same
  copy, `NestType.h1`, `maxLines: 3` and ellipsis, and `.h3`/`.body`/`.caption`
  correctly stay plain `Text`.
* **DESIGN_SPEC §5 P05 — every element present and copy character-exact.**
  h1 "Who’s in your nest?" (U+2019); subtitle "Nicknames only — no photos, no
  email." (U+2014); two roster cards (Maya, then Leo) with a 44 px edit pencil
  each and "Age 7–9" / "Age 4–6" (U+2013); "Add a child" card; Nickname field
  with the design hint; chips "4–6 / 7–9 / 10–12 / 13+" (U+2013, `13+`
  untouched) with the design's 7–9 default; five 44 px swatch circles with the
  design's peach default; "We only ask for an age range so quests suit them.";
  secondary "Add another child" (plus icon, 48 high); primary "Continue"; CTA
  caption "You can change any of this later in Family.". UK spelling throughout
  ("Avatar colour", "Nicknames"); no US variants.
* **Form rhythm vs the HTML** (`.form-card` padding 14, `.field` margin-top 10,
  `.lbl` 8, `.chip-row` 4, `.swatches` 4, `.form-note` 6, `.scroll > …` 14
  and 12, `.scroll` bottom padding 32): every gap in
  `add_child_form_card.dart:51-135` and `add_children_view.dart:187-236` is the
  token for that CSS value, and each has a proof in
  `add_children_test.dart` ("P05 form card rhythm matches the HTML").
* **PIP rule.** N/A — this screen has no Pip slot (avatar initials only), as
  `5_ui.md` records. Nothing uses `pip_stage_*.svg`.
* **Owner rules.** Bottom edge: `NestBottomCta` paints `tokens.surface` and
  puts the home-indicator inset **inside** that box via `SafeArea(top: false)`,
  so no page-tint strip appears under the bar in either mode. Alignment: one
  `padSide` gutter for the h1, subtitle, roster and card, and the CTA's edges
  equal the card's.
* **Accessibility.** 44 px minimum on every control (chips via the widened
  hit test, swatches 44×44, both buttons 48/52, the pencil 44, nav back 44);
  the h1 is `Semantics(header: true)`; chips expose `button` + `selected`;
  swatches expose `button` + `selected` + a colour-name label; the pencil reads
  "Edit Maya"/"Edit Leo"; the field's error is a live region inside
  `NestTextField`; the validation message is not colour-only. Finding 2 is the
  only a11y gap.
* **Children's Code.** No analytics, ads, network or third-party SDK anywhere in
  the feature (grep for `analytics|advert|http|firebase|sentry|package:http` →
  no matches). The two `debugPrint`s log a colour token and an exception object
  locally; nothing is transmitted and no child's data reaches a third party.
  P05 is parent mode, and the router's existing guard sends kid mode to the
  parental gate (covered by a test).
* **Lifecycle / streams.** `TextEditingController` and `FocusNode` are disposed
  in `State.dispose` (`add_children_view.dart:30-35`); the bloc's `emit.forEach`
  is cancelled by `Bloc.close`; no `Timer`/`AnimationController` is created by
  P05, so `DISABLE_ANIMATIONS` is trivially honoured.
* **Tests.** 130 green, zero skips (the mandated `[P05-BUG-11]` proof is
  un-skipped and passing, not hidden), and every widget test that pumps the app
  ends with `disposeApp(tester)` — `grep` finds no other teardown pattern.

## For the next stages (not findings)

1. Fix the `catch` width (finding 1) — one keyword.
2. Correct the three stale strings in the group-label test (finding 2) and file
   the `NestChipWrap(groupLabel:)` shared request.
3. Add the one-line left-edge assertion (finding 3).
4. File the 48 px token request (finding 4); tighten or drop the tautological
   bound (finding 5); retitle the landed shared request (finding 6); fix the
   "Nunito" slip (finding 7).
5. Make sure the concurrent stage-6 balanced-headings test lands with the pixel
   bound (finding 8) so the family suite stays green.

VERDICT: PASS
