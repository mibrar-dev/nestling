# P07 Paywall — UI check (Stage 5, iteration 3)

Method (iPhone simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390×844):
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_light_3.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB light fresh parent maya` → stable frame, EXIT 0
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_dark_3.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB dark fresh parent maya` → stable frame, EXIT 0
- `python3 tools/screens/compare.py design/screens/light/P07-paywall.png docs/screens/P07/ui/app_light_3.png docs/screens/P07/ui/cmp_light_3.png`
- `python3 tools/screens/compare.py design/screens/dark/P07-paywall.png docs/screens/P07/ui/app_dark_3.png docs/screens/P07/ui/cmp_dark_3.png`
- Sources: `design/html-source/screens/P07-paywall.html`, `1_plan.md`, SPACING_SPEC §§1–2/8, `ORCHESTRATOR_NOTES.md`. Pixels are logical (÷3). Status-bar text ignored per rule.

## Mean diff

- Light: **5.48%** (was 11.43% at iteration 2; bands: 0 0–105: 1.60% · 1 105–211: 3.52% · 2 211–316: 7.72% · 3 316–422: 7.37% · 4 422–527: 5.74% · 5 527–633: 10.06% · 6 633–738: 2.49% · 7 738–844: 5.32%)
- Dark: **5.28%** (was 9.78%; bands: 0: 1.57% · 1: 2.47% · 2: 7.82% · 3: 7.65% · 4: 5.84% · 5: 9.32% · 6: 2.45% · 7: 5.12%)
- Iteration 2's blockers are fixed: the legal row is horizontal and the CTA is compact — band 6 fell 28.69% → 2.49%, and the CTA button sits at y 646–698 vs design 646–697 (pixel-perfect). Remaining drift is band 5 (plan card shift), band 2 (title wrap, unchanged) and band 7 (separator offset).

## Deviations (design value → app value + fix)

1. **Major — benefit row 4 wraps to 2 lines, pushing the plan card 24 px down so its tag line is clipped by the CTA.** Design: `Co-parent sharing, so James sees the same` on one line (ink spans x 55–365 = 310 px in a 315 px slot: gutter 20 + tick 24 + gap 10, 5 px to spare); plan-card leaf borders at y 521–522 / 625–626, fully above the CTA panel (top ≈630). App: the same string wraps after `the` (`…sees the` ends at x 332; per-char width matches the design to ~1%, but the bundled Inter measures ~1–2% wider overall, so the 310 px line no longer fits the 315 px slot); plan top border lands at y 545–547 (+24 = exactly one wrapped line) and the card bottom (~649) slides ~19 px under the CTA panel — the tag `One price, the whole family` is half-covered at top-of-scroll. All layout inputs match the spec (gutter 20, tick 24, gap 10, Inter 15/24 explicit per plan §a), so this is font-metrics fidelity, not a layout bug; no token-compliant nudge exists (sizes/copy must not change). Fix: accept as engine-level rendering, or address at the design-system level (e.g. verified Inter metrics/tracking); do NOT shrink text or edit copy — both would break tokens/tests. The clipped tag keeps this a FAIL until resolved.
2. **Major — legal `·` separators sit ~10 px below the link baseline.** Design: links and separators share one baseline (link band y 767–779, seps y 771–772). App: links on one band (y 754–763, horizontal ✓) but both separators render at y 764–772, visibly dropped below the text (see compare crop). Cause: the 44 px-tall `_LegalLink` boxes vs the 18 px sep `Text` share one `Wrap` run — the link glyphs render top-weighted in their min-height boxes while the short sep line boxes settle lower in the run, so `WrapCrossAlignment.center` never brings the dot onto the link baseline. Fix: give the separators the identical 44 px box as the links (e.g. wrap each sep in `SizedBox(height: tapParent, child: Center(child: Text('·', …)))` and ensure link content is likewise centered, so both glyph families — same 13/18 metrics — centre identically). Keep the `Wrap` fallback for 320 dp / 1.3× overflow.
3. **Minor (unchanged) — title wraps with orphan “days”.** Design (`text-wrap: balance`): `Try Nestling` / `free for 14 days`. App: `Try Nestling free for 14` / `days`. Identical 2-line block height, no layout shift. Fix is constrained: copy tests require the exact single string, so no hard break may be inserted; accept or add balance support in the design system.

## Verified matches (no action)

- Nav/close (44×44 surface-2 r12), hero geometry (circle/nest/Pip slot/coins align; hero ink rows identical to design), title block position, benefits 1–3 (row 3 text at y 448 vs 447), plan-card geometry (borders, 2 px leaf ring, radio, radius, shadow), plan copy incl. em dash, CTA button (52 px, y 646–698) + caption (with `the`) + horizontal legal links, 20 px gutters throughout.
- **BOTTOM EDGE: PASS** — last row is CTA surface both themes (light 255,255,255; dark 31,28,46 = `#1F1C2E`); no paper/meadow strip. The design PNGs' own paper strip is correctly not reproduced (owner rule overrides).
- **COPY: PASS** — curly ’, em dashes, `·` separators, `£` all exact vs HTML. **DARK: PASS** — no theme-specific deviation. **FONTS: PASS** — no `google_fonts`/`GoogleFonts` in view or feature tests. **PIP:** `PipAvatar(mochi, stage 4, inNest)` vs PNG's v1 SVG is the mandated override, not a finding.

## Verdict basis

Iteration 3 fixed the vertical legal stack and the oversized CTA, halving the diff. What a designer would still reject: the wrapped 4th benefit with the plan-card tag sliding under the CTA, and the dropped `·` separators. Both are visible in light and dark at top-of-scroll.

VERDICT: FAIL
