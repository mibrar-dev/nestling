# K02 Kid PIN (`/kid-pin`) — 5_ui (iteration 1)

Shots (simulator BC440E48-B3A3-43BC-971B-0EF5DB621874, `demo kid maya`):
- `docs/screens/K02/ui/app_light_1.png` (1170×2532, = 390×844 @3x)
- `docs/screens/K02/ui/app_dark_1.png` (1170×2532)

Compare output:
- Light: `mean diff: 5.33%`; bands 0: 1.60 (0–105), 1: 0.19 (105–211), 2: 2.07 (211–316), 3: 3.07 (316–422), 4: 11.09 (422–527), 5: 12.82 (527–633), 6: 8.79 (633–738), 7: 3.07 (738–844).
- Dark: `mean diff: 5.06%`; bands 0: 1.57, 1: 0.21, 2: 1.97, 3: 2.97, 4: 10.76, 5: 11.99, 6: 7.96, 7: 3.09.
- Bands 4–6 (keypad zone) carry the diff; bands 0–1 (top bar/avatar) are ~0–1.6% (status-bar chrome + font raster only).

Method: logical px = PNG px ÷ 3. Dark-ink row/column projections on design vs app (light pair; dark pair is geometrically identical per the compare sheets).

Measured Y (logical px, design vs app, Δ = app − design):
- `NESTLING` mark text rows: ~265–270 vs ~265–270 → Δ 0.
- Say title `Hi Maya! Enter your secret code`: rows ~292–305 both → Δ 0.
- PIN dots block: 331–365, dots 340–358 both; x-segments identical 141–159 / 171–189 / 201–219 / 231–249 (18 px dots, 12 px gap, total x 141–249) → Δ 0.
- Keypad row tops: R1 393–395 vs 393–395 (Δ 0); R2 ~473–475 vs ~483–485 (Δ +10); R3 ~558–560 vs ~568–570 (Δ +10); R4 ~638–640 vs ~658–660 (Δ +20). R4 bottom ~710–715 vs ~725–730 (Δ +15–18).
- Key columns, row-1 left edges: design 77 / 159 / 241 (pitch 82, grid x 77–313, w 236) vs app 63 / 159 / 255 (pitch 96, grid x 63–327, w 264). Centre column aligned; outer keys Δ −14 (left) / +14 (right).
- Key size 72 circle both (mid-slice chord ~70 in both — circle curvature, not a size change).
- Caption `Forgot it? Just ask a grown-up.`: top ~737 (rows 740/745) vs ~763 (rows 765/770) → Δ +26.
- Avatar disc: lilac span x 131–259 (128) identical both. Lock-button row white segments identical. Bottom-centre meadow px identical `[204, 237, 192]`.

## Deviations

1. Keypad column pitch (SHARED — `NestKeypad`, fix on `shared/keypad_grid`, do not fix in K02). Design: col pitch 82, grid x 77–313. App: col pitch 96, grid x 63–327. Outer keys ±14 px off (e.g. left key left edge 77 vs 63). Exceeds ±2. Fix: shared keypad grid gap 24 → design 10 (ORCHESTRATOR_NOTES mandatory item; plan SHARED_REQUEST #2). K02 takes the component as-is.
2. Keypad row pitch (same SHARED root cause). Design row pitch 82 (R1 393, R2 ~473, R3 ~558, R4 ~638). App pitch ~88–90 (R1 393, R2 ~483, R3 ~568, R4 ~658): R2 Δ +10, R3 Δ +10, R4 Δ +20, R4 bottom Δ +15–18. Exceeds ±2. Fix: shared row gap 16 → design 10; re-shot after main lands it.
3. Caption vertical position (downstream of #2, no local fix). Design top ~737, app top ~763 (Δ +26) — the taller keypad pushes the 20 px-gap caption down. Resolves with the shared keypad fix; K02 layout (gap 20, scroll pad 32) already matches the HTML.
4. Home-indicator mock pill: design draws the 134×5 mock pill (y 825–829, x 128–262); simctl app shot shows none (transparent bottom spacer per plan §9; the OS draws the real indicator). Chrome difference, not a product defect — no fix.
5. Status-bar time/glyphs (07:46 + simulator icons vs 9:41 mock): ignored per STATUS BAR orchestrator rule — no fix.

Not deviations (checked, passing):
- Presence/order: back, lock, avatar, mark pill, greeting, dots, 10 digit keys + blank + delete, caption — all present, in design order.
- Copy (vs HTML source char-by-char): `NESTLING`, `Hi Maya! Enter your secret code` (no trailing period, as in source line 38), `Forgot it? Just ask a grown-up.` (period) — exact in both themes.
- Dots fill: design shows 2 filled (illustrative mid-entry mock, aria `Two of four digits entered`); app shows 0 filled = correct empty initial state. Position identical; state difference is correct behaviour, not a defect.
- Avatar/mark/say/dots/top-bar/meadow geometry: Δ 0 (see table). Key shape/size, 3 px kid borders, kid shadows, pill radii, lock 56×r18 surface + line border — match.
- Alignment: 20 px side gutters, centred avatar/dots/keypad/caption — no off-by-px element outside the keypad grid.
- Bottom edge (owner rule): no bottom bar on this screen; meadow runs to the physical edge in both themes, no strip — PASS.
- Dark mode: same geometry as light; colours correct (dark sky, dark-navy keys with light borders, empty dots light-bordered, lilac disc dark tint + lavender M, caption ink-2). No dark-only deviation.
- No `£`, no Pip slot on this screen (avatar only — PIP rule N/A), no chip rows (N/A), no balanced heading in K02 CSS (N/A).

UI VERDICT RULE audit: keypad rows/cols (up to ±14 col, +20 row) and caption (+26) exceed ±2 px — including as a uniform keypad-block shift. FAIL.

VERDICT: FAIL
