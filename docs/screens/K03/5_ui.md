# K03 Kid home — UI check (Stage 5, iteration 8)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB only, per SIMULATORS rule; 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_8.png" <udid> light demo kid maya` -> valid K03 light. Same with `dark` -> see incident note.
- INCIDENT (environmental, not a screen finding): the first dark capture returned the wrong screen (P10 Quest-library Ideas, parent light — another loop's app on this supposedly exclusive simulator; `ps` confirmed P10/P06 loops running concurrently), and a retry captured the home screen (app not launched). After verifying the simulator idle via a raw screenshot, a third dark run captured valid K03 dark (09:40). `cmp_dark_8.png` was regenerated from the VALID capture only. A stray `app_dark_8b.png` (home screen) was deleted.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_8.png docs/screens/K03/ui/cmp_light_8.png` (and dark, valid capture). Read all four images. Logical px (PNG/3), tolerance ±2px.
- Rules applied: all (PIP, STATUS BAR, DATA + PERIODS, BOTTOM EDGE, ALIGNMENT, CHILD ORDER n/a, COPY re-verified U+0027, FONTS clean, no letterSpacing, chips display-only, SHAPES rects, BALANCED present in code, TRIAL n/a), ORCHESTRATOR_NOTES (all incl. #65 explicit pet call + #35 geometry targets), `1_plan.md`, SPACING_SPEC.

Results:
- light mean diff: 7.39% — bands: 0: 1.87% · 1: 2.97% · 2: 12.66% · 3: 15.31% · 4: 2.75% · 5: 5.27% · 6: 11.57% · 7: 6.73%
- dark mean diff: 6.67% — bands: 0: 1.88% · 1: 2.66% · 2: 11.21% · 3: 13.01% · 4: 2.86% · 5: 5.51% · 6: 10.81% · 7: 5.42%
- (The 69.03% dark figure from the contaminated capture is void and superseded.)
- #35 geometry targets: ALL MET or better — hearts 443-452 EXACT both themes (target 448±2 ✓); progress borders 527,528+541,542 EXACT (target 527-542 ✓); card-1 top 559-561 EXACT, bottom 644-646 EXACT (target 559±2 ✓); card-1 title text rows identical (560-646 sparse set both); dock top 719-721 EXACT; nest max width ≈196 centred ≈194.5 (target 198±2 / 195±1 ✓); Pip seated in bowl, rim overlap, no gap ✓; card-2 peeking above dock ✓.
- Dark meadow FIXED: x=10 rows y600/650/700 pixel-identical (35,57,81),(34,60,77),(33,64,72). Bottom edge dock-surface to y842 both themes ✓ (white light, navy dark — BOTTOM EDGE pass, no strip).
- SHAPES: coin pill, lock 56, bubble x/w, progress x24-365, all 3 dock buttons within 1-2px; card-1 extents identical; chip pills full/padded (no collapse); checks leaf both.
- New since iter7: dishwasher tile now sky-tint (matches HTML; SHARED_REQUEST #1 evidently implemented on main — hoover has no K03 HTML sample so no claim there).

Accepted / overridden (NOT defects): A1 counts 4/4-of-6 + fill (DATA+PERIODS); A2 card-2 Hoover/Done vs Reading/+10 sample (alphabetical wins — the remaining band-6 heat); A3 Pip/nest ART (mandated v2 vs v1 drawings — the remaining band-2/3 heat is outlines, positions coincide); A4 status bar; A5 band-7 PNG delta (required by override); A6 dark pet glow (spec §7, PNG omits); A7 title size (pre-declared).

Deviations (design → app + fix):
1. Quest-list gap +6px (minor, ALIGNMENT). Card-1 bottom 644-646 both; card-2 top 659-661 vs 665-667: gap 12-13 (spec `.k3-quests` gap 12 ✓ design) vs 18-19. Eats 6px of card-2's peek. Fix: quest-list separator to exactly 12 (likely a base-16 separator used between cards instead of the quests 12). No code touched here.
2. Speech-bubble tail white extends +10px lower (cosmetic, no layout impact — body h36 vs 37 identical, x/w identical, downstream exact). Tail triangle geometry vs HTML. Fix with #1 if trivial, else accept.

Otherwise correct: everything in the target audit, header, bubble copy/tail position, hearts, chips, progress, cards/checks per status, exact dock, 20px gutters, no overflow/ellipsis, coins-only, all dark flips, NestBalancedText present, no GoogleFonts, copy exact.

Iteration-9 fix (local, trivial): #1 separator 12; #2 tail geometry. Shared/pre-declared: none outstanding for the visual pass.

VERDICT: FAIL
