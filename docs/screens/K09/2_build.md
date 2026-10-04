# K09 · 2 BUILD (integrate, iteration 1)

Merge of the two parallel builders on `screen/K09`: `2a_build_logic.md` (the
non-UI layer) and `2b_build_ui.md` (the views/widgets). Both landed on the same
worktree, so my job was only to make the combined result compile and pass.

**No integration breakage was found.** Both halves already agreed on the
`KidJarState` surface 2b was written against, so there was nothing to reconcile
— no mismatched events, states, imports or renamed members, and no test failed
because of the merge. The only work I did was close the one coverage gap 2b
explicitly handed over.

## Summary of 2a (logic) — as landed

- `domain/entities/jar_snapshot.dart` (new): `JarSnapshot {childId, items,
  summary}` + `formatJarAmount(pence)` (`+£3.80` at/above £1, `+12p` below,
  U+2212 `−£2.00` safety branch).
- `domain/kid_jar_repository.dart`: added `Stream<JarSnapshot> watchJar()`.
- `data/kid_jar_repository_impl.dart`: `watchJar()` fans `watchAppState`
  (`activeChildId ?? 'maya'`) into one atomic `_jarFor(child)` snapshot, so a
  list can never pair new rows with a stale owed figure. Money-in filter
  `{weekly_base, quest_bonus, gift}` newest-first; row mapping per `1_plan.md`
  §b; `watchSummary` math byte-identical, now derived from the same emission.
- `presentation/bloc/`: `KidJarState` gained `childId, owedPence, goalTitle,
  goalSavedPence, goalTargetPence, nextPayoutDay` + `copyWithLoaded`;
  `KidJarLoadRequested` → `loading` then `emit.forEach(watchJar())` (a retry
  re-adds the event and cancels the prior subscription). No new events.
- Tests: `kid_jar_repository_test.dart` (13) + `kid_jar_bloc_test.dart` (7).

Note for the record: 2a deliberately did **not** use the plan's `asyncExpand` —
it copied `kid_shop`'s feature-local `_switchMap`, because `asyncExpand` pauses
the outer subscription until the inner one closes and Drift watch streams never
close, so an active-child switch after the first emission would stall forever.
That is a correct deviation, not a shortcut.

## Summary of 2b (UI) — as landed

- `views/my_jar_view.dart`: `KidScope` + transparent `Scaffold` +
  `NestStatusBar` + `.krow-top` (back / `NestLockButton`), the `.scroll` column,
  loading / failure / loaded states, `MyJarCopy`.
- `widgets/jar_illustration.dart`: the jar transcribed feature-private as a
  `CustomPainter` with a live fill level (so it cannot be a played-back asset).
- `widgets/jar_goal_card.dart` (`.k9-goal`), `widgets/jar_history_card.dart`
  (`.k9-list`, rows, disc tint cycle, glyph map, empty row),
  `widgets/jar_amounts.dart` (`jarPounds`, the two "£x.xx" figures).
- Geometry measured off `design/screens/light/K09-jar.png` rather than estimated
  from the plan (the plan's y values were wrong): title 107…141, jar 151…371
  (186×220, x 102…288), amount 377…421, "coming on…" 423…449, goal card
  465…618, "What went in" 634…660, history card 676…, row-1 disc 689…729,
  divider 739…741 inset 66.
- Tests: `my_jar_view_test.dart` (15) + `my_jar_view_geometry_test.dart` (3,
  isolated so the bundled Nunito metrics are real).

## FIXES items

### Done

1. **Empty-jar row had no test** (2b "Deviations", 3rd bullet). 2b could not
   cover it because a seeded demo family always has money-in rows and a
   childless one is redirected off `/my-jar` before the card can render — and
   reaching the state through the view would have meant a fake repository or a
   change to shared redirect behaviour. Fixed the small way instead:
   `JarHistoryCard` is pure (theme tokens in, no bloc, no repository), so the
   test pumps the widget directly under `NestTheme.light()` with no
   `configureDependencies`, no database and no seeded child. Added **2 tests** to
   `my_jar_view_test.dart`: the empty row shows `Nothing here yet` /
   `Finish a quest to fill your jar`, carries **no** ledger amount, and keeps the
   design's one-row box height (60 + 3 px borders = 66); and it claims **no**
   `SemanticsAction.tap`. Both use a shared const `_emptyJarHost()` helper, so
   the duplication is gone too. The route and redirect are untouched.
2. **8 `prefer_const_constructors` lints** that my own new tests introduced on
   first write. Fixed by hoisting the subtree into the const `_emptyJarHost()`
   rather than suppressing anything — `analysis_options` was not weakened.

### Left / confirmed, no change needed

3. **Quest-bonus glyph.** 2b flagged "if 2a carries the quest's own
   `questIconKey`, switch to `questIconFor`". Checked: 2a's repository maps
   `quest_bonus` to note / `Quest bonus` and does **not** carry an icon key, so
   the fallback applies — and the fallback *is* the design. `K09-jar.html:90`
   draws the bins glyph (`M6 3h12l-2 5H8Z` lid + `M8 8v10a4 4 0 0 0 8 0V8` body)
   and `:95` the gift box, which is exactly `jarEntryGlyph`'s mapping. Satisfies
   the ICONS rule ("each screen matches its own design's glyphs exactly"). No
   change.
4. **Test file names.** 2b asked for a rename decision on
   `my_jar_view_geometry_test.dart` / the folded copy parity test. Kept the
   names as built — they contain `view`, matching the `kid_jar` feature's
   existing convention and the geometry isolation note at the top of the file.
   Renaming would churn paths for no gain.
5. **Failure-state art** (`NestIcons.jar` at 96 px) — a stage-5 UI-check call,
   not an integration one. Left as 2b built it.
6. **DB wins over the design's numbers.** The seed's weekly base is 300p, so the
   list row reads `+£3.00` where the design's example row reads `+£3.80`, and
   the seed has nine money-in rows where the design shows three. Correct per
   DATA OVER MOCKS; the view test asserts the DB value and says why.

Nothing was redesigned, refactored or restyled. The only edit of any kind is the
two added tests.

## Verification

`dart format .` → `Formatted 614 files (0 changed) in 1.90 seconds.` (clean)

`flutter analyze` →

```
Analyzing app...
No issues found! (ran in 3.1s)
```

`flutter test --timeout 120s` (whole repo) →

```
01:44 +4091 ~4: All tests passed!
```

- `test/features/kid_jar` → **40/40 pass** (2a's 20 + 2b's 18 + my 2).
- `test/core/data/repositories_test.dart` → **22/22 pass**, so 2a's snapshot
  refactor did not disturb the shared summary or `moveToSavings`.
- The `~4` skips are pre-existing and belong to other features
  (`kid_home/k01_bugs_test.dart`, `kid_home/k03_bugs_test.dart`,
  `pocket_money/p12_bugs_test.dart` — all `skip: true` with a bug id). **No
  kid_jar test is skipped.**
- RULES §1 scope: every changed and added path is inside
  `app/lib/features/kid_jar/**`, `app/test/features/kid_jar/**` or
  `docs/screens/K09/**`. Nothing in `app/lib/core/**`, `app/lib/app/**`, another
  feature or `tools/screens/**` was touched — verified by filtering
  `git status --porcelain` against those prefixes (0 violations).
- No `SHARED_REQUEST.md` needed (plan §g: nothing outside the feature was
  required). No `ORCHESTRATOR_NOTES.md` exists for K09.
- **No simulator was booted, installed on, screenshotted or driven** (stage 5
  only, and only E7D5555E…). No `flutter clean`, no interactive `flutter run`, no
  image attached.

## For the UI check (stage 5)

Everything below is measured in logical px at 390×844 and is what stage 5 must
re-measure on the rendered app against
`design/screens/light/K09-jar.png` and `dark/K09-jar.png` (±2 px):

| element | design | app (asserted) |
|---|---|---|
| status bar | 0…47 | reserved only — OS draws the glyphs |
| back box | x 20…76, y 47…103 | 20, 47, 56×56 |
| lock box | x 314…370, y 47…103 | 314, 47, 56×56 |
| title line box | y 107…141 (28/34, centred) | 20, 107, 350×34 |
| jar | y 151…371, x 102…288 | 102, 151, 186×220 |
| hero amount | y 377…421 (40/44, centred) | top 377, h 44 |
| "coming on Saturday" | y 423…449 (18/26, centred) | top 423, h 26 |
| goal card | y 465…618, x 20…370 | 20, 465, 350×153 |
| progress bar | y 557…573, x 39…351 | 39, 557, 312×16 |
| "What went in" | y 634…660 | 20, 634, 350×26 |
| history card | y 676…, x 20…370 | left 20, top 676, width 350 |
| row 1 disc | y 689…729, x 37…77 | 37, 689, 40×40 |
| divider | y 739…741, x 89…367 (inset 66) | 89, 739, 278×2 |

Two rulings from 2b that stage 5 should confirm on the rendered app rather than
take on trust:

1. **Hero weight = Bold (w700), not Black (w900).** The plan says `kidHero`
   w900, but `<span class="kid-hero money">` has `.money { font-weight: 700 }`
   (`components.css:155`) *after* `.kid-hero` (`:37`) in the cascade. 2b measured
   the PNG's `0` stem at 4.7 px on a 40 px face = 0.12 em, versus ≈0.17 em for
   the Black weight used by `.k9-amts b`. The view therefore uses `kidHero` with
   `fontWeight.w700` + `FontFeature.tabularFigures()`.
2. **Jar fill measured against the interior.** The plan says
   `fraction × 104`; the SVG's fill rect (`y 104 h 104`) sits inside a 168-unit
   interior, i.e. 62% *of the interior*. The painter uses
   `fillFraction × 168`, which reproduces the design exactly at 62% and still
   reads correctly at any other level; coins are clipped to the level as well as
   to the glass.

Bottom edge is satisfied trivially: K09 has no bar of its own, so the shared
meadow runs to the physical edge and the scroll's tail padding is
`--s8 + --home-h` (32 + 34).

## LEFT FOR NEXT ITERATION

- Stage 5 UI check against both design PNGs: the ±2 px table above, light and
  dark, and a ruling on the two judgement calls (hero weight, jar fill).
- If the UI check prefers the jar illustration as the failure-state art, swap
  `NestIcons.jar` for `JarIllustration` in `_JarFailure` — one line.

VERDICT: PASS