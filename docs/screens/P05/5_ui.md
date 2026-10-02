# P05 · Add children — UI check (STAGE 5, iteration 2)

Route `/add-children`, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844).
Shots use `SEED=onboarding_kids` per `ORCHESTRATOR_NOTES.md` (overrides the brief's `fresh`;
the Maya + Leo cards now render from the database). Parent mode, `THEME=light|dark`.
Comparisons: `tools/screens/compare.py` vs `design/screens/light|dark/P05-add-children.png`.

- Light: `docs/screens/P05/ui/app_light_2.png` → `cmp_light_2.png`, **mean diff 5.51%** (was 6.61%)
- Dark: `docs/screens/P05/ui/app_dark_2.png` → `cmp_dark_2.png`, **mean diff 5.76%** (was 6.76%)

Per-band drift (light): band0 0–105: 1.58% · band1 105–211: 6.42% · band2 211–316: 4.53% ·
band3 316–422: 4.83% · band4 422–527: 5.66% · band5 527–633: 13.70% · band6 633–738: 3.59% ·
band7 738–844: 3.71%. Dark is near-identical (band1 6.87%, band5 14.84%).

Pixel landmarks measured from both PNGs at 3× (÷3 = logical px), light mode:
title ink 113.3–133 / sub ink 158.3–166.7 (identical both) · card top ~192 vs ~238 ·
card height ~113 vs ~124 · h3 ink 334.7–346.7 vs 423.7–435.7 · Nickname ink 370–377 vs
459–466 · CTA top 644 vs 645.

No Pip slot on this screen (avatar initials only) → PIP rule N/A.
Status-bar time/glyphs and home-indicator pill ignored (OS-drawn).

## Deviations

1. [FAIL — blocks gate] Kid grid sits ~46 px too low; form card ~89 px too low;
   swatches clipped, helper caption below the fold.
   Design: card top ~192, h3 ink 334.7, Nickname ink 370, swatch row + caption
   "We only ask for an age range so quests suit them." fully visible above the CTA.
   App (light + dark): card top ~238 (+46), h3 ink 423.7 (+89), Nickname ink 459 (+89);
   only swatch tops peek above the bottom CTA, caption hidden until scrolled.
   Band5 drift (13.7–14.8%) is this.
   Root cause (P05-local, read-only finding): `KidCardGrid`'s `GridView.builder`
   (`kid_card_grid.dart:33-43`) sets no `padding`, so it inherits the ambient
   MediaQuery safe-area insets (~47 top / ~34 bottom). 46 + 11 (taller cards, see #2)
   + 32 ≈ the measured +89. The outer `ListView` is immune (explicit top-0 padding).
   Fix (one line, RULES §1): `padding: EdgeInsets.zero` on that `GridView.builder`.
   Note for the fix pass: after this fix ~23 px of known excess remains (card +11,
   chip row +12, see #2/#3) while the design fits with zero slack (content ends 645 =
   CTA top 644) — re-measure; the caption may still kiss the CTA.

2. [Minor — P05-local choice, flagged] Kid cards ~124 px tall vs design ~113.
   Design: `.kid-card` padding 12/10/10 over 44 + 2 + 24 + 4 + 18 content = ~113;
   the 44 px edit button overlays without adding height. App: `cardH` adds 10 px
   pencil clearance (content itself is now top-aligned per `Align(topCenter)`, so
   review finding 8's 5 px centring offset is gone — only the height differs).
   Fix (optional, P05-local): drop the clearance to match 113, or keep deliberately
   and accept ~11 px of the band2/3 drift.

3. [Fixed this iteration — pass] Age-band chips render in ONE row in both modes
   (4–6, 7–9 selected, 10–12, 13+, gap 8) via the P05-local `IntrinsicWidth`
   workaround for P05-BUG-1. The shared `NestChip` height note stands: the chip box
   is 44 tall vs the design's 32 visual (+12, tap area is overlaid in the mock, not
   stacked) — a DS-level follow-up, already in `SHARED_REQUEST.md` #3; not gate-blocking
   on its own.

4. [Fixed this iteration — pass] Header is pixel-identical (title ink 113.3, sub ink
   158.3–166.7 in both). The shared compact-nav fix (52 px, matching spec) is verified —
   do not patch locally, per orchestrator note 3.

5. [Pass] Bottom edge (owner rule): `NestBottomCta` surface runs to the physical edge in
   both modes (CTA top 644 vs 645, identical geometry). The design PNG is the one that
   breaks the rule (34 px cream strip under the CTA) — the app is the correct one.

6. [Observation — not a defect, orchestrator-owned] Card order Leo|Maya vs design Maya|Leo.
   DATA OVER MOCKS: the roster comes from the DB nickname order (P05-BUG-3); the cards
   render above "Add a child" from the database as orchestrator note 2 requires. No action.

7. [Accepted — no action] Nickname field shows no leaf focus ring (design shows the HTML
   `autofocus` mock state). Do NOT add autofocus. Copy (en-dashes, "Avatar colour",
   all strings), 20 px gutters, card padding/radii/shadows, swatch fills + peach ring,
   CTA buttons + caption, dark-mode tokens, alignment of head/grid/form/CTA edges: all match.

## Verdict basis

Deviation 1 is a visible, designer-rejectable break (colour choice + helper text cut off
at first paint, ~89 px form offset, far outside ±2 px) with a one-line P05-local fix.
Everything else passes or is data/owner-ruled correct.

VERDICT: FAIL
