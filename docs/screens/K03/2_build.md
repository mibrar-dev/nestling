# K03 Kid home — build notes (Stage 2 INTEGRATE, iteration 11)

Two builders worked in parallel on `kid_home`. This stage is the integrator: it
confirmed the merged tree compiles and passes, and independently re-checked the
one claim in this iteration that contradicted a direct instruction.

**Gate: PASS** — `dart format .` clean · `flutter analyze` → *No issues found!* ·
`flutter test` → *`+1792: All tests passed!`*

Still **zero skipped tests** (fifth iteration running). Iteration 10 closed
**all six stages PASS** — the first fully-green iteration for K03 — so FIXES_10
is a two-item post-merge polish list, not a defect list.

**No product code changed this iteration.** The whole delivery is four new
regression pins in two test files.

## 1. The halves as delivered

### 2a — logic (`2a_build_logic.md`)

No code changes, correctly: FIXES_10's two items are a colour pin (views) and
a shared glow confirmation. 2a filed no contract change, re-read 2b's scope,
confirmed `grep skip:` clean and K03-BUG-1…15 all un-skipped and green, and
routed both items: the dark meadow to 2b, the pet glow to "nothing to change
locally".

### 2b — UI (`2b_build_ui.md`)

Four pins, no view change — "Do not change anything else" honoured:

- **FIXES_10 #1** — new group `K03 — lower meadow colour at the design rows` in
  `kid_home_geometry_test.dart` (4 tests: light+dark × rows 600/700). Each pumps
  the real app inside a `RepaintBoundary` at 390×844 @3× with the **bundled
  Inter/Nunito loaded**, then asserts the **painted pixel** at logical (10, y)
  against `_designMeadowAt(tokens, y)` — derived from the tokens plus the CSS
  62 % stop, so a token change moves the pin. The important part is a
  **direction guard**: the row must have moved *off* `kidHorizon` toward
  `kidMeadow` by >2/255 in green and blue. A flat band — or one graded over its
  own in-flow height (≈640 px), which is exactly what left dark navy for three
  iterations — fails that even when the band's top tone is untouched.
- **FIXES_10 #2** — two tests in `kid_home_view_test.dart` asserting dark paints
  exactly one `PetStageGlow`, 230×230, with `stops`/`radius`/`center` equal to
  the shared constants **and an outer stop of alpha 0** (the disc→fade
  assertion), light paints none.

File placement was deliberate and correct: the colour pins live in the geometry
file because they read absolute screen rows and `kid_home_view_test.dart` runs on
`flutter_test`'s default font — loading real fonts there would move ~120 passing
tests (its own header documents this).

## 2. Integration work: the mandate was wrong, and the builder was right to refuse it

FIXES_10 #1 instructed: *"the lower content area … must use `--kid-meadow` dark
`#1E4A3A` … The app is still flat navy."* 2b measured instead of complying,
concluded the mandate's premise was false, declined to repaint, and delivered the
pin instead. **I verified that independently** rather than taking it on trust.

Sampling the **gutter background** (logical x=10 — physical px 30; x=30 lands
*inside* the cards and reads the card surface, which is why a first pass at x=30
showed identical `(31,28,46)` on both sides and looked like a match for the
wrong reason), design dark vs the iteration-10 device capture:

| row | design | app (iter 10) | Δ |
|---|---|---|---|
| 535 | (37,52,88) | (38,53,89) | +1,+1,+1 |
| 560 | (36,53,85) | (35,53,84) | −1,0,−1 |
| **600** | **(35,56,81)** | **(34,56,80)** | −1,0,−1 |
| 650 | (34,60,76) | (33,58,75) | −1,−2,−1 |
| **700** | **(33,63,72)** | **(32,63,71)** | −1,0,−1 |
| 715 | (33,65,71) | (34,66,71) | +1,+1,0 |

Cross-checked at logical x=8 and x=380: worst case −2/255. So the dark meadow
**is already graded** — a monotone navy → teal run, within 2/255 of the design
across the whole visible band. There is no flat navy left, and the note repeats
an observation first filed four iterations ago.

The decisive part is *what the instructed fix would have cost*. `components.css:25`
is `linear-gradient(180deg, kid-sky-top 0%, kid-sky-bottom 62%, kid-horizon 62%,
kid-meadow 100%)`, so rows 600/700 sit at t ≈ 0.24 and t ≈ 0.55 of that run, and
the design's own RGB there is the token lerp:

- `lerp(#253359, #1E4A3A, 0.237) = (35,56,82)` ≈ design (35,56,81) ✅
- `lerp(#253359, #1E4A3A, 0.55) = (33,64,72)` ≈ design (33,63,72) ✅
- a **flat** `#1E4A3A = (30,74,58)` at row 600 would be **5 levels off in red
  and 18 in green** from the design itself.

So obeying the instruction would have moved the band *away* from the design and
then pinned the wrong value. `kidMeadow` is the run's **end** tone (row 844,
below the dock), not the tone of rows 600/700. 2b delivered the regression pin
the note actually asked for ("pin the colour at (10,600) and (10,700)") without
touching the pixels. I changed nothing and endorse the call.

## 3. FIXES_10 items

| # | Item | Status |
|---|---|---|
| 1 | Dark meadow `#1E4A3A`, pin (10,600)/(10,700) | **Measured already correct; pin delivered.** Premise ("flat navy") disproved by measurement; the repaint would have moved it 18 levels of green off the design. 4 painted-pixel pins added, with a direction guard so a flat band fails |
| 2 | Confirm the dark pet glow matches the design soft fade | **CONFIRMED, nothing local changed.** Shared `PetStageGlow` implements `.pet-stage::before` as a 230×230 `radial-gradient(circle 110px at 50% 45%, white@10%, transparent 70%)` off `--pet-glow` — a fade, not a disc; K03 renders it through shared `NestPetStage`. 2 tests pin the geometry **and the outer alpha 0** |

"Do not change anything else" was honoured: no view, domain, data or bloc file
changed.

## 4. Verification (in `app/`, this stage)

```
$ dart format .
Formatted 422 files (0 changed) in 1.23 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.2s)

$ flutter test test/features/kid_home
00:05 +184: All tests passed!

$ flutter test
00:27 +1792: All tests passed!
```

- Targeted re-runs of this iteration's new work:
  `kid_home_geometry_test.dart` → `+5: All tests passed!` (4 colour pins + the
  pet-slot pin); `kid_home_view_test.dart --plain-name "pet glow"` → `+2`.
- RULES §1 respected: only `app/test/features/kid_home/**` and
  `docs/screens/K03/**`. **This stage changed no file at all** — both
  investigations were read-only (PIL over existing PNGs).
- No simulator booted, installed on or captured (SIMULATORS rule: only the
  UI-check stage may, and only `BC440E48-B3A3-43BC-971B-0EF5DB621874`).
- No `google_fonts`/`GoogleFonts`, no `// ignore:` suppression, no `skip:`
  marker in the feature.
- `analysis_options.yaml` untouched; no test weakened to get green.

## 5. Handover

Nothing in K03's scope is outstanding. Carried:

- **SHARED_REQUEST #17** — `NestSpeechBubble` tail interior; shared, cosmetic.
- **SHARED_REQUEST #16(b)** — a `shadowPadding` parameter on the shared quest
  card; when it lands, delete `_kQuestCardShadowRoom` and put `NestSpacing.s3`
  straight back.
- **SHARED_REQUEST #6** — now with numbers from 2b: above the 62 % horizon the
  **sky** is also under-graded (dark row 500 design (43,52,112) vs app
  (36,44,99), up to −13 in blue; light row 520 (241,249,255) vs (228,241,254)).
  Same cause, one scope up: `KidScope`'s background is `[kidSkyTop →
  kidSkyBottom]` where the CSS holds `kidSkyBottom` flat from 0 % to 62 %. This
  is the main remaining source of band 1–4 heat in dark and cannot be fixed from
  K03. When it lands, delete `_MeadowPainter`, its `gradeSpan`, and the
  `TODO(K03)`.
- **Orchestrator ruling still wanted** — quest order: K03 keeps its documented
  alphabetical sort, or adopts the app-wide creation order the design's card 2
  actually agrees with (raised in iteration 10, unanswered).
- **Test gap (unchanged)** — no `hasAction(SemanticsAction.tap)` assertion pins
  any K03 control. Behaviour verified correct in iteration 9; the test stage
  should pin it.
- **Two new untracked PNGs**, `docs/screens/K03/ui/widgetrender_{light,dark}_11.png`
  (1170×2532). These are **widget renders, not device captures** — no OS status
  bar, no home-indicator inset, Pip on the SVG fallback. 2b documented the caveat
  in its note and they were produced by a scratch test that was then deleted.
  They are kept as offline evidence for the meadow pins, but the next UI stage
  must not read them as a stage-5 verdict — device shots come from
  `tools/screens/shot.sh`. Flagged here because they sit in the same folder as
  the real captures and only the `widgetrender_` prefix distinguishes them.

Next real step is the UI check on device: confirm the band table holds now that
the pet block is right in light (6.0% light / 5.6% dark at iteration 10) and
that the glow reads as a fade on the real simulator. The remaining band 1–4 heat
is `KidScope`'s two-stop sky gradient, which is SHARED_REQUEST #6 and will not be
fixed locally.

VERDICT: PASS