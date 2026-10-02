# P02 Value tour — QA code review (Stage 4, iteration 4)

Reviewed the full branch diff (`git diff main...HEAD` + working tree) against the
mandatory `docs/screens/P02/ORCHESTRATOR_NOTES.md`, the COPY and CHILD ORDER owner
rules, RULES §1, ARCHITECTURE, DESIGN_SPEC §5 P02, SPACING_SPEC and the design
system (post `shared_requests_batch1` + the path-based router push/pop test).

Verified in `app/`: `flutter analyze` → *No issues found!*; `dart format
--set-exit-if-changed .` → *0 changed* (364 files); `flutter test` → **645 passed,
0 failed, 0 skipped** — the shared push/pop blocker is gone (main rewrote
`test/app/router_push_test.dart` to assert router locations, and it merged clean).

Device bands re-measured on `ui/app_light_5.png` (light) and `ui/app_dark_5.png`
(dark) against the design PNGs (÷3):

| Band | Design | App | |
|---|---|---|---|
| card 1 top / bottom | 107 / 507 | 107 / 507 | exact |
| progress bar | 371–379 | 374–382 | +3, shared chip border box |
| dashed add-row | 447 → 490 | 447 → 490 | exact |
| dots / title ink | 534–542 / 582–608.3 | identical | exact |
| CTA hairline | 725 | 726 | 1px hairline |
| preview titles | 4 full names | 4 full names (81→244, 196.7, 239.3, 220.3) | no ellipsis |
| bottom edge y800–843 | paper | `#FFFFFF` / `#1F1C2E` | owner rule ✓ |

**Every iteration-3 finding is closed:**

| Iteration-3 finding | State |
|---|---|
| 1 MAJOR — unbounded shrink-to-fit (titles ~9px at 320, ~6.5px at 320×1.3) | fixed: `ValueTourFitText` measures the natural width and only shrinks while `slot/natural ≥ minScale`, otherwise full-size ellipsis; BUG-10a/b/c prove the painted scale |
| 2 — vacuous "no truncation" proofs | fixed: both replaced by real measurements (`paintedScaleOf` = slot ÷ unbounded paragraph width; fallback asserts `didExceedMaxLines == true`) |
| 3 — stale retirement contract on the preview row | fixed: doc comment now states the row is permanent and explains the deliberate tint-mapping duplication |
| 4 — chip border box untracked | fixed: filed as `SHARED_REQUEST.md` item 5 |
| 5 — card 2 caption `maxLines: 1` | fixed: now goes through `ValueTourFitText` |
| 6 — cards reaching into `_ValueTourViewState` statics | fixed: `_chipMaxW`/`_headChip`/`_dateChipLabel` are file-private top-level |
| 7 — `PopScope` intercepting a deep link | open, documented, still minor |
| merge blocker (`router_push_test.dart`) | resolved on main; suite green |

**ORCHESTRATOR_NOTES:** 1 (design static copy/data) ✓ · 2 (typographic
characters) ✓ · 3 (no truncation at 390) ✓, with the 320 × 1.3 half met by
full-size ellipsis rather than wrapping (see note 2) · 4 (bottom edge) ✓.

## Findings

### 1. MINOR — `minScale = 0.92` still allows painting below the 15px parent floor
`app/lib/features/onboarding/presentation/widgets/value_tour_preview_row.dart:123,147`.
The doc comment (`:105-113`) promises the widget never paints below a size that
is "never a substitute for layout (DESIGN_SPEC §0 rules 4/9)", but the floor is
0.92, so a slot at 92–100% of the natural width renders the design's 15/600 title
at **13.8–15px** — under DESIGN_SPEC §0 rule 9's ≥15px parent body text. Measured
today the ratio at 390 is 1.01 (scale 1.00, verified on device), so nothing is
wrong in this build; the window only opens if the resolved Inter grows ~9%.
Fix: `minScale: 1.0` (the fit path then only triggers at an exact fit and the
`FittedBox` becomes a no-op — plain ellipsis otherwise), or keep 0.92 and state
the 13.8px worst case in the doc so the comment stops claiming rules 4/9 are met.

### 2. MINOR — `_headChip` keeps the unbounded shrink the review just banned
`app/lib/features/onboarding/presentation/views/value_tour_view.dart:32-43`.
`FittedBox(fit: BoxFit.scaleDown)` inside `ConstrainedBox(maxWidth: 180)` has no
lower bound either: a chip label wider than 180dp would paint below the 14px
`.chip` token (`nest_chip.dart` chipLabel 14/20). Today's labels are static consts
(`'Sat 4 Oct'`, `'Fledgling'`, ~103 and ~80dp) so it never triggers, but it is the
same hazard one copy edit away, and `NestChip` already ellipsises internally via
`Flexible` + `overflow: ellipsis`.
Fix: drop the `FittedBox` and let the shared chip ellipsise, or reuse
`ValueTourFitText`'s bounded rule for the chip label.

### 3. MINOR — `ValueTourFitText` is public inside a feature-private file
`value_tour_preview_row.dart:119`. ARCHITECTURE defines
`presentation/widgets/` as *feature-private* widgets; a public class name with a
`ValueTour` prefix invites cross-feature import and re-export.
Fix: make it file-private (`_ValueTourFitText`) — the view already imports the
widget file — or, if the fit-or-ellipsis rule is wanted app-wide, move it to the
design system and note that in `SHARED_REQUEST.md` rather than shipping it as a
feature API.

### 4. MINOR — `app/ios/Podfile.lock` is modified in the worktree
`app/ios/Podfile.lock` (+6 lines: the `flutter_timezone` pod). That path is
outside RULES §1 (allowed: `app/lib/features/onboarding/**`,
`app/test/features/onboarding/**`, `docs/screens/P02/**`); it is a CocoaPods
byproduct of the simulator builds the screenshot stages run, not part of the
screen, and it must not ride along in the screen commit.
Fix: `git checkout -- app/ios/Podfile.lock` (or have the orchestrator confirm pod
locks are owned by main).

### 5. MINOR — a `TextPainter` layout per row on every layout pass
`value_tour_preview_row.dart:136-147`: `ValueTourFitText` builds and lays out a
throwaway `TextPainter` inside `LayoutBuilder` to measure the natural width, five
times per card (4 titles + card 2's caption) on every layout, including each
page-change rebuild. Microseconds each, so no measurable frame cost today, but it
is avoidable work on the hot path.
Fix: memoise the measurement per `(text, style, textScaler)` in a static map, or
compute it once per card and pass `natural` in.

### 6. MINOR — `PopScope(canPop: false)` also intercepts a deep link
`value_tour_view.dart:181-183`, `:140-144`. BUG-6 (in-flow back → `/welcome`) is
fixed; a cold `INITIAL_ROUTE=/value-tour` also lands on `/welcome` instead of
letting back exit. Accepted in `2_build.md` and unchanged since iteration 2 —
confirm it is intended. (Lowest priority of the six.)

## Verified (no finding)

- **Iteration-3 MAJOR really fixed** — the fit path is bounded and measured:
  `paintedScaleOf` (`value_tour_view_test.dart`) divides the `FittedBox` slot by
  the unbounded paragraph width, so the assertions on ratios 1.0/0.95/0.92 and the
  0.5 starvation case are real (the old tautologies are gone, and
  `didExceedMaxLines == true` in the fallback case proves horizontal truncation is
  detectable again). BUG-10a/b/c apply the same measurement at 320×1.0, 320×1.3 and
  390×1.3 and require ≥ 0.9. The probe builds its own slot from a measured natural
  width, so it is font-agnostic and immune to the ~2× widget-test font — the same
  care the stage-3 notes asked for.
- **ORCHESTRATOR_NOTES 1 (design copy/data is the spec)** — `Maya · weekly`,
  `Leo · once`, `Maya · daily`, coins 15/15/10/15, `4 of 6 quests done today`,
  static `Sat 4 Oct` (`value_tour_view.dart:93`, `:322-351`, `:390-394`), with the
  deliberate reversal of DATA OVER MOCKS documented in-code.
- **ORCHESTRATOR_NOTES 2 + the COPY rule** — every design string matches
  `P02-value-tour.html` code point by code point (`Today’s`/`Pip’s`/`Maya’s` U+2019,
  `Reading –` U+2013, `·` U+00B7, `“Put the bins out” —` U+201C/D/2014, `£`
  amounts) in the view, in `onboarding_repository_impl.dart:33-47` and in the tests,
  which additionally reject ASCII quotes/apostrophes and U+2026 in every string
  rendered across all three pages.
- **CHILD ORDER** — no child roster on this screen (rows follow the design's
  illustration order; nothing sorted alphabetically) and the seed-order test
  asserts `[maya, leo]` with a discriminating negative case.
- **Bottom edge (owner)** — CTA surface runs to the physical edge: verified in both
  device shots (y800–843 = `#FFFFFF` light, `#1F1C2E` dark) and by the
  painted-pixel tests at 34dp inset and inset 0.
- **Alignment (owner)** — 20dp gutters for the copy, CTA, card left edge and Skip at
  320/390/430 × both themes; one shared inner left edge per card row; Skip's ink
  ends at 356.7 vs the design's 365.0 — the deliberate 8px outer pad that trades
  the design's 12dp nav inset for the owner's 20dp gutter (correct: the rule
  overrides the PNG).
- **RULES §1** — code changes stay inside `features/onboarding/presentation/**`,
  `features/onboarding/data/onboarding_repository_impl.dart` (allowed, and
  commented) and `test/features/onboarding/**`; the only out-of-scope edit is
  finding 4. No `core/`, `app/`, `tools/` or `analysis_options` change.
- **ARCHITECTURE** — feature shape intact; no new bloc/event/state, no DI or route
  change, no use-case or `utils` layer, `package:nestling/...` imports only.
- **Design system** — private `_TourNav` retired for the shared
  `NestNavBar(compact: true, actionLabel: 'Skip')`; all pager metrics from the new
  `NestPager` tokens (only the 40dp stage-dot art is a documented token-less
  private const); no `Color(0x…)` in either file; every gap/inset a `NestSpacing`
  value; the measurement style comes from `NestType`, whose GoogleFonts styles carry
  an explicit family, so the `TextPainter` probe and the painted text resolve the
  same face.
- **DESIGN_SPEC §5 P02 / SPACING_SPEC** — all elements present and ordered (Skip,
  3 dots with the first active, card order and rhythm, 400dp pager, clipped peek,
  `Next` → `Continue`); UK spelling; `£` to two decimals; coins not prices.
- **PIP rule** — `PipAvatar(style: PipStyle.mochi, stage: 3)` (sunny/idle/none are
  widget defaults), no v1 `pip_stage_*.svg`, 158dp slot via `NestPager.pet`, design
  alt text, stage dots decorative as in the HTML.
- **Accessibility** — one `Semantics(header: true)`; the pager group label tracks
  the step; Skip is a real button (label + tap action, ≥44dp, asserted on the shared
  node); CTA ≥52dp full width; icon tiles silent; the three add-row labels are
  plain text, proven to carry **no** tap action and to neither page nor navigate;
  Pip labelled `image`; dots are indicators with no "Go to page" actions.
- **Performance** — no streams/timers/animation controllers; `_controller` disposed
  in `dispose()` and on width change; cards const; one `setState` per page change;
  `shouldRepaint` correct; `PageView.builder` builds only the visible pair; reduced
  motion honoured for the page turn and by `NestMotion` in the dots (finding 5 is
  the only added layout cost).
- **Error handling** — `_goTo` guards `hasClients`, clamps the target, honours
  RULES §6; `ValueTourFitText` guards non-finite slots and zero-width painters;
  `_onSystemBack` checks `context.mounted`; no throws on any path.
- **Children's Code** — parent-only marketing copy, no analytics/ads/tracking, no
  child photos/emails/location, no loss-aversion framing, no £ on a kid surface.

## Notes for the orchestrator (not findings)

1. ORCHESTRATOR_NOTES 3's second half (320 × 1.3) is met by **full-size ellipsis**,
   not by wrapping, and that is the right call here: the 38dp `.pv-row` cannot
   grow without breaking the spec-fixed 400dp card — four 2-line titles add ~80dp to
   a card whose content is already 359dp (439 > 400). If wrapping is preferred at
   narrow widths, the pager must be allowed to grow (or the tile/pill to shrink).
2. The residual ~4px body-text offset vs the PNG (628.7 vs 632.7 for the same line
   box) is a font-metric difference between the browser render and Flutter's
   Google-Fonts Inter, identical on every screen; the design-width rows now match
   exactly (dots, title, card bounds, CTA).
3. `NestListRow(compact: true)` still has no callers after P02 moved off it — a
   tidy-up candidate for the shared backlog alongside `SHARED_REQUEST.md` item 5
   (chip border box), which is the last measured shared drift on this screen (+3dp
   of card-1 body offset and the documented `gap9` on card 2).
4. Design-system lesson worth keeping: `FittedBox(scaleDown)` is shrink-to-fit with
   no lower bound. `ValueTourFitText`'s measure-then-decide pattern is the shape
   every "avoid ellipsis" hack in the app should take.

VERDICT: PASS