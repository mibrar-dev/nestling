# Shared request — P05 children in creation order (CHILD ORDER ruling)

> Status (iteration 6): durable fix LANDED on main (schema v3: `children`
> gains `createdAt`/`createdAtTz`; `AppDatabase.watchChildren` orders by
> `createdAt, rowid`). P05's interim `rowid`-only query is retired as of this
> iteration — `FamilyRepositoryImpl.watchChildren` now delegates to the shared
> `AppDatabase.watchChildren` helper. This request can be closed once the UI
> gate confirms Maya-first on the merged build. The order-locking tests
> (`add_children_test.dart` child-order groups) cover the ruling and stay
> green unchanged (seed `createdAt` order == insertion order).
>
> Previous status (iteration 4): interim LANDED in P05 — `FamilyRepositoryImpl`
> ordered its own query by `rowid` (insertion proxy) inside RULES §1, so the
> screen and repository satisfy the ruling today. This request remains open
> as the DURABLE fix (createdAt column + core ordering) so every roster
> screen inherits it at once.

Need: the orchestrator's standing CHILD ORDER ruling says children are always
listed in the order they were added (Maya, then Leo), never alphabetically —
in every screen and repository. `AppDatabase.watchChildren`
(`app/lib/core/data/app_database.dart:291-296`) orders by `nickname`
(BINARY collation), so the P05 grid shows Leo left / Maya right, and any
mixed-case or accented nickname sorts worse. The `children` table has no
creation marker (no `createdAt`, unlike `quests`/`quest_completions`), and
the `FamilyChild` entity carries none either, so the feature cannot recover
the order locally: whatever it does with the nickname-ordered list is a
guess. Options: (a) add a `createdAt` column (default `currentDateAndTime`)
to `children` + order `watchChildren` by it, or (b) order `watchChildren` by
`rowid` as the creation proxy. Either way every roster screen inherits the
ruling-compliant order at once.

Files: `app/lib/core/data/app_database.dart` (schema and/or the
`watchChildren` ordering; drift migration if (a))

Blocks: **yes** — until it lands P05 consumes the repository order behind
`TODO(P05)` (`kid_card_grid.dart`) and the UI gate sees Leo|Maya against a
Maya|Leo mock. The existing order-locking test documents the current
(nickname) behaviour and flips with the shared fix.

---

# Shared request — P05 Add children nav bar — LANDED on main

> Status (iteration 2): landed — `nest_nav_bar.dart` now returns
> `SizedBox.shrink()` for a null/empty compact title and the bar is 60 px.
> P05 dropped its `title: ''` + `TODO(P05)` workaround and passes no title.

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
# — LANDED on main (P05 workaround removed in iteration 4)

> Status (iteration 2): the shared component is unchanged, so P05 wraps each
> chip in `IntrinsicWidth` (`add_child_form_card.dart`) — one row in
> production (real Nunito), ≤2 rows under the wider test fallback font, no
> overflow at 320/1.3. The component-level fix below is still open for every
> other chip-row screen.

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

# Shared request — P05 compact `NestNavBar` is 44 px, the spec says 52 px — LANDED on main

> Status (iteration 2): landed — compact nav is now 60 px (header −16 px on
> P03–P05). P05 consumes the component as-is.

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

---

# Shared request — P05 `router_push_test.dart` asserts the pre-build P05
# placeholder title (breaks the full `flutter test` run)

Need: `app/test/app/router_push_test.dart:104` passes
`showsFrom: 'P05 Add children'` — the title the **placeholder** view rendered
before this screen was built. P05 is now the real screen, so the assertion at
`router_push_test.dart:37` (`find.text(showsFrom)` is non-empty) fails and the
full `flutter test` run is red:

```
00:01 +3 -1: push/pop contract push between top-level onboarding routes,
pop returns [E]
The following TestFailure was thrown running a test:
Expected: true
  Actual: <false>
  ... router_push_test.dart line 37
```

Fix (test-side, one string): `showsFrom` should be a string the real
`/add-children` route renders — the h1, `Who’s in your nest?` (U+2019), i.e.
`'Who\u2019s in your nest?'`. `showsTo: 'P06 Pocket money setup'` is still
correct (`pocket_money_setup_view.dart:12`). Nothing in P05 needs to change:
the test drives `GoRouter.of(context).push('/pocket-money-setup')` on the
router itself, so it does not depend on how P05 navigates.

Evidence this is not a P05 regression: the string `'P05 Add children'` exists
nowhere in `app/lib` (only in that test); the file arrived from main in
`7eaa1f7` ("Shared requests batch 1 … + contract tests", the batch that
answered P05's push/pop investigation); and this worktree has never touched
`app/test/app/**` or `app/lib/app/**`.

Files: `app/test/app/router_push_test.dart`

Blocks: **yes for the repo gate** — `flutter test` is red on every branch where
P05 is built until this string is updated. It is outside RULES §1, so no screen
agent can fix it.

---

# Shared request — P05 residual band drift: on-device line boxes are taller
# than the CSS `line-height` (shared typography, app-wide)

Need: after the BUG-8 fix, `cmp_light_3` still drifts 4.87% and the QA note
records cumulative drift **inside** the form card (+4 at "Nickname", +8 at the
field, +13 at the chips, +20 at "Avatar colour"), i.e. every row renders a few
pixels taller than the design, compounding down the card. Measured in a widget
test on the current code, **every gap and every row height is exactly the HTML
value** (390 px, text scale 1.0):

| element | HTML | measured in test |
|---|---|---|
| `.h3` "Add a child" | 18/24 | 24.0 ✓ |
| `.field { margin-top: 10px }` | 10 | 10.0 ✓ |
| `.field { gap: 6px }` | 6 | 6.0 ✓ |
| `.field label` | 13/18 | 18.0 ✓ |
| `.field input { height: 52px }` | 52 | 52.0 ✓ |
| `.lbl { margin-top: 8px }` | 8 | 8.0 ✓ |
| `.chip-row { margin-top: 4px }` | 4 | 4.0 ✓ |
| `.lbl` (Avatar colour) | 8 | 8.0 ✓ |
| `.swatches { margin-top: 4px }` | 4 | 4.0 ✓ |
| `.form-note { margin-top: 6px }` | 6 | 6.0 ✓ |

Every gap is a literal `SizedBox`, so none of them can grow on device; the only
variable left is each row's height, which comes from `NestType` line boxes.
`NestType` documents "Every style carries `height = lineHeight / fontSize` so
line boxes match the CSS exactly" (`tokens/typography.dart:8`), which holds for
the test fallback font (1.0 em) but not for the runtime-fetched Nunito/Inter:
Flutter scales the font's ascent+descent, whose natural line height is > 1 em,
so each line box is taller by roughly `fontSize × height × (metrics − 1 em)` —
about +4 per row here, which reproduces the QA note's +4/+8/+13/+20 ladder
exactly and also the 8 px head offset ("Add a child" card top ≈ 407 vs the
design's 399).

Not fixable in P05 (RULES §1): the type scale is shared, the fonts are fetched
at runtime rather than bundled (`pubspec.yaml` has no font assets), and every
screen's vertical rhythm inherits the same few-pixels-per-row drift. Options
worth an owner decision: clamp the line height with `TextHeightBehavior` /
a strut so line boxes are font-independent, or bundle the two families with
metrics that match the CSS, or accept the drift as a known design delta.

Files: `app/lib/core/design_system/tokens/typography.dart` (and any
`TextHeightBehavior`/strut policy in the theme).

Blocks: no for P05 — every P05 gap and row height is spec-exact and is now
pinned by tests; the screen's residual drift is this shared effect.

---

# Shared request — P05 `NestChip`: the 44-px tap box is in the flow, the design
# measures a 32-px `.chip` (vertical twin of the landed width fix)

Need: the width fix that landed in `7eaa1f7` made chips shrink-wrap
horizontally, but the **vertical** half of the same trade-off is still there:
`nest_chip.dart:87-102` builds `ConstrainedBox(minWidth 44) → Padding(4.5) →
Ink(32)`, so the chip **occupies 44 px of vertical flow** while the design's
`.chip { height: 32px }` occupies 32. Everything below the chip row therefore
sits 12 px lower than the design — measured on P05 with `cmp_light_4`: chips row
centre ≈ +5 px (44/2 − 32/2 = 6) and "Avatar colour" row + helper text ≈ +12
(44 − 32).

Measured on the current code, everything else in that block is already exact, so
this is the whole remaining in-card delta:

| | design | app | Δ |
|---|---|---|---|
| `.chip` flow height | 32 | **44** (44-min tap box) | +12 |
| chip row → "Avatar colour" | 8 | 8 | 0 |
| "Avatar colour" → `.swatches` | 4 | 4 | 0 |
| `.sw` diameter / gaps | 44 / 8 | 44 / 8 | 0 |
| `.form-note { margin-top: 6px }` | 6 | 6 | 0 |

Options for the design-system owner: (a) keep the 44 minimum out of the flow —
e.g. a `Stack`/`SizedBox(44)` hit area around a 32-px pill, the same shape as
the landed width fix; (b) accept 44 and treat the P05 designs' `.chip` as 44 in
the flow. P05 cannot do either locally: the chip is shared and the design
explicitly wants a 44-min tap target (`SPACING_SPEC` §6), so shrinking the flow
height in `add_child_form_card.dart` would either clip the tap area or
re-implement the component.

The screen side is finished and pinned: `add_children_test.dart` asserts the
12-px delta explicitly ("the chip row height is the design value plus the 44-px
tap box"), so the day the shared fix lands that assertion goes to 0 and the
test fails until the expectation is flipped to 32.

Files: `app/lib/core/design_system/components/nest_chip.dart`

Blocks: no for P05 — every P05 gap, row height, swatch and gutter is
design-exact and pinned; the residual is this shared effect.

---

# Shared request — P05 `NestChip`'s overlaid 44-px target is unreachable inside
# the chip `Wrap` (P05-BUG-11, open — effective target is 32×pill)

Need: the shared batch-2 chip keeps the design's 32-px visual and widens the
hit test with `_ExpandedHitBox` (44×44). Measured on P05 today, the vertical
half of that widening never happens: the chips sit in a `Wrap` whose own box is
exactly the run height, so Flutter stops the hit test at the `Wrap` and the ±6
px overlay is dropped. Reachable vertical target = the pill itself, 32 px, for
every chip in a single-row layout (the production case).

Measured (390 px, text scale 1.0, first row of the age-chip block, chip pill
`34,527 → 104,559`):

| tap y | inside the 44-px target? | selects the chip? |
|---|---|---|
| 520–526 (above the pill) | yes | **no** — clipped by the Wrap |
| 527–559 (the pill) | yes | yes |
| 564 (below the pill) | yes | **no** — clipped |

So the screen's four age bands expose a 32-px-tall touch target where
`SPACING_SPEC` §3/§10.6 require ≥44 in parent mode — the exact regression the
shared fix was meant to avoid. Note the horizontal half works (the pill is
44-min wide by construction), and `_RenderExpandedHitBox` documents the
constraint itself ("ancestors that are themselves tight … cannot forward hits
outside their own box").

P05 cannot fix it locally: the tight ancestor is the `Wrap` inside
`add_child_form_card.dart`, and the only ways to widen it (padding the row,
`runSpacing` growth, a `Stack` with a taller box) put the 44 px back **in the
flow**, which is the 12-px drift that batch 2 just removed. A real fix has to
come from the component side — e.g. the chip's hit expander participating in a
parent that is allowed to overflow (`RenderBox.hitTest` on a box whose ancestors
forward), or a design-system row primitive that owns both the visual 32 px and
the 44-px target.

Files: `app/lib/core/design_system/components/nest_chip.dart` (+ whichever
shared row/capsule primitive ends up owning the tap area).

Blocks: no for the build — the screen builds and every gap is design-exact. It
does block an accessibility pass: parent-mode tap targets must be ≥44.

Proofs: `app/test/features/family/add_children_test.dart`, group *P05 chip tap
area* — "[P05-BUG-11] the vertical overlay is clipped by the chip Wrap", which
asserts today's reachable 32 px and flips to `isTrue` when the fix lands; the
bugs-stage proof of the same defect is in `p05_bugs_test.dart` with the id in
its name and carries `skip: true` (run it with
`flutter test --run-skipped test/features/family/p05_bugs_test.dart`).
