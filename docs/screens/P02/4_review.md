# P02 Value tour — QA code review (Stage 4, iteration 3)

Reviewed the full branch diff (`git diff main...HEAD` + working tree) against the
mandatory `docs/screens/P02/ORCHESTRATOR_NOTES.md`, the new COPY and CHILD ORDER
owner rules, RULES §1, ARCHITECTURE, DESIGN_SPEC §5 P02, SPACING_SPEC and the
design system (post `shared_requests_batch1`).

Verified in `app/`: `flutter analyze` → *No issues found!*; `dart format
--set-exit-if-changed .` → *0 changed*; `flutter test` → **612 passed, 1 failed**
(the failure is the out-of-scope shared test in the merge-blocker note below).

Device bands re-measured on `ui/app_light_4.png` against
`design/screens/light/P02-value-tour.png` (÷3):

| Band | Design | App | |
|---|---|---|---|
| card 1 top / bottom | 107 / 507 | 107 / 507 | exact |
| dashed add-row | 447 → 490 | 447 → 490 | exact |
| CTA hairline / button | 725 / 742–794 | 726 / 742 | exact |
| dots / title ink | 534–542 / 582–608 | identical | exact |
| step-body line 1 ink | 632.7–645.3 | 633.3–641 | exact (iteration-2's 4px offset is gone) |
| preview-row tile 1 | 170 | 173 | +3, shared chip border box |
| bottom edge y800–843 | paper | surface `#FFF` / `#1F1C2E` | owner rule ✓ |

**ORCHESTRATOR_NOTES compliance:** 1 (design static copy + data) ✓ ·
2 (typographic characters) ✓ · 4 (bottom edge) ✓ · 3 (no truncation) ✗ at
narrow widths — finding 1.

## Merge blocker (orchestrator-owned — not a screen finding)

`app/test/app/router_push_test.dart:91` asserts `showsTo: 'P02 Value tour'`,
a literal that only exists on main's placeholder. The screen cannot render it
without inventing copy the design does not have, and RULES §1 keeps `test/app/`
out of screen scope, so **the branch cannot go all-green until the orchestrator
batches the one-line fix** already filed as `SHARED_REQUEST.md` item 4
(`showsTo: 'Set quests in seconds'`, matching the file's own P01 pattern).
This is the same red state the build stage ended on; P02's own code is not at
fault and must not be "fixed" by editing the view.

## Findings

### 1. MAJOR — the preview titles shrink to illegible type instead of wrapping
`app/lib/features/onboarding/presentation/widgets/value_tour_preview_row.dart:83-101`.

`FittedBox(fit: BoxFit.scaleDown, alignment: centerLeft, child: Text(title, maxLines: 1, overflow: ellipsis))`
does **not** guarantee "no ellipsis" — it guarantees "no ellipsis *or* clip",
by scaling the text to whatever factor fits. Flutter's
`RenderFittedBox.performLayout` (3.47.5, `rendering/proxy_box.dart:2922`) lays
the child out with `const BoxConstraints()` — fully unbounded — and then
`applyBoxFit(scaleDown, childSize, slot)` returns `min(1, slotW/childW,
slotH/childH)`. Measured with the device's real Inter (title ink 81.0→244.0 at
390, i.e. a natural 163dp in a 164.7dp slot ⇒ scale 1.00):

- 320dp: title slot = 208 − 36 tile − 8 − 8 − ~59 pill ≈ **97dp** vs a 163dp
  natural ⇒ **scale ≈ 0.60 ⇒ "Empty the dishwasher" paints at ~9px**.
- 320dp × text scale 1.3: natural ≈ 212dp, slot ≈ 92dp ⇒ **scale ≈ 0.43 ⇒ ~6.5px**.

That breaks DESIGN_SPEC §0 rule 9 (parent body text ≥ 15px) and rule 4 ("long
text wraps or truncates with ellipsis"), and it fails the second half of
ORCHESTRATOR_NOTES 3 ("320 width + text scale 1.3 wraps rather than ellipsises
where the design has room"). It is also silently font-dependent at the design
width: with an Inter 2% wider than the browser's, the 390dp title would quietly
render at ~14.7px instead of the design's 15px.

Fix: bound the shrink. Lay the title out in a `LayoutBuilder` and only keep the
shrink-to-fit while `slot / natural ≥ ~0.92`; below that allow the row's title to
wrap (`maxLines: 2`, `softWrap: true`) or ellipsise at full 15px — the row height
is already `max(36, …)`, so a 2-line title only costs height on narrow screens
where the design has no reference. Assert the *effective* scale in a test
(`natural = paragraph.size.width`, `slot = tester.getSize(find.byType(FittedBox)).width`,
expect `slot / natural ≥ 0.9` at 390 and at 320 × 1.3).

### 2. MINOR — both "no truncation" proofs are tautological
`app/test/features/onboarding/p02_bugs_test.dart:353-372` (BUG-7) asserts
`paragraph.getMaxIntrinsicWidth(double.infinity) <= paragraph.size.width + 0.5`;
because the FittedBox child is laid out **unbounded**, `size.width` *is* the
intrinsic width, so this can never fail. `value_tour_view_test.dart:1336-1348`
("no preview title is truncated at 320dp × text scale 1.3") asserts
`paragraph.didExceedMaxLines == false`, which is equally unconditional — the
unconstrained single-line paragraph never wraps, truncated or not. Both tests
therefore pass while the screen does exactly what finding 1 describes; the stage-3
note "the device is the authority for line fitting" is right, but the two tests
still read as enforcement.
Fix: assert the painted geometry (finding 1's scale ratio) or the painted ink
width of the row title (the UI stage already measures it from the screenshot), and
delete/redirect the two vacuous assertions so the suite does not certify a defect.

### 3. MINOR — stale retirement contract on `ValueTourPreviewRow`
`value_tour_preview_row.dart:10-12` still says "Retire it in favour of the shared
compact-row variant requested in `SHARED_REQUEST.md` once that lands", and
`SHARED_REQUEST.md` item 2 is now **WITHDRAWN** ("solved locally"). Iteration 2
also flagged the duplicated `NestTileTint → (bg, fg)` switch
(`value_tour_preview_row.dart:54-60` vs `nest_list_row.dart:37-44`); with the
request withdrawn there is no path for that duplication to retire.
Fix: update the doc comment to say the widget is the permanent P02 row (no shared
variant planned) and either extract the tint mapping to one shared helper or state
in the comment that the duplication is deliberate.

### 4. MINOR — the chip's 1.5px border still inflates the head row; no request is open for it
`nest_chip.dart:26-33` puts `Border.all(1.5)` around a `SizedBox(32)`, so the chip
is a 35px box. Measured consequence: card-1's first tile is at **y173 vs the
design's y170** (+3 through the whole card body), and card 2 only fits the restored
400dp pager because `.pg-stages` was shaved from the spec's **10 to 9**
(`value_tour_view.dart:433-436`, `NestSpacing.gap9`). Batch 1 changed the chip's
semantics but not its box, and `SHARED_REQUEST.md` item 3 (pager tokens) is now
marked DONE — so nothing is tracking the actual cause.
Fix: add a shared request for the chip's border-box (`Container(decoration:)` with
an inner 32dp content box, or `border` inset), then restore
`NestSpacing.gap10` at `value_tour_view.dart:436`.

### 5. MINOR — card 2's caption is clipped to one line
`value_tour_view.dart:423-432` keeps `maxLines: 1` + ellipsis on
"175 of 250 coins · Pip evolves at 250" (design `.pv-cap` wraps) so the wide
widget-test font cannot push the 400dp card over budget; below ~350dp it
ellipsises. Same trade-off as finding 1 — solve it with the same scale/wrap rule
rather than a blanket `maxLines: 1`. (Unchanged since iteration 2.)

### 6. MINOR — the view still reaches into `_ValueTourViewState` statics
`value_tour_view.dart:80-93`, used at `:348`, `:405`, `:506`. `_headChip` and
`_dateChipLabel` hold no state but live on the screen's `State` class and are
called from three sibling widgets. (Unchanged since iteration 2.)
Fix: file-private top-level helpers or a small `_HeadChip` widget.

### 7. MINOR — `PopScope(canPop: false)` also intercepts a deep link
`value_tour_view.dart:181-183`, `:140-144`. BUG-6 (back → `/welcome`) is fixed for
the in-flow case, but a cold `INITIAL_ROUTE=/value-tour` also lands on `/welcome`
instead of letting back exit. Accepted in `2_build.md`; confirm it is intended.
(Unchanged since iteration 2.)

## Verified (no finding)

- **ORCHESTRATOR_NOTES 1 (design copy/data is the spec)** — every sample string
  is the design's: `Maya · weekly`, `Leo · once`, `Maya · daily`,
  `15/15/10/15`, `4 of 6 quests done today`, static `Sat 4 Oct`
  (`value_tour_view.dart:93`, `:300-329`, `:368-372`). This deliberately reverses
  the iteration-2 DATA OVER MOCKS alignment and BUG-4/BUG-5, and the code
  comments say so (`:90-92`, `:288-292`).
- **ORCHESTRATOR_NOTES 2 + the COPY rule (character-exact)** — I compared every
  design string with the HTML character-by-character: `Today’s quests`,
  `Pip’s nest`, `Maya’s jar` (U+2019), `Reading – 20 minutes` (U+2013),
  `·` separators, `£3.00/+£1.20/£4.20`, and the step body
  `Pick from 40+ ready-made jobs like “Put the bins out” — or make your own.`
  (U+201C/U+201D/U+2014) are byte-identical to
  `design/html-source/screens/P02-value-tour.html` in the view, in
  `onboarding_repository_impl.dart:33-47` (mirrored so loaded and pre-load frames
  agree) and in all three test files. The test suite additionally rejects ASCII
  quotes/apostrophes and U+2026 in every rendered string across all three pages.
- **CHILD ORDER** — this screen renders no child roster (the four rows are the
  design's illustration order; nothing is sorted alphabetically), and the new
  seed-order test asserts `[maya, leo]` with a discriminating negative case.
- **Bottom edge (owner)** — CTA surface runs to the physical edge; verified in
  the device shot (y800–843 is `#FFFFFF` light, `#1F1C2E` dark, never page tint)
  and by the painted-pixel tests at 34dp inset and inset 0.
- **Alignment (owner)** — 20dp gutters for the copy, CTA, card left edge and Skip
  at 320/390/430 × both themes, one shared inner left edge per card row. Skip's
  ink ends at x356.7 (design 365.0): the deliberate 8px outer pad that trades the
  design's 12dp nav inset for the owner's 20dp gutter — correct under the rule
  that overrides the design PNGs, not a misalignment.
- **RULES §1** — changed paths: `features/onboarding/presentation/**`,
  `features/onboarding/data/onboarding_repository_impl.dart` (allowed: the
  punctuation mirror, with an explanatory comment), `test/features/onboarding/**`,
  `docs/screens/P02/**`. No `core/`, `app/`, `tools/` or `analysis_options` edit.
- **ARCHITECTURE** — the retired `_TourNav` and the shared-bar swap keep the
  feature shape; no new bloc/event/state, no DI or route change, no use-case or
  `utils` layer, `package:nestling/...` imports only.
- **Design system** — the feature-private `_TourNav` and `p02_skip` key are gone in
  favour of the shared `NestNavBar(compact: true, actionLabel: 'Skip')`
  (batch 1's content-sized trailing slot; `value_tour_view.dart:192-199`), and the
  bar renders 4+44+12 = 60, so card 1 is back at the design's y107. All pager
  metrics now come from the new `NestPager` tokens (`stage`, `pet`,
  `lineMinHeight`, `addDash*`, `addMinHeight`) — the only private size left is the
  40dp stage-dot art, which is documented as token-less. No `Color(0x…)` in either
  file; every gap/inset is `NestSpacing`.
- **DESIGN_SPEC §5 P02 / SPACING_SPEC** — all elements present (Skip, 3 dots with
  the first active, card order and rhythm, 400dp pager, clipped peek, "Next"→
  "Continue" CTA); UK spelling, `£` to two decimals, coins not prices.
- **PIP rule** — `PipAvatar(style: PipStyle.mochi, stage: 3)` (sunny/idle/none are
  widget defaults), no v1 `pip_stage_*.svg`, 158dp slot via `NestPager.pet`, the
  design's alt text, stage dots decorative as in the HTML.
- **Accessibility** — one `Semantics(header: true)`; the pager group label tracks
  the step; Skip is a real button (label + tap action, ≥44); CTA ≥52 full width;
  icon tiles silent; the three add-row labels are plain text **and proven to carry
  no tap action** (iteration-2 finding 9 now closed); Pip labelled `image`; dots are
  indicators with no "Go to page" actions.
- **Performance** — no streams/timers/animation controllers; `_controller`
  disposed in `dispose()` and on width change; cards const; one `setState` per page
  change; `shouldRepaint` correct; `PageView.builder` builds only the visible pair;
  reduced motion honoured for the page turn and by `NestMotion` in the dots. The
  FittedBox unbounded relayout costs four small paragraphs.
- **Error handling** — `_goTo` guards `hasClients`, clamps the target and honours
  RULES §6; `_onSystemBack` checks `context.mounted`; no throws on any path.
- **Children's Code** — parent-only marketing copy, no analytics/ads/tracking, no
  child photos/emails/location, no loss-aversion framing, no £ on a kid surface.

## Notes for the orchestrator (not findings)

- ORCHESTRATOR_NOTES 3's first half (390dp, one line) is met today — verified on
  the device shot (all four titles render in full, ink 81.0→244.0, no U+2026) — but
  only because Flutter's Inter draws ~2% wider than the browser's and the title
  still fits its 164.7dp slot. Findings 1–2 make that explicit and durable.
- DESIGN_SPEC §0 rule 4/9 vs `FittedBox` shrink-to-fit is a general design-system
  question (other screens may reach for the same trick to dodge ellipsis); the fix
  in finding 1 is worth stating as a rule: never scale a design's type below its
  token size — wrap or ellipsise instead.
- `shot.sh` now saves stable frames in both themes (the batch-1
  `DISABLE_ANIMATIONS` parsing fix closed the iteration-1…3 UI-6 residue).
- `NestListRow(compact: true)` still has no callers after P02 moved off it — a
  tidy-up candidate for the shared request backlog.

VERDICT: FAIL