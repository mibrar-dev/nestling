# K03 Kid home — UI check (Stage 5, iteration 9)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB only; 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_9.png" <udid> light demo kid maya` -> valid K03 light (10:13). Same with `dark` -> valid K03 dark. Absolute OUT paths used. Both `stable frame saved`, no warnings; dark verified K03 (no repeat of the iter8 contamination).
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_9.png docs/screens/K03/ui/cmp_light_9.png` (and dark). Read all four images. Logical px (PNG/3), tolerance ±2px.
- Rules applied: all (PIP, STATUS BAR, DATA + PERIODS, BOTTOM EDGE, ALIGNMENT, CHILD ORDER n/a, COPY U+0027 re-verified, FONTS clean, no letterSpacing, chips display-only, SHAPES rects, BALANCED present, TRIAL n/a, new ACCESSIBILITY rule noted — tap actions are not visually verifiable; covered by the test stage), ORCHESTRATOR_NOTES (all incl. #65 explicit call + 09:52 QA triage), `1_plan.md`, SPACING_SPEC.

Results:
- light mean diff: 6.78% — bands: 0: 1.82% · 1: 2.97% · 2: 12.66% · 3: 15.31% · 4: 2.75% · 5: 5.27% · 6: 6.67% · 7: 6.73%
- dark mean diff: 6.08% — bands: 0: 1.82% · 1: 2.66% · 2: 11.21% · 3: 13.01% · 4: 2.86% · 5: 5.51% · 6: 6.14% · 7: 5.42%
- Band 6 collapsed (11.57→6.67 / 10.81→6.14): the quest-list gap is FIXED — card rows now IDENTICAL design vs app ([644,645,646, 659,660,661] both; gap 12-13 both = spec `.k3-quests` gap 12 ✓).
- Geometry chain (all #35 pins): hearts 443-452 EXACT both themes; progress borders EXACT; card-1 top/bottom EXACT (559-561 / 644-646); card-1 title rows identical; dock top 719-721 EXACT; nest max-width ≈196 centred ≈194.5 (target 198±2/195±1 ✓); card-2 peeking ✓; dark meadow pixel-identical at sampled rows; bottom edge dock-surface to y842 both themes ✓.
- SHAPES: coin pill, lock 56, bubble x/w/body (36 vs 37), progress x24-365, all 3 dock buttons within 1-2px, card extents, full chip pills — all match except the tail (see #2).

Accepted / overridden (NOT defects): A1 counts 4/4-of-6 + fill (DATA+PERIODS); A2 card-2 Hoover/Done vs Reading/+10 (alphabetical wins — residual band-6 heat); A3 v2 Pip/nest DRAWINGS vs v1 (mandated art — residual band-2/3 outlines, positions coincide); A4 status bar; A5 band-7 PNG delta (required by override); A6 dark pet glow (spec §7); A7 title size (pre-declared); A8 NestBalancedText present, no GoogleFonts, copy exact.

Deviations (design → app + fix):
1. Pip seat + nest proportions (SHARED component — do NOT fix locally, per 09:52 QA note; branch shared/pet_stage_seat owns it). Measured/visible: nest renders squashed (≈198×72 vs 198×86) and Pip stands ON the rim (feet visible on top) instead of sitting IN the bowl with ≈20px rim overlap and no gap. Positions/chain are exact (see above) — this is art geometry inside the shared `NestPetStage`, not screen layout. Fix: shared branch; screen loop must not adjust the pet block or the `NestPetStage` call unless that branch's report says so (notes #35.3: SHARED_REQUEST route if needed).
2. Speech-bubble tail white +10px (cosmetic, no layout impact): tail interior column x195 white y152-164 (13px) vs y152-174 (23px); body identical 36 vs 37, x/w identical, downstream exact. Fix: shared `NestSpeechBubble` tail geometry (flagged for the shared component; trivial).

Otherwise correct: header, bubble copy/body, hearts, chips, progress, cards/checks per status, exact dock + bottom edge, 20px gutters, no overflow/ellipsis, coins-only, all dark flips, a11y labels unchanged from prior passes (test stage owns tap-action asserts).

Next: #1 belongs to shared/pet_stage_seat (await that branch; no local pass should touch it). #2 is shared-component cosmetic. Nothing further is locally actionable on this screen's visual pass.

VERDICT: FAIL
