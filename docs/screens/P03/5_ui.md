# P03 Create account — UI check (Stage 5, iteration 7)

Route `/create-account` · parent mode · `SEED=fresh` · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844 — the only sim this stage may touch).
Mandatory: `docs/screens/P03/ORCHESTRATOR_NOTES.md` + standing rules (PIP vacuous; status bar ignored; bottom-edge
OWNER rule; CHILD ORDER n/a; COPY exact characters; FONTS no google_fonts; LETTER SPACING default 0;
CHIP ROWS n/a — no chips; SHAPES — bg/border rects measured below; BALANCED HEADINGS — see observation).
Design sources: `design/screens/light|dark/P03-create-account.png` (1170×2532 @3x), HTML source, DESIGN_SPEC §5 P03, SPACING_SPEC.
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /create-account $PWD/docs/screens/P03/ui/app_light_7.png 604697A9-11DA-462F-9837-396E9CA2493A light fresh parent maya` → stable frame saved (absolute out path; relative breaks after `shot.sh` cds into `app/`).
- Same with `dark` → `app_dark_7.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P03-create-account.png docs/screens/P03/ui/app_light_7.png docs/screens/P03/ui/cmp_light_7.png` (and dark → `cmp_dark_7.png`).
- Read `cmp_light_7.png` with the file reader; verified rects/edges by 1–4 px luminance scans.
- Filled-state capture: still host-blocked (no SimulatorKit/HID path, no Simulator.app GUI — proven iterations 2–4
  on this unchanged host). Fallback stands: empty-state captures cover all state-independent geometry; filled state
  pinned by the "design filled state" widget test.

## Mean diff

- Light: **3.10%** (was 3.50%) — bands (0) 0–105: 1.61% · (1) 105–211: 0.30% · (2) 211–316: 0.14% · (3) 316–422: 0.19% · (4) 422–527: 1.33% · (5) 527–633: 0.96% · (6) 633–738: 12.73% · (7) 738–844: 7.60%.
- Dark: **2.47%** (was 3.00%) — bands (0) 0–105: 1.60% · (1) 105–211: 0.32% · (2) 211–316: 0.14% · (3) 316–422: 0.23% · (4) 422–527: 1.32% · (5) 527–633: 0.93% · (6) 633–738: 9.45% · (7) 738–844: 5.83%.
- Bands 1–5 are at noise level. Bands 6–7 residual is empty-vs-filled pixels (field text, dots, CTA colour),
  the OS home pill in captures, and the design's own mock pill.

## Checked and matching — shapes (bg/border rects, x/y/w/h logical)

- Apple button bg: design x=20 y=256 w=350 h=51 vs app x=20 y=256 w=350 h=51 — identical.
- Google button bg: design x=21 y=320 w=348 h=50 vs app x=22 y=320 w=346 h=50 — 1 px edge threshold noise; identical.
- Password field bg: design x=21 y=536 w=348 h=50 vs app x=21 y=536 w=348 h=50 — identical. Email field
  column profile identical row-for-row (white 446–494 both).
- CTA button: edges design vs app — left x18→22, right x368→372, top y693→694 — identical rect
  (≈20/694/350×52); fill differs (solid vs disabled-faded — expected empty state, see non-findings).
- Text landmarks: subtitle L1 right x=365 both (`Children never / need an email.`); title break edges x≈174/218
  vs 172/217; legal `Terms` 760–770 + `Privacy Notice` 780–790 both; CTA hairline 677 vs 678; helper on the
  20 px gutter; note row (shield x=24, text x=52–56, one baseline).
- Copy character-exact (U+2019, U+2014, U+00A0 verified); dark-mode flips correct; bottom edge surface-uniform
  to y=844 both themes (OWNER); 20 px gutters, no overflow/clipping/stray ellipsis (ALIGNMENT).

## Deviations

None. Every pill, button, and field bg rect matches the design within tolerance, with correct copy, token
colours, radii, shadows, and icons in both themes.

## Non-findings and observations (do not fix here)

- Empty fields + disabled faded CTA vs design filled values + solid-green CTA: correct launch behaviour under
  `SEED=fresh`. Expected band-6 contributor.
- Mid-grey 134×5 OS home pill in captures (proven not app-drawn in iteration 6 — no home-indicator reference in
  the view or `NestBottomCta`): OS chrome, same category as the ignored status bar; OWNER surface-to-edge passes.
- Status-bar clock: ignored. Process items (uncommitted work, merge order): loop/orchestrator-owned.
- Observation for the build stage (no visible deviation today): the headline still reaches the design break via
  `ConstrainedBox(maxWidth: …)` (`create_account_view.dart:103-105`, the P03-BUG-7 fix) rather than the newer
  `NestBalancedText` component the BALANCED HEADINGS rule prescribes for `text-wrap: balance` headings. The
  rendered lines break exactly like the design with no orphan (`Create your` / `family account`), so this is
  mechanism, not a visible deviation — recorded here only because the rule is new since the fix landed.

No deviation remains that a designer could flag — the screen matches the design element by element, shape by shape.

VERDICT: PASS
