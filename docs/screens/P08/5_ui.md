# P08 · Today (home) — UI check (Stage 5, iteration 3)

Route `/today`, mode parent, seed demo, child maya, simulator BC440E48-B3A3-43BC-971B-0EF5DB621874.
`docs/screens/P08/ORCHESTRATOR_NOTES.md` (4 items + K03-BUG-4 periods ruling) all
mandatory and verified. No code edited this stage. Per the new process rule,
branch/commit/merge state is not reported.

## Shots + diffs

- `bash tools/screens/shot.sh "$PWD/app" /today "$PWD/docs/screens/P08/ui/app_light_3.png" BC440E48-B3A3-43BC-971B-0EF5DB621874 light demo parent maya` (absolute OUT; relative breaks `shot.sh`)
- Same with `dark` → `app_dark_3.png`. Both runs again printed the 25 s
  never-stabilised warning yet saved complete, fully-loaded, mutually consistent
  frames (carried note, see 6).
- `python3 tools/screens/compare.py design/screens/light/P08-today.png docs/screens/P08/ui/app_light_3.png docs/screens/P08/ui/cmp_light_3.png` (and dark).

| Theme | Mean diff (iter 1 → 2 → 3) | Bands (y-range: diff%) |
|---|---|---|
| Light | 6.67% → 5.03% → **5.03%** | 0–105: 5.75 · 105–211: 5.40 · 211–316: 3.25 · 316–422: 5.94 · 422–527: 3.12 · 527–633: 5.93 · 633–738: 5.32 · 738–844: 5.49 |
| Dark | 6.55% → 4.82% → **4.81%** | 0–105: 5.92 · 105–211: 4.65 · 211–316: 3.40 · 316–422: 4.57 · 422–527: 3.13 · 527–633: 6.00 · 633–738: 5.53 · 738–844: 5.27 |

Both app shots + both compare sheets read with the file reader. Pixel-measured with
PIL (÷3): card-fill spans, bottom-strip vs tab-bar colours.

## Owner rules (both PASS, measured)

- **BOTTOM EDGE: PASS.** Strip below the tab bar (bottom 32 px) is pure white in
  light and `#1F1C2E` in dark — pixel-identical to each theme's tab-bar surface.
  No coloured strip under the bar or around the home area in either theme.
- **ALIGNMENT: PASS.** Banner fill x 60→1109, quest-card fills x 60→1109
  (physical) = exactly **20.0 px** logical gutters left and right (±0.3 sub-pixel).
  Cards, banner and (by the same grid) kid cards share edges; nothing off-gutter.

## Element check vs design (all hold from iter 2)

1. **Pips** — Maya Mochi·sunny S3, Leo Bolt·sky S2 via `PipAvatar` from DB fields;
   72×72 centred slots kept. Band-3 heat is the mandated art change, not a defect.
2. **Banner** — "3 quests waiting for your thumbs-up" + "Maya and Leo did
   brilliantly yesterday" + Review; geometry matches both themes.
3. **Quest rows** — 16 px gaps (rows level with design); status order
   pending → to-do → approved; meta reads "· Daily"; coin → repeat → chip order.
4. **Header/cards/chrome** — greeting, `+`/`S` actions, 2-up cards, "Today's quests"
   + "See all", "MAYA · 9" group label, tab bar states all match; dark flips clean
   with zero theme branches.

## Data-driven, not deviations (mandatory rules)

5. **Leo "1 of 4 quests" (was "2 of 4" in iters 1–2).** Live count under the
   mandatory PERIODS ruling + today-anchored seed: a completion aged out of the
   current London day. Internally consistent — bar ≈ 25 %, Maya 4/6 ≈ 67 %, banner
   total still 3 (2 Maya + 1 Leo pending). Design's "2 of 4" is a static mock;
   per DATA OVER MOCKS the database value is correct.
6. **Row-2 identity** ("Lay the table" vs mock "Reading – 20 minutes", which sits
   at app row 3 as To do) — same rules: ordering rule satisfied, membership is
   live data.
7. **"Fri 2 Oct" vs "Sat 4 Oct", status-bar time** — live date/OS chrome; ignored
   per rules. Banner-title wrap stays the accepted `text-wrap: balance` substitution.

## Carried queries (not P08 defects, no change)

- Dishwasher tile glyph (mock padlock/bag vs design-system appliance, plan §a.8):
  designer sign-off still owed; P08 may not change shared icons.
- Money tab icon (card vs banknote): shared ParentShell chrome, for the
  orchestrator/shared loop.
- `shot.sh` stabilisation warnings persist on both themes; saved frames are
  complete and consistent. Churn source still unidentified — worth one
  motion-rule look (RULES §6), but nothing rendered is mid-animation.

## Coverage limit

Viewport only (through Maya row 2 + partial row 3); Leo's group, lower rows and
"Hand to Maya or Leo" are below the fold — same scope as the 390×844 design PNG.

VERDICT: PASS
