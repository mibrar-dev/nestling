# Shared requests — P09

## 1. `NestSegmented` height — RESOLVED on main (`8ad0cdc`, "shared(batch4)")

Need: `NestSegmented` used to render a **44 px** container with a **36 px**
thumb, but `docs/design/SPACING_SPEC.md` §"`.segmented → NestSegmented`" (and
DESIGN_SPEC §9 conflict 1) both rule that the rendered value wins:
"height **52** total (44 + 4 + 4); buttons Expanded, **44** high". The P09
design PNG agrees — measured on `design/screens/light/P09-quest-editor.png`
the segmented track is y 480→532 (52) and the selected thumb y 484→528 (44).

Status: **landed**. The component now builds
`height: NestDevice.tapParent + NestSpacing.s2` (52) with
`height: NestDevice.tapParent` (44) segments, so P09's Repeats block needs no
workaround. `quest_editor_view_geometry_test.dart` pins the track at
`(20, 480, 350, 52)` and the three tab centres at 79.7 / 195 / 310.3, so a
regression fails the screen's own suite. Nothing further is requested.

## 2. `NestToggle` paints its track centred in its hit box — compensated in P09, advisory

Need: `.toggle` in `design/html-source/components.css` is a **51x31** track with
an absolutely positioned `::before { left/right: -4px; top/bottom: -7px }`
hit area. The design puts the **track** flush with the row's content edge and
lets only the hit area overhang into the card padding — measured on the P09
PNG the track is x 303→354, y 620.5→651.5 while the hit area runs to 358.

`NestToggle` is the mirror image: a 59x44 box (the same 51+8 / 31+13 hit area)
that *centres* the 51x31 track inside it, so in a `.card` the painted switch
lands 4 px short of the content edge and 2 px low — an alignment failure under
the owner's "nothing a few px off" rule for any screen that right-aligns a
toggle (P09 `Needs my approval`, and P08/P16 wherever they use it).

P09 does not re-implement the component: it wraps it in
`Transform.translate(QuestEditorMetrics.toggleTrackOffset /* (4, -2) */)` so
the visible track lands on the design rect, and the 44 px tap target only
moves into the card's own 16 px padding (where the CSS `::before` sits
anyway). A cleaner fix on the component would be to make the 51x31 track the
child's own box and let the 59x44 hit area be an `OverflowBox`/padding that
hangs outside it — then every call site aligns the track by ordinary layout.

Files: `app/lib/core/design_system/components/nest_toggle.dart`
(needs a shared change because `core/` is off-limits to screen agents).

Blocks: **no** — P09 lands and is pixel-correct with the in-view offset.

## 3. NOTIFY (done inside P09, one precedent-based exception) — P08 tests located the pushed editor by its placeholder title

Need: `test/features/today/today_view_test.dart` (11 uses) and
`test/features/today/p08_bugs_test.dart` (4 uses) found the pushed P09 route
with `find.text('P09 Quest editor')` — the **placeholder** `AppBar` title of
the foundation stub. P09 replaced the stub with the real sheet (no AppBar, per
the design), so all 8 of those P08 proofs went red and `flutter test` could
not pass. The repo already ruled on this exact class of fix:

- `docs/screens/_shared/router_push_test_fix_REPORT.md` §4 — "Never a
  placeholder view title"; assert a route (or a `ValueKey`), and §5 names
  these two files as the outstanding instance of it.
- `docs/screens/_shared/shared_batch4.md` §4 — the batch agent was told
  explicitly: "You MAY edit `app/test/features/today/**` … to delete the
  hidden anchor".

Status: **done** in this iteration, test-only, no P08 assertion weakened.
The anchor becomes the durable contract — `pushedPath(tester)` /
`_pushedUri(tester)` (both read `GoRouter.state.uri` from the top-most
rendered route) for "the editor is on screen", and
`find.byType(QuestEditorView, skipOffstage: false)` for the two proofs whose
whole point is "exactly one editor page, not two stacked". Every other
assertion in those tests (query params, `pop` returning to `/today`, the
guard latching) is untouched.

Files (outside RULES §1, deliberate): `app/test/features/today/today_view_test.dart`,
`app/test/features/today/p08_bugs_test.dart`.
Blocks: no — but **the orchestrator should know**: if P08's loop is running,
these two files are the only place its branch and this one touch the same
lines, and a merge conflict there is a textual conflict, not a design one.

## 4. `NestIcons` glyphs for bed / dishwasher / hoover / bin do not match the P09 design (BLOCKS P09 UI check)

Need: the P09 icon picker (`.ic`, 6 × 44×44 tiles) draws its glyphs from the
shared `NestIcons` set, but four of them are visibly different objects from
the design's inline SVGs (`design/html-source/screens/P09-quest-editor.html`
and both `design/screens/*/P09-quest-editor.png`), in light and dark:

- `NestIcons.bed` = lidded chest/box; design Bed = flat mattress/bed-frame
  side view.
- `NestIcons.dishwasher` = dishwasher/oven with racks; design Dishes =
  handled basket.
- `NestIcons.hoover` = hook/whistle-like loop; design Hoover = canister
  vacuum with hose + wheels (this is the *selected* tile — most visible).
- `NestIcons.bin` = rimmed trash bin; design Bins = small handled case/clasp.
- (`NestIcons.book`, `NestIcons.paw` match; tile geometry — 44×44, r14,
  1.5 border, selected leaf/tint — is already correct.)

Whole-tile MAE vs the design (0–255): bed 4.5, dishwasher 19.9, hoover
20.5, bin 17.3, book 4.1, paw 1.9. Measured in `docs/screens/P09/5_ui.md
(stage 5, iteration 1): layout is pixel-perfect (uniform shift 0, every
edge ≤ ±2 px, gutters 20, paper to the physical edge), so the glyphs are
the *only* blocker and the UI check verdict is FAIL until they match.

P09's mapping (`app/lib/features/quests/presentation/views/quest_editor_view.dart:230-240`)
is already semantically right (bed→bed, dishwasher→dishwasher,
hoover→hoover, book→book, bins→bin, paw→paw) — and re-drawing glyphs inside
`quests/` would fork the design system, so the screen takes no redraw.

**CORRECTION (iteration 2, stage 5 — verified against git, supersedes the
paragraph below):** no DS redraw has landed. `git log --all` shows
`ic_hoover.svg` / `ic_bed.svg` / `ic_bin.svg` / `ic_dishwasher.svg` untouched
since the baseline (`f912ef0`), the working tree is clean under
`app/assets/`, and the baseline bytes ARE what both UI checks measured:

- `ic_bed.svg` (baseline) = bed frame + headboard arc
  (`M3 18v-8…M3 18h18` + `M5 8V6a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v2`); the
  design's Bed is the same frame WITHOUT the headboard arc (MAE 4.5 —
  close, not exact).
- `ic_hoover.svg` (baseline) = rounded canister (`rect x=3 y=10.8 w=11.8
  h=8.2 rx=3.4`) + curved hose + handle bar + two filled-dot wheels; the
  design's Hoover is an angular canister (`rect x=3 y=8 w=13 h=8 rx=2`) +
  angular hose + two leg LINES (MAE 20.5 — a different drawing).
- `ic_basket.svg` (baseline, substituted onto the Dishes tile in the
  iter-2 build) = tapered slatted laundry basket; the design's Dishes is a
  plain basket + single arch handle (MAE 17.5). Per the mandatory
  orchestrator ruling (ORCHESTRATOR_NOTES.md 17:57 item 1) this look-alike
  substitution must be REVERTED, not kept: the exact design glyph is
  missing from `app/assets/icons`, so the DS must gain it.
- `ic_bin.svg` (baseline) = rimmed wheelie bin; the design's Bins is a
  small handled case with a clasp (MAE 17.3).
- `ic_book.svg` and `ic_paw.svg` ARE path-identical to the design's SVGs
  (verified byte-for-byte on the `<path>`/`<circle>` elements; tile MAE
  4.1 / 1.9 is raster residue only).

Exact design sources (verbatim from
`design/html-source/screens/P09-quest-editor.html`, 24×24, stroke 2, round
caps/joins) for the DS redraw — Bed, Dishes, Hoover, Bins in that order:

- Bed: `<path d="M3 18v-8a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v8"/><path d="M3 18h18"/>`
- Dishes: `<path d="M4 11h16v9a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-9z"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>`
- Hoover: `<rect x="3" y="8" width="13" height="8" rx="2"/><path d="M16 12h3a2 2 0 0 0 2-2V7a2 2 0 0 0-4 0M7 16v3M11 16v3"/>`
- Bins: `<path d="M3 7h13v9H3zM7 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M10 12h4"/>`

Superseded paragraph (kept for the audit trail — its redraw claims are
wrong, see CORRECTION above):

- `assets/icons/ic_hoover.svg` is now a canister body
  (`rect x="3" y="10.8" w="11.8" h="8.2" rx="3.4"`) with a hose, a handle bar
  and two wheels — the design's *object* (the "hook/whistle loop" the UI check
  measured is gone).
- `assets/icons/ic_bed.svg` is now a bed frame + headboard side view; the
  design's SVG is the same frame without the headboard arc.
- `ic_book.svg` and `ic_paw.svg` are byte-identical to the design's SVGs.

Still outstanding: **`ic_dishwasher.svg`** is an appliance (rack line + two
control dots) where the design's Dishes is a handled basket, and
**`ic_bin.svg`** is a rimmed wheelie bin where the design's Bins is a small
handled case with a clasp. For Dishes the screen now draws
`NestIcons.basket` (the DS laundry basket: tapered body + handle arc) as the
closest in-DS match — a glyph swap in `quests/`, not a redraw — but the exact
design path is still wanted. `ic_dishwasher.svg` stays the right glyph for the
seeded quests on the P10 library rows (`quest_idea_meta.dart`'s
`questIconAsset`).

Files: `app/lib/core/design_system/**` wherever `NestIcons.bed`,
`.dishwasher`, `.hoover`, `.bin` are drawn. The exact design paths are
quoted in the CORRECTION above (P09 HTML source, 24 px, stroke 2, round
caps/joins).
Blocks: **yes for the UI verdict** — P09 cannot PASS stage 5 until the DS
glyphs match. Two P09-side steps are still needed on top of the DS redraw
(screen code, next iteration): (1) REVERT the iter-2 `NestIcons.basket`
substitution on the Dishes tile (`quest_editor_view.dart:260-270`) back to
the exact-glyph icon once the DS gains it — look-alike substitution is
forbidden by ORCHESTRATOR_NOTES.md 17:57 item 1; (2) re-take the stage-5
screenshots after the merge-back. Iter-2 stage-5 tile MAEs for the record:
bed 4.5 / dishes 17.5 / hoover 20.5 / book 4.1 / bins 17.3 / paw 1.9.

## 5. `NestStepper` draws its minus as U+002D, both designs print U+2212 (advisory)

Need: `app/lib/core/design_system/components/nest_stepper.dart:32` passes
`label: '-'` (HYPHEN-MINUS, U+002D) to `_StepBtn`. Both designs that show a
stepper print `&minus;` — `design/html-source/screens/P09-quest-editor.html`
(`aria-label="Decrease reward">−</button>`, bytes `e2 88 92`) and the P06
source — so the Reward card's `−` is rendered ~3 px short and 1–2 px high
against the PNG.

The repo has already ruled on this exact class: **P06-BUG-12** ("the stepper
minus is the design's U+2212, never U+002D") was fixed with a screen-local
`P06WeeklyStepper` + `kP06StepperMinusGlyph = '−'` and two regression tests
(`p06_bugs_test.dart:870`, `p06_weekly_stepper_widget_test.dart:34`), and
`money_ledger_view_test.dart:352` audits the app's copy for ASCII hyphens
precisely because "the design uses U+2014/U+2212". P09 cannot take that
workaround without forking the component (`--tap` sizing, `NestType.money`
value, the shared 44 px buttons), so the glyph stays a shared request.

**Note for whoever lands it (verified iteration 2, stage 2b):**
`test/features/quests/quest_editor_copy_test.dart`'s `kGlyphs` currently
*requires* the ASCII hyphen (`'-'`, line 85) because the app still draws one —
the opposite of the older note here, which said the list excluded it. When
`nest_stepper.dart` switches to `'−'`, that entry must be replaced with `'−'`
in the same commit or P09's copy audit goes red.

Files: `app/lib/core/design_system/components/nest_stepper.dart`
Blocks: **no** — a 1-character copy deviation in a shared control; P09 lands
either way. Fixing the component fixes P06's fork at the same time.

## 6. `NestTextField` default variant leaves a ~3 px text inset (advisory, ORCHESTRATOR_NOTES 17:57 item 2)

Need: the orchestrator's QA of `cmp_light_1` measured the Quest name
value starting at x ≈ 40 where the design has x ≈ 37. Measured in a P09
widget test: the input box is exactly the design's `20 / 156 / 350 / 52`,
but its `EditableText` starts at x **40** — 20 px in from the box edge,
where `components.css:131` asks for `border 1px` + `padding 0 16px` = 17.
Cause is shared: the default variant sets
`contentPadding: EdgeInsets.symmetric(horizontal: NestSpacing.s4, vertical: 14)`
(`nest_text_field.dart:303`) on top of Material's built-in ~4 px text inset.
The same file already has the fix pattern — the search variant cancels it
with `contentPadding: EdgeInsets.only(left: -4, …)`
(`nest_text_field.dart:199`, "Cancels the editable's built-in 4 px text
inset").

Files: `app/lib/core/design_system/components/nest_text_field.dart`
Blocks: **no** — 3 px of glyph inset inside a 52 px field; the element rects
are exact and stage 5 measured every edge within ±2 px.