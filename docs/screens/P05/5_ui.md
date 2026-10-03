# P05 · Add children — UI check (STAGE 5, iteration 8)

Route `/add-children`, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844, mandated).
Shots use `SEED=onboarding_kids` (brief + `ORCHESTRATOR_NOTES.md`). Parent mode, `THEME=light|dark`.
Comparisons: `tools/screens/compare.py` vs `design/screens/light|dark/P05-add-children.png`.

- Light: `docs/screens/P05/ui/app_light_8.png` → `cmp_light_8.png`, **mean diff 1.29%** (was 1.34%)
- Dark: `docs/screens/P05/ui/app_dark_8.png` → `cmp_dark_8.png`, **mean diff 1.22%** (was 1.26%)

Per-band drift (light): band0 0–105: 1.61% · band1 105–211: 0.32% · band2 211–316: 0.20% ·
band3 316–422: 1.70% · band4 422–527: 2.69% · band5 527–633: 0.14% · band6 633–738: 1.35% ·
band7 738–844: 2.33%. Dark matches within ~0.5%.

Text landmarks (ink rows, ÷3 = logical px): title 113.3, subtitle 158.3–166.7, card names
254.0–262.7, h3 334.7–346.7, Nickname 370.0–376.7, Age-band 454.0–460.7, chips 480/481–490,
Avatar-colour 516.0–522.7, caption 588.0–594.7, CTA 678/716–768/781–790 — all ±1 px vs design,
unchanged from iteration 6/7.

SHAPES (new rule — background/border rects, px @3x, design → app):

| rect | design (x, y, w, h) | app (x, y, w, h) | Δ |
|---|---|---|---|
| kid card (left) | x 60–570, top 561 | x 60–570, top 561 | 0 |
| form card top / bottom | 945 / 1763 | 945 / 1763 | 0 |
| chip pills (x-runs, y 1449) | w 165/162/201/162, x0 102 | w 159/156/194/156, x0 102 | −6 px w each (≈ −2 logical) |
| chip pill height | 1407–1502 (96 px = 32) | 1407–1502 (96 px = 32) | 0 |
| swatches (5 circles) | x-runs identical, Ø 132 px = 44 | identical | 0 |
| Continue button | y 2148–2303 (52 high) | identical | 0 |

No Pip slot on this screen (avatar initials only) → PIP rule N/A.
Status-bar time/glyphs (band0) and home-indicator pill (band7) ignored — OS-drawn.
CHIP ROWS rule: age chips use `NestChipWrap` (form_card.dart:87; swatch row:119);
`NestChipWrap` is the Wrap whose hit test reaches around the row with no layout change —
row geometry above confirms 32 px pills in one row.
BALANCED HEADINGS rule: design `.h1` sets `text-wrap: balance` and the h1 renders through
`NestBalancedText` (add_children_view.dart:198-201) — compliant (single line at 390 px,
no orphan possible).

## Deviations (none gate-blocking)

1. Chip pills ≈ 2 logical px narrower each (same left edge x 102, same 32 px height,
   same gaps; row ends ≈ 8 px earlier over 4 pills). Cause: bundled Nunito/Inter renders
   chip labels ~3% narrower than the design's web fonts (the known delegated body-text
   brief) — shared font rendering, not P05 layout: P05 passes text + tokens only, and
   letter-spacing compensation is forbidden (LETTER SPACING rule). At/barely-inside the
   ±2 px tolerance per pill; invisible except by pixel overlay. No P05 action possible.
2. Nickname field unfocused (design shows the focused leaf ring; band3 ≈1.7%).
   Accepted mock state per orchestrator notes — do not add autofocus.
3. Band4/6 heat (≈2.7%/1.4%) is the accepted focus-ring difference plus sub-pixel
   text/pill-edge rendering; no positional deviation (table above).
4. Copy character-exact vs HTML (curly ’ U+2019, em/en dashes, "Avatar colour", all
   labels/captions/buttons, `Edit <name>`). No overflow/clipping/ellipsis.
5. Owner rules: bottom bar surface to the physical edge both modes; 20 px gutters, all
   edges aligned. Dark-mode colours match.

## Verdict basis

All shapes and text within tolerance in both modes; order (Maya, Leo), copy, owner rules
all hold; the single measurable delta (2 px narrower pills) is shared font rendering a
designer could not reasonably reject and P05 is forbidden from compensating.

VERDICT: PASS
