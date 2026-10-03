# P07 Paywall — UI check (Stage 5, iteration 2)

Method (iPhone simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390×844):
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_light_2.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB light fresh parent maya` → stable frame saved, EXIT 0
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_dark_2.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB dark fresh parent maya` → stable frame saved, EXIT 0
- `python3 tools/screens/compare.py design/screens/light/P07-paywall.png docs/screens/P07/ui/app_light_2.png docs/screens/P07/ui/cmp_light_2.png`
- `python3 tools/screens/compare.py design/screens/dark/P07-paywall.png docs/screens/P07/ui/app_dark_2.png docs/screens/P07/ui/cmp_dark_2.png`
- Sources: `design/html-source/screens/P07-paywall.html`, `1_plan.md`, SPACING_SPEC §§1–2/8, `ORCHESTRATOR_NOTES.md`. All pixel numbers below are logical px (screenshot ÷ 3). Status-bar text ignored per orchestrator rule.

## Mean diff

- Light: **11.43%** (bands: 0 0–105: 1.63% · 1 105–211: 3.52% · 2 211–316: 7.72% · 3 316–422: 7.37% · 4 422–527: 22.00% · 5 527–633: 16.79% · 6 633–738: 28.69% · 7 738–844: 3.88%)
- Dark: **9.78%** (bands: 0 0–105: 1.58% · 1 105–211: 2.47% · 2 211–316: 7.82% · 3 316–422: 7.65% · 4 422–527: 19.25% · 5 527–633: 14.03% · 6 633–738: 21.72% · 7 738–844: 3.80%)
- Bands 0–3 (nav, hero, title, benefits 1–3) match closely; all drift sits in bands 4–6 (4th benefit, plan card, CTA). The screen is fully built — the failures are two visible layout defects, not missing content.

## Deviations (design value → app value + fix)

1. **Major — legal row stacks vertically instead of one horizontal row.** Design (HTML `.legal-row`, flex, gap 2): `Restore purchases · Terms · Privacy` on a single centred row; sky link pixels sit on one band at y≈768–774. App: three full-width rows — `Restore purchases` at y≈615, `Terms` at y≈693, `Privacy` at y≈771 — with the `·` separators isolated on their own lines (ink dots at y≈575, ≈622). Root cause in `paywall_view.dart` `_LegalLink`: the chain `ConstrainedBox > Material > InkWell > Padding > Center > Text` sits inside a `Wrap`; `Center` (Align) expands to the Wrap run's full 350 px width, so every link occupies its own run. Fix: drop the expanding inner `Center` so the link sizes to its text (e.g. `InkWell > Padding > Text`), keeping the 44×44 min target from the outer `ConstrainedBox`; all three links + separators then fit one run at 390 dp as in the design.
2. **Major — bottom CTA panel ≈150 px too tall; CTA button 156 px too high.** Design: green CTA button y 646–697 (52 px). App: y 490–541 (52 px, correct size, wrong place). The panel top edge is dragged up by deviation 1's five stacked legal lines. Fix: follows from fixing 1 — with a single-row legal row the panel compacts to the design geometry (button ≈646).
3. **Major (consequence of 1–2) — 4th benefit and plan card hidden behind the CTA at top-of-scroll.** Design shows benefit rows 1–4 (last text band y 481–490) plus the plan card (leaf borders y 521–522 / 625–626) above the CTA. App: scroll content aligns exactly through row 3 (row-3 text band y 448 vs design 447), but row 4 (expected ≈481) is covered by the CTA panel and no plan-card border pixels are detected anywhere above the fold. The widgets exist in normal flow below (code order hero/title/benefits/plan/timeline/note is correct, presence covered by widget tests) — they are purely overlapped. Fix: same as 1; once the CTA compacts, design content bottom (plan border 625, panel top 630) fits exactly as drawn.
4. **Minor — title breaks with orphan “days”.** Design (HTML `class="h1 balance"`, `text-wrap: balance`): `Try Nestling` / `free for 14 days`. App (plain engine wrap, centred, same 2-line height y≈291/297–344): `Try Nestling free for 14` / `days`. No layout shift (identical block height), purely typographic. Fix is constrained: copy tests require the exact single string, so a hard `\n` would break `find.text`; either accept engine wrap or add balance support at the design-system level — do not touch the copy string.
5. **Not a finding — Pip rendering differs from the PNG.** Design shows the v1 `pip_stage_4.svg` songbird (with scarf); app renders `PipAvatar(style: mochi, stage: 4, inNest: true)`. The orchestrator PIP rule mandates `PipAvatar` and forbids v1 SVGs on product screens — the app is correct, the PNG is overridden. Hero geometry otherwise matches (circle/nest/coins positions and sizes align; hero ink rows y 250–280 identical).

## Owner / orchestrator checks

- **BOTTOM EDGE: PASS.** App last row = CTA surface in both themes (light 255,255,255 = surface; dark 31,28,46 = `#1F1C2E` surface). No paper/meadow strip under the bar or home-indicator area. (The design PNGs themselves show a paper strip there — the owner rule overrides the designs, and the app correctly does not reproduce it.)
- **ALIGNMENT: PASS** for visible content — nav, hero, title, benefits 1–3 share the design's 20 px gutters (bands 0–3 ≤ 7.8%, rows align to the pixel: row 3 at 448 vs 447).
- **COPY: PASS** — title, 3 visible benefits (curly ’ intact), CTA, caption (`…after the 14-day trial…` with `the`), links all character-correct vs HTML.
- **DARK COLOURS: PASS** — dark surface panel, leaf-tint ticks, leaf CTA, readable sky links; deviations are the same two layout items, nothing theme-specific.
- **FONTS: PASS** — no `google_fonts`/`GoogleFonts` in the view or feature tests (bundled-asset tokens used).
- **STATUS BAR:** ignored per rule (live time vs `9:41` mock).
- **ORCHESTRATOR_NOTES item 1** (trial/restore session handoff → `/today`) is behavioural, not visual; the CTA exists and the wiring is covered by stage 3/6 tests, not this check.

## Verdict basis

Two designer-visible defects at top-of-scroll in both themes: the legal links stacked as five full-width lines, and the oversized CTA panel swallowing the 4th benefit and the whole plan card. Everything else — nav, hero, title, benefits, CTA button, caption, bottom edge, gutters, dark theme — matches.

VERDICT: FAIL
