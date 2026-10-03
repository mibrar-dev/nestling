# K03 Kid home — UI check (Stage 5, iteration 12)

Method (simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB only; 390x844):
- `bash tools/screens/shot.sh "$PWD/app" /kid-home "$PWD/docs/screens/K03/ui/app_light_12.png" <udid> light demo kid maya` -> valid K03 light (14:59). Same with `dark` -> valid K03 dark (15:00). Absolute OUT paths used. Both `stable frame saved`, no warnings, no contamination.
- `python3 tools/screens/compare.py design/screens/light/K03-kid-home.png docs/screens/K03/ui/app_light_12.png docs/screens/K03/ui/cmp_light_12.png` (and dark). Read all four images. Logical px (PNG/3).
- Verdict under the UI VERDICT RULE (±2px every element excl. OS glyphs + DB content; title/first-control/card-top y reported).

Results:
- light mean diff: 6.54% — bands: 0: 1.85% · 1: 3.58% · 2: 13.06% · 3: 12.42% · 4: 2.75% · 5: 5.27% · 6: 6.67% · 7: 6.73%
- dark mean diff: 5.61% — bands: 0: 1.86% · 1: 3.06% · 2: 10.66% · 3: 9.64% · 4: 2.57% · 5: 5.51% · 6: 6.14% · 7: 5.42%
- TAIL FIXED (the sole iter11 deviation): column profile x=195 shows the tail now INK-filled in app (KKKKK after bubble border) exactly like the design (KKKK, HTML `border-top ink` triangle); extents within 1-2px (design ~167-175 vs app ~168-177). The iter11 white-filled tail is gone. Body x/y/w unchanged.
- Position chain (all within ±2px, both themes): title top 489; lock bbox identical; card-1 check top-left identical; card tops 559/659; card bottoms; hearts 443; progress borders + x-extent; dock top 719-721; nest width/centre; bottom edge dock-surface; gutters 20px.
- Pet bands 2-3 residual is mandated-ART outlines only (v2 Pip/nest drawings vs v1): slot positions proven by the green widget-geometry pins (nest 278±2/364±2, centre 195±1, Pip feet 301±3, hearts 448±2, card-1 559±2); downstream chain exact, so no layout shift. The v2 crown-vs-v1-spikes column difference is interior art, not position.
- Dark meadow holds pixel-identical; bottoms correct; code: `NestBalancedText` present, no `GoogleFonts`, copy U+0027 exact.

Accepted / overridden: A1 counts+fill (DATA+PERIODS); A2 card-2 content (alphabetical wins); A3 v2 art (mandated); A4 status clock; A5 band-7 PNG delta (override-required); A6 dark glow (SHARED pet_glow, not a finding); A7 title size (pre-declared).
- No open deviations. Nothing is locally actionable; nothing further needs a shared route for the visual pass (tile tint already implemented on main).

VERDICT: PASS
