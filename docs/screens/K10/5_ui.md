# K10 · Payout day (`/payout-day`) — 5_ui (iteration 1)

Route: `/payout-day`, kid mode, child maya, seed demo. Simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844 logical, PNG 1170×2532 @3x, ÷3).
No code edited. No `ORCHESTRATOR_NOTES.md` exists for K10 (checked). Plan `1_plan.md` §b DB expectation applies.

## Shots

- `bash tools/screens/shot.sh "$PWD/app" /payout-day "$PWD/docs/screens/K10/ui/app_light_1.png" 604697A9-11DA-462F-9837-396E9CA2493A light demo kid maya` → stable frame saved.
- Same with `dark` → `app_dark_1.png`.
- NOTE: relative `OUT` fails because `shot.sh` does `cd "$APP_DIR"` before `cp "$TMP/cur.png" "$OUT"`; absolute `OUT` used. No script edited.
- `python3 tools/screens/compare.py design/screens/light/K10-payout-day.png docs/screens/K10/ui/app_light_1.png docs/screens/K10/ui/cmp_light_1.png`
- `python3 tools/screens/compare.py design/screens/dark/K10-payout-day.png docs/screens/K10/ui/app_dark_1.png docs/screens/K10/ui/cmp_dark_1.png`

## Mean diff

Light mean diff: **5.38%**

| band | y-range | diff% |
|---|---|---|
| 0 | 0–105 | 1.58% |
| 1 | 105–211 | 0.19% |
| 2 | 211–316 | 0.11% |
| 3 | 316–422 | 0.14% |
| 4 | 422–527 | 2.11% |
| 5 | 527–633 | 16.51% |
| 6 | 633–738 | 15.57% |
| 7 | 738–844 | 6.84% |

Dark mean diff: **4.95%**

| band | y-range | diff% |
|---|---|---|
| 0 | 0–105 | 1.61% |
| 1 | 105–211 | 0.22% |
| 2 | 211–316 | 0.09% |
| 3 | 316–422 | 0.38% |
| 4 | 422–527 | 2.11% |
| 5 | 527–633 | 15.37% |
| 6 | 633–738 | 15.50% |
| 7 | 738–844 | 4.35% |

Bands 1–3 (≈0.1–0.4%) = rain illustration pixel-perfect. Bands 5–6 spike = note-2 DB text + fund shift (see D1–D3). Band 7 = bottom-edge owner-rule override (see D4). Band 0 = status-bar glyphs only (ignored per STATUS BAR rule: design `9:41`, app `03:43`/`03:46`).

## Measured y (logical px, ÷3, design vs app, light + dark agree)

Method: 3x PNG scan, middle-third horizontal border runs (card 3 px ink border = 9 px @3x), title top via text-pixel projection, gutters via vertical border runs at y=460.

| element | design y (top) | app y (top) | Δ |
|---|---|---|---|
| screen title `It's payout day!` top | 113.3 | 113.3 | 0.0 |
| back / lock row (56×56, `.krow-top` 47…107) | same slot | same slot | 0 |
| rain box 180×270 (`.rain`) | ~141 (title bottom + sep) | ~141 | 0 |
| note 1 top (`.k10-note` #1) | 427.0 | 427.0 | 0.0 |
| note 1 bottom | 490.0–493.0 | 490.0–493.0 | 0.0 |
| note 2 top (`.k10-note` #2) | 509.0 | 509.0 | 0.0 |
| note 2 bottom | 572.0–575.0 | 594.0–597.0 | +22.0 (DB-driven, D1) |
| fund card top (`.k10-fund`) | 591.0–594.0 | 613.0–616.0 | +22.0 (DB-driven knock-on, D3) |
| kid-bar top (`.kid-bar`, 3 px ink top border) | 721.0–724.0 | 721.0–724.0 | 0.0 |
| gutters (cards x / w) | x=20.0, right 367.0–369.7 (w≈350) | x=20.0, right 367.0–369.7 (w≈350) | 0.0 |

Title / first card / bar tops match within ±2 px. Fund-top +22 is entirely the DB-driven note-2 wrap (excluded by UI VERDICT RULE alongside DB content).

## Numbered deviations (element, design value, app value, fix)

D1. Note 2 title copy + wrap — design `£1.00 went into your Lego fund` (1 line, card h≈66) vs app `£5.50 went into your Lego Friends set` (2 lines, card h≈88, bottom +22). DB-driven per `1_plan.md` §b (seed move 550, goal `Lego Friends set`): paid 380 / moved 550 / saved 1550 vs mock 420/100/1650. Card follows same CSS box model (surface, 3 px ink, r16, sh-kid, 10/12 padding, 40 px disc) and wraps instead of overflowing. No fix (correct DATA OVER MOCKS behaviour; `2b_build_ui.md` deviation 1 discloses the same +22).

D2. Note 1 + fund numbers + progress width — design `Mum marked £4.20 as paid` / `£16.50` / `£8.49 to go` / `of £24.99` / `66% there!` / 66% fill vs app `Mum marked £3.80 as paid` / `£15.50` / `£9.49 to go` / `of £24.99` / `62% there!` / 62% fill. DB-driven (same seed rows as D1). Layout, type (`k10-t` 17/22 w800, `k10-s` 14/18 w700, amts 17/23 w900, `kcap` 15/20 w700), `NestProgress(kid:true)` shape, and colours match. No fix.

D3. Fund card vertical position — design top 591 vs app top 613 (+22). Pure knock-on of D1 (16 px scroll rhythm kept: note-1 bottom 493 + 16 = 509 note-2 top in both; fund = note-2 bottom + 16 in both). Excluded from ±2 px rule as DB-driven shift. No fix.

D4. Bottom edge below kid-bar — design shows meadow strip under bar/home-indicator (light green, dark green) vs app same-surface-to-edge (light white surface, dark dark surface, `NestHomeIndicator` inside surface box). App is CORRECT per BOTTOM EDGE owner rule (overrides designs). `compare.py` band 7 diff is this intentional difference. No fix.

D5. Status-bar glyphs — design `9:41` + mock icons vs app OS `03:43`/`03:46` + real icons. Ignored per STATUS BAR rule (`NestStatusBar` reserves 47 px only). No fix.

## Element-by-element

- Presence/order: top row (back `Back` 56×56 + lock `Grown-ups` 56×56 r18) → title → rain jar → note 1 → note 2 → fund → kid-bar `Thanks Mum!` leaf. Same order as `K10-payout-day.html:37–96`. Pip row (`.k10-pip`, 72 px `PipAvatar` + speech `Pip says well done, Maya!`) is below the fold behind the fixed bar in BOTH design and app initial frames (fund cut off at bar in both PNGs); no visible deviation in this frame. PIP rule is code-side (active child Maya Mochi·sunny·stage 3 via `PipAvatar`, never v1 SVG) per `2b_build_ui.md`; geometry test records rain 105/141/180/270.
- Copy (byte check): HTML `It's` is U+0027 straight apostrophe (`0x27`); app `title = "It's payout day!"` matches. `£` is UTF-8 `C2 A3` in HTML; app renders via `jarPounds` with same glyph. `Thanks Mum!`, `Pocket money for this week`, `Just like you asked`, `Lego Friends set`, `to go`, `there!` all match HTML wording/punctuation; amounts differ only per D2 (DB).
- Spacing/sizes/alignment: side gutters 20, scroll separators 16, bar `12/20/10`, rain 180×270, discs 40, icons 22, button min-h 64 — all match; no misalignment; card/background rects (not just text) measured above match.
- Colours/radii/shadows/icons: surface/ink/coinTint/leafTint/lilacTint fills via tokens in both themes; fixed jar palette (`#F4B400` coins, `#E09700` mass, `#7C6CF2` lid/sparkle, `#F2FAFF` glass, `#1F9D63` leaf spark, ink 3–4 px outlines) identical in light+dark; r16 notes / r24 fund / r18 lock.lg / r24 kid button; sh-kid offsets visible under cards+button in both; note-1 check (stroke ≈3) and note-2 circle+arrow transcriptions match design glyphs; no overflow/clipping/ellipsis failure (D1 wraps cleanly).
- Dark mode: card/border/button/progress/meadow-token swaps match `design/screens/dark/K10-payout-day.png` (dark surface cards, white borders, brown coinTint fund, bright-green `Thanks Mum!`, dark sky + hills). No dark-only deviation beyond D1–D4 (same in both themes).
- Kid background: sky + meadow 390×136 at bottom 0 from shared `KidScope` in both; only difference below bar is the required D4 surface run.

No uniform vertical shift. Every non-DB element is within ±2 px.

VERDICT: PASS
