# P02 Value tour — QA code review (Stage 4, iteration 2)

Reviewed the current branch diff (`git diff main...HEAD` + working tree):
`value_tour_view.dart` (rewrite), the new
`presentation/widgets/value_tour_preview_row.dart`, `value_tour_view_test.dart`,
`p02_bugs_test.dart` (9 skipped proofs un-skipped), and the notes.

Verified in `app/`: `flutter analyze` → *No issues found!*;
`dart format --output=none --set-exit-if-changed .` → *0 changed* (349 files);
`flutter test` → *443 passed, 0 failed, 0 skipped*.

**Iteration-1 findings 1–9 are all closed**, and I re-measured the design bands
against the new device screenshot `ui/app_light_2.png` to confirm it:

| Band | Design (÷3) | App | |
|---|---|---|---|
| card 1 top / bottom | 107 / 507 | 107 / 507 | exact |
| preview-row tile pitch | 50 (170,220,270,320) | 50 (173,223,273,323) | pitch exact, +3 shared chip drift |
| progress bar | 371–379 | 374–382 | +3 (same cause) |
| dashed add-row | 447 → 490 | 447 → 490.3 | exact |
| dots ink | 534–542 (x 170–191.7/198–205.7/212–219.7) | identical | exact |
| title ink | 582–608.3 | 582–608.3 | exact |
| CTA hairline / button | 725 / 742–794 | 726 / 742–794 | 1px hairline, button exact |
| bottom edge (y 800…843) | paper (design) | surface `#FFFFFF` / `#1F1C2E` | owner rule wins ✓ |

All four preview titles now render in full (row-title ink ends at 234.7/196.7/
239.3/220.3 — no ellipsis), the step copy is no longer clipped, and card 1's
content (359) leaves the design's 44px `margin-top:auto` slack. No blocker or
major findings remain.

## Findings

### 1. MINOR — card 1's date chip shows the *payout* Saturday, not today
`value_tour_view.dart:100-107` (`_payoutChipLabel`), used at `:421-423` (card 1,
"Today's quests") and `:581-583` (card 3, "coming on Saturday"). Both chips now
read "the next Saturday after `Seed.anchorDay`" (`Sat 10 Oct` under the pinned
test clock). On card 1 that implies today is a week away from the chip's date,
and the card's own title says "Today's quests". The design's `Sat 4 Oct` was
meant to be *today* on card 1 and the payout day on card 3; only the weekday
letter was wrong (BUG-5).
Fix: card 1 → `formatLondonDay(Seed.anchorDay)` (today); keep the next-Saturday
derivation for card 3 only. Add a test asserting the two chips differ and that
card 1's equals the anchor day.

### 2. MINOR — the presentation layer derives a production date from the seeder
`value_tour_view.dart:7` imports `core/data/seed.dart` and calls
`Seed.anchorDay` (`:101`). `Seed` is the demo/test seeder: the screen's chrome
now silently follows `Seed.anchorOverride`, which only exists for tests.
Architecturally a view should not read a seeder (data comes from
repository/bloc; `ARCHITECTURE` per-feature contract), and the chip is a clock
concern, not seed data.
Fix: compute it from `london_time.dart` (`toLondon(DateTime.now().toUtc())`)
and keep test determinism by passing the anchor in (a `DateTime anchor`
parameter defaulting to today, set by the test helpers) — or, if `Seed.anchorDay`
is kept deliberately, say so in the doc comment at `:91-99`.

### 3. MINOR — `ValueTourPreviewRow` duplicates the shared tile-tint palette
`value_tour_preview_row.dart:52-59` repeats the 6-case
`NestTileTint → (bg, fg)` switch from `nest_list_row.dart:37-44`. Two copies of
a palette mapping will drift the first time a tint changes, and the new copy is
the one this screen renders.
Fix: extract the mapping into one shared helper (`nest_list_row.dart` or the
tokens layer) and call it from both, or add it to `SHARED_REQUEST.md` item 2 so
the shared compact variant ships with a single mapping.

### 4. MINOR — `ValueTourPreviewRow` is missing the `TODO(P02)` marker
`value_tour_preview_row.dart:1-17` documents the retirement path in prose but
carries no `TODO(P02)` comment, while RULES §2 asks for one while blocked and
`3_test.md:106-109` states the widget ships "behind `TODO(P02)`". Only
`value_tour_view.dart:299` has the marker today.
Fix: add `// TODO(P02): retire when SHARED_REQUEST item 2 lands.` at the top of
the widget so the pending work is greppable.

### 5. MINOR — the chip's 1.5px border inflates the head row (+3) and forced a 1px spec shave
`nest_chip.dart:29-37` puts a 1.5px `Border.all` around a `SizedBox(32)`, so the
chip is a 35px box; the card-1 head row is therefore 35 (design 32) and every
inner row sits +3px from the design (measured: tiles 173 vs 170, progress 374 vs
371). To keep card 2 inside the restored 400dp the screen also had to drop
`.pg-stages` from the spec 10 to 9 (`value_tour_view.dart:508-511`, `gap9`).
The screen used the shared component correctly, so the fix belongs in the shared
request (non-blocking today).
Fix: add the chip's border-box to `SHARED_REQUEST.md` item 3 (draw the border
inside the 32, e.g. `Container(decoration: …)` around a `SizedBox` sized
`height − 3`, or `border: Border.fromBorderSide` with an inner `BoxFit`), then
restore `NestSpacing.gap10` at `value_tour_view.dart:511`.

### 6. MINOR — card 2's caption is clipped to one line to protect the 400 budget
`value_tour_view.dart:498-507` forces `maxLines: 1` + ellipsis on
"175 of 250 coins · Pip evolves at 250". The design's `.pv-cap` wraps (no
max-lines); the single-line rule exists only because the wide widget-test font
would push a 400dp card over budget, so at 320dp the caption ellipsises.
Fix: keep it (the small-screen ellipsis rule permits this) but re-evaluate once
finding 5 frees ~1px in card 2, or state the accepted deviation in `2_build.md`
next to the `gap9` note.

### 7. MINOR — cards reach into `_ValueTourViewState` statics
`value_tour_view.dart:421-423`, `:480`, `:581-583` call
`_ValueTourViewState._headChip` / `_payoutChipLabel` (`:81-107`), which are
private statics of the screen's `State` class yet hold no state. Works, but it
leaks the State into three sibling widgets and makes the helpers awkward to
test or reuse.
Fix: move them to a file-private top-level function (or a small private
`_HeadChip` widget) next to `_TourNav`.

### 8. MINOR — `PopScope(canPop: false)` also catches a deep link to `/value-tour`
`value_tour_view.dart:195-197`, `:154-158`. BUG-6 (system back → `/welcome`) is
fixed for the in-flow case, but a cold deep link / `INITIAL_ROUTE=/value-tour`
now also lands on `/welcome` instead of letting back exit — acceptable in an
onboarding flow and noted in `2_build.md`, just confirm it is intended.
Fix: leave as is, or veto only when the tour was entered from `/welcome`
(e.g. a flag set in `didChangeDependencies` / `GoRouterState.extra`).

### 9. MINOR — the a11y proof for the dashed add-rows asserts only the label
`value_tour_view_test.dart` "preview add-rows expose plain-text labels" proves
the three labels are reachable, but nothing pins that they carry **no** tap
action / button flag (the point of moving them out of `ExcludeSemantics`).
Fix: assert `hasAction(SemanticsAction.tap) == false` and
`flagsCollection.isButton == false` on one of the three nodes, so a future
`InkWell` in `_DashedAddRow` cannot slip through as a fake control.

## Verified (no finding)

- **RULES §1** — changed paths are `features/onboarding/presentation/**`,
  `test/features/onboarding/**`, `docs/screens/P02/**` only; `core/`, `app/`,
  `tools/` and `analysis_options` untouched; `SHARED_REQUEST.md` grew to three
  non-blocking items, each naming the interim widget and its retirement path.
- **ARCHITECTURE** — feature-first; the new widget lives in
  `features/onboarding/presentation/widgets/` (feature-private, per the
  per-feature contract); no new bloc/event/state, no repo or DI change, route
  still provides `OnboardingBloc`; `package:nestling/...` imports only.
- **Iteration-1 MAJOR closed with evidence** — pager is 400 (`value_tour_view.dart:49`,
  asserted at `value_tour_view_test.dart` 400 / 520), the copy is no longer
  clipped, and the short-screen overflow is gone: pager + copy share one
  `SingleChildScrollView` (`:203-269`), so only status + nav + CTA are fixed;
  BUG-1a/b/c and BUG-3a/b prove it at 320×568 and 375×667 × 1.3.
- **Design-system usage** — no `Color(0x…)` in either file (grep clean);
  `NestStatusBar`, `NestCard`, `NestChip`, `NestCoinPill(small)`, `NestProgress`,
  `NestPagerDots`, `NestBottomCta`, `NestButton`, `NestMoney`, `NestIcon`,
  `NestIcon`+`NestCoinPill` in the new row; every gap/inset is a `NestSpacing`
  value (`_pagerInsetLeft = NestSpacing.padSide`, no literal 20 left).
  `NestListRow` is no longer used by P02, and no other caller uses
  `compact: true` — worth passing to the orchestrator with item 2 (the flag is
  now dead shared code).
- **DESIGN_SPEC §5 P02** — all three steps' titles and bodies verbatim from
  `OnboardingRepositoryImpl._steps`, 3 dots with the first active, Skip top-right,
  card order and rhythm (dots 22 / title 30 / body 12, rows gap 12, foot 14,
  cap 6, amount 14+2, lines 16, total 4+6) unchanged; UK spelling, £ with two
  decimals, coins (not prices) on every card.
- **PIP rule** — `PipAvatar(style: PipStyle.mochi, stage: 3)` (sunny/idle/none
  are the widget defaults), no v1 `pip_stage_*.svg`, 158×158 main slot with the
  design alt text, stage dots decorative as in the HTML.
- **Bottom edge (owner)** — painted-pixel tests in both themes (34dp inset and
  inset 0) and the device screenshot: surface to y=843 in light and dark, never
  page tint.
- **Alignment (owner)** — 20px gutters on the copy, the CTA, the card's left
  edge and Skip's right edge at 320/390/430 × light/dark, and one shared inner
  left edge for every card row.
- **Accessibility** — one `Semantics(header: true)`, the pager group label that
  tracks the step, Skip `button` + explicit `onTap` + ≥44 box, CTA ≥52 full
  width, icon tiles silent, add-row labels exposed, Pip labelled `image`, dots
  indicators only (no `Go to page` actions).
- **Performance** — no streams, timers or animation controllers; `_controller`
  disposed in `dispose()` and on width change; all three cards `const`; one
  `setState` per page change; `shouldRepaint` correct; `PageView.builder` builds
  only the visible pair; reduced motion honoured for the page turn and by
  `NestMotion` in the dots. Nothing renders continuously — consistent with 6_bugs
  finding no screen-side animation.
- **Error handling** — `_goTo` guards `hasClients`, clamps the target and uses
  `animateToPage`/`jumpToPage` per RULES §6; `_onSystemBack` checks
  `context.mounted`; no throws on any path.
- **Children's Code** — parent-only marketing copy that speaks to parents
  ("your family", no "For Kids"), no analytics/ads/tracking, no child photos,
  emails, chat or location, no loss-aversion framing, no £ on any kid surface.

## Notes for the orchestrator (not findings)

- The app's step-body copy renders ~4px higher than the design PNG for the same
  line box (the 'P' of "Pick" at 628.67 vs 632.67, identical 12.66px cap
  height) — a font-metrics difference between the HTML render and the app's
  Google-Fonts face. It affects every screen's text band, is not P02 code, and
  is the main residual contributor to the band-1/2 diff.
- The body copy still uses the repo/DESIGN_SPEC punctuation (straight quotes, no
  em dash) while the PNG shows “ ” + —: UI item 3, still needs a ruling.
- `shot.sh`'s "frame never stabilised in 25 s" persists in both themes (UI item
  6). Nothing on this screen animates under `DISABLE_ANIMATIONS=1` — the dots
  resolve to zero duration, `PipAvatar` short-circuits to its SVG fallback and
  widget `pumpAndSettle` is clean — so this is a capture-tool/OS-animation
  question, not a P02 code defect, and it should not block this screen.
- DESIGN_SPEC §5's "peeking at 16px" is stale (HTML/PNG show a 48px peek at 390);
  the code follows the design.

VERDICT: PASS