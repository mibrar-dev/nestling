# P12 · Money (ledger) — Stage 5 UI check (iteration 1)

Route `/money`, simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /money $PWD/docs/screens/P12/ui/app_light_1.png BC440E48-B3A3-43BC-971B-0EF5DB621874 light demo parent maya` → stable frame saved.
- Same with `dark` → `app_dark_1.png`.
- NOTE: the brief's relative `docs/screens/P12/ui/…` OUT path fails (`cp: … No such file or directory`) because `shot.sh` `cd`s into `$APP_DIR` before copying, so a relative OUT resolves under `app/`. Absolute `$PWD/…` OUT paths were used instead. No script edit made (shared file).
- `python3 tools/screens/compare.py design/screens/light/P12-money.png docs/screens/P12/ui/app_light_1.png docs/screens/P12/ui/cmp_light_1.png`
- `python3 tools/screens/compare.py design/screens/dark/P12-money.png docs/screens/P12/ui/app_dark_1.png docs/screens/P12/ui/cmp_dark_1.png`

## Mean diff

- Light: **10.46%** (bands: 0: 8.42, 1: 14.13, 2: 9.00, 3: 22.07, 4: 10.92, 5: 7.83, 6: 8.77, 7: 2.51)
- Dark: **8.22%** (bands: 0: 8.56, 1: 4.81, 2: 8.76, 3: 14.54, 4: 10.26, 5: 7.63, 6: 8.64, 7: 2.60)

Both means are dominated by rule-accepted differences (status bar, seeded-DB rows/date); chrome band 7 matches at ~2.5% in both themes. Compare PNGs read at full resolution alongside both app screenshots and both design PNGs.

## Element-by-element

Checked against `design/html-source/screens/P12-money.html` (copy source of truth): title, segmented Maya|Leo, hero (lab/amount/breakdown/button), goal card (coin art, title with em dash U+2014, caption with middle dot U+00B7, progress), history header + rows (tile 40×40 r12, gap 12, min-h 56, no dividers, ellipsis, per-type icon/tint/title/sub/amount incl. minus U+2212 on spend and unsigned payout), tab bar, gutters (20 px, cards/bars share x 20…370), radii, shadows, dark-mode tokens. Row buttons + footer caption sit below the fold in BOTH design and app (identical fold behaviour); their copy/geometry is covered by the 12 passing widget tests.

## Numbered deviations

1. Status bar — design: mock `9:41` + mock glyphs; app: OS `12:00`/`12:04` + real icons. Fix: none — ignored per orchestrator STATUS BAR rule (NestStatusBar only reserves height).
2. Hero breakdown payout date — design: `Next payout Sat 4 Oct`; app: `Next payout Sat 3 Oct`. Fix: none — DATA OVER MOCKS; seed story day is Sat 3 Oct 2026 (`1_plan.md` §a), database value is correct.
3. History rows — design: `Paid · Sat 27 Sep / £3.80`, `Quest bonus · Put the bins out / +£0.12`, `Birthday money (added by Mum) / +£10.00`, `Spent · Comic / −£2.00`; app: `Weekly pocket money / Sat 3 Oct / +£3.00`, `Quest bonus · Put the bin… / +£0.12`, `Quest bonus · Hoover th… / +£0.40` (DB newest-first order). Fix: none — DATA OVER MOCKS, explicitly accepted by `1_plan.md` §a. Visible row geometry matches spec: 40×40 tiles with correct per-type tints (sky pound tile, coin tiles), gap 12, trailing tabular amounts right-aligned, title/sub ellipsis, `+12p · Approved` sub copy with U+00B7.
4. Tab-bar Money glyph — shared `ParentShell`/`NestTabBar` chrome (RULES.md: `app/lib/app/**` + `core/**` untouchable); band 7 diff ~2.5% is the ignored status/home-reserve area, icons/labels/active-leaf state match. Fix: none — not P12-owned, and no visible mismatch.
5. Bottom edge — design PNGs show a paper strip + home pill below the tab bar; app runs the bar's own surface colour to the physical edge in light AND dark. Fix: none — complies with the OWNER BOTTOM-EDGE rule, which overrides the designs.
6. Alignment/gutters — title, segmented, hero, goal card, history card all share the 20 px gutters; no element is a few px off in either theme. Fix: none.
7. Dark-mode colours — hero `#2A2640`-family (not ink), mint button, dark surface cards, dark tile tints, unchanged coin illustration; all match the dark design. Fix: none.

No other visible deviation: hero amount `£4.20` with −0.4 tracking, `Maya is owed` lab, `Payout time` 52 px button, `Lego Friends set — £24.99` / `£15.50 saved · 62%` + 62% progress fill, `History` h3 — all present, ordered, correctly coloured and spaced within ±2 px logical.

VERDICT: PASS
