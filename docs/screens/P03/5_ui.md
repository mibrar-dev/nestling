# P03 Create account — UI check (Stage 5, iteration 4)

Route `/create-account` · parent mode · `SEED=fresh` · child maya · simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
Mandatory: `docs/screens/P03/ORCHESTRATOR_NOTES.md` (latest: iter-3 QA — legal nbsp, subtitle U+2019 + break,
filled capture) + standing rules (PIP vacuous; status bar ignored; bottom-edge OWNER rule; CHILD ORDER n/a;
COPY — exact typographic characters vs HTML).
Design sources: `design/screens/light|dark/P03-create-account.png` (1170×2532 @3x), HTML source
(`You&rsquo;re`, `Privacy Notice`, `— ever.`), DESIGN_SPEC §5 P03, SPACING_SPEC.
No code edited in this stage.

## Captures

- `bash tools/screens/shot.sh $PWD/app /create-account $PWD/docs/screens/P03/ui/app_light_4.png BC440E48-B3A3-43BC-971B-0EF5DB621874 light fresh parent maya` → stable frame saved (absolute out path; relative breaks after `shot.sh` cds into `app/`).
- Same with `dark` → `app_dark_4.png` → stable frame saved.
- `python3 tools/screens/compare.py design/screens/light/P03-create-account.png docs/screens/P03/ui/app_light_4.png docs/screens/P03/ui/cmp_light_4.png` (and dark → `cmp_dark_4.png`).
- Read `cmp_light_4.png` with the file reader; verified geometry by 1–2 px luminance scans.
- Filled-state capture: still host-blocked — `idb ui tap` fails with `SimulatorKit … does not exist`
  (re-probed iteration 3; this Xcode 27 install has no SimulatorKit/HID path and no Simulator.app GUI).
  Fallback stands: empty-state captures cover all state-independent geometry; the filled state is pinned by the
  `create_account_view_test.dart` "design filled state" test.

## Mean diff

- Light: **4.66%** (unchanged from iteration 3) — bands (0) 0–105: 1.58% · (1) 105–211: 5.59% · (2) 211–316: 2.50% · (3) 316–422: 1.76% · (4) 422–527: 2.48% · (5) 527–633: 2.78% · (6) 633–738: 14.39% · (7) 738–844: 6.22%.
- Dark: **4.26%** (was 4.27%) — bands (0) 0–105: 1.52% · (1) 105–211: 5.86% · (2) 211–316: 2.56% · (3) 316–422: 1.78% · (4) 422–527: 2.57% · (5) 527–633: 2.88% · (6) 633–738: 11.20% · (7) 738–844: 5.74%.
- Bands 6–7 residual is empty-vs-filled pixels (field text, dots, CTA colour), the design's home-pill vs none in
  `simctl` captures, and the single deviation below.

## Checked and matching

- Subtitle copy character (iteration-3 deviation 1): FIXED. The view now contains U+2019 (`'You’re the grown-up…'`,
  verified by source read; repo U+2019 count in the view is 1, was 0). Satisfies the COPY rule and ON iter-3 item 2a.
- Legal footer (nbsp): unchanged, still matching — `Terms` rows 760–770, `Privacy Notice` rows 780–790, same as
  design (761–768 / 779–791); caption ≈38 dp, centred, normal gap.
- CTA hairline: design y=677, app y=678 (both themes implied by identical dark bands) — within ±2 px; note
  clearance identical at 39 px.
- Header (ink y=120, Apple y=255 both), title break (`Create your` / `family account`, edges x 174/218 vs 172/217),
  helper on the 20 px gutter with identical 12 px text-top gap, note row (shield x=24, text x=52–56, one baseline),
  or-row, buttons, fields, eye icon, dark-mode flips, bottom edge (surface uniform to y=844 both themes),
  20 px gutters, no overflow/clipping/stray ellipsis: all within tolerance.

## Deviations (element, design value, app value, fix)

1. Subtitle wraps a word early (ORCHESTRATOR_NOTES iter-3 item 2b — still open). Design line 1 ends
   `…in charge. Children never` (right edge x≈365–367) with `need an email.` on line 2. App line 1 ends
   `…in charge. Children` (right edge x≈328–330, rows y 192–200) with `never need an email.` on line 2
   (rows y 214–224) — same 350 dp measure and same vertical position (line-1 rows y 190–200 both), so the app's
   subtitle glyphs still run ~35 px wider per line than the HTML `.body`. The U+2019 fix did not move the break
   (expected: one glyph's width cannot account for ~35 px). Fix: match the HTML subtitle metrics exactly
   (16/24 Inter 400 — size, weight, letter-spacing/word-spacing, font-feature settings — per `tokens.css` /
   `components.css`, no ad-hoc values), then confirm the design break `Children never / need an email.` at
   390 width; keep sensible wrapping at 320 dp / scale 1.3.

## Non-findings (explained, do not fix)

- Empty fields + disabled faded CTA vs design filled values + solid-green CTA: correct launch behaviour under
  `SEED=fresh` (keep per ON item 3). Expected band-6 contributor, not a defect.
- Status-bar clock and the design's home-indicator pill (never drawn by `simctl`): ignored/artefact per standing
  rules; the OWNER bottom edge itself passes with surface to the edge.
- Process items (uncommitted iteration-4 build/test work in this worktree) belong to the loop, not to findings.

One visible deviation remains — the subtitle's second line reads `never need an email.` instead of `need an email.`,
plainly visible side-by-side and explicitly mandated by ON iter-3 item 2 — so this iteration does not pass.
It is a single localised style-metrics fix.

VERDICT: FAIL
