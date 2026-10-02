# P02 Value tour — Stage 5 UI check (iteration 2)

Route `/value-tour`, seed `fresh`, mode `parent`, child `maya`, simulator
604697A9-11DA-462F-9837-396E9CA2493A (390×844). No `ORCHESTRATOR_NOTES.md`
exists; orchestrator stage-prompt rules apply (Pip = `PipAvatar` mochi/sunny,
status-bar differences ignored, data-over-mocks, bottom-edge owner rule).

Provenance: `ui/app_light_2.png` / `app_dark_2.png` were captured earlier in
this iteration (08:35/08:37) after the last screen-code edit (08:31) and were
verified current; `compare.py` was re-run by this stage below.
Compares: `cmp_light_2.png`, `cmp_dark_2.png`.

## Mean diff

- Light: **4.05%** (bands: 0: 2.01, 1: 5.48, 2: 5.26, 3: 6.61, 4: 0.87,
  5: 3.94, 6: 4.39, 7: 3.80). Was 6.50% in iteration 1.
- Dark: **3.85%** (bands: 0: 1.90, 1: 5.36, 2: 5.31, 3: 6.05, 4: 0.81,
  5: 4.09, 6: 4.68, 7: 2.58). Dark token colours sampled identical to
  design. All layout findings apply to both themes.

## Fixed since iteration 1 (verified)

Card geometry now exact (top y=107, pitch 50 px, dots y=534–540, title
y=584–604, button y=742–792 — all identical counts/positions); rows 2–4
titles render in full; tour nav is the spec 60 px; Next button, dots,
progress 4/6, chips, icons/tints, dashed row, CTA padding all match.

## Accepted overrides (not deviations)

- Chip `Sat 3 Oct` vs PNG `Sat 4 Oct`: database wins (4 Oct 2026 is a
  Sunday; seed anchored to Sat 3 Oct 2026 — P02-BUG-5). Correct as shown.
- Row subtitles (`Maya · daily`, `Maya · weekly`, …) vs PNG assignees:
  seeded quest rows win (P02-BUG-4). Correct as shown.
- Bottom edge is bar-surface colour to the physical edge (PNG shows paper;
  owner bottom-edge rule overrides). Correct as shown.
- Status-bar glyphs/time differ (OS-drawn; ignored per rule).

## Deviations (logical px, design ÷ 3)

1. Row-1 title still ellipsised (MAJOR — the one designer-reject left).
   Element: card-1 row 1. Design value: `Empty the dishwasher` in full
   (ends x=240, 14 px clear of the pill at x=254). App value:
   `Empty the dishwas…` (ellipsis, ends x=234). Measured geometry is
   otherwise identical on both sides — pill x=254–312 (w 58), tile x=36–71
   (w 35) — so the text slot is the same 174 px; Flutter's Inter 600
   renders this longest title ~2 px wider than the browser and trips the
   ellipsis. Rows 2–4 fit with a few px to spare. Fix: reclaim a few px on
   this row without touching shared code or spec type (e.g. verify
   `NestCoinPill.small` internals — gap/padding — against design-small and
   tighten if any slack; otherwise shrink nothing and seek designer /
   orchestrator sign-off, since no token-compliant lever remains).

2. Body block sits ~4 px high (MINOR). Element: step-1 body. Design value:
   lines y≈634–644 + 662–668, left x=22. App value: y≈630–640 + 658–664,
   same left edge, same 2-line wrap. Fix: nudge the title→body gap so the
   block lands on the design rows; not a reject on its own.

3. Body punctuation unchanged (MINOR, needs ruling, not a builder defect).
   Element: step-1 body copy. Design PNG: curly quotes + em dash
   (`…“Put the bins out” — or…`). App: straight quotes, no dash, which
   matches DESIGN_SPEC §5 P02 and the repo strings verbatim. Fix:
   orchestrator to rule PNG vs spec-doc; builder then follows.

## Coverage gap (not a failure)

Steps 2–3 (Pip nest / jar cards, `Continue`) are still only peek-visible;
widget tests cover their content (Stage 6: 4 `PipAvatar`s mochi/sunny
[3,1,2,3], no v1 SVGs). Capture pages 2–3 if the loop wants full proof.

VERDICT: FAIL
