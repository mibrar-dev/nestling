# K03 Kid home — UI check (Stage 5, iteration 11)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB only; 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_11.png" <udid> light demo kid maya` -> valid K03 light (14:16). Dark first attempt captured a foreign parent-light screen (same iter8 contamination: other loops active on this machine); after verifying, a retry captured valid K03 dark (14:19). Absolute OUT paths used. `cmp_dark_11.png` regenerated from the VALID capture only (the 69.13% figure is void).
- `python3 tools/screens/compare.py …` (both themes). Read all four images. Logical px (PNG/3).
- Verdict applied under the new UI VERDICT RULE: every element within ±2px of design (excluding OS glyphs + DB-driven content); measured y of screen title, first control, each card top reported below.

Results:
- light mean diff: 6.02% — bands: 0: 1.82% · 1: 3.11% · 2: 7.23% · 3: 11.39% · 4: 3.64% · 5: 6.57% · 6: 7.62% · 7: 6.73%
- dark mean diff: 5.20% — bands: 0: 1.82% · 1: 2.79% · 2: 5.75% · 3: 8.81% · 4: 3.31% · 5: 6.55% · 6: 7.15% · 7: 5.42%
- VERDICT-RULE measurements (design → app, light): screen title "Today's quests" top y489 → 489 ✓; first control lock bbox (315,56,368,109) → identical ✓; card-1 check top-left (299,575) → identical ✓; card-1 top 559-561 → 559-560 ✓; card-1 bottom 644-646 → 644-645 ✓; card-2 top 659-661 → 659-660 ✓ (gap 12 = spec ✓); hearts 443-452 → 443-451 ✓; progress borders + x24-365 ✓; dock top 719-721 → identical ✓; bottom edge dock-surface to y842 both ✓; gutters 20px ✓.
- Pet slot: nest max-width 194-198 centred ≈194.5-195 (target 198±2/195±1, stroke-threshold noise); Pip seated in bowl, rim overlap, no gap ✓; downstream chain exact. Widget-geometry pins (nest 278±2/364±2, Pip feet 301±3, hearts 448±2, card-1 559±2) GREEN in this iteration's test stage.
- Dark-meadow dispute (notes 10:52 claim "still flat navy"): CONTRADICTED by dense measurement — x=10 column y530-720 design vs app match within ≤3 total channel diff at EVERY row (e.g. y600 (36,57,81)/(35,57,82); y700 (33,64,72)/(33,64,72) identical); only the gradient-start row y520 differs (soft edge, invisible). The remaining band 5-6 heat is card CONTENT (Hoover/Done vs Reading/+10), not background. Full table in the shell history of this check. Respectfully: no meadow defect in these captures.
- Code: `NestBalancedText` present; no `GoogleFonts`; no `letterSpacing`; chips display-only; COPY U+0027 (standing verified pattern).

Accepted / overridden: A1 counts+fill (DATA+PERIODS); A2 card-2 content (alphabetical wins); A3 v2 art drawings (mandated — residual band-2/3 outlines, positions proven); A4 status clock; A5 band-7 PNG delta (override-required); A6 dark glow (SHARED branch pet_glow, explicitly not a finding); A7 title size (pre-declared); pet-seat art proportions (SHARED branch pet_stage_seat, do-not-touch, test-pinned).

Deviations (design → app + fix):
1. Speech-bubble tail white extends +10px (fails the ±2px rule): tail column x195 white y152-164 (13px) → y152-174 (23px). Bubble body identical (36 vs 37, same x/y/w); zero layout impact (downstream exact); invisible without overlay but rule-explicit. Fix: shared `NestSpeechBubble` tail geometry to HTML `.speech` tail — K03 cannot edit core (RULES §1), so this needs a SHARED_REQUEST (or the shared component's owner), same route as tile tints. No code touched in this stage.

Otherwise correct: every measured position above, header, bubble copy/body, hearts + caption, chips (full pills), progress, cards/checks per status, exact dock, alignment, no overflow/ellipsis, coins-only, all dark flips, a11y tap asserts green in test stage.

Next: SHARED_REQUEST (or shared owner) for the bubble tail; nothing further is locally actionable on this screen.

VERDICT: FAIL
