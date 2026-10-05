# K10 · Payout day (`/payout-day`) — 5_ui (iteration 2)

Route `/payout-day`, kid mode, child maya, seed demo. Simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844 logical; PNGs 1170×2532 @3x, ÷3). No code edited. No `ORCHESTRATOR_NOTES.md` for K10. DB expectation per `1_plan.md` §b.

## Shots

- `bash tools/screens/shot.sh "$PWD/app" /payout-day "$PWD/docs/screens/K10/ui/app_light_2.png" 604697A9-11DA-462F-9837-396E9CA2493A light demo kid maya` → stable frame.
- Same with `dark` → `app_dark_2.png` (absolute OUT used: `shot.sh` `cd`s into `$APP_DIR` before `cp`, so a relative OUT resolves under `app/`).
- `python3 tools/screens/compare.py design/screens/light/K10-payout-day.png docs/screens/K10/ui/app_light_2.png docs/screens/K10/ui/cmp_light_2.png` (and dark). Compare + app PNGs READ with file reader.

## Mean diff

Light **5.38%**: 0–105: 1.59% · 105–211: 0.19% · 211–316: 0.11% · 316–422: 0.14% · 422–527: 2.11% · 527–633: 16.51% · 633–738: 15.57% · 738–844: 6.84%.
Dark **4.95%**: 0–105: 1.59% · 105–211: 0.22% · 211–316: 0.09% · 316–422: 0.38% · 422–527: 2.11% · 527–633: 15.37% · 633–738: 15.50% · 738–844: 4.31%.
Bands 1–3 (≈0.1–0.4%) = jar/rain pixel-perfect. Bands 5–6 = DB-driven note-2 wrap + fund knock-on (D1–D3). Band 7 = bottom-edge owner-rule override (D4). Band 0 = status-bar glyphs only (ignored per STATUS BAR rule: design `9:41`, app `05:10`/`05:13`).

## Measured y, design vs app (logical px; light and dark identical)

Border-run scan, middle-third x, 3 px ink borders = 9 px @3x; title top via text-pixel projection; gutters via vertical border runs at y=460.

| element | design top | app top | Δ |
|---|---|---|---|
| title `It's payout day!` top | 113.3 | 113.3 | 0.0 |
| back/lock row (56×56, 47…107) | same slot | same slot | 0 |
| rain jar 180×270 | ~141 | ~141 | 0 |
| note 1 top | 427.0 | 427.0 | 0.0 |
| note 1 bottom | 490.0–493.0 | 490.0–493.0 | 0.0 |
| note 2 top | 509.0 | 509.0 | 0.0 |
| note 2 bottom | 572.0–575.0 | 594.0–597.0 | +22 DB-driven (D1) |
| fund card top | 591.0–594.0 | 613.0–616.0 | +22 DB-driven knock-on (D3) |
| kid-bar top (3 px ink border) | 721.0–724.0 | 721.0–724.0 | 0.0 |
| card gutters (BACKGROUND rect) | x 20.0–22.7 / 367.0–369.7 (w≈350) | x 20.0–22.7 / 367.0–369.7 (w≈350) | 0.0 |

No uniform vertical shift. Every non-DB element within ±2 px.

## Deviations (element, design, app, fix)

D1. Note-2 title + height — design `£1.00 went into your Lego fund`, 1 line, card ≈66 tall vs app `£5.50 went into your Lego Friends set`, 2 lines, card ≈88 tall (+22). DB-driven (seed move 550, goal `Lego Friends set` per plan §b; mock abbreviated to `Lego fund`). Same CSS box (surface, 3 px ink, r16, sh-kid, 10/12 padding, 40 px disc, `Flexible` wrap, no overflow/clipping). No fix.
D2. Amounts/progress — design `Mum marked £4.20 as paid` / `£16.50` / `£8.49 to go` / `66% there!` / 66% fill vs app `£3.80` / `£15.50` / `£9.49 to go` / `62% there!` / 62% fill. DB-driven (seed paid 380, saved 1550/2499). Type, `NestProgress(kid:true)` shape, colours match. No fix.
D3. Fund-card y — design 591 vs app 613 (+22). Pure knock-on of D1 (16 px scroll rhythm kept both: note-1 bottom 493 + 16 = note-2 top 509; fund = note-2 bottom + 16). Excluded as DB-driven shift. No fix.
D4. Bottom edge — design meadow strip under bar/home indicator vs app bar surface run to physical edge (light white, dark dark surface, indicator inside). App CORRECT per BOTTOM EDGE owner rule (overrides designs; band-7 diff is this). No fix.
D5. Status bar — design `9:41`/mock icons vs OS clock/icons. Ignored per rule. No fix.

## Element check

- Presence/order: back `Back` + lock `Grown-ups` (56×56 r18) → title → rain jar → note 1 → note 2 → fund → kid-bar `Thanks Mum!` leaf. Matches `K10-payout-day.html:37–96`. Pip row (72 px `PipAvatar` + `Pip says well done, Maya!`) sits below fund, behind fixed bar in BOTH design and app first frames (fund cut at bar) — no visible deviation; PIP rule is code-side (active child Maya Mochi·sunny·stage 3, never v1 SVG).
- Copy: `It's` = U+0027 straight apostrophe in HTML and app; `£` = C2 A3; wording/punctuation (`Thanks Mum!`, `Pocket money for this week`, `Just like you asked`, `to go`, `there!`) matches HTML; only numbers/names differ per D1–D2.
- Shapes not just text: card/button BACKGROUND/BORDER rects measured above (x/w/h via border runs) match; radii (notes r16, fund r24, lock.lg r18, kid button r24), 3 px ink borders, sh-kid offsets, 40 px discs, 22 px icons, 56–64 px tap targets all visually match.
- Colours/icons/dark mode: token fills both themes; fixed jar palette identical light+dark; check + circle-arrow glyphs match design; progress green; dark `Thanks Mum!` bright-green/dark-text matches dark design. No dark-only deviation beyond D1–D4.
- Alignment: 20 px gutters both sides, cards/bars share edges, nothing off. Kid background shared sky + meadow 390×136 at bottom 0; only sub-bar difference is required D4.

VERDICT: PASS
