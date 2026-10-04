# K09 · 2b BUILD (UI chunk, iteration 1)

Scope: `app/lib/features/kid_jar/presentation/views/**` and
`presentation/widgets/**` for K09, plus the view/geometry tests in
`app/test/features/kid_jar/` (files whose names contain `view`). Domain, data
and bloc untouched — the logic builder's `2a_build_logic.md` (no CONTRACT
CHANGES) landed first and its `KidJarState` fields are used exactly as planned.

## Files changed

- `presentation/views/my_jar_view.dart` — chrome (`KidScope` + transparent
  `Scaffold` + `NestStatusBar` + `.krow-top` back/lock), the `.scroll` column,
  loading / failure / loaded states, `MyJarCopy`.
- `presentation/widgets/jar_illustration.dart` — `JarIllustration`, the jar
  transcribed feature-private as a `CustomPainter` (live fill level, so it
  cannot be a played-back asset).
- `presentation/widgets/jar_goal_card.dart` — `.k9-goal`.
- `presentation/widgets/jar_history_card.dart` — `.k9-list`, its rows, the
  disc tint cycle, the entry-type glyph map, the empty row.
- `presentation/widgets/jar_amounts.dart` — `jarPounds` (the two "£x.xx"
  figures). The history row's own amount string is the domain's
  `formatJarAmount`, which 2a landed — not duplicated here.
- `test/features/kid_jar/my_jar_view_test.dart` (15 tests) and
  `my_jar_view_geometry_test.dart` (3 tests).

## Geometry — measured, not estimated

`1_plan.md` §(a) carries estimated y values (title 140–174, jar 192–412,
amount 418–462). Those do not match the rendered design, so every position was
measured off `design/screens/light/K09-jar.png` with a script over the pixels
and cross-checked against the CSS box model of `K09-jar.html`. The design is
the truth for a UI check:

```
status bar      0…47      back / lock boxes   x 20…76 & 314…370, y 47…103
scroll viewport 107…810   title line box     y 107…141  (28/34, centred)
jar                    151…371  (186×220, x 102…288)
hero amount             377…421  (40/44, centred)
"coming on Saturday"    423…449  (18/26, centred)
goal card               465…618  (350 × 153, x 20…370)
  progress bar          557…573  (312 × 16, x 39…351)
"What went in"          634…660  (20/26)
history card            676…     (350 wide; 3 rows = 186 in the design,
                                 the seed's nine rows = 562)
  row 1 disc            689…729  (40, x 37…77)
  divider               y 739…741, x 89…367 (inset 66 from the row edge)
```

Two places where the plan and the HTML disagree with the rendered pixels, both
resolved to the pixels:

1. **Hero weight.** `1_plan.md` says the hero amount is `kidHero` w900, but
   `<span class="kid-hero money">` has `.money { font-weight: 700 }`
   (`components.css:155`) later in the cascade than `.kid-hero` (`:37`), so the
   design renders **Bold**. Measured: the `0` stem is 4.7 px at 40 px = 0.12 em
   (Black would be ≈0.17 em, cf. `.k9-amts b` at 0.176 em). The view therefore
   uses `kidHero` with `fontWeight.w700` + `FontFeature.tabularFigures()`.
2. **Jar fill.** The plan describes the fill as `fraction × 104`; the SVG's fill
   rect (`y 104 h 104`) sits inside a 168-unit interior, i.e. 62% of the
   interior. The painter measures the level against the interior
   (`fillFraction × 168`), which reproduces the design exactly at 62% and reads
   correctly at any other level. Coins are clipped to the level as well as to
   the glass, so a lower jar never shows coins floating in empty air.

## Owner rules applied

- **KID BACKGROUND** — `KidScope` only; no local hills, no local sky.
- **BOTTOM EDGE** — K09 has no bar, so the meadow runs to the physical edge;
  `SafeArea(top: false)` supplies the bottom inset the design's
  `.home-indicator` sibling would, and the scroll's tail padding is
  `--s8 + --home-h` (32 + 34) so the last line clears the home indicator
  (K08 precedent).
- **ALIGNMENT** — 20 px gutters everywhere; both cards, the back and lock
  boxes and the heading share the same edges (asserted at 320/390/430).
- **BALANCED HEADINGS** — `.kid-title`/`.kid-hero` carry `text-wrap: balance`,
  so the title and the "What went in" heading use `NestBalancedText`
  (single line → identical rect, plain `Text` inside).
- **COPY** — every string typed from `K09-jar.html`; no invented punctuation.
- **LETTER SPACING** — none added; `NestType` styles default to 0.
- **ACCESSIBILITY ACTIONS** — back and lock both come from
  `NestIconButton` / `NestLockButton`, which pass `onTap` on their `Semantics`
  node (no `excludeSemantics` wrapper anywhere on this screen); the history
  card and its rows claim **no** tap action, and the tests assert both.
- **CLOCK / IDS / TRIAL** — no `DateTime.now()`, no ids, no
  `subscription_status` in the UI layer. No `google_fonts`.
- **ICONS** — kid glyphs: `poundCoin` (pocket money), `questBins` (quest
  bonus), `gift`, at the design's 22 px inside the 40 px disc.

## Verification

- `dart format` clean; `flutter analyze lib/features/kid_jar
  test/features/kid_jar` → **No issues found**.
- `flutter test --timeout 120s test/features/kid_jar` → **38/38 pass** (my 18
  plus 2a's 20). Geometry asserts every box above within ±2 (UI VERDICT RULE)
  with the bundled Nunito loaded (K08/K03 isolation pattern); the copy test
  covers the design's strings, the jar/progress/amount labels, both navigation
  destinations, `performAction` on the lock, dark mode and the 320/390/430 ×
  1.0/1.3 matrix.
- No simulator booted, no whole-app test run, no `flutter clean`.

## Deviations / judgement calls for the next stage to confirm

- The plan's `my_jar_geometry_test.dart` / `my_jar_copy_parity_test.dart` are
  named `my_jar_view_geometry_test.dart` and folded into
  `my_jar_view_test.dart`, so every file I added contains `view` (the
  ownership rule for this chunk). Rename if the integrator prefers the plan's
  names.
- Quest-bonus rows use `NestIcons.questBins` from the entry type alone. If 2a's
  repository starts carrying the quest's own `questIconKey`, switch the glyph to
  `questIconFor(key, audience: NestAudience.kid)` (`jarEntryGlyph` is the single
  place to change).
- The empty-jar row (`Nothing here yet` / `Finish a quest to fill your jar`) is
  implemented in `JarHistoryCard` but not covered by a test: a childless family
  redirects away from `/my-jar` before the card can render, so the state needs
  either a fake repository (2a owns the fakes) or a widget-level test.
- The failure state uses `NestIcons.jar` (a token icon) at 96 px as its art.
  The design has no error frame, so this is the K08-shaped choice; if the UI
  check wants the jar illustration there instead, swap it for `JarIllustration`.

## LEFT FOR NEXT ITERATION

- UI check (stage 5) against both design PNGs: the `±2 px` band table for the
  measured boxes above, light and dark.
- Confirm the two rulings above (hero weight, jar fill) against the rendered
  app before signing off the screen.
- A widget-level test for the empty jar row if the redirect is changed to keep
  `/my-jar` reachable.

VERDICT: PASS