# P03 Create account — UI check (Stage 5, iteration 8)

Route `/create-account` · parent mode · `SEED=fresh` · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844 — the only sim this stage may touch).
Mandatory: `docs/screens/P03/ORCHESTRATOR_NOTES.md` (latest: render h1 with `NestBalancedText`, headline L1/L2 tops
112.67/146.00 pinned by tests, P03-BUG-24) + standing rules (PIP vacuous; status bar ignored; bottom-edge OWNER
rule; CHILD ORDER n/a; COPY exact characters; FONTS no google_fonts; LETTER SPACING default 0; CHIP ROWS n/a;
SHAPES — rects measured; BALANCED HEADINGS).
Design sources: `design/screens/light|dark/P03-create-account.png` (1170×2532 @3x), HTML source, DESIGN_SPEC §5 P03, SPACING_SPEC.
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /create-account $PWD/docs/screens/P03/ui/app_light_8.png 604697A9-11DA-462F-9837-396E9CA2493A light fresh parent maya` → stable frame saved (absolute out path; relative breaks after `shot.sh` cds into `app/`).
- Same with `dark` → `app_dark_8.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P03-create-account.png docs/screens/P03/ui/app_light_8.png docs/screens/P03/ui/cmp_light_8.png` (and dark → `cmp_dark_8.png`).
- Read `cmp_light_8.png` with the file reader; verified rects/edges by 1–4 px luminance scans.
- Filled-state capture: still host-blocked (no SimulatorKit/HID path, no Simulator.app GUI — proven iterations 2–4
  on this unchanged host). Fallback stands: empty-state captures cover all state-independent geometry; filled state
  pinned by the "design filled state" widget test.

## Mean diff

- Light: **3.10%** (unchanged) — bands (0) 0–105: 1.59% · (1) 105–211: 0.30% · (2) 211–316: 0.14% · (3) 316–422: 0.19% · (4) 422–527: 1.33% · (5) 527–633: 0.96% · (6) 633–738: 12.73% · (7) 738–844: 7.60%.
- Dark: **2.49%** (was 2.47%) — bands (0) 0–105: 1.59% · (1) 105–211: 0.32% · (2) 211–316: 0.14% · (3) 316–422: 0.23% · (4) 422–527: 1.32% · (5) 527–633: 0.93% · (6) 633–738: 9.45% · (7) 738–844: 5.95%.
- Bands 1–5 at noise level. Bands 6–7 residual is empty-vs-filled pixels (field text, dots, CTA colour), the OS
  home pill in captures, and the design's own mock pill.

## Checked and matching (elements + shapes)

- Headline via `NestBalancedText` (adopted this iteration, `create_account_view.dart:101`): line 1 ends `Create your`
  (right x≈171–172, rows y 124–132), line 2 ends `family account` (right x≈212–217, rows y 156–164) — identical to
  the design edges (172/217); no orphan line. The iteration-7 width-cap observation is closed by the component.
- Subtitle `Children never / need an email.` (L1 right x=365, U+2019) — identical. Header (ink y=120, Apple black
  y=255), Google/password bg rects identical to iter-7 measurement, CTA hairline 677 vs 678, legal `Terms` 760–768
  + `Privacy Notice` 780–788 with nbsp, helper on the 20 px gutter, note row (shield x=24, text x=52–56).
- Dark-mode flips correct; bottom edge surface-uniform to y=844 both themes (OWNER); 20 px gutters, no
  overflow/clipping/stray ellipsis (ALIGNMENT); copy character-exact; no google_fonts; no local letter-spacing.

## Deviations

None. Every pill, button, and field bg rect matches the design within tolerance, with correct copy, token
colours, radii, shadows, and icons in both themes.

## Non-findings (explained, do not fix)

- Empty fields + disabled faded CTA vs design filled values + solid-green CTA: correct launch behaviour under
  `SEED=fresh`. Expected band-6 contributor.
- Mid-grey 134×5 OS home pill in captures (proven not app-drawn in iteration 6): OS chrome, same category as the
  ignored status bar; OWNER surface-to-edge passes around it.
- Status-bar clock: ignored. Process items (uncommitted iteration-8 work, merge order): loop/orchestrator-owned.

No deviation remains that a designer could flag — the screen matches the design element by element, shape by shape.

VERDICT: PASS
