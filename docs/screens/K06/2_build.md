# K06 · Pip's nest (`/pip`) — Stage 2 (INTEGRATE, iteration 4)

Job: make the 2a (logic) + 2b (UI) halves compile and pass together. Smallest
change only — no redesign.

**Outcome: `dart format .` clean · `flutter analyze` → No issues found ·
`flutter test` → 3844 pass / 4 skips / 0 fail.** This is the first iteration
where the merged tree needed **no integration fix at all** — one stale comment.
2b closed every open `FIXES_3` item, including the batch-7 component switch this
stage deferred in iteration 3 (§5.1), and K06 now has **zero `skip:` anywhere in
`test/features/pip/`** for the first time.

## 1. Summary of 2a (logic, iteration 4) — `2a_build_logic.md`

**Zero logic-layer edits, correctly so** — and the reasoning is the useful part:

- No state, event, repository or entity shape changed; the bloc contract is
  exactly as iteration 3 left it.
- `FIXES_3` #1–#5 are all in `presentation/views|widgets`, the parallel UI
  builder's layer, so touching them would have pre-empted the plan as well as
  the layer split.
- **#2 (`pipStageName` out of `domain/`) and #3 (cost constants onto the
  abstract repository)** were handed to 2b explicitly, because neither can land
  without coordinated edits in files 2a does not own: the helper's three call
  sites are views/widgets, and relocating the constants orphans six readers in
  `pip_nest_view.dart`. 2a's two test imports move with whatever path lands.
- **#6** is a `docs/DESIGN_SPEC.md` prose amend (shared, outside RULES §1) →
  filed as `SHARED_REQUEST.md` §8.
- **#8** is process, not a finding (untracked file + another stage's in-flight
  edit), correctly left alone.

## 2. Summary of 2b (UI, iteration 4) — `2b_build_ui.md`

Net **−585 / +349** across 17 files. Both local design-system forks deleted, and
the last open design-fidelity major closed from the screen side.

| # | Item | Result |
|---|---|---|
| 1 | **major** — batch-7 component switch (2 of 5 had landed) | care row → `NestKidButton(trailing:)`; pet block → `NestPetStage` with the documented K06 args; locked tile → `NestDashedBorder`. `pip_care_button.dart` + `pip_nest_slot.dart` deleted, `_DashedBorderPainter` deleted. |
| 2 | **minor** — `pipStageName()` sat in `domain/` | moved to `presentation/widgets/pip_look.dart`; removed from `domain/entities/pip_nest.dart`; call sites + test imports re-pointed. |
| 3 | **minor** — view imported the concrete `PipRepositoryImpl` for costs | `feedCostCoins` / `bathCostCoins` now on the abstract `PipRepository`; impl duplicates deleted; six view readers re-pointed. The view no longer names `data/` at all. |
| 4 | **minor** — `_BackButton` re-implemented `NestIconButton` | now `NestIconButton(icon: NestIcons.back, iconSize: 26, transparent bg/border)`, same pop/fallback and `k06-back` key. |
| 5 | **minor** — locked-tile price drew w800, design `.k6-item-p` is w900 | `PipCoinAmount` takes a `fontWeight`; tile passes w900, care row keeps w800 (design's `.k6-coin`). |
| 6 | **minor** — `DESIGN_SPEC.md` §5 K06 prose quotes superseded numbers | not actionable in a screen; filed as `SHARED_REQUEST.md` §8. |
| 16 | **minor** — the sun-hat proof was the only live skip | **closed**: `shared/k06_glyphs` (`5ff0c40`) landed the exact glyphs, the mapping moved, the proof is un-skipped and green. |

**Glyphs switched, all now design-exact** (verified below): wardrobe `sunhat →
wardrobeSunHat`; care `Feed → kidFeed`, `Play → kidPlay` (the old `feedBowl` /
`ball` were look-alikes); `Bath` already matched. Scarf/wellies were already on
the batch-7 constants; crown stays.

## 3. Integration check

- **No mismatched BLoC states/events/imports/renamed members.** 2a changed
  nothing; 2b's cross-layer edits are exactly the four files 2a handed it
  (`domain/pip_repository.dart`, `data/pip_repository_impl.dart`,
  `domain/entities/pip_nest.dart`, `pip_repository_test.dart`) plus the two
  forced test-file lines it disclosed (`k06_bugs_test.dart` — an import and a
  `find.byType(PipCareButton) → NestKidButton` that could not survive the fork
  deletion). Disclosed rather than hidden; I checked each is mechanical.
- **The forks are genuinely gone, not just unreferenced.**
  `grep -r "PipCareButton\|PipNestSlot\|_DashedBorderPainter" app/lib app/test`
  returns **only two comments** (a historical note in `k06_bugs_test.dart` and
  one in `pip_iter2_fixes_test.dart` describing the switch) — no code references,
  and both files are deleted from `lib/features/pip/presentation/widgets/`. This
  is the "never re-implement components" rule finally satisfied for this screen.
- **The 91 px care-row contract survived the component swap**, and I verified
  how rather than taking the note's word for it. 2b reports that switching to the
  shared `NestKidButton` made the *keyed widget box* 97 px (91 px of painted
  card + 6 px of internal `Padding(bottom: gap6)` for the pressed shadow), which
  reddened the iteration-2 proof. The design number did not drift: the proof now
  measures the **painted** `AnimatedContainer` rect — which is also what the
  owner's "UI check measures shapes, not only text" rule asks for — against 91,
  *and separately* asserts the widget box is exactly `91 + NestSpacing.gap6`, so
  the view's `SizedBox(s4 − gap6)` compensation cannot be silently re-tuned.
  Both assertions pass. Measuring the widget box would have reported a false
  6 px error.
- **ORCHESTRATOR_NOTES, all four items:** item 1 (locked-tile dashed border)
  closed in iteration 2 and now runs on the *shared* component; **item 2 closed
  — all four tiles plus both care glyphs are now the design's paths, and there is
  no skip left to hide behind**; item 3 closed upstream by batch 7; item 4
  informational.
- **New this iteration — ICONS rule (`questIconFor` / `rewardIconFor`,
  audience: kid).** Checked: K06 draws **no** quest or reward glyph, so the
  rule has nothing to bind here (`grep questIconFor|rewardIconFor|NestAudience`
  over `lib/features/pip` + `test/features/pip` → 0 hits). The screen's icons
  are its own design glyphs, which the rule's last clause covers directly.
- **Iteration 1–3 fixes all intact:** `kid_home_view_test.dart` still locates
  `/pip` by `pushedPath` (`grep 'K06 Pip nest'` repo-wide → nothing), and all
  seven `k06_bugs_test.dart` proofs run un-skipped.

### Glyph verification (I read the bytes; 2b's claim confirmed)

Normalising each asset's `<path d>` / `<circle>` data and comparing with the
design source's inline SVGs, taken from `K06-pip.html` lines 67–69 and 73–76:

```
ic_kid_feed.svg          == design Feed   M3 11h18a9 9 0 0 1-18 0Z / M12 11V5 / M9 5a3 3 0 0 1 6 0
ic_kid_play.svg          == design Play   circle(12,12,9) + the two seam arcs
ic_bubbles.svg           == design Bath   circles (9,15,5) (16,9.5,3.5) (16.5,17.5,2.5)
ic_wardrobe_scarf.svg    == design Scarf  M5 3h4v18H5z / M11 3h4v5… / M7 9v6
ic_wardrobe_sun_hat.svg  == design Sun hat M3 16h18l-1.6 2.4H4.6z / M7 16a5 5 0 0 1 10 0z
ic_wardrobe_wellies.svg  == design Wellies M8 3v8l-2 4.2… / M6 3h4M14 3h4
```

All six match byte-for-byte after whitespace/case normalisation. For the record,
the look-alikes the screen used before are genuinely different documents —
`ic_sun_hat.svg` is `m2.413.8h19.2…` **plus an extra `m7.411.6h9.2` brim
stroke**, `ic_ball.svg` is a different circle, `ic_feed_bowl.svg` adds two extra
circles — so this is a real fidelity fix, not a rename.

## 4. FIXES

### FIX 1 — one stale comment in `k06_bugs_test.dart` (done; the only edit)

2b listed this itself as its item 5 and left it for "whichever stage next owns
that file" — that is this stage, since I own integration. The `K06-BUG-6` proof's
comment still narrates the now-deleted `_DashedBorderPainter` as the live
implementation:

```
- // simulator). The screen-local `_DashedBorderPainter` is attached as
- // `CustomPaint.painter`, which paints BEHIND the child — …
+ // simulator). The bug was the screen-local `_DashedBorderPainter`,
+ // attached as `CustomPaint.painter` — which paints BEHIND the child, …
+ // Iteration 4 deleted that fork: the tile now uses the shared
+ // `NestDashedBorder`, so the proof asserts the shared component's own
+ // painted stroke instead.
```

Comment only. The proof itself was already green and correct (it scans pixels in
the tile's top band, which works identically on the shared component, in both
themes).

### FIXES — nothing else

No failing tests, no compile errors, no mismatched contract. Iteration 3's nine
price premises and its glyph switch all held through this iteration's much
larger refactor, which is the strongest evidence yet that they were re-based to
read the database rather than to match a number: **−533 lines of product code
and 220 K06 tests still pass without touching a single expectation.**

## 5. Left for the next stages (not mine to settle)

1. **`5_ui` must re-measure the care row by its PAINTED rect.** This is the one
   real trap in 2b's change and it would produce a false failure: the shared
   `NestKidButton` reserves 6 px below the card for its pressed shadow, so a
   widget-box measurement reads 97 where the design says 91. Measure the visible
   background rect (the `AnimatedContainer`), or the card's top + 91.
2. **`5_ui` should eyeball the three newly switched glyphs** in light and dark
   at their design sizes (Feed bowl, Play seamed ball, Sun hat). All three are
   token-coloured, so only the paths changed and no colour assertion moved.
3. **`DESIGN_SPEC.md` §5 K06 prose** (SHARED_REQUEST §8): the stage is 230×206
   and the wardrobe tiles are ~78.5 px, for whoever owns the spec.
4. **`kPipNotWearable`** ("That one is not something Pip can wear.") is still
   the only on-screen string the design does not define — unchanged since
   iteration 1, still awaiting orchestrator ratification.
5. **`NestProgress`'s kid highlight spans the whole track** rather than only the
   filled span (shared component).

## 6. Verification

### Skips — 4, **none in K06**

`grep 'skip:' app/test/features/pip` matches no declaration; the only hits are
words inside comments. K06 has had **zero parked tests for the first time in this
loop** (iteration 1: 4, iteration 2: 4, iteration 3: 1, iteration 4: **0**).

The 4 remaining repo skips are all other screens': `k01_bugs_test.dart`
(K01-BUG-7), `k03_bugs_test.dart` ×2 (K03-BUG-16/17, in K03's own loop),
`p12_bugs_test.dart` (P12-BUG-04).

### Standing rules checked

- **PIP** — the nest slot and the growth preview still render the active child's
  own `PipAvatar` (Maya mochi · sunny · stage 3; Leo bolt · sky · stage 2) from
  the DB profile; `grep pip_stage_ lib/features/pip` → 0.
- **DATA OVER MOCKS** — no price literal anywhere in the view or the tests after
  iteration 3's re-basing; costs now come from the abstract repository, which is
  where a seed change will be visible.
- **CHILD ORDER** — the wardrobe renders Scarf, Sun hat, Wellies, Crown for every
  child; the repository's `watchNest` orders explicitly, never alphabetically.
- **FONTS / CLOCK / IDS** — `google_fonts|GoogleFonts` → 0 in
  `lib/features/pip` + `test/features/pip`; `DateTime.now()` → 0 in
  `lib/features/pip`; `newId(` → 0 (this screen writes no new rows).
- **TOKEN RULE** — the component switch moved three forked widgets onto shared
  components whose colours are tokens; no colour or size literal was introduced
  (the two new `NestPetStage` geometry args are the design's own 206 / 81).
- **BOTTOM EDGE / ALIGNMENT / COPY / ACCESSIBILITY / BALANCED HEADINGS /
  CHIP ROWS / LETTER SPACING** — untouched; the 9 `SemanticsAction.tap`
  contracts still hold (no control was re-wrapped; the back control is now
  `NestIconButton`, and its proof passes).
- **SIMULATORS** — none booted, installed on, screenshot or driven. No
  `flutter clean`, no `analysis_options` change, no `google_fonts` added, no
  image attached (design PNGs read locally, crops only).

### Verification tails

```
$ dart format .
Formatted 591 files (0 changed) in 1.94 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.0s)

$ flutter test --timeout 120s
01:33 +3844 ~4: All tests passed!

$ flutter test --timeout 120s test/features/pip
00:06 +220: All tests passed!            (0 skips)

$ flutter test --timeout 120s test/features/pip/k06_bugs_test.dart --run-skipped
00:02 +25: All tests passed!             (all seven bug proofs)
```

The last two runs are the evidence for this iteration's two claims: the whole
K06 feature is green with nothing parked, and every stage-6 bug finding still
holds against the refactored shared components.

## 7. Files changed by this stage

- `app/test/features/pip/k06_bugs_test.dart` — FIX 1, one comment block.
- `docs/screens/K06/2_build.md` (this file, supersedes iteration 3's).

No `app/lib/**` file was touched: the merged logic + UI compiled and passed as
the two builders left it, which is the outcome this stage exists to produce.

VERDICT: PASS
