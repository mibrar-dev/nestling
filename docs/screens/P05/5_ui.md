# P05 · Add children — UI check (STAGE 5, iteration 7)

Route `/add-children`, simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
Shots use `SEED=onboarding_kids` (brief + `ORCHESTRATOR_NOTES.md`). Parent mode, `THEME=light|dark`.
Comparisons: `tools/screens/compare.py` vs `design/screens/light|dark/P05-add-children.png`.

- Light: `docs/screens/P05/ui/app_light_7.png` → `cmp_light_7.png`, **mean diff 1.34%** (was 1.34%)
- Dark: `docs/screens/P05/ui/app_dark_7.png` → `cmp_dark_7.png`, **mean diff 1.26%** (was 1.25%)

Per-band drift (light): band0 0–105: 1.63% · band1 105–211: 0.32% · band2 211–316: 0.20% ·
band3 316–422: 1.70% · band4 422–527: 3.11% · band5 527–633: 0.14% · band6 633–738: 1.35% ·
band7 738–844: 2.33%. Dark matches within ~0.5% (band5 0.13%).

Pixel landmarks measured from both PNGs at 3× (÷3 = logical px), light mode:

| element (ink rows) | design | app | Δ |
|---|---|---|---|
| title "Who’s" | 113.3–133.0 | 113.3–132.7 | 0 |
| subtitle | 158.3–166.7 | 158.3–166.7 | 0 |
| card names (Maya\|Leo) | 254.0–262.7 | 254.0–262.7 | 0 |
| h3 "Add a child" | 334.7–346.7 | 334.7–346.7 | 0 |
| "Nickname" label | 370.0–376.7 | 370.0–376.7 | 0 |
| "Age band" label | 454.0–460.7 | 454.0–460.7 | 0 |
| chip labels | 481.0–490.7 | 480.0–489.7 | −1 |
| "Avatar colour" label | 516.0–522.7 | 516.0–522.7 | 0 |
| swatch row zone | 529–577 | 529–577 | 0 |
| helper caption | 588.0–594.7 | 588.0–594.7 | 0 |
| CTA (buttons + caption) | 678 / 716–768 / 781–790 | identical | 0 |
| CTA top (gutter) | 644 | 645 | +1 |

Every row within ±1 px, unchanged from iteration 6. `NestChipWrap` is not yet in
`core/design_system` (grep: absent), so the age chips still use the plain `Wrap` + shared
32 px-layout `NestChip` — visually and geometrically identical to iteration 6, one row,
7–9 selected. The pending `NestChipWrap` swap is test-stage business ([P05-BUG-11] stays
skipped per the orchestrator's 04:31 decision); it changes hit-testing, not layout, so it
cannot regress these pixels.

No Pip slot on this screen (avatar initials only) → PIP rule N/A.
Status-bar time/glyphs (band0) and home-indicator pill (band7) ignored — OS-drawn.

## Deviations (all accepted or sub-visible — none gate-blocking)

1. Nickname field unfocused (design shows the focused leaf ring; band3 ≈1.7%).
   Accepted mock state per orchestrator notes — do not add autofocus.
2. Band4 heat (≈3.1% light / 2.6% dark) is the accepted focus-ring difference plus
   sub-pixel pill/text rendering (bundled Nunito, letterSpacing 0 per shared rule);
   chip label rows measure −1 px, inside tolerance.
3. CTA caption/button heat (band6 ≈1.4%) is text-rendering only; geometry identical.
4. Copy character-exact vs HTML (curly ’ U+2019, em/en dashes, "Avatar colour", all
   labels/captions/buttons, `Edit <name>`). No overflow/clipping/ellipsis.
5. Owner rules: bottom bar surface to the physical edge both modes; 20 px gutters, all
   edges aligned. Dark-mode colours match.

## Verdict basis

All elements present, correctly ordered (Maya, Leo), exact copy, positions within ±1 px
of the design in both modes; every remaining diff pixel falls in an ignored category
(OS status bar / home pill), an accepted mock state (unfocused field), or sub-pixel
font rendering. No visible deviation a designer would reject.

VERDICT: PASS
