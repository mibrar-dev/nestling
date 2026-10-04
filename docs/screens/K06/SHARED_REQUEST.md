# Shared request — K06 two shared-component gaps

Two K06 layout needs cannot be expressed by the shared design system as it
stands on `main`. Both were solved screen-locally inside
`app/lib/features/pip/presentation/widgets/` (allowed by RULES §1), with the
design's own numbers and no invented values. Landing these would let K07 (and
any future kid screen) delete the forks.

## 1. `NestPetStage` cannot express the K06 pet slot

Need: K06's design slot is 230 × 206 with the nest `<img>` 230 × 230 at
`bottom: 0` (so it bleeds 24 px above the slot) and `PipAvatar` 134 tall at
`bottom: 81` (`design/html-source/screens/K06-pip.html`). The shared explicit
size mode pins its block to `PipNestFallback._explicitSlotH = 236` and seats
the pip at `nestRimTopFraction * nestH + rimOverlap` with
`rimOverlap = 44.2` — both tuned to K03's 236 × 188 slot. Feeding it K06's
numbers puts the nest 31 px too high and the pip 45 px too high, and no
(nestWidth, nestHeight, pipHeight) triple fixes it: keeping the nest square
(230, as the design's `<img>` is) forces the pip box to ~120 tall instead of
134. With a screen-local 40-line slot (`widgets/pip_nest_slot.dart`) the app
lands the design's slot exactly (measured: x 80, y 150, 230 × 206).

Files: `core/design_system/components/nest_pet_stage.dart`,
`core/design_system/motion/pip_rive.dart` (`PipNestFallback.explicitGeometry`,
`_explicitSlotH`, `_explicitBleed`, `rimOverlap`).

Blocks: no. K06 works around it; the fork is marked `TODO(K06)`-style in the
widget's header comment.

## 2. `NestKidButton` has no third ("trailing") row

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

## 3. Minor: no dashed-border widget

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
