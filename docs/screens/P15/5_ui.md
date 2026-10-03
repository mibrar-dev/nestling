# P15 · Child profile — Stage 5 (UI check) — iteration 2

Route `/child-profile` · simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB (390×844) · `CHILD=maya`, `SEED=demo`, parent mode.
`ORCHESTRATOR_NOTES.md` (18:15) exists — every item checked below.

## Captures

- `ui/app_light_2.png` ← `shot.sh "$PWD/app" /child-profile … light demo parent maya` (absolute OUT path; bare-relative OUT resolves under `app/` after the script's `cd`, so `cp` fails)
- `ui/app_dark_2.png` ← same with `dark`
- `ui/cmp_light_2.png`, `ui/cmp_dark_2.png` ← `compare.py` sheets (design | app | diff)

## Mean diff

- Light: **0.99%** (was 1.21; bands: 0: 1.59, 1: 0.11, 2: 0.68, 3: 1.84, 4: 0.45, 5: 0.42, 6: 0.30, 7: 2.50)
- Dark: **0.92%** (was 1.13; bands: 0: 1.57, 1: 0.11, 2: 0.63, 3: 1.28, 4: 0.43, 5: 0.45, 6: 0.26, 7: 2.61)
- Bands 4–5 (list rows) fell 1.37/1.39 → 0.42/0.45: the subtitle starvation is gone. Residual bands: 0 = status-bar time/glyphs (design `9:41`, app real clock — ignored per STATUS BAR ruling, OS-drawn); 3 = Pip art swap (PIP ruling: v1 SVG → `PipAvatar` Mochi·sunny·stage 3 in the same 84 slot) + `18`→`4` (DATA OVER MOCKS); 7 = home-indicator pill in design PNG, absent in `simctl` captures (OS-drawn).

## Measured y (logical px, 390×844; design vs app)

- Hero card top **47 vs 47** (both themes); stats **227 vs 227**; Pip card **325 vs 325**; list **457 vs 457**; danger card **653 vs 653**; danger bottom/tab top **727 vs 727** (paper→surface scans at x=195/x=60, light exact; dark edge sequences match).
- Screen title `Maya` ink rows: light **151–163 vs 151–163**; dark **152–163 vs 152–163** (1 px rounding, within tolerance).
- First control (avatar `M` circle, hero): centred in card, identical rows both images (band 1 diff 0.11% — noise floor).
- No uniform shift; every element within ±2 px.

## Orchestrator items

1. **Subtitles render in FULL** — fixed: `On · Maya knows their code`, `6 active · 4 daily, 2 weekly`, `£3.00 a week · Owed £4.20` all on one line, no `…`, light and dark (rightmost-ink extents identical design vs app in all three rows).
2. **Row icons** — fixed: Quests tile is the circled check (circle + check, as the HTML), Pocket money tile is the gold leaf coin; lock tile unchanged and matching.
3. **Pronoun `their`** — kept per orchestrator decision; not a finding.
4. **Quest counts (`4`, `4 daily, 2 weekly`)** — DB-driven per ruling; not findings.

## Element-by-element (design vs app_2)

Presence/order/copy/spacing/sizes/alignment/colours/radii/shadows/icons/ellipsis/dark-mode: hero (`M`, `Maya`, `Age 7–9 · Pip is a Fledgling` — U+2013/U+00B7 exact), stats 3-up (equal height, 10 gap, `Quests this week` wraps ×2), Pip card (`Pip · Fledgling`, `Evolves at 250 total coins`, 70% bar, `175 of 250 · 70%`), three list rows (titles, full subtitles, `Change ›`/U+203A `›` trailings), danger card (`Remove Maya from family`, 48 high, dangerGhost), tab bar (Family active). Gutters 20–369 on every band. Bottom edge: below-tab area is tab-bar `surface` to the physical edge, light (white) and dark (#1F1C2E) — no strip. Dark theme flips per tokens (danger → light red, tiles correctly tinted).

## Deviations

None remaining. Every residual pixel difference is covered by an orchestrator ruling (status bar, PIP art, DB numbers) or OS-drawn chrome (home indicator).

VERDICT: PASS
