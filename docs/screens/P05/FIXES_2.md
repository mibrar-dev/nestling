# Fix list after iteration 2

## From 4_review.md
# P05 · Add children — QA code review (STAGE 4, iteration 2)

Scope reviewed: `git diff main...HEAD` + the working tree for `screen/P05`
(RULES §1 paths only). No product code was edited; one throwaway geometry
probe (`app/test/features/family/zz_probe_tmp_test.dart`) was created and
deleted.

Reviewed against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P05, `docs/design/SPACING_SPEC.md` §§1–3/6/10, the
design system, both design PNGs, the HTML source, and
`docs/screens/P05/ORCHESTRATOR_NOTES.md` (mandatory items checked — see
*Orchestrator items* below).

Gates re-run independently in this stage:

```
dart format --set-exit-if-changed .   → 358 files, 0 changed
flutter analyze                        → No issues found!   (full app)
flutter test                           → 00:11 +585: All tests passed!
                                          0 skipped, 0 failed
grep -c "skip:"  test/features/family/*.dart → 0 / 0
git status → features/family/{presentation,data}, test/features/family,
             docs/screens/P05   (all RULES §1)
```

**Result: 1 major, 9 minor, 0 blocker. Twelve of the thirteen iteration-1
findings are closed; the new major is a device-only vertical inflation around
the kid grid, precisely measured below, that the widget suite cannot see.**

---

## Findings

### 1. MAJOR — the kid grid renders 47 px too low and the form card 89 px too low, clipping the swatch row and caption behind the bottom CTA

`app/lib/features/family/presentation/widgets/kid_card_grid.dart:20-47`
(the only P05-owned code between the head block and the form card), with the
two gaps at
`app/lib/features/family/presentation/views/add_children_view.dart:209, 214`.

Measured from the two artifacts the loop already owns (logical px, PNG ÷ 3;
`docs/screens/P05/ui/iteration2_test_probe_light.png` = the current build,
taken 13:12, i.e. after the last source edit at 12:47):

| | design | app (iter 2, `onboarding_kids`) | Δ |
|---|---|---|---|
| h1 ink | 112.3–138.0 | 112.3–138.0 | **0** ✓ |
| sub ink | 155.0–170.0 | 155.0–170.0 | **0** ✓ |
| kid grid top | 187 | 234 | **+47** |
| kid card height | 116 | 124 | +8 |
| gap grid → form card | 13 | 47 | **+34** |
| form card top | 315 | 404 | **+89** |
| h3 → "Nickname" inside the card | 19 / 53 | 19 / 52 | **0** ✓ |
| CTA panel top | 644 | 645 | +1 ✓ |

So the head block and *both* cards' internals are pixel-exact; **the whole
error is the ~46 px of space that appears on each side of the grid** (gaps of
60 and 46 where the code and the design both say 14 and 12). Consequences, all
visible in the artifact: the form card is pushed under the fixed
`NestBottomCta`, so the swatch row is half-clipped and the "We only ask for an
age range so quests suit them." caption is not on screen at all without
scrolling, and `iteration-1` band drift in the 300–450 range will return.

**This is not reproducible from the source, and that is the finding.** I
pumped the real screen in a probe (390×844 @3×, `SEED=demo`, and again with
`viewPadding.bottom = 34` to mimic the device insets) and printed the rects:

```
inset0.0  h1 top=107  sub top=183  grid top=245 bottom=416  form top=428
          gap sub->grid = 14.0   gap grid->form = 12.0
inset34.0 h1 top=107  sub top=183  grid top=245 bottom=450  form top=462
          gap sub->grid = 14.0   gap grid->form = 12.0
```

Both gaps are exactly the `SizedBox` values at every configuration — which is
also why the whole test suite (including the new chip/owner-rule tests) is
green while the device is 80 px out. A `const SizedBox(height: 14)` cannot
measure 60 on a device, so one of two things is true and the fix stage must
say which:

* **(a) the artifact is not the current build.** Possible even though the
  mtimes say the source predates the shot: `shot.sh` runs
  `flutter run` in `$APP_DIR`, so confirm with one fresh
  `shot.sh … /add-children … light onboarding_kids parent maya` and re-measure
  before touching code.
* **(b) something device-only is in play** — the likeliest shared suspect is
  the inset handling: `NestStatusBar` now sizes itself to
  `max(MediaQuery.viewPaddingOf(context).top, 47)`
  (`app/lib/core/design_system/components/nest_chrome.dart:34-38`), i.e. its
  height is device-dependent (≈59 pt on a Dynamic-Island simulator vs 47 in
  the design), and the head happens to land correctly only because the compact
  nav is 52. If the same inset handling reaches the scroll content, it lands
  *inside* the list. That is core code — `SHARED_REQUEST.md`, not a P05 patch.

**Fix direction that holds either way (and removes the last nested scroll
view in the screen).** `SPACING_SPEC` §10.2 explicitly allows `GridView`
**or** `Wrap` for the 2-up card row. Replacing the `LayoutBuilder` +
`GridView.builder(shrinkWrap: true)` in `KidCardGrid` with a
`Wrap(spacing: gap10, runSpacing: gap10, children: [SizedBox(width: colW,
child: _KidCard(...)), …])` gives: no nested `Scrollable`, no `childAspectRatio`
arithmetic, and a card that hugs its content (the design's 116) instead of a
computed 124 with the `gap10` pencil-clearance fudge. It also makes the
vertical rhythm a pure box tree that a host test can actually assert, which is
the deeper problem: today no test can catch an 80 px drift here.

*(Not a finding, same area: the +8 card height is the `cardH` formula
`22 + 44 + 2 + 24 + 4 + 18 + 10` at `kid_card_grid.dart:24-31` — the trailing
`gap10` exists only to clear the 44 px pencil, and the design's card is
114 + 0. Switch to the `Wrap` above and the card is content-sized.)*

### 2. MINOR — the design's single-row chip layout is now only proven on the simulator, and the regression proof was relaxed to "≤ 2 rows"

`app/lib/features/family/presentation/widgets/add_child_form_card.dart:78-90`,
`app/test/features/family/p05_bugs_test.dart:88-141`.

The P05-local `IntrinsicWidth` mitigation for P05-BUG-1 is the right call under
RULES §2 (core is read-only) and it is correctly commented. The consequence is
that the proof had to become font-robust — `box.width < 322` and
`tops.length <= 2` — because the test fallback font is ~30 % wider than Nunito.
That is a weaker guarantee than the design's, and nothing in the test suite
re-asserts the real single row. The shared fix in
`SHARED_REQUEST.md` #3 (`Center(widthFactor: 1, heightFactor: 1)` in
`app/lib/core/design_system/components/nest_chip.dart:74`) remains owed — every
screen with a chip row still needs it.

Fix: keep the mitigation, keep the shared request, and make the UI stage
re-assert the single row on the simulator (it already has to re-shoot for
finding 1).

### 3. MINOR — a bug-proof's name promises something its body does not test

`app/test/features/family/p05_bugs_test.dart:121-161`.
`'[P05-BUG-1] the avatar swatches are visible and selectable without scrolling'`
calls `scrollUntilVisible` before tapping, so it proves *selectability*, not
*visibility*. With finding 1 the swatches genuinely are below the fold, so the
name is currently false.

Fix: rename to `… are selectable after scrolling`, or — better — after
finding 1 is fixed, assert the un-scrolled geometry (`swatch.bottom <
CTA top`) and keep the scroll only for the tap.

### 4. MINOR — a request that arrives while a save is in flight is silently dropped

`app/lib/features/family/presentation/bloc/family_bloc.dart:65`.

`if (state.saveInProgress) return;` is the correct fix for P05-BUG-2 (it stops
the duplicate insert), but it also swallows a legitimate "Continue" tapped in
the same frame: no navigation, no inline error, no feedback. The buttons are
disabled for the whole save, so the window is one frame and the design has no
"still saving" state, so leaving it is defensible — it just needs to be a
decision rather than a side effect.

Fix (optional): keep the guard and remember a pending navigation in the state
(`pendingContinue: bool`) that the view acts on when `saveInProgress` drops, or
accept it explicitly in `2_build.md` as intended.

### 5. MINOR — navigation still runs as a `VoidCallback` inside the bloc

`app/lib/features/family/presentation/bloc/family_event.dart:30-37`,
`app/lib/features/family/presentation/bloc/family_bloc.dart:94`.
Carried from iteration 1 and explicitly deferred (removing it would change an
existing member's signature that P15 shares). No functional defect now that
the double-fire path is closed, but the bloc still performs a `context.go`
side effect.

Fix (when P15 lands and the event is free to change): emit a state field
(e.g. `lastSavedNickname` is already there — add `continueAfterSave`) and let
the `BlocListener` navigate.

### 6. MINOR — `presentation/widgets/child_display.dart` contains no widgets

`app/lib/features/family/presentation/widgets/child_display.dart`.
`ARCHITECTURE.md` defines `presentation/widgets/` as "feature-private widgets"
and forbids extra folders per feature, yet this file holds two pure mapping
functions. 18 lines is not a "utils dumping ground", so this is a placement
nit only.

Fix: either accept it (a feature-private mapper is a normal Dart idiom) or
attach the two functions to the widget that owns each
(`AddChildFormCard.displayBand`, `_KidCard.avatarColour`) and delete the file.

### 7. MINOR — `copyWith` can never clear `lastSavedNickname`

`app/lib/features/family/presentation/bloc/family_state.dart:53, 67`.
`lastSavedNickname: lastSavedNickname ?? this.lastSavedNickname` keeps the
previous value for the bloc's lifetime. Harmless today (the view only compares
the current field against it on a save transition) but it is the same
footgun `nicknameError` already solved with the `_keepNicknameError` sentinel
ten lines above.

Fix: reuse the sentinel pattern, or document that the field is write-once.

### 8. MINOR — an unknown `avatar_colour` renders a neutral card with no trace

`app/lib/features/family/presentation/widgets/child_display.dart:13`.
`_ => NestAvatarColor.neutral` silently paints surface-2/ink for a value the
screen does not understand, which is a data bug made invisible.

Fix: keep the DS-safe fallback but `debugPrint('unknown avatar colour: $raw')`
so the bad row is debuggable (one line, same pattern as finding 12's fix).

### 9. MINOR — the failure panel shows a raw exception string to a parent

`app/lib/features/family/presentation/views/add_children_view.dart:171`
renders `state.errorMessage`, which is `error.toString()`
(`family_bloc.dart:41`). This is the codebase-wide pattern (P08 does the same),
so it is not a P05 regression, but on this screen it can read
"Instance of 'DatabaseException'…".

Fix: keep `error.toString()` in the state (useful in the bloc tests) and map
to a parent-safe string at the view, or leave it and note the app-wide
decision.

### 10. MINOR — the 1 px pencil offsets are still un-tokened

`app/lib/features/family/presentation/widgets/kid_card_grid.dart:105-107`
(`Positioned(top: 1, right: 1)`). Carried from iteration 1; the
`mirrors .edit { top: 1px }` comment makes it honest, and `NestSpacing` has no
1 px step. Only remaining un-tokened value in the diff.

Fix: add `NestSpacing.gap1` to the shared scale (a shared change → keep it on
`SHARED_REQUEST.md`) or sign it off as a faithful mirror of the source CSS.

---

## Iteration-1 findings — closed

| # | Finding | State |
|---|---|---|
| 1 | MAJOR · chips stacked full-width, swatches under the CTA | **fixed** in P05 via `IntrinsicWidth` per chip (`add_child_form_card.dart:78-90`), verified on the simulator in `docs/screens/P05/ui/iteration2_test_probe_light.png`: one left-aligned row, 8 px gaps. Shared component fix still owed (finding 2). |
| 2 | MINOR · same-frame double submit | **fixed** — `if (state.saveInProgress) return;` (`family_bloc.dart:65`) |
| 3 | MINOR · retry leaked watchers (P08-B08) | **fixed** — `_closeOnError` (`family_bloc.dart:33, 110-117`), same construction as `today_bloc.dart:78-88` |
| 4 | MINOR · dead `FamilyChildrenRequested` + wrong comment | **fixed** — event, handler and comment deleted |
| 5 | MINOR · missing chip-group semantics | **fixed** — `Semantics(container: true, label: 'Age band')` (`add_child_form_card.dart:71-73`) |
| 6 | MINOR · raw `GestureDetector` swatches | **fixed** — `Material(shape: CircleBorder) > InkWell(CircleBorder)` (`add_child_form_card.dart:157-180`), matching the codebase pattern |
| 7 | MINOR · h1 not a header landmark | **fixed** — `Semantics(header: true)` (`add_children_view.dart:195-203`) |
| 8 | MINOR · kid-card content 5 px low | **fixed** — `Center` → `Align(topCenter)` (`kid_card_grid.dart:71-72`) |
| 9 | MINOR · Continue read the controller | **fixed** — reads `bloc.state.draftNickname` (`add_children_view.dart:56`) |
| 10 | MINOR · `onSaved` navigation callback | deferred with reasons → finding 5 |
| 11 | MINOR · helpers exported from the bloc file | **fixed** — `presentation/widgets/child_display.dart`; the duplicate `_displayBand` deleted |
| 12 | MINOR · swallowed save error | **fixed** — `debugPrint` (`family_bloc.dart:96`) |
| 13 | MINOR · 1 px offsets un-tokened | comment added → finding 10 |

Also closed from `6_bugs.md`: **P05-BUG-5** (typing during a save is discarded)
now uses `lastSavedNickname` + the `typedMore` check in the bloc and the
guarded controller clear in the view; **P05-BUG-6** (`ageYears` always 7) is
fixed in `family_repository_impl.dart` with a band→age mapping that matches the
seed (Maya 9, Leo 6) and leaves the repository interface untouched. All eight
skipped proofs are un-skipped and green.

## Orchestrator items (mandatory, `ORCHESTRATOR_NOTES.md`)

1. *Chips horizontal, left-aligned, 8 px gaps* — met in the build
   (`IntrinsicWidth` per chip; simulator artifact shows one row) and left to
   the UI stage to re-verify (finding 2). Not patched into core ✓.
2. *`SEED=onboarding_kids`, no faked children* — the grid reads
   `state.children` from the repository and nothing in the diff fabricates a
   child; the test stage proved the pair renders from that seed and that the
   route does not redirect (`_onboardingLocations`) ✓.
3. *Header is shared, do not patch locally* — P05 consumes the merged compact
   nav and passes no title; the `title: ''` + `TODO(P05)` workaround is gone
   (`add_children_view.dart:92-95`) ✓. No core edit in the diff ✓.
4. *Bottom panel to the edge + perfect alignment* — untouched and still pinned
   by the owner-rule tests at 320/390/430 in both themes; the measured CTA top
   is 645 vs the design's 644 ✓.
5. *UPDATE: `onboarding_kids` shot, header re-measured* — the test stage's
   probe shot uses `onboarding_kids` and reports the h1 ink at 112.3–138.0,
   pixel-identical to the design; I independently re-measured the same PNG and
   agree ✓.

---

## Confirmed clean (no action)

* **RULES §1 scope.** `git status` touches only
  `features/family/presentation/**`, `features/family/data/**` (allowed: RULES §1
  permits `domain/** + data/**` when the screen needs it — used once, for
  `ageYears`), `test/features/family/**`, `docs/screens/P05/**`. No
  `app/lib/core/**`, no `app/lib/app/**`, no other feature, no
  `tools/screens/**`. `analysis_options.yaml` untouched.
* **ARCHITECTURE.md.** Feature-first layout intact; one bloc per feature; one
  view per route; feature-private widgets; no use-case classes, no new
  folders; the route still provides the bloc (`family_routes.dart:24-26`) and
  the view never re-creates it; all imports `package:nestling/...`. The shared
  bloc surface stays **additive** (`lastSavedNickname` only, no renames, no
  signature changes), so P15 merges cleanly.
* **Design-system reuse.** `NestStatusBar`, `NestNavBar`, `NestCard`,
  `NestAvatar`, `NestTextField`, `NestChip`, `NestButton`, `NestBottomCta`,
  `NestIcon` — nothing re-implemented. Every colour comes from
  `context.nest`; every size from `NestSpacing` / `NestDevice` /
  `NestAvatarSize` / DS props; every style from `NestType`. The only raw value
  left is finding 10's two 1 px offsets. Swatch fills map to the strong brand
  tokens while the avatars map to the `*Tint`/`a*` pairs, matching the design's
  two treatments of the same `a-*` class.
* **Copy / UK spelling / spec §5 P05.** Exact match with the design HTML:
  "Who's in your nest?", "Nicknames only — no photos, no email.", "Add a
  child", "Nickname", "e.g. Ollie", "Age band", "4–6 / 7–9 / 10–12 / 13+"
  (en-dash via the shared `displayAgeBand`), "Avatar colour" (*colour*, not
  color), "We only ask for an age range so quests suit them.", "+ Add another
  child", "Continue", "You can change any of this later in Family."
* **DATA OVER MOCKS.** Age bands, avatar colours and age text all come from
  the seeded rows (`seed.dart:152-177`); no design number is hard-coded.
  Roster order stays the DB's (nickname order) — the mock-vs-ordering call
  remains the orchestrator's, unchanged by design.
* **Owner rules.** Bottom edge: `NestBottomCta` last in the column with its own
  `SafeArea(top: false)` and `tokens.surface` fill over a `tokens.paper`
  Scaffold — no strip in light or dark. Alignment: one
  `NestSpacing.padSide` gutter on the `ListView`, so head, cards, form card,
  CTA buttons and caption share the same edges; grid column computed
  `(W − 40 − 10)/2` per `SPACING_SPEC` §10.2.
* **Spacing spec.** `.scroll` `0 20 32`; `.bottom-cta` 16/20 gap 8 centred
  caption; `.form-card` padding 14; `.kid-card` `12 10 10`; `.avatar` s44;
  `.field` label 13 w600 ink-2, input 52; swatch 44×44 with a 3 px ink ring
  (`spreadRadius: NestSpacing.gap3`) that fits the 8 px inter-swatch gap.
* **Tap targets.** back 44×44, pencil 44×44, chips 44-min (DS), swatches
  exactly 44×44, Add-another 48, Continue 52.
* **Error / empty / loading handling.** Spinner for `initial|loading`; message
  + `Try again` on failure (which now releases the failed load before
  re-subscribing); empty nickname → inline error with no repository call;
  >24 chars → inline error; repository throw → inline message, form preserved,
  error logged; `SEED=fresh`/`empty` → the form-only empty state, which is the
  design-correct layout when the database has no children.
* **Resource hygiene.** `TextEditingController` + `FocusNode` disposed
  (`add_children_view.dart:30-35`); the only stream subscription is owned by
  `emit.forEach`, and its error path now terminates the subscription
  (finding 3 from iteration 1). No `Timer`, `AnimationController` or manual
  `Listener` is created by this screen.
* **Performance.** No rebuild storm; every `const`-able widget is `const`
  (`NestStatusBar`, the `SizedBox` separators, `NestIcon`, the empty grid); the
  per-keystroke rebuild is one `BlocBuilder` over a short list; the grid is a
  shrink-wrapped, never-scrolling view over a family-sized list (and finding 1's
  `Wrap` change would make it cheaper still).
* **Children's Code.** Parent-only screen; no analytics, ads, telemetry or
  network calls; no child data logged; nothing crosses into kid mode, and
  kid-mode deep links to `/add-children` are redirected to the parental gate by
  the shared router. Pip is correctly N/A (initial-letter avatars marked
  `aria-hidden` in the design; §5 P05 says "lilac avatar 'M'").
* **Tests.** 98 in `test/features/family/` (90 + 8), **zero skips**, no
  `skip:`/ignored/tautological bodies, every app-pumping test ends with
  `disposeApp` (the router-only harness drains explicitly), the eight
  iteration-1 bug proofs are live and green, and the family tests were
  re-verified in the full-suite run above.

## For the next stages (not findings)

* **Autofocus.** The design PNG shows the focused field (HTML `autofocus`
  mock); no screen in the app autofocuses a field. Keep it that way — do not
  add autofocus to chase pixels.
* **`NestChip`** still stretches in any `Wrap` (finding 2) — the shared fix
  should be batched with the next design-system change; do not re-open it in
  P05.
* **`continue with a nickname saves then navigates`** now silently no-ops for a
  sub-frame tap (finding 4); if the bugs stage wants a decision, the tests to
  extend are "Continue during an in-flight save is inert" and the
  "Continue → `/pocket-money-setup`" navigation test.


## From 5_ui.md
# P05 · Add children — UI check (STAGE 5, iteration 2)

Route `/add-children`, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844).
Shots use `SEED=onboarding_kids` per `ORCHESTRATOR_NOTES.md` (overrides the brief's `fresh`;
the Maya + Leo cards now render from the database). Parent mode, `THEME=light|dark`.
Comparisons: `tools/screens/compare.py` vs `design/screens/light|dark/P05-add-children.png`.

- Light: `docs/screens/P05/ui/app_light_2.png` → `cmp_light_2.png`, **mean diff 5.51%** (was 6.61%)
- Dark: `docs/screens/P05/ui/app_dark_2.png` → `cmp_dark_2.png`, **mean diff 5.76%** (was 6.76%)

Per-band drift (light): band0 0–105: 1.58% · band1 105–211: 6.42% · band2 211–316: 4.53% ·
band3 316–422: 4.83% · band4 422–527: 5.66% · band5 527–633: 13.70% · band6 633–738: 3.59% ·
band7 738–844: 3.71%. Dark is near-identical (band1 6.87%, band5 14.84%).

Pixel landmarks measured from both PNGs at 3× (÷3 = logical px), light mode:
title ink 113.3–133 / sub ink 158.3–166.7 (identical both) · card top ~192 vs ~238 ·
card height ~113 vs ~124 · h3 ink 334.7–346.7 vs 423.7–435.7 · Nickname ink 370–377 vs
459–466 · CTA top 644 vs 645.

No Pip slot on this screen (avatar initials only) → PIP rule N/A.
Status-bar time/glyphs and home-indicator pill ignored (OS-drawn).

## Deviations

1. [FAIL — blocks gate] Kid grid sits ~46 px too low; form card ~89 px too low;
   swatches clipped, helper caption below the fold.
   Design: card top ~192, h3 ink 334.7, Nickname ink 370, swatch row + caption
   "We only ask for an age range so quests suit them." fully visible above the CTA.
   App (light + dark): card top ~238 (+46), h3 ink 423.7 (+89), Nickname ink 459 (+89);
   only swatch tops peek above the bottom CTA, caption hidden until scrolled.
   Band5 drift (13.7–14.8%) is this.
   Root cause (P05-local, read-only finding): `KidCardGrid`'s `GridView.builder`
   (`kid_card_grid.dart:33-43`) sets no `padding`, so it inherits the ambient
   MediaQuery safe-area insets (~47 top / ~34 bottom). 46 + 11 (taller cards, see #2)
   + 32 ≈ the measured +89. The outer `ListView` is immune (explicit top-0 padding).
   Fix (one line, RULES §1): `padding: EdgeInsets.zero` on that `GridView.builder`.
   Note for the fix pass: after this fix ~23 px of known excess remains (card +11,
   chip row +12, see #2/#3) while the design fits with zero slack (content ends 645 =
   CTA top 644) — re-measure; the caption may still kiss the CTA.

2. [Minor — P05-local choice, flagged] Kid cards ~124 px tall vs design ~113.
   Design: `.kid-card` padding 12/10/10 over 44 + 2 + 24 + 4 + 18 content = ~113;
   the 44 px edit button overlays without adding height. App: `cardH` adds 10 px
   pencil clearance (content itself is now top-aligned per `Align(topCenter)`, so
   review finding 8's 5 px centring offset is gone — only the height differs).
   Fix (optional, P05-local): drop the clearance to match 113, or keep deliberately
   and accept ~11 px of the band2/3 drift.

3. [Fixed this iteration — pass] Age-band chips render in ONE row in both modes
   (4–6, 7–9 selected, 10–12, 13+, gap 8) via the P05-local `IntrinsicWidth`
   workaround for P05-BUG-1. The shared `NestChip` height note stands: the chip box
   is 44 tall vs the design's 32 visual (+12, tap area is overlaid in the mock, not
   stacked) — a DS-level follow-up, already in `SHARED_REQUEST.md` #3; not gate-blocking
   on its own.

4. [Fixed this iteration — pass] Header is pixel-identical (title ink 113.3, sub ink
   158.3–166.7 in both). The shared compact-nav fix (52 px, matching spec) is verified —
   do not patch locally, per orchestrator note 3.

5. [Pass] Bottom edge (owner rule): `NestBottomCta` surface runs to the physical edge in
   both modes (CTA top 644 vs 645, identical geometry). The design PNG is the one that
   breaks the rule (34 px cream strip under the CTA) — the app is the correct one.

6. [Observation — not a defect, orchestrator-owned] Card order Leo|Maya vs design Maya|Leo.
   DATA OVER MOCKS: the roster comes from the DB nickname order (P05-BUG-3); the cards
   render above "Add a child" from the database as orchestrator note 2 requires. No action.

7. [Accepted — no action] Nickname field shows no leaf focus ring (design shows the HTML
   `autofocus` mock state). Do NOT add autofocus. Copy (en-dashes, "Avatar colour",
   all strings), 20 px gutters, card padding/radii/shadows, swatch fills + peach ring,
   CTA buttons + caption, dark-mode tokens, alignment of head/grid/form/CTA edges: all match.

## Verdict basis

Deviation 1 is a visible, designer-rejectable break (colour choice + helper text cut off
at first paint, ~89 px form offset, far outside ±2 px) with a one-line P05-local fix.
Everything else passes or is data/owner-ruled correct.


## From 6_bugs.md
# P05 · Add children — bug hunt (STAGE 6, iteration 2)

Route `/add-children` (feature `family`, parent mode). Adversarial pass on
`screen/P05` at the iteration-2 build (working tree after
`8f7a170 P05: loop iteration 1`, uncommitted iteration-2 fixes; main merged
through `45c5605`).

Gates on this build: `dart format` clean · `flutter analyze` No issues
found! · `flutter test test/features/family` **98 passed, 1 skipped, 0
failed** · no file outside RULES §1 touched.

Proofs: `app/test/features/family/p05_bugs_test.dart` — the eight
iteration-1 proofs (P05-BUG-1, 2, 4, 5, 6, 7) run **un-skipped and green**;
the new **P05-BUG-8** proof carries `skip: true` with the id in the name so
the suite stays green. Verified failing with
`flutter test --run-skipped test/features/family/p05_bugs_test.dart`
→ the eight fixed proofs pass, P05-BUG-8 fails exactly as recorded.

**Result: 1 major open (P05-BUG-8, the device-only grid inset bug already
reported by stage 4/5 — now proved deterministically in-widget), 0 new minor
bugs. All eight iteration-1 bugs are fixed and stay fixed. VERDICT: FAIL**
— the major clips the swatch row and the helper caption behind the bottom CTA
on any device with safe-area insets.

---

## P05-BUG-8 — MAJOR — the kid grid re-applies the device safe-area insets, pushing the form card ~81 px down and clipping the swatches + caption behind the CTA

**Where:** `app/lib/features/family/presentation/widgets/kid_card_grid.dart:33-44`
— the inner `GridView.builder` passes no `padding`. `BoxScrollView` only
consumes `MediaQuery.padding` when `padding == null`, so on a device the
47 px top / 34 px bottom insets become the grid's own `SliverPadding`
(the outer `ListView` is immune because it passes explicit padding, and it
does not remove the ambient padding for its children).

**Repro (deterministic, in-widget — this is what stage 4's probe missed):**
the test surface defaults to zero insets, so the suite cannot see it. Set the
device insets the way a real device reports them — `MediaQuery.padding` comes
from `view.padding`, `viewPadding` from `view.viewPadding`:

```dart
const insets = FakeViewPadding(top: 47 * 3, bottom: 34 * 3); // physical px @3x
tester.view.padding = insets;      // ← stage 4 only set viewPadding, so
tester.view.viewPadding = insets;  //   MediaQuery.padding stayed zero
await pumpAppRoute(tester, '/add-children');
```

Measured (390×844, demo seed, fallback font):

| gap | design (HTML) | zero insets | device insets |
|---|---|---|---|
| subtitle bottom → first card top | 14 (`.kid-grid` margin-top) | **14.0** ✓ | **61.0** (14 + 47) |
| last card bottom → form card top | 12 (`.form-card` margin-top) | **12.0** ✓ | **46.0** (12 + 34) |

On-device impact, measured from the loop's own artifacts in stage 4/5
(`docs/screens/P05/ui/iteration2_test_probe_light.png`, `app_light_2.png`):
kid grid top 234 vs 187 design (+47), form card top 404 vs 315 (+89), only
the swatch tops peek above the CTA (top 645) and “We only ask for an age
range so quests suit them.” is not on screen at first paint. A secondary
consequence of the same padding: when the keyboard opens, `padding.bottom`
collapses to 0 and the grid's 34 px bottom padding disappears, shifting the
content under the finger.

**Proof:** `[P05-BUG-8] the kid grid does not add the device safe-area
insets` (skip: true) — expected 14, actual 61; the second assertion is 12 vs
46.

**Suggested fix (one line, RULES §1):** `padding: EdgeInsets.zero` on the
`GridView.builder` in `kid_card_grid.dart`. The review's `Wrap` alternative
(no nested scrollable at all, `SPACING_SPEC` §10.2 allows it) also closes it.
After the fix, re-measure the ~23 px of known excess (kid card +11 px pencil
headroom, chip row +12 px 44-px tap boxes — `5_ui.md` deviations 2/3): the
design fits with zero slack, so the caption may still kiss the CTA.

---

## Iteration-1 bugs — all fixed and regression-proofed

| # | Bug (iteration 1) | Fix | Proof status |
|---|---|---|---|
| P05-BUG-1 | Chips stacked full-width, swatches under the CTA | P05-local `IntrinsicWidth` per chip; shared `NestChip` request still open | green (2 proofs) |
| P05-BUG-2 | Same-frame double submit | `if (state.saveInProgress) return;` first line of the handler | green (2 proofs) |
| P05-BUG-4 | Retry leaked the failed load's watchers | `_closeOnError` transform on the combined load stream | green |
| P05-BUG-5 | Typing mid-save discarded | `lastSavedNickname` + conditional clear in bloc and view | green |
| P05-BUG-6 | New children always stored `ageYears = 7` | band → age mapping in `FamilyRepositoryImpl.addChild` | green |
| P05-BUG-7 | H1 had no header landmark | `Semantics(header: true)` | green |
| P05-BUG-3 | Roster order (DB vs mock) | Orchestrator-owned; unchanged | observation |

The iteration-2 changes were also re-read adversarially: the `saveInProgress`
guard cannot drop a legitimate retry (state clears on success and failure),
the conditional clear cannot clear newer typing (`lastSavedNickname` compares
trimmed values and the field is only cleared while it still holds the saved
name), `_closeOnError` still delivers the failure state before closing, and
the `ageYears` mapping is monotonic (6/9/12/13, unknown → 7) matching the
seed’s own ages.

## Verified sound (adversarial probes on the iteration-2 build)

| Area | Result |
|---|---|
| Rapid double taps | two same-frame taps with the real DB insert **one** child (bloc guard); next-frame re-tap already covered |
| Data edge cases | 0 children → form-only; 1 child → 170 px card; 6 children incl. “Maximilian-Alexander” → 3 computed rows; empty roster list → no grid; no exceptions |
| Text scale 1.3 × 320 | six children + long names, **with device insets too** → no overflow, grid scrolls |
| Kid-mode guard | kid-mode deep link to `/add-children` → `/parental-gate` |
| Restart / Drift persistence | child added, fresh app launch over the same DB → card present |
| Dark mode + insets | CTA surface runs to the physical bottom edge (624…844) with the 34 px home-indicator inset |
| Async gaps | bloc drops emits after close; `onSaved` callbacks are `mounted`-guarded |
| Money / timezone | P05 renders no money or dates — N/A by construction |
| Owner rules (zero insets) | 20 px gutters, form card == CTA edges, CTA to the physical edge — existing tests green |

## Fix-pass notes

* P05-BUG-8 is the only gate blocker; it is the same defect stage 4 filed as
  finding 1 and stage 5 as deviation 1, now with a deterministic widget proof
  (stage 4's probe set only `viewPadding`, which does not feed
  `MediaQuery.padding` in tests).
* The shared `NestChip` request (`SHARED_REQUEST.md` #3) stays open: the P05
  `IntrinsicWidth` workaround holds until the component fix lands.
* Known residuals after the BUG-8 fix (stage 5 deviations 2/3): kid card
  +11 px, chip row +12 px — re-measure the caption against the CTA.

