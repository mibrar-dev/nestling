# P02 Value tour — QA code review (Stage 4, iteration 1)

Reviewed `git diff main...HEAD` (docs only) plus the working-tree change to
`app/lib/features/onboarding/presentation/views/value_tour_view.dart` and the new
`app/test/features/onboarding/value_tour_view_test.dart`.

Verified locally in `app/`: `flutter analyze` → *No issues found!*;
`dart format --output=none --set-exit-if-changed .` → *0 changed* (346 files);
`flutter test` → *422 passed, 0 failed*. Design bands measured off
`design/screens/light|P02-value-tour.png` at ÷3 (card 1 = y 107→507, i.e. 400 tall;
dots ink 534–542; title ink 583.7–603; body lines 623–647 / 647–671; CTA hairline
725; body line 1 ink x 21.3→353, line 2 x 21.0→246.3).

## Findings

### 1. MAJOR — fixed pager height 468 breaks the design's 400 and slices the step copy
`app/lib/features/onboarding/presentation/views/value_tour_view.dart:53`
(`_pagerBaseH = 468`), `:143` (`pagerH = _pagerBaseH * ts`), `:155-156`.

`SPACING_SPEC` §7 (l. 317) and the PNG both fix the pager card at **400**; the
screen uses 468. Consequences at the design's own 390×844:

- Card top 47 + nav 52 = 99 (design 107) and the card is 468 tall (design 400), so
  everything below the pager sits **+60px** lower than the PNG: dots ink at
  594 (design 534), title ink at ~643 (design 583.7), body at 683 (design 623).
- The design keeps 54px of slack below the body (671 → CTA hairline 725). The app
  has **−37px**: content 22+18+30+34+12+48+32 = 196 into a 726−567 = 159 region,
  so the **second body line is cut ~5px by the CTA's top hairline** at rest
  (`SingleChildScrollView` clips, no overflow exception, so the test suite is
  blind to it). `or make your own.` renders sliced.
- On a 667-tall device (iPhone SE class) 47+52+468+84 = 651 leaves ~16px for the
  step copy — effectively none.

Root cause (shared, not screen-local — measured): the design's `.pv-row` is 38px
(36 tile, 15/20 name + 13/18 sub, no vertical padding, gap 8), but
`NestListRow(compact:)` is **60px**: `nest_list_row.dart:53` keeps
`fromLTRB(12, 10, 16, 10)` and `:79-93` uses a 22px title line + 18px sub, so
4×60+3×12 = 276 vs the design's 188. Plus the chip's 1.5px border folding into its
`SizedBox(32)` (+3). Production content is therefore 16+35+14+276+14+8+6+18+44+16
= **447** (465 under the widget-test fallback font, which is what the note at
`:40-52` sizes for) against a 400 box that has only 44px of `margin-top:auto`
slack. Inflating the box was the only local option *if the shared row is fixed* —
and it is not fixed and was not escalated.

Fix: file a `SHARED_REQUEST` (RULES §2) for `NestListRow(compact:)` to match
`.pv-row` (no vertical row padding, title 15/20, sub 13/18, internal gap 8) — the
compact flag exists only for P02 (`nest_list_row.dart:31-32`) — then set
`_pagerBaseH = 400` and update the two tests that pin the deviated value
(`value_tour_view_test.dart:852-855`, `:871-874`). If the shared change cannot
land, keep 400 and shrink the card's own content (a feature-private preview row
with the design's metrics) rather than growing a spec-fixed box and clipping the
copy.

### 2. MINOR — `_pagerInsetLeft = 20` duplicates `NestSpacing.padSide`
`value_tour_view.dart:28` (used at `:97`, `:154`). The same file already uses
`NestSpacing.padSide` (`:183`, `:242`) for the same 20px gutter; the tests then
hard-code `20` and `12` too (`value_tour_view_test.dart:711`, `:717`).
Fix: `static const double _pagerInsetLeft = NestSpacing.padSide;` and assert
against `NestSpacing.padSide` in the test.

### 3. MINOR — `_TourNav` re-implements a nav action instead of reusing the design system
`value_tour_view.dart:232-284`, esp. the bare `GestureDetector` at `:256-258` and
the hard-coded `height: 52` at `:239-240`. The shared `NestNavBar` →
`_NavActionButton` (`nest_nav_bar.dart:158-196`) is exactly this control
(Semantics button+label, Material/InkWell, ≥44 box, leaf label); the private copy
loses the ripple/hover/focus and duplicates a 52px metric the DS does not own.
The reason for going private (compact bar traps the action in a 44px slot) is
legitimately filed in `SHARED_REQUEST.md`, but the interim bar need not re-hand-roll
the button.
Fix: build the action with the shared Material/InkWell pattern (or use the
non-compact `NestNavBar(actionLabel: 'Skip', onAction: …)`, whose trailing slot is
not fixed) and drop the bespoke height once the shared compact fix lands.

### 4. MINOR — `_DashedAddRow` hides real copy from screen readers
`value_tour_view.dart:590` `ExcludeSemantics` drops "New quest",
"Next stage: Songbird" and "No bank card needed" from the a11y tree. The design's
HTML exposes them (plain `<div>`, no `aria-hidden`), and the last one is a
product claim. They are non-interactive, which is the only reason they are
currently hidden.
Fix: keep the label in the semantics tree as plain text (no button flag, no tap
action) and exclude only the leading icon; keep a test asserting the strings are
findable by semantics label.

### 5. MINOR — un-tokenised geometry
`value_tour_view.dart:384` (`_dotD = 52`), `:385` (`_artD = 40`), `:415`
(`dimension: 158`), `:551` (`minHeight: 32`), `:633-635` (dash `1.5/6/4`), plus
the redundant `NestCard(padding: EdgeInsets.all(NestSpacing.s4))` at `:328`, `:390`,
`:483` (the component default is already `s4` — `nest_card.dart:31-32`). The
review criterion is tokens only; these have no token in `spacing.dart`.
Fix: request tokens for the design's `.pg-stage 52` / `.pg-pet 158` /
`.pg-line min-h 32` / the `.pv-add` dashed metrics in a `SHARED_REQUEST`, and
until then keep each as a documented `static const` naming its CSS source (as
`_pagerBaseH` does); drop the redundant `NestCard` padding.

### 6. MINOR — preview rows contradict `Seed.demo` (DATA OVER MOCKS)
`value_tour_view.dart:299, 306, 313, 320`. `seed.dart:218-236` has
`q-dishwasher` = maya/**daily**, `q-bins` = **maya**/**weekly**, `q-reading` =
maya/daily, `q-tidy` = maya/**daily**; the card shows
"Empty the dishwasher · Maya · **weekly**", "Put the bins out · **Leo · once**",
"Tidy your bedroom · Maya · **weekly**". The coin amounts (15/15/10/15) and the
"4 of 6" progress (Maya has 6 quests) do match the seed.
Fix: use the seeded assignee/repeat, or state the deliberate marketing-mock
exception in `2_build.md` (the orchestrator rule says the DB wins).

### 7. MINOR — double-tapping "Next" skips a step
`value_tour_view.dart:118-137`: `_goTo` clamps the target but then always calls
`controller.nextPage(...)`, which advances one page from the *current* offset — a
second tap during the 300ms animation lands on step 3 and skips step 2.
Fix: `controller.animateToPage(target, …)` (or ignore the tap while a
`PageController` animation is in flight).

### 8. MINOR — tests pin the deviated geometry and a self-referential "matches Seed.demo"
`value_tour_view_test.dart:852-855` and `:871-874` assert `468` / `468 × 1.3`,
locking in finding 1. `:793-818` ("card 3 ledger matches Seed.demo") compares
hard-coded literals in the test with hard-coded literals in the view, so it proves
nothing about the seed; the same applies to the `4/6`, `15/15/10/15` and
`175 of 250` assertions at `:742`, `:748`, `:750`.
Fix: assert the design's 400 / 400×ts once fixed, and have the ledger test read
Maya's balance (and the quest rows) from the Drift DB instead of literals.

### 9. MINOR — a11y test does not assert the Skip tap action
`value_tour_view_test.dart:568-577` checks `label` and `isButton` but not
`hasAction(SemanticsAction.tap)`, so a regression that dropped the activation
action (the control is a `GestureDetector`, not a focusable widget) would pass.
Fix: add the tap-action assertion for `p02_skip`.

## Verified (no finding)

- **RULES §1** — only `features/onboarding/presentation/**`,
  `test/features/onboarding/**` and `docs/screens/P02/**` touched; no `core/`,
  no `app/`, no `tools/`, no `analysis_options` change; `SHARED_REQUEST.md` filed.
- **ARCHITECTURE** — feature-first, view in `presentation/views/`, route-level
  `BlocProvider` untouched, one bloc per feature, `package:nestling/...` imports,
  no use-case/`utils` layers.
- **DESIGN_SYSTEM** — `NestStatusBar`, `NestCard`, `NestListRow(compact:)`,
  `NestChip`, `NestCoinPill(small)`, `NestProgress`, `NestPagerDots`,
  `NestBottomCta`, `NestButton`, `NestMoney`, `NestIcon`, `NestRadii`,
  `NestSpacing`/`NestType` tokens; no `Color(0x…)` anywhere in the view
  (`_DashedBorder` takes `tokens.line`); copy, card order, rhythm (dots 22 /
  title 30 / body 12, rows gap 12, foot 14, cap 6, stages 10, amount 14 + 2,
  lines 16, total 4 + 6) all match the HTML/SPACING_SPEC.
- **PIP rule** — `PipAvatar(style: mochi, stage: 3)`; sunny/idle/none are the
  widget defaults (`pip_avatar.dart:234-237`), no v1 `pip_stage_*.svg`, main art
  158×158 with the design's alt text, stage dots `aria-hidden` per the HTML.
- **Bottom edge (owner)** — `NestBottomCta` paints `tokens.surface` to the screen
  edge under the inset; `NestHomeIndicator` is 0 in-app. No coloured strip.
- **Children's Code** — parent-only marketing copy, no analytics/ads/tracking, no
  child photos/emails/location, no loss-aversion framing, no prices in £ in any kid
  surface (none here), route already gated out of kid mode by shared code.
- **Performance** — no streams/timers/animation controllers; `_controller`
  disposed in `dispose()` and the replaced one disposed on width change; cards
  const; `onPageChanged` → one `setState`; `shouldRepaint` correct; no
  `AnimatedSwitcher`; reduced motion honoured for the page turn
  (`disableAnimations || kDisableAnimations`) and by `NestMotion.resolve` in the
  dots.
- **Error handling** — `_goTo` guards `hasClients`, clamps the target, no throws.

## Notes for the orchestrator (not findings)

- The HTML renders the body as `like “Put the bins out” — or` (curly quotes + em
  dash); the app, `DESIGN_SPEC` §5 and `OnboardingRepositoryImpl._steps` all use
  `'Put the bins out' or`. The app follows spec+repo (DATA OVER MOCKS), so expect a
  small text diff in the body band of the PNG comparison.
- `DESIGN_SPEC` §5 P02 says the peeking thumbnails show "16px" from the right
  edge; the HTML (`c2 left 342`) and the PNG show a 48px peek at 390. The code
  follows the design — correct, but the spec line is stale.
- The PNG renders `.nav-bar.compact` at 60px (4 + 44 + 12) while `SPACING_SPEC`
  §7 (l. 88) maps the Flutter compact bar to 52; `_TourNav` follows
  `SPACING_SPEC`, which costs ~8px against the PNG. Worth a one-line ruling so
  the other onboarding screens stay consistent.

VERDICT: FAIL
