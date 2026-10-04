# Shared jar glyphs — K09 My jar history (REPORT)

Branch: `shared/jar_glyphs`. Read-only input:
`../K09/docs/screens/K09/5_ui.md` deviations 1 (row-1 coin-slot vs
`poundCoin`), 2 (row-2 lidded bin vs `questBins`), 4 (gift below the fold).

## Files changed

- `app/assets/icons/ic_jar_pocket_money.svg` (NEW) — exact
  `design/html-source/screens/K09-jar.html:85` coin-slot mark:
  `circle cx12/cy12/r8` + `M12 8v8` + `M9.5 9.5h5` + `M9.5 14.5h5`.
- `app/assets/icons/ic_quest_bins_kid.svg` (NEW) — exact
  `K09-jar.html:90` lidded bin: `M6 3h12l-2 5H8Z` +
  `M8 8v10a2 2 0 0 0 8 0V8`.
- `app/lib/core/design_system/assets/nestling_assets.dart` — added
  `NestlingIcons.jarPocketMoney` and `NestlingIcons.questBinsKid`
  constants with K09-exact doc comments; extended the `gift` doc to record
  that `ic_gift.svg` already draws the `K09-jar.html:95` paths (no
  `jarGift` file needed).
- `app/lib/core/design_system/components/nest_icon.dart` — added
  `NestIcons.jarPocketMoney` / `NestIcons.questBinsKid` forwarding
  constants (old `poundCoin`, `questBins`, `gift`, `bin`, `ribbon`
  untouched).
- `app/lib/core/design_system/components/quest_icons.dart` — kid
  `bins`/`bin` now resolves to `NestIcons.questBinsKid`; parent keeps
  `NestIcons.questBins`. Doc comment updated (kid set sources + single
  design-source list).
- `app/test/design_system/shared_jar_glyphs_test.dart` (NEW) — see below.
- `app/test/design_system/audience_glyphs_test.dart` — kid `bins`/`bin`
  expectations moved from `questBins` to `questBinsKid`; header comment
  notes the K09 kid bins.
- `app/test/features/kid_home/quest_detail_icon_audience_test.dart` —
  divergent set `{bed, dishwasher, book}` → `{bed, dishwasher, book,
  bins}` + `_divergentKidAssets['bins'] = questBinsKid`.
- `app/test/features/kid_home/quest_detail_view_icon_audience_test.dart` —
  `_divergentKeys` gains `bins`/`bin`; `bins` removed from the shared list.
- `app/test/features/kid_home/k04_bugs_test.dart` — K04-BUG-3 `q-bins`
  expectation `questBins` → `questBinsKid`; header comment updated.
- `app/test/features/kid_home/kid_home_repository_test.dart` —
  `questIconFor` split test: `bins`/`bin` moved to the divergent list,
  shared list keeps `hoover`/`plate`.

No `app/lib/features/**/presentation/**` screen code touched. No new
ignores; no lint weakening.

## What / why

1. **Pocket money (`NestIcons.jarPocketMoney`).** The design row-1 glyph
   (`K09-jar.html:85`) is a geometric coin-slot mark, NOT the `£`
   letterform in `ic_pound_coin.svg` (which draws `M14.6 7.5…` + two
   crossbars). New asset + constants; `poundCoin` is untouched for its
   other callers.
2. **Kid `bins`: the kid designs disagree — K09 wins.** The kid set's
   `bins` was the parent P09 handled case (`M3 7h13v9H3z…` + clasp in
   `ic_quest_bins.svg`). K09 draws a lidded bin (`M6 3h12l-2 5H8Z` +
   body). K03/K04 draw NO bins row at all (K03 shows Empty the
   dishwasher / Reading / Tidy your bedroom; K04 shows the bedroom hero),
   so the old kid fallback was never design-compared — it was just the
   parent glyph reused. Per the task, K09 (where bins appears most
   prominently) is now the kid canonical: `questIconFor('bins'/'bin',
   audience: kid)` → `questBinsKid`. Parent (`P08/P09/P10`) is byte
   untouched.
   **K03/K04 re-check:** neither HTML contains a bins row, so no
   design-compared pixel changes. DB-driven bins rows (Maya `q-bins`)
   now render the K09 lidded bin on kid screens — the intended kid
   canonical. Kid icon guards updated accordingly (above); K03/K04 suites
   pass.
3. **Gift (`NestIcons.gift`, NO new file).** `K09-jar.html:95` (`rect
   3/9/18/12` + `M3 13h18` + `M12 9v12` + bow loops `S9.5 3 7 3a2.2 2.2 0
   0 0 0 6` / `s2.5-6 5-6a2.2 2.2 0 0 1 0 6`) is exactly what
   `ic_gift.svg` draws (the two straight strokes are combined into one
   `m` subpath: `M3 13h18m-9-4v12m0-12…`). The shared set does NOT lack
   it, so no `jarGift` asset/constant was added — K09 keeps calling
   `NestIcons.gift`.

## Test names added (`shared_jar_glyphs_test.dart`)

- `Shared jar glyphs: constants and files asset constants point at the
  new files, old untouched`
- `Shared jar glyphs: constants and files new icon files exist on disk`
- `Shared jar glyphs: constants and files ic_jar_pocket_money.svg is the
  exact K09 coin-slot glyph`
- `Shared jar glyphs: constants and files ic_quest_bins_kid.svg is the
  exact K09 lidded-bin glyph`
- `Shared jar glyphs: constants and files gift already matches K09: no
  new jarGift file needed`
- `Shared jar glyphs: constants and files light/gift renders tinted`
  (matrix: light+dark × jarPocketMoney/questBinsKid/gift)
- `Shared jar glyphs: questIconFor bins split kid bins uses the K09
  lidded bin, parent keeps P09`
- `Shared jar glyphs: questIconFor bins split kid bins asset file
  exists`

Also updated (existing files): `audience_glyphs_test.dart` kid
`bins`/`bin` map + alias; `quest_detail_icon_audience_test.dart` table
invariant (now four divergent keys); `quest_detail_view_icon_audience_
test.dart` diverge/shared premise; `k04_bugs_test.dart` K04-BUG-3
`q-bins`; `kid_home_repository_test.dart` split test.

## Follow-up screens must do

- **K09 (required):** in `app/lib/features/kid_jar/presentation/widgets/
  jar_history_card.dart` `jarEntryGlyph`, map `quest_bonus` →
  `NestIcons.questBinsKid` (or `questIconFor('bins', audience:
  NestAudience.kid)`), the default pocket-money branch → `NestIcons.
  jarPocketMoney` (NOT `NestIcons.poundCoin`), and keep `gift` →
  `NestIcons.gift`. Same swap in `_JarEmptyRow` (`poundCoin` →
  `jarPocketMoney`). Then re-run `shot.sh` + `compare.py` light/dark;
  deviations 1–2 should close, deviation 4 (gift) should compare equal.
  (Feature edit left to the K09 agent — this branch does not touch
  feature code.)
- **K03/K04 (no code change):** if a UI check screenshots a DB-driven
  bins quest, expect the new K09 lidded bin on kid surfaces, not the
  parent handled case.
- **P08/P09/P10 (no action):** parent `bins` still resolves to the
  P09-exact `questBins`.

Checks: `dart format` clean, `flutter analyze` → `No issues found!`,
`flutter test --timeout 120s` → all pass (4161 + 4 skipped).

VERDICT: PASS
