# P17 Parental gate — 5_ui (iteration 2)

Route `/parental-gate`, mode kid, child maya, seed demo. Simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844 logical, 1170×2532 physical; ÷3).
No code edited by this stage. ORCHESTRATOR_NOTES.md applied as mandatory (items 1–7 checked below).

Shots:
- `docs/screens/P17/ui/app_light_2.png` / `app_dark_2.png`
- `docs/screens/P17/ui/cmp_light_2.png` / `cmp_dark_2.png` via `tools/screens/compare.py`

Mean diff:
- light: 6.66% (bands 0–7: 1.22 / 1.51 / 2.76 / 6.51 / 11.40 / 10.84 / 5.56 / 13.38)
- dark: 5.41% (bands: 1.41 / 1.52 / 2.57 / 6.22 / 10.99 / 10.22 / 5.14 / 5.23)
- Iteration 1 was 7.86% / 6.43%: bands 0–2 (scrim/backdrop/title/question) are fixed (now ~1–2.7%); bands 3–7 (keypad rows 2–4, cancel, caption, bottom) still fail.

Measured y, logical px (physical ÷3; modal edges = first/last row with >60% modal-surface run; text bands = dark-ink pixel histogram, centre column ±):
- Modal (card) top: design 66.0 / app 66.0 (Δ 0) — PASS, orchestrator item 2 fixed for top
- Modal bottom: design 777.7 / app 803.7 (Δ +26.0) — FAIL
- Modal left/width: design x24.0 w342.0 / app x24.0 w342.0 (Δ 0) — PASS
- Screen title “Grown-ups only” top: design 164.0 / app 164.0 (Δ 0) — PASS (orchestrator item 3 fixed)
- Instruction “Type the answer in numbers:” band: design 160.0 / app 160.0 (Δ 0) — PASS
- Question band top: design 225.0 / app 225.3 (Δ +0.3) — PASS (orchestrator item 3 fixed)
- Keypad row 1 top: design 344.0 / app 344.0 (Δ 0) — PASS
- Keypad row 2 top: design 426.0 / app 432.0 (Δ +6.0) — FAIL
- Keypad row 3 top: design 508.0 / app 520.0 (Δ +12.0) — FAIL
- Keypad row 4 top: design 590.3 / app 608.3 (Δ +18.0) — FAIL
- Cancel “Back to Pip” top: design 696.3 / app 724.0 (Δ +27.7) — FAIL (orchestrator item 6 not met: centres 702 vs ~729)
- Caption inherits the bottom shift (light band 7 diff 13.38%).

Non-findings (orchestrator rules — do NOT fix):
- Question copy “seven times six” vs “four times nine” and digit content (“4”+caret vs empty/carets): runtime state per orchestrator item 7 / DATA OVER MOCKS. Never hard-code design numbers.
- Status time/glyphs (9:41 vs 07:05/07:06): ignored per STATUS BAR rule. Home-indicator pill in design vs none in simctl shot: gallery mock only.
- Coin “120”, avatar “M” lilac, “Hi Maya!” copy: match DB/design.

What matches (element-by-element):
- Presence/order/copy: lock tile → title → instruction → question → digits → keypad (1–9, 0, delete) → “Back to Pip” → caption. Copy character-for-character with the HTML source.
- Scrim/backdrop (orchestrator item 1): FIXED. Full-screen barrier dims the whole kid screen including header and status-bar area; bands 0–1 now ~1.2–1.5%. Header “Hi Maya!” peeks dimmed above the card exactly like the design; no bright header, no status-bar collision.
- Shapes (background/border rects, not just glyphs): modal x24 w342 radius 32, lock tile 52, digit boxes 56×64 row, key circles match design diameter in row 1 (row height 72.0 in both), delete/lock icons match, no overflow/clipping/ellipsis, dark-mode surfaces/rings correct (dark keys white ring, no shadow).
- Alignment: side gutters exact; rows centred; nothing a few px off horizontally.
- Bottom edge owner rule: no bottom bar on this screen; scrim + shared kid meadow run full-bleed to the physical edge, no strip under a bar. Kid hills visible bottom 0 in both (shared scope, not local paint).
- Pip: covered by the card in both design and app; header child data correct (Maya). No v1 SVG visible.

Deviations (design → app + fix):

1. Keypad row pitch too tall — FAIL (orchestrator item 5 open).
   Design row tops 344 / 426 / 508 / ~590 (pitch 82); app 344 / 432 / 520 / 608 (pitch ~88: Δ 0, +6, +12, +18 cumulative).
   Fix: match the HTML keypad gap (row gap 16 with 72 keys, not 88 pitch); pin rows 2–4 tops to 426 / 508 / 590 ±2 in the geometry test.

2. Modal bottom / cancel / caption pushed down +26 — FAIL (orchestrator items 2, 6 open).
   Design bottom 777.7 (712 tall), cancel top 696.3, footnote ~748; app bottom 803.7 (738 tall), cancel top 724.0.
   Fix: with top fixed at 66, restore the exact bottom stack per CSS (keypad +16 → cancel min-height 56 margin-top 12 → note margin-top 10 → 20 bottom padding) so bottom returns to 778±2 and cancel centre to 702±2. Do not let the taller keypad pitch stretch the card.

3. (Consequence, no separate fix) Bands 4–5 (~11%) and light band 7 (13.38%) are fully explained by 1–2 plus expected question/digits state differences. Top-half geometry (orchestrator items 1–4: scrim, card top, title 168/155→now exact, question 228/215→now exact, boxes/row 1) is verified fixed this iteration.

Builder targets for iteration 3: keep top/title/question/row 1 as-is; fix keypad pitch to 82 and re-pin card bottom 778, cancel centre 702, footnote 748, with the scrim/barrier test (0,0)→full-size from ORCHESTRATOR_NOTES item 7.

VERDICT: FAIL
