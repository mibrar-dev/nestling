# P11 · Approvals — Stage 5 UI CHECK (iteration 1)

Method (simulator `E7D5555E-378A-49DF-AAEE-16677AF4B9DB`, 390×844):

```
bash tools/screens/shot.sh "$PWD/app" /approvals "$PWD/docs/screens/P11/ui/app_light_1.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB light demo parent maya
bash tools/screens/shot.sh "$PWD/app" /approvals "$PWD/docs/screens/P11/ui/app_dark_1.png"  E7D5555E-378A-49DF-AAEE-16677AF4B9DB dark  demo parent maya
python3 tools/screens/compare.py design/screens/light/P11-approvals.png docs/screens/P11/ui/app_light_1.png docs/screens/P11/ui/cmp_light_1.png
python3 tools/screens/compare.py design/screens/dark/P11-approvals.png  docs/screens/P11/ui/app_dark_1.png  docs/screens/P11/ui/cmp_dark_1.png
```

Screenshots are 1170×2532 (@3x); all px below are logical (÷3). No code edited.

## Mean diff % + band table

Light: **mean diff 11.30%**

```
band  y-range    diff%
  0      0-105    1.61%
  1    105-211    0.14%
  2    211-316   11.76%
  3    316-422   12.70%
  4    422-527   23.02%
  5    527-633   14.73%
  6    633-738   16.05%
  7    738-844   10.49%
```

Dark: **mean diff 9.60%**

```
band  y-range    diff%
  0      0-105    1.62%
  1    105-211    0.13%
  2    211-316    9.47%
  3    316-422   11.50%
  4    422-527   18.66%
  5    527-633   12.31%
  6    633-738   14.61%
  7    738-844    8.60%
```

Bands 0–1 (status/nav/helper) are ~identical. Bands 2–7 carry the three
documented deltas below (missing `.qn` quote block = 34 px per card,
DB-driven card 2/3 rows, OWNER bottom-edge CTA). Nothing else lights up.

## Measured y positions (logical px, centre-column scan, design vs app light)

| element | design y | app y | Δ |
|---|---|---|---|
| nav title ink rows | 68–78 | 68–78 | 0 |
| helper banner top / bottom | 107 / 171 | 107 / 171 | 0 |
| helper text rows | 127–153 | 127–153 | 0 |
| card 1 top | 187 | 187 | 0 |
| card 1 bottom (surface→gap) | 359–362 (h 172) | 325–329 (h 138) | −34 (quote block) |
| card 1 Approve green fill (R-edge x=340) | 298–340 (core h 43) | 264–306 (core h 43) | −34 (quote block) |
| card 2 top | 375 | 341 | −34 (quote block) |
| card 2 bottom | 547–550 (h 172) | 479–483 (h 138) | −34 |
| card 3 top | 563 | 495 | −68 (2× quote block) |
| card 3 bottom | ~717 (runs under CTA) | 633–637 (h 138) | −84 (quotes + scroll gap) |
| CTA surface top | ~707–718 | 727 | +9 (OWNER surface-to-edge) |
| CTA button (Approve all) | x 20–369, y 734–785 (350×52) | x 21–369, y 742–793 (349×52) | +8 y, 0–1 x (AA) |
| bottom edge fill (y=839–842) | paper (251,247,240) + pill | surface white to edge | OWNER override (correct) |

Dark sampled tokens match exactly: paper (21,19,31), helper tint
(23,58,43), card surface (31,28,46) — identical design vs app. Approve mint
and Not-yet/ink/avatar colours are the same token pair in both (centre
samples hit glyph ink, edge samples hit identical fills).

Shapes (background/border rects, not just text):
helper x 20–370 w 350 both; card x 20–370 w 350 both; card-1 Approve
w 154 both, green core h 43 both; Not-yet borders x 36 / 189 both, edge
height 43–44 both; CTA button 350×52 both. No P05-style collapsed pill.

## Checks against orchestrator + spec rules

- PIP: N/A (initial avatars only — `M` lilac / `L` peach s44, correct per child).
- STATUS BAR: ignored (design 9:41 mock vs OS 15:21/15:22 real). Height-only
  reserve confirmed by title at identical y 68–78.
- DATA OVER MOCKS: app rows are the seeded DB 3 (dishwasher Maya 15 8:12am;
  table Maya 10 8:05am; bed Leo 5 7:58am, all Today, newest-first). Correct.
- BOTTOM EDGE: PASS — surface runs to y=844 light (255,255,255) and dark
  (31,28,46). No paper/meadow strip under the bar in either theme.
- ALIGNMENT: PASS — 20 px gutters everywhere (helper, cards, CTA button
  left 20/21), nothing off by >1 px AA.
- CHILD ORDER: Maya, Maya, Leo = creation order, not alphabetical. Correct.
- COPY: helper byte-exact (`“Not yet” sends a kind note — no coins are taken
  away.` U+201C/U+201D/U+2014), title `Waiting for you (3)`, `Not yet` /
  `Approve` / `Approve all (3)`, `·` U+00B7 separators, `Today 8:12am`-style
  times. Matches HTML source char-for-char (quotes intentionally absent, §1).
- FONTS / LETTER SPACING / CHIP ROWS / BALANCED HEADINGS: nothing added, no
  chips, no balance scope — per plan.
- DARK MODE: paper/surface/tint/ink pairs match tokens; Approve mint with
  dark text, Not-yet dark fill with light text, same as dark PNG.
- OVERFLOW: none; long title `Maya · Empty the dishwasher` single-line
  ellipsis at 390 px; helper wraps to the same 2 lines with the same break.
- RADII/SHADOWS: helper r-m 16, cards r-l 24, buttons pill 999 — visually
  identical; sh-1 hairlines identical (border scans match at x=36/189).

## Numbered deviations (element, design value, app value, fix)

1. `.qn` quote lines on all 3 cards — design: 17/24 w700 quote
   (`“I stacked everything neatly!”` / `“I did the pillows too.”` /
   `“Toys are all in the box.”`, block 10+24=34 px); app: absent, card
   h 138 vs 172. Fix: NONE in screen scope — `quest_completions` has no
   note/message column (RULES shared core). Already filed as
   `SHARED_REQUEST.md` item 1 (add `note TEXT DEFAULT ''` + seed values);
   DATA OVER MOCKS forbids hard-coding the mock quotes. Cascade
   (buttons −34, card tops 187/341/495 vs 187/375/563) is exactly the
   plan-predicted 34 px. Excluded from the ±2 px rule as DB-driven
   (no data source).
2. Card 2/3 rows content — design card 2 `Leo · Make your bed / Today
   7:58am · 5 coins`, card 3 `Maya · Tidy your bedroom / Yesterday 5:40pm ·
   15 coins`; app card 2 `Maya · Lay the table / Today 8:05am · 10 coins`,
   card 3 `Leo · Make your bed / Today 7:58am · 5 coins`. Fix: NONE —
   app shows the real seeded DB values (correct per DATA OVER MOCKS;
   `Yesterday 5:40pm` / `Tidy your bedroom` are mock content with no DB
   row). Excluded as DB-driven content.
3. Bottom CTA y (+8/9 px) and missing paper home strip — design button
   734–785 on surface 718 + paper strip 810+ with mock pill; app button
   742–793 on surface 727 → physical edge 844, no strip. Fix: NONE —
   mandatory OWNER bottom-edge override (`NestBottomCta` surface to edge).
   Size (350×52), gutters, colours identical. UI checks must not FAIL
   the override.
4. Status-bar glyphs — design `9:41` + mock icons; app real OS time/icons.
   Fix: NONE — ignored per STATUS BAR rule; layout anchor (title 68–78)
   proves no shift.

No other visible deviation: presence/order (nav → helper → 3 cards →
CTA), spacing of every non-DB element, sizes, alignment, colours, radii,
shadows, chevron icon, and dark-mode pairs are within ±2 px (mostly ±0).

VERDICT: PASS
