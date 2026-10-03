# P15 · Child profile — Stage 5 (UI check) — iteration 3

Route `/child-profile` · simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844) · `CHILD=maya`, `SEED=demo`, parent mode.
`ORCHESTRATOR_NOTES.md` (18:15) unchanged — all four items re-checked below.

## Captures

- `ui/app_light_3.png` ← `shot.sh "$PWD/app" /child-profile … light demo parent maya` (absolute OUT path; bare-relative OUT resolves under `app/` after the script's `cd`, so `cp` fails)
- `ui/app_dark_3.png` ← same with `dark`
- `ui/cmp_light_3.png`, `ui/cmp_dark_3.png` ← `compare.py` sheets (design | app | diff)

## Mean diff

- Light: **0.99%** (bands: 0: 1.59, 1: 0.11, 2: 0.68, 3: 1.84, 4: 0.45, 5: 0.42, 6: 0.30, 7: 2.50)
- Dark: **0.92%** (bands: 0: 1.57, 1: 0.11, 2: 0.63, 3: 1.28, 4: 0.43, 5: 0.45, 6: 0.26, 7: 2.61)
- Identical to iteration 2 to the second decimal — layout stable across builds. Residuals: band 0 = status-bar clock/glyphs (ignored, OS-drawn); band 3 = Pip art swap (PIP ruling) + `18`→`4` (DATA OVER MOCKS); band 7 = home-indicator pill in design PNG, absent in `simctl` captures (OS-drawn).

## Measured y (logical px, 390×844; design vs app)

- Card tops (paper→surface scans x=195/x=60): hero **47 vs 47**, stats **227 vs 227**, Pip **325 vs 325**, list **457 vs 457**, danger **653 vs 653**, danger bottom/tab top **727 vs 727** — both themes.
- Screen title `Maya`: light **152–163 vs 152–163**; dark **152–163 vs 152–163**.
- First control (avatar `M` circle): centred identically (band 1 diff 0.11%, noise floor).
- Stats middle-cell text block (dark): **243–276 vs 243–276** (a single-row threshold blip at 249 in one scan verified as anti-alias noise, not an edge).
- No uniform shift; every element within ±2 px.

## Orchestrator items

1. **Subtitles in FULL** — holds: `On · Maya knows their code`, `6 active · 4 daily, 2 weekly`, `£3.00 a week · Owed £4.20`, one line each, no `…`, light and dark.
2. **Row icons** — hold: Quests tile circled check, Pocket tile gold leaf coin, lock tile unchanged.
3. **Pronoun `their`** — kept per decision; not a finding.
4. **DB quest counts** — not findings.

## Element-by-element (design vs app_3)

Hero (`M`, `Maya`, `Age 7–9 · Pip is a Fledgling`), stats 3-up (equal height, 10 gap, two-line label), Pip card (title, `Evolves at 250 total coins`, 70% bar, `175 of 250 · 70%`), three list rows (full subtitles, `Change ›`/U+203A trailings), danger button, tab bar (Family active) — all present, ordered, copy-exact (U+2013/U+00B7/U+203A/U+00A3), aligned. Gutters 20–369 every band. Bottom edge: below-tab pixels equal tab-bar `surface` (True both themes) — no strip. Dark tokens correct throughout.

## Deviations

None. Every residual pixel difference is covered by an orchestrator ruling or OS-drawn chrome.

VERDICT: PASS
