# P03 Create account — UI check (Stage 5, iteration 6)

Route `/create-account` · parent mode · `SEED=fresh` · child maya · simulator 604697A9-11DA-462F-9837-396E9CA2493A (iPhone 16e, 390×844).
Mandatory: `docs/screens/P03/ORCHESTRATOR_NOTES.md` (incl. 17:22 subtitle-shared UPDATE and 23:48 shared-batch-2 note:
NestChip 32 px — n/a, no chips on P03; NestTextField error state — shared; google_fonts gone) + standing rules
(PIP vacuous; status bar ignored; bottom-edge OWNER rule; CHILD ORDER n/a; COPY exact characters; FONTS no
google_fonts; LETTER SPACING default 0; CHIP ROWS n/a).
Design sources: `design/screens/light|dark/P03-create-account.png` (1170×2532 @3x), HTML source, DESIGN_SPEC §5 P03, SPACING_SPEC.
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /create-account $PWD/docs/screens/P03/ui/app_light_6.png 604697A9-11DA-462F-9837-396E9CA2493A light fresh parent maya` → stable frame saved (absolute out path; relative breaks after `shot.sh` cds into `app/`).
- Same with `dark` → `app_dark_6.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P03-create-account.png docs/screens/P03/ui/app_light_6.png docs/screens/P03/ui/cmp_light_6.png` (and dark → `cmp_dark_6.png`).
- Read `cmp_light_6.png` with the file reader; verified edges by 1–2 px luminance scans.
- Filled-state capture: still host-blocked (no SimulatorKit/HID path, no Simulator.app GUI — proven iterations 2–4
  on this unchanged host). Fallback stands: empty-state captures cover all state-independent geometry; filled state
  pinned by the "design filled state" widget test.

## Mean diff

- Light: **3.50%** (was 4.66%) — bands (0) 0–105: 1.64% · (1) 105–211: 0.30% · (2) 211–316: 0.14% · (3) 316–422: 0.24% · (4) 422–527: 2.33% · (5) 527–633: 2.61% · (6) 633–738: 13.81% · (7) 738–844: 6.93%.
- Dark: **3.00%** (was 4.27%) — bands (0) 0–105: 1.60% · (1) 105–211: 0.32% · (2) 211–316: 0.14% · (3) 316–422: 0.28% · (4) 422–527: 2.41% · (5) 527–633: 2.70% · (6) 633–738: 10.61% · (7) 738–844: 5.95%.
- Bands 1–3 are now at noise level (0.14–0.32%). Bands 6–7 residual is empty-vs-filled pixels (field text, dots,
  CTA colour), the home-pill artefact below, and the design's own mock pill.

## Checked and matching (all elements)

- Subtitle break (shared fix now in this branch): FIXED. App line 1 now ends `…in charge. Children never`
  (right edge x≈365–367, rows y 192–200) with `need an email.` on line 2 — identical to the design (x≈365–367).
  Bands 1–2 fell 5.6%→0.3%. Copy is U+2019 `You’re` (COPY rule satisfied).
- Header (ink y=120, Apple black y=255 both), title break (`Create your` / `family account`, x≈174/218 vs 172/217),
  legal footer (`Terms` 760–770, `Privacy Notice` 780–790 with nbsp, ≈38 dp centred block), CTA hairline
  design y=677 vs app y=678 (within ±2 px; clearance identical at 39 px), helper on the 20 px gutter with the
  design-identical gap, note row (shield x=24, text x=52–56, one baseline), or-row, buttons, fields, eye icon.
- Dark-mode flips correct (Apple white, Google near-black, sky links, lilac shield). No google_fonts involvement
  on this screen; letter-spacing follows the shared default (no local tracking added).
- Bottom edge (OWNER): surface uniform to y=844 both themes (light 255, dark 35) — no coloured strip.
  Alignment (OWNER): 20 px gutters, no overflow/clipping/stray ellipsis.

## Deviations

None. Every element this screen owns matches the design within the ±2 px tolerance, character-exact copy,
token colours, radii, shadows, and icons in both themes.

## Non-findings (explained, do not fix)

- A 134×5 mid-grey pill now appears at y≈831–835 in the app captures (light grey ~90–130 on white; grey ~72–76
  on dark surface) that was absent on the previous simulator. It is NOT app-drawn — no `NestHomeIndicator` /
  home-indicator reference exists in the P03 view or `NestBottomCta` (grep clean), and its colour matches neither
  theme's spec pill (ink-opaque light / white dark). It is this iPhone-16e runtime's OS home indicator landing in
  the `simctl` framebuffer: OS chrome in the same category as the status bar (which the OS likewise draws on
  device). The OWNER rule itself passes — the bar's surface colour runs uninterrupted to the physical edge
  around it. Ignored exactly like status-bar pixels.
- Empty fields + disabled faded CTA vs design filled values + solid-green CTA: correct launch behaviour under
  `SEED=fresh` (keep per orchestrator). Expected band-6 contributor.
- Status-bar clock: ignored per standing rule. Process items (uncommitted iteration-6 work, merge order):
  handled by the loop and orchestrator.

No P03-attributable deviation remains that a designer could flag — the screen matches the design element by element.

VERDICT: PASS
