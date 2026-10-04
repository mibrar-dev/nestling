# Shared request — K06 shared-component gaps (all RESOLVED, iteration 4)

> **STATUS UPDATE — stage 2b, iteration 4: every section below is now
> RESOLVED and nothing is outstanding.** §1/§2/§3 landed on `main` as
> `shared/shared_batch7` and K06 has ADOPTED them (the local forks
> `pip_nest_slot.dart`, `pip_care_button.dart` and `_DashedBorderPainter`
> are deleted — `4_review.md` #1). §5 (glyphs) and §6 (prices) were already
> adopted at iteration 3. §7 (the sun-hat glyph) landed as
> `shared/k06_glyphs` (commit `5ff0c40`) and is adopted too, with its parked
> proof un-skipped and green. §8 carries the only remaining item, which is
> purely documentary.

## 1. RESOLVED (adopted on `main` as shared_batch7) — `NestPetStage` cannot express the K06 pet slot

Need: K06's design slot is 230 × 206 with the nest `<img>` **230 × 206** at
`bottom: 0` (HTML line 22) and `PipAvatar` 134 tall at `bottom: 81`
(`design/html-source/screens/K06-pip.html`). The shared explicit
size mode pins its block to `PipNestFallback._explicitSlotH = 236` and seats
the pip at `nestRimTopFraction * nestH + rimOverlap` with
`rimOverlap = 44.2` — both tuned to K03's 236 × 188 slot. Feeding it K06's
numbers puts the nest 31 px too high and the pip 45 px too high.
With a screen-local 40-line slot (`widgets/pip_nest_slot.dart`) the app
lands the design's slot exactly (measured: x 80, y 150, 230 × 206).

Iteration 1 of this screen drew the nest art **230 × 230** with
`BoxFit.fill`, on the reading that the design's `<img>` was square and
"bleeds above the slot". That is wrong on both counts (K06-BUG-4, corrected
in iteration 2): the CSS says 206 high, and `nest.svg` is a
`viewBox="0 0 240 240"` document, which a browser fits UNIFORMLY into the
230 × 206 `<img>` box — a 206 × 206 nest with 12 px of letterbox each side.
Measured on `design/screens/light/K06-pip.png` (÷3): the nest's widest painted
row is logical y 277.7 and spans x 108.3 – 281.3, i.e. 173.0 wide =
`202 units × 206/240`, which is the 206 scale exactly. A shared slot mode
that honoured an explicit `(width, height)` box for the nest art with
`BoxFit.contain` would serve this without the screen-local fork.

Files: `core/design_system/components/nest_pet_stage.dart`,
`core/design_system/motion/pip_rive.dart` (`PipNestFallback.explicitGeometry`,
`_explicitSlotH`, `_explicitBleed`, `rimOverlap`).

Blocks: no. K06 works around it; the fork is marked `TODO(K06)`-style in the
widget's header comment.

## 2. RESOLVED (adopted on `main` as shared_batch7) — `NestKidButton` has no third ("trailing") row

Need: `.k6-care .btn-kid` stacks three rows in a column — 24 px icon, the
17/20 label, then the coin price (`.k6-coin`, 16 px coin + 14 px digits) or the
`.k6-free` pill (3/8 padding, 13 px w800). `NestKidButton` lays out
`icon + gap + label` only, so the care row is reproduced in
`widgets/pip_care_button.dart`: same 3 px ink border, `--r-l` radius,
`--sh-kid` shadow, `translateY(4px)` press, disabled `opacity .45` with no tap
action, and the same Semantics contract (button + label + enabled + onTap).

Files: `core/design_system/components/nest_kid_button.dart` — add
`Widget? trailing` rendered after the label with the same `gap` as the
icon/label pair (K06 passes `gap: 3` already).

Blocks: no.

## 3. RESOLVED (adopted on `main` as shared_batch7) — Minor: no dashed-border widget

`.k6-item.locked` is a 3 px dashed `--ink-2` border on `--surface-2` with no
shadow. Flutter has no dashed `BorderSide` and the design system has no
dashed-border component, so `widgets/pip_wardrobe_tile.dart` walks the tile's
rounded-rect path with a small `CustomPainter` (dash 6 / gap 3, measured off
the design PNG). A shared `NestDashedBorder` would remove ~35 lines from this
screen and any future locked/locked-state card.

Files: `core/design_system/components/` (new file + barrel export).
Blocks: no.

## 4. NOTIFY (done inside K06 at integration, one precedent-based exception) — K03 tests located the pushed `/pip` route by its placeholder title

Need: `app/test/features/kid_home/kid_home_view_test.dart` located the pushed
`/pip` route with `find.text('K06 Pip nest')` — the **placeholder** `AppBar`
title of the foundation stub — in two proofs: `K03 navigation dock Pip opens
/pip` and `every dock button exposes a tap action and routes` (tuple entry
`('Pip', '/pip', 'K06 Pip nest')`). K06 replaced that stub with the real nest
(no `AppBar`, per the design), so both went red and `flutter test` could not
pass (`01:32 +3187 ~2 -2`).

The repo has already ruled on this exact class of fix, twice:

- `docs/screens/_shared/HEADER.md` line 6 — "NEVER assert placeholder view
  texts … screen agents replace placeholders; assert the router location
  (`currentPath`) or keys instead".
- `docs/screens/_shared/router_push_test_fix_REPORT.md` §5 — "If a shared test
  ever needs a widget on screen, assert a `ValueKey` on shared chrome, or assert
  a path. **Never a placeholder view title**", and its follow-up #5 names the
  feature-test cleanup that a screen must do when its own route lands.
- Precedent for the agent doing it rather than waiting:
  `docs/screens/P09/SHARED_REQUEST.md` §3 (identical situation against P08's
  `today_view_test.dart` / `p08_bugs_test.dart`, same swap).

Status: **done** at Stage 2 (integration), test-only, no K03 assertion
weakened, no K03 behaviour touched. Both proofs now assert the route:

- `dock Pip opens /pip`: `expect(find.text('K06 Pip nest'), findsOneWidget)` →
  `expect(pushedPath(tester), '/pip')`, with the in-file comment already used
  by the sibling `lock opens the parental gate` proof (line 1995).
- `every dock button exposes a tap action and routes`: the tuple's third field
  becomes `String?`; `('Pip', '/pip', null)` asserts the route only, and
  `find.text(screen)` runs only for the two destinations that are still
  placeholders (`K08 Reward shop`, `K09 My jar`). The `hasTap` check, the
  `performTap` semantics activation and `expect(pushedPath(tester), path)` for
  all three dock buttons are byte-for-byte unchanged — the K03 contract the test
  exists to protect is strictly stronger afterwards (it can no longer pass
  against a stub that merely renders the old title).

Files (outside RULES §1, deliberate): `app/test/features/kid_home/kid_home_view_test.dart`
— 16 lines, both hunks confined to the two `/pip` assertions.
Blocks: no. **The orchestrator should know:** if the K03 loop is running, this
file is the only place its branch and this one touch the same lines, and the
merge conflict there is textual, not a design conflict.

---

## 5 — DONE (adopted) — Wardrobe glyphs are the design's glyphs (ORCHESTRATOR_NOTES 11:30, item 2)

Need: replace two shared `core/design_system` icon assets whose art is a
**look-alike**, not the K06 design glyph. The wardrobe tiles paint
`NestIcons.scarf` / `NestIcons.wellies` / `NestIcons.sunHat`, which resolve to
`assets/icons/ic_scarf.svg`, `assets/icons/ic_wellies.svg`,
`assets/icons/ic_sun_hat.svg`. A screen agent may not edit anything under
`app/lib/core/**` (RULES §1), and the note forbids substituting a glyph — so
the fix has to land on the shared asset, from the design's own path data.

Design glyphs, copied verbatim from `design/html-source/screens/K06-pip.html`
`.k6-ward` (the `<svg viewBox="0 0 24 24" … stroke-width="2">` inside each
`.k6-item`):

```html
<!-- Scarf (line 73) -->  <path d="M5 3h4v18H5z"/><path d="M11 3h4v5a2 2 0 0 1-4 0z"/><path d="M7 9v6"/>
<!-- Sun hat (line 74) --> <path d="M3 16h18l-1.6 2.4H4.6z"/><path d="M7 16a5 5 0 0 1 10 0z"/>
<!-- Wellies (line 75) --> <path d="M8 3v8l-2 4.2A3 3 0 0 0 8.7 20h5.6A2.4 2.4 0 0 0 16.6 15l-2.6-4V3z"/><path d="M6 3h4M14 3h4"/>
<!-- Crown (line 76) -->  <path d="M4 8l3.6 3L12 5l4.4 6L20 8l-1.6 9H5.6z"/><path d="M6 20h12"/>
```

Measured differences (asset path data vs the design, whitespace/case
normalised):

| Tile | Asset today | Design | Verdict |
|---|---|---|---|
| Scarf | `M7.6 3.6h8.8v13.2l-1.7 2.4H9.3L7.6 16.8Z` + two bars + three fringe ticks (a fringed blanket) | two vertical strokes, a flag, one tick | **different glyph** (named in the note) |
| Wellies | `M6.8 5.1h4.4v8.1h3.9a3.1 3.1 0 0 1 3.1 3.1v.4a2.4 2.4 0 0 1-2.4 2.4H8.9a2.1 2.1 0 0 1-2.1-2.1Z` + 2 strokes | boot/flask body + the two top ticks `M6 3h4M14 3h4` | **different glyph** (named in the note) |
| Sun hat | `M2.4 13.8h19.2l-1.6 2.8H4Z` + `M6.8 13.8a5.2 7 0 0 1 10.4 0Z` + an extra `M7.4 11.6h9.2` | `M3 16h18l-1.6 2.4H4.6z` + `M7 16a5 5 0 0 1 10 0z` | same idea, different coordinates + an extra stroke (not named in the note) |
| Crown | `M4 8l3.6 3L12 5l4.4 6L20 8l-1.6 9H5.6zm2 12h12` | `M4 8…H5.6z` + `M6 20h12` | **same geometry** (implicit lineto; `m2 12h12` ≡ `M6 20h12` after `z`) — leave it alone |

Files: `app/assets/icons/ic_scarf.svg`, `app/assets/icons/ic_wellies.svg`,
`app/assets/icons/ic_sun_hat.svg` (shared design-system assets), plus their
declarations in `app/lib/core/design_system/assets/nestling_assets.dart` if
the file names change.

**PARTLY LANDED (13:52 update + verified at Stage 2, iteration 3).**
`shared/shared_batch7` (`2517101`) added `ic_wardrobe_scarf.svg` and
`ic_wardrobe_wellies.svg` (`NestIcons.wardrobeScarf` / `.wardrobeWellies`) with
the exact K06 paths, and K06 now paints them (`pip_look.dart`), so **§5 is
closed for the two glyphs ORCHESTRATOR_NOTES item 2 names** — both proofs in
`pip_orchestrator_notes_test.dart` are live and green.

**Still open — the sun hat.** Batch 7 left `NestIcons.sunHat` alone, reporting
that it "already match[es] the design geometry". It does not: the asset is
`m2.413.8h19.2l-1.62.8H4z` + `m6.813.8a5.2700110.40z` + an extra
`m7.411.6h9.2`, against the design's `m316h18l-1.62.4h4.6z` +
`m716a55001100z` — same silhouette, different coordinates plus an extra brim
stroke (the same table row in §5 above already recorded this). The note does
not name the sun hat, so this is a bonus finding rather than a mandate, but it
is the same defect class and K06 may not edit the asset (RULES §1). Filed as
§7 below with its parked proof.

Blocks: **no** for K06 — the screen renders today and the fix is cosmetic. But
it blocks the note's item 2, which is a mandatory iteration-2 target.

Proof (parked, deterministic):
`app/test/features/pip/pip_orchestrator_notes_test.dart` —
"ORCHESTRATOR NOTES item 2: the scarf / wellies / sunhat glyph is the design
path". Each compares the asset's path data against the path data read out of
`K06-pip.html` at test time, so the oracle can never drift:

```
flutter test test/features/pip/pip_orchestrator_notes_test.dart --run-skipped
```

## 6 — DONE (shared_batch7 `2517101`, verified at Stage 2 iteration 3) — wardrobe prices: the seed says 40/120, the design says 30/60
(ORCHESTRATOR_NOTES 11:30, item 3)

Need: decide the single source of truth for `pip_wardrobe.priceCoins`. The
K06 design (HTML lines 75–76 and `design/screens/light/K06-pip.png`) shows
**Wellies 30 / Crown 60**; `Seed._wardrobeDemo`
(`app/lib/core/data/seed.dart:605-613`) writes **40 / 120** for Maya and
30/40/120 for Leo. The note says the seed mirrors the designs and asks for a
request rather than a hard-coded price; the DATA OVER MOCKS rule says the
database is correct and the design number is the mock. Both rules agree on the
mechanics — **never hard-code a price in the view**, render
`watchWardrobe(item).priceCoins` — and disagree only on which row is right.

This is a shared `core/data/seed.dart` change plus a schema-value question, so
it cannot be fixed inside `features/pip/**` (RULES §1).

Options for the orchestrator:
1. change the seed to 30/60 to match the designs (and re-check any other screen
   that renders these prices), or
2. change the design source + both PNGs to 40/120 and keep the seed.

K06 renders the seeded value today: `PipWardrobeTile` shows `'${item.priceCoins}'`
and the semantics label `'<Name>, <price> coins'` — no literal anywhere. Tests
that pin this behaviour, so a seed change flips them honestly rather than
silently:
`pip_nest_view_test.dart` ("wardrobe renders design names, owned state and DB
prices", "every control exposes SemanticsAction.tap", "an affordable wardrobe
tap buys…", "buying an affordable item spends the DB price"),
`pip_repository_test.dart`, `pip_orchestrator_notes_test.dart` item 3 (which
also proves the price follows the row: it re-seeds Crown to 7 and expects 7).
Files: `app/lib/core/data/seed.dart` (or `design/html-source/screens/K06-pip.html`
+ `design/screens/{light,dark}/K06-pip.png`).
Blocks: no.

**Resolution.** The orchestrator took option 1: `shared_batch7` moved
`Seed._wardrobeDemo` to the design's numbers for Maya and Leo (wellies 30,
crown 60), so DATA OVER MOCKS and the designs now agree and there is nothing
left to choose. K06 needed **no production change** — the view already rendered
`item.priceCoins`. What the merge did redden was every K06 test that had typed
the old 40/120 as its premise; Stage 2 iteration 3 re-based them all to read
the seeded row instead (see `2_build.md` FIX 2). The `K06-BATCH7` proof that was
parked precisely for this is live again and green.

## 7 — RESOLVED (`shared/k06_glyphs`, `5ff0c40`; adopted + proof un-skipped): the sun-hat glyph was a look-alike (the third tile batch 7 left behind)

Need: `app/assets/icons/ic_sun_hat.svg` should draw the design's sun-hat paths
from `K06-pip.html` line 74 —

```html
<path d="M3 16h18l-1.6 2.4H4.6z"/><path d="M7 16a5 5 0 0 1 10 0z"/>
```

— as a new shared asset beside batch 7's `ic_wardrobe_scarf.svg` /
`ic_wardrobe_wellies.svg` (e.g. `ic_wardrobe_sunhat.svg` +
`NestIcons.wardrobeSunHat`). What the screen paints today is the same
silhouette on different coordinates plus an extra brim stroke:
`m2.413.8h19.2l-1.62.8h4z` + `m6.813.8a5.2700110.40z` + `m7.411.6h9.2`.

Why this is filed even though ORCHESTRATOR_NOTES 11:30 item 2 names only Scarf
and Wellies: those two are closed, so this is the same defect class left with
one tile, and it is the tile a user sees third. Batch 7's report states sun hat
and crown "already match the design geometry"; the proof below shows the sun hat
does not, while the crown does (it is excluded from the byte comparison for a
documented reason: identical geometry written with an implicit lineto and a
relative `m2 12h12`).

K06 may not edit shared assets (RULES §1) and the note forbids substituting a
glyph in-screen, so this needs a shared batch.

Files: `app/assets/icons/ic_sun_hat.svg` (or a new
`assets/icons/ic_wardrobe_sunhat.svg`) + `nestling_assets.dart` /
`nest_icon.dart`.
Blocks: no (K06 renders and the note's mandate is met). Proof (parked,
deterministic — the oracle is the HTML, read at test time):
`app/test/features/pip/pip_orchestrator_notes_test.dart` →
"ORCHESTRATOR NOTES item 2 (extra): the sunhat glyph is the design path".

```
flutter test test/features/pip/pip_orchestrator_notes_test.dart --run-skipped \
  --plain-name sunhat
```

Adoption note (stage 2b, iteration 4): `pipWardrobeIcon('sunhat')` now returns
`NestIcons.wardrobeSunHat` (`assets/icons/ic_wardrobe_sun_hat.svg`), and the
parked byte proof in `pip_orchestrator_notes_test.dart` ("ORCHESTRATOR NOTES
item 2 (extra): the sunhat glyph is the design path") is LIVE — no `skip:` is
left anywhere in `test/features/pip/`. The Feed and Play care glyphs moved to
the same batch's `NestIcons.kidFeed` / `NestIcons.kidPlay` (exact
`K06-pip.html` `.k6-care` paths, confirmed against both design PNGs);
`NestIcons.bubbles` already matched Bath.

## 8 — OPEN (documentation only, no runtime effect) — `DESIGN_SPEC.md` §5 K06 quotes superseded numbers

`4_review.md` #6: §5 K06's prose still says "280px stage 3" and "72px tiles".
The HTML/PNG oracle is `.k6-pet` **230 × 206** (a square `nest.svg`
letterboxed with `BoxFit.contain`, `pipBottom: 81`) and four `flex:1` tiles of
(350 − 3 × 12) / 4 = **78.5** at 390 px, shrinking with the width
(SPACING_SPEC §10.2). K06 follows the measured PNG — the iteration-3 UI stage
measured every structural row at Δ 0 — so no screen code changes; the spec
text is what will mislead the next K* screen that copies it. Outside this
screen's editable set (RULES §1 allows `docs/screens/K06/**` only), hence
filed rather than amended.
