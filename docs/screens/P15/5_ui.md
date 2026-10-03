# P15 · Child profile — Stage 5 (UI check) — iteration 1

Route `/child-profile` · simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844) · `CHILD=maya`, `SEED=demo`, parent mode.

## Captures

- `ui/app_light_1.png` ← `shot.sh $PWD/app /child-profile … light demo parent maya` (absolute OUT path; the bare-relative OUT in the brief resolves under `app/` after the script's `cd`, so `cp` fails)
- `ui/app_dark_1.png` ← same with `dark`
- `ui/cmp_light_1.png`, `ui/cmp_dark_1.png` ← `compare.py` sheets (design | app | diff)

## Mean diff

- Light: **1.21%** (bands: 0: 1.65, 1: 0.11, 2: 0.68, 3: 1.84, 4: 1.24, 5: 1.37, 6: 0.30, 7: 2.50)
- Dark: **1.13%** (bands: 0: 1.61, 1: 0.11, 2: 0.63, 3: 1.28, 4: 1.14, 5: 1.39, 6: 0.26, 7: 2.61)
- Band 0 ≈ status-bar time/glyphs (ignored per STATUS BAR ruling; OS draws them: design `9:41`, app `18:08`/`18:09`). Band 7 ≈ home-indicator pill present in design PNG, absent in `simctl` captures (OS-drawn; no coloured strip under the tab bar in either theme — BOTTOM EDGE passes: below-tab area is tab-bar `surface` to the physical edge, light and dark).

## Expected deltas (rulings — not deviations)

- Stats value `18` → `4`; quests breakdown `3 daily, 3 weekly` → `4 daily, 2 weekly`: DATA OVER MOCKS, DB wins (matches `1_plan.md` §(b) demo numbers).
- Pip art: v1 `pip_stage_3.svg` (green wings) → `PipAvatar` Mochi·sunny·stage 3 in the same 84×84 slot: PIP ruling.
- Kid PIN subtitle pronoun `her` → `their`: builder-documented adaptation (schema has no gender; see deviation 4).

## Measured y (logical px, 390×844; design vs app, light)

Card tops via paper→surface scan at x=195 and x=60: hero **47 vs 47**, stats **227 vs 227**, Pip card **325 vs 325**, list **457 vs 457**, danger card **653 vs 653**; danger bottom/tab top **727 vs 727**. Title `Maya` ink rows **151–163 vs 151–163**. No uniform shift; every band edge within ±2 px.

## Deviations

1. **List subtitles ellipsized early (all 3 rows; light + dark) — overflow/clipping failure.** Design renders full strings; app cuts ~40–60 logical px early with `…`: `On · Maya knows t…` (design `On · Maya knows her code`, rightmost ink x 239 → 195), `6 active · 4 daily, 2…` (design `6 active · 3 daily, 3 weekly`, 237 → 198), `£3.00 a week · Ow…` (design `£3.00 a week · Owed £4.20`, 252 → 190). Even the narrow-`›` rows clip, so `list-main` is starved, not just the `Change ›` row. Fix: give the title/sub column the design's full remaining width (flex `list-main`, trailing shrink-0 with design padding only) so each subtitle fits on one line at 390 px; re-screenshot both themes.
2. **Quests row icon glyph differs.** Design tile: circle outline (r≈9) with small check inside (HTML `circle` + `check` path). App tile: plain large check, no circle (verified in @3x tile crop). Fix: use the circled-check asset (`NestIcons` entry matching the design) for the Quests row.
3. **Pocket money row icon glyph differs.** Design tile: gold coin with leaf emboss (`coin.svg`). App tile: `£` glyph in a circle (`poundCoin`). Fix: use the coin asset for the Pocket money row.
4. **Kid PIN subtitle pronoun** (design `Maya knows her code`, app `Maya knows their code` — full string unreadable in-shot due to deviation 1, per `2b_build_ui.md` copy asserts). Builder-intentional (no gender in schema); needs design sign-off, listed here for the record.
5. **Dark-mode check:** colours flip per tokens (surface/paper/ink, danger → light red, tiles tinted correctly); same three deviations (1–3) reproduce in dark; no strip under tab bar; alignment/gutters identical to light.

Alignment/owner rules otherwise pass: 20 px gutters everywhere, card/tab-bar edges share x=20/370, radii/shadows/progress (70%) match, hero avatar/stat tiles/Pip title/captions/danger button copy exact.

VERDICT: FAIL
