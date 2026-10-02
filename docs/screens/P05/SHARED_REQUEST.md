# Shared request — P05 Add children nav bar

Need: `NestNavBar` in compact mode with no title crashes. When `title` is
null the middle `Expanded` builds a `Spacer` (itself an `Expanded`) inside
itself, and Flutter throws a competing-`FlexParentData` assertion. P05 (and
any future back-chevron-only bar) needs `compact: true` with no centred
title to work — either return a `SizedBox.shrink()`/`Spacer`-free filler when
`title == null`, or document the supported configuration.

Files: `app/lib/core/design_system/components/nest_nav_bar.dart`

Blocks: no — P05 builds against the foundation as-is with a `TODO(P05)`
workaround (`title: ''`, visually identical: an empty centred text node).

---

# Shared request — P05 navigation (`push` no-op from top-level routes)

Need: `context.push(...)` from a top-level (non-shell) route never
navigates and never errors — verified in a widget probe
(`GoRouter.of(ctx).push('/pocket-money-setup')` leaves
`currentConfiguration` on `/add-children`, while `go(...)` moves). The
onboarding funnel (P01 precedent) navigates with `go`, and the child
profile (a `StatefulShellRoute` branch page) is reached from P08 with `go`
+ `?childId=` — so P05 follows the same `go` convention and lands without
this. But every future onboarding plan that specifies `push` will hit the
same silent no-op; worth one orchestrator-level look at the router setup
(go_router 18.0.2, `buildAppRouter` in `app/lib/app/router.dart`).

Files: `app/lib/app/router.dart` (shared — investigation only, no edit
requested from this screen)

Blocks: no — P05 uses `go` throughout (`go` to `/privacy`, `go` to
`/pocket-money-setup`, `go` to `/child-profile?childId=`).

---

# Shared request — P05 Add children `NestChip` stretches to the full row width
# (BLOCKS the P05 UI gate)

Need: an **interactive `NestChip` inside a `Wrap` fills the whole run width**,
so any multi-chip row collapses into one chip per line, centred, and the form
grows ~170 px. `nest_chip.dart:69-90` builds the interactive branch as
`ConstrainedBox(min 44×44) → Center → Material → InkWell → Ink(padding 14)`.
`Center` is an `Align` without factors, so it takes `constraints.biggest`: in a
`Wrap` run that is the entire available width, every chip reports a full-width
box, and the `Wrap` must break after each one. The visible pill (`Ink`) keeps
its intrinsic width — only the layout/hit box is wrong.

Measured on P05 (demo seed, 390×844, logical px, from the P05 test stage):

| | design | app |
|---|---|---|
| age chips | one row, `gap: 8` | 4 stacked rows at y 519 / 571 / 623 / 675 |
| chip layout box | `.chip { height:32; padding:0 14 }` + 44 tap area | **322×44 each** (whole card content width) |
| form card height | ≈298 (design PNG y 315→613) | ≈470+ |
| 10–12 / 13+ chips | visible | below the fold, **under** the bottom CTA |
| avatar swatches | visible | under the bottom CTA |

Consequences beyond the visual diff (reproduced in `3_test.md`):

1. A tap at a swatch's position lands on the CTA's **Continue** button and
   navigates to `/pocket-money-setup` instead of choosing a colour.
2. Only 2 of the 4 age bands are reachable without scrolling.
3. Screenshot evidence: `docs/screens/P05/ui/bug_evidence_chips_light.png`.

Why P05 cannot work around it (measured in throwaway probes, since deleted):

* `Row` gives the right chip widths (73.75 px at scale 1.0, 323.5 total ≤
  350 available) but the chip box fills the row height (560 px tall in an
  unbounded-height Row), and the four chips **overflow by 32 px at 390/1.3×**
  and by **102 px at 320/1.3×**. `SPACING_SPEC` §10 requires 320 + 1.3 to lay
  out, so `Row` is out.
* `Wrap` is what the design asks for (`.chip-row { display:flex; gap:8px;
  flex-wrap:wrap }`, `SPACING_SPEC` §6 `.chip-row`) and it is the only
  container that survives 320 + 1.3×.

So the fix belongs in the component. `SPACING_SPEC` §6 already states the
intent: "base 32 high is below 44 → Flutter must wrap in 44-min tap area" —
the tap area must not stretch the chip. A candidate that keeps the pill's
intrinsic width while guaranteeing ≥44×44: replace the full-width `Center`
with a `ConstrainedBox(min 44×44)` **around the pill** via
`Stack(alignment: center)`, or give `Center` `widthFactor: 1,
heightFactor: 1` and enforce the 44 minimum on the pill's own
`ConstrainedBox`.

Regression test to add with the fix (P05 — cannot pass today, see
`3_test.md` P05-BUG-1):

```dart
testWidgets('age chips share one row', (tester) async {
  await setUpTestScope();
  await pumpAppRoute(tester, '/add-children');
  final tops = <double>{
    for (final band in AddChildFormCard.ageBands)
      tester.getTopLeft(find.byKey(Key('ageChip-$band'))).dy,
  };
  expect(tops, hasLength(1)); // one row, not four
});
```

Files: `app/lib/core/design_system/components/nest_chip.dart`
(affected call site today:
`app/lib/features/family/presentation/widgets/add_child_form_card.dart:70-82`)

Blocks: **yes for the P05 UI gate** — all 65 P05 tests and `flutter analyze`
pass, but the screen cannot match the design until a chip row renders as one
row. Every screen with a chip row hits this (today
`design_system_gallery/presentation/widgets/pip_lab_controls.dart`,
`gallery_parent_a.dart`).

---

# Shared request — P05 compact `NestNavBar` is 44 px, the spec says 52 px

Need: `NestNavBar` compact sets `constraints: BoxConstraints(minHeight:
NestDevice.tapParent)` (44), so the whole bar is 44 tall — measured on P05:
the back button occupies y 47→91 and the head starts at y 91.
`SPACING_SPEC` "nav-bar" (lines 83, 88) specifies **min-height 52** for
`.nav-bar.compact` ("Flutter: 64 (52 compact) bar"). The delta moves every
compact-bar screen's content up from the design: measured against
`design/screens/light/P05-add-children.png`, the h1 ink sits at y 112.3 in the
design and y 96.3 in the app screenshot.

Files: `app/lib/core/design_system/components/nest_nav_bar.dart`

Blocks: no — P05 uses the design-system component as-is; a one-line
`minHeight` change fixes every compact bar at once.
