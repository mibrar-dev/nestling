# K03 Kid home — Stage 2b UI chunk (iteration 11)

Scope: `app/lib/features/kid_home/presentation/views/**`,
`presentation/widgets/**` and the view/widget tests in
`app/test/features/kid_home/` (`kid_home_view_test.dart`,
`kid_home_geometry_test.dart`). **No domain/data/bloc/route/DI file touched** —
`2a_build_logic.md` re-read before finishing (now written for iteration 11):
still **no CONTRACT CHANGES**, and its two FIXES_10 dispositions both point the
dark meadow at me and the pet glow at "nothing to change locally". No simulator
was booted, installed on, driven or screenshot (SIMULATORS rule — stage 5 only).

## FIXES_10 item 1 — dark meadow behind the lower content: measured CORRECT, now pinned

The mandate was: the lower content area behind the progress bar and the quest
cards must paint `--kid-meadow` dark `#1E4A3A`, pinned at (10, 600) and
(10, 700) in dark, because "the app is still flat navy".

**I measured both PNGs rather than taking that on faith, and the shipped app is
already graded — there is no flat navy left in dark.** Pixel-exact comparison of
`design/screens/dark/K03-kid-home.png` against the iteration-10 device capture
`docs/screens/K03/ui/app_dark_10.png` (÷3 to logical px, gutter column x=10,
and the same at x=8/30/360/380):

| row | design | device (iter 10) | delta |
|---|---|---|---|
| 535 | 37,53,88 | 38,53,89 | +1,+0,+1 |
| 560 | 36,53,85 | 35,53,84 | −1,0,−1 |
| 600 | **35,56,81** | **34,56,80** | −1,0,−1 |
| 650 | 34,60,76 | 33,58,75 | −1,−2,−1 |
| 700 | **33,63,72** | **32,63,71** | −1,0,−1 |
| 715 | 33,65,70 | 33,65,70 | 0,0,0 |

Every row from the 62 % horizon stop down to the dock is within 2/255 of the
design, and it is on a monotone navy → teal-green run. Light matches the same
way ((10,600) 223,243,214 vs 223,242,213). So `_MeadowPainter`'s compressed
`gradeSpan = NestDevice.height × (1 - 0.62)` was already doing the job; the
orchestrator's note repeats an observation first filed four iterations ago.

**I did not repaint the band to a literal `#1E4A3A`, because the design PNG says
that would be wrong.** `components.css` l.25 is
`linear-gradient(180deg, kid-sky-top 0%, kid-sky-bottom 62%, kid-horizon 62%,
kid-meadow 100%)`: rows 600 and 700 sit at t ≈ 0.24 and t ≈ 0.55 of the
62 %→100 % run, and the design's own RGB there is exactly the token lerp —
`Color.lerp(#253359, #1E4A3A, 0.237) = (35,56,82)` ≈ design (35,56,81), and
`Color.lerp(…, 0.55) = (33,64,72)` ≈ design (33,63,72). A flat `#1E4A3A` at row
600 would sit 5 levels off in red and 18 in green **from the design itself**.
`kidMeadow` is the run's *end* tone (row 844, below the dock), not the tone of
rows 600/700. Data/asset beats note: the design PNG is the ground truth here,
exactly as it is for the other design numbers.

**What I did deliver: the pin the note asked for, so this can never silently
regress** — `kid_home_geometry_test.dart`, new group
`K03 — lower meadow colour at the design rows (FIXES_10 #1)`, 4 tests
(light+dark × rows 600 and 700). Each pumps the real app inside a
`RepaintBoundary` at 390×844 @3× with the **bundled Inter/Nunito loaded** (so
the rows are the design's rows, not this file's default-font rows) and asserts
the PAINTED pixel at logical (10, y):

- every channel within ±2/255 of `_designMeadowAt(tokens, y)` — derived from
  `kidHorizon`/`kidMeadow` + the CSS 62 % stop + `NestDevice.height`, so a token
  change moves the pin; the design's measured RGB is in each failure reason;
- alpha 255;
- and a direction guard that is the actual regression: the row must have moved
  **off** `kidHorizon` toward `kidMeadow` by >2/255 in green and blue. A flat
  band — or one graded over its own in-flow height (≈640 px), which is what
  left dark navy three iterations running — fails this even if the band's top
  tone is untouched. The guard is direction-aware so it holds in both themes
  (rises in dark, falls in light).

Measured by the pins (tightened to 0 tolerance once to read the raw bytes):
dark (10,600) `rgb(35,56,81)`, dark (10,700) `rgb(33,63,72)` — **pixel-identical
to the design PNG**; light (10,600) `rgb(223,243,214)`, light (10,700)
`rgb(210,238,198)` — identical too. Restored to ±2 for Skia/8-bit rounding.

Note on file placement: the pin lives in the geometry file, not the view file,
because it reads ABSOLUTE screen rows and `kid_home_view_test.dart` runs on
`flutter_test`'s default font (that file's header already documents that real
fonts would move ~120 passing tests). A one-line pointer was left in the view
file's meadow group next to the gradient assertions.

## FIXES_10 item 2 — dark pet glow: confirmed, nothing local

`shared/pet_glow` is on this branch (`19a9d38`, and `66e8a7f` is an ancestor of
HEAD), and `PetStageGlow` (`core/design_system/motion/pip_rive.dart:421`)
implements the design's `.pet-stage::before` as a 230×230 box,
`radial-gradient(circle 110px at 50% 45%, white@10%, transparent 70%)` off the
`--pet-glow` token (`#1AFFFFFF` in dark, absent in light) — a fade, not a disc.
K03 renders it through the shared `NestPetStage`; no local fork exists.

To keep "the screen uses the shared fade" from regressing into a local disc I
added two tests in `kid_home_view_test.dart` (group
`K03 dark pet glow is the shared --pet-glow fade`): dark paints exactly one
`PetStageGlow.glowKey`, 230×230, with `stops`/`radius`/`center` equal to the
shared constants and an **outer stop of alpha 0** (that is the disc→fade
assertion), plus `--pet-glow == #1AFFFFFF`; light paints none.
`flutter test test/core/design_system/nest_pet_stage_test.dart` → **+16, all
passed** (includes "pet glow matches --pet-glow (soft fade, not a solid disc)"
for the explicit, Rive and legacy paths).

## Review / ORCHESTRATOR items re-checked (no code change needed)

- **Nothing else was open in my layer.** No view/widget file needed an edit this
  iteration: FIXES_10's only two items are above, `2a` filed no contract change,
  and iteration 10's device check (`5_ui.md`) had every other element exact
  (header, bubble body, hearts, chip, progress, card 1 top/bottom 559–561 /
  644–646, dock top 719–721, 20 px gutters, dark flips). FIXES_10 says "Do not
  change anything else", and I did not.
- **PIP** — unchanged: the child's own `PipAvatar` (Maya: Mochi · sunny ·
  stage 3) in the pet stage, failure, empty and no-child states; no
  `pip_stage_*.svg`.
- **STATUS BAR** — `NestStatusBar()` reserves height only; untouched.
- **DATA OVER MOCKS / PERIODS / CHILD ORDER** — no design number hard-coded in
  the view; counts come from state.
- **BOTTOM EDGE (owner)** — untouched: the dock's `Container(color:
  tokens.surface)` wraps its `SafeArea(top: false)`, so the bar's own surface
  runs from y 720 to the physical edge in both themes, no meadow/sky strip. (The
  design PNGs do show green below the dock; that is the accepted override A5, not
  a defect, and my pins deliberately stop at row 700 — above the dock.)
- **ALIGNMENT (owner)** — 20 px gutters and the shared nest axis unchanged.
- **COPY / FONTS / LETTER SPACING / CHIP ROWS / BALANCED HEADINGS / SHAPES /
  TRIAL / ACCESSIBILITY ACTIONS** — no copy, font, spacing or chip touched; the
  new pins measure painted background pixels, not text.

## One measurement worth passing to the orchestrator (not mine to fix)

Above the 62 % horizon the app's **sky** is still under-graded against the
design, and it grows with the row: at x=10, row 500 is design (43,52,112) vs app
(36,44,99) in dark — up to −13 in blue; light row 520 is (241,249,255) vs
(228,241,254), −13 in red. Cause is the same missing 3rd/4th gradient stop as
the meadow band, one scope up: `KidScope`'s background is only
`[kidSkyTop → kidSkyBottom]` across the whole height
(`core/design_system/theme/kid_scope.dart`), while the CSS holds `kidSkyBottom`
flat from 0 % to 62 %. That is core, it is already filed as **SHARED_REQUEST
#6**, and this stage may not edit `core/` — so it stays open there. It is the
main remaining source of band 1–4 heat in the dark comparison and it will not be
fixed locally.

## Verification (in `app/`, this worktree)

- `dart format lib/features/kid_home/presentation test/features/kid_home` →
  formatted, 0 pending.
- `flutter analyze lib/features/kid_home test/features/kid_home` →
  **No issues found!**
- `flutter test test/features/kid_home/kid_home_geometry_test.dart` → **+5**,
  all passed (the 4 new colour pins + the pre-existing pet-slot pin).
- `flutter test test/features/kid_home/` → **+184, all passed** (whole feature
  folder, so the change breaks neither the bloc nor the K03-BUG proofs; the
  whole-app suite is the integrator's).
- `flutter test test/core/design_system/nest_pet_stage_test.dart` → **+16**, all
  passed (FIXES_10 item 2 evidence).
- `grep skip:` over `test/features/kid_home/` → clean (FIXES_10 references no
  skipped test; nothing to un-skip). `grep google_fonts|GoogleFonts` → only the
  comment in `k03_bugs_test.dart` saying there are none. No
  `analysis_options.yaml` change; no `flutter clean`.

**No simulator** was used. As an offline cross-check I rendered the pumped
screen in a throwaway widget test at real fonts and wrote
`docs/screens/K03/ui/widgetrender_{light,dark}_11.png` (1170×2532). They confirm
the four meadow pins byte-for-byte, but they are **widget renders, not device
captures** (no OS status bar / home-indicator inset, Pip on the SVG fallback),
so they must NOT be used as a stage-5 UI verdict — device shots come from
`tools/screens/shot.sh`. The scratch test file that produced them was deleted;
nothing scratch is left in the tree.

## LEFT FOR NEXT ITERATION

- SHARED_REQUEST **#17** (speech-bubble tail interior) and **#16(b)** (card
  shadow padding, `_kQuestCardShadowRoom`) — shared-component, nothing local
  remains; the revert instructions are still in the view comments.
- SHARED_REQUEST **#6** — now with numbers in this file: the sky above the
  horizon is up to 13/255 under-graded because `KidScope` has two gradient
  stops where the CSS has four. When it lands, delete the feature-local
  `_MeadowPainter` and its `gradeSpan`, and drop the `TODO(K03)` in the view.
- A fresh device UI capture (stage 5) to re-confirm the band and confirm the
  glow reads as a fade on the real simulator; expected band 5/6 heat to be
  unchanged from iteration 10 (it is already at the design's colour).

VERDICT: PASS