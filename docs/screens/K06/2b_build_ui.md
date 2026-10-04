# K06 · Pip's nest (`/pip`) — UI build (stage 2b, iteration 4)

Layer owned: `app/lib/features/pip/presentation/views/**` +
`presentation/widgets/**`, plus the view/widget tests in
`app/test/features/pip/` (`*view*`, `*widget*`). Re-read `2a_build_logic.md`
before finishing: **CONTRACT CHANGES: None** — no event, state, entity or
repository shape changed, so nothing had to be re-coded against a new
contract. Its `FIXES_3` triage handed five items to this layer (#1–#5), two of
them only after coordinated edits in files the logic stage does not own; those
handoffs are listed item by item below.

Net effect of this iteration: **-585 / +349 lines** across 17 files, both
local design-system forks deleted, and K06's last open design-fidelity major
(the sun-hat glyph) closed from the screen side.

## FIXES_3 triage — every UI/layout/copy item

| # | Item | Status here |
|---|---|---|
| 1 | **major** — batch-7 component switch only 2/5 landed (`PipCareButton`, `PipNestSlot`, `_DashedBorderPainter` still forked) | **DONE.** Care row → `NestKidButton(trailing:)`; pet block → `NestPetStage` with the documented K06 args; locked tile → `NestDashedBorder`. `pip_care_button.dart` and `pip_nest_slot.dart` deleted, painter deleted. `grep -r "PipCareButton\|PipNestSlot\|_DashedBorderPainter" lib/features/pip/presentation/` → empty. |
| 2 | **minor** — `pipStageName()` sits in `domain/` (architecture: domain = entities + abstract repo only) | **DONE.** Moved to `presentation/widgets/pip_look.dart` beside the other Pip-look helpers; removed from `domain/entities/pip_nest.dart`. Call sites: `pip_nest_view.dart` (already imports `pip_look.dart`), `pip_growth_card.dart` (+1 import). |
| 3 | **minor** — view imports the concrete `PipRepositoryImpl` for the care-cost numbers | **DONE.** `feedCostCoins` / `bathCostCoins` now live on the abstract `PipRepository`; the impl duplicates are deleted and its two internal reads re-pointed; all six view readers re-pointed. `pip_nest_view.dart` no longer names `data/` at all. |
| 4 | **minor** — `_BackButton` re-implements `NestIconButton` | **DONE.** The top row uses `NestIconButton(icon: NestIcons.back, size: NestDevice.tapKid, iconSize: 26, backgroundColor/borderColor: Colors.transparent)` with the same `context.pop()` / `go(KidHomeRoutePaths.home)` fallback and the `k06-back` key the tests find. |
| 5 | **minor** — locked-tile price drew w800, the design's `.k6-item-p` is w900 | **DONE.** `PipCoinAmount` takes a `fontWeight`; the tile passes `w900`, the care row keeps `w800` (the design's `.k6-coin`). No test asserted either weight, so this was free. |
| 6 | **minor** — `DESIGN_SPEC.md` §5 K06 prose quotes superseded numbers (280 px stage, 72 px tiles) | **Not actionable here** — shared doc outside RULES §1. Runtime already follows the PNG oracle; filed as `SHARED_REQUEST.md` §8 for a spec amend. |
| 8 | **process** — `pip_orchestrator_notes_test.dart` syntax error in an uncommitted sweep, `pip_buy_result_test.dart` untracked | **Not findings** (orchestrator rule); both are green as they now stand. |
| 16 | **minor** — the only live skip is the sun-hat byte proof | **DONE.** See the ORCH item 2 row. |

### ORCH item 2 (6_bugs' one open major) — closed from the screen side

`shared/k06_glyphs` (`5ff0c40`, merged into this worktree) added the exact
`K06-pip.html` glyphs, so the screen's mapping could finally move:

- `pipWardrobeIcon('sunhat')` → `NestIcons.wardrobeSunHat` (was
  `NestIcons.sunHat`, whose brim sat 2.2 units higher with a flatter dome and
  a third band stroke). Scarf / Wellies were already on the batch-7 constants;
  crown stays (batch 7 verified its geometry).
- Feed → `NestIcons.kidFeed`, Play → `NestIcons.kidPlay` (exact `.k6-care`
  paths; the old `feedBowl` / `ball` were look-alikes). Bath already matched
  (`bubbles`).
- The parked proof is **un-skipped and green** —
  `pip_orchestrator_notes_test.dart` → "ORCHESTRATOR NOTES item 2 (extra): the
  sunhat glyph is the design path". There is now **no `skip:` anywhere in
  `test/features/pip/`**.

I re-verified the two switched care glyphs against the light design PNG by
reading local crops of it (no image attached, per the brief): the design's Feed
is the bowl + stem + morsel arc and Play is the seamed circle — i.e. the two
new constants, not the old look-alikes.

### One test-side consequence the switch exposed (and how it was resolved)

`pip_iter2_fixes_test.dart`'s "the row is still exactly 91 px" proof measured
the **keyed widget box** of `k06-feed`. With the shared `NestKidButton` that box
is 91 px of painted card **+ 6 px** of internal `Padding(bottom: gap6)` — the
room its pressed 6 px shadow needs — so it now measures 97 and the proof went
red. The design number did **not** drift: the painted card is still 91 (and the
view already absorbs the 6 with `SizedBox(height: s4 - gap6)` to hold the pitch
after the row at s4). The proof now measures the **painted** rect
(`AnimatedContainer` descendant, the visible background box — which is also what
the owner's "UI check measures shapes, not only text" rule asks for) against 91,
and separately asserts the widget box is exactly `91 + NestSpacing.gap6`, so the
compensation cannot be silently re-tuned. All three buttons stay equal in height
and top at 1.0×, 1.3×, 320 px and 430 px.

## Files changed

Product (`lib/features/pip/`):
- `presentation/views/pip_nest_view.dart` — care row on `NestKidButton(trailing:)`
  with the design glyphs, pet block on `NestPetStage` (230×206, pip 134,
  `pipBottom: 81`, `BoxFit.contain`, no glow, no ground shadow), `NestIconButton`
  back control, costs read from the abstract repo.
- `presentation/widgets/pip_look.dart` — `pipStageName()` moved in; sun hat →
  `wardrobeSunHat`; rationale comments updated.
- `presentation/widgets/pip_wardrobe_tile.dart` — `NestDashedBorder` instead of
  the local painter; tile price w900.
- `presentation/widgets/pip_growth_card.dart` — one import (helper's new home).
- `presentation/widgets/pip_coin_amount.dart` — `fontWeight` param.
- **deleted** `presentation/widgets/pip_care_button.dart`,
  `presentation/widgets/pip_nest_slot.dart`.

Coordinated edits outside my layer, made only because #2/#3 could not land
without them, and both explicitly handed to this stage by `2a_build_logic.md`
("Left for the UI builder… one mechanical pass"):
- `domain/pip_repository.dart` — the two care-cost constants added to the
  abstract contract (5 and 3; values unchanged).
- `data/pip_repository_impl.dart` — duplicate constants removed, its two
  internal reads re-pointed at the abstract.
- `domain/entities/pip_nest.dart` — helper deleted (moved out).
- `test/features/pip/pip_repository_test.dart` — import path only (the review's
  own instruction: "plus the two test imports"); `pip_bloc_test.dart` never
  called it, so it needed nothing.
- `test/features/pip/k06_bugs_test.dart` — 2 lines (an import and a
  `find.byType(PipCareButton)` → `NestKidButton`) that could not survive the
  fork deletion. That file is not view/widget-named; the change was forced and
  is disclosed here rather than hidden.
- `test/features/pip/pip_orchestrator_notes_test.dart` — the `skip: true`
  removed (mandated by this brief) plus its comment.
- `test/features/pip/{pip_nest_view,pip_nest_widget,pip_nest_interactions,pip_iter2_fixes}_test.dart`
  — re-targeted at the shared components; the care-height proof re-based as
  described.

`docs/screens/K06/SHARED_REQUEST.md` — §1/§2/§3 marked RESOLVED/adopted on
`main` (the roll-up `4_review.md` #1 asked for), §5 marked done, §7 marked
resolved with the adoption note, and a new §8 filed for the DESIGN_SPEC prose.

## Verification (UI-stage scope — no whole-app suite, no simulator)

```
flutter analyze lib                              → No issues found!   (2.9s)
flutter analyze lib/features/pip test/features/pip → No issues found!
flutter test --timeout 120s test/features/pip   → +220: All tests passed!   (0 skips)
```

The feature-directory run is scoped to `test/features/pip` (not the whole-app
suite, which is the integrator's): I ran it because #2/#3 touch `domain/` +
`data/` and I must not ship a tree that breaks the logic stage's proofs. My own
view/widget files are green inside it (`pip_nest_view_test`,
`pip_nest_widget_test`, `pip_nest_interactions_test`,
`pip_iter2_fixes_test`, `pip_orchestrator_notes_test` = +74).

Owner rules re-checked while editing: no `flutter clean`, no `flutter run`, no
simulator booted/installed/driven/screenshot, no image attached (the PNGs were
read with the file reader, crops only), `analysis_options` untouched, no
`google_fonts`, no `DateTime.now()`, no new ids, no colour/size literals (the
glyph swaps changed asset constants only, colours stay on tokens), no
`letterSpacing` added, `NestBalancedText` still on the `.kid-title` heading,
`NestChipWrap` untouched (this screen has no chip row), copy characters
untouched (U+00B7 middle dot, ASCII apostrophe in "Pip's wardrobe", em dash in
the caption), `PipAvatar` still the child's own look everywhere (Maya mochi ·
sunny · stage 3; Leo bolt · sky · stage 2), child order Maya-then-Leo from the
repository, no bottom bar so nothing under one, meadow only from `KidScope`.

## LEFT FOR NEXT ITERATION

1. **`5_ui` must re-measure the care row by its painted rect.** The shared
   `NestKidButton` adds 6 px of shadow padding below the card, so a UI check
   that reads the widget box will see 97 where the design says 91 — measure
   the visible background rect (or the card's top + 91) or it will report a
   false 6 px error. The design check for everything else (positions, chips,
   wardrobe tiles) is unchanged.
2. **`5_ui` should eyeball the three switched glyphs** in light and dark at
   their design sizes: the Feed bowl, the Play seamed ball and the Sun hat.
   All three are token-coloured, so only the paths changed.
3. **`DESIGN_SPEC.md` §5 K06 prose** (SHARED_REQUEST §8): 230×206 stage and
   78.5 px tiles, for whoever owns the spec.
4. **`kPipNotWearable`** ("That one is not something Pip can wear.") is still
   the only on-screen string the design does not define — orchestrator
   ratification, unchanged since iteration 1.
5. **Stale comment, not a defect:** `k06_bugs_test.dart:318` still narrates the
   "screen-local `_DashedBorderPainter`" that this iteration deleted (the
   proof itself is green and correct). One-line comment fix for whichever
   stage next owns that file.

VERDICT: PASS
