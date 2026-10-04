# P15 · Child profile — Stage 5 (UI check) — iteration 4

Route `/child-profile` · simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844) · `CHILD=maya`, `SEED=demo`, parent mode.
`ORCHESTRATOR_NOTES.md` (18:15) unchanged — all four items re-checked. Note: wall date is now Sun 4 Oct 2026; the demo seed anchors to TODAY, so DB-driven counts are live values (they still read `4` / `6 active · 4 daily, 2 weekly`, same London week) — excluded from the verdict per DATA OVER MOCKS either way.

## Captures

- `ui/app_light_4.png` ← `shot.sh "$PWD/app" /child-profile … light demo parent maya` (absolute OUT path; bare-relative OUT resolves under `app/` after the script's `cd`, so `cp` fails)
- `ui/app_dark_4.png` ← same with `dark`
- `ui/cmp_light_4.png`, `ui/cmp_dark_4.png` ← `compare.py` sheets (design | app | diff)

## Mean diff

- Light: **1.00%** (bands: 0: 1.66, 1: 0.11, 2: 0.68, 3: 1.84, 4: 0.45, 5: 0.42, 6: 0.30, 7: 2.50)
- Dark: **0.93%** (bands: 0: 1.64, 1: 0.11, 2: 0.63, 3: 1.28, 4: 0.43, 5: 0.45, 6: 0.26, 7: 2.61)
- Matches iterations 2–3 within 0.01 (band-0 lift is the simulator clock now reading `00:06`/`00:09`). Residuals: status-bar glyphs (ignored, OS-drawn), Pip art swap (PIP ruling), `18`→`4` + breakdown (DATA OVER MOCKS), home-indicator pill in design PNG only (OS-drawn).

## Measured y (logical px, 390×844; design vs app)

- Card tops: hero **47 vs 47**, stats **227 vs 227**, Pip **325 vs 325**, list **457 vs 457**, danger **653 vs 653**, danger bottom/tab top **727 vs 727** — both themes (the lone dark-scan blip at 249 sits inside the stats tile; the middle-cell text block measures **243–276 vs 243–276**, i.e. anti-alias noise, as established in iteration 3).
- Screen title `Maya`: **152–163 vs 152–163**, both themes.
- First control (avatar `M` circle): centred identically (band 1 diff 0.11%, noise floor).
- No uniform shift; every element within ±2 px.

## Orchestrator items

1. **Subtitles in FULL** — holds: `On · Maya knows their code`, `6 active · 4 daily, 2 weekly`, `£3.00 a week · Owed £4.20`, one line each, no `…`, light and dark.
2. **Row icons** — hold: Quests circled check, Pocket gold leaf coin, lock unchanged.
3. **Pronoun `their`** — kept per decision; not a finding.
4. **DB quest counts** — not findings.

## Element-by-element (design vs app_4)

Hero, stats 3-up, Pip card (70% bar, `175 of 250 · 70%`), three list rows (full subtitles, `Change ›`/U+203A trailings), danger button, tab bar (Family active) — present, ordered, copy-exact (U+2013/U+00B7/U+203A/U+00A3), aligned. Gutters 20–369 every band. Bottom edge: below-tab pixels equal tab-bar `surface` (True both themes) — no strip. Dark tokens correct throughout.

## Deviations

None. Every residual pixel difference is covered by an orchestrator ruling or OS-drawn chrome.

VERDICT: PASS
