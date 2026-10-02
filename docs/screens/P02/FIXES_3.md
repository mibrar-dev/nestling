# Fix list after iteration 3

## From 2_build.md
# P02 Value tour — build notes (Stage 2, iteration 3)

Implemented per `docs/screens/P02/1_plan.md`, the mandatory
`docs/screens/P02/ORCHESTRATOR_NOTES.md`, the new COPY / CHILD ORDER /
bottom-edge / alignment owner rules, and every item in
`docs/screens/P02/FIXES_2.md`. Main has moved since iteration 2
(`shared_requests_batch1`: chip/nav/typography/pager-token fixes,
`DISABLE_ANIMATIONS` parsing, `router_push_test.dart`); this build adopts
what it delivered for P02 and re-verifies everything against it.

## Files changed (this stage)

- `app/lib/features/onboarding/presentation/views/value_tour_view.dart`:
  retired the feature-private `_TourNav` for the shared compact bar
  (`NestNavBar(compact: true, actionLabel: 'Skip', …)` — content-sized
  trailing slot landed in batch 1) plus an 8px outer pad that keeps Skip on
  the 20px owner gutter (design nav inset is 12px); adopted the new
  `NestPager` tokens (`stage`, `pet`, `lineMinHeight`, `addDash*`,
  `addMinHeight`) for every pager metric except the 40px stage-dot art.
  Height stays 4+44+12 = 60, card top stays y=107, Skip stays at width−20.
- `app/test/features/onboarding/value_tour_view_test.dart`: Skip finders
  reworked onto the shared node (tap/size via `find.text('Skip')` and the
  bar's `InkWell`; label/button via `bySemanticsLabel('Skip')`; tap action
  on the `InkWell` node); added the `_skipInkwell` helper. No expectation
  weakened — sizes, labels, gutter and action asserts are unchanged.
- `docs/screens/P02/SHARED_REQUEST.md`: item 1 (compact slot) and item 3
  (pager tokens) marked DONE/adopted; item 2 stays withdrawn; new item 4
  (shared push/pop contract, Blocks: yes — see below).
- Screenshots: `ui/app_light_4.png`, `ui/app_dark_4.png`, `ui/cmp_light_4.png`,
  `ui/cmp_dark_4.png` (step 1, sim 16e, fresh seed; both frames stable).

## Fix items (FIXES_2 → state)

- BUG-7 (titles truncate): already in tree — `FittedBox(scaleDown)` title
  slot in `ValueTourPreviewRow`; proof passes; device shot shows `Empty the
  dishwasher` in full. Verified, no change needed.
- BUG-8 (design copy): already in tree — design subs, static `Sat 4 Oct`
  chips, derivation deleted. Verified.
- BUG-9 (punctuation): already in tree — curly body/heads in view, repo
  impl mirror, bloc/contract/bug tests. Verified.
- Review/UI residue (body 4px, punctuation ruling): resolved by BUG-9; no
  action.
- Already-green proofs (BUG-1a/b/c, 2, 3a/b, 6) re-verified green after the
  nav/token adoption.
- COPY rule audit vs HTML: `’` heads, `“”`/`—` body, `–` reading, `·`
  separators, `£` amounts all match; no `&nbsp;` in the P02 source to mirror.
- CHILD ORDER: card rows follow the design illustration order (not a
  children list; nothing alphabetical).
- Bottom edge: CTA surface to the physical edge, both themes (re-verified on
  the new shots).

## UI verification (sim 16e, `shot.sh` + `compare.py`, step 1)

- Light mean diff 3.92% → **4.00%** (bands 0–7: 1.95/5.54/5.03/6.43/0.89/
  3.95/4.37/3.80); dark 3.83% → **3.83%**. Deltas vs iteration 3 are noise
  (stable-frame captures, Rive still art); layout/copy identical: full
  titles, `Sat 4 Oct`, design subs, curly body, 400dp pager, dots/title/CTA
  on the design rows, Skip on the 20px gutter.
- Both `shot.sh` runs saved **stable frames** (no 25s warning this round —
  the shared `DISABLE_ANIMATIONS` parsing fix resolved iteration 1–3's
  UI-6 residue).

## Verification (in `app/`)

- `dart format .` — clean (0 changed on final pass).
- `flutter analyze` tail: `No issues found!`
- `flutter test` (full) tail: `00:11 +609 -1` — the single failure is
  `test/app/router_push_test.dart` (`push /value-tour from /welcome`),
  which asserts `find.text('P02 Value tour')`. That literal exists only on
  main's placeholder (`AppBar(title: 'P02 Value tour')`); this branch
  implements the screen per the design, so the expectation contradicts the
  implemented screen. It is outside screen scope (`test/app/`, RULES §1),
  cannot be fixed by any in-scope change, and passes on main — filed as
  SHARED_REQUEST item 4 (Blocks: yes) with the one-line fix specified
  (`showsTo: 'Set quests in seconds'`, matching the file's own P01 pattern).


## From 3_test.md
# P02 Value tour — test notes (Stage 3, iteration 3, second pass)

Route `/value-tour`, feature `onboarding`, parent mode. Tests live in
`app/test/features/onboarding/`; the in-memory Drift DB comes from
`setUpTestScope()` (`Seed.demo` / `Seed.empty` / `Seed.fresh`) and every
router test ends with `disposeApp()`. No screen, bloc, route or design-system
code was changed by this stage.

This pass covers the two **newly added orchestrator rules** (CHILD ORDER,
character-exact COPY) and re-verifies the screen after the iteration-4 build
adopted the **shared `NestNavBar`** for the tour header (shared request 1
landed in batch 1, so the feature-private `_TourNav` and its `p02_skip` key
are gone).

## Tests added this stage

`value_tour_view_test.dart` — 132 → **137 tests** (5 added).

### Orchestrator COPY rule — character-by-character (2)

Font-independent by design: the widget-test font is ~2x wider than real Inter
(a probe measured "Maya · weekly" at 172dp in a 154dp slot, and 7 of the
single-line paragraphs reporting `didExceedMaxLines`), so line fitting cannot
be judged in tests — the device is the authority (see `p02_bugs_test.dart`
P02-BUG-7). Character *identity*, however, is fully testable:

- **Every design character is the typographic code point** — asserts the
  literals carry U+2013 (en dash, `Reading – 20 minutes`), U+2019 (`Today’s`,
  `Pip’s`, `Maya’s`), U+00B7 (`Maya · weekly`, `175 of 250 coins · …`), and
  U+201C/U+201D + U+2014 in the step bodies, plus the *absence* of the ASCII
  fallback for each (`ready-made`'s word-level hyphen excepted), and that the
  step-2 copy has no dash because the design has none.
- **All three pages render exactly the design's characters** — walks the whole
  tour, asserts every card string from `P02-value-tour.html` (`:68-121`) is
  present, then collects **every** rendered string across all three pages and
  rejects any containing an ASCII quote, an ASCII apostrophe or an ellipsis
  (U+2026 can only enter copy through truncation).

### Orchestrator CHILD ORDER ruling (1)

- **Seeded children keep insertion order, not alphabetical** — asserts the
  Drift rows come back `[maya, leo]` (`seed.dart:182`, `:204`) and explicitly
  *not* `[leo, maya]`, so the assertion discriminates the ruling from the
  alternative instead of passing vacuously.

## Bug found (blocking, shared scope — not a screen defect)

**P02 finding: the shared push/pop contract test asserts the retired
placeholder title.**

- **Where:** `app/test/app/router_push_test.dart:91` (`showsTo: 'P02 Value
  tour'`), asserted at `:46`.
- **Repro:** `flutter test test/app/router_push_test.dart` →
  `Expected: true / Actual: <false>` on `push /value-tour from /welcome, pop
  returns`; the other three cases in that file pass.
- **Why:** P02 replaced the foundation placeholder in iteration 1, and no
  design text contains "P02 Value tour" —
  `grep -rn "P02 Value tour" lib/features/onboarding/` matches a doc comment
  only. The real screen renders the tour ("Set quests in seconds"), so the
  shared expectation can never be satisfied by the screen.
- **Scope:** `app/test/app/**` is shared (RULES §1 keeps screen agents to
  `app/test/features/<feature>/**`), so this stage must not edit it, and
  adding the string to the view to satisfy a test would violate the design.
  Already filed by the build stage as `SHARED_REQUEST.md` #4 ("Blocks: yes");
  this stage added independent reproduction evidence to that item. Fix is one
  line — expect real copy, as the same file already does for P01's
  `showsFrom: 'Chores that feel like a game.'`.

Per the stage rules the screen was **not** patched.

## Failures found in my own new tests (test bugs, corrected before gating)

- The first sweep forbade *any* ASCII hyphen, which flagged the body's
  "ready-made" — a word-level hyphen the design itself uses. The rule is now
  precise: hyphen forbidden only when spaced (a dash where – / — belongs),
  and "ready-made" is pinned explicitly.
- Two wrong assertions while writing them: a hard-coded code-point index, a
  duplicated-sub count asserted on pages that do not carry it, and a
  double-advance before the per-page collection loop.

## Re-verified after the shared `NestNavBar` adoption

All previously green coverage still passes against the shared header — 18-combo
width × scale × theme matrix, pager geometry, the three card contents, the 5
bloc states, `Seed.empty`/`Seed.fresh`, the PipAvatar rule, navigation, the
owner-rule pixel proofs (BOTTOM EDGE) and the alignment gutters, plus
`p02_bugs_test.dart`'s 11 proofs with **zero skips**.

One test-authoring consequence is now in the contract file: the Skip action is
shared design-system code, so tests locate it by its `InkWell` inside
`NestNavBar` (size, tap action) and by its semantics label (label, button flag)
rather than the retired `p02_skip` key.

## Results (run by this stage, `app/`)

- `dart format .` — 360 files, 0 changed on final pass.
- `flutter analyze` — `No issues found!`
- `flutter test test/features/onboarding` — **135 passed, 0 failed,
  0 skipped** (every P02-owned and P01-owned test).
- `flutter test` (full suite) — **612 passed, 1 failed, 0 skipped**; the only
  failure is the shared case above (`router_push_test.dart`).

`flutter test` is therefore not all-green, so this stage does not claim PASS.

## Other residual observations (non-blocking)

- The lazy route-level `BlocProvider` (`onboarding_routes.dart:36-40`) still
  runs its load event only on the first read; unchanged since iteration 1 and
  pinned deliberately.
- At 390dp the card head keeps its 180dp chip cap (`_headChip`), which is not
  binding in the real font (~80dp chip) but squeezes the head in the ~2x test
  font. Device behaviour is the UI stage's authority; worth a 320dp device
  look if the QA pass revisits narrow widths.
- Uncommitted build work in the worktree (process item, per the stage rules).


## From 4_review.md
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


## From 6_bugs.md
# P02 Value tour — adversarial bug hunt (Stage 6, iteration 3)

Route `/value-tour`, feature `onboarding`, parent mode, seed `demo`, test
clock pinned to Sat 3 Oct 2026. `ORCHESTRATOR_NOTES.md` exists and is
mandatory; the iteration-3 build fixed BUG-7/8/9 (design copy, typographic
punctuation, full titles), retired the private tour bar for the shared
`NestNavBar(compact: true)` and adopted the `NestPager` tokens. Stage 5 UI
passes at 390×844; Stage 4 review leaves one MAJOR (finding 1) — independently
reproduced here as **P02-BUG-10**.

Proofs live in `app/test/features/onboarding/p02_bugs_test.dart`: the fixed
bugs are un-skipped regressions (10 passing), the one open item is marked
`skip: true` so `flutter test` stays green. No screen code was changed by this
stage (tests + `docs/screens/P02/**` only).

| Id | Severity | Status | Failing tests |
|---|---|---|---|
| P02-BUG-10 | MAJOR | OPEN | `P02-BUG-10a`, `10b`, `10c` |
| P02-BUG-1,2,3,6,7,8,9 | — | FIXED, proofs pass | `P02-BUG-1a/b/c`, `2`, `3a/b`, `6`, `8a/b`, `9` |
| P02-BUG-4/5 | — | VOID | reversed by ORCHESTRATOR_NOTES 1 → replaced by BUG-8 |

---

## P02-BUG-10 — MAJOR — Preview titles shrink far below the 15dp type size instead of wrapping

**Where:** `ValueTourPreviewRow` title slot —
`FittedBox(fit: BoxFit.scaleDown)` around the title
(`value_tour_preview_row.dart:83-101`; review iteration 3, finding 1).

**Repro / evidence**

- The FittedBox lays its child out **unbounded** and then scales it to the
  slot with no lower bound (`applyBoxFit(scaleDown, child, slot) = min(1,
  slotW/childW, slotH/childH)`), so the title's effective type size is
  `15dp × scale` — any slot/natural ratio, however small, is accepted.
- Review iteration 3 finding 1, measured with the device's real Inter:
  **320dp → scale ≈ 0.60 → ~9px**; **320dp × 1.3 → scale ≈ 0.43 → ~6.5px**
  (natural ≈ 212dp vs a ~92dp slot). At 390 × 1.3 the same path silently
  cancels the user's 1.3× request for the long titles.
- This stage's effective-scale proofs (widget-test font, unbounded paragraph
  vs FittedBox slot) reproduce the unbounded behaviour: **0.27 at 320×1.0,
  0.19 at 320×1.3, 0.37 at 390×1.3** (`P02-BUG-10a/b/c`).
- Violates DESIGN_SPEC §0 rule 9 (parent body text ≥ 15dp), rule 4 ("long
  text wraps or truncates with ellipsis") and the second half of
  ORCHESTRATOR_NOTES 3 ("320 width + text scale 1.3 wraps rather than
  ellipsises where the design has room").

**Failing tests**

- `P02-BUG-10a preview titles do not paint below 0.9x at 320dp x 1.0`
- `P02-BUG-10b preview titles do not paint below 0.9x at 320dp x 1.3`
- `P02-BUG-10c preview titles do not paint below 0.9x at 390dp x 1.3`

(each asserts the effective scale of all four titles ≥ 0.9; measured from
`slot / unbounded-paragraph width`, and 1.0 when no FittedBox wraps the
title, i.e. when it wraps/ellipsises at full size).

**Suggested fix:** bound the shrink. Keep the fit-to-slot path only while
`slot / natural ≥ ~0.92` (measure natural with a `TextPainter`/`LayoutBuilder`
using the same 15/20 w600 style); below that, let the title wrap
(`maxLines: 2`, `softWrap: true`) or ellipsise at the full 15dp. The row
height already uses `max(36, …)`, and the pager has vertical room at 1.3
(520dp), so wrapping costs nothing at 390. Keep 390×1.0 one line (device
scale ≈ 1.0 — verified by the UI stage).

**Interplay to watch when fixing:** if the fix wraps in the widget-test
fallback font at 390×1.0 (where natural ≫ slot), the `P02-BUG-2` row-height
proof (rows ≤ 40dp) may need a font-robust restatement (tile 36dp, gaps 8dp,
no vertical padding) — adapt the proof, never keep the shrink.

## Test-integrity fix made by this stage (review finding 2)

The former `P02-BUG-7` proof asserted
`paragraph.getMaxIntrinsicWidth(...) ≤ paragraph.size.width` — vacuous under
`FittedBox`, whose child is laid out unbounded, so `size.width` *is* the
intrinsic width. It has been **removed** and replaced by the `P02-BUG-10`
effective-scale proofs above. The 390dp "one line, no ellipsis" requirement
is verified on the device shot by the UI stage (title ink 81.0→244.0, pill at
254, no U+2026).

The same vacuous pattern remains in `value_tour_view_test.dart:1336-1348`
("no preview title is truncated at 320dp × text scale 1.3") — it asserts
`didExceedMaxLines == false` on the unconstrained single-line paragraph and
can never fail; it must be replaced by the scale assertion when BUG-10 is
fixed (already in the review's fix list).

---

## Fixed in iteration 3 — re-verified by the un-skipped proofs

- **P02-BUG-1/2/3** — pager 400dp (card y107→507 exact), 38dp preview rows,
  unified scroll on 320×568 / 375×667×1.3 (no exceptions, copy reachable,
  horizontal paging intact).
- **P02-BUG-6** — system back (in-flow and deep link) lands `/welcome`.
- **P02-BUG-7** — at 390dp all four titles render in full on one line
  (device ink 81.0→244.0; see the BUG-10 caveat for other widths).
- **P02-BUG-8** — design static copy restored: `Maya · weekly`, `Leo · once`,
  `Maya · daily`, `Maya · weekly`; chips `Sat 4 Oct` (proofs read the
  rendered rows/chips).
- **P02-BUG-9** — character-exact punctuation: `Today’s quests`,
  `Pip’s nest`, `Maya’s jar`, `“Put the bins out” — or make your own.`
- Shared-nav swap and `NestPager` tokens introduced no regressions: Skip is a
  single semantics node (`label 'Skip'`, `isButton`, tap action) at 89×44 with
  its right edge on the 20dp gutter (x=370), card geometry unchanged, no new
  exceptions.

## Checked — no new bug

- **320 / 430 / 1.3 matrices:** no RenderFlex overflow or exceptions at any
  probed surface; only the BUG-10 scaling is wrong.
- **Rapid taps / back / deep links / kid guard / dark tokens / money /
  timezone / async / a11y labels:** unchanged from iteration 2 (clean);
  the new shared bar keeps a single labelled, tappable Skip node.
- **External, not a screen finding:** `test/app/router_push_test.dart` still
  asserts the placeholder literal `'P02 Value tour'` (main-only), so the full
  suite is 611 passed + 3 skipped + 1 failed. `test/app/` is outside RULES §1;
  already filed as `SHARED_REQUEST.md` item 4 and owned by the orchestrator.

## Carry-over minors from the Stage 4 review (in the review's fix list)

1. Chip's 1.5dp border inflates the head row by +3 (tile y173 vs design 170)
   and forces `gap9` instead of the spec `gap10` on card 2 — needs a shared
   chip border-box request.
2. `ValueTourPreviewRow`'s doc comment still promises retirement in favour of
   the withdrawn shared-row request; the `NestTileTint` → colours switch is
   duplicated from `NestListRow`.
3. Card 2's caption is pinned to `maxLines: 1` (ellipsises below ~350dp)
   instead of the same wrap rule as BUG-10.
4. `_headChip`/`_dateChipLabel` live on `_ValueTourViewState` and are called
   from sibling widgets; move to file-private helpers.
5. `PopScope(canPop: false)` also intercepts a cold deep-link back and lands
   on `/welcome` (accepted in `2_build.md`; confirm intended).

## Verification (run this stage, `app/`)

- `flutter test test/features/onboarding/p02_bugs_test.dart` —
  **10 passed, 3 skipped, 0 failed**.
- `flutter test --run-skipped …/p02_bugs_test.dart` — `P02-BUG-10a/b/c` fail
  with measured scales **0.27 / 0.19 / 0.37** (< 0.9).
- `flutter test test/features/onboarding` — **134 passed, 3 skipped**.
- `flutter test` (full) — **611 passed, 3 skipped, 1 failed** (external
  `test/app/router_push_test.dart`, orchestrator-owned).
- `flutter analyze` — `No issues found!`; `dart format` clean.
- No screen code touched; only `p02_bugs_test.dart` and this file.

