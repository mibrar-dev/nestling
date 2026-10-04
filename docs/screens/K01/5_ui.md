# K01 · Who's playing? — Stage 5 (UI CHECK, iteration 1)

Route `/who-is-playing` · mode kid · seed demo · child maya · simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh "$PWD/app" /who-is-playing "$PWD/docs/screens/K01/ui/app_light_1.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light demo kid maya` → `docs/screens/K01/ui/app_light_1.png`
- Same with `dark` → `docs/screens/K01/ui/app_dark_1.png`
- `python3 tools/screens/compare.py design/screens/light/K01-profile-picker.png docs/screens/K01/ui/app_light_1.png docs/screens/K01/ui/cmp_light_1.png`
- `python3 tools/screens/compare.py design/screens/dark/K01-profile-picker.png docs/screens/K01/ui/app_dark_1.png docs/screens/K01/ui/cmp_dark_1.png`
- Compare images READ (not attached): `docs/screens/K01/ui/cmp_light_1.png`, `docs/screens/K01/ui/cmp_dark_1.png`.

## Mean diff + bands

Light: mean diff 6.10%

```
band  y-range    diff%
  0      0-105    1.78%
  1    105-211    2.02%
  2    211-316    6.27%
  3    316-422    3.67%
  4    422-527    7.02%
  5    527-633   10.23%
  6    633-738   10.86%
  7    738-844    6.94%
```

Dark: mean diff 5.62%

```
band  y-range    diff%
  0      0-105    1.77%
  1    105-211    2.02%
  2    211-316    5.77%
  3    316-422    3.60%
  4    422-527    6.69%
  5    527-633    9.75%
  6    633-738    9.06%
  7    738-844    6.29%
```

Bands 5–6 carry the tile-bottom + caption + meadow drift in both themes.

## Measured positions (logical px, ÷3; design vs app)

| Element | Design light | App light | Design dark | App dark | ±2 px? |
|---|---|---|---|---|---|
| Title "Who's playing?" top (first dark/light row, x 60–330) | 129 | 129 | 129 | 129 | PASS |
| Sub "Tap your face to start" top | 190 | 190 | 190 | 190 | PASS |
| Lock button (first control): white rect, x=342 vertical | 48.0–101.7, border x 333–350 | 48.0–101.7, border x 333–350 | same | same | PASS |
| Left tile top border (x=30) | 297.7 | 314.3 (+16.6) | 297.7 | 314.3 (+16.6) | FAIL |
| Left tile bottom border (x=30) | 640.0 | 656.3 (+16.3) | 640.0 | 656.3 (+16.3) | FAIL |
| Right tile top (white start, x=216) | 299 | 315 (+16) | — (same code path) | — | FAIL |
| Tile left/right edges at y=400 | 21 / 185 / 204 / 368 | 21 / 185 / 204 / 368 | 21 / 185 / 204 / 368 | 21 / 185 / 204 / 368 | PASS |
| Caption first text row (x=195 gap) | 747.0 | 781.0 (+34) | 742-equiv | 781-equiv | FAIL |
| Meadow top at left gutter (x=30) | 646 | 752 (+106) | 646 | 751 (+105) | FAIL |

Tile height matches (design 342.3 vs app 342.0); the whole tiles band is shifted down, not resized.

## Element-by-element

- Presence/order: title, sub, 2 tiles (Maya then Leo, CHILD ORDER ok), lock, caption, meadow — all present, correct order. No overflow, clipping, or ellipsis faults at 390 px.
- Copy (visual): "Who's playing?" / "Tap your face to start" / "Maya" / "Age 7–9" / "Leo" / "Age 4–6" / "Grown-ups: tap the lock to get back to your dashboard." all match. Note: HTML source uses ASCII `'` in the title (`K01-profile-picker.html:42`) while the app renders U+2019 per `1_plan.md` §0 and house convention (P02/P03/P04/P07 all ship U+2019); ages use `&ndash;` (U+2013) in both. Not counted as a defect.
- Alignment/gutters: tile outer edges identical (21/185/204/368), 20 px side gutters, lock at x 314–370 — PASS. Tiles are aligned to each other; the band itself is displaced.
- Sizes: tile width/gap/border-3/radius-32, lock 56×56 r18, avatar s96 look, pet circle 132 look — widths match at y=400; vertical shift corrupts chord-width spot checks but shapes match visually.
- Colours: tile border ink (30,27,58) both; dark tile border near-white both; sky gradient within ~5 units (design (224,239,255) vs app (219,238,255) at y250 — gradient-stop variance, negligible). Meadow bottom differs: design (204,237,192, hill-front tint) vs app (191,232,176, flat hill-back) — see D3.
- Radii/shadows: r-xl tiles, 56-lock r18, kid shadow under tiles visible in both — PASS.
- Icons: lock padlock glyph matches; no v1 `pip_stage_*.svg` used — PASS.
- Bottom edge (OWNER RULE): no bottom bar on this screen; meadow runs to the physical edge in both app shots, no strip under a bar — PASS.
- Status bar / home pill: design 9:41 vs sim clock, design home pill vs sim no pill — ignored per STATUS BAR rule (OS-drawn). Not findings.
- Dark mode: same geometry shift as light; dark tokens flip correctly (tile surface dark, border near-white, pet tints dark). Same fails as light.

## Deviations (design value → app value + fix)

1. D1 — Tiles band ~16.5 px too low. Design tile top 297.7 → app 314.3; bottom 640.0 → 656.3 (light and dark identical). Title/sub/lock are exact, so the extra space is between the sub and the tiles band. Violates the ±2 px rule and the UI VERDICT RULE (uniform shift = FAIL). Fix: reduce the space above the tiles band / re-centre `.k1-mid` so tile tops land at 297–299 (feature dir: `profile_picker_view.dart` tiles-band layout; see `2b` layout-notes deviation — fixed header/footer vs plan `Expanded`-in-scroll).
2. D2 — Caption ~34 px too low (consequence of D1 plus band weighting). Design caption top 747 → app 781. Fix: with D1 corrected, re-pin caption so its first row lands at 747 (light) with the 16 px band→caption gap and 32 px bottom pad per plan.
3. D3 — Meadow hill geometry wrong (shared `KidScope`, not fixable in feature dir). Design: two-tone hills rising behind the tiles (meadow top at gutter y 646; centre hill-back crest high). App: single flat hill below the tiles (meadow top at gutter y 752, +106). The tiles overlap the meadow in the design but sit fully on blue in the app. Fix: shared — reshape `KidScope` meadow to the 136 px two-hill SVG (`hill-back` + `hill-front` overlay); file `SHARED_REQUEST.md` if the loop requires it.
4. D4 — Meadow bottom colour is hill-back only (consequence of D3). Design bottom (204,237,192, hill-front `color-mix` bake per SPACING §9.14) → app (191,232,176). Fix: with D3, restore the lighter hill-front overlay colour.
5. D5 — Leo Pip artwork differs (INTENTIONAL, not a defect — PIP orchestrator rule overrides the design). Design shows yellow hatchling with eggshell for Leo; app correctly renders the child's OWN Pip via `PipAvatar` (Bolt·sky·stage 2, blue). Maya (Mochi·sunny·stage 3, yellow) matches. No fix; noted so the heat-map red on Leo's pet circle is not mistaken for a regression.
6. D6 — Sky gradient tint differs by ~5 units at mid-screen (design (224,239,255) vs app (219,238,255)). Below designer-reject threshold; noted only. No fix.

Bands 2–6 red is accounted for by D1–D4; bands 0–1 (≈2%) is status-bar-glyph + anti-alias noise only.

VERDICT: FAIL
