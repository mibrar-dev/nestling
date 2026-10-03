# P11 · Approvals — Stage 5 UI CHECK (iteration 2)

Method (simulator `E7D5555E-378A-49DF-AAEE-16677AF4B9DB`, 390×844):

```
bash tools/screens/shot.sh "$PWD/app" /approvals "$PWD/docs/screens/P11/ui/app_light_2.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB light demo parent maya
bash tools/screens/shot.sh "$PWD/app" /approvals "$PWD/docs/screens/P11/ui/app_dark_2.png"  E7D5555E-378A-49DF-AAEE-16677AF4B9DB dark  demo parent maya
python3 tools/screens/compare.py design/screens/light/P11-approvals.png docs/screens/P11/ui/app_light_2.png docs/screens/P11/ui/cmp_light_2.png
python3 tools/screens/compare.py design/screens/dark/P11-approvals.png  docs/screens/P11/ui/app_dark_2.png  docs/screens/P11/ui/cmp_dark_2.png
```

Screenshots 1170×2532 (@3x); px below logical (÷3). No code edited. This
iteration runs on the post-merge tree (`shared/completion_note` on main,
iteration-2 build): `quest_completions.kid_note` (schema v6) renders as
`“$kidNote”`, NULL shows no line and no gap.

## Mean diff % + band table

Light: **mean diff 6.39%** (was 11.30%)

```
band  y-range    diff%
  0      0-105    1.66%
  1    105-211    0.14%
  2    211-316    0.34%
  3    316-422    2.34%
  4    422-527   18.29%
  5    527-633    8.25%
  6    633-738   17.95%
  7    738-844    2.27%
```

Dark: **mean diff 5.55%** (was 9.60%)

```
band  y-range    diff%
  0      0-105    1.65%
  1    105-211    0.13%
  2    211-316    0.34%
  3    316-422    2.27%
  4    422-527   14.95%
  5    527-633    8.15%
  6    633-738   14.63%
  7    738-844    2.39%
```

Bands 0–3 are now ~identical (card 1 with quote matches). Bands 4–6 carry
only the DB-driven rows (card 2 NULL quoteless vs design quote; card 3
different pending + different quote). Band 7 is the OWNER home strip +
status glyphs.

## Measured y positions (logical px, design vs app light iteration 2)

| element | design y | app y | Δ |
|---|---|---|---|
| nav title ink rows | 68–78 | 68–78 | 0 |
| helper banner top / bottom | 107 / 171 | 107 / 171 | 0 |
| helper text rows | 127–153 | 127–153 | 0 |
| helper tint x-span | 20–369 (w 350) | 20–369 (w 350) | 0 |
| card 1 top | 187 | 187 | 0 |
| card 1 bottom | 360–362 (h 172) | 360–363 (h 172) | 0–1 |
| card 1 Approve green rect | x 200–353, y 295–342 | x 200–353, y 295–342 | 0 |
| card 1 quote | `“I stacked everything neatly!”` 1 line | identical line, same break | 0 |
| card 2 top | 375 | 375 | 0 |
| card 2 bottom | 548–550 (h 172, with quote) | 514–517 (h 138, NULL no gap) | −34 DB-driven |
| card 3 top | 563 | 529 | −34 DB-driven (NULL upstream) |
| CTA button (Approve all) | y 734–785 (x 20–369, 350×52) | y 734–785 (x 20–369) | 0 |
| bottom edge fill y 842 | paper (251,247,240) + mock pill | surface white to edge | OWNER override (correct) |

Dark tokens sampled identical: paper (21,19,31), helper tint (23,58,43),
card surface (31,28,46). Shapes are background/border rects: pills full
154-wide (borders x 36/189 iteration 1, unchanged geometry), CTA 350×52,
cards x 20–370 — no collapsed pill.

## Orchestrator notes (all mandatory items verified)

1. Quotes render from `kid_note`: card 1 `“I stacked everything neatly!”`,
   card 3 `“I did the pillows too.”` with inline curly quotes per the shared
   report; card 2 (q-table, NULL) shows no quote line and no gap (h 138).
   Matches `completion_note_REPORT.md` (raw text + `“$kidNote”`).
2. Pending set from DB (dishwasher Maya 8:12 / table Maya 8:05 / bed Leo
   7:58, newest-first, Maya,Maya,Leo creation order) — correct, not a finding.
3. CTA position fixed: button 734–785 both (centre 760 = 844−84). Surface
   still runs to the physical edge (white / dark surface at y 842).
4. Card geometry with + without quote both present on screen: with-quote
   h 172 (cards 1, 3), without-quote h 138 (card 2, no gap).

## Numbered deviations (element, design value, app value, fix)

1. Card 2 row — design `Leo · Make your bed / Today 7:58am · 5 coins` +
   `“I did the pillows too.”`; app `Maya · Lay the table / Today 8:05am ·
   10 coins`, no quote (NULL). Fix: NONE — app shows the true seeded
   pending (table/NULL per shared report). Excluded as DB-driven content.
2. Card 3 row — design `Maya · Tidy your bedroom / Yesterday 5:40pm ·
   15 coins` + `“Toys are all in the box.”`; app `Leo · Make your bed /
   Today 7:58am · 5 coins` + `“I did the pillows too.”`. Fix: NONE —
   DB-driven pending + its true note (orchestrator item 2; `Tidy your
   bedroom` / `Yesterday 5:40pm` / `Toys…` have no DB row).
3. Home strip under CTA — design paper strip + mock pill (810+); app
   surface to the edge both themes. Fix: NONE — mandatory OWNER
   bottom-edge override; UI checks must not FAIL it.
4. Status-bar glyphs — design `9:41` mock vs real OS time/icons. Fix:
   NONE — ignored per STATUS BAR rule (title anchor 68–78 proves no shift).

Presence/order (nav → helper → 3 cards → CTA), copy (helper em dash and
`“ ”`/`·` per HTML, `Waiting for you (3)`, `Not yet`/`Approve`/
`Approve all (3)`), spacing/sizes of every non-DB element, alignment
(20 px gutters), colours, radii, shadows, chevron, dark-mode pairs, and
ellipsis/overflow are within ±2 px (measured mostly ±0).

VERDICT: PASS
