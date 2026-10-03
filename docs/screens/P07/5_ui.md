# P07 Paywall — UI check (Stage 5, iteration 4)

Method (iPhone simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB, 390×844):
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_light_4.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB light fresh parent maya` → stable frame, EXIT 0
- `bash tools/screens/shot.sh "$PWD/app" /paywall "$PWD/docs/screens/P07/ui/app_dark_4.png" E7D5555E-378A-49DF-AAEE-16677AF4B9DB dark fresh parent maya` → stable frame, EXIT 0
- `python3 tools/screens/compare.py design/screens/light/P07-paywall.png docs/screens/P07/ui/app_light_4.png docs/screens/P07/ui/cmp_light_4.png`
- `python3 tools/screens/compare.py design/screens/dark/P07-paywall.png docs/screens/P07/ui/app_dark_4.png docs/screens/P07/ui/cmp_dark_4.png`
- Sources: `design/html-source/screens/P07-paywall.html`, `1_plan.md`, SPACING_SPEC §§1–2/8, `ORCHESTRATOR_NOTES.md` (incl. iteration-4 update). Pixels are logical (÷3). Status-bar text ignored per rule.

## Mean diff

- Light: **2.56%** (was 5.48%; bands: 0 0–105: 1.58% · 1 105–211: 3.52% · 2 211–316: 7.64% · 3 316–422: 4.12% · 4 422–527: 0.29% · 5 527–633: 0.40% · 6 633–738: 0.18% · 7 738–844: 2.74%)
- Dark: **2.48%** (was 5.28%; bands: 0: 1.58% · 1: 2.47% · 2: 7.74% · 3: 4.24% · 4: 0.29% · 5: 0.45% · 6: 0.18% · 7: 2.86%)
- Iteration 3's two majors are both resolved: bands 4–6 (benefits 4, plan card, CTA) are now 0.2–0.5%, i.e. pixel-identical modulo anti-aliasing.

## Deviations

1. **Minor (accepted) — title wraps with orphan “days”.** Design (`text-wrap: balance`): `Try Nestling` / `free for 14 days`. App: `Try Nestling free for 14` / `days`; identical 2-line block height, no layout shift (band 2's 7.6% is this wrap alone). `ORCHESTRATOR_NOTES.md` iteration-4 update explicitly accepts this as MINOR and forbids a hard break, so it is not a failure. No fix.
2. **Resolved — benefit row 4 single-line again.** `Co-parent sharing, so James sees the same` renders one line (ink band y 482–490 vs design 481–490); the shared letterSpacing-0 change (main fd92d95) removed the Material tracking that made bundled Inter ~1–2% wider. Plan card borders now at y 521–523 / 625–627 vs design 521–522 / 625–626; tag line fully visible above the CTA. No fix.
3. **Resolved — legal `·` separators on the link baseline.** Full-resolution crops of y 756–790 show `Restore purchases · Terms · Privacy` on one shared baseline exactly like the design (iteration-4 vertical-padding fix in `_LegalLink`). Band-7 residual (2.7–2.9%) is glyph anti-aliasing only. No fix.

## Verified matches (element by element)

- Nav/close (44×44 surface-2 r12, `Close and go back`), hero (170 circle, nest 150, `PipAvatar` mochi/stage-4 120 slot, 3 coins at specified rotations), title position/copy, benefits 1–4 (ticks 24 leaf-tint + Inter 15/24, curly ’ intact, row 3 at y 448 vs 447), plan card (2 px leaf border, radio, title em dash, sub, leaf-ink tag), CTA button 52 px at y 646–698 vs 646–697, caption (with `the`), horizontal legal row with 44 px targets, 20 px gutters throughout.
- **BOTTOM EDGE: PASS** — surface runs to the physical edge both themes (light 255,255,255; dark 31,28,46 = `#1F1C2E`); the design PNGs' paper strip is correctly not reproduced per owner rule.
- **ALIGNMENT: PASS** — cards/bars share the 20 px edges; measured rows match to ≤1 px. **COPY: PASS** — all typographic characters exact vs HTML. **DARK: PASS** — no theme-specific deviation. **FONTS: PASS** — zero `google_fonts`/`GoogleFonts` references in view or feature tests. **LETTER SPACING: PASS** — no added tracking (relies on shared zero default).
- **PIP:** `PipAvatar` vs PNG v1 art is the mandated override, not a finding. **ORCHESTRATOR_NOTES item 1** (trial/restore handoff) is behavioural, covered by stage 3/6 tests.

## Verdict basis

Every iteration-3 deviation is resolved and measured pixel-equal; the single remaining visible difference (title line-break) is explicitly accepted as minor by the orchestrator with no permitted fix. No visible deviation a designer would reject remains.

VERDICT: PASS
