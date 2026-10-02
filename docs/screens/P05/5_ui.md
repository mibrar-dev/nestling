# P05 · Add children — UI check (STAGE 5, iteration 1)

Route `/add-children`, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844).
Shots: `SEED=fresh`, parent mode, `THEME=light|dark` (mandated command).
Comparisons: `tools/screens/compare.py` vs `design/screens/light|dark/P05-add-children.png`.

- Light: `docs/screens/P05/ui/app_light_1.png` vs design → `cmp_light_1.png`, **mean diff 6.61%**
- Dark: `docs/screens/P05/ui/app_dark_1.png` vs design → `cmp_dark_1.png`, **mean diff 6.76%**

Per-band drift (light): band0 0–105: 2.79% · band1 105–211: 11.88% · band2 211–316: 3.82% ·
band3 316–422: 4.57% · band4 422–527: 5.04% · band5 527–633: 19.21% · band6 633–738: 1.77% ·
band7 738–844: 3.71%. Dark is near-identical (band1 12.26%, band5 21.22%).

No Pip slot on this screen (avatar initials only) → PIP rule N/A.
Status-bar time/glyphs and home-indicator pill ignored (OS-drawn; `NestStatusBar` reserves height only).

## Deviations

1. [FAIL — blocks gate] Age-band chips render as 4 stacked full-width rows.
   Design: one row of 4 pills (`4–6`, `7–9` selected, `10–12`, `13+`), `gap 8`, form card ≈298 px tall.
   App (light + dark): 4 centred pills stacked vertically, one per row; form card ≈170 px taller;
   bands 5 drift 19–21% is almost entirely this. Same defect as review finding 1 / P05-BUG-1 /
   `SHARED_REQUEST.md` #3 (interactive `NestChip`'s factorless `Center` claims the full `Wrap`
   run width). A designer would reject this on sight.
   Fix: shared `nest_chip.dart` fix (e.g. `Center(widthFactor: 1, heightFactor: 1)` keeping the
   44-min tap area on the pill itself), already filed as blocking; or P05-local
   `IntrinsicWidth(child: NestChip(...))` per review evidence (2 rows max at 320 px / 1.3×, 1 row at 390 px).

2. [Expected — not a defect] Kid cards absent (Maya/Leo).
   Design: 2 cards (Maya lilac M Age 7–9, Leo peach L Age 4–6, edit pencils); band1 drift ≈12% is this.
   App: no cards — `SEED=fresh` means zero children, and the empty form-only layout IS the P05
   empty state per `1_plan.md` §d (DATA OVER MOCKS: the database is correct, here empty).
   Fix: none in product code. Re-shoot with `demo` seed next iteration to check the grid itself
   against the design (order note: DB sorts by nickname → Leo left, Maya right; design mock shows
   Maya first — orchestrator owns that call, recorded as P05-BUG-3).

3. [Minor — filed, no action] Compact nav bar 44 px vs spec 52 px.
   Design: h1 ink ≈ y112. App: h1 ≈ y96 (whole head block sits ≈8–16 px high; part of band0/1 drift).
   Fix: shared `NestNavBar` `minHeight` change, `SHARED_REQUEST.md` #4 (blocks: no). P05 consumes the DS component as-is.

4. [Accepted — no action] Nickname field has no leaf focus ring.
   Design: field shows focused ring (HTML `autofocus` mock state).
   App: unfocused. Per review: no screen autofocuses fields — do NOT add autofocus to chase pixels.

5. [Pass] Bottom edge (owner rule): `NestBottomCta` surface runs to the physical edge in both
   modes — no coloured strip under the bar or around the home-indicator area. Band7 drift (≈3.7–3.8%)
   is only the mock-vs-OS home-indicator pill and status glyphs.

6. [Pass] Everything else matches in both modes: copy (incl. en-dashes, "Avatar colour",
   "Nicknames only — no photos, no email."), title style/position (modulo #3), 20 px gutters with
   head/card/CTA/caption on the same edges, card padding/radii/shadows, swatch row (5 × 44 px,
   peach selected with ink ring), caption text, secondary "+ Add another child" (48) + primary
   "Continue" (52) + centred caption, dark-mode tokens (surface cards on paper, leaf-tint selected
   chip, mint Continue). No overflow, clipping, or ellipsis faults at 390 px.

## Verdict basis

Deviation 1 is a visible, designer-rejectable layout break present identically in light and dark;
it is already filed as the blocking shared request. Deviation 2 is seed-mandated and must not be
"fixed" in code. All owner rules (bottom edge, alignment, PIP N/A) otherwise hold.

VERDICT: FAIL
