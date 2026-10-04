# K01 · Who's playing? — Stage 5 (UI CHECK, iteration 2)

Route `/who-is-playing` · mode kid · seed demo · child maya · simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
No code edited in this stage. ORCHESTRATOR_NOTES.md applied: D3/D4 meadow hills are shared (not K01 findings); D5 Leo's own Pip is correct.

## Captures

- `bash tools/screens/shot.sh "$PWD/app" /who-is-playing "$PWD/docs/screens/K01/ui/app_light_2.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light demo kid maya` → `docs/screens/K01/ui/app_light_2.png`
- Same with `dark` → `docs/screens/K01/ui/app_dark_2.png`
- `python3 tools/screens/compare.py design/screens/light/K01-profile-picker.png docs/screens/K01/ui/app_light_2.png docs/screens/K01/ui/cmp_light_2.png`
- `python3 tools/screens/compare.py design/screens/dark/K01-profile-picker.png docs/screens/K01/ui/app_dark_2.png docs/screens/K01/ui/cmp_dark_2.png`
- Compare images READ (not attached): `docs/screens/K01/ui/cmp_light_2.png`, `docs/screens/K01/ui/cmp_dark_2.png`.

## Mean diff + bands

Light: mean diff 1.53% (was 6.10% in iteration 1)

```
band  y-range    diff%
  0      0-105    1.56%
  1    105-211    0.25%
  2    211-316    0.84%
  3    316-422    0.13%
  4    422-527    0.53%
  5    527-633    6.85%
  6    633-738    0.82%
  7    738-844    1.20%
```

Dark: mean diff 1.32% (was 5.62%)

```
band  y-range    diff%
  0      0-105    1.57%
  1    105-211    0.28%
  2    211-316    0.86%
  3    316-422    0.14%
  4    422-527    0.51%
  5    527-633    5.09%
  6    633-738    0.91%
  7    738-844    1.19%
```

Band 0 ≈ status-bar glyphs (OS-drawn, ignored). Band 5 = pet-circle/Pip-art zone (DB-driven art, see D5). All layout bands (1–4, 6–7) ≤ 1.2%.

## Measured positions (logical px, ÷3; design vs app)

| Element | Design light | App light | Design dark | App dark | ±2 px? |
|---|---|---|---|---|---|
| Title "Who's playing?" top (first text row, x 60–330) | 129.0 | 129.0 | 129.0 | 129.0 | PASS |
| Sub "Tap your face to start" top | 190 | 190 | 190 | 190 | PASS |
| Lock button (first control): white rect, x=342 vertical | 48.0–101.7, border x 333–350 | 48.0–101.7, border x 333–350 | same | same | PASS |
| Left tile top border (x=30) | 297.7 | 297.3 (−0.4) | 297.7 | 297.3 (−0.4) | PASS |
| Right tile top (white start, x=216) | 299 | 299 | — (same code path) | — | PASS |
| Left tile bottom border (x=30) | 640.0 | 639.3 (−0.7) | 640.0 | 639.3 (−0.7) | PASS |
| Tile left/right edges at y=400 | 21 / 185 / 204 / 368 | 21 / 185 / 204 / 368 | 21 / 185 / 204 / 368 | 21 / 185 / 204 / 368 | PASS |
| Caption first text row (x=195 gap) | 747.0 | 747.0 | 746.7 | 747.0 | PASS |
| Meadow top at left gutter (x=30) | 646.3 | 645.7 | ~646 | 645.7 | PASS |

D1 (tiles +16.5 px) and D2 (caption +34 px) from iteration 1 are fixed. Tile height unchanged (342.3 vs 342.0); the band now sits exactly on the design.

## Element-by-element

- Presence/order: title, sub, 2 tiles (Maya then Leo, CHILD ORDER ok), lock, caption, two-tone meadow hills — all present, correct order. No overflow, clipping, or ellipsis faults at 390 px.
- Copy (visual): "Who's playing?" / "Tap your face to start" / "Maya" / "Age 7–9" / "Leo" / "Age 4–6" / "Grown-ups: tap the lock to get back to your dashboard." all match. HTML source uses ASCII `'` in the title while the app renders U+2019 per `1_plan.md` §0 and house convention; ages use `&ndash;` (U+2013) in both. Not a defect.
- Spacing/sizes: tile width/gap/border-3/radius-32, lock 56×56 r18, avatar s96 look, pet circle 132 look — background/border rects match (edges identical at y=400, tops/bottoms within 1 px).
- Alignment: 20 px side gutters, tiles/lock/caption aligned to the same edges — PASS.
- Colours: tile border ink (30,27,58) light / near-white dark both; pet tints lilac/peach (and dark variants); meadow two-tone hills present in both themes — PASS.
- Radii/shadows: r-xl tiles, r18 lock, kid shadow under tiles visible in both — PASS.
- Icons: lock padlock glyph matches; no v1 `pip_stage_*.svg` used — PASS.
- Bottom edge (OWNER RULE): no bottom bar on this screen; meadow runs to the physical edge in both shots, no strip — PASS.
- Dark mode: same geometry as light; tokens flip correctly — PASS.
- Status bar / home pill: design 9:41 vs sim clock, design home pill vs sim none — OS-drawn, ignored per STATUS BAR rule. Not findings.

## Deviations (design value → app value + fix)

1. D5 — Pip artwork differs (INTENTIONAL, not a defect — PIP orchestrator rule overrides the design PNGs; DB-driven content is excluded from the ±2 px verdict). Design shows v1 fledgling (Maya, green wings) and yellow hatchling in shell (Leo); app correctly renders each child's OWN `PipAvatar` (Maya Mochi·sunny·stage 3, Leo Bolt·sky·stage 2). This accounts for band 5 residual (6.85% light / 5.09% dark). No fix.
2. D6 — Sky-gradient tint differs by ~5 units mid-screen (negligible interpolation variance). No fix.
3. Band-0 residual (~1.6%) is status-bar glyphs only (OS-drawn). No fix.
4. Faint text outlines in the diff heat-map are font anti-aliasing only. No fix.
5. D1/D2 (iteration 1: tiles +16.5 px, caption +34 px) — FIXED this pass, verified above. D3/D4 (meadow) — shared per ORCHESTRATOR_NOTES, and the shared fix has landed (two-tone hills now render); no local action.

No visible deviation a designer would reject remains.

VERDICT: PASS
